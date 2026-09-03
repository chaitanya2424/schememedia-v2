"""Comments on a scheme.

Top-level only for this iteration -- see repositories/comments.py's module
docstring on why nesting is additive later, not a redesign. Listing is
public (comments are discovery content, same spirit as search/scheme
detail); creating and deleting require auth, and a user may only delete
their own comment. `comment_count` is maintained by a DB trigger, not
touched here -- see repositories/comments.py.
"""

from __future__ import annotations

import uuid
from typing import Annotated

from fastapi import APIRouter, Body, Path, Request, status
from pydantic import BaseModel, Field

from schememedia.core.deps import (
    CommentRepositoryDep,
    CurrentUserDep,
    OptionalCurrentUserIdDep,
)
from schememedia.core.errors import (
    ErrorEnvelopeOut,
    NotFoundError,
    PermissionDeniedError,
)
from schememedia.core.rate_limit import COMMENT_CREATE_LIMIT, limiter
from schememedia.repositories.comments import CommentRow

router = APIRouter(prefix="/schemes/{scheme_id}/comments", tags=["comments"])


class CommentOut(BaseModel):
    id: str
    content: str
    created_at: str
    edited: bool
    # Anonymised if the author's account was later deactivated/deleted --
    # the comment survives (soft-deleted accounts keep threads intact, see
    # User.deleted_at's docstring), the byline just can't be attributed.
    author_name: str | None
    # Whether the signed-in caller wrote this comment -- the only way the
    # frontend can safely offer a delete control, since the comment's own
    # user_id is never sent to the client. False (not null) for a
    # signed-out caller: "not mine" is unambiguous even without an account.
    viewer_is_author: bool

    @classmethod
    def from_domain(cls, row: CommentRow, *, viewer_id: uuid.UUID | None) -> CommentOut:
        return cls(
            id=str(row.id),
            content=row.content,
            created_at=row.created_at.isoformat(),
            edited=row.edited_at is not None,
            author_name=row.author_name,
            viewer_is_author=viewer_id is not None and viewer_id == row.user_id,
        )


class CommentsResponseOut(BaseModel):
    comments: list[CommentOut]
    total_count: int


class CommentCreateRequest(BaseModel):
    content: Annotated[str, Field(min_length=1, max_length=5000)]


@router.get(
    "",
    response_model=CommentsResponseOut,
    operation_id="listComments",
    summary="Comments on a scheme, newest first (public)",
)
async def list_comments(
    comments: CommentRepositoryDep,
    viewer_id: OptionalCurrentUserIdDep,
    scheme_id: Annotated[str, Path(description="A scheme's canonical scheme_id.")],
) -> CommentsResponseOut:
    rows = await comments.list_for_scheme(scheme_id)
    return CommentsResponseOut(
        comments=[CommentOut.from_domain(r, viewer_id=viewer_id) for r in rows],
        total_count=len(rows),
    )


@router.post(
    "",
    response_model=CommentOut,
    status_code=status.HTTP_201_CREATED,
    operation_id="createComment",
    summary="Post a comment on a scheme",
    responses={
        404: {
            "model": ErrorEnvelopeOut,
            "description": "No active scheme matches this scheme_id.",
        }
    },
)
@limiter.limit(COMMENT_CREATE_LIMIT)
async def create_comment(
    request: Request,  # required by @limiter.limit -- see its own docstring
    user: CurrentUserDep,
    comments: CommentRepositoryDep,
    scheme_id: Annotated[str, Path(description="A scheme's canonical scheme_id.")],
    body: Annotated[CommentCreateRequest, Body()],
) -> CommentOut:
    if not await comments.scheme_exists(scheme_id):
        raise NotFoundError(f"No scheme found for {scheme_id!r}.")
    row = await comments.create(user.id, scheme_id, body.content.strip())
    return CommentOut.from_domain(row, viewer_id=user.id)


@router.delete(
    "/{comment_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    operation_id="deleteComment",
    summary="Delete your own comment",
    responses={
        403: {
            "model": ErrorEnvelopeOut,
            "description": "The comment belongs to a different user.",
        },
        404: {
            "model": ErrorEnvelopeOut,
            "description": "No comment matches this comment_id.",
        },
    },
)
async def delete_comment(
    user: CurrentUserDep,
    comments: CommentRepositoryDep,
    scheme_id: Annotated[str, Path(description="A scheme's canonical scheme_id.")],
    comment_id: Annotated[str, Path(description="The comment's id.")],
) -> None:
    try:
        parsed_id = uuid.UUID(comment_id)
    except ValueError as exc:
        raise NotFoundError(f"No comment found for {comment_id!r}.") from exc

    owner_id = await comments.get_owner(scheme_id, parsed_id)
    if owner_id is None:
        raise NotFoundError(f"No comment found for {comment_id!r}.")
    if owner_id != user.id:
        raise PermissionDeniedError("You can only delete your own comment.")
    await comments.soft_delete(parsed_id)
