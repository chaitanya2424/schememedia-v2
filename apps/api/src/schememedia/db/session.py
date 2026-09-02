"""Database engine and session management.

The session dependency below always terminates its transaction: commit on
success, rollback on exception, close in every case. v1's get_db() yielded a
raw connection and did neither, so read endpoints returned connections to the
pool still "idle in transaction", and after any error the aborted transaction
travelled with the connection -- every later request reusing it failed with
"current transaction is aborted".
"""

from __future__ import annotations

from collections.abc import AsyncGenerator
from typing import Any

from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from schememedia.core.config import Settings
from schememedia.core.logging import get_logger

logger = get_logger(__name__)

_engine: AsyncEngine | None = None
_session_factory: async_sessionmaker[AsyncSession] | None = None


def init_engine(settings: Settings) -> AsyncEngine:
    """Create the engine and session factory. Called once during startup."""
    global _engine, _session_factory

    if _engine is not None:
        return _engine

    connect_args: dict[str, Any] = {}
    if settings.db_disable_statement_cache:
        # Required behind PgBouncer in transaction mode (Neon's pooled
        # endpoint). Without it asyncpg raises DuplicatePreparedStatementError
        # under concurrency, intermittently and confusingly.
        connect_args["statement_cache_size"] = 0
        connect_args["prepared_statement_cache_size"] = 0

    _engine = create_async_engine(
        settings.sqlalchemy_url,
        echo=settings.db_echo,
        pool_size=settings.db_pool_size,
        max_overflow=settings.db_max_overflow,
        pool_timeout=settings.db_pool_timeout_seconds,
        pool_recycle=settings.db_pool_recycle_seconds,
        pool_pre_ping=True,  # survives Neon idle-connection drops
        connect_args=connect_args,
    )

    _session_factory = async_sessionmaker(
        bind=_engine,
        class_=AsyncSession,
        expire_on_commit=False,
        autoflush=False,
    )

    logger.info(
        "database_engine_initialised",
        pool_size=settings.db_pool_size,
        statement_cache_disabled=settings.db_disable_statement_cache,
    )
    return _engine


async def dispose_engine() -> None:
    """Close all pooled connections. Called during shutdown."""
    global _engine, _session_factory
    if _engine is not None:
        await _engine.dispose()
        logger.info("database_engine_disposed")
    _engine = None
    _session_factory = None


def get_engine() -> AsyncEngine:
    if _engine is None:
        raise RuntimeError("Database engine not initialised. Call init_engine first.")
    return _engine


async def get_session() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI dependency yielding a session with a guaranteed clean exit."""
    if _session_factory is None:
        raise RuntimeError("Session factory not initialised. Call init_engine first.")

    session = _session_factory()
    try:
        yield session
        await session.commit()
    except Exception:
        await session.rollback()
        raise
    finally:
        await session.close()
