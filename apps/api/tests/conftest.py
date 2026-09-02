from __future__ import annotations

import asyncio
import os
import sys
from collections.abc import AsyncGenerator
from pathlib import Path

import pytest
import pytest_asyncio
from dotenv import load_dotenv
from httpx import ASGITransport, AsyncClient

from schememedia.core.config import Settings
from schememedia.main import create_app

# Load the repository .env so tests run from a bare `pytest` invocation without
# the developer exporting variables in every new shell session.
load_dotenv(Path(__file__).resolve().parents[3] / ".env")

if sys.platform == "win32":
    # asyncpg is unreliable on Windows' default ProactorEventLoop under
    # pytest-asyncio, producing spurious "Event loop is closed" teardown
    # errors. The selector loop is the supported combination.
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())


def resolve_test_database_url() -> str:
    """TEST_DATABASE_URL, or DATABASE_URL with a _test suffix.

    Derivation keeps the common case zero-config while still allowing an
    explicit override.
    """
    explicit = os.getenv("TEST_DATABASE_URL", "").strip()
    if explicit:
        return explicit
    base = os.getenv("DATABASE_URL", "").strip()
    if not base:
        return ""
    from urllib.parse import urlparse, urlunparse

    parsed = urlparse(base)
    return urlunparse(parsed._replace(path=parsed.path.rstrip("/") + "_test"))


@pytest.fixture(scope="session")
def test_settings() -> Settings:
    """Settings built explicitly, never read from a developer's local .env."""
    return Settings(
        app_env="test",
        database_url="postgresql://test:test@localhost:5432/schememedia_test",
        log_json=False,
        log_level="WARNING",
        cors_origins=["http://localhost:3000"],
    )


@pytest_asyncio.fixture
async def client(test_settings: Settings) -> AsyncGenerator[AsyncClient, None]:
    """HTTP client bound to the app in-process, exercising the full stack."""
    app = create_app(test_settings)
    transport = ASGITransport(app=app)
    # Lifespan is entered so the engine is initialised exactly as in production.
    async with (
        AsyncClient(transport=transport, base_url="http://test") as ac,
        app.router.lifespan_context(app),
    ):
        yield ac


def database_is_reachable(url: str) -> bool:
    """Probe the test database once, with a short timeout.

    Checking that a URL string exists is not the same as checking that
    anything answers on it. Without this probe, a developer who has not yet
    installed PostgreSQL sees eleven tracebacks instead of eleven skips.
    """
    if not url:
        return False
    import asyncpg

    async def probe() -> bool:
        try:
            conn = await asyncio.wait_for(asyncpg.connect(url), timeout=3)
        except Exception:
            return False
        await conn.close()
        return True

    try:
        return asyncio.run(probe())
    except Exception:
        return False
