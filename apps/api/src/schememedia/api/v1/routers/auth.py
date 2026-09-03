"""Registration, login, token refresh, logout, and the current account.

Bearer tokens, not cookies: identical on Flutter Web and a future native
Android client, no CSRF surface to defend, no cookie-domain/SameSite
questions across the separately-hosted API/frontend this app already runs
in staging. See services/auth.py and core/security.py for the token
scheme itself; this router only translates that service's domain
exceptions into this app's error envelope.
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Body, Request
from pydantic import BaseModel, EmailStr, Field

from schememedia.core.deps import AuthServiceDep, CurrentUserDep
from schememedia.core.errors import AuthenticationError, ConflictError
from schememedia.core.rate_limit import (
    AUTH_LOGIN_LIMIT,
    AUTH_REFRESH_LIMIT,
    AUTH_REGISTER_LIMIT,
    limiter,
)
from schememedia.db.models.user import User
from schememedia.services.auth import (
    AuthSession,
    EmailAlreadyRegisteredError,
    InvalidCredentialsError,
    InvalidRefreshTokenError,
)

router = APIRouter(prefix="/auth", tags=["auth"])

# bcrypt only examines the first 72 bytes of its input -- reject a longer
# password outright rather than silently hashing only part of it.
_MAX_PASSWORD_LENGTH = 72


class AuthRegisterRequest(BaseModel):
    email: EmailStr
    password: Annotated[str, Field(min_length=8, max_length=_MAX_PASSWORD_LENGTH)]
    full_name: Annotated[str | None, Field(default=None, max_length=200)]


class AuthLoginRequest(BaseModel):
    email: EmailStr
    password: Annotated[str, Field(min_length=1, max_length=_MAX_PASSWORD_LENGTH)]


class AuthRefreshRequest(BaseModel):
    refresh_token: Annotated[str, Field(min_length=1)]


class AuthLogoutRequest(BaseModel):
    refresh_token: Annotated[str, Field(min_length=1)]


class UserOut(BaseModel):
    id: str
    email: str
    full_name: str | None
    created_at: str

    @classmethod
    def from_domain(cls, user: User) -> UserOut:
        return cls(
            id=str(user.id),
            email=user.email,
            full_name=user.full_name,
            created_at=user.created_at.isoformat(),
        )


class AuthSessionOut(BaseModel):
    user: UserOut
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int = Field(description="Access token lifetime, in seconds.")

    @classmethod
    def from_domain(cls, session: AuthSession, *, expires_in: int) -> AuthSessionOut:
        return cls(
            user=UserOut.from_domain(session.user),
            access_token=session.access_token,
            refresh_token=session.refresh_token,
            expires_in=expires_in,
        )


def _client_context(request: Request) -> tuple[str | None, str | None]:
    user_agent = request.headers.get("User-Agent")
    ip_address = request.client.host if request.client else None
    return user_agent, ip_address


@router.post(
    "/register",
    response_model=AuthSessionOut,
    operation_id="registerAccount",
    summary="Create an account and sign in",
    responses={409: {"description": "An account with this email already exists."}},
)
@limiter.limit(AUTH_REGISTER_LIMIT)
async def register(
    request: Request,  # required by @limiter.limit
    auth: AuthServiceDep,
    body: Annotated[AuthRegisterRequest, Body()],
) -> AuthSessionOut:
    user_agent, ip_address = _client_context(request)
    try:
        session = await auth.register(
            email=body.email,
            password=body.password,
            full_name=body.full_name,
            user_agent=user_agent,
            ip_address=ip_address,
        )
    except EmailAlreadyRegisteredError as exc:
        raise ConflictError("An account with this email already exists.") from exc
    return AuthSessionOut.from_domain(
        session, expires_in=auth.settings.jwt_access_token_expire_minutes * 60
    )


@router.post(
    "/login",
    response_model=AuthSessionOut,
    operation_id="login",
    summary="Sign in with email and password",
    responses={401: {"description": "Invalid email or password."}},
)
@limiter.limit(AUTH_LOGIN_LIMIT)
async def login(
    request: Request,
    auth: AuthServiceDep,
    body: Annotated[AuthLoginRequest, Body()],
) -> AuthSessionOut:
    user_agent, ip_address = _client_context(request)
    try:
        session = await auth.login(
            email=body.email,
            password=body.password,
            user_agent=user_agent,
            ip_address=ip_address,
        )
    except InvalidCredentialsError as exc:
        # Deliberately the same message whether the email is unknown or the
        # password is wrong -- see InvalidCredentialsError's own docstring.
        raise AuthenticationError("Invalid email or password.") from exc
    return AuthSessionOut.from_domain(
        session, expires_in=auth.settings.jwt_access_token_expire_minutes * 60
    )


@router.post(
    "/refresh",
    response_model=AuthSessionOut,
    operation_id="refreshSession",
    summary="Exchange a refresh token for a new access token (rotates the refresh token)",
    responses={401: {"description": "Invalid, expired, or already-used refresh token."}},
)
@limiter.limit(AUTH_REFRESH_LIMIT)
async def refresh(
    request: Request,
    auth: AuthServiceDep,
    body: Annotated[AuthRefreshRequest, Body()],
) -> AuthSessionOut:
    user_agent, ip_address = _client_context(request)
    try:
        session = await auth.refresh(
            body.refresh_token, user_agent=user_agent, ip_address=ip_address
        )
    except InvalidRefreshTokenError as exc:
        raise AuthenticationError("Please sign in again.") from exc
    return AuthSessionOut.from_domain(
        session, expires_in=auth.settings.jwt_access_token_expire_minutes * 60
    )


@router.post(
    "/logout",
    status_code=204,
    operation_id="logout",
    summary="Revoke a refresh token",
)
async def logout(
    auth: AuthServiceDep, body: Annotated[AuthLogoutRequest, Body()]
) -> None:
    await auth.logout(body.refresh_token)


@router.get(
    "/me",
    response_model=UserOut,
    operation_id="getCurrentUser",
    summary="The signed-in account",
    responses={401: {"description": "Missing, invalid, or expired access token."}},
)
async def me(user: CurrentUserDep) -> UserOut:
    return UserOut.from_domain(user)
