"""Tests for eligibility_json -> scheme_eligibility_rules translation.

Written before the implementation. Fixtures marked REAL are taken verbatim
from schemes.json.

The governing decision (REBUILD_PLAN, Interpretation A): `false` and `null`
are generator defaults meaning "not a requirement" and emit no rule. Only
`true` and non-null numerics become rules.
"""

from __future__ import annotations

import pytest

from schememedia.db.models.enums import ALL_ATTRIBUTE_KEYS, RuleGroup, RuleOperator
from schememedia.services.eligibility_translator import (
    TranslatedRule,
    translate_eligibility,
)


def _blank_all() -> dict[str, object]:
    return {
        "min_age": None,
        "max_age": None,
        "is_govt_employee": False,
        "is_pregnant_or_lactating": False,
        "is_farmer": False,
        "owns_cultivable_land": False,
        "is_taxpayer": False,
        "is_pensioner_above_10k": False,
        "no_pucca_house": False,
        "rural_required": False,
        "born_after": None,
        "not_govt_employee": False,
    }


def _blank_any() -> dict[str, object]:
    return {
        "max_income": None,
        "is_sc_st": False,
        "has_bpl_card": False,
        "has_eshram_card": False,
        "is_mgnrega_worker": False,
        "is_divyang": False,
        "has_yellow_ration_card": False,
        "has_orange_ration_card": False,
        "has_business_plan": False,
        "is_ews": False,
        "is_lig": False,
        "is_mig": False,
        "is_woman": False,
        "is_unorganized_worker": False,
    }


def _translate(all_block=None, any_block=None):
    return translate_eligibility(
        {
            "must_match_all": all_block or _blank_all(),
            "must_match_one_of": any_block or _blank_any(),
        }
    )


# ---------------------------------------------------------------------------
# Interpretation A
# ---------------------------------------------------------------------------


def test_all_false_and_null_produces_no_rules() -> None:
    """REAL shape: 709 of 1,000 schemes have every boolean false.

    Reading false as "must be false" would require an applicant to be
    simultaneously not-a-farmer, not-a-taxpayer and without a pucca house.
    """
    result = _translate()
    assert result.rules == []


def test_true_produces_a_rule() -> None:
    block = _blank_all() | {"is_farmer": True}
    result = _translate(all_block=block)
    assert len(result.rules) == 1
    rule = result.rules[0]
    assert rule.attribute_key == "is_farmer"
    assert rule.operator is RuleOperator.EQ
    assert rule.value_bool is True
    assert rule.rule_group is RuleGroup.ALL


# ---------------------------------------------------------------------------
# Numeric thresholds
# ---------------------------------------------------------------------------


def test_min_age_maps_to_age_gte() -> None:
    result = _translate(all_block=_blank_all() | {"min_age": 18})
    rule = result.rules[0]
    assert (rule.attribute_key, rule.operator, rule.value_numeric) == (
        "age",
        RuleOperator.GTE,
        18,
    )


def test_max_age_maps_to_age_lte() -> None:
    result = _translate(all_block=_blank_all() | {"max_age": 60})
    rule = result.rules[0]
    assert (rule.attribute_key, rule.operator, rule.value_numeric) == (
        "age",
        RuleOperator.LTE,
        60,
    )


def test_min_and_max_age_coexist_without_colliding() -> None:
    """Same attribute, different operators -- the unique constraint permits it."""
    result = _translate(all_block=_blank_all() | {"min_age": 18, "max_age": 60})
    assert len(result.rules) == 2
    keys = {(r.rule_group, r.attribute_key, r.operator) for r in result.rules}
    assert len(keys) == 2


def test_max_income_maps_to_annual_income_lte_in_the_any_group() -> None:
    result = _translate(any_block=_blank_any() | {"max_income": 250000})
    rule = result.rules[0]
    assert rule.attribute_key == "annual_income"
    assert rule.operator is RuleOperator.LTE
    assert rule.rule_group is RuleGroup.ANY


# ---------------------------------------------------------------------------
# Renamed and negated keys
# ---------------------------------------------------------------------------


def test_rural_required_maps_to_is_rural() -> None:
    result = _translate(all_block=_blank_all() | {"rural_required": True})
    assert result.rules[0].attribute_key == "is_rural"
    assert result.rules[0].value_bool is True


def test_not_govt_employee_maps_to_is_govt_employee_false() -> None:
    """The schema has no not_govt_employee attribute, so this is forced."""
    result = _translate(all_block=_blank_all() | {"not_govt_employee": True})
    rule = result.rules[0]
    assert rule.attribute_key == "is_govt_employee"
    assert rule.value_bool is False


def test_born_after_never_emits() -> None:
    """Null in all 1,000 records; included defensively."""
    result = _translate(all_block=_blank_all() | {"born_after": 1990})
    assert result.rules == []


# ---------------------------------------------------------------------------
# Decision 2 -- contradictory government-employee flags
# ---------------------------------------------------------------------------


def test_contradictory_govt_employee_flags_emit_nothing_and_flag() -> None:
    """REAL: SCH_38603FF1, SCH_EBE5D9CA, SCH_DF093CC3.

    Both map to (scheme_id, 'all', 'is_govt_employee', 'eq'), differing only
    in value_bool -- a unique-constraint violation that would abort the
    import. An unsatisfiable pair carries no matching signal, so neither is
    emitted and the scheme is flagged. raw_eligibility preserves the original.
    """
    block = _blank_all() | {"is_govt_employee": True, "not_govt_employee": True}
    result = _translate(all_block=block)
    assert all(r.attribute_key != "is_govt_employee" for r in result.rules)
    assert result.scheme_needs_review is True
    assert any("contradict" in w.lower() for w in result.warnings)


def test_non_contradictory_govt_employee_flags_still_work() -> None:
    for key, expected in (("is_govt_employee", True), ("not_govt_employee", False)):
        result = _translate(all_block=_blank_all() | {key: True})
        assert result.rules[0].attribute_key == "is_govt_employee"
        assert result.rules[0].value_bool is expected
        assert result.scheme_needs_review is False


# ---------------------------------------------------------------------------
# Decision 3 -- implausible values
# ---------------------------------------------------------------------------


@pytest.mark.parametrize("income", [1, 2, 15, 600])
def test_implausible_income_is_flagged_but_still_imported(income: int) -> None:
    """33 schemes carry a ceiling below Rs 1,000 -- almost certainly lakhs
    recorded as rupees. Imported as given, flagged, never silently corrected.
    """
    result = _translate(any_block=_blank_any() | {"max_income": income})
    assert result.rules[0].value_numeric == income
    assert result.rules[0].needs_review is True


def test_plausible_income_is_not_flagged() -> None:
    result = _translate(any_block=_blank_any() | {"max_income": 250000})
    assert result.rules[0].needs_review is False


# ---------------------------------------------------------------------------
# Invariants
# ---------------------------------------------------------------------------


def test_every_emitted_key_is_in_the_schema_vocabulary() -> None:
    """A key outside ALL_ATTRIBUTE_KEYS violates the CHECK constraint."""
    all_true = dict.fromkeys(_blank_all(), True)
    all_true |= {"min_age": 18, "max_age": 60, "born_after": None}
    any_true = dict.fromkeys(_blank_any(), True) | {"max_income": 100000}
    result = translate_eligibility(
        {"must_match_all": all_true, "must_match_one_of": any_true}
    )
    for rule in result.rules:
        assert rule.attribute_key in ALL_ATTRIBUTE_KEYS


def test_no_rule_violates_the_unique_constraint() -> None:
    all_true = dict.fromkeys(_blank_all(), True) | {"min_age": 18, "max_age": 60}
    any_true = dict.fromkeys(_blank_any(), True) | {"max_income": 100000}
    result = translate_eligibility(
        {"must_match_all": all_true, "must_match_one_of": any_true}
    )
    keys = [(r.rule_group, r.attribute_key, r.operator) for r in result.rules]
    assert len(keys) == len(set(keys))


def test_every_rule_has_a_label() -> None:
    result = _translate(
        all_block=_blank_all() | {"is_farmer": True, "min_age": 18},
        any_block=_blank_any() | {"max_income": 250000},
    )
    for rule in result.rules:
        assert isinstance(rule, TranslatedRule)
        assert rule.label.strip()


def test_income_label_uses_indian_digit_grouping() -> None:
    result = _translate(any_block=_blank_any() | {"max_income": 250000})
    assert "2,50,000" in result.rules[0].label


def test_translation_is_deterministic() -> None:
    block = _blank_all() | {"is_farmer": True, "min_age": 18}
    first = _translate(all_block=block)
    second = _translate(all_block=block)
    assert [r.attribute_key for r in first.rules] == [
        r.attribute_key for r in second.rules
    ]
