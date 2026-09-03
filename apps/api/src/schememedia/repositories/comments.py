"""Async data access for scheme comments.

Top-level comments only for this iteration -- `Comment.parent_id` already
supports threaded replies (db/models/content.py), so nesting is additive
later, not a redesign. `comment_count` on `schemes` is maintained by a DB
trigger (migrations/versions/4e8790001be5_counter_triggers.py) that follows
`deleted_at`, which is why delete here is a soft delete, not a row removal
-- v1's history here (see Comment's own docstring) is exactly the failure
mode this repository is built to make impossible: every write goes through
the same table the trigger and the read path both see.
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import datetime

from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from schememedia.db.models import Comment, Scheme, User


@dataclass(frozen=True)
class CommentRow:
    id: uuid.UUID
    content: str
    created_at: datetime
    edited_at: datetime | None
    user_id: uuid.UUID | None
    author_name: str | None


@dataclass
class SqlCommentRepository:
    session: AsyncSession

    async def scheme_exists(self, scheme_id: str) -> bool:
        result = await self.session.scalar(
            select(Scheme.scheme_id).where(
                Scheme.scheme_id == scheme_id, Scheme.is_active.is_(True)
            )
        )
        return result is not None

    async def list_for_scheme(self, scheme_id: str) -> list[CommentRow]:
        rows = (
            await self.session.execute(
                select(
                    Comment.id,
                    Comment.content,
                    Comment.created_at,
                    Comment.edited_at,
                    Comment.user_id,
                    User.full_name.label("author_name"),
                )
                .join(User, User.id == Comment.user_id, isouter=True)
                .where(
                    Comment.scheme_id == scheme_id,
                    Comment.parent_id.is_(None),
                    Comment.deleted_at.is_(None),
                    Comment.hidden_at.is_(None),
                )
                # Matches ix_comments_scheme_created's own ordering.
                .order_by(Comment.created_at.desc())
            )
        ).all()
        return [
            CommentRow(
                id=r.id,
                content=r.content,
                created_at=r.created_at,
                edited_at=r.edited_at,
                user_id=r.user_id,
                author_name=r.author_name,
            )
            for r in rows
        ]

    async def create(
        self, user_id: uuid.UUID, scheme_id: str, content: str
    ) -> CommentRow:
        comment = Comment(user_id=user_id, scheme_id=scheme_id, content=content)
        self.session.add(comment)
        await self.session.flush()
        user = await self.session.get(User, user_id)
        return CommentRow(
            id=comment.id,
            content=comment.content,
            created_at=comment.created_at,
            edited_at=comment.edited_at,
            user_id=comment.user_id,
            author_name=user.full_name if user else None,
        )

    async def get_owner(self, scheme_id: str, comment_id: uuid.UUID) -> uuid.UUID | None:
        return await self.session.scalar(
            select(Comment.user_id).where(
                Comment.id == comment_id,
                Comment.scheme_id == scheme_id,
                Comment.deleted_at.is_(None),
            )
        )

    async def soft_delete(self, comment_id: uuid.UUID) -> None:
        await self.session.execute(
            update(Comment).where(Comment.id == comment_id).values(deleted_at=func.now())
        )
