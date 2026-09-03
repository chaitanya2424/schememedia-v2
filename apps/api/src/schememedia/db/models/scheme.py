"""Scheme catalog: schemes, categories, tags, benefits, documents, rules."""

from __future__ import annotations

from datetime import date, datetime
from typing import TYPE_CHECKING, Any

from pgvector.sqlalchemy import Vector
from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Computed,
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
    text,
)
from sqlalchemy.dialects.postgresql import JSONB, TSVECTOR
from sqlalchemy.orm import Mapped, mapped_column, relationship

from schememedia.db.models.base import Base, TimestampMixin, UUIDPrimaryKeyMixin
from schememedia.db.models.enums import (
    ALL_ATTRIBUTE_KEYS,
    Jurisdiction,
    RuleGroup,
    RuleOperator,
    SchemeType,
    VerificationStatus,
)

if TYPE_CHECKING:
    from schememedia.db.models.content import Comment
    from schememedia.db.models.interaction import SchemeLike, SchemeRating, SchemeSave

# Single source of truth for both the CLI that writes embeddings
# (cli/generate_embeddings.py) and the retriever that embeds a query the
# same way (repositories/search.py) -- a query embedded with a different
# model would not be comparable to the stored vectors.
EMBEDDING_MODEL_NAME = "sentence-transformers/all-MiniLM-L6-v2"
EMBEDDING_DIM = 384


class Category(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """A browsable category.

    v1 hardcoded nine categories in the frontend and filtered by *tag*, so
    "housing" matched 8 schemes by tag while 107 carried Housing in their
    category column. Categories are now rows with a real foreign key.
    """

    __tablename__ = "categories"

    slug: Mapped[str] = mapped_column(String(60), nullable=False, unique=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    name_hi: Mapped[str | None] = mapped_column(String(100))
    icon: Mapped[str | None] = mapped_column(String(16))
    display_order: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, server_default="0"
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, server_default="true"
    )

    schemes: Mapped[list[Scheme]] = relationship(back_populates="category")

    __table_args__ = (Index("ix_categories_display_order", "display_order"),)


class Tag(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """A normalised search tag. v1 stored 1,470 freeform duplicated strings."""

    __tablename__ = "tags"

    slug: Mapped[str] = mapped_column(String(80), nullable=False, unique=True)
    name: Mapped[str] = mapped_column(String(80), nullable=False)

    schemes: Mapped[list[Scheme]] = relationship(
        secondary="scheme_tags", back_populates="tags"
    )


class SchemeTag(Base):
    """Association table for the scheme/tag many-to-many."""

    __tablename__ = "scheme_tags"

    scheme_id: Mapped[str] = mapped_column(
        String(64),
        ForeignKey("schemes.scheme_id", ondelete="CASCADE"),
        primary_key=True,
    )
    tag_id: Mapped[Any] = mapped_column(
        ForeignKey("tags.id", ondelete="CASCADE"), primary_key=True
    )

    __table_args__ = (Index("ix_scheme_tags_tag_id", "tag_id"),)


class Scheme(Base, TimestampMixin):
    """A government scheme.

    The natural key from the source dataset is kept as the primary key so
    existing identifiers, and any interactions referencing them, remain valid
    across re-imports.
    """

    __tablename__ = "schemes"

    scheme_id: Mapped[str] = mapped_column(String(64), primary_key=True)
    slug: Mapped[str] = mapped_column(String(220), nullable=False, unique=True)

    name: Mapped[str] = mapped_column(String(500), nullable=False)
    name_hi: Mapped[str | None] = mapped_column(String(500))
    ministry: Mapped[str | None] = mapped_column(String(300))

    category_id: Mapped[Any | None] = mapped_column(
        ForeignKey("categories.id", ondelete="SET NULL")
    )
    scheme_type: Mapped[SchemeType] = mapped_column(
        Enum(
            SchemeType,
            name="scheme_type",
            values_callable=lambda e: [m.value for m in e],
        ),
        nullable=False,
        default=SchemeType.OTHER,
        server_default=SchemeType.OTHER.value,
    )
    jurisdiction: Mapped[Jurisdiction] = mapped_column(
        Enum(
            Jurisdiction,
            name="jurisdiction",
            values_callable=lambda e: [m.value for m in e],
        ),
        nullable=False,
        default=Jurisdiction.CENTRAL,
        server_default=Jurisdiction.CENTRAL.value,
    )
    state_code: Mapped[str | None] = mapped_column(String(3))

    description_short: Mapped[str | None] = mapped_column(Text)
    description_long: Mapped[str | None] = mapped_column(Text)

    # The link to the government application page. Absent from the v1 dataset
    # and arguably its most valuable missing field.
    official_url: Mapped[str | None] = mapped_column(Text)
    application_deadline: Mapped[date | None] = mapped_column(Date)

    # ---------- Provenance ----------
    # The source dataset is machine-generated and partly unreliable, so the
    # UI must be able to show where a record came from and when it was last
    # checked. raw_eligibility preserves the original blob for audit.
    data_source: Mapped[str | None] = mapped_column(String(100))
    last_verified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    # Distinct from last_verified_at, which is reserved for the future
    # manual-verification workflow (see VerificationStatus) and today is
    # never set by anything -- this one records the last time the importer
    # actually touched the row (including a no-op upsert of unchanged
    # data), regardless of whether anything changed. Never set for a scheme
    # the importer held back because it is officially_verified -- see
    # importer/pipeline.py's compare-before-write logic.
    last_imported_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    needs_review: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False, server_default="false"
    )
    # See ADR 0003. Every search/detail result carries this so a caller
    # cannot render a scheme without knowing how much it can be trusted --
    # separate from needs_review, which flags an importer-side data problem
    # rather than the record's provenance.
    verification_status: Mapped[VerificationStatus] = mapped_column(
        Enum(
            VerificationStatus,
            name="verification_status",
            values_callable=lambda e: [m.value for m in e],
        ),
        nullable=False,
        default=VerificationStatus.UNVERIFIED,
        server_default=VerificationStatus.UNVERIFIED.value,
    )
    raw_eligibility: Mapped[dict[str, Any] | None] = mapped_column(JSONB)

    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, server_default="true"
    )

    # ---------- Denormalised counters ----------
    # Maintained by triggers. Deliberate redundancy: v1 ran two correlated
    # subqueries per scheme per request to compute these, which is the first
    # thing that would fall over under load.
    like_count: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, server_default="0"
    )
    save_count: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, server_default="0"
    )
    comment_count: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, server_default="0"
    )
    rating_sum: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, server_default="0"
    )
    rating_count: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, server_default="0"
    )

    # ---------- Search ----------
    embedding: Mapped[Any | None] = mapped_column(Vector(EMBEDDING_DIM))

    # Generated by Postgres, so it can never drift from the source columns.
    # Weights: name highest, then long description, then ministry.
    search_vector: Mapped[Any] = mapped_column(
        TSVECTOR,
        Computed(
            "setweight(to_tsvector('english', coalesce(name, '')), 'A') || "
            "setweight(to_tsvector('english', coalesce(description_long, '')), 'B') || "
            "setweight(to_tsvector('english', coalesce(ministry, '')), 'C')",
            persisted=True,
        ),
    )

    category: Mapped[Category | None] = relationship(back_populates="schemes")
    tags: Mapped[list[Tag]] = relationship(
        secondary="scheme_tags", back_populates="schemes"
    )
    benefits: Mapped[list[SchemeBenefit]] = relationship(
        back_populates="scheme",
        cascade="all, delete-orphan",
        order_by="SchemeBenefit.display_order",
    )
    documents: Mapped[list[SchemeDocument]] = relationship(
        back_populates="scheme",
        cascade="all, delete-orphan",
        order_by="SchemeDocument.display_order",
    )
    eligibility_rules: Mapped[list[SchemeEligibilityRule]] = relationship(
        back_populates="scheme", cascade="all, delete-orphan"
    )
    likes: Mapped[list[SchemeLike]] = relationship(
        back_populates="scheme", cascade="all, delete-orphan"
    )
    saves: Mapped[list[SchemeSave]] = relationship(
        back_populates="scheme", cascade="all, delete-orphan"
    )
    ratings: Mapped[list[SchemeRating]] = relationship(
        back_populates="scheme", cascade="all, delete-orphan"
    )
    comments: Mapped[list[Comment]] = relationship(
        back_populates="scheme", cascade="all, delete-orphan"
    )

    __table_args__ = (
        CheckConstraint("like_count >= 0", name="like_count_non_negative"),
        CheckConstraint("save_count >= 0", name="save_count_non_negative"),
        CheckConstraint("comment_count >= 0", name="comment_count_non_negative"),
        CheckConstraint("rating_count >= 0", name="rating_count_non_negative"),
        CheckConstraint(
            "(jurisdiction = 'central') OR "
            "(jurisdiction = 'state' AND state_code IS NOT NULL)",
            name="state_scheme_requires_state_code",
        ),
        Index("ix_schemes_category_active", "category_id", "is_active"),
        Index("ix_schemes_jurisdiction_state", "jurisdiction", "state_code"),
        Index("ix_schemes_like_count", text("like_count DESC")),
        Index("ix_schemes_search_vector", "search_vector", postgresql_using="gin"),
        # HNSW rather than IVFFlat: no training step, and recall does not
        # degrade as rows are added. Created in the migration with tuned
        # parameters.
        Index(
            "ix_schemes_embedding_hnsw",
            "embedding",
            postgresql_using="hnsw",
            postgresql_with={"m": 16, "ef_construction": 64},
            postgresql_ops={"embedding": "vector_cosine_ops"},
        ),
    )

    @property
    def average_rating(self) -> float | None:
        if self.rating_count == 0:
            return None
        return round(self.rating_sum / self.rating_count, 2)


class SchemeBenefit(Base, UUIDPrimaryKeyMixin):
    """One benefit line. v1 buried these inside eligibility_json."""

    __tablename__ = "scheme_benefits"

    scheme_id: Mapped[str] = mapped_column(
        String(64), ForeignKey("schemes.scheme_id", ondelete="CASCADE"), nullable=False
    )
    stage: Mapped[str | None] = mapped_column(String(200))
    amount_text: Mapped[str] = mapped_column(Text, nullable=False)
    # Parsed where possible, enabling "schemes worth over Rs 50,000" filters.
    amount_numeric: Mapped[float | None] = mapped_column(Numeric(14, 2))
    currency: Mapped[str] = mapped_column(
        String(3), nullable=False, default="INR", server_default="INR"
    )
    display_order: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, server_default="0"
    )
    # 633 of 1,000 source benefit strings are truncated mid-word at ~200
    # characters. Flagged rather than silently presented as complete.
    is_truncated: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False, server_default="false"
    )

    scheme: Mapped[Scheme] = relationship(back_populates="benefits")

    __table_args__ = (Index("ix_scheme_benefits_scheme_id", "scheme_id"),)


class SchemeDocument(Base, UUIDPrimaryKeyMixin):
    """One required document.

    997 of 1,000 source records packed every document into a single string
    (median 307 characters). The importer splits these; anything it cannot
    split confidently is stored whole and flagged for review.
    """

    __tablename__ = "scheme_documents"

    scheme_id: Mapped[str] = mapped_column(
        String(64), ForeignKey("schemes.scheme_id", ondelete="CASCADE"), nullable=False
    )
    name: Mapped[str] = mapped_column(Text, nullable=False)
    is_mandatory: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, server_default="true"
    )
    display_order: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, server_default="0"
    )
    needs_review: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False, server_default="false"
    )

    scheme: Mapped[Scheme] = relationship(back_populates="documents")

    __table_args__ = (Index("ix_scheme_documents_scheme_id", "scheme_id"),)


class SchemeEligibilityRule(Base, UUIDPrimaryKeyMixin):
    """One eligibility condition.

    The central schema change of the rebuild. v1 kept rules inside an opaque
    JSONB blob matched by a SQL function that was never committed to the
    repository -- unreadable, unverifiable, and impossible to explain to a
    user. As rows, matching becomes a join, an admin can correct a bad rule,
    and every rule carries a human-readable label so the API can answer
    "why did this match?".

    A rule exists only where a constraint is genuinely asserted. Under the
    agreed interpretation, false and null in the source data both mean "not a
    requirement" and produce no row: of ~12,000 source flag values, roughly
    599 become rules.
    """

    __tablename__ = "scheme_eligibility_rules"

    scheme_id: Mapped[str] = mapped_column(
        String(64), ForeignKey("schemes.scheme_id", ondelete="CASCADE"), nullable=False
    )
    rule_group: Mapped[RuleGroup] = mapped_column(
        Enum(
            RuleGroup, name="rule_group", values_callable=lambda e: [m.value for m in e]
        ),
        nullable=False,
    )
    attribute_key: Mapped[str] = mapped_column(String(60), nullable=False)
    operator: Mapped[RuleOperator] = mapped_column(
        Enum(
            RuleOperator,
            name="rule_operator",
            values_callable=lambda e: [m.value for m in e],
        ),
        nullable=False,
    )

    value_bool: Mapped[bool | None] = mapped_column(Boolean)
    value_numeric: Mapped[float | None] = mapped_column(Numeric(14, 2))
    value_text: Mapped[str | None] = mapped_column(String(100))

    # Shown to the user in match explanations, e.g. "You are a farmer".
    label: Mapped[str] = mapped_column(String(200), nullable=False)
    label_hi: Mapped[str | None] = mapped_column(String(200))

    scheme: Mapped[Scheme] = relationship(back_populates="eligibility_rules")

    __table_args__ = (
        # Exactly one typed value per rule.
        CheckConstraint(
            "num_nonnulls(value_bool, value_numeric, value_text) = 1",
            name="exactly_one_value",
        ),
        # A typo in the importer fails at insert time instead of producing a
        # rule that can never match anything.
        CheckConstraint(
            "attribute_key IN ("
            + ", ".join(f"'{key}'" for key in ALL_ATTRIBUTE_KEYS)
            + ")",
            name="known_attribute_key",
        ),
        UniqueConstraint(
            "scheme_id",
            "rule_group",
            "attribute_key",
            "operator",
            name="uq_scheme_eligibility_rules_scheme_group_attr_op",
        ),
        Index("ix_scheme_eligibility_rules_scheme_group", "scheme_id", "rule_group"),
        Index("ix_scheme_eligibility_rules_attribute_key", "attribute_key"),
    )
