"""Phase 1 foundation tests.

These deliberately run without a database. Proving the app starts, serves
liveness, and reports readiness as degraded (rather than crashing) when
Postgres is absent is exactly the resilience v1 lacked.
"""

from __future__ import annotations

from collections.abc import AsyncGenerator

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from pydantic import ValidationError as PydanticValidationError

from schememedia.core.config import Settings
from schememedia.core.errors import NotFoundError
from schememedia.main import create_app

# ---------- Liveness ----------


@pytest.mark.asyncio
async def test_health_returns_ok(client: AsyncClient) -> None:
    response = await client.get("/health")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert body["environment"] == "test"


@pytest.mark.asyncio
async def test_health_does_not_require_database(client: AsyncClient) -> None:
    """Liveness must never depend on a dependency, or pods restart-loop."""
    response = await client.get("/health")
    assert response.status_code == 200


# ---------- Readiness ----------


@pytest_asyncio.fixture
async def client_without_database() -> AsyncGenerator[AsyncClient, None]:
    """A dedicated app bound to a database URL nothing is listening on, in
    any environment -- deliberately NOT the shared `client` fixture.

    A previous version of both tests below reused `client` (real,
    reachable test/test credentials matching CI's own Postgres service)
    and relied on it reporting "degraded" anyway -- true only by accident,
    when a local development machine's own Postgres role setup happened
    not to have a matching test/test role. In a real CI run, where those
    exact credentials ARE provisioned on purpose, `/ready` correctly
    reported 200, and both tests below silently tested nothing. Port 1 is
    a reserved port nothing binds to on a loopback interface, so a
    connection attempt fails immediately (a real refusal, not a timeout)
    the same way in local dev, CI, or anywhere else.
    """
    settings = Settings(
        app_env="test",
        database_url="postgresql://nobody:nobody@localhost:1/does-not-exist",
        log_json=False,
        log_level="WARNING",
        cors_origins=["http://localhost:3000"],
    )
    app = create_app(settings)
    transport = ASGITransport(app=app)
    async with (
        AsyncClient(transport=transport, base_url="http://test") as ac,
        app.router.lifespan_context(app),
    ):
        yield ac


@pytest.mark.asyncio
async def test_ready_reports_degraded_without_database(
    client_without_database: AsyncClient,
) -> None:
    response = await client_without_database.get("/ready")
    assert response.status_code == 503
    body = response.json()
    assert body["status"] == "degraded"
    assert body["dependencies"][0]["name"] == "database"
    assert body["dependencies"][0]["status"] == "unavailable"


@pytest.mark.asyncio
async def test_ready_does_not_leak_connection_details(
    client_without_database: AsyncClient,
) -> None:
    """Driver exceptions can embed the connection string. Never echo them."""
    response = await client_without_database.get("/ready")
    assert response.status_code == 503  # confirms this exercised the failure path at all
    assert "password" not in response.text.lower()
    assert "postgresql://" not in response.text
    assert "nobody" not in response.text


# ---------- Request IDs ----------


@pytest.mark.asyncio
async def test_request_id_is_returned(client: AsyncClient) -> None:
    response = await client.get("/health")
    assert response.headers.get("X-Request-ID")


@pytest.mark.asyncio
async def test_inbound_request_id_is_preserved(client: AsyncClient) -> None:
    response = await client.get("/health", headers={"X-Request-ID": "trace-abc-123"})
    assert response.headers["X-Request-ID"] == "trace-abc-123"


# ---------- Error envelope ----------


@pytest.mark.asyncio
async def test_unknown_route_uses_error_envelope(client: AsyncClient) -> None:
    response = await client.get("/api/v1/does-not-exist")
    assert response.status_code == 404
    body = response.json()
    assert "error" in body
    assert "code" in body["error"]
    assert "message" in body["error"]


async def test_app_error_maps_to_status_and_code() -> None:
    error = NotFoundError("Scheme not found.", details={"scheme_id": "SCH_1"})
    assert error.status_code == 404
    assert error.code == "not_found"
    assert error.details == {"scheme_id": "SCH_1"}


# ---------- Configuration ----------


def test_missing_database_url_fails_fast(monkeypatch: pytest.MonkeyPatch) -> None:
    """A missing secret must stop the process, not degrade at request time.

    Both sources are suppressed: _env_file blocks the .env file, monkeypatch
    clears the process environment. Otherwise a developer with DATABASE_URL
    exported would see this test pass for the wrong reason.
    """
    monkeypatch.delenv("DATABASE_URL", raising=False)
    with pytest.raises(PydanticValidationError):
        Settings(_env_file=None)  # type: ignore[call-arg]


def test_cors_origins_accept_comma_separated_string() -> None:
    settings = Settings(
        database_url="postgresql://u:p@localhost:5432/db",
        cors_origins="http://a.com, http://b.com",  # type: ignore[arg-type]
    )
    assert settings.cors_origins == ["http://a.com", "http://b.com"]


def test_sqlalchemy_url_forces_asyncpg_driver() -> None:
    settings = Settings(database_url="postgresql://u:p@localhost:5432/db")
    assert settings.sqlalchemy_url.startswith("postgresql+asyncpg://")


def test_production_hides_interactive_docs() -> None:
    settings = Settings(
        app_env="production",
        database_url="postgresql://u:p@localhost:5432/db",
    )
    app = create_app(settings)
    assert app.docs_url is None
    assert app.openapi_url is None
