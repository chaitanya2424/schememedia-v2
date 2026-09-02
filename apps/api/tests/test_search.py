"""Search tests.

Two layers, deliberately:

  * RRF fusion is pure logic and tested without a database.
  * Retrieval quality is tested against real PostgreSQL with the real
    dataset, using realistic multi-word queries -- single-word queries hide
    exactly the AND/OR failure this layer exists to avoid.
"""

from __future__ import annotations

from pathlib import Path

import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session

from schememedia.repositories.search import (
    Candidate,
    PgVectorRetriever,
    SqlKeywordRetriever,
)
from schememedia.services.search import SearchService, reciprocal_rank_fusion
from tests.conftest import database_is_reachable, resolve_test_database_url

TEST_DATABASE_URL = resolve_test_database_url()
DATABASE_AVAILABLE = database_is_reachable(TEST_DATABASE_URL)


# ---------------------------------------------------------------------------
# Fusion -- pure logic, no database
# ---------------------------------------------------------------------------


def test_rrf_ranks_by_position_not_score() -> None:
    """The whole point: incomparable score scales must not matter.

    A retriever returning tiny cosine distances must not be drowned out by
    one returning large BM25 ranks.
    """
    big = [Candidate("A", 900.0), Candidate("B", 800.0)]
    tiny = [Candidate("B", 0.002), Candidate("A", 0.001)]
    fused = dict(reciprocal_rank_fusion([big, tiny]))
    assert abs(fused["A"] - fused["B"]) < 1e-9


def test_rrf_rewards_appearing_in_both_lists() -> None:
    first = [Candidate("A", 1.0), Candidate("B", 0.9)]
    second = [Candidate("A", 1.0), Candidate("C", 0.5)]
    order = [scheme_id for scheme_id, _ in reciprocal_rank_fusion([first, second])]
    assert order[0] == "A"


def test_rrf_preserves_order_for_a_single_list() -> None:
    single = [Candidate("A", 5.0), Candidate("B", 3.0), Candidate("C", 1.0)]
    order = [scheme_id for scheme_id, _ in reciprocal_rank_fusion([single])]
    assert order == ["A", "B", "C"]


def test_rrf_handles_empty_input() -> None:
    assert reciprocal_rank_fusion([]) == []
    assert reciprocal_rank_fusion([[]]) == []


def test_rrf_is_deterministic_on_ties() -> None:
    tied = [Candidate("B", 1.0), Candidate("A", 1.0)]
    first = reciprocal_rank_fusion([tied])
    second = reciprocal_rank_fusion([tied])
    assert first == second


# ---------------------------------------------------------------------------
# Retrieval quality -- real database, real dataset
# ---------------------------------------------------------------------------

pytestmark_db = pytest.mark.skipif(
    not DATABASE_AVAILABLE, reason="PostgreSQL is not reachable; see README section 1"
)


FIXTURE = Path(__file__).parent / "fixtures" / "search_schemes.json"


@pytest.fixture(scope="module")
def service():
    """Seed a known set of REAL scheme records, verbatim from the dataset.

    The tests previously read whatever happened to be in the database, which
    made them depend on another test module's teardown -- they silently
    skipped once test_importer_pipeline truncated the tables. Seeding here
    makes retrieval assertions deterministic and order-independent.

    Embeddings are generated for the seeded fixture too, so `service` fuses
    real keyword and real semantic retrieval -- exactly the hybrid path
    production traffic takes, not keyword-only.
    """
    from schememedia.cli.generate_embeddings import run as generate_embeddings
    from schememedia.importer.pipeline import run_import, sync_database_url

    engine = create_engine(sync_database_url(TEST_DATABASE_URL), future=True)
    with Session(engine) as session:
        session.execute(text("TRUNCATE schemes, categories, tags CASCADE"))
        session.commit()
        run_import(session, FIXTURE)
        session.commit()
        generate_embeddings(session)
        session.commit()
        yield SearchService(
            keyword=SqlKeywordRetriever(session),
            semantic=PgVectorRetriever(session),
        )
        session.execute(text("TRUNCATE schemes, categories, tags CASCADE"))
        session.commit()
    engine.dispose()


@pytestmark_db
@pytest.mark.parametrize(
    ("query", "expect_in_top"),
    [
        ("scholarship for disabled students", "disab"),
        ("widow pension", "widow"),
        ("housing assistance", "hous"),
        ("training for farmers", "farm"),
    ],
)
def test_realistic_queries_return_relevant_top_results(
    service: SearchService, query: str, expect_in_top: str
) -> None:
    """Multi-word natural-language queries, not single keywords."""
    response = service.search(query, limit=5)
    assert response.results, f"no results for {query!r}"
    names = " ".join(r.name.lower() for r in response.results[:5])
    assert expect_in_top in names, f"{query!r} -> {[r.name for r in response.results]}"


@pytestmark_db
def test_query_with_an_absent_word_still_returns_results(
    service: SearchService,
) -> None:
    """The regression this layer exists to prevent.

    Under plainto_tsquery's AND semantics this returned ZERO results,
    because the word "poor" appears nowhere in the dataset.
    """
    response = service.search("housing for rural poor", limit=10)
    assert response.results, "AND semantics has regressed"


@pytestmark_db
def test_results_are_ordered_by_descending_score(service: SearchService) -> None:
    response = service.search("scholarship for students", limit=10)
    scores = [r.score for r in response.results]
    assert scores == sorted(scores, reverse=True)


@pytestmark_db
def test_limit_is_respected_and_capped(service: SearchService) -> None:
    assert len(service.search("scholarship", limit=3).results) <= 3
    assert len(service.search("scholarship", limit=10_000).results) <= 100


@pytestmark_db
def test_stopword_only_query_returns_nothing_rather_than_everything(
    service: SearchService,
) -> None:
    assert service.search("the and of").results == []


@pytestmark_db
def test_empty_query_returns_nothing(service: SearchService) -> None:
    assert service.search("   ").results == []


@pytestmark_db
def test_nonsense_query_returns_nothing(service: SearchService) -> None:
    assert service.search("zzzqqqxwv").results == []


# ---------------------------------------------------------------------------
# Provenance
# ---------------------------------------------------------------------------


@pytestmark_db
def test_every_result_carries_its_verification_status(
    service: SearchService,
) -> None:
    """A UI must not be able to render a scheme without knowing its status."""
    response = service.search("farmer training", limit=5)
    assert response.results
    for result in response.results:
        assert result.verification_status in {
            "unverified",
            "source_provided",
            "officially_verified",
        }


@pytestmark_db
def test_legacy_records_are_not_reported_as_verified(
    service: SearchService,
) -> None:
    """Importing cleanly is not the same as being verified."""
    response = service.search("scholarship", limit=20)
    assert response.results
    assert all(not r.is_officially_verified for r in response.results)


@pytestmark_db
def test_response_reports_a_verification_breakdown(service: SearchService) -> None:
    response = service.search("pension", limit=10)
    assert sum(response.verification_breakdown.values()) == response.total_returned
