"""Tests for the importer pipeline.

Real PostgreSQL, real schemes.json -- schema tests already establish the
project's position that testing SQL behaviour against a mock proves
nothing, and idempotency in particular is a database-level property
(unique constraints, ON CONFLICT) that a fake session cannot exercise
honestly.

Idempotency is the single most valuable test here (BUILD_PLAN.md, Week 1):
importing twice must produce identical row counts.
"""

from __future__ import annotations

from pathlib import Path

import pytest
from sqlalchemy import create_engine, func, select, text
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
from schememedia.importer.pipeline import run_import, sync_database_url
from tests.conftest import database_is_reachable, resolve_test_database_url

TEST_DATABASE_URL = resolve_test_database_url()
DATABASE_AVAILABLE = database_is_reachable(TEST_DATABASE_URL)

REPO_ROOT = Path(__file__).resolve().parents[3]
SCHEMES_JSON = REPO_ROOT / "schemes.json"

pytestmark = [
    pytest.mark.skipif(
        not DATABASE_AVAILABLE, reason="PostgreSQL is not reachable; see README section 1"
    ),
    pytest.mark.skipif(not SCHEMES_JSON.exists(), reason=f"{SCHEMES_JSON} not present"),
]


def _row_counts(session: Session) -> dict[str, int]:
    return {
        "schemes": session.scalar(select(func.count()).select_from(Scheme)) or 0,
        "categories": session.scalar(select(func.count()).select_from(Category)) or 0,
        "tags": session.scalar(select(func.count()).select_from(Tag)) or 0,
        "scheme_tags": session.scalar(select(func.count()).select_from(SchemeTag)) or 0,
        "benefits": session.scalar(select(func.count()).select_from(SchemeBenefit)) or 0,
        "documents": session.scalar(select(func.count()).select_from(SchemeDocument))
        or 0,
        "rules": session.scalar(select(func.count()).select_from(SchemeEligibilityRule))
        or 0,
    }


@pytest.fixture(scope="module")
def imported_twice():
    """Run the real importer against the real dataset, twice, once for the module.

    Session-scoped truncation + two imports is expensive (~1,000 records x
    the full translate/split pipeline) so it runs once and every test in
    this module asserts against the shared result, rather than each test
    re-importing.
    """
    engine = create_engine(sync_database_url(TEST_DATABASE_URL), future=True)
    with Session(engine) as session:
        session.execute(
            text(
                "TRUNCATE schemes, categories, tags, scheme_tags, "
                "scheme_benefits, scheme_documents, scheme_eligibility_rules "
                "CASCADE"
            )
        )
        session.commit()

        first_report = run_import(session, SCHEMES_JSON)
        session.commit()
        first_counts = _row_counts(session)

        second_report = run_import(session, SCHEMES_JSON)
        session.commit()
        second_counts = _row_counts(session)

        yield session, first_report, first_counts, second_report, second_counts

        session.execute(
            text(
                "TRUNCATE schemes, categories, tags, scheme_tags, "
                "scheme_benefits, scheme_documents, scheme_eligibility_rules "
                "CASCADE"
            )
        )
        session.commit()
    engine.dispose()


# ---------------------------------------------------------------------------
# Idempotency -- the load-bearing test
# ---------------------------------------------------------------------------


def test_row_counts_are_identical_after_a_second_import(imported_twice) -> None:
    _session, _r1, first_counts, _r2, second_counts = imported_twice
    assert first_counts == second_counts


def test_second_import_inserts_nothing_new(imported_twice) -> None:
    _session, _r1, _c1, second_report, _c2 = imported_twice
    assert second_report.schemes_inserted == 0
    assert second_report.schemes_updated == 1000
    assert second_report.categories_created == 0
    assert second_report.tags_created == 0
    assert second_report.slug_collisions_resolved == 0


def test_scheme_slugs_are_stable_across_reimport(imported_twice) -> None:
    """A re-import must not change a scheme's URL out from under a bookmark."""
    session, _r1, _c1, _r2, _c2 = imported_twice
    slugs_now = dict(session.execute(select(Scheme.scheme_id, Scheme.slug)).all())
    # Re-run once more and confirm slugs are byte-identical to what a prior
    # test already observed via the fixture's two imports.
    run_import(session, SCHEMES_JSON)
    session.commit()
    slugs_after = dict(session.execute(select(Scheme.scheme_id, Scheme.slug)).all())
    assert slugs_now == slugs_after


# ---------------------------------------------------------------------------
# Measured against the real dataset -- see HANDOFF.md section 5 and 9
# ---------------------------------------------------------------------------


def test_all_1000_schemes_import(imported_twice) -> None:
    _session, first_report, _c1, _r2, _c2 = imported_twice
    assert first_report.schemes_seen == 1000
    assert first_report.schemes_inserted == 1000


def test_eleven_categories_created(imported_twice) -> None:
    _session, first_report, _c1, _r2, _c2 = imported_twice
    assert first_report.categories_created == 11


def test_one_benefit_row_per_scheme(imported_twice) -> None:
    _session, first_report, _c1, _r2, _c2 = imported_twice
    assert first_report.benefits_created == 1000


def test_truncated_benefits_match_measured_count(imported_twice) -> None:
    """627 blobs at exactly 200 chars + 6 more at 195-199 -- 633 total."""
    _session, first_report, _c1, _r2, _c2 = imported_twice
    assert first_report.benefits_truncated == 633


def test_documents_split_matches_measured_distribution(imported_twice) -> None:
    _session, first_report, _c1, _r2, _c2 = imported_twice
    assert first_report.documents_split_by_rule == {
        "numbered": 123,
        "bullet": 3,
        "semicolon": 10,
        "sentence": 609,
        "unsplit": 252,
    }


def test_exactly_one_slug_collision_is_resolved(imported_twice) -> None:
    """REAL: two schemes both named 'Establishment of Goat Unit (10 +1)'."""
    _session, first_report, _c1, _r2, _c2 = imported_twice
    assert first_report.slug_collisions_resolved == 1


def test_eighty_schemes_would_match_nobody_under_strict_or(imported_twice) -> None:
    _session, first_report, _c1, _r2, _c2 = imported_twice
    assert first_report.schemes_that_match_nobody == 80


def test_unmapped_scheme_types_are_policy_and_employment(imported_twice) -> None:
    """No enum value fits these; both counted rather than silently guessed."""
    _session, first_report, _c1, _r2, _c2 = imported_twice
    assert first_report.unmapped_scheme_types == {"policy": 158, "employment": 54}


# ---------------------------------------------------------------------------
# Correctness in context -- not just unit-level translator/splitter behaviour
# ---------------------------------------------------------------------------


def test_a_known_scheme_gets_the_expected_rules(imported_twice) -> None:
    """REAL: SCH_1F47743B -- sc_st/ews/lig, no must_match_all rules."""
    session, _r1, _c1, _r2, _c2 = imported_twice
    rows = session.execute(
        select(
            SchemeEligibilityRule.rule_group,
            SchemeEligibilityRule.attribute_key,
        ).where(SchemeEligibilityRule.scheme_id == "SCH_1F47743B")
    ).all()
    keys = {(group.value, attr) for group, attr in rows}
    assert keys == {("any", "is_sc_st"), ("any", "is_ews"), ("any", "is_lig")}


def test_contradictory_govt_employee_schemes_are_flagged(imported_twice) -> None:
    """REAL: SCH_38603FF1, SCH_EBE5D9CA, SCH_DF093CC3."""
    session, _r1, _c1, _r2, _c2 = imported_twice
    for scheme_id in ("SCH_38603FF1", "SCH_EBE5D9CA", "SCH_DF093CC3"):
        needs_review = session.scalar(
            select(Scheme.needs_review).where(Scheme.scheme_id == scheme_id)
        )
        assert needs_review is True
        rules = session.execute(
            select(SchemeEligibilityRule.attribute_key).where(
                SchemeEligibilityRule.scheme_id == scheme_id,
                SchemeEligibilityRule.attribute_key == "is_govt_employee",
            )
        ).all()
        assert rules == []


def test_raw_eligibility_is_preserved_verbatim(imported_twice) -> None:
    session, _r1, _c1, _r2, _c2 = imported_twice
    raw = session.scalar(
        select(Scheme.raw_eligibility).where(Scheme.scheme_id == "SCH_1F47743B")
    )
    assert raw["must_match_one_of"]["is_sc_st"] is True
    assert raw["search_tags"] == ["Sports", "Journalism", "Award"]


def test_new_verification_status_defaults_to_unverified(imported_twice) -> None:
    session, _r1, _c1, _r2, _c2 = imported_twice
    status = session.scalar(
        select(Scheme.verification_status).where(Scheme.scheme_id == "SCH_1F47743B")
    )
    assert status.value == "unverified"
