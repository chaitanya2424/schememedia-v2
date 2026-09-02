"""Data access for a single scheme's full detail view.

Separate from repositories/search.py's `hydrate()`, which deliberately
fetches only the small set of display fields a search *list* needs (never
SELECT * -- v1 shipped the 384-dim embedding to the browser on every detail
view). A detail page needs more: benefits, documents, tags, and the raw
eligibility rules -- this module is where that larger, single-scheme read
lives, one query per child table rather than one large join, matching the
style already used in cli/generate_embeddings.py's _tags_by_scheme /
_benefits_by_scheme.
"""

from __future__ import annotations

from dataclasses import dataclass, field

from sqlalchemy import select
from sqlalchemy.orm import Session

from schememedia.db.models import (
    Category,
    Scheme,
    SchemeBenefit,
    SchemeDocument,
    SchemeEligibilityRule,
    SchemeTag,
    Tag,
)


@dataclass
class SchemeDetailRow:
    """Everything a detail page needs, assembled from separate queries."""

    scheme: Scheme
    category_name: str | None
    tags: list[str] = field(default_factory=list)
    benefits: list[SchemeBenefit] = field(default_factory=list)
    documents: list[SchemeDocument] = field(default_factory=list)
    eligibility_rules: list[SchemeEligibilityRule] = field(default_factory=list)


@dataclass
class SqlSchemeRepository:
    session: Session

    def get_detail(self, identifier: str) -> SchemeDetailRow | None:
        """Look up by scheme_id first, then by slug -- both are natural,
        stable identifiers a frontend route might use.
        """
        scheme = self.session.get(Scheme, identifier)
        if scheme is None:
            scheme = self.session.execute(
                select(Scheme).where(Scheme.slug == identifier)
            ).scalar_one_or_none()
        if scheme is None or not scheme.is_active:
            return None

        category_name = None
        if scheme.category_id is not None:
            category_name = self.session.execute(
                select(Category.name).where(Category.id == scheme.category_id)
            ).scalar_one_or_none()

        tags = list(
            self.session.execute(
                select(Tag.name)
                .join(SchemeTag, SchemeTag.tag_id == Tag.id)
                .where(SchemeTag.scheme_id == scheme.scheme_id)
                .order_by(Tag.name)
            )
            .scalars()
            .all()
        )
        benefits = list(
            self.session.execute(
                select(SchemeBenefit)
                .where(SchemeBenefit.scheme_id == scheme.scheme_id)
                .order_by(SchemeBenefit.display_order)
            )
            .scalars()
            .all()
        )
        documents = list(
            self.session.execute(
                select(SchemeDocument)
                .where(SchemeDocument.scheme_id == scheme.scheme_id)
                .order_by(SchemeDocument.display_order)
            )
            .scalars()
            .all()
        )
        eligibility_rules = list(
            self.session.execute(
                select(SchemeEligibilityRule).where(
                    SchemeEligibilityRule.scheme_id == scheme.scheme_id
                )
            )
            .scalars()
            .all()
        )

        return SchemeDetailRow(
            scheme=scheme,
            category_name=category_name,
            tags=tags,
            benefits=benefits,
            documents=documents,
            eligibility_rules=eligibility_rules,
        )
