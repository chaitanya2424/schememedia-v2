"""API rate limiting and request body-size protection.

Two layers, deliberately:

  * The mechanism itself (limiter -> RateLimitExceeded -> this app's error
    envelope, with a real Retry-After header) is tested against a tiny
    throwaway app, not the real one -- fast, no database, no dependency
    stack to fake.
  * That the *real* assistant route actually carries the strictest limit
    (the one requirement this whole feature exists to satisfy -- a burst
    of requests can exhaust Gemini's entire daily free-tier quota) is
    tested end to end against the real app, with a FakeProvider standing
    in for Gemini so the test is fast, free, and deterministic.

`limiter.reset()` runs before each test that hits a real limit: the
limiter's in-memory storage is shared process-wide (correct for a single
deployed instance, see core/rate_limit.py), so without a reset one test's
hits would count against the next test's budget.
"""

from __future__ import annotations

import pytest
import pytest_asyncio
from fastapi import FastAPI, Request
from httpx import ASGITransport, AsyncClient

from schememedia.core.config import Settings
from schememedia.core.deps import get_llm_provider
from schememedia.core.errors import register_exception_handlers
from schememedia.core.rate_limit import (
    ASSISTANT_LIMIT,
    RECOMMENDATIONS_LIMIT,
    SEARCH_LIMIT,
    limiter,
)
from schememedia.main import MAX_REQUEST_BODY_BYTES, create_app
from tests.conftest import database_is_reachable, resolve_test_database_url
from tests.fakes import FakeProvider

TEST_DATABASE_URL = resolve_test_database_url()
DATABASE_AVAILABLE = database_is_reachable(TEST_DATABASE_URL)


# ---------------------------------------------------------------------------
# Documented limits stay in sync with core/rate_limit.py's own comment --
# a stale comment there is a real risk (it's the one place meant to answer
# "what are the limits?" without reading four router files).
# ---------------------------------------------------------------------------


def test_assistant_has_the_strictest_limit() -> None:
    """The one invariant this feature exists to guarantee: a single burst
    cannot exhaust Gemini's daily quota through this endpoint before it
    could through any other.
    """
    from limits import parse

    assistant = parse(ASSISTANT_LIMIT)
    for other in (RECOMMENDATIONS_LIMIT, SEARCH_LIMIT):
        assert assistant.amount < parse(other).amount, (
            f"{ASSISTANT_LIMIT!r} must be stricter than {other!r}"
        )


# ---------------------------------------------------------------------------
# Mechanism -- a tiny throwaway app, not the real one
# ---------------------------------------------------------------------------


@pytest_asyncio.fixture
async def toy_client():
    """A tiny throwaway app wired the same way the real one is (limiter on
    app.state, the same exception handlers) -- fast, no database, nothing
    to fake.
    """
    limiter.reset()
    app = FastAPI()
    app.state.limiter = limiter
    register_exception_handlers(app)

    @app.get("/limited")
    @limiter.limit("2/minute")
    async def limited(request: Request) -> dict[str, bool]:
        return {"ok": True}

    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as ac:
        yield ac
    limiter.reset()


@pytest.mark.asyncio
async def test_requests_within_the_limit_succeed(toy_client: AsyncClient) -> None:
    assert (await toy_client.get("/limited")).status_code == 200
    assert (await toy_client.get("/limited")).status_code == 200


@pytest.mark.asyncio
async def test_exceeding_the_limit_returns_429_in_this_apps_envelope(
    toy_client: AsyncClient,
) -> None:
    await toy_client.get("/limited")
    await toy_client.get("/limited")
    response = await toy_client.get("/limited")

    assert response.status_code == 429
    body = response.json()
    assert body["error"]["code"] == "rate_limited"
    assert body["error"]["message"]
    assert "limit" in body["error"]["details"]
    assert response.headers.get("Retry-After")


# ---------------------------------------------------------------------------
# The real assistant route -- strictest limit, applied end to end
# ---------------------------------------------------------------------------


@pytest.fixture(scope="module")
def fake_provider() -> FakeProvider:
    return FakeProvider(tool_call_query="test query", reply_text="A fake grounded reply.")


@pytest.fixture(scope="module")
def rate_limited_app(fake_provider: FakeProvider):
    if not DATABASE_AVAILABLE:
        pytest.skip("PostgreSQL unreachable; see README section 1")

    settings = Settings(
        app_env="test",
        database_url=TEST_DATABASE_URL,  # type: ignore[arg-type]
        log_json=False,
        log_level="WARNING",
        cors_origins=["http://localhost:3000"],
    )
    app = create_app(settings)
    app.dependency_overrides[get_llm_provider] = lambda: fake_provider
    return app


@pytest_asyncio.fixture
async def rate_limited_client(rate_limited_app):
    limiter.reset()
    async with (
        AsyncClient(
            transport=ASGITransport(app=rate_limited_app), base_url="http://test"
        ) as ac,
        rate_limited_app.router.lifespan_context(rate_limited_app),
    ):
        yield ac
    limiter.reset()


@pytest.mark.asyncio
async def test_assistant_endpoint_enforces_its_limit(
    rate_limited_client: AsyncClient,
) -> None:
    from limits import parse

    allowed = parse(ASSISTANT_LIMIT).amount

    statuses = []
    for _ in range(allowed + 1):
        response = await rate_limited_client.post(
            "/api/v1/assistant/message", json={"message": "hello"}
        )
        statuses.append(response.status_code)

    assert statuses[:allowed] == [200] * allowed, statuses
    assert statuses[allowed] == 429, statuses

    body = response.json()
    assert body["error"]["code"] == "rate_limited"
    assert ASSISTANT_LIMIT.split("/")[0] in body["error"]["details"]["limit"]


# ---------------------------------------------------------------------------
# Request body-size protection
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_oversized_body_is_rejected_with_413(
    rate_limited_client: AsyncClient,
) -> None:
    oversized_message = "x" * (MAX_REQUEST_BODY_BYTES + 1_000)
    response = await rate_limited_client.post(
        "/api/v1/assistant/message", json={"message": oversized_message}
    )
    assert response.status_code == 413
    body = response.json()
    assert body["error"]["code"] == "request_too_large"


@pytest.mark.asyncio
async def test_a_normal_sized_body_is_not_affected(
    rate_limited_client: AsyncClient,
) -> None:
    response = await rate_limited_client.post(
        "/api/v1/assistant/message", json={"message": "a completely normal message"}
    )
    assert response.status_code != 413
