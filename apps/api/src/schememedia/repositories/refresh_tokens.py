"""Async data access for refresh-token grants.

See core/security.py's module docstring for the token scheme this stores,
and db/models/user.py's RefreshToken for why only a hash is ever persisted.
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import UTC, datetime

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from schememedia.db.models.user import RefreshToken


@dataclass
class SqlRefreshTokenRepository:
    session: AsyncSession

    async def create(
        self,
        *,
        user_id: uuid.UUID,
        token_hash: str,
        expires_at: datetime,
        user_agent: str | None = None,
        ip_address: str | None = None,
    ) -> RefreshToken:
        token = RefreshToken(
            user_id=user_id,
            token_hash=token_hash,
            expires_at=expires_at,
            user_agent=user_agent,
            ip_address=ip_address,
        )
        self.session.add(token)
        await self.session.flush()
        return token

    async def get_by_hash(self, token_hash: str) -> RefreshToken | None:
        return await self.session.scalar(  # type: ignore[no-any-return]
            select(RefreshToken).where(RefreshToken.token_hash == token_hash)
        )

    async def revoke(
        self, token_id: uuid.UUID, *, replaced_by_id: uuid.UUID | None = None
    ) -> None:
        values: dict[str, object] = {"revoked_at": datetime.now(UTC)}
        if replaced_by_id is not None:
            values["replaced_by_id"] = replaced_by_id
        await self.session.execute(
            update(RefreshToken).where(RefreshToken.id == token_id).values(**values)
        )

    async def revoke_all_for_user(self, user_id: uuid.UUID) -> None:
        """Called when a rotated/revoked token is presented again -- the
        standard signal of token theft (see core/security.py). Every
        currently-active refresh token for this user is revoked, forcing a
        fresh login everywhere.
        """
        await self.session.execute(
            update(RefreshToken)
            .where(RefreshToken.user_id == user_id, RefreshToken.revoked_at.is_(None))
            .values(revoked_at=datetime.now(UTC))
        )
