"""User-generated content: comments, reports, notifications."""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import TYPE_CHECKING, Any

from sqlalchemy import (
    CheckConstraint,
    DateTime,
    Enum,
    ForeignKey,
    Index,
    String,
    Text,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from schememedia.db.models.base import Base, TimestampMixin, UUIDPrimaryKeyMixin
from schememedia.db.models.enums import (
    NotificationType,
    ReportReason,
    ReportStatus,
    ReportTargetType,
)

if TYPE_CHECKING:
    from schememedia.db.models.scheme import Scheme
    from schememedia.db.models.user import User


class Comment(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """A comment on a scheme, optionally replying to another comment.

    v1's POST /comment returned success and wrote nothing, while the UI
    rendered the comment optimistically -- users lost data and were told it
    had saved.
    """

    __tablename__ = "comments"

    scheme_id: Mapped[str] = mapped_column(
        String(64), ForeignKey("schemes.scheme_id", ondelete="CASCADE"), nullable=False
    )
    user_id: Mapped[uuid.UUID | None] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )
    parent_id: Mapped[uuid.UUID | None] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("comments.id", ondelete="CASCADE")
    )

    content: Mapped[str] = mapped_column(Text, nullable=False)

    # Soft delete keeps reply threads intact; the API renders these as
    # "[deleted]" rather than removing descendants.
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    # Set by a moderator acting on a report.
    hidden_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    edited_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    scheme: Mapped[Scheme] = relationship(back_populates="comments")
    user: Mapped[User | None] = relationship(back_populates="comments")
    replies: Mapped[list[Comment]] = relationship(
        back_populates="parent", cascade="all, delete-orphan"
    )
    parent: Mapped[Comment | None] = relationship(
        back_populates="replies", remote_side="Comment.id"
    )

    __table_args__ = (
        CheckConstraint(
            "length(btrim(content)) BETWEEN 1 AND 5000", name="content_length"
        ),
        # Top-level comments, newest first -- the default detail-page query.
        Index(
            "ix_comments_scheme_created",
            "scheme_id",
            text("created_at DESC"),
            postgresql_where=text("parent_id IS NULL AND deleted_at IS NULL"),
        ),
        Index("ix_comments_parent_id", "parent_id"),
        Index("ix_comments_user_id", "user_id"),
    )


class Report(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """A report against a scheme or a comment.

    Polymorphic by target_type rather than two tables: the moderation queue
    reads them as one list, and neither target dominates in volume.

    Given the source data's quality, "outdated" reports against schemes are
    expected to be the most common and the most valuable -- users will find
    errors before we do.
    """

    __tablename__ = "reports"

    reporter_id: Mapped[uuid.UUID | None] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )
    target_type: Mapped[ReportTargetType] = mapped_column(
        Enum(
            ReportTargetType,
            name="report_target_type",
            values_callable=lambda e: [m.value for m in e],
        ),
        nullable=False,
    )
    # Not a foreign key: the target is one of two tables with different key
    # types. Existence is validated in the service layer before insert.
    target_id: Mapped[str] = mapped_column(String(64), nullable=False)

    reason: Mapped[ReportReason] = mapped_column(
        Enum(
            ReportReason,
            name="report_reason",
            values_callable=lambda e: [m.value for m in e],
        ),
        nullable=False,
    )
    details: Mapped[str | None] = mapped_column(Text)

    status: Mapped[ReportStatus] = mapped_column(
        Enum(
            ReportStatus,
            name="report_status",
            values_callable=lambda e: [m.value for m in e],
        ),
        nullable=False,
        default=ReportStatus.OPEN,
        server_default=ReportStatus.OPEN.value,
    )
    resolved_by_id: Mapped[uuid.UUID | None] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    resolution_note: Mapped[str | None] = mapped_column(Text)

    __table_args__ = (
        Index("ix_reports_target", "target_type", "target_id"),
        # The moderation queue only ever reads open reports.
        Index(
            "ix_reports_open",
            text("created_at DESC"),
            postgresql_where=text("status = 'open'"),
        ),
    )


class Notification(Base, UUIDPrimaryKeyMixin):
    """An in-app notification.

    v1 had working endpoints for these and no UI at all.
    """

    __tablename__ = "notifications"

    user_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    notification_type: Mapped[NotificationType] = mapped_column(
        Enum(
            NotificationType,
            name="notification_type",
            values_callable=lambda e: [m.value for m in e],
        ),
        nullable=False,
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    body: Mapped[str | None] = mapped_column(Text)
    # Deep-link target and any type-specific data.
    payload: Mapped[dict[str, Any]] = mapped_column(
        JSONB, nullable=False, default=dict, server_default="{}"
    )
    read_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=text("now()"),
    )

    user: Mapped[User] = relationship(back_populates="notifications")

    __table_args__ = (
        Index("ix_notifications_user_created", "user_id", text("created_at DESC")),
        # Powers the unread badge without scanning read notifications.
        Index(
            "ix_notifications_unread",
            "user_id",
            postgresql_where=text("read_at IS NULL"),
        ),
    )
