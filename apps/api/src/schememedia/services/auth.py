"""Registration, login, and refresh-token orchestration.

Deliberately isolated from every scheme/recommendation domain module -- see
core/security.py's module docstring for the boundary this maintains: this
file only ever imports the auth repositories, core/security.py, and the
User model.

Returns plain domain results or raises the plain exceptions below; HTTP
status/error-envelope translation happens in api/v1/routers/auth.py -- the
same "services return domain results, routers decide the HTTP shape"
convention api/v1/routers/schemes.py already uses (NotFoundError raised in
the router from a `None` return, not inside SchemeDetailService).
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, datetime

from schememedia.core.config import Settings
from schememedia.core.security import (
    create_access_token,
    hash_password,
    hash_refresh_token,
    issue_refresh_token,
    verify_password,
)
from schememedia.db.models.user import User
from schememedia.repositories.refresh_tokens import SqlRefreshTokenRepository
from schememedia.repositories.users import SqlUserRepository


class EmailAlreadyRegisteredError(Exception):
    """Raised by `register` -- unlike login, telling a registering caller
    "that email is already registered" is standard UX, not a user-
    enumeration risk in the same way a login failure reason would be.
    """


class InvalidCredentialsError(Exception):
    """Wrong email, wrong password, or a deactivated account -- deliberately
    one exception for all three. Revealing which of the three actually
    happened is a user-enumeration side channel; the router turns this into
    one generic "Invalid email or password" message regardless.
    """


class InvalidRefreshTokenError(Exception):
    """Unknown, expired, or already-revoked (possible theft, see
    AuthService.refresh) refresh token. The caller must sign in again.
    """


@dataclass(frozen=True)
class AuthSession:
    """What register/login/refresh hand back: a usable access token plus a
    fresh refresh token for the caller to store.
    """

    user: User
    access_token: str
    refresh_token: str
    refresh_token_expires_at: datetime


@dataclass
class AuthService:
    users: SqlUserRepository
    refresh_tokens: SqlRefreshTokenRepository
    settings: Settings

    async def register(
        self,
        *,
        email: str,
        password: str,
        full_name: str | None,
        user_agent: str | None = None,
        ip_address: str | None = None,
    ) -> AuthSession:
        normalized_email = email.strip().lower()
        existing = await self.users.get_by_email(normalized_email)
        if existing is not None:
            raise EmailAlreadyRegisteredError(normalized_email)
        user = await self.users.create(
            email=normalized_email,
            password_hash=hash_password(password),
            full_name=full_name,
        )
        return await self._issue_session(
            user, user_agent=user_agent, ip_address=ip_address
        )

    async def login(
        self,
        *,
        email: str,
        password: str,
        user_agent: str | None = None,
        ip_address: str | None = None,
    ) -> AuthSession:
        normalized_email = email.strip().lower()
        user = await self.users.get_by_email(normalized_email)
        if (
            user is None
            or not user.is_active
            or not verify_password(password, user.password_hash)
        ):
            raise InvalidCredentialsError()
        await self.users.touch_last_login(user.id)
        return await self._issue_session(
            user, user_agent=user_agent, ip_address=ip_address
        )

    async def refresh(
        self,
        raw_refresh_token: str,
        *,
        user_agent: str | None = None,
        ip_address: str | None = None,
    ) -> AuthSession:
        token_hash = hash_refresh_token(raw_refresh_token)
        stored = await self.refresh_tokens.get_by_hash(token_hash)
        if stored is None:
            raise InvalidRefreshTokenError("unknown token")
        if stored.revoked_at is not None:
            # Reuse of an already-rotated/revoked token is the standard
            # signal of a stolen refresh token -- kill every active session
            # for this user rather than trust just this one request.
            await self.refresh_tokens.revoke_all_for_user(stored.user_id)
            # Committed explicitly, here, before raising: db/session.py's
            # get_session() rolls the whole request's session back on any
            # exception, which -- without this -- would silently undo the
            # revocation on the very request that detected the theft,
            # leaving every other active token quietly still valid.
            await self.refresh_tokens.session.commit()
            raise InvalidRefreshTokenError("token already used")
        if stored.expires_at <= datetime.now(UTC):
            raise InvalidRefreshTokenError("token expired")

        user = await self.users.get_by_id(stored.user_id)
        if user is None or not user.is_active:
            raise InvalidRefreshTokenError("account no longer active")

        issued = issue_refresh_token(self.settings)
        new_token = await self.refresh_tokens.create(
            user_id=user.id,
            token_hash=issued.token_hash,
            expires_at=issued.expires_at,
            user_agent=user_agent,
            ip_address=ip_address,
        )
        # Rotation: the presented token is retired and linked forward to
        # its replacement, forming the chain reuse-detection walks.
        await self.refresh_tokens.revoke(stored.id, replaced_by_id=new_token.id)

        return AuthSession(
            user=user,
            access_token=create_access_token(user.id, self.settings),
            refresh_token=issued.raw_token,
            refresh_token_expires_at=issued.expires_at,
        )

    async def logout(self, raw_refresh_token: str) -> None:
        """Idempotent: an already-revoked or unknown token is not an error
        -- the caller's intent (be signed out) is already satisfied.
        """
        token_hash = hash_refresh_token(raw_refresh_token)
        stored = await self.refresh_tokens.get_by_hash(token_hash)
        if stored is not None and stored.revoked_at is None:
            await self.refresh_tokens.revoke(stored.id)

    async def _issue_session(
        self, user: User, *, user_agent: str | None = None, ip_address: str | None = None
    ) -> AuthSession:
        issued = issue_refresh_token(self.settings)
        await self.refresh_tokens.create(
            user_id=user.id,
            token_hash=issued.token_hash,
            expires_at=issued.expires_at,
            user_agent=user_agent,
            ip_address=ip_address,
        )
        return AuthSession(
            user=user,
            access_token=create_access_token(user.id, self.settings),
            refresh_token=issued.raw_token,
            refresh_token_expires_at=issued.expires_at,
        )
