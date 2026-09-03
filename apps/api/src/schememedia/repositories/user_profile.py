"""Async data access for the authenticated user's eligibility profile.

See services/user_profile.py for the conversion between this ORM row and
the plain `Profile` dict the eligibility engine and recommendation service
already accept -- this module only fetches/creates the row itself.
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from schememedia.db.models.user import UserProfile


@dataclass
class SqlUserProfileRepository:
    session: AsyncSession

    async def get_or_create(self, user_id: uuid.UUID) -> UserProfile:
        """Every user has exactly one profile from the moment it is first
        read -- callers never have to branch on "does a profile exist yet"
        (every field starts NULL/unknown, which is exactly the honest
        starting state anyway, see UserProfile's own docstring).
        """
        profile = await self.session.scalar(
            select(UserProfile).where(UserProfile.user_id == user_id)
        )
        if profile is None:
            profile = UserProfile(user_id=user_id)
            self.session.add(profile)
            await self.session.flush()
        return profile
