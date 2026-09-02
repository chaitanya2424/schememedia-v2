"""Application factory.

This module wires the application together and contains no business logic.
v1's main.py was 403 lines of routes with raw SQL, caching, and Gemini calls
inline, which made every piece of it untestable without a live database.
"""

from __future__ import annotations

from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware

from schememedia.api.v1.router import api_router
from schememedia.api.v1.routers import health
from schememedia.core.config import Settings, get_settings
from schememedia.core.errors import register_exception_handlers
from schememedia.core.logging import configure_logging, get_logger
from schememedia.core.middleware import RequestContextMiddleware
from schememedia.db.session import dispose_engine, init_engine
from schememedia.db.sync_session import dispose_sync_engine, init_sync_engine

logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Start and stop long-lived resources.

    The engine is created eagerly but no connection is opened here: startup
    must not fail because a database is briefly unreachable. /ready reports
    the true state, and pool_pre_ping recovers dropped connections.
    """
    settings: Settings = app.state.settings
    logger.info("application_starting", environment=settings.app_env)

    init_engine(settings)
    # Second pool: search/recommendation/assistant routes call the existing
    # sync services (SearchService, RecommendationService) via
    # run_in_threadpool rather than duplicating them as async -- see
    # db/sync_session.py's module docstring.
    init_sync_engine(settings)

    yield

    await dispose_engine()
    dispose_sync_engine()
    logger.info("application_stopped")


def create_app(settings: Settings | None = None) -> FastAPI:
    """Build the application. Accepts injected settings for tests."""
    settings = settings or get_settings()

    configure_logging(level=settings.log_level, json_output=settings.log_json)

    app = FastAPI(
        title=settings.app_name,
        version="2.0.0",
        lifespan=lifespan,
        # Interactive docs are useful everywhere except production.
        docs_url=None if settings.is_production else "/docs",
        redoc_url=None,
        openapi_url=None if settings.is_production else "/openapi.json",
    )
    app.state.settings = settings

    # Order matters: request context is outermost so every later layer,
    # including error handlers, sees the request ID.
    app.add_middleware(RequestContextMiddleware)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
        allow_headers=["Authorization", "Content-Type", "X-Request-ID"],
        expose_headers=["X-Request-ID"],
    )
    # Audit finding M2: no response compression at all. A 20-result
    # /recommendations response measured ~30KB uncompressed during frontend
    # testing -- real cost on mobile. Default 500-byte floor skips
    # compressing tiny responses (health checks, short errors) where gzip's
    # own overhead isn't worth it.
    app.add_middleware(GZipMiddleware, minimum_size=500)

    register_exception_handlers(app)

    # Probes stay unversioned; orchestrators should not chase API versions.
    app.include_router(health.router)
    app.include_router(api_router, prefix=settings.api_v1_prefix)

    return app


# Intentionally no module-level `app = create_app()`.
# Importing this module must not construct the application: doing so reads
# configuration at import time, which breaks test settings injection and turns
# a missing environment variable into an import error.
# Run with:  uvicorn schememedia.main:create_app --factory
