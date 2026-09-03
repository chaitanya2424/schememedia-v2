"""Import provenance: what the importer actually changed, when, and whether
it was applied to the live row.

Two tables, deliberately separate from `schemes` and its child tables
rather than folded in as extra columns:

  * ImportRun -- one row per `importer.pipeline.run_import()` execution.
    `report` is the same data ImportReport.render() prints, structured
    rather than just text, so a later query can filter on e.g.
    schemes_inserted without re-parsing a log line.
  * SchemeFieldChange -- one row per (scheme, field) pair whose value
    differed between the live row and what this run's source data said,
    whether or not that difference was actually written -- see `applied`.

This is what closes the gap the redesign's data-freshness design named:
before this, a re-import silently overwrote every tracked field on every
run with no record of what changed or when. It does not add any new
*detection* mechanism (no crawling, no scheduled job -- see that design) --
it makes each existing, manually-triggered import run auditable, and holds
back writes to a manually verification-confirmed scheme instead of
silently clobbering it (see `applied` and importer/pipeline.py's
compare-before-write logic).
"""

from __future__ import annotations

from datetime import datetime
from typing import Any

from sqlalchemy import Boolean, DateTime, ForeignKey, Index, String, Text, func
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from schememedia.db.models.base import Base, UUIDPrimaryKeyMixin


class ImportRun(Base, UUIDPrimaryKeyMixin):
    """One execution of `importer.pipeline.run_import()`."""

    __tablename__ = "import_runs"

    started_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    # Nullable: set only once the run completes -- a row with finished_at
    # still NULL after the process exits means the run crashed mid-way (the
    # batch that was running rolled back per-batch, see pipeline.py's
    # DEFAULT_BATCH_SIZE docs; already-committed batches are unaffected).
    finished_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    source_label: Mapped[str] = mapped_column(String(200), nullable=False)
    # SHA-256 of the source file's bytes, when known -- lets two runs be
    # compared to confirm "nothing in the file actually changed" without
    # diffing the whole file by hand.
    source_file_hash: Mapped[str | None] = mapped_column(String(64))
    report: Mapped[dict[str, Any] | None] = mapped_column(JSONB)

    field_changes: Mapped[list[SchemeFieldChange]] = relationship(
        back_populates="import_run", cascade="all, delete-orphan"
    )


class SchemeFieldChange(Base, UUIDPrimaryKeyMixin):
    """One field on one scheme that differed between the live row and this
    run's source data.

    `applied` is False only for a scheme whose verification_status was
    already officially_verified when this run encountered it -- the change
    is recorded for review but never written, see importer/pipeline.py.
    Every other row here is a change that was written as part of the normal
    upsert.
    """

    __tablename__ = "scheme_field_changes"

    scheme_id: Mapped[str] = mapped_column(
        String(64), ForeignKey("schemes.scheme_id", ondelete="CASCADE"), nullable=False
    )
    import_run_id: Mapped[Any] = mapped_column(
        ForeignKey("import_runs.id", ondelete="CASCADE"), nullable=False
    )
    field_name: Mapped[str] = mapped_column(String(100), nullable=False)
    # Text, not JSONB: values here span plain strings, enum names, and a
    # serialised raw_eligibility blob -- one column simple enough to read
    # directly in a SQL client is more useful for an audit trail than a
    # typed column per possible field.
    old_value: Mapped[str | None] = mapped_column(Text)
    new_value: Mapped[str | None] = mapped_column(Text)
    applied: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, server_default="true"
    )
    detected_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    import_run: Mapped[ImportRun] = relationship(back_populates="field_changes")

    __table_args__ = (
        Index("ix_scheme_field_changes_scheme_id", "scheme_id"),
        Index("ix_scheme_field_changes_import_run_id", "import_run_id"),
        # The common review query: "what's still pending for this scheme".
        Index(
            "ix_scheme_field_changes_scheme_applied",
            "scheme_id",
            "applied",
        ),
    )
