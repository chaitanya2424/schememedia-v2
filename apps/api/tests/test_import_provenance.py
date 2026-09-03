"""Tests for the importer's provenance layer (ImportRun, SchemeFieldChange,
Scheme.last_imported_at) -- see importer/pipeline.py's module docstring.

Real PostgreSQL throughout, same reasoning as test_import.py: idempotency
and compare-before-write are both database-level properties (ON CONFLICT,
an actual second SELECT reading back what a prior INSERT wrote) a mocked
session cannot exercise honestly.

Six things this file proves, matching the hardening design's own list:
  * imports are recorded (ImportRun)
  * field changes are captured (SchemeFieldChange, applied=True)
  * verified records are not silently overwritten (applied=False, live row
    untouched, child data untouched)
  * unverified records continue to import normally
  * re-import remains idempotent (now including the provenance tables
    themselves -- no runaway growth on an unchanged file)
  * existing eligibility/search behaviour is unchanged (a smoke check here;
    the authoritative proof is the full suite -- test_eligibility_matcher.py
    and test_search.py -- passing unmodified)
"""

from __future__ import annotations

import copy
import json
from collections.abc import Generator
from pathlib import Path

import pytest
from sqlalchemy import create_engine, func, select, text, update
from sqlalchemy.orm import Session

from schememedia.db.models import (
    ImportRun,
    Scheme,
    SchemeBenefit,
    SchemeDocument,
    SchemeEligibilityRule,
    SchemeFieldChange,
)
from schememedia.db.models.enums import VerificationStatus
from schememedia.importer.pipeline import run_import, sync_database_url
from tests.conftest import database_is_reachable, resolve_test_database_url

TEST_DATABASE_URL = resolve_test_database_url()
DATABASE_AVAILABLE = database_is_reachable(TEST_DATABASE_URL)

REPO_ROOT = Path(__file__).resolve().parents[3]
SCHEMES_JSON = REPO_ROOT / "schemes.json"
SMALL_FIXTURE = Path(__file__).parent / "fixtures" / "search_schemes.json"

_TRUNCATE_ALL = text(
    "TRUNCATE schemes, categories, tags, scheme_tags, "
    "scheme_benefits, scheme_documents, scheme_eligibility_rules, "
    "import_runs, scheme_field_changes CASCADE"
)

pytestmark = [
    pytest.mark.skipif(
        not DATABASE_AVAILABLE, reason="PostgreSQL is not reachable; see README section 1"
    ),
    pytest.mark.skipif(not SCHEMES_JSON.exists(), reason=f"{SCHEMES_JSON} not present"),
]


@pytest.fixture
def truncated_session() -> Generator[Session, None, None]:
    engine = create_engine(sync_database_url(TEST_DATABASE_URL), future=True)
    with Session(engine) as session:
        session.execute(_TRUNCATE_ALL)
        session.commit()
        yield session
        session.execute(_TRUNCATE_ALL)
        session.commit()
    engine.dispose()


def _load_fixture() -> list[dict]:
    return json.loads(SMALL_FIXTURE.read_text(encoding="utf-8"))


def _write_modified_fixture(
    tmp_path: Path, scheme_id: str, **field_overrides: object
) -> Path:
    """A copy of the small fixture with one record's fields overridden --
    stands in for "the source data changed since the last import" without
    needing a second real fixture file on disk.
    """
    records = _load_fixture()
    target = next(r for r in records if r["scheme_id"] == scheme_id)
    target.update(field_overrides)
    out = tmp_path / "modified_schemes.json"
    out.write_text(json.dumps(records), encoding="utf-8")
    return out


FIRST_SCHEME_ID = "SCH_08134B86"  # the small fixture's first record, see conftest above


# ---------------------------------------------------------------------------
# Imports are recorded
# ---------------------------------------------------------------------------


def test_run_import_creates_one_import_run_row(truncated_session: Session) -> None:
    run_import(truncated_session, SMALL_FIXTURE)

    runs = truncated_session.execute(select(ImportRun)).scalars().all()
    assert len(runs) == 1
    run = runs[0]
    assert run.source_label == str(SMALL_FIXTURE)
    assert run.source_file_hash is not None
    assert len(run.source_file_hash) == 64  # sha256 hex digest
    assert run.started_at is not None
    assert run.finished_at is not None
    assert run.finished_at >= run.started_at
    assert run.report is not None
    assert run.report["schemes_seen"] == 8


def test_two_runs_create_two_import_run_rows(truncated_session: Session) -> None:
    run_import(truncated_session, SMALL_FIXTURE)
    run_import(truncated_session, SMALL_FIXTURE)

    count = truncated_session.scalar(select(func.count()).select_from(ImportRun))
    assert count == 2


def test_last_imported_at_is_set_on_every_import(truncated_session: Session) -> None:
    run_import(truncated_session, SMALL_FIXTURE)
    last_imported_at = truncated_session.scalar(
        select(Scheme.last_imported_at).where(Scheme.scheme_id == FIRST_SCHEME_ID)
    )
    assert last_imported_at is not None


def test_last_imported_at_advances_on_reimport(truncated_session: Session) -> None:
    run_import(truncated_session, SMALL_FIXTURE)
    first = truncated_session.scalar(
        select(Scheme.last_imported_at).where(Scheme.scheme_id == FIRST_SCHEME_ID)
    )

    run_import(truncated_session, SMALL_FIXTURE)
    second = truncated_session.scalar(
        select(Scheme.last_imported_at).where(Scheme.scheme_id == FIRST_SCHEME_ID)
    )
    assert second >= first


# ---------------------------------------------------------------------------
# Field changes are captured
# ---------------------------------------------------------------------------


def test_unchanged_reimport_records_zero_field_changes(
    truncated_session: Session,
) -> None:
    run_import(truncated_session, SMALL_FIXTURE)
    report = run_import(truncated_session, SMALL_FIXTURE)  # identical file, byte for byte

    assert report.field_changes_applied == 0
    count = truncated_session.scalar(select(func.count()).select_from(SchemeFieldChange))
    assert count == 0


def test_a_changed_field_is_captured_with_old_and_new_values(
    truncated_session: Session, tmp_path: Path
) -> None:
    run_import(truncated_session, SMALL_FIXTURE)
    original = next(r for r in _load_fixture() if r["scheme_id"] == FIRST_SCHEME_ID)

    modified = _write_modified_fixture(
        tmp_path, FIRST_SCHEME_ID, description_short="A brand new description."
    )
    report = run_import(truncated_session, modified)

    assert report.field_changes_applied >= 1
    change = truncated_session.execute(
        select(SchemeFieldChange).where(
            SchemeFieldChange.scheme_id == FIRST_SCHEME_ID,
            SchemeFieldChange.field_name == "description_short",
        )
    ).scalar_one()
    assert change.applied is True
    assert change.old_value == original["description_short"]
    assert change.new_value == "A brand new description."

    # And it was actually applied to the live row -- not just logged.
    live_value = truncated_session.scalar(
        select(Scheme.description_short).where(Scheme.scheme_id == FIRST_SCHEME_ID)
    )
    assert live_value == "A brand new description."


def test_multiple_changed_fields_each_get_their_own_row(
    truncated_session: Session, tmp_path: Path
) -> None:
    run_import(truncated_session, SMALL_FIXTURE)
    modified = _write_modified_fixture(
        tmp_path,
        FIRST_SCHEME_ID,
        description_short="Changed description.",
        ministry="Ministry of Something Else",
    )
    run_import(truncated_session, modified)

    changed_fields = set(
        truncated_session.execute(
            select(SchemeFieldChange.field_name).where(
                SchemeFieldChange.scheme_id == FIRST_SCHEME_ID
            )
        ).scalars()
    )
    assert changed_fields == {"description_short", "ministry"}


def test_an_unrelated_scheme_gets_no_field_change_row(
    truncated_session: Session, tmp_path: Path
) -> None:
    run_import(truncated_session, SMALL_FIXTURE)
    modified = _write_modified_fixture(
        tmp_path, FIRST_SCHEME_ID, ministry="Ministry of Something Else"
    )
    run_import(truncated_session, modified)

    other_scheme_ids = {
        r["scheme_id"] for r in _load_fixture() if r["scheme_id"] != FIRST_SCHEME_ID
    }
    changed_scheme_ids = set(
        truncated_session.execute(select(SchemeFieldChange.scheme_id)).scalars()
    )
    assert changed_scheme_ids == {FIRST_SCHEME_ID}
    assert changed_scheme_ids.isdisjoint(other_scheme_ids)


# ---------------------------------------------------------------------------
# Verified records are not silently overwritten
# ---------------------------------------------------------------------------


def test_officially_verified_scheme_is_not_overwritten(
    truncated_session: Session, tmp_path: Path
) -> None:
    run_import(truncated_session, SMALL_FIXTURE)
    truncated_session.execute(
        update(Scheme)
        .where(Scheme.scheme_id == FIRST_SCHEME_ID)
        .values(verification_status=VerificationStatus.OFFICIALLY_VERIFIED)
    )
    truncated_session.commit()

    modified = _write_modified_fixture(
        tmp_path, FIRST_SCHEME_ID, description_short="An attempted silent overwrite."
    )
    report = run_import(truncated_session, modified)

    live_value = truncated_session.scalar(
        select(Scheme.description_short).where(Scheme.scheme_id == FIRST_SCHEME_ID)
    )
    assert live_value != "An attempted silent overwrite."  # untouched

    status = truncated_session.scalar(
        select(Scheme.verification_status).where(Scheme.scheme_id == FIRST_SCHEME_ID)
    )
    assert status == VerificationStatus.OFFICIALLY_VERIFIED  # also untouched

    assert report.schemes_held_back_verified == 1
    assert report.schemes_verified_with_pending_changes == 1

    change = truncated_session.execute(
        select(SchemeFieldChange).where(
            SchemeFieldChange.scheme_id == FIRST_SCHEME_ID,
            SchemeFieldChange.field_name == "description_short",
        )
    ).scalar_one()
    assert change.applied is False
    assert change.new_value == "An attempted silent overwrite."


def test_officially_verified_schemes_child_data_is_not_overwritten(
    truncated_session: Session, tmp_path: Path
) -> None:
    """Not just scalar fields -- benefits/documents/rules stay untouched too."""
    run_import(truncated_session, SMALL_FIXTURE)
    truncated_session.execute(
        update(Scheme)
        .where(Scheme.scheme_id == FIRST_SCHEME_ID)
        .values(verification_status=VerificationStatus.OFFICIALLY_VERIFIED)
    )
    truncated_session.commit()

    before_benefit = (
        truncated_session.execute(
            select(SchemeBenefit.amount_text).where(
                SchemeBenefit.scheme_id == FIRST_SCHEME_ID
            )
        )
        .scalars()
        .all()
    )
    before_documents = (
        truncated_session.execute(
            select(SchemeDocument.name).where(SchemeDocument.scheme_id == FIRST_SCHEME_ID)
        )
        .scalars()
        .all()
    )
    before_rules = (
        truncated_session.execute(
            select(SchemeEligibilityRule.attribute_key).where(
                SchemeEligibilityRule.scheme_id == FIRST_SCHEME_ID
            )
        )
        .scalars()
        .all()
    )

    records = _load_fixture()
    target = next(r for r in records if r["scheme_id"] == FIRST_SCHEME_ID)
    elig = copy.deepcopy(target["eligibility_json"])
    elig["benefits"] = [{"stage": "Different Stage", "amount": "A different amount"}]
    target["eligibility_json"] = elig
    out = tmp_path / "modified_child_data.json"
    out.write_text(json.dumps(records), encoding="utf-8")

    run_import(truncated_session, out)

    after_benefit = (
        truncated_session.execute(
            select(SchemeBenefit.amount_text).where(
                SchemeBenefit.scheme_id == FIRST_SCHEME_ID
            )
        )
        .scalars()
        .all()
    )
    after_documents = (
        truncated_session.execute(
            select(SchemeDocument.name).where(SchemeDocument.scheme_id == FIRST_SCHEME_ID)
        )
        .scalars()
        .all()
    )
    after_rules = (
        truncated_session.execute(
            select(SchemeEligibilityRule.attribute_key).where(
                SchemeEligibilityRule.scheme_id == FIRST_SCHEME_ID
            )
        )
        .scalars()
        .all()
    )

    assert after_benefit == before_benefit
    assert after_documents == before_documents
    assert after_rules == before_rules


def test_verified_scheme_with_no_actual_change_is_not_counted_as_pending(
    truncated_session: Session,
) -> None:
    """Held back is about *protection*, not every verified scheme touched
    by a run -- one with no real diff shouldn't show up asking for review.
    """
    run_import(truncated_session, SMALL_FIXTURE)
    truncated_session.execute(
        update(Scheme)
        .where(Scheme.scheme_id == FIRST_SCHEME_ID)
        .values(verification_status=VerificationStatus.OFFICIALLY_VERIFIED)
    )
    truncated_session.commit()

    report = run_import(truncated_session, SMALL_FIXTURE)  # unchanged file

    assert report.schemes_held_back_verified == 1
    assert report.schemes_verified_with_pending_changes == 0
    count = truncated_session.scalar(select(func.count()).select_from(SchemeFieldChange))
    assert count == 0


# ---------------------------------------------------------------------------
# Unverified records continue to import normally
# ---------------------------------------------------------------------------


def test_unverified_scheme_is_updated_normally(
    truncated_session: Session, tmp_path: Path
) -> None:
    run_import(truncated_session, SMALL_FIXTURE)
    status = truncated_session.scalar(
        select(Scheme.verification_status).where(Scheme.scheme_id == FIRST_SCHEME_ID)
    )
    assert status == VerificationStatus.UNVERIFIED  # the importer's own default

    modified = _write_modified_fixture(
        tmp_path, FIRST_SCHEME_ID, description_short="A perfectly normal update."
    )
    report = run_import(truncated_session, modified)

    live_value = truncated_session.scalar(
        select(Scheme.description_short).where(Scheme.scheme_id == FIRST_SCHEME_ID)
    )
    assert live_value == "A perfectly normal update."
    assert report.schemes_held_back_verified == 0
    # Verification status itself is never touched by a normal update either
    # -- unrelated to compare-before-write, this has always been true (see
    # _import_scheme's on_conflict_do_update set_, which never lists
    # verification_status).
    status_after = truncated_session.scalar(
        select(Scheme.verification_status).where(Scheme.scheme_id == FIRST_SCHEME_ID)
    )
    assert status_after == VerificationStatus.UNVERIFIED


def test_source_provided_scheme_is_also_updated_normally(
    truncated_session: Session, tmp_path: Path
) -> None:
    """Only officially_verified is protected -- source_provided is not a
    confirmation, see VerificationStatus's own docstring.
    """
    run_import(truncated_session, SMALL_FIXTURE)
    truncated_session.execute(
        update(Scheme)
        .where(Scheme.scheme_id == FIRST_SCHEME_ID)
        .values(verification_status=VerificationStatus.SOURCE_PROVIDED)
    )
    truncated_session.commit()

    modified = _write_modified_fixture(
        tmp_path, FIRST_SCHEME_ID, description_short="Updated despite source_provided."
    )
    run_import(truncated_session, modified)

    live_value = truncated_session.scalar(
        select(Scheme.description_short).where(Scheme.scheme_id == FIRST_SCHEME_ID)
    )
    assert live_value == "Updated despite source_provided."


# ---------------------------------------------------------------------------
# Re-import remains idempotent
# ---------------------------------------------------------------------------


def test_reimporting_an_unchanged_file_leaves_row_counts_identical(
    truncated_session: Session,
) -> None:
    run_import(truncated_session, SMALL_FIXTURE)
    first_counts = {
        "schemes": truncated_session.scalar(select(func.count()).select_from(Scheme)),
        "benefits": truncated_session.scalar(
            select(func.count()).select_from(SchemeBenefit)
        ),
        "documents": truncated_session.scalar(
            select(func.count()).select_from(SchemeDocument)
        ),
        "rules": truncated_session.scalar(
            select(func.count()).select_from(SchemeEligibilityRule)
        ),
    }

    run_import(truncated_session, SMALL_FIXTURE)
    second_counts = {
        "schemes": truncated_session.scalar(select(func.count()).select_from(Scheme)),
        "benefits": truncated_session.scalar(
            select(func.count()).select_from(SchemeBenefit)
        ),
        "documents": truncated_session.scalar(
            select(func.count()).select_from(SchemeDocument)
        ),
        "rules": truncated_session.scalar(
            select(func.count()).select_from(SchemeEligibilityRule)
        ),
    }

    assert first_counts == second_counts


def test_reimporting_an_unchanged_file_reports_zero_child_changes(
    truncated_session: Session,
) -> None:
    run_import(truncated_session, SMALL_FIXTURE)
    report = run_import(truncated_session, SMALL_FIXTURE)

    assert report.schemes_with_benefit_changes == 0
    assert report.schemes_with_document_changes == 0
    assert report.schemes_with_rule_changes == 0


def test_changed_child_data_is_detected_and_counted(
    truncated_session: Session, tmp_path: Path
) -> None:
    run_import(truncated_session, SMALL_FIXTURE)

    records = _load_fixture()
    target = next(r for r in records if r["scheme_id"] == FIRST_SCHEME_ID)
    elig = copy.deepcopy(target["eligibility_json"])
    elig["benefits"] = [{"stage": "New Stage", "amount": "A new amount entirely"}]
    target["eligibility_json"] = elig
    out = tmp_path / "changed_benefits.json"
    out.write_text(json.dumps(records), encoding="utf-8")

    report = run_import(truncated_session, out)

    assert report.schemes_with_benefit_changes == 1
    amount = truncated_session.scalar(
        select(SchemeBenefit.amount_text).where(
            SchemeBenefit.scheme_id == FIRST_SCHEME_ID
        )
    )
    assert amount == "A new amount entirely"


# ---------------------------------------------------------------------------
# Existing eligibility/search behaviour is unchanged (smoke check -- the
# authoritative proof is test_eligibility_matcher.py / test_search.py
# passing unmodified, see module docstring)
# ---------------------------------------------------------------------------


def test_a_known_scheme_still_gets_its_expected_rules(truncated_session: Session) -> None:
    """Same assertion test_import.py's imported_twice-based test makes,
    against the real dataset -- here on the small fixture, to prove the
    provenance changes didn't alter what _reimport_rules actually writes.
    """
    run_import(truncated_session, SMALL_FIXTURE)
    rows = truncated_session.execute(
        select(
            SchemeEligibilityRule.rule_group,
            SchemeEligibilityRule.attribute_key,
        ).where(SchemeEligibilityRule.scheme_id == FIRST_SCHEME_ID)
    ).all()
    keys = {(group.value, attr) for group, attr in rows}
    assert keys == {("any", "is_divyang"), ("any", "is_lig"), ("any", "annual_income")}
