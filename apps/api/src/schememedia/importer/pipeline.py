"""Core import pipeline: schemes.json -> database.

Idempotent and re-runnable (see tests/test_import.py): running twice against
an unchanged file produces identical row counts. Two different idempotency
strategies, chosen per table:

  * `schemes` -- upsert on `scheme_id` (the natural key preserved from the
    source, per REBUILD_PLAN A-7, so existing likes/saves stay valid). A
    scheme's `slug` is generated once, on first import, and never
    recomputed on re-import -- otherwise a stable, shareable URL would
    change underneath anyone who bookmarked it.
  * Every child table (`scheme_tags`, `scheme_benefits`, `scheme_documents`,
    `scheme_eligibility_rules`) -- delete-then-reinsert per scheme, every
    run. Simpler than diffing for the write itself, and correct: these rows
    have no independent identity a caller could hold onto across a
    re-import. A content diff still runs first, purely for the report (see
    `_reimport_benefits` and friends) -- it changes nothing about what gets
    written.

PROVENANCE -- compare-before-write, added alongside the data-freshness
hardening design (see docs/adr and the redesign conversation this
implements)
----------------------------------------------------------------------------
Every run is recorded as one `ImportRun` row. Every scheme field that
differs between the live row and this run's source data is recorded as one
`SchemeFieldChange` row (see db/models/provenance.py), whether or not it was
actually written:

  * For a scheme whose `verification_status` is `officially_verified`, the
    diff is computed and recorded (`applied=False`) but NEVER written -- no
    scalar field, and no child table (tags/benefits/documents/rules)
    either. An admin's manual verification is never silently clobbered by a
    later re-import.
  * For every other scheme, the diff is recorded (`applied=True`) and then
    applied exactly as before -- this adds visibility, not a behaviour
    change, for the normal path.

This is deliberately NOT a live refresh mechanism: nothing here fetches
data on its own, on a schedule or otherwise. It only makes each existing,
manually-triggered `run_import()` call auditable. See the design doc for
why that boundary is where it is.

Sync SQLAlchemy throughout -- this is a batch job, not request-serving code,
so it doesn't need the app's async engine (see sync_database_url below).
"""

from __future__ import annotations

import hashlib
import json
import re
import unicodedata
from dataclasses import asdict, dataclass, field
from datetime import UTC, date, datetime
from pathlib import Path
from typing import Any

from sqlalchemy import delete, func, insert, select, update
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.orm import Session

from schememedia.db.models import (
    Category,
    ImportRun,
    Scheme,
    SchemeBenefit,
    SchemeDocument,
    SchemeEligibilityRule,
    SchemeFieldChange,
    SchemeTag,
    Tag,
)
from schememedia.db.models.enums import Jurisdiction, SchemeType, VerificationStatus
from schememedia.services.document_splitter import split_documents
from schememedia.services.eligibility_translator import (
    TranslationResult,
    translate_eligibility,
)

# Raw source scheme_type values, measured on the real 1,000-record dataset:
# {subsidy: 716, policy: 158, employment: 54, loan: 32, pension: 24,
#  insurance: 16}. Four map directly onto SchemeType. Two do not --
# "policy" and "employment" have no equivalent in the enum (which has
# scholarship/training/award/grant instead, none of which fit these records
# any better than OTHER would). Mapped to OTHER rather than guessed at;
# counted separately in the data-quality report rather than decided
# silently.
SCHEME_TYPE_MAP: dict[str, SchemeType] = {
    "subsidy": SchemeType.SUBSIDY,
    "loan": SchemeType.LOAN,
    "pension": SchemeType.PENSION,
    "insurance": SchemeType.INSURANCE,
}

DATA_SOURCE = "schemes.json (v1 dataset)"

# Benefit amount strings truncated by the source generator. Measured: 627
# blobs at exactly 200 chars, 6 more at 195-199 -- 633 total, none between
# 1 and 194. len() >= 195 catches exactly this set with no false positives
# on the real data.
TRUNCATION_LENGTH_THRESHOLD = 195

_NON_ALNUM = re.compile(r"[^a-z0-9]+")

# Committing the whole file in one transaction is instant on a local
# loopback Postgres, but over a real WAN link (e.g. Neon) it's a
# multi-minute transaction built from ~1,000 small round trips -- and a
# single dropped connection anywhere in that window discarded everything,
# discovered the hard way importing into a real staging database. Every
# scheme write is already idempotent (ON CONFLICT upsert / delete-then-
# reinsert, see the module docstring), so batching just moves the commit
# boundary; it changes nothing about what gets written.
DEFAULT_BATCH_SIZE = 50

# Scheme scalar fields compared against the live row on every re-import --
# see _diff_scheme_fields. Deliberately not every column: slug is stable by
# design (module docstring), data_source/is_active/verification_status are
# either constant or explicitly excluded from the diff (verification_status
# is exactly what compare-before-write protects, see module docstring).
_TRACKED_SCHEME_FIELDS = (
    "name",
    "ministry",
    "category_id",
    "scheme_type",
    "jurisdiction",
    "state_code",
    "description_short",
    "needs_review",
    "raw_eligibility",
)


def sync_database_url(url: str) -> str:
    """Convert the app's asyncpg URL to a sync psycopg URL for batch jobs."""
    if "+asyncpg" in url:
        return url.replace("postgresql+asyncpg://", "postgresql+psycopg://", 1)
    if url.startswith("postgresql://"):
        return url.replace("postgresql://", "postgresql+psycopg://", 1)
    return url


def _slugify(text: str) -> str:
    """ASCII, lowercase, hyphen-separated. Never empty."""
    normalised = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()
    slug = _NON_ALNUM.sub("-", normalised.lower()).strip("-")
    return slug or "scheme"


def _unique_slug(name: str, used: set[str], report: ImportReport) -> str:
    """A slug for a scheme seen for the first time.

    One real collision exists in the data -- two schemes both named
    "Establishment of Goat Unit (10 +1)" -- resolved generically with a
    numeric suffix rather than a hardcoded special case, so any future
    collision is handled the same way.
    """
    base = _slugify(name)[:200]
    slug = base
    suffix = 2
    while slug in used:
        slug = f"{base}-{suffix}"
        suffix += 1
    if slug != base:
        report.slug_collisions_resolved += 1
    used.add(slug)
    return slug


@dataclass
class ImportReport:
    """Printed at the end of every import run -- see HANDOFF.md section 9.
    Also stored, as a plain dict (see run_import), on the ImportRun row for
    this run -- so a later query can filter on any of these fields without
    re-parsing the printed text.
    """

    schemes_seen: int = 0
    schemes_inserted: int = 0
    schemes_updated: int = 0
    schemes_needing_review: int = 0
    schemes_missing_official_url: int = 0
    schemes_that_match_nobody: int = 0
    categories_created: int = 0
    tags_created: int = 0
    benefits_created: int = 0
    benefits_truncated: int = 0
    documents_created: int = 0
    documents_needing_review: int = 0
    documents_split_by_rule: dict[str, int] = field(default_factory=dict)
    rules_created: int = 0
    rules_needing_review: int = 0
    slug_collisions_resolved: int = 0
    unmapped_scheme_types: dict[str, int] = field(default_factory=dict)

    # ---------- Provenance (see module docstring) ----------
    # A scheme held back because it is officially_verified -- no field,
    # and no child table, was written for it this run.
    schemes_held_back_verified: int = 0
    # Of those held back, how many actually had at least one field differ
    # from the source data -- i.e. how many are worth a human's attention.
    schemes_verified_with_pending_changes: int = 0
    # Scalar-field changes actually written this run (excludes the held-back
    # ones above, which are recorded but never applied).
    field_changes_applied: int = 0
    # Schemes (not held back) whose benefits/documents/rules content
    # differed from what was already stored, detected by comparing content
    # before the existing delete-then-reinsert -- see _reimport_benefits
    # and friends.
    schemes_with_benefit_changes: int = 0
    schemes_with_document_changes: int = 0
    schemes_with_rule_changes: int = 0
    # A whole-table snapshot, not specific to what this run touched: how
    # many currently-active schemes have a deadline already in the past.
    # Always 0 today -- the source dataset carries no application_deadline
    # at all (see db/models/scheme.py) -- but the metric exists so it means
    # something the moment deadline data starts arriving, by whatever route
    # (a richer source file, a future manual-correction workflow). No
    # crawling or scheduled check added here; see module docstring.
    schemes_deadline_passed_still_active: int = 0

    def render(self) -> str:
        lines = [
            "SchemeMedia import -- data quality report",
            "=" * 60,
            f"Schemes seen:                {self.schemes_seen}",
            f"  inserted:                  {self.schemes_inserted}",
            f"  updated:                   {self.schemes_updated}",
            f"  needs_review:              {self.schemes_needing_review}",
            f"  missing official_url:      {self.schemes_missing_official_url}",
            f"  match nobody (no OR rule): {self.schemes_that_match_nobody}",
            f"  deadline passed, active:   {self.schemes_deadline_passed_still_active}",
            "Provenance:",
            f"  held back (verified):      {self.schemes_held_back_verified}"
            f" (with pending changes: {self.schemes_verified_with_pending_changes})",
            f"  field changes applied:     {self.field_changes_applied}",
            f"  schemes w/ benefit changes:  {self.schemes_with_benefit_changes}",
            f"  schemes w/ document changes: {self.schemes_with_document_changes}",
            f"  schemes w/ rule changes:     {self.schemes_with_rule_changes}",
            f"Categories created:          {self.categories_created}",
            f"Tags created:                {self.tags_created}",
            f"Benefits created:            {self.benefits_created}"
            f" (truncated: {self.benefits_truncated})",
            f"Documents created:           {self.documents_created}"
            f" (needs_review: {self.documents_needing_review})",
            "  split by rule:             "
            f"{dict(sorted(self.documents_split_by_rule.items()))}",
            f"Eligibility rules created:   {self.rules_created}"
            f" (needs_review: {self.rules_needing_review})",
            f"Slug collisions resolved:    {self.slug_collisions_resolved}",
        ]
        if self.unmapped_scheme_types:
            lines.append(
                "scheme_type values with no direct enum match, mapped to "
                f"OTHER: {dict(sorted(self.unmapped_scheme_types.items()))}"
            )
        return "\n".join(lines)


def _upsert_categories(
    session: Session, records: list[dict[str, Any]], report: ImportReport
) -> dict[str, Any]:
    """Return {slug: category_id}, creating any category rows not yet present."""
    names = sorted({r["category"] for r in records if r.get("category")})
    existing: dict[str, Any] = {
        row.slug: row.id for row in session.execute(select(Category.slug, Category.id))
    }
    for order, name in enumerate(names):
        slug = _slugify(name)
        if slug in existing:
            continue
        category_id = session.execute(
            pg_insert(Category)
            .values(slug=slug, name=name, display_order=order)
            .returning(Category.id)
        ).scalar_one()
        existing[slug] = category_id
        report.categories_created += 1
    return existing


def _upsert_tags(
    session: Session, records: list[dict[str, Any]], report: ImportReport
) -> dict[str, Any]:
    """Return {slug: tag_id}, creating any tag rows not yet present.

    Distinct tag *names* that happen to slugify to the same value (case or
    punctuation variants) collapse onto one tag row -- the first name seen
    wins for display purposes. Rare enough on this dataset not to warrant a
    separate merge report.
    """
    raw_names: dict[str, str] = {}
    for record in records:
        for name in record["eligibility_json"].get("search_tags") or []:
            raw_names.setdefault(_slugify(name), name)

    existing: dict[str, Any] = {
        row.slug: row.id for row in session.execute(select(Tag.slug, Tag.id))
    }
    for slug, name in raw_names.items():
        if slug in existing:
            continue
        tag_id = session.execute(
            pg_insert(Tag).values(slug=slug, name=name[:80]).returning(Tag.id)
        ).scalar_one()
        existing[slug] = tag_id
        report.tags_created += 1
    return existing


def _fetch_existing_scheme_rows(session: Session) -> dict[str, dict[str, Any]]:
    """A snapshot of every scheme's tracked fields, taken once before this
    run's writes begin -- what compare-before-write diffs against. See
    run_import: fetched after categories/tags are upserted+committed but
    before the write loop starts, so it reflects "the world before this
    run", never a partial view of this run's own progress (each scheme_id
    appears once per source file, so nothing this run writes is ever read
    back into this snapshot).
    """
    columns = (
        Scheme.scheme_id,
        Scheme.slug,
        Scheme.name,
        Scheme.ministry,
        Scheme.category_id,
        Scheme.scheme_type,
        Scheme.jurisdiction,
        Scheme.state_code,
        Scheme.description_short,
        Scheme.needs_review,
        Scheme.raw_eligibility,
        Scheme.verification_status,
    )
    return {
        row.scheme_id: {
            "slug": row.slug,
            "name": row.name,
            "ministry": row.ministry,
            "category_id": row.category_id,
            "scheme_type": row.scheme_type,
            "jurisdiction": row.jurisdiction,
            "state_code": row.state_code,
            "description_short": row.description_short,
            "needs_review": row.needs_review,
            "raw_eligibility": row.raw_eligibility,
            "verification_status": row.verification_status,
        }
        for row in session.execute(select(*columns))
    }


def _stringify_field(
    field_name: str, value: Any, category_slug_by_id: dict[Any, str]
) -> str | None:
    """Human-readable text for one side of a SchemeFieldChange row -- an
    audit trail read directly in a SQL client, not a typed column per
    possible field (see db/models/provenance.py).
    """
    if value is None:
        return None
    if field_name == "category_id":
        return category_slug_by_id.get(value, str(value))
    if isinstance(value, dict):
        return json.dumps(value, sort_keys=True)
    if hasattr(value, "value"):  # a Python Enum member (scheme_type, jurisdiction)
        return str(value.value)
    return str(value)


def _diff_scheme_fields(
    existing: dict[str, Any] | None,
    new_values: dict[str, Any],
    category_slug_by_id: dict[Any, str],
) -> list[tuple[str, str | None, str | None]]:
    """Field-level diff of `new_values` against the live row. Empty for a
    scheme seen for the first time (`existing is None`) -- nothing has
    "changed" yet, there is only an initial value.
    """
    if existing is None:
        return []
    changes = []
    for field_name in _TRACKED_SCHEME_FIELDS:
        old_val = existing.get(field_name)
        new_val = new_values[field_name]
        if old_val == new_val:
            continue
        changes.append(
            (
                field_name,
                _stringify_field(field_name, old_val, category_slug_by_id),
                _stringify_field(field_name, new_val, category_slug_by_id),
            )
        )
    return changes


def _import_scheme(
    session: Session,
    record: dict[str, Any],
    *,
    category_cache: dict[str, Any],
    category_slug_by_id: dict[Any, str],
    tag_cache: dict[str, Any],
    existing_rows: dict[str, dict[str, Any]],
    existing_slugs: dict[str, str],
    used_slugs: set[str],
    import_run_id: Any,
    field_changes: list[dict[str, Any]],
    report: ImportReport,
) -> None:
    scheme_id = record["scheme_id"]
    elig = record.get("eligibility_json") or {}

    category_id = (
        category_cache.get(_slugify(record["category"]))
        if record.get("category")
        else None
    )

    raw_type: str = record.get("scheme_type") or ""
    scheme_type = SCHEME_TYPE_MAP.get(raw_type)
    if scheme_type is None:
        scheme_type = SchemeType.OTHER
        report.unmapped_scheme_types[raw_type] = (
            report.unmapped_scheme_types.get(raw_type, 0) + 1
        )

    existing = existing_rows.get(scheme_id)
    is_new = existing is None

    # Stable across re-imports -- see module docstring.
    slug = (
        _unique_slug(record["name"], used_slugs, report)
        if is_new
        else existing_slugs[scheme_id]
    )

    translation = translate_eligibility(elig)
    new_values: dict[str, Any] = {
        "name": record["name"],
        "ministry": record.get("ministry"),
        "category_id": category_id,
        "scheme_type": scheme_type,
        "jurisdiction": Jurisdiction(record["jurisdiction"]),
        "state_code": record.get("state_code"),
        "description_short": record.get("description_short"),
        "needs_review": translation.scheme_needs_review,
        "raw_eligibility": elig,
    }
    changes = _diff_scheme_fields(existing, new_values, category_slug_by_id)

    # Compare-before-write: a scheme an admin has already confirmed against
    # the official source is never silently overwritten by a later
    # re-import. The diff is still recorded, for review, but nothing is
    # written -- no scalar field and no child table. See module docstring.
    if (
        existing is not None
        and existing["verification_status"] == VerificationStatus.OFFICIALLY_VERIFIED
    ):
        for field_name, old_val, new_val in changes:
            field_changes.append(
                {
                    "scheme_id": scheme_id,
                    "import_run_id": import_run_id,
                    "field_name": field_name,
                    "old_value": old_val,
                    "new_value": new_val,
                    "applied": False,
                }
            )
        report.schemes_held_back_verified += 1
        if changes:
            report.schemes_verified_with_pending_changes += 1
        return

    for field_name, old_val, new_val in changes:
        field_changes.append(
            {
                "scheme_id": scheme_id,
                "import_run_id": import_run_id,
                "field_name": field_name,
                "old_value": old_val,
                "new_value": new_val,
                "applied": True,
            }
        )
    report.field_changes_applied += len(changes)

    session.execute(
        pg_insert(Scheme)
        .values(
            scheme_id=scheme_id,
            slug=slug,
            name=new_values["name"],
            ministry=new_values["ministry"],
            category_id=new_values["category_id"],
            scheme_type=new_values["scheme_type"],
            jurisdiction=new_values["jurisdiction"],
            state_code=new_values["state_code"],
            description_short=new_values["description_short"],
            data_source=DATA_SOURCE,
            needs_review=new_values["needs_review"],
            verification_status=VerificationStatus.UNVERIFIED,
            raw_eligibility=new_values["raw_eligibility"],
            is_active=True,
            last_imported_at=datetime.now(UTC),
        )
        .on_conflict_do_update(
            index_elements=["scheme_id"],
            set_={
                "name": new_values["name"],
                "ministry": new_values["ministry"],
                "category_id": new_values["category_id"],
                "scheme_type": new_values["scheme_type"],
                "jurisdiction": new_values["jurisdiction"],
                "state_code": new_values["state_code"],
                "description_short": new_values["description_short"],
                "data_source": DATA_SOURCE,
                "needs_review": new_values["needs_review"],
                "raw_eligibility": new_values["raw_eligibility"],
                "last_imported_at": datetime.now(UTC),
            },
        )
    )
    if is_new:
        report.schemes_inserted += 1
    else:
        report.schemes_updated += 1
    if translation.scheme_needs_review:
        report.schemes_needing_review += 1
    if not any(r.rule_group.value == "any" for r in translation.rules):
        report.schemes_that_match_nobody += 1
    if not record.get("official_url"):
        report.schemes_missing_official_url += 1

    _reimport_tags(session, scheme_id, elig, tag_cache)
    _reimport_benefits(session, scheme_id, elig, report, is_new=is_new)
    _reimport_documents(session, scheme_id, elig, report, is_new=is_new)
    _reimport_rules(session, scheme_id, translation, report, is_new=is_new)


def _reimport_tags(
    session: Session, scheme_id: str, elig: dict[str, Any], tag_cache: dict[str, Any]
) -> None:
    session.execute(delete(SchemeTag).where(SchemeTag.scheme_id == scheme_id))
    tag_ids = {
        tag_cache[_slugify(name)]
        for name in (elig.get("search_tags") or [])
        if _slugify(name) in tag_cache
    }
    if tag_ids:
        session.execute(
            insert(SchemeTag),
            [{"scheme_id": scheme_id, "tag_id": tag_id} for tag_id in tag_ids],
        )


def _reimport_benefits(
    session: Session,
    scheme_id: str,
    elig: dict[str, Any],
    report: ImportReport,
    *,
    is_new: bool,
) -> None:
    rows = []
    for order, benefit in enumerate(elig.get("benefits") or []):
        amount = benefit.get("amount") or ""
        truncated = len(amount) >= TRUNCATION_LENGTH_THRESHOLD
        rows.append(
            {
                "scheme_id": scheme_id,
                "stage": benefit.get("stage"),
                "amount_text": amount,
                "display_order": order,
                "is_truncated": truncated,
            }
        )
        report.benefits_created += 1
        if truncated:
            report.benefits_truncated += 1

    # Content diff, purely for the report -- delete-then-reinsert below is
    # unconditional either way (module docstring: these rows have no
    # independent identity to diff against for the write itself).
    if not is_new:
        existing_content = {
            (row.stage, row.amount_text)
            for row in session.execute(
                select(SchemeBenefit.stage, SchemeBenefit.amount_text).where(
                    SchemeBenefit.scheme_id == scheme_id
                )
            )
        }
        new_content = {(r["stage"], r["amount_text"]) for r in rows}
        if existing_content != new_content:
            report.schemes_with_benefit_changes += 1

    session.execute(delete(SchemeBenefit).where(SchemeBenefit.scheme_id == scheme_id))
    if rows:
        session.execute(insert(SchemeBenefit), rows)


def _reimport_documents(
    session: Session,
    scheme_id: str,
    elig: dict[str, Any],
    report: ImportReport,
    *,
    is_new: bool,
) -> None:
    rows = []
    order = 0
    for blob in elig.get("documents_required") or []:
        result = split_documents(blob)
        report.documents_split_by_rule[result.rule] = (
            report.documents_split_by_rule.get(result.rule, 0) + 1
        )
        if result.needs_review:
            report.documents_needing_review += 1
        for part in result.parts:
            rows.append(
                {
                    "scheme_id": scheme_id,
                    "name": part,
                    "display_order": order,
                    "needs_review": result.needs_review,
                }
            )
            order += 1
            report.documents_created += 1

    if not is_new:
        existing_content = {
            (row.name, row.needs_review)
            for row in session.execute(
                select(SchemeDocument.name, SchemeDocument.needs_review).where(
                    SchemeDocument.scheme_id == scheme_id
                )
            )
        }
        new_content = {(r["name"], r["needs_review"]) for r in rows}
        if existing_content != new_content:
            report.schemes_with_document_changes += 1

    session.execute(delete(SchemeDocument).where(SchemeDocument.scheme_id == scheme_id))
    if rows:
        session.execute(insert(SchemeDocument), rows)


def _normalize_numeric(value: Any) -> float | None:
    """Numeric rule values round-trip through Postgres `Numeric` as
    `decimal.Decimal`, while a freshly translated rule carries a plain
    `float` -- comparing the two directly would report a spurious change on
    every single numeric rule, every run. Both sides go through this before
    comparison in `_reimport_rules`.
    """
    return float(value) if value is not None else None


def _reimport_rules(
    session: Session,
    scheme_id: str,
    translation: TranslationResult,
    report: ImportReport,
    *,
    is_new: bool,
) -> None:
    rows = []
    for rule in translation.rules:
        rows.append(
            {
                "scheme_id": scheme_id,
                "rule_group": rule.rule_group,
                "attribute_key": rule.attribute_key,
                "operator": rule.operator,
                "value_bool": rule.value_bool,
                "value_numeric": rule.value_numeric,
                "value_text": rule.value_text,
                "label": rule.label,
                "label_hi": rule.label_hi,
            }
        )
        report.rules_created += 1
        if rule.needs_review:
            report.rules_needing_review += 1

    if not is_new:
        existing_content = {
            (
                row.rule_group,
                row.attribute_key,
                row.operator,
                row.value_bool,
                _normalize_numeric(row.value_numeric),
                row.value_text,
            )
            for row in session.execute(
                select(
                    SchemeEligibilityRule.rule_group,
                    SchemeEligibilityRule.attribute_key,
                    SchemeEligibilityRule.operator,
                    SchemeEligibilityRule.value_bool,
                    SchemeEligibilityRule.value_numeric,
                    SchemeEligibilityRule.value_text,
                ).where(SchemeEligibilityRule.scheme_id == scheme_id)
            )
        }
        new_content = {
            (
                r["rule_group"],
                r["attribute_key"],
                r["operator"],
                r["value_bool"],
                _normalize_numeric(r["value_numeric"]),
                r["value_text"],
            )
            for r in rows
        }
        if existing_content != new_content:
            report.schemes_with_rule_changes += 1

    session.execute(
        delete(SchemeEligibilityRule).where(SchemeEligibilityRule.scheme_id == scheme_id)
    )
    if rows:
        session.execute(insert(SchemeEligibilityRule), rows)


def run_import(
    session: Session, path: Path, *, batch_size: int = DEFAULT_BATCH_SIZE
) -> ImportReport:
    """Import every scheme in `path` into the database. Safe to run repeatedly,
    including re-running after a partial failure (see DEFAULT_BATCH_SIZE above):
    a batch that fails -- a real data error or a dropped connection -- rolls
    back only itself and re-raises, so the run stops loudly rather than
    silently skipping the scheme. Every already-committed batch survives.
    Re-running afterwards is the resume mechanism: already-committed schemes
    are harmlessly re-upserted (reported as updated, not inserted), and
    whatever didn't finish is processed for the first time.

    Every call is recorded as one ImportRun row, and every scheme field that
    differs from the live row as one SchemeFieldChange row -- see module
    docstring.
    """
    report = ImportReport()
    file_bytes = Path(path).read_bytes()
    records: list[dict[str, Any]] = json.loads(file_bytes.decode("utf-8"))
    report.schemes_seen = len(records)

    import_run_id = session.execute(
        pg_insert(ImportRun)
        .values(
            source_label=str(path),
            source_file_hash=hashlib.sha256(file_bytes).hexdigest(),
        )
        .returning(ImportRun.id)
    ).scalar_one()

    category_cache = _upsert_categories(session, records, report)
    tag_cache = _upsert_tags(session, records, report)
    session.commit()

    category_slug_by_id = {
        category_id: slug for slug, category_id in category_cache.items()
    }

    # A snapshot of the world before this run's writes begin -- see
    # _fetch_existing_scheme_rows.
    existing_rows = _fetch_existing_scheme_rows(session)
    existing_slugs = {sid: row["slug"] for sid, row in existing_rows.items()}
    used_slugs = set(existing_slugs.values())

    total = len(records)
    for start in range(0, total, batch_size):
        batch = records[start : start + batch_size]
        field_changes: list[dict[str, Any]] = []
        try:
            for record in batch:
                _import_scheme(
                    session,
                    record,
                    category_cache=category_cache,
                    category_slug_by_id=category_slug_by_id,
                    tag_cache=tag_cache,
                    existing_rows=existing_rows,
                    existing_slugs=existing_slugs,
                    used_slugs=used_slugs,
                    import_run_id=import_run_id,
                    field_changes=field_changes,
                    report=report,
                )
            if field_changes:
                session.execute(insert(SchemeFieldChange), field_changes)
            session.commit()
        except Exception:
            session.rollback()
            raise
        processed = min(start + batch_size, total)
        print(f"  {processed}/{total} schemes imported")

    # A whole-table snapshot, not scoped to this run's own writes -- see
    # ImportReport.schemes_deadline_passed_still_active's own docstring.
    report.schemes_deadline_passed_still_active = session.execute(
        select(func.count())
        .select_from(Scheme)
        .where(Scheme.application_deadline < date.today())
        .where(Scheme.is_active.is_(True))
    ).scalar_one()

    session.execute(
        update(ImportRun)
        .where(ImportRun.id == import_run_id)
        .values(finished_at=datetime.now(UTC), report=asdict(report))
    )
    session.commit()

    return report
