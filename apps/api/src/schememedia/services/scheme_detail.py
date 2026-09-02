"""Scheme detail: assembles one scheme's full record, optionally with
eligibility evaluated against a caller-supplied profile.

Thin by design -- the real logic (evaluate_scheme's four-valued matching)
already lives in eligibility_matcher.py; this module's job is only to fetch
and assemble, matching this project's layering rule (routers -> services ->
repositories -> database, nothing skips a layer) even where, as here, there
is not much business logic to speak of.
"""

from __future__ import annotations

from dataclasses import dataclass

from schememedia.db.models import (
    Scheme,
    SchemeBenefit,
    SchemeDocument,
    SchemeEligibilityRule,
)
from schememedia.repositories.schemes import SqlSchemeRepository
from schememedia.services.eligibility_matcher import (
    Profile,
    SchemeEligibilityResult,
    evaluate_scheme,
)


@dataclass
class SchemeDetail:
    scheme: Scheme
    category_name: str | None
    tags: list[str]
    benefits: list[SchemeBenefit]
    documents: list[SchemeDocument]
    eligibility_rules: list[SchemeEligibilityRule]
    # Only populated when the caller supplied a profile -- otherwise every
    # rule would show as UNKNOWN, which is not "no eligibility data", it is
    # "no profile was asked about", a different thing worth not conflating.
    eligibility: SchemeEligibilityResult | None = None


@dataclass
class SchemeDetailService:
    schemes: SqlSchemeRepository

    def get_detail(
        self, identifier: str, *, profile: Profile | None = None
    ) -> SchemeDetail | None:
        row = self.schemes.get_detail(identifier)
        if row is None:
            return None

        eligibility = None
        if profile is not None:
            eligibility = evaluate_scheme(
                row.scheme.scheme_id,
                row.eligibility_rules,
                profile,
                needs_review=row.scheme.needs_review,
            )

        return SchemeDetail(
            scheme=row.scheme,
            category_name=row.category_name,
            tags=row.tags,
            benefits=row.benefits,
            documents=row.documents,
            eligibility_rules=row.eligibility_rules,
            eligibility=eligibility,
        )
