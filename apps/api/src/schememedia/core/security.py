"""Password hashing, access tokens, and refresh token handling.

Deliberately isolated from every domain module (schemes, search,
recommendations, assistant) -- nothing here imports or is imported by
services/recommendation.py, services/assistant.py, or their repositories.
The only place auth and the scheme/recommendation domain meet is
core/deps.py's dependencies, which hand a plain `uuid.UUID` (the current
user's id) to a route -- never a password, token, or User row.

TWO DIFFERENT KINDS OF TOKEN, ON PURPOSE
------------------------------------------
  * Access token -- a short-lived (Settings.jwt_access_token_expire_minutes,
    default 15 min), HS256-signed JWT. Verified from its signature alone, no
    database hit per request -- this is what makes checking auth on every
    request cheap. A leaked access token is only useful for a few minutes.
  * Refresh token -- long-lived (Settings.jwt_refresh_token_expire_days,
    default 30 days), a plain random string, NEVER a JWT. Only its SHA-256
    hash is ever stored (RefreshToken.token_hash, db/models/user.py) --  a
    database leak alone cannot yield a usable token. Rotated on every use
    (see services/auth.py); presenting an already-rotated/revoked token is
    the standard signal of token theft and revokes every active token for
    that user.

Password hashing uses bcrypt directly (not passlib -- see pyproject.toml's
comment). bcrypt only examines the first 72 bytes of its input; a longer
password is rejected by AuthRegisterRequest's max_length instead of being
silently truncated.
"""

from __future__ import annotations

import hashlib
import secrets
import uuid
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from typing import Any

import bcrypt
import jwt

from schememedia.core.config import Settings

ACCESS_TOKEN_TYPE = "access"
_JWT_ALGORITHM = "HS256"


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(password: str, password_hash: str) -> bool:
    try:
        return bcrypt.checkpw(password.encode("utf-8"), password_hash.encode("utf-8"))
    except ValueError:
        # A malformed/foreign hash (should never happen against this app's
        # own data) fails closed rather than raising into the caller.
        return False


@dataclass(frozen=True)
class AccessTokenPayload:
    user_id: uuid.UUID
    expires_at: datetime


def create_access_token(user_id: uuid.UUID, settings: Settings) -> str:
    now = datetime.now(UTC)
    expires_at = now + timedelta(minutes=settings.jwt_access_token_expire_minutes)
    payload: dict[str, Any] = {
        "sub": str(user_id),
        "type": ACCESS_TOKEN_TYPE,
        "iat": now,
        "exp": expires_at,
        # `exp`/`iat` are only second-precision (the JWT spec's NumericDate),
        # so two tokens minted for the same user inside the same second
        # would otherwise be byte-identical -- e.g. login immediately
        # followed by refresh. A random jti makes every issued token
        # distinct regardless of timing, and is the standard place a future
        # revocation-by-jti list would key off, if that's ever needed.
        "jti": secrets.token_hex(8),
    }
    return jwt.encode(payload, settings.jwt_secret_key, algorithm=_JWT_ALGORITHM)


class InvalidTokenError(Exception):
    """Raised for any malformed, expired, mistyped, or forged access token.

    One exception type regardless of the specific PyJWT failure -- the
    caller (core/deps.py) only ever needs to know "this token is not
    usable", never which of PyJWT's several exception subclasses fired.
    """


def decode_access_token(token: str, settings: Settings) -> AccessTokenPayload:
    try:
        payload = jwt.decode(token, settings.jwt_secret_key, algorithms=[_JWT_ALGORITHM])
    except jwt.PyJWTError as exc:
        raise InvalidTokenError(str(exc)) from exc

    if payload.get("type") != ACCESS_TOKEN_TYPE:
        # A refresh token (or any other token type this app might issue in
        # the future) must never be accepted where an access token is
        # required, even though it would otherwise decode validly.
        raise InvalidTokenError("Not an access token.")

    try:
        user_id = uuid.UUID(payload["sub"])
    except (KeyError, ValueError) as exc:
        raise InvalidTokenError("Token subject is not a valid user id.") from exc

    return AccessTokenPayload(
        user_id=user_id, expires_at=datetime.fromtimestamp(payload["exp"], tz=UTC)
    )


@dataclass(frozen=True)
class RefreshTokenIssue:
    """The raw token (returned to the caller exactly once) and its hash
    (the only form ever persisted).
    """

    raw_token: str
    token_hash: str
    expires_at: datetime


def issue_refresh_token(settings: Settings) -> RefreshTokenIssue:
    raw_token = secrets.token_urlsafe(32)  # 256 bits of entropy
    expires_at = datetime.now(UTC) + timedelta(
        days=settings.jwt_refresh_token_expire_days
    )
    return RefreshTokenIssue(
        raw_token=raw_token,
        token_hash=hash_refresh_token(raw_token),
        expires_at=expires_at,
    )


def hash_refresh_token(raw_token: str) -> str:
    """SHA-256, not bcrypt -- unlike a human password, a refresh token
    already carries 256 bits of its own entropy, so a slow, salted hash
    buys nothing; a fast hash is what lets a lookup-by-hash query use an
    index (RefreshToken.token_hash is unique-indexed) rather than iterating
    every row to bcrypt-compare it, which a per-row-salted hash would
    require.
    """
    return hashlib.sha256(raw_token.encode("utf-8")).hexdigest()
