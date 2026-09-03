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

from collections.abc import Generator
from pathlib import Path
from unittest.mock import patch

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
from schememedia.importer import pipeline as pipeline_module
from schememedia.importer.pipeline import run_import, sync_database_url
from tests.conftest import database_is_reachable, resolve_test_database_url

TEST_DATABASE_URL = resolve_test_database_url()
DATABASE_AVAILABLE = database_is_reachable(TEST_DATABASE_URL)

REPO_ROOT = Path(__file__).resolve().parents[3]
SCHEMES_JSON = REPO_ROOT / "schemes.json"

# Small, fast, always-tracked fixture (8 records) -- reused from test_search.py's
# convention -- for the batching tests below, which don't need the full
# 1,000-scheme dataset and would otherwise slow the suite down needlessly.
SMALL_FIXTURE = Path(__file__).parent / "fixtures" / "search_schemes.json"

_TRUNCATE_ALL = text(
    "TRUNCATE schemes, categories, tags, scheme_tags, "
    "scheme_benefits, scheme_documents, scheme_eligibility_rules CASCADE"
)

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


@pytest.fixture
def truncated_session() -> Generator[Session, None, None]:
    """A fresh, function-scoped session against an empty database.

    Unlike `imported_twice` above (module-scoped, runs its two imports
    once up front), the batching tests below need to control commits and
    induce a mid-run failure themselves, so each gets its own clean slate.
    """
    engine = create_engine(sync_database_url(TEST_DATABASE_URL), future=True)
    with Session(engine) as session:
        session.execute(_TRUNCATE_ALL)
        session.commit()
        yield session
        session.execute(_TRUNCATE_ALL)
        session.commit()
    engine.dispose()


def _fail_on_nth_call(n: int):
    """A stand-in for `_import_scheme` that raises on its `n`-th invocation
    and otherwise behaves exactly like the real thing.

    A dropped connection and a genuine data error surface identically to
    `run_import` -- both are just "an exception happened mid-batch" -- so a
    plain `RuntimeError` is a faithful, deterministic stand-in for the
    connection drops actually observed importing into a real Neon staging
    database (real network flakiness can't be induced reliably in a test).
    """
    real_import_scheme = pipeline_module._import_scheme
    calls = {"count": 0}

    def _flaky(*args: object, **kwargs: object) -> None:
        calls["count"] += 1
        if calls["count"] == n:
            raise RuntimeError("simulated dropped connection")
        real_import_scheme(*args, **kwargs)

    return _flaky


# ---------------------------------------------------------------------------
# Batching -- commits per chunk instead of one all-or-nothing transaction,
# so a dropped connection over a WAN link (e.g. staging on Neon) loses at
# most one batch's worth of work instead of everything. See pipeline.py's
# DEFAULT_BATCH_SIZE and run_import() docstrings.
# ---------------------------------------------------------------------------


def test_batch_size_is_configurable(truncated_session: Session) -> None:
    with patch.object(
        truncated_session, "commit", wraps=truncated_session.commit
    ) as commit_spy:
        report = run_import(truncated_session, SMALL_FIXTURE, batch_size=3)

    assert report.schemes_seen == 8
    # One commit for categories/tags, ceil(8 / 3) = 3 scheme batches, plus
    # one final commit that records this run's finished_at/report on its
    # ImportRun row (see run_import's provenance finalisation step).
    assert commit_spy.call_count == 5


def test_partial_failure_rolls_back_only_the_failed_batch(
    truncated_session: Session,
) -> None:
    # batch_size=2 over 8 records -> batches of schemes [1,2] [3,4] [5,6] [7,8].
    # Failing on the 5th call lands partway through the third batch, so
    # batches 1-2 (4 schemes) must survive and batch 3 must roll back whole.
    with (
        patch.object(pipeline_module, "_import_scheme", side_effect=_fail_on_nth_call(5)),
        pytest.raises(RuntimeError, match="simulated dropped connection"),
    ):
        run_import(truncated_session, SMALL_FIXTURE, batch_size=2)

    committed = truncated_session.scalar(select(func.count()).select_from(Scheme))
    assert committed == 4


def test_rerun_after_partial_failure_completes_without_duplicates(
    truncated_session: Session,
) -> None:
    with (
        patch.object(pipeline_module, "_import_scheme", side_effect=_fail_on_nth_call(5)),
        pytest.raises(RuntimeError),
    ):
        run_import(truncated_session, SMALL_FIXTURE, batch_size=2)

    committed_before_resume = truncated_session.scalar(
        select(func.count()).select_from(Scheme)
    )
    assert committed_before_resume == 4

    # No patch this time -- the resume runs to completion, exactly what a
    # human re-running the CLI after a connection drop would do.
    report = run_import(truncated_session, SMALL_FIXTURE, batch_size=2)

    final_count = truncated_session.scalar(select(func.count()).select_from(Scheme))
    assert final_count == 8
    assert report.schemes_inserted + report.schemes_updated == 8
    assert report.schemes_updated >= committed_before_resume


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
