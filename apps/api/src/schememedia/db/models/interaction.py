"""User/scheme interactions.

v1 stored likes, saves, and ratings in one table keyed by an interaction_type
string with a nullable rating_value. Nothing prevented a rating of 47, a "like"
carrying a rating, or the same scheme being liked twice. Splitting them lets the
database enforce what the application means.
"""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import (
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    String,
    func,
    text,
)
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from schememedia.db.models.base import Base

if TYPE_CHECKING:
    from schememedia.db.models.scheme import Scheme
    from schememedia.db.models.user import User


class SchemeLike(Base):
    """A like. The composite primary key makes a double-like impossible."""

    __tablename__ = "scheme_likes"

    user_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True,
    )
    scheme_id: Mapped[str] = mapped_column(
        String(64),
        ForeignKey("schemes.scheme_id", ondelete="CASCADE"),
        primary_key=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    user: Mapped[User] = relationship(back_populates="likes")
    scheme: Mapped[Scheme] = relationship(back_populates="likes")

    # Reverse lookup: "who liked this scheme?" and the collaborative-filtering
    # query both traverse scheme -> users.
    __table_args__ = (Index("ix_scheme_likes_scheme_id", "scheme_id"),)


class SchemeSave(Base):
    """A bookmark."""

    __tablename__ = "scheme_saves"

    user_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True,
    )
    scheme_id: Mapped[str] = mapped_column(
        String(64),
        ForeignKey("schemes.scheme_id", ondelete="CASCADE"),
        primary_key=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    user: Mapped[User] = relationship(back_populates="saves")
    scheme: Mapped[Scheme] = relationship(back_populates="saves")

    __table_args__ = (
        Index("ix_scheme_saves_scheme_id", "scheme_id"),
        # The Saved tab lists a user's saves newest-first.
        Index("ix_scheme_saves_user_created", "user_id", text("created_at DESC")),
    )


class SchemeRating(Base):
    """A 1-5 rating. One per user per scheme, updatable in place."""

    __tablename__ = "scheme_ratings"

    user_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True,
    )
    scheme_id: Mapped[str] = mapped_column(
        String(64),
        ForeignKey("schemes.scheme_id", ondelete="CASCADE"),
        primary_key=True,
    )
    rating: Mapped[int] = mapped_column(Integer, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )

    user: Mapped[User] = relationship(back_populates="ratings")
    scheme: Mapped[Scheme] = relationship(back_populates="ratings")

    __table_args__ = (
        CheckConstraint("rating BETWEEN 1 AND 5", name="rating_range"),
        Index("ix_scheme_ratings_scheme_id", "scheme_id"),
    )
