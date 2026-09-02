"""Aggregate router for API v1.

Feature routers (auth, interactions, comments, profile, admin) are
registered here as later phases add them.
"""

from __future__ import annotations

from fastapi import APIRouter

from schememedia.api.v1.routers import assistant, recommendations, schemes, search

api_router = APIRouter()

api_router.include_router(search.router)
api_router.include_router(recommendations.router)
api_router.include_router(schemes.router)
api_router.include_router(assistant.router)
