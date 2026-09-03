"""Shared fixtures for the auth/profile/saved-schemes/likes/comments/
authenticated-recommendations HTTP test files (test_auth_routes.py,
test_profile_routes.py, test_saved_schemes_routes.py, test_likes_routes.py,
test_comments_routes.py, test_recommendations_me_routes.py).

Not itself a test module (no `test_` prefix -- pytest will not collect it),
same convention as tests/fakes.py. One module-scoped app, seeded once with
the small 8-scheme fixture + real embeddings (same fixture and pattern
test_import.py/test_assistant.py already use) -- auth-related tables are
truncated before every individual test for isolation; the scheme/category
data is never written to by anything in these test files, so it stays
seeded once for the whole module.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session

from schememedia.core.config import Settings
from schememedia.core.rate_limit import limiter
from schememedia.importer.pipeline import run_import, sync_database_url
from schememedia.main import create_app
from tests.conftest import database_is_reachable, resolve_test_database_url

TEST_DATABASE_URL = resolve_test_database_url()
DATABASE_AVAILABLE = database_is_reachable(TEST_DATABASE_URL)
REPO_ROOT = Path(__file__).resolve().parents[3]
SMALL_FIXTURE = Path(__file__).parent / "fixtures" / "search_schemes.json"

pytestmark = pytest.mark.skipif(
    not (DATABASE_AVAILABLE and SMALL_FIXTURE.exists()),
    reason="PostgreSQL unreachable or fixtures/search_schemes.json missing",
)

_TRUNCATE_EVERYTHING = text(
    "TRUNCATE schemes, categories, tags, scheme_tags, "
    "scheme_benefits, scheme_documents, scheme_eligibility_rules, "
    "users, refresh_tokens, user_profiles, scheme_saves, scheme_likes, "
    "comments CASCADE"
)
_TRUNCATE_ACCOUNT_TABLES = text(
    "TRUNCATE users, refresh_tokens, user_profiles, scheme_saves, "
    "scheme_likes, comments CASCADE"
)

DEFAULT_PASSWORD = "correct-horse-1"


@pytest.fixture(scope="module")
def fastapi_app():
    """Seeds the small real dataset (+ embeddings) once for every test file
    that imports this fixture, and builds the real app -- see module
    docstring.
    """
    from schememedia.cli.generate_embeddings import run as generate_embeddings

    engine = create_engine(sync_database_url(TEST_DATABASE_URL), future=True)
    with Session(engine) as session:
        session.execute(_TRUNCATE_EVERYTHING)
        session.commit()
        run_import(session, SMALL_FIXTURE)
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
    )
    app = create_app(settings)

    yield app

    cleanup_engine = create_engine(sync_database_url(TEST_DATABASE_URL), future=True)
    with Session(cleanup_engine) as session:
        session.execute(_TRUNCATE_EVERYTHING)
        session.commit()
    cleanup_engine.dispose()


@pytest_asyncio.fixture
async def client(fastapi_app):
    """Function-scoped: truncates only the account-related tables before
    each test (users/refresh_tokens/user_profiles/scheme_saves), leaving
    the module-scoped scheme/category data untouched -- nothing in these
    test files ever writes to schemes/categories/etc.
    """
    engine = create_engine(sync_database_url(TEST_DATABASE_URL), future=True)
    with Session(engine) as session:
        session.execute(_TRUNCATE_ACCOUNT_TABLES)
        session.commit()
    engine.dispose()

    limiter.reset()
    async with (
        AsyncClient(
            transport=ASGITransport(app=fastapi_app), base_url="http://test"
        ) as ac,
        fastapi_app.router.lifespan_context(fastapi_app),
    ):
        yield ac
    limiter.reset()


async def register(
    client: AsyncClient,
    email: str,
    *,
    password: str = DEFAULT_PASSWORD,
    full_name: str | None = "Test User",
) -> dict[str, Any]:
    """Registers a fresh account and returns the full AuthSessionOut body
    (user + access_token + refresh_token + ...) -- the common setup step
    for almost every test in these files.
    """
    response = await client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": password, "full_name": full_name},
    )
    assert response.status_code == 200, response.text
    return response.json()


def auth_headers(session: dict[str, Any]) -> dict[str, str]:
    return {"Authorization": f"Bearer {session['access_token']}"}
