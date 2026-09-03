"""Aggregate router for API v1.

Feature routers (interactions, comments, admin) are registered here as
later phases add them. auth/profile/saved_schemes landed together: the
account model those three depend on (User, UserProfile, RefreshToken,
SchemeSave) already existed, unused, since the initial migration.
"""

from __future__ import annotations

from fastapi import APIRouter

from schememedia.api.v1.routers import (
    assistant,
    auth,
    profile,
    recommendations,
    saved_schemes,
    schemes,
    search,
)

api_router = APIRouter()

api_router.include_router(search.router)
api_router.include_router(recommendations.router)
api_router.include_router(schemes.router)
api_router.include_router(assistant.router)
api_router.include_router(auth.router)
api_router.include_router(profile.router)
api_router.include_router(saved_schemes.router)
