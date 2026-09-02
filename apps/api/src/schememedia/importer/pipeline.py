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
    run. Simpler than diffing, and correct: these rows have no independent
    identity a caller could hold onto across a re-import.

Sync SQLAlchemy throughout -- this is a batch job, not request-serving code,
so it doesn't need the app's async engine (see sync_database_url below).
"""

from __future__ import annotations

import json
import re
import unicodedata
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from sqlalchemy import delete, insert, select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.orm import Session

from schememedia.db.models import (
    Category,
    Scheme,
    SchemeBenefit,
    SchemeDocument,
    SchemeEligibilityRule,
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
    """Printed at the end of every import run -- see HANDOFF.md section 9."""

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


def _import_scheme(
    session: Session,
    record: dict[str, Any],
    *,
    category_cache: dict[str, Any],
    tag_cache: dict[str, Any],
    existing_slugs: dict[str, str],
    used_slugs: set[str],
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

    # Stable across re-imports -- see module docstring.
    if scheme_id in existing_slugs:
        slug = existing_slugs[scheme_id]
    else:
        slug = _unique_slug(record["name"], used_slugs, report)

    translation = translate_eligibility(elig)

    is_new = scheme_id not in existing_slugs
    session.execute(
        pg_insert(Scheme)
        .values(
            scheme_id=scheme_id,
            slug=slug,
            name=record["name"],
            ministry=record.get("ministry"),
            category_id=category_id,
            scheme_type=scheme_type,
            jurisdiction=Jurisdiction(record["jurisdiction"]),
            state_code=record.get("state_code"),
            description_short=record.get("description_short"),
            data_source=DATA_SOURCE,
            needs_review=translation.scheme_needs_review,
            verification_status=VerificationStatus.UNVERIFIED,
            raw_eligibility=elig,
            is_active=True,
        )
        .on_conflict_do_update(
            index_elements=["scheme_id"],
            set_={
                "name": record["name"],
                "ministry": record.get("ministry"),
                "category_id": category_id,
                "scheme_type": scheme_type,
                "jurisdiction": Jurisdiction(record["jurisdiction"]),
                "state_code": record.get("state_code"),
                "description_short": record.get("description_short"),
                "data_source": DATA_SOURCE,
                "needs_review": translation.scheme_needs_review,
                "raw_eligibility": elig,
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
    _reimport_benefits(session, scheme_id, elig, report)
    _reimport_documents(session, scheme_id, elig, report)
    _reimport_rules(session, scheme_id, translation, report)


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
    session: Session, scheme_id: str, elig: dict[str, Any], report: ImportReport
) -> None:
    session.execute(delete(SchemeBenefit).where(SchemeBenefit.scheme_id == scheme_id))
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
    if rows:
        session.execute(insert(SchemeBenefit), rows)


def _reimport_documents(
    session: Session, scheme_id: str, elig: dict[str, Any], report: ImportReport
) -> None:
    session.execute(delete(SchemeDocument).where(SchemeDocument.scheme_id == scheme_id))
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
    if rows:
        session.execute(insert(SchemeDocument), rows)


def _reimport_rules(
    session: Session, scheme_id: str, translation: TranslationResult, report: ImportReport
) -> None:
    session.execute(
        delete(SchemeEligibilityRule).where(SchemeEligibilityRule.scheme_id == scheme_id)
    )
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
    if rows:
        session.execute(insert(SchemeEligibilityRule), rows)


def run_import(session: Session, path: Path) -> ImportReport:
    """Import every scheme in `path` into the database. Safe to run repeatedly."""
    report = ImportReport()
    records: list[dict[str, Any]] = json.loads(Path(path).read_text(encoding="utf-8"))
    report.schemes_seen = len(records)

    category_cache = _upsert_categories(session, records, report)
    tag_cache = _upsert_tags(session, records, report)

    existing_slugs: dict[str, str] = {
        row.scheme_id: row.slug
        for row in session.execute(select(Scheme.scheme_id, Scheme.slug))
    }
    used_slugs = set(existing_slugs.values())

    for record in records:
        _import_scheme(
            session,
            record,
            category_cache=category_cache,
            tag_cache=tag_cache,
            existing_slugs=existing_slugs,
            used_slugs=used_slugs,
            report=report,
        )

    session.flush()
    return report
