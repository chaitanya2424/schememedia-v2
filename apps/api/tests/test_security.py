"""Pure unit tests for core/security.py -- no database, no HTTP.

Password hashing and token creation/verification are deterministic,
self-contained functions; testing them directly here is faster and more
precise than only exercising them indirectly through the HTTP-level auth
tests (tests/test_auth_routes.py).
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta

import jwt
import pytest

from schememedia.core.config import Settings
from schememedia.core.security import (
    ACCESS_TOKEN_TYPE,
    InvalidTokenError,
    create_access_token,
    decode_access_token,
    hash_password,
    hash_refresh_token,
    issue_refresh_token,
    verify_password,
)

SETTINGS = Settings(
    app_env="test",
    database_url="postgresql://test:test@localhost:5432/schememedia_test",  # type: ignore[arg-type]
    jwt_secret_key="unit-test-secret",
)


# ---------------------------------------------------------------------------
# Password hashing
# ---------------------------------------------------------------------------


def test_hash_password_is_not_the_plaintext() -> None:
    hashed = hash_password("correct horse battery staple")
    assert hashed != "correct horse battery staple"


def test_correct_password_verifies() -> None:
    hashed = hash_password("correct horse battery staple")
    assert verify_password("correct horse battery staple", hashed) is True


def test_wrong_password_does_not_verify() -> None:
    hashed = hash_password("correct horse battery staple")
    assert verify_password("wrong password", hashed) is False


def test_two_hashes_of_the_same_password_differ() -> None:
    """A random salt per hash -- otherwise identical passwords would
    produce identical hashes, leaking which users share a password.
    """
    assert hash_password("same password") != hash_password("same password")


def test_verify_password_against_a_malformed_hash_fails_closed() -> None:
    assert verify_password("anything", "not-a-real-bcrypt-hash") is False


# ---------------------------------------------------------------------------
# Access tokens
# ---------------------------------------------------------------------------


def test_a_freshly_issued_access_token_decodes_to_the_same_user_id() -> None:
    user_id = uuid.uuid4()
    token = create_access_token(user_id, SETTINGS)
    payload = decode_access_token(token, SETTINGS)
    assert payload.user_id == user_id


def test_access_token_is_rejected_under_a_different_secret() -> None:
    token = create_access_token(uuid.uuid4(), SETTINGS)
    other_settings = Settings(
        app_env="test",
        database_url=SETTINGS.database_url,
        jwt_secret_key="a-completely-different-secret",
    )
    with pytest.raises(InvalidTokenError):
        decode_access_token(token, other_settings)


def test_expired_access_token_is_rejected() -> None:
    user_id = uuid.uuid4()
    now = datetime.now(UTC)
    # Hand-encode an already-expired token -- create_access_token always
    # issues a fresh one, so an expired token must be built directly.
    expired = jwt.encode(
        {
            "sub": str(user_id),
            "type": ACCESS_TOKEN_TYPE,
            "iat": now - timedelta(hours=1),
            "exp": now - timedelta(minutes=1),
        },
        SETTINGS.jwt_secret_key,
        algorithm="HS256",
    )
    with pytest.raises(InvalidTokenError):
        decode_access_token(expired, SETTINGS)


def test_garbage_token_is_rejected() -> None:
    with pytest.raises(InvalidTokenError):
        decode_access_token("this-is-not-a-jwt-at-all", SETTINGS)


def test_a_token_of_the_wrong_type_is_rejected() -> None:
    """A refresh token must never be accepted where an access token is
    required, even if something (a bug, a forged token) gives it the right
    signature and a `sub` claim.
    """
    now = datetime.now(UTC)
    wrong_type_token = jwt.encode(
        {
            "sub": str(uuid.uuid4()),
            "type": "refresh",
            "iat": now,
            "exp": now + timedelta(minutes=15),
        },
        SETTINGS.jwt_secret_key,
        algorithm="HS256",
    )
    with pytest.raises(InvalidTokenError):
        decode_access_token(wrong_type_token, SETTINGS)


def test_a_token_with_a_non_uuid_subject_is_rejected() -> None:
    now = datetime.now(UTC)
    malformed = jwt.encode(
        {
            "sub": "not-a-uuid",
            "type": ACCESS_TOKEN_TYPE,
            "iat": now,
            "exp": now + timedelta(minutes=15),
        },
        SETTINGS.jwt_secret_key,
        algorithm="HS256",
    )
    with pytest.raises(InvalidTokenError):
        decode_access_token(malformed, SETTINGS)


def test_access_token_expiry_respects_configured_minutes() -> None:
    short_settings = Settings(
        app_env="test",
        database_url=SETTINGS.database_url,
        jwt_secret_key="unit-test-secret",
        jwt_access_token_expire_minutes=1,
    )
    before = datetime.now(UTC)
    token = create_access_token(uuid.uuid4(), short_settings)
    payload = decode_access_token(token, short_settings)
    delta = payload.expires_at - before
    assert timedelta(seconds=50) < delta <= timedelta(minutes=1, seconds=5)


# ---------------------------------------------------------------------------
# Refresh tokens
# ---------------------------------------------------------------------------


def test_refresh_token_hash_is_deterministic() -> None:
    """The whole point of hashing by content, not randomly-salted: a
    lookup-by-hash query (repositories/refresh_tokens.py) has to reproduce
    the same hash the token was stored under.
    """
    assert hash_refresh_token("some-raw-token") == hash_refresh_token("some-raw-token")


def test_different_refresh_tokens_hash_differently() -> None:
    assert hash_refresh_token("token-a") != hash_refresh_token("token-b")


def test_issued_refresh_token_hash_matches_hash_refresh_token() -> None:
    issued = issue_refresh_token(SETTINGS)
    assert issued.token_hash == hash_refresh_token(issued.raw_token)


def test_two_issued_refresh_tokens_are_not_the_same_raw_value() -> None:
    a = issue_refresh_token(SETTINGS)
    b = issue_refresh_token(SETTINGS)
    assert a.raw_token != b.raw_token


def test_refresh_token_expiry_respects_configured_days() -> None:
    settings = Settings(
        app_env="test",
        database_url=SETTINGS.database_url,
        jwt_secret_key="unit-test-secret",
        jwt_refresh_token_expire_days=1,
    )
    before = datetime.now(UTC)
    issued = issue_refresh_token(settings)
    delta = issued.expires_at - before
    assert timedelta(hours=23) < delta <= timedelta(days=1, minutes=1)


# ---------------------------------------------------------------------------
# Settings guard -- the literal default secret must never reach production
# ---------------------------------------------------------------------------


def test_default_jwt_secret_is_rejected_in_production() -> None:
    with pytest.raises(ValueError, match="JWT_SECRET_KEY"):
        Settings(
            app_env="production",
            database_url=SETTINGS.database_url,
            cors_origins=["https://example.com"],
        )


def test_default_jwt_secret_is_fine_outside_production() -> None:
    # Must not raise -- this is exactly what every other test file's bare
    # Settings(...) construction relies on.
    Settings(app_env="test", database_url=SETTINGS.database_url)
    Settings(app_env="local", database_url=SETTINGS.database_url)


def test_a_real_secret_is_accepted_in_production() -> None:
    Settings(
        app_env="production",
        database_url=SETTINGS.database_url,
        jwt_secret_key="a-real-production-secret",
        cors_origins=["https://example.com"],
    )
