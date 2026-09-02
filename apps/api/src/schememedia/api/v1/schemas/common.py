"""Small, explicit Literal aliases for the domain's fixed vocabularies.

Deliberately hand-written, independent copies of the wire values -- NOT
`Literal[tuple(e.value for e in SomeEnum)]` built from the SQLAlchemy-backed
enums in db/models/enums.py. Two reasons:

1. A Literal type needs literal values at type-check time; it cannot be
   assembled from a runtime loop.
2. Even if it could, the external API contract should not silently change
   shape just because an internal enum is renamed, reordered, or split --
   independence from internal implementation details (the thing this file
   exists for) cuts both ways: the wire contract is pinned here, in the API
   layer, not derived from wherever the domain layer happens to keep it
   today.

Using Literal instead of plain `str` is also what makes every one of these
fields show up in OpenAPI/Swagger as a documented, validated enum instead of
an opaque free-form string.
"""

from __future__ import annotations

from typing import Literal

VerificationStatusOut = Literal["unverified", "source_provided", "officially_verified"]
EligibilityStateOut = Literal["pass", "fail", "unknown", "not_applicable"]
JurisdictionOut = Literal["central", "state"]
SchemeTypeOut = Literal[
    "subsidy",
    "scholarship",
    "loan",
    "pension",
    "insurance",
    "training",
    "award",
    "grant",
    "other",
]
RuleGroupOut = Literal["all", "any"]
RuleOperatorOut = Literal["eq", "gte", "lte"]
