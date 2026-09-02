"""Enumerations.

The eligibility attribute vocabulary lives here and is the single source of
truth for both sides of matching: the columns on user_profiles and the
attribute_key values in scheme_eligibility_rules. Keeping one list prevents
the two sides drifting apart, which would silently break matching.
"""

# ruff: noqa: UP042 -- str+Enum (not StrEnum) is deliberate: SQLAlchemy and
# Pydantic both serialise these to plain strings, and StrEnum changes repr()
# in ways that leak into API responses.

from __future__ import annotations

import enum


class UserRole(str, enum.Enum):
    USER = "user"
    MODERATOR = "moderator"
    ADMIN = "admin"


class Jurisdiction(str, enum.Enum):
    CENTRAL = "central"
    STATE = "state"


class SchemeType(str, enum.Enum):
    SUBSIDY = "subsidy"
    SCHOLARSHIP = "scholarship"
    LOAN = "loan"
    PENSION = "pension"
    INSURANCE = "insurance"
    TRAINING = "training"
    AWARD = "award"
    GRANT = "grant"
    OTHER = "other"


class RuleGroup(str, enum.Enum):
    """How a rule combines with its siblings.

    ALL -- every rule in this group must match (AND).
    ANY -- at least one rule in this group must match (OR).
    """

    ALL = "all"
    ANY = "any"


class RuleOperator(str, enum.Enum):
    EQ = "eq"  # boolean or text equality
    GTE = "gte"  # user value >= rule value (e.g. min_age)
    LTE = "lte"  # user value <= rule value (e.g. max_income)


class AttributeType(str, enum.Enum):
    BOOLEAN = "boolean"
    NUMERIC = "numeric"
    TEXT = "text"


class VerificationStatus(str, enum.Enum):
    """How much a scheme record can be trusted.

    The source dataset is machine-generated and partly unreliable (REBUILD_PLAN
    D.4): identical boilerplate descriptions, truncated benefits, no
    official_url. A caller must not be able to render a scheme without knowing
    how much we actually trust it, so this travels with every search result
    rather than being inferred client-side from needs_review/data_source.

    UNVERIFIED -- imported as-is, nobody has checked it against a primary
    source. The default for everything the importer writes.
    SOURCE_PROVIDED -- came with an attributed source (e.g. a named portal or
    dataset) but has not been independently checked.
    OFFICIALLY_VERIFIED -- confirmed against the government's own page.
    Reserved for future manual/admin verification; the importer never sets
    this on its own.
    """

    UNVERIFIED = "unverified"
    SOURCE_PROVIDED = "source_provided"
    OFFICIALLY_VERIFIED = "officially_verified"


class ReportTargetType(str, enum.Enum):
    SCHEME = "scheme"
    COMMENT = "comment"


class ReportStatus(str, enum.Enum):
    OPEN = "open"
    REVIEWED = "reviewed"
    DISMISSED = "dismissed"


class ReportReason(str, enum.Enum):
    OUTDATED = "outdated"  # data quality: expected to be the most common
    INCORRECT = "incorrect"
    SPAM = "spam"
    ABUSIVE = "abusive"
    OTHER = "other"


class NotificationType(str, enum.Enum):
    COMMENT_REPLY = "comment_reply"
    NEW_SCHEME = "new_scheme"
    DEADLINE_REMINDER = "deadline_reminder"
    SYSTEM = "system"


# ---------------------------------------------------------------------------
# Eligibility attribute vocabulary
# ---------------------------------------------------------------------------
# Every key here maps to a column on user_profiles and is a permitted
# attribute_key in scheme_eligibility_rules. A CHECK constraint enforces the
# latter, so a typo in the importer fails loudly at insert time rather than
# silently producing a rule that can never match.


class EligibilityAttribute(str, enum.Enum):
    # Demographic
    AGE = "age"
    IS_WOMAN = "is_woman"
    IS_SC_ST = "is_sc_st"
    IS_OBC = "is_obc"
    IS_MINORITY = "is_minority"
    IS_DIVYANG = "is_divyang"

    # Economic
    ANNUAL_INCOME = "annual_income"
    IS_EWS = "is_ews"
    IS_LIG = "is_lig"
    IS_MIG = "is_mig"
    HAS_BPL_CARD = "has_bpl_card"
    HAS_YELLOW_RATION_CARD = "has_yellow_ration_card"
    HAS_ORANGE_RATION_CARD = "has_orange_ration_card"
    IS_TAXPAYER = "is_taxpayer"
    IS_PENSIONER_ABOVE_10K = "is_pensioner_above_10k"

    # Occupation
    IS_FARMER = "is_farmer"
    OWNS_CULTIVABLE_LAND = "owns_cultivable_land"
    IS_MGNREGA_WORKER = "is_mgnrega_worker"
    IS_UNORGANIZED_WORKER = "is_unorganized_worker"
    HAS_ESHRAM_CARD = "has_eshram_card"
    IS_GOVT_EMPLOYEE = "is_govt_employee"
    IS_STUDENT = "is_student"
    HAS_BUSINESS_PLAN = "has_business_plan"

    # Housing / location
    IS_RURAL = "is_rural"
    NO_PUCCA_HOUSE = "no_pucca_house"
    STATE_CODE = "state_code"

    # Health
    IS_PREGNANT_OR_LACTATING = "is_pregnant_or_lactating"


ATTRIBUTE_TYPES: dict[EligibilityAttribute, AttributeType] = {
    EligibilityAttribute.AGE: AttributeType.NUMERIC,
    EligibilityAttribute.ANNUAL_INCOME: AttributeType.NUMERIC,
    EligibilityAttribute.STATE_CODE: AttributeType.TEXT,
}


def attribute_type(attribute: EligibilityAttribute) -> AttributeType:
    """Everything not explicitly listed is a boolean flag."""
    return ATTRIBUTE_TYPES.get(attribute, AttributeType.BOOLEAN)


ALL_ATTRIBUTE_KEYS: tuple[str, ...] = tuple(a.value for a in EligibilityAttribute)
