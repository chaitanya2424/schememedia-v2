"""Liveness and readiness probes.

/health  -- is the process alive? No dependencies. Never fails while running.
/ready   -- can it serve traffic? Checks dependencies, returns 503 if not.

Keeping these separate matters for deployment: an orchestrator restarts on a
failed liveness probe but merely withholds traffic on a failed readiness probe.
Collapsing them into one endpoint causes restart loops when the database blips.
"""

from __future__ import annotations

from typing import Literal

from fastapi import APIRouter, Response, status
from pydantic import BaseModel
from sqlalchemy import text

from schememedia.core.deps import SettingsDep
from schememedia.core.logging import get_logger
from schememedia.db import session as db_session

logger = get_logger(__name__)

router = APIRouter(tags=["health"])


class HealthResponse(BaseModel):
    status: Literal["ok"]
    app: str
    environment: str


class DependencyStatus(BaseModel):
    name: str
    status: Literal["ok", "unavailable"]
    detail: str | None = None


class ReadinessResponse(BaseModel):
    status: Literal["ready", "degraded"]
    dependencies: list[DependencyStatus]


@router.get(
    "/health",
    response_model=HealthResponse,
    operation_id="getHealth",
    summary="Liveness probe",
)
async def health(settings: SettingsDep) -> HealthResponse:
    return HealthResponse(
        status="ok",
        app=settings.app_name,
        environment=settings.app_env,
    )


@router.get(
    "/ready",
    response_model=ReadinessResponse,
    operation_id="getReadiness",
    summary="Readiness probe",
)
async def ready(response: Response) -> ReadinessResponse:
    dependencies: list[DependencyStatus] = []

    try:
        engine = db_session.get_engine()
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
        dependencies.append(DependencyStatus(name="database", status="ok"))
    except Exception as exc:
        logger.warning(
            "readiness_check_failed", dependency="database", error_type=type(exc).__name__
        )
        dependencies.append(
            DependencyStatus(
                name="database",
                status="unavailable",
                # A fixed, generic string -- never the driver exception's own
                # type name. Some driver exceptions (e.g. asyncpg's
                # InvalidPasswordError) embed words like "password" in their
                # own class name, which would otherwise leak into the
                # response even though no credential value is involved. The
                # full type name is still logged above for debugging.
                detail="connection_error",
            )
        )

    all_ok = all(dep.status == "ok" for dep in dependencies)
    if not all_ok:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE

    return ReadinessResponse(
        status="ready" if all_ok else "degraded",
        dependencies=dependencies,
    )
