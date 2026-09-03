"""Async data access for bookmarked schemes.

Built on SchemeSave (db/models/interaction.py), which already existed,
unused, with exactly the shape this needs: a composite (user_id, scheme_id)
primary key, so the database itself makes a duplicate save impossible --
`save()` below is `ON CONFLICT DO NOTHING` against that same key, not a
second application-level dedup check.
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import datetime

from sqlalchemy import delete, select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession

from schememedia.db.models import Category, Scheme
from schememedia.db.models.interaction import SchemeSave


@dataclass(frozen=True)
class SavedSchemeRow:
    """The same fields SearchResult carries (services/search.py) -- a saved
    scheme is presented with identical provenance to a search result, per
    the "preserve existing verification/provenance fields" requirement --
    plus `saved_at`, which only makes sense in this context.
    """

    scheme_id: str
    slug: str
    name: str
    description_short: str | None
    category: str | None
    jurisdiction: str
    state_code: str | None
    scheme_type: str
    verification_status: str
    needs_review: bool
    official_url: str | None
    saved_at: datetime


@dataclass
class SqlSavedSchemeRepository:
    session: AsyncSession

    async def list_for_user(self, user_id: uuid.UUID) -> list[SavedSchemeRow]:
        rows = (
            await self.session.execute(
                select(
                    Scheme.scheme_id,
                    Scheme.slug,
                    Scheme.name,
                    Scheme.description_short,
                    Category.name.label("category"),
                    Scheme.jurisdiction,
                    Scheme.state_code,
                    Scheme.scheme_type,
                    Scheme.verification_status,
                    Scheme.needs_review,
                    Scheme.official_url,
                    SchemeSave.created_at.label("saved_at"),
                )
                .select_from(SchemeSave)
                .join(Scheme, Scheme.scheme_id == SchemeSave.scheme_id)
                .outerjoin(Category, Category.id == Scheme.category_id)
                .where(SchemeSave.user_id == user_id, Scheme.is_active.is_(True))
                # Newest first -- matches SchemeSave's own
                # ix_scheme_saves_user_created index.
                .order_by(SchemeSave.created_at.desc())
            )
        ).all()
        return [
            SavedSchemeRow(
                scheme_id=r.scheme_id,
                slug=r.slug,
                name=r.name,
                description_short=r.description_short,
                category=r.category,
                jurisdiction=r.jurisdiction.value,
                state_code=r.state_code,
                scheme_type=r.scheme_type.value,
                verification_status=r.verification_status.value,
                needs_review=r.needs_review,
                official_url=r.official_url,
                saved_at=r.saved_at,
            )
            for r in rows
        ]

    async def scheme_exists(self, scheme_id: str) -> bool:
        result = await self.session.scalar(
            select(Scheme.scheme_id).where(
                Scheme.scheme_id == scheme_id, Scheme.is_active.is_(True)
            )
        )
        return result is not None

    async def is_saved(self, user_id: uuid.UUID, scheme_id: str) -> bool:
        result = await self.session.scalar(
            select(SchemeSave).where(
                SchemeSave.user_id == user_id, SchemeSave.scheme_id == scheme_id
            )
        )
        return result is not None

    async def save(self, user_id: uuid.UUID, scheme_id: str) -> None:
        await self.session.execute(
            pg_insert(SchemeSave)
            .values(user_id=user_id, scheme_id=scheme_id)
            .on_conflict_do_nothing(index_elements=["user_id", "scheme_id"])
        )

    async def unsave(self, user_id: uuid.UUID, scheme_id: str) -> None:
        await self.session.execute(
            delete(SchemeSave).where(
                SchemeSave.user_id == user_id, SchemeSave.scheme_id == scheme_id
            )
        )
