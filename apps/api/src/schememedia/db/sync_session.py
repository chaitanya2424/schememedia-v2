"""Sync database engine -- for request-time code that reuses the existing
sync-session services (SearchService, RecommendationService, the
eligibility repository) rather than forking them into parallel async
implementations.

Those services were built for the importer, the embedding CLI, and their
own test suites -- all one-shot batch jobs, where a sync Session is the
right choice (see importer/pipeline.py's module docstring). The live API is
fully async (db/session.py). Rather than duplicate four already-tested
modules into async twins that could silently drift from the originals, API
routes call the sync services through `starlette.concurrency.run_in_threadpool`
(see core/deps.py) -- the standard, FastAPI-documented pattern for a sync
data-access layer inside an async app.

The cost is a second connection pool. That is a deliberate, bounded trade:
this module is a near-exact mirror of db/session.py (same lifecycle
functions, same init-once-at-startup shape) so the two stay easy to compare
and reason about side by side, rather than introducing a third pattern.
"""

from __future__ import annotations

from sqlalchemy import create_engine
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, sessionmaker

from schememedia.core.config import Settings
from schememedia.core.logging import get_logger
from schememedia.importer.pipeline import sync_database_url

logger = get_logger(__name__)

_engine: Engine | None = None
_session_factory: sessionmaker[Session] | None = None


def init_sync_engine(settings: Settings) -> Engine:
    """Create the sync engine and session factory. Called once during startup."""
    global _engine, _session_factory

    if _engine is not None:
        return _engine

    _engine = create_engine(
        sync_database_url(str(settings.database_url)),
        pool_size=settings.db_pool_size,
        max_overflow=settings.db_max_overflow,
        pool_timeout=settings.db_pool_timeout_seconds,
        pool_recycle=settings.db_pool_recycle_seconds,
        pool_pre_ping=True,
        echo=settings.db_echo,
    )
    _session_factory = sessionmaker(bind=_engine, expire_on_commit=False, autoflush=False)

    logger.info("sync_database_engine_initialised", pool_size=settings.db_pool_size)
    return _engine


def dispose_sync_engine() -> None:
    """Close all pooled connections. Called during shutdown."""
    global _engine, _session_factory
    if _engine is not None:
        _engine.dispose()
        logger.info("sync_database_engine_disposed")
    _engine = None
    _session_factory = None


def get_sync_session() -> Session:
    """A new sync Session from the shared pool. Caller closes it.

    Unlike db/session.py's get_session (an async generator FastAPI can wrap
    a request's whole lifetime around), this returns a plain Session --
    callers use it inside a single run_in_threadpool call, then close it
    explicitly. See core/deps.py.
    """
    if _session_factory is None:
        raise RuntimeError(
            "Sync session factory not initialised. Call init_sync_engine first."
        )
    return _session_factory()
