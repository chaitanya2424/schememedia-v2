"""User accounts, eligibility profiles, and session tokens."""

from __future__ import annotations

import uuid
from datetime import date, datetime
from typing import TYPE_CHECKING, Any

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    Enum,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    String,
    Text,
    UniqueConstraint,
    column,
    func,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from schememedia.db.models.base import Base, TimestampMixin, UUIDPrimaryKeyMixin
from schememedia.db.models.enums import UserRole

if TYPE_CHECKING:
    from schememedia.db.models.content import Comment, Notification
    from schememedia.db.models.interaction import SchemeLike, SchemeRating, SchemeSave


class User(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """An account.

    Authentication data only. Everything used for eligibility matching lives
    on UserProfile, so the two can be authorised and audited separately --
    profiles hold caste, disability, and income data under the DPDP Act.
    """

    __tablename__ = "users"

    email: Mapped[str] = mapped_column(String(320), nullable=False)
    # Lowercased at the application boundary; the unique index below is on
    # lower(email) so "A@b.com" and "a@b.com" cannot both register.
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str | None] = mapped_column(String(200))
    phone: Mapped[str | None] = mapped_column(String(20))

    role: Mapped[UserRole] = mapped_column(
        Enum(UserRole, name="user_role", values_callable=lambda e: [m.value for m in e]),
        nullable=False,
        default=UserRole.USER,
        server_default=UserRole.USER.value,
    )

    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, server_default="true"
    )
    email_verified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    last_login_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    # Soft delete: preserves comment threads and aggregate counts when a user
    # exercises their right to erasure. Personal fields are scrubbed
    # separately; this flag only removes them from active use.
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    profile: Mapped[UserProfile | None] = relationship(
        back_populates="user", cascade="all, delete-orphan", uselist=False
    )
    refresh_tokens: Mapped[list[RefreshToken]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    likes: Mapped[list[SchemeLike]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    saves: Mapped[list[SchemeSave]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    ratings: Mapped[list[SchemeRating]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    comments: Mapped[list[Comment]] = relationship(back_populates="user")
    notifications: Mapped[list[Notification]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )

    __table_args__ = (
        # Case-insensitive uniqueness: "A@b.com" and "a@b.com" are one account.
        Index("uq_users_email_lower", func.lower(column("email")), unique=True),
        Index("ix_users_role", "role"),
    )


class UserProfile(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """Attributes used for eligibility matching.

    NOTE ON CARDINALITY -- this table carries its own primary key and a
    *unique* user_id rather than using user_id as the primary key. The
    relationship is one-to-one today. Should household profiles ever be added
    ("check eligibility for my mother"), relaxing this to one-to-many means
    dropping one unique constraint instead of restructuring a table and every
    foreign key pointing at it. The cost of the hedge is one extra column.

    Every field is optional. Matching quality improves as the profile is
    completed, but a user must never be forced to disclose caste, disability,
    or income to use the product.
    """

    __tablename__ = "user_profiles"

    user_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    label: Mapped[str | None] = mapped_column(String(100))
    is_primary: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, server_default="true"
    )

    # ---------- Demographic ----------
    date_of_birth: Mapped[date | None] = mapped_column(Date)
    # Derived from date_of_birth when present; stored so a user can give an
    # age without a full date of birth, and so matching never has to compute
    # age inside a query.
    age: Mapped[int | None] = mapped_column(Integer)
    is_woman: Mapped[bool | None] = mapped_column(Boolean)
    is_sc_st: Mapped[bool | None] = mapped_column(Boolean)
    is_obc: Mapped[bool | None] = mapped_column(Boolean)
    is_minority: Mapped[bool | None] = mapped_column(Boolean)
    is_divyang: Mapped[bool | None] = mapped_column(Boolean)

    # ---------- Economic ----------
    annual_income: Mapped[float | None] = mapped_column(Numeric(12, 2))
    is_ews: Mapped[bool | None] = mapped_column(Boolean)
    is_lig: Mapped[bool | None] = mapped_column(Boolean)
    is_mig: Mapped[bool | None] = mapped_column(Boolean)
    has_bpl_card: Mapped[bool | None] = mapped_column(Boolean)
    has_yellow_ration_card: Mapped[bool | None] = mapped_column(Boolean)
    has_orange_ration_card: Mapped[bool | None] = mapped_column(Boolean)
    is_taxpayer: Mapped[bool | None] = mapped_column(Boolean)
    is_pensioner_above_10k: Mapped[bool | None] = mapped_column(Boolean)

    # ---------- Occupation ----------
    is_farmer: Mapped[bool | None] = mapped_column(Boolean)
    owns_cultivable_land: Mapped[bool | None] = mapped_column(Boolean)
    is_mgnrega_worker: Mapped[bool | None] = mapped_column(Boolean)
    is_unorganized_worker: Mapped[bool | None] = mapped_column(Boolean)
    has_eshram_card: Mapped[bool | None] = mapped_column(Boolean)
    is_govt_employee: Mapped[bool | None] = mapped_column(Boolean)
    is_student: Mapped[bool | None] = mapped_column(Boolean)
    has_business_plan: Mapped[bool | None] = mapped_column(Boolean)

    # ---------- Housing / location ----------
    state_code: Mapped[str | None] = mapped_column(String(3))
    district: Mapped[str | None] = mapped_column(String(100))
    is_rural: Mapped[bool | None] = mapped_column(Boolean)
    no_pucca_house: Mapped[bool | None] = mapped_column(Boolean)

    # ---------- Health ----------
    is_pregnant_or_lactating: Mapped[bool | None] = mapped_column(Boolean)

    # Escape hatch for rare or future attributes, so adding one does not
    # require a migration. Attributes that participate in matching should be
    # promoted to real columns.
    custom_attributes: Mapped[dict[str, Any]] = mapped_column(
        JSONB, nullable=False, default=dict, server_default="{}"
    )

    user: Mapped[User] = relationship(back_populates="profile")

    __table_args__ = (
        UniqueConstraint("user_id", name="uq_user_profiles_user_id"),
        CheckConstraint("age IS NULL OR (age >= 0 AND age <= 120)", name="age_range"),
        CheckConstraint(
            "annual_income IS NULL OR annual_income >= 0", name="income_non_negative"
        ),
        Index("ix_user_profiles_state_code", "state_code"),
    )


class RefreshToken(Base, UUIDPrimaryKeyMixin):
    """A refresh-token grant.

    Only a hash is stored: a database leak must not yield usable tokens.
    Rows are retained after revocation so reuse of a rotated token can be
    detected -- the standard signal of a stolen token.
    """

    __tablename__ = "refresh_tokens"

    user_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    token_hash: Mapped[str] = mapped_column(String(128), nullable=False, unique=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    # Set when this token is rotated, forming a chain for reuse detection.
    replaced_by_id: Mapped[uuid.UUID | None] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("refresh_tokens.id", ondelete="SET NULL")
    )
    user_agent: Mapped[str | None] = mapped_column(Text)
    ip_address: Mapped[str | None] = mapped_column(String(45))  # IPv6-sized
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    user: Mapped[User] = relationship(back_populates="refresh_tokens")

    __table_args__ = (
        Index("ix_refresh_tokens_user_id", "user_id"),
        Index(
            "ix_refresh_tokens_active",
            "user_id",
            postgresql_where=text("revoked_at IS NULL"),
        ),
    )
