"""MAX_COSINE_DISTANCE calibration -- real dataset, real embeddings.

Kept in its own file, not appended to test_search.py: test_search.py's own
`service` fixture (module-scoped, seeded from the small search_schemes.json
fixture) leaves its session with an open transaction between tests (no test
there calls `session.commit()` after `service.search(...)`, only the
fixture's own teardown does). A second module-scoped fixture importing the
real 1,000-scheme dataset into the *same* test database, in the *same*
file, raced that open transaction for a lock on `schemes` and genuinely
hung in `TRUNCATE` -- confirmed live via `pg_stat_activity` (one backend
"idle in transaction" mid a `hydrate()` SELECT, a second "active" and
blocked on `Lock: relation` running the `real_data_service` fixture's own
TRUNCATE). A separate file gives this its own engine lifecycle with no
carry-over session from an unrelated fixture.

Found during structured user testing: "health insurance" is an
unambiguous, realistic query whose genuinely correct semantic match landed
at cosine distance 0.5433 -- just past the original 0.5 cutoff, so semantic
search contributed nothing and keyword term-frequency alone ranked an
irrelevant "Soil Health...Health Card" scheme first (it matches the word
"health" twice). See repositories/search.py's MAX_COSINE_DISTANCE comment
for the full measurement this revision (0.56) is based on.
"""

from __future__ import annotations

from pathlib import Path

import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session

from schememedia.repositories.search import (
    MAX_COSINE_DISTANCE,
    PgVectorRetriever,
    SqlKeywordRetriever,
)
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
    """Full pipeline against the real dataset -- see test_recommendation.py's
    matching fixture, which this mirrors.
    """
    from schememedia.cli.generate_embeddings import run as generate_embeddings
    from schememedia.importer.pipeline import run_import, sync_database_url

    engine = create_engine(sync_database_url(TEST_DATABASE_URL), future=True)
    with Session(engine) as session:
        session.execute(_TRUNCATE)
        session.commit()
        run_import(session, SCHEMES_JSON)
        session.commit()
        generate_embeddings(session)
        session.commit()
        yield SearchService(
            keyword=SqlKeywordRetriever(session),
            semantic=PgVectorRetriever(session),
        )
        session.execute(_TRUNCATE)
        session.commit()
    engine.dispose()


def test_health_insurance_finds_the_genuine_match_via_semantic_search(
    service: SearchService,
) -> None:
    """REAL: without semantic search contributing, keyword term-frequency
    alone puts an irrelevant agriculture/soil scheme first (see the module
    docstring). With MAX_COSINE_DISTANCE correctly including this query's
    real best match, the genuinely relevant insurance scheme must appear
    near the top.
    """
    response = service.search("health insurance", limit=10)
    assert response.results
    top_names = [r.name for r in response.results[:5]]
    assert any("insurance" in name.lower() for name in top_names), top_names


def test_vague_single_words_still_return_nothing_via_semantic_search(
    service: SearchService,
) -> None:
    """The other half of the calibration: 0.56 must NOT be so loose that
    too-vague single words (whose "best" semantic match is spurious, not
    genuinely relevant -- see the module docstring) start pulling in
    semantic noise. Keyword search alone may still legitimately match
    these words in scheme names/descriptions; this only asserts semantic
    retrieval specifically stays empty for them.
    """
    assert service.semantic is not None
    for query in ("money", "scheme", "benefits"):
        candidates = service.semantic.search(query, limit=5)
        assert candidates == [], (
            f"{query!r} should not semantically match anything at "
            f"MAX_COSINE_DISTANCE={MAX_COSINE_DISTANCE}, got {candidates}"
        )
