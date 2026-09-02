"""Translate the source `eligibility_json` blob into eligibility rules.

Interpretation A (approved, see REBUILD_PLAN and docs/adr/0001): `false` and
`null` in the source are generator defaults meaning "not a requirement" and
emit no rule. Measured support: `must_match_all` holds 8,651 `false` values
against 349 `true` -- roughly 25:1 -- and 709 of 1,000 schemes have every
boolean set to `false`. Reading `false` as "must be false" would make a sports
journalism award require the applicant to be not-a-farmer, not-a-taxpayer and
without a pucca house.

Nothing here silently corrects source data. Implausible values are imported as
given and flagged; contradictions are reported rather than resolved.

Measured output over the real dataset: 2,622 rules, median 2 per scheme,
max 8, with 53 schemes yielding none.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from schememedia.db.models.enums import EligibilityAttribute as A
from schememedia.db.models.enums import RuleGroup, RuleOperator
from schememedia.services.eligibility_labels import (
    BOOLEAN_LABELS,
    BOOLEAN_LABELS_HI,
    NUMERIC_LABEL_TEMPLATES,
    NUMERIC_LABEL_TEMPLATES_HI,
    format_indian_number,
)

# An annual income ceiling below this is not a real policy. 33 schemes carry
# one, including values of 1 and 2 -- almost certainly lakhs recorded as
# rupees. Flagged, never rewritten: we do not know the intended multiplier.
IMPLAUSIBLE_INCOME_BELOW = 1000

# Source boolean key -> (attribute, required value).
# Every attribute here exists in EligibilityAttribute, which the database
# enforces through the known_attribute_key CHECK constraint.
BOOLEAN_KEY_MAP: dict[str, tuple[A, bool]] = {
    "is_farmer": (A.IS_FARMER, True),
    "is_govt_employee": (A.IS_GOVT_EMPLOYEE, True),
    "is_pensioner_above_10k": (A.IS_PENSIONER_ABOVE_10K, True),
    "is_pregnant_or_lactating": (A.IS_PREGNANT_OR_LACTATING, True),
    "is_taxpayer": (A.IS_TAXPAYER, True),
    "no_pucca_house": (A.NO_PUCCA_HOUSE, True),
    "owns_cultivable_land": (A.OWNS_CULTIVABLE_LAND, True),
    # Renamed: the source says "rural_required", the profile says "is_rural".
    "rural_required": (A.IS_RURAL, True),
    # Negated: the schema has no not_govt_employee attribute, so this is the
    # only representation available -- and the right one. Two attributes held
    # in permanent opposition is a bug waiting to happen.
    "not_govt_employee": (A.IS_GOVT_EMPLOYEE, False),
    "has_bpl_card": (A.HAS_BPL_CARD, True),
    "has_business_plan": (A.HAS_BUSINESS_PLAN, True),
    "has_eshram_card": (A.HAS_ESHRAM_CARD, True),
    "has_orange_ration_card": (A.HAS_ORANGE_RATION_CARD, True),
    "has_yellow_ration_card": (A.HAS_YELLOW_RATION_CARD, True),
    "is_divyang": (A.IS_DIVYANG, True),
    "is_ews": (A.IS_EWS, True),
    "is_lig": (A.IS_LIG, True),
    "is_mgnrega_worker": (A.IS_MGNREGA_WORKER, True),
    "is_mig": (A.IS_MIG, True),
    "is_sc_st": (A.IS_SC_ST, True),
    "is_unorganized_worker": (A.IS_UNORGANIZED_WORKER, True),
    "is_woman": (A.IS_WOMAN, True),
}

# Source numeric key -> (attribute, operator).
NUMERIC_KEY_MAP: dict[str, tuple[A, RuleOperator]] = {
    "min_age": (A.AGE, RuleOperator.GTE),
    "max_age": (A.AGE, RuleOperator.LTE),
    "max_income": (A.ANNUAL_INCOME, RuleOperator.LTE),
}

# Present in all 1,000 records and null in every one. Listed explicitly so an
# unknown-key warning is not raised for it.
IGNORED_KEYS: frozenset[str] = frozenset({"born_after"})


@dataclass(frozen=True)
class TranslatedRule:
    """One rule, ready to insert into scheme_eligibility_rules."""

    rule_group: RuleGroup
    attribute_key: str
    operator: RuleOperator
    label: str
    label_hi: str | None = None
    value_bool: bool | None = None
    value_numeric: float | None = None
    value_text: str | None = None
    needs_review: bool = False


@dataclass
class TranslationResult:
    rules: list[TranslatedRule] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)
    scheme_needs_review: bool = False


def _is_number(value: Any) -> bool:
    return isinstance(value, int | float) and not isinstance(value, bool)


def _boolean_label(attribute: A, required: bool) -> tuple[str, str | None]:
    english = BOOLEAN_LABELS.get(attribute)
    hindi = BOOLEAN_LABELS_HI.get(attribute)
    index = 0 if required else 1
    return (
        english[index] if english else attribute.value.replace("_", " "),
        hindi[index] if hindi else None,
    )


def _numeric_label(
    attribute: A, operator: RuleOperator, value: float
) -> tuple[str, str | None]:
    key = (attribute, operator.value)
    display = format_indian_number(value)
    english_template = NUMERIC_LABEL_TEMPLATES.get(key)
    hindi_template = NUMERIC_LABEL_TEMPLATES_HI.get(key)
    return (
        english_template.format(value=display)
        if english_template
        else f"{attribute.value} {operator.value} {display}",
        hindi_template.format(value=display) if hindi_template else None,
    )


def _has_contradictory_govt_flags(block: dict[str, Any]) -> bool:
    """Both "must be a government employee" and "must not be" asserted.

    Three real schemes do this: SCH_38603FF1, SCH_EBE5D9CA, SCH_DF093CC3.
    Both map to the same (scheme_id, group, attribute, operator) tuple and
    would violate the unique constraint, aborting the import.
    """
    return block.get("is_govt_employee") is True and (
        block.get("not_govt_employee") is True
    )


def _translate_block(
    block: dict[str, Any], group: RuleGroup, result: TranslationResult
) -> None:
    skip_govt = _has_contradictory_govt_flags(block)
    if skip_govt:
        result.warnings.append(
            "is_govt_employee and not_govt_employee both true -- contradictory "
            "requirement, neither rule emitted"
        )
        result.scheme_needs_review = True

    for key, value in block.items():
        if key in IGNORED_KEYS:
            continue

        if key in NUMERIC_KEY_MAP:
            if not _is_number(value):
                continue
            attribute, operator = NUMERIC_KEY_MAP[key]
            flagged = attribute is A.ANNUAL_INCOME and value < IMPLAUSIBLE_INCOME_BELOW
            if flagged:
                result.warnings.append(
                    f"{key}={value} is implausibly low; imported as given"
                )
                result.scheme_needs_review = True
            label, label_hi = _numeric_label(attribute, operator, value)
            result.rules.append(
                TranslatedRule(
                    rule_group=group,
                    attribute_key=attribute.value,
                    operator=operator,
                    value_numeric=value,
                    label=label,
                    label_hi=label_hi,
                    needs_review=flagged,
                )
            )
            continue

        if key in BOOLEAN_KEY_MAP:
            if value is not True:
                continue
            attribute, required = BOOLEAN_KEY_MAP[key]
            if skip_govt and attribute is A.IS_GOVT_EMPLOYEE:
                continue
            label, label_hi = _boolean_label(attribute, required)
            result.rules.append(
                TranslatedRule(
                    rule_group=group,
                    attribute_key=attribute.value,
                    operator=RuleOperator.EQ,
                    value_bool=required,
                    label=label,
                    label_hi=label_hi,
                )
            )
            continue

        result.warnings.append(f"unknown eligibility key '{key}' ignored")


def translate_eligibility(eligibility_json: dict[str, Any]) -> TranslationResult:
    """Translate one scheme's eligibility blob into rules.

    Deterministic: source key order drives output order, so re-importing
    unchanged data produces identical rows.
    """
    result = TranslationResult()
    _translate_block(eligibility_json.get("must_match_all") or {}, RuleGroup.ALL, result)
    _translate_block(
        eligibility_json.get("must_match_one_of") or {}, RuleGroup.ANY, result
    )
    return result
