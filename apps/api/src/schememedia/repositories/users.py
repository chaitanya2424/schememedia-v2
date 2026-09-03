"""Async data access for accounts.

Async, unlike the search/recommendation/eligibility repositories -- those
are sync for a specific, documented reason (db/sync_session.py: reusing
already-tested batch-job code) that does not apply here. This is new,
simple CRUD against the live API's actual default session (db/session.py).
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import UTC, datetime

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from schememedia.db.models.user import User


@dataclass
class SqlUserRepository:
    session: AsyncSession

    async def get_by_email(self, email: str) -> User | None:
        """`email` must already be lowercased by the caller -- see User's
        own docstring ("Lowercased at the application boundary; the unique
        index below is on lower(email)").
        """
        return await self.session.scalar(  # type: ignore[no-any-return]
            select(User).where(User.email == email)
        )

    async def get_by_id(self, user_id: uuid.UUID) -> User | None:
        return await self.session.get(User, user_id)

    async def create(
        self, *, email: str, password_hash: str, full_name: str | None
    ) -> User:
        user = User(email=email, password_hash=password_hash, full_name=full_name)
        self.session.add(user)
        await self.session.flush()  # populates user.id without ending the transaction
        return user

    async def touch_last_login(self, user_id: uuid.UUID) -> None:
        await self.session.execute(
            update(User).where(User.id == user_id).values(last_login_at=datetime.now(UTC))
        )
