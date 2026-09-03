"""Async data access for scheme likes.

Mirrors repositories/saved_schemes.py exactly: built on SchemeLike
(db/models/interaction.py), which already existed, unused, with the same
composite (user_id, scheme_id) primary key shape -- `like()` is
`ON CONFLICT DO NOTHING` against that key, so a double-like is impossible
at the database level. The `like_count` on `schemes` is maintained by a DB
trigger (migrations/versions/4e8790001be5_counter_triggers.py), not here.
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass

from sqlalchemy import delete, select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession

from schememedia.db.models import Scheme
from schememedia.db.models.interaction import SchemeLike


@dataclass
class SqlLikeRepository:
    session: AsyncSession

    async def scheme_exists(self, scheme_id: str) -> bool:
        result = await self.session.scalar(
            select(Scheme.scheme_id).where(
                Scheme.scheme_id == scheme_id, Scheme.is_active.is_(True)
            )
        )
        return result is not None

    async def is_liked(self, user_id: uuid.UUID, scheme_id: str) -> bool:
        result = await self.session.scalar(
            select(SchemeLike).where(
                SchemeLike.user_id == user_id, SchemeLike.scheme_id == scheme_id
            )
        )
        return result is not None

    async def like(self, user_id: uuid.UUID, scheme_id: str) -> None:
        await self.session.execute(
            pg_insert(SchemeLike)
            .values(user_id=user_id, scheme_id=scheme_id)
            .on_conflict_do_nothing(index_elements=["user_id", "scheme_id"])
        )

    async def unlike(self, user_id: uuid.UUID, scheme_id: str) -> None:
        await self.session.execute(
            delete(SchemeLike).where(
                SchemeLike.user_id == user_id, SchemeLike.scheme_id == scheme_id
            )
        )
