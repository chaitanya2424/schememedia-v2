"""End-to-end tests for the recommendation service: hybrid search fused with
deterministic eligibility, against the real 1,000-scheme dataset.

Each query below was chosen by first running it against the real database
and confirming which real scheme lands where -- these are not invented
expectations, they are the actual, observed behaviour of the real system,
pinned down as a regression test.
"""

from __future__ import annotations

from pathlib import Path

import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session

from schememedia.importer.pipeline import run_import, sync_database_url
from schememedia.repositories.eligibility import SqlEligibilityRuleRepository
from schememedia.repositories.search import PgVectorRetriever, SqlKeywordRetriever
from schememedia.services.eligibility_matcher import EligibilityState
from schememedia.services.recommendation import RecommendationService
from schememedia.services.search import SearchService
from tests.conftest import database_is_reachable, resolve_test_database_url

TEST_DATABASE_URL = resolve_test_database_url()
DATABASE_AVAILABLE = database_is_reachable(TEST_DATABASE_URL)
REPO_ROOT = Path(__file__).resolve().parents[3]
SCHEMES_JSON = REPO_ROOT / "schemes.json"

pytestmark = pytest.mark.skipif(
    not (DATABASE_AVAILABLE and SCHEMES_JSON.exists()),
    reason="PostgreSQL unreachable or schemes.json missing; see README section 1",
)

_TRUNCATE = text(
    "TRUNCATE schemes, categories, tags, scheme_tags, "
    "scheme_benefits, scheme_documents, scheme_eligibility_rules CASCADE"
)


@pytest.fixture(scope="module")
def service():
    """Full pipeline against the real dataset: import, embed, wire up.

    Module-scoped: the import + embedding pass (~1,000 records) runs once
    for this file, not once per test.
    """
    from schememedia.cli.generate_embeddings import run as generate_embeddings

    engine = create_engine(sync_database_url(TEST_DATABASE_URL), future=True)
    with Session(engine) as session:
        session.execute(_TRUNCATE)
        session.commit()
        run_import(session, SCHEMES_JSON)
        session.commit()
        generate_embeddings(session)
        session.commit()

        yield RecommendationService(
            search=SearchService(
                keyword=SqlKeywordRetriever(session),
                semantic=PgVectorRetriever(session),
            ),
            rules=SqlEligibilityRuleRepository(session),
        )

        session.execute(_TRUNCATE)
        session.commit()
    engine.dispose()


# ---------------------------------------------------------------------------
# No profile -- must never claim PASS or FAIL on zero information
# ---------------------------------------------------------------------------


def test_no_profile_never_confirms_pass_or_fail(service: RecommendationService) -> None:
    response = service.recommend("sports journalism award", limit=10)
    assert response.profile_provided is False
    assert response.recommendations
    for rec in response.recommendations:
        assert rec.eligibility.state in (
            EligibilityState.UNKNOWN,
            EligibilityState.NOT_APPLICABLE,
        )


def test_no_profile_still_returns_full_search_relevance_order(
    service: RecommendationService,
) -> None:
    """With no profile, nothing can PASS or FAIL, so nothing gets demoted --
    the recommendation order must equal the underlying search order exactly.
    """
    query = "sports journalism award"
    search_only = service.search.search(query, limit=10)
    recommended = service.recommend(query, limit=10)
    assert [r.scheme_id for r in recommended.recommendations] == [
        r.scheme_id for r in search_only.results
    ]


# ---------------------------------------------------------------------------
# A matching profile surfaces PASS -- REAL: SCH_1F47743B, sc_st/ews/lig only
# ---------------------------------------------------------------------------


def test_matching_profile_surfaces_pass_for_a_known_real_scheme(
    service: RecommendationService,
) -> None:
    response = service.recommend(
        "sports journalism award", profile={"is_sc_st": True}, limit=10
    )
    assert response.profile_provided is True
    by_id = {rec.scheme_id: rec for rec in response.recommendations}
    assert "SCH_1F47743B" in by_id
    match = by_id["SCH_1F47743B"]
    assert match.eligibility.state is EligibilityState.PASS
    assert any("Scheduled Caste" in e for e in match.eligibility.explanations)


def test_non_matching_profile_produces_fail_for_the_same_scheme(
    service: RecommendationService,
) -> None:
    response = service.recommend(
        "sports journalism award",
        profile={"is_sc_st": False, "is_ews": False, "is_lig": False},
        limit=10,
    )
    by_id = {rec.scheme_id: rec for rec in response.recommendations}
    assert by_id["SCH_1F47743B"].eligibility.state is EligibilityState.FAIL


# ---------------------------------------------------------------------------
# Known FAIL is demoted, never removed -- REAL: SCH_EBE5D9CA
# ---------------------------------------------------------------------------


def test_known_fail_is_demoted_but_still_present(service: RecommendationService) -> None:
    """REAL: SCH_EBE5D9CA ranks #1 by relevance for this query. A profile
    that definitively fails every one of its rules must push it to the end
    of the results, never remove it -- eligibility ranks, it does not filter.
    """
    query = "avivahita pension unmarried woman"
    profile = {
        "is_woman": False,
        "annual_income": 500000,
        "age": 20,
        "is_taxpayer": False,
    }

    unranked = service.search.search(query, limit=10)
    assert unranked.results[0].scheme_id == "SCH_EBE5D9CA"  # confirms the premise

    response = service.recommend(query, profile=profile, limit=10)
    scheme_ids = [rec.scheme_id for rec in response.recommendations]
    assert "SCH_EBE5D9CA" in scheme_ids, "a known FAIL must still be returned"

    failing = next(
        rec for rec in response.recommendations if rec.scheme_id == "SCH_EBE5D9CA"
    )
    assert failing.eligibility.state is EligibilityState.FAIL

    # Not necessarily the unique last item -- other pension schemes in these
    # results (e.g. Old Age Pension, requiring age >= 60) also legitimately
    # fail this same harsh profile. The real property is: everything from
    # its position onward is also a known FAIL, i.e. it is correctly inside
    # the demoted trailing block, not that it is the only demoted result.
    position = scheme_ids.index("SCH_EBE5D9CA")
    trailing_states = [
        rec.eligibility.state for rec in response.recommendations[position:]
    ]
    assert all(s is EligibilityState.FAIL for s in trailing_states)


def test_fail_state_never_precedes_a_non_fail_state(
    service: RecommendationService,
) -> None:
    """General ordering property, not tied to one scheme id."""
    response = service.recommend(
        "avivahita pension unmarried woman",
        profile={
            "is_woman": False,
            "annual_income": 500000,
            "age": 20,
            "is_taxpayer": False,
        },
        limit=10,
    )
    states = [rec.eligibility.state for rec in response.recommendations]
    first_fail = next(
        (i for i, s in enumerate(states) if s is EligibilityState.FAIL), None
    )
    if first_fail is not None:
        assert all(s is EligibilityState.FAIL for s in states[first_fail:])


# ---------------------------------------------------------------------------
# needs_review and verification_status flow through the whole pipeline
# ---------------------------------------------------------------------------


def test_needs_review_flows_through_search_and_eligibility_consistently(
    service: RecommendationService,
) -> None:
    """REAL: SCH_58532113 -- one of the 33 implausible-income schemes."""
    response = service.recommend(
        "chief minister relief fund medical",
        profile={"annual_income": 250000},
        limit=10,
    )
    by_id = {rec.scheme_id: rec for rec in response.recommendations}
    assert "SCH_58532113" in by_id
    rec = by_id["SCH_58532113"]
    assert rec.result.needs_review is True
    assert rec.eligibility.needs_review is True
    # The implausible rule itself is applied as stored, not corrected.
    assert any(
        "Rs 1 or less" in e and "Does not match" in e
        for e in rec.eligibility.explanations
    )


def test_every_recommendation_carries_verification_status(
    service: RecommendationService,
) -> None:
    response = service.recommend("scholarship for disabled students", limit=15)
    assert response.recommendations
    for rec in response.recommendations:
        assert rec.result.verification_status in {
            "unverified",
            "source_provided",
            "officially_verified",
        }
        assert isinstance(rec.result.needs_review, bool)


# ---------------------------------------------------------------------------
# Response shape and bookkeeping
# ---------------------------------------------------------------------------


def test_eligibility_breakdown_sums_to_total_returned(
    service: RecommendationService,
) -> None:
    response = service.recommend(
        "scholarship for disabled students", profile={"is_divyang": True}, limit=15
    )
    assert sum(response.eligibility_breakdown.values()) == response.total_returned


def test_limit_is_respected(service: RecommendationService) -> None:
    response = service.recommend("scholarship", limit=3)
    assert len(response.recommendations) <= 3


def test_empty_query_returns_nothing(service: RecommendationService) -> None:
    response = service.recommend("zzzqqqxwv", profile={"is_farmer": True})
    assert response.recommendations == []
    assert response.total_returned == 0
    assert response.eligibility_breakdown == {}


def test_every_recommendation_has_at_least_one_explanation_or_is_not_applicable(
    service: RecommendationService,
) -> None:
    response = service.recommend(
        "scholarship for disabled students", profile={"is_divyang": True}, limit=15
    )
    for rec in response.recommendations:
        if rec.eligibility.state is EligibilityState.NOT_APPLICABLE:
            assert rec.eligibility.rules == ()
        else:
            assert rec.eligibility.explanations
