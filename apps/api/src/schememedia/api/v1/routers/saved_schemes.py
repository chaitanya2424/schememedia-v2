"""The authenticated user's bookmarked schemes.

Built on SqlSavedSchemeRepository (repositories/saved_schemes.py), which is
built on SchemeSave (db/models/interaction.py) -- a table that already
existed, unused, with a composite (user_id, scheme_id) primary key, so a
duplicate save is impossible at the database level, not just checked in
application code.
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Path, status
from pydantic import BaseModel

from schememedia.api.v1.schemas.common import (
    JurisdictionOut,
    SchemeTypeOut,
    VerificationStatusOut,
)
from schememedia.core.deps import CurrentUserDep, SavedSchemeRepositoryDep
from schememedia.core.errors import ErrorEnvelopeOut, NotFoundError
from schememedia.repositories.saved_schemes import SavedSchemeRow

router = APIRouter(prefix="/me/saved-schemes", tags=["saved-schemes"])


class SavedSchemeOut(BaseModel):
    scheme_id: str
    slug: str
    name: str
    description_short: str | None
    category: str | None
    jurisdiction: JurisdictionOut
    state_code: str | None
    scheme_type: SchemeTypeOut
    # Preserved unchanged from the scheme row, same as every other list
    # endpoint (search, recommendations) -- a saved scheme is never shown
    # as more trustworthy than it actually is just because it was saved.
    verification_status: VerificationStatusOut
    needs_review: bool
    official_url: str | None
    saved_at: str

    @classmethod
    def from_domain(cls, row: SavedSchemeRow) -> SavedSchemeOut:
        return cls(
            scheme_id=row.scheme_id,
            slug=row.slug,
            name=row.name,
            description_short=row.description_short,
            category=row.category,
            jurisdiction=row.jurisdiction,
            state_code=row.state_code,
            scheme_type=row.scheme_type,
            verification_status=row.verification_status,
            needs_review=row.needs_review,
            official_url=row.official_url,
            saved_at=row.saved_at.isoformat(),
        )


class SavedSchemesResponseOut(BaseModel):
    schemes: list[SavedSchemeOut]
    total_count: int


@router.get(
    "",
    response_model=SavedSchemesResponseOut,
    operation_id="listSavedSchemes",
    summary="Schemes the signed-in user has saved, newest first",
)
async def list_saved_schemes(
    user: CurrentUserDep, saved: SavedSchemeRepositoryDep
) -> SavedSchemesResponseOut:
    rows = await saved.list_for_user(user.id)
    return SavedSchemesResponseOut(
        schemes=[SavedSchemeOut.from_domain(r) for r in rows], total_count=len(rows)
    )


@router.post(
    "/{scheme_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    operation_id="saveScheme",
    summary="Save a scheme (idempotent -- saving an already-saved scheme is a no-op)",
    responses={
        404: {
            "model": ErrorEnvelopeOut,
            "description": "No active scheme matches this scheme_id.",
        }
    },
)
async def save_scheme(
    user: CurrentUserDep,
    saved: SavedSchemeRepositoryDep,
    scheme_id: Annotated[str, Path(description="A scheme's canonical scheme_id.")],
) -> None:
    if not await saved.scheme_exists(scheme_id):
        raise NotFoundError(f"No scheme found for {scheme_id!r}.")
    await saved.save(user.id, scheme_id)


@router.delete(
    "/{scheme_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    operation_id="unsaveScheme",
    summary="Remove a saved scheme (idempotent -- unsaving an unsaved scheme is a no-op)",
)
async def unsave_scheme(
    user: CurrentUserDep,
    saved: SavedSchemeRepositoryDep,
    scheme_id: Annotated[str, Path(description="A scheme's canonical scheme_id.")],
) -> None:
    await saved.unsave(user.id, scheme_id)
