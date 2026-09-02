"""Shared FastAPI dependencies.

Routes resolve settings through app.state rather than the module-level
get_settings() cache. The global cache reads the process environment, which
silently ignores injected configuration and makes tests exercise a different
application than the one under test.
"""

from __future__ import annotations

from collections.abc import Iterator
from typing import Annotated

from fastapi import Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from schememedia.core.config import Settings
from schememedia.db import sync_session
from schememedia.db.session import get_session
from schememedia.repositories.eligibility import SqlEligibilityRuleRepository
from schememedia.repositories.schemes import SqlSchemeRepository
from schememedia.repositories.search import PgVectorRetriever, SqlKeywordRetriever
from schememedia.services.providers import get_provider
from schememedia.services.providers.base import LLMProvider
from schememedia.services.recommendation import RecommendationService
from schememedia.services.scheme_detail import SchemeDetailService
from schememedia.services.search import SearchService


def get_app_settings(request: Request) -> Settings:
    settings: Settings = request.app.state.settings
    return settings


SettingsDep = Annotated[Settings, Depends(get_app_settings)]
SessionDep = Annotated[AsyncSession, Depends(get_session)]


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
