"""Shared FastAPI dependencies.

Routes resolve settings through app.state rather than the module-level
get_settings() cache. The global cache reads the process environment, which
silently ignores injected configuration and makes tests exercise a different
application than the one under test.
"""

from __future__ import annotations

import uuid
from collections.abc import Iterator
from typing import Annotated

from fastapi import Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from schememedia.core.assistant_guard import AssistantGuard
from schememedia.core.config import Settings
from schememedia.core.errors import AuthenticationError
from schememedia.core.security import InvalidTokenError, decode_access_token
from schememedia.db import sync_session
from schememedia.db.models.user import User
from schememedia.db.session import get_session
from schememedia.repositories.comments import SqlCommentRepository
from schememedia.repositories.eligibility import SqlEligibilityRuleRepository
from schememedia.repositories.likes import SqlLikeRepository
from schememedia.repositories.refresh_tokens import SqlRefreshTokenRepository
from schememedia.repositories.saved_schemes import SqlSavedSchemeRepository
from schememedia.repositories.schemes import SqlSchemeRepository
from schememedia.repositories.search import PgVectorRetriever, SqlKeywordRetriever
from schememedia.repositories.user_profile import SqlUserProfileRepository
from schememedia.repositories.users import SqlUserRepository
from schememedia.services.auth import AuthService
from schememedia.services.providers import get_provider
from schememedia.services.providers.base import LLMProvider
from schememedia.services.recommendation import RecommendationService
from schememedia.services.scheme_detail import SchemeDetailService
from schememedia.services.search import SearchService


def get_app_settings(request: Request) -> Settings:
    settings: Settings = request.app.state.settings
    return settings


def get_assistant_guard(request: Request) -> AssistantGuard:
    guard: AssistantGuard = request.app.state.assistant_guard
    return guard


SettingsDep = Annotated[Settings, Depends(get_app_settings)]
SessionDep = Annotated[AsyncSession, Depends(get_session)]
AssistantGuardDep = Annotated[AssistantGuard, Depends(get_assistant_guard)]


# ---------------------------------------------------------------------------
# Sync-session services (search, recommendation, eligibility) -- see
# db/sync_session.py's module docstring for why these are sync rather than
# duplicated as async. FastAPI runs a plain `def` dependency (including a
# sync generator, as below) in a worker thread automatically, so
# constructing these off the event loop needs no extra wrapping here; the
# blocking *calls* into them (service.search(...), run_assistant_turn(...))
# still need `run_in_threadpool` at the call site inside each route -- see
# api/v1/routers/search.py, recommendations.py, assistant.py.
# ---------------------------------------------------------------------------


def get_search_service() -> Iterator[SearchService]:
    session = sync_session.get_sync_session()
    try:
        yield SearchService(
            keyword=SqlKeywordRetriever(session),
            semantic=PgVectorRetriever(session),
        )
    finally:
        session.close()


def get_recommendation_service() -> Iterator[RecommendationService]:
    session = sync_session.get_sync_session()
    try:
        yield RecommendationService(
            search=SearchService(
                keyword=SqlKeywordRetriever(session),
                semantic=PgVectorRetriever(session),
            ),
            rules=SqlEligibilityRuleRepository(session),
        )
    finally:
        session.close()


def get_scheme_detail_service() -> Iterator[SchemeDetailService]:
    session = sync_session.get_sync_session()
    try:
        yield SchemeDetailService(schemes=SqlSchemeRepository(session))
    finally:
        session.close()


def get_llm_provider(settings: SettingsDep) -> LLMProvider:
    # A new provider (and its SDK client) per request -- simple and correct
    # for now. Constructing a GeminiProvider/AnthropicProvider does not
    # itself make a network call, so the per-request cost is small; caching
    # one provider instance on app.state (mirroring how the DB engines are
    # created once at startup) is a reasonable later optimisation, not a
    # correctness issue today.
    return get_provider(settings)


SearchServiceDep = Annotated[SearchService, Depends(get_search_service)]
RecommendationServiceDep = Annotated[
    RecommendationService, Depends(get_recommendation_service)
]
SchemeDetailServiceDep = Annotated[
    SchemeDetailService, Depends(get_scheme_detail_service)
]
LLMProviderDep = Annotated[LLMProvider, Depends(get_llm_provider)]


# ---------------------------------------------------------------------------
# Auth -- async, on the app's actual default session (db/session.py), not
# the sync carve-out above. See services/auth.py and core/security.py's
# module docstrings for why this is a self-contained layer: nothing below
# imports a scheme/search/recommendation module, and nothing above this
# line needs to import auth.
# ---------------------------------------------------------------------------

_BEARER_PREFIX = "Bearer "


def get_current_user_id(request: Request, settings: SettingsDep) -> uuid.UUID:
    """The one place an access token is read off a request. Never trusts a
    client-supplied user id anywhere else -- every authenticated route
    below derives identity from here, from the token's signature alone.
    """
    header = request.headers.get("Authorization")
    if not header or not header.startswith(_BEARER_PREFIX):
        raise AuthenticationError("Missing or malformed Authorization header.")
    token = header[len(_BEARER_PREFIX) :]
    try:
        payload = decode_access_token(token, settings)
    except InvalidTokenError as exc:
        raise AuthenticationError("Invalid or expired access token.") from exc
    return payload.user_id


CurrentUserIdDep = Annotated[uuid.UUID, Depends(get_current_user_id)]


def get_optional_current_user_id(
    request: Request, settings: SettingsDep
) -> uuid.UUID | None:
    """Like get_current_user_id, but for routes that stay public and only
    *personalize* for a signed-in caller (e.g. scheme detail's
    viewer_has_liked). No header, a malformed header, or an expired/invalid
    token all resolve to "anonymous" rather than a 401 -- the route itself
    must keep working for a signed-out visitor, so a stale token should
    degrade to the signed-out view, not break the page.
    """
    header = request.headers.get("Authorization")
    if not header or not header.startswith(_BEARER_PREFIX):
        return None
    token = header[len(_BEARER_PREFIX) :]
    try:
        payload = decode_access_token(token, settings)
    except InvalidTokenError:
        return None
    return payload.user_id


OptionalCurrentUserIdDep = Annotated[
    uuid.UUID | None, Depends(get_optional_current_user_id)
]


async def get_current_user(user_id: CurrentUserIdDep, session: SessionDep) -> User:
    """The full account row, for routes that need more than just the id
    (e.g. /auth/me). A token can outlive the account it names (deleted
    between issuance and use, deactivated) -- that case is still an
    authentication failure, not a 404, since the caller's credential is
    what's actually invalid.
    """
    user = await SqlUserRepository(session).get_by_id(user_id)
    if user is None or not user.is_active:
        raise AuthenticationError("This account is no longer available.")
    return user


CurrentUserDep = Annotated[User, Depends(get_current_user)]


def get_auth_service(session: SessionDep, settings: SettingsDep) -> AuthService:
    return AuthService(
        users=SqlUserRepository(session),
        refresh_tokens=SqlRefreshTokenRepository(session),
        settings=settings,
    )


def get_user_profile_repository(session: SessionDep) -> SqlUserProfileRepository:
    return SqlUserProfileRepository(session)


def get_saved_scheme_repository(session: SessionDep) -> SqlSavedSchemeRepository:
    return SqlSavedSchemeRepository(session)


def get_like_repository(session: SessionDep) -> SqlLikeRepository:
    return SqlLikeRepository(session)


def get_comment_repository(session: SessionDep) -> SqlCommentRepository:
    return SqlCommentRepository(session)


AuthServiceDep = Annotated[AuthService, Depends(get_auth_service)]
UserProfileRepositoryDep = Annotated[
    SqlUserProfileRepository, Depends(get_user_profile_repository)
]
SavedSchemeRepositoryDep = Annotated[
    SqlSavedSchemeRepository, Depends(get_saved_scheme_repository)
]
LikeRepositoryDep = Annotated[SqlLikeRepository, Depends(get_like_repository)]
CommentRepositoryDep = Annotated[SqlCommentRepository, Depends(get_comment_repository)]
