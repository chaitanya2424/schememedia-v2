"""HTTP-layer tests for the API surface exposed to a future frontend:
search, recommendations, scheme detail, and the assistant.

These exercise the real FastAPI app, real routing, real request/response
serialization, and the real 1,000-scheme dataset -- not a second copy of
what the service-level test suites (test_search.py, test_recommendation.py,
test_eligibility_matcher.py, test_assistant.py) already cover thoroughly.
The assistant route uses a FakeProvider override (tests/fakes.py) for its
main tests, same "test without API calls" reasoning as test_assistant.py,
plus one real-Gemini-gated test that swaps the override out temporarily.
"""

from __future__ import annotations

import os
from pathlib import Path

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session

from schememedia.core.config import Settings
from schememedia.core.deps import get_llm_provider
from schememedia.importer.pipeline import run_import, sync_database_url
from schememedia.main import create_app
from tests.conftest import database_is_reachable, resolve_test_database_url
from tests.fakes import FakeProvider

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
def fake_provider() -> FakeProvider:
    return FakeProvider(
        tool_call_query="sports journalism award",
        tool_call_profile={"is_sc_st": True},
        reply_text="You may be eligible for the Biju Patnaik Sports Award.",
    )


@pytest.fixture(scope="module")
def fastapi_app(fake_provider: FakeProvider):
    """Seeds the real dataset once, builds the real app, and overrides
    LLMProviderDep with a fake by default -- see the live-Gemini test below
    for how one test temporarily removes that override. A separate fixture
    from app_client so a test can reach `app.dependency_overrides` directly
    instead of poking at httpx's private transport attribute.
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
    engine.dispose()

    settings = Settings(
        app_env="test",
        database_url=TEST_DATABASE_URL,  # type: ignore[arg-type]
        log_json=False,
        log_level="WARNING",
        cors_origins=["http://localhost:3000"],
        # Several tests below reuse the same message text against this one
        # module-scoped app while mutating fake_provider.reply_text between
        # calls -- the opposite of what the assistant's response cache
        # (core/assistant_guard.py) is for. Cache behaviour itself is
        # covered by tests/test_assistant_guard.py.
        assistant_cache_ttl_seconds=0,
    )
    app = create_app(settings)
    app.dependency_overrides[get_llm_provider] = lambda: fake_provider

    yield app

    cleanup_engine = create_engine(sync_database_url(TEST_DATABASE_URL), future=True)
    with Session(cleanup_engine) as session:
        session.execute(_TRUNCATE)
        session.commit()
    cleanup_engine.dispose()


@pytest_asyncio.fixture
async def app_client(fastapi_app):
    """Function-scoped, matching conftest.py's own `client` fixture --
    module-scoped async fixtures conflict with this project's
    asyncio_default_fixture_loop_scope = "function" (pyproject.toml).
    `fastapi_app` (the expensive part: seeding 1,000 real schemes) stays
    module-scoped; re-entering the lightweight AsyncClient/lifespan context
    per test is cheap.
    """
    async with (
        AsyncClient(
            transport=ASGITransport(app=fastapi_app), base_url="http://test"
        ) as ac,
        fastapi_app.router.lifespan_context(fastapi_app),
    ):
        yield ac


# ---------------------------------------------------------------------------
# Routes are actually registered
# ---------------------------------------------------------------------------


async def test_new_routes_appear_in_the_openapi_schema(app_client: AsyncClient) -> None:
    response = await app_client.get("/openapi.json")
    assert response.status_code == 200
    paths = response.json()["paths"]
    assert "/api/v1/search" in paths
    assert "/api/v1/recommendations" in paths
    assert "/api/v1/schemes/{identifier}" in paths
    assert "/api/v1/assistant/message" in paths


async def test_docs_still_serves(app_client: AsyncClient) -> None:
    response = await app_client.get("/docs")
    assert response.status_code == 200


# ---------------------------------------------------------------------------
# Search
# ---------------------------------------------------------------------------


async def test_search_endpoint_returns_real_results(app_client: AsyncClient) -> None:
    """REAL: SCH_1F47743B ranks #1 for this query."""
    response = await app_client.get(
        "/api/v1/search", params={"q": "sports journalism award"}
    )
    assert response.status_code == 200
    body = response.json()
    scheme_ids = [r["scheme_id"] for r in body["results"]]
    assert "SCH_1F47743B" in scheme_ids
    match = next(r for r in body["results"] if r["scheme_id"] == "SCH_1F47743B")
    assert match["verification_status"] in {
        "unverified",
        "source_provided",
        "officially_verified",
    }


async def test_search_endpoint_respects_limit(app_client: AsyncClient) -> None:
    response = await app_client.get(
        "/api/v1/search", params={"q": "scholarship", "limit": 3}
    )
    assert response.status_code == 200
    assert len(response.json()["results"]) <= 3


async def test_search_endpoint_rejects_empty_query(app_client: AsyncClient) -> None:
    response = await app_client.get("/api/v1/search", params={"q": ""})
    assert response.status_code == 422
    assert response.json()["error"]["code"] == "validation_error"


# ---------------------------------------------------------------------------
# Recommendations
# ---------------------------------------------------------------------------


async def test_recommendations_endpoint_annotates_eligibility(
    app_client: AsyncClient,
) -> None:
    """REAL: SCH_1F47743B, sc_st/ews/lig only -- see test_recommendation.py."""
    response = await app_client.post(
        "/api/v1/recommendations",
        json={"query": "sports journalism award", "profile": {"is_sc_st": True}},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["profile_provided"] is True
    match = next(r for r in body["recommendations"] if r["scheme_id"] == "SCH_1F47743B")
    assert match["eligibility_state"] == "pass"
    assert any(
        rule["state"] == "pass" and "Scheduled Caste" in rule["label"]
        for rule in match["eligibility_rules"]
    )


async def test_recommendations_endpoint_works_without_a_profile(
    app_client: AsyncClient,
) -> None:
    response = await app_client.post(
        "/api/v1/recommendations", json={"query": "sports journalism award"}
    )
    assert response.status_code == 200
    body = response.json()
    assert body["profile_provided"] is False
    assert all(
        r["eligibility_state"] in {"unknown", "not_applicable"}
        for r in body["recommendations"]
    )


async def test_recommendations_endpoint_ignores_unrecognised_profile_keys(
    app_client: AsyncClient,
) -> None:
    response = await app_client.post(
        "/api/v1/recommendations",
        json={
            "query": "sports journalism award",
            "profile": {"is_sc_st": True, "not_a_real_attribute": "x"},
        },
    )
    assert response.status_code == 200


# ---------------------------------------------------------------------------
# Scheme detail
# ---------------------------------------------------------------------------


async def test_scheme_detail_by_scheme_id(app_client: AsyncClient) -> None:
    response = await app_client.get("/api/v1/schemes/SCH_1F47743B")
    assert response.status_code == 200
    body = response.json()
    assert body["name"] == "Biju Patnaik Sports Award for Excellence in Sports Journalism"
    assert body["category"] == "Sports & Culture"
    assert "Sports" in body["tags"]
    assert body["verification_status"] == "unverified"


async def test_scheme_detail_by_slug(app_client: AsyncClient) -> None:
    by_id = await app_client.get("/api/v1/schemes/SCH_1F47743B")
    slug = by_id.json()["slug"]
    by_slug = await app_client.get(f"/api/v1/schemes/{slug}")
    assert by_slug.status_code == 200
    assert by_slug.json()["scheme_id"] == "SCH_1F47743B"


async def test_scheme_detail_404_for_unknown_identifier(app_client: AsyncClient) -> None:
    response = await app_client.get("/api/v1/schemes/SCH_DOES_NOT_EXIST")
    assert response.status_code == 404
    assert response.json()["error"]["code"] == "not_found"


# ---------------------------------------------------------------------------
# Assistant -- FakeProvider (no API calls)
# ---------------------------------------------------------------------------


async def test_assistant_endpoint_returns_a_grounded_reply(
    app_client: AsyncClient, fake_provider: FakeProvider
) -> None:
    fake_provider.reply_text = "You may be eligible for the Biju Patnaik Sports Award."
    response = await app_client.post(
        "/api/v1/assistant/message", json={"message": "anything"}
    )
    assert response.status_code == 200
    body = response.json()
    assert body["reply"] == fake_provider.reply_text
    assert body["grounding_warnings"] == []
    scheme_ids = [r["scheme_id"] for r in body["evidence"]["results"]]
    assert "SCH_1F47743B" in scheme_ids


async def test_assistant_endpoint_surfaces_grounding_warnings(
    app_client: AsyncClient, fake_provider: FakeProvider
) -> None:
    fake_provider.reply_text = "Apply at https://totally-made-up.example.com/apply"
    response = await app_client.post(
        "/api/v1/assistant/message", json={"message": "anything"}
    )
    assert response.status_code == 200
    warnings = response.json()["grounding_warnings"]
    assert any("fabricated or unsupported URL" in w for w in warnings)
    # Restore for any later test relying on the default.
    fake_provider.reply_text = "You may be eligible for the Biju Patnaik Sports Award."


async def test_assistant_endpoint_rejects_an_empty_message(
    app_client: AsyncClient,
) -> None:
    response = await app_client.post("/api/v1/assistant/message", json={"message": ""})
    assert response.status_code == 422


# ---------------------------------------------------------------------------
# Assistant -- real Gemini, through the actual HTTP route (optional, gated)
# ---------------------------------------------------------------------------

GEMINI_AVAILABLE = bool(
    os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
)


@pytest.mark.skipif(
    not GEMINI_AVAILABLE,
    reason="GEMINI_API_KEY/GOOGLE_API_KEY not set; live Gemini route test skipped",
)
async def test_assistant_endpoint_with_real_gemini(
    app_client: AsyncClient, fastapi_app
) -> None:
    """Temporarily removes the FakeProvider override so this one request
    goes through get_llm_provider() -> the real, configured provider.
    """
    override = fastapi_app.dependency_overrides.pop(get_llm_provider, None)
    try:
        response = await app_client.post(
            "/api/v1/assistant/message",
            json={
                "message": "I'm SC/ST, are there any sports or journalism awards for me?"
            },
        )
    finally:
        if override is not None:
            fastapi_app.dependency_overrides[get_llm_provider] = override

    if response.status_code == 503:
        # The free tier's daily quota (20 requests/day for gemini-3.6-flash,
        # confirmed via direct diagnosis -- not a per-minute rate limit) is
        # easy to exhaust during a day of live-testing this same route. A
        # 503 here means the ServiceUnavailableError path itself is working
        # correctly (see assistant.py's route) -- it is not evidence of a
        # regression, so this skips rather than fails.
        pytest.skip(
            "Gemini free-tier daily quota likely exhausted (503) -- "
            "the request reached the real API; see assistant.py's "
            "ServiceUnavailableError handling, which is what returned this."
        )

    assert response.status_code == 200
    body = response.json()
    assert body["reply"]
    assert body["grounding_warnings"] == []
