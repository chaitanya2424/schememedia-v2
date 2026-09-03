"""Liking a scheme.

Mirrors api/v1/routers/saved_schemes.py's shape exactly -- same
idempotent-toggle pattern, same repository style -- built on SchemeLike
(db/models/interaction.py), which already existed, unused, with the exact
shape this needs. `like_count` is maintained by a DB trigger (see
repositories/likes.py's module docstring), not touched here.
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Path, status

from schememedia.core.deps import CurrentUserDep, LikeRepositoryDep
from schememedia.core.errors import ErrorEnvelopeOut, NotFoundError

router = APIRouter(prefix="/schemes/{scheme_id}/like", tags=["likes"])


@router.post(
    "",
    status_code=status.HTTP_204_NO_CONTENT,
    operation_id="likeScheme",
    summary="Like a scheme (idempotent -- liking an already-liked scheme is a no-op)",
    responses={
        404: {
            "model": ErrorEnvelopeOut,
            "description": "No active scheme matches this scheme_id.",
        }
    },
)
async def like_scheme(
    user: CurrentUserDep,
    likes: LikeRepositoryDep,
    scheme_id: Annotated[str, Path(description="A scheme's canonical scheme_id.")],
) -> None:
    if not await likes.scheme_exists(scheme_id):
        raise NotFoundError(f"No scheme found for {scheme_id!r}.")
    await likes.like(user.id, scheme_id)


@router.delete(
    "",
    status_code=status.HTTP_204_NO_CONTENT,
    operation_id="unlikeScheme",
    summary="Remove a like (idempotent -- unliking an unliked scheme is a no-op)",
)
async def unlike_scheme(
    user: CurrentUserDep,
    likes: LikeRepositoryDep,
    scheme_id: Annotated[str, Path(description="A scheme's canonical scheme_id.")],
) -> None:
    await likes.unlike(user.id, scheme_id)
