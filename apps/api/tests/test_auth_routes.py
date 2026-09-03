"""HTTP-level tests for authentication -- registration, login, refresh
(including rotation and reuse-detection), logout, and /auth/me. Real app,
real database.

profile/saved-schemes/authenticated-recommendations tests live in their
own files (test_profile_routes.py, test_saved_schemes_routes.py,
test_recommendations_me_routes.py) -- all four share the seeded-app
fixture pattern defined here in a small local `conftest`-style module
(tests/_account_fixtures.py) rather than each re-seeding independently.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

from httpx import AsyncClient
from sqlalchemy import create_engine, text

from schememedia.importer.pipeline import sync_database_url
from tests._account_fixtures import (  # noqa: F401 -- fixtures
    TEST_DATABASE_URL,
    client,
    fastapi_app,
    pytestmark,
    register,
)


def _backdate_refresh_token_expiry(raw_token: str) -> None:
    """Directly ages a refresh token past its expiry via SQL -- there is no
    API for this, and there should not be; it stands in for "30 days have
    passed" without an actual wait.
    """
    from schememedia.core.security import hash_refresh_token

    engine = create_engine(sync_database_url(TEST_DATABASE_URL), future=True)
    with engine.begin() as conn:
        conn.execute(
            text(
                "UPDATE refresh_tokens SET expires_at = :expires WHERE token_hash = :hash"
            ),
            {
                "expires": datetime.now(UTC) - timedelta(days=1),
                "hash": hash_refresh_token(raw_token),
            },
        )
    engine.dispose()


# ---------------------------------------------------------------------------
# Registration
# ---------------------------------------------------------------------------


async def test_register_returns_a_user_and_tokens(client: AsyncClient) -> None:
    response = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "new.user@example.com",
            "password": "correct-horse-1",
            "full_name": "New User",
        },
    )
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["user"]["email"] == "new.user@example.com"
    assert body["user"]["full_name"] == "New User"
    assert body["access_token"]
    assert body["refresh_token"]
    assert body["token_type"] == "bearer"
    assert body["expires_in"] > 0


async def test_register_full_name_is_optional(client: AsyncClient) -> None:
    response = await client.post(
        "/api/v1/auth/register",
        json={"email": "no.name@example.com", "password": "correct-horse-1"},
    )
    assert response.status_code == 200, response.text
    assert response.json()["user"]["full_name"] is None


async def test_registering_a_duplicate_email_is_rejected(client: AsyncClient) -> None:
    await register(client, "dup@example.com")
    response = await client.post(
        "/api/v1/auth/register",
        json={"email": "dup@example.com", "password": "another-password-1"},
    )
    assert response.status_code == 409
    body = response.json()
    assert body["error"]["code"] == "conflict"


async def test_registering_with_different_case_email_is_still_a_duplicate(
    client: AsyncClient,
) -> None:
    await register(client, "CaseTest@Example.com")
    response = await client.post(
        "/api/v1/auth/register",
        json={"email": "casetest@example.com", "password": "another-password-1"},
    )
    assert response.status_code == 409


async def test_registering_with_a_short_password_is_rejected(client: AsyncClient) -> None:
    response = await client.post(
        "/api/v1/auth/register", json={"email": "short@example.com", "password": "short"}
    )
    assert response.status_code == 422
    body = response.json()
    assert body["error"]["code"] == "validation_error"


async def test_registering_with_an_invalid_email_is_rejected(client: AsyncClient) -> None:
    response = await client.post(
        "/api/v1/auth/register",
        json={"email": "not-an-email", "password": "correct-horse-1"},
    )
    assert response.status_code == 422


# ---------------------------------------------------------------------------
# Login
# ---------------------------------------------------------------------------


async def test_login_with_correct_credentials_succeeds(client: AsyncClient) -> None:
    await register(client, "login.ok@example.com", password="correct-horse-1")
    response = await client.post(
        "/api/v1/auth/login",
        json={"email": "login.ok@example.com", "password": "correct-horse-1"},
    )
    assert response.status_code == 200, response.text
    assert response.json()["user"]["email"] == "login.ok@example.com"


async def test_login_is_case_insensitive_on_email(client: AsyncClient) -> None:
    await register(client, "MixedCase@Example.com", password="correct-horse-1")
    response = await client.post(
        "/api/v1/auth/login",
        json={"email": "mixedcase@example.com", "password": "correct-horse-1"},
    )
    assert response.status_code == 200, response.text


async def test_login_with_wrong_password_is_rejected(client: AsyncClient) -> None:
    await register(client, "wrongpw@example.com", password="correct-horse-1")
    response = await client.post(
        "/api/v1/auth/login",
        json={"email": "wrongpw@example.com", "password": "totally-wrong"},
    )
    assert response.status_code == 401
    assert response.json()["error"]["code"] == "authentication_required"


async def test_login_with_unknown_email_is_rejected(client: AsyncClient) -> None:
    response = await client.post(
        "/api/v1/auth/login",
        json={"email": "nobody@example.com", "password": "whatever-password"},
    )
    assert response.status_code == 401


async def test_login_failure_message_does_not_reveal_which_check_failed(
    client: AsyncClient,
) -> None:
    """Unknown email and wrong password must be indistinguishable to the
    caller -- otherwise the endpoint becomes a user-enumeration oracle.
    """
    await register(client, "enum.check@example.com", password="correct-horse-1")
    wrong_password = await client.post(
        "/api/v1/auth/login",
        json={"email": "enum.check@example.com", "password": "nope"},
    )
    unknown_email = await client.post(
        "/api/v1/auth/login",
        json={"email": "does.not.exist@example.com", "password": "nope"},
    )
    assert (
        wrong_password.json()["error"]["message"]
        == unknown_email.json()["error"]["message"]
    )


# ---------------------------------------------------------------------------
# Authorization -- missing/invalid/expired tokens
# ---------------------------------------------------------------------------


async def test_me_without_a_token_is_rejected(client: AsyncClient) -> None:
    response = await client.get("/api/v1/auth/me")
    assert response.status_code == 401
    assert response.json()["error"]["code"] == "authentication_required"


async def test_me_with_a_garbage_token_is_rejected(client: AsyncClient) -> None:
    response = await client.get(
        "/api/v1/auth/me", headers={"Authorization": "Bearer not-a-real-token"}
    )
    assert response.status_code == 401


async def test_me_with_a_malformed_authorization_header_is_rejected(
    client: AsyncClient,
) -> None:
    response = await client.get(
        "/api/v1/auth/me", headers={"Authorization": "not-bearer-at-all"}
    )
    assert response.status_code == 401


async def test_me_with_a_valid_token_returns_the_right_user(client: AsyncClient) -> None:
    session = await register(client, "me.check@example.com")
    response = await client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {session['access_token']}"},
    )
    assert response.status_code == 200
    assert response.json()["email"] == "me.check@example.com"


# ---------------------------------------------------------------------------
# Refresh -- rotation and reuse detection
# ---------------------------------------------------------------------------


async def test_refresh_issues_a_new_access_and_refresh_token(client: AsyncClient) -> None:
    session = await register(client, "refresh.ok@example.com")
    response = await client.post(
        "/api/v1/auth/refresh", json={"refresh_token": session["refresh_token"]}
    )
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["access_token"] != session["access_token"]
    assert body["refresh_token"] != session["refresh_token"]


async def test_the_new_access_token_from_refresh_actually_works(
    client: AsyncClient,
) -> None:
    session = await register(client, "refresh.works@example.com")
    refreshed = (
        await client.post(
            "/api/v1/auth/refresh", json={"refresh_token": session["refresh_token"]}
        )
    ).json()
    response = await client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {refreshed['access_token']}"},
    )
    assert response.status_code == 200


async def test_a_rotated_refresh_token_can_no_longer_be_used(client: AsyncClient) -> None:
    session = await register(client, "rotated.old@example.com")
    await client.post(
        "/api/v1/auth/refresh", json={"refresh_token": session["refresh_token"]}
    )
    reuse = await client.post(
        "/api/v1/auth/refresh", json={"refresh_token": session["refresh_token"]}
    )
    assert reuse.status_code == 401


async def test_reusing_a_rotated_refresh_token_revokes_the_whole_chain(
    client: AsyncClient,
) -> None:
    """The theft-detection response: presenting an already-rotated token
    must kill every active session for that user, including the one
    legitimately issued by the rotation itself.
    """
    session = await register(client, "theft.detect@example.com")
    rotated = (
        await client.post(
            "/api/v1/auth/refresh", json={"refresh_token": session["refresh_token"]}
        )
    ).json()

    # Reuse of the original (now-rotated) token -- the theft signal.
    reuse = await client.post(
        "/api/v1/auth/refresh", json={"refresh_token": session["refresh_token"]}
    )
    assert reuse.status_code == 401

    # The token issued *from* that rotation must now also be dead.
    legitimate_followup = await client.post(
        "/api/v1/auth/refresh", json={"refresh_token": rotated["refresh_token"]}
    )
    assert legitimate_followup.status_code == 401


async def test_an_unknown_refresh_token_is_rejected(client: AsyncClient) -> None:
    response = await client.post(
        "/api/v1/auth/refresh", json={"refresh_token": "this-token-was-never-issued"}
    )
    assert response.status_code == 401


async def test_an_expired_refresh_token_is_rejected(client: AsyncClient) -> None:
    session = await register(client, "expired.refresh@example.com")
    _backdate_refresh_token_expiry(session["refresh_token"])
    response = await client.post(
        "/api/v1/auth/refresh", json={"refresh_token": session["refresh_token"]}
    )
    assert response.status_code == 401


# ---------------------------------------------------------------------------
# Logout
# ---------------------------------------------------------------------------


async def test_logout_revokes_the_refresh_token(client: AsyncClient) -> None:
    session = await register(client, "logout.ok@example.com")
    logout_response = await client.post(
        "/api/v1/auth/logout", json={"refresh_token": session["refresh_token"]}
    )
    assert logout_response.status_code == 204

    refresh_after_logout = await client.post(
        "/api/v1/auth/refresh", json={"refresh_token": session["refresh_token"]}
    )
    assert refresh_after_logout.status_code == 401


async def test_logout_with_an_unknown_token_does_not_error(client: AsyncClient) -> None:
    response = await client.post(
        "/api/v1/auth/logout", json={"refresh_token": "never-issued"}
    )
    assert response.status_code == 204


async def test_logout_does_not_invalidate_the_access_token_before_it_expires(
    client: AsyncClient,
) -> None:
    """Access tokens are stateless (core/security.py) -- logout revokes the
    refresh token only. A still-unexpired access token keeps working until
    it naturally expires, by design.
    """
    session = await register(client, "logout.access.still.works@example.com")
    await client.post(
        "/api/v1/auth/logout", json={"refresh_token": session["refresh_token"]}
    )
    response = await client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {session['access_token']}"},
    )
    assert response.status_code == 200


# ---------------------------------------------------------------------------
# Error envelope shape
# ---------------------------------------------------------------------------


async def test_auth_errors_use_the_standard_error_envelope(client: AsyncClient) -> None:
    response = await client.get("/api/v1/auth/me")
    body = response.json()
    assert "error" in body
    assert set(body["error"].keys()) >= {"code", "message"}
