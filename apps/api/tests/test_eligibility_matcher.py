"""Tests for the eligibility matching engine.

Two layers, matching the project's own convention (test_search.py,
test_import.py):

  * Pure logic against synthetic rules -- every state, every combination,
    no database.
  * Validated against the real 1,000-scheme, 2,616-rule dataset -- the
    engine must run every real rule without exception, and the three
    genuinely contradictory schemes and the implausible-income schemes must
    behave exactly as the module docstring says they do.
"""

from __future__ import annotations

from pathlib import Path

import pytest
from sqlalchemy import create_engine, select, text
from sqlalchemy.orm import Session

from schememedia.db.models import Scheme, SchemeEligibilityRule
from schememedia.db.models.enums import RuleGroup, RuleOperator
from schememedia.importer.pipeline import sync_database_url
from schememedia.services.eligibility_matcher import (
    EligibilityState,
    evaluate_scheme,
    missing_attributes,
)
from schememedia.services.eligibility_translator import TranslatedRule
from tests.conftest import database_is_reachable, resolve_test_database_url

# TranslatedRule is a convenient concrete RuleLike -- see eligibility_matcher's
# own Protocol docstring. Used here purely as fixture data; the matcher has
# no import-time dependency on the translator.


def _rule(
    *,
    group: RuleGroup = RuleGroup.ALL,
    key: str = "is_farmer",
    op: RuleOperator = RuleOperator.EQ,
    value_bool: bool | None = None,
    value_numeric: float | None = None,
    value_text: str | None = None,
    label: str = "label",
) -> TranslatedRule:
    return TranslatedRule(
        rule_group=group,
        attribute_key=key,
        operator=op,
        label=label,
        value_bool=value_bool,
        value_numeric=value_numeric,
        value_text=value_text,
    )


# ---------------------------------------------------------------------------
# Boolean requirements -- PASS / FAIL / UNKNOWN
# ---------------------------------------------------------------------------


def test_matching_boolean_requirement_passes() -> None:
    rules = [_rule(key="is_farmer", value_bool=True, label="You are a farmer")]
    result = evaluate_scheme("SCH_X", rules, {"is_farmer": True})
    assert result.state is EligibilityState.PASS
    assert result.must_match_all.rules[0].state is EligibilityState.PASS


def test_non_matching_boolean_requirement_fails() -> None:
    rules = [_rule(key="is_farmer", value_bool=True)]
    result = evaluate_scheme("SCH_X", rules, {"is_farmer": False})
    assert result.state is EligibilityState.FAIL


def test_missing_attribute_is_unknown_not_fail() -> None:
    """The central rule of the whole module: absence is not a failed test."""
    rules = [_rule(key="is_farmer", value_bool=True)]
    result = evaluate_scheme("SCH_X", rules, {})
    assert result.state is EligibilityState.UNKNOWN
    assert result.must_match_all.rules[0].state is EligibilityState.UNKNOWN


def test_explicit_none_is_also_unknown() -> None:
    rules = [_rule(key="is_farmer", value_bool=True)]
    result = evaluate_scheme("SCH_X", rules, {"is_farmer": None})
    assert result.state is EligibilityState.UNKNOWN


# ---------------------------------------------------------------------------
# Audit finding H3: a boolean rule against a *string* profile value must
# never fall back to Python's own truthiness. `bool("false")` is `True` --
# without the fix this regression-tests, a caller sending the JSON string
# "false" (not the JSON boolean false) for a boolean attribute would
# silently PASS a rule they intended to fail. The public /recommendations
# API's `profile` type (`dict[str, bool | float | str | None]`) allows a
# string for any key, so this is reachable through the documented contract,
# not just a synthetic edge case.
# ---------------------------------------------------------------------------


def test_string_false_is_unknown_not_a_truthy_pass() -> None:
    rules = [_rule(key="is_farmer", value_bool=True, label="You are a farmer")]
    result = evaluate_scheme("SCH_X", rules, {"is_farmer": "false"})
    assert result.state is EligibilityState.UNKNOWN, (
        "a string 'false' must never be coerced via Python truthiness into a pass"
    )


def test_string_true_is_also_unknown_never_guessed() -> None:
    """Symmetric with the case above: a string is never a legitimate
    boolean input, regardless of which way it looks like it should coerce.
    """
    rules = [_rule(key="is_farmer", value_bool=True)]
    result = evaluate_scheme("SCH_X", rules, {"is_farmer": "true"})
    assert result.state is EligibilityState.UNKNOWN


def test_a_real_json_boolean_is_unaffected_by_the_string_fix() -> None:
    """Confirms the fix is scoped to strings -- an actual bool True/False
    still evaluates normally, matching test_matching_boolean_requirement_
    passes/test_non_matching_boolean_requirement_fails above.
    """
    rules = [_rule(key="is_farmer", value_bool=False, label="Not a farmer")]
    assert (
        evaluate_scheme("SCH_X", rules, {"is_farmer": False}).state
        is EligibilityState.PASS
    )
    assert (
        evaluate_scheme("SCH_X", rules, {"is_farmer": True}).state
        is EligibilityState.FAIL
    )


# ---------------------------------------------------------------------------
# Genuine negative requirements -- e.g. not_govt_employee -> value_bool=False
# ---------------------------------------------------------------------------


def test_negative_requirement_passes_when_attribute_is_false() -> None:
    """REAL shape: not_govt_employee maps to (is_govt_employee, required=False)."""
    rules = [_rule(key="is_govt_employee", value_bool=False, label="Not a govt employee")]
    result = evaluate_scheme("SCH_X", rules, {"is_govt_employee": False})
    assert result.state is EligibilityState.PASS


def test_negative_requirement_fails_when_attribute_is_true() -> None:
    rules = [_rule(key="is_govt_employee", value_bool=False)]
    result = evaluate_scheme("SCH_X", rules, {"is_govt_employee": True})
    assert result.state is EligibilityState.FAIL


def test_negative_requirement_is_unknown_when_missing() -> None:
    rules = [_rule(key="is_govt_employee", value_bool=False)]
    result = evaluate_scheme("SCH_X", rules, {})
    assert result.state is EligibilityState.UNKNOWN


# ---------------------------------------------------------------------------
# Numeric thresholds -- gte / lte, boundary conditions
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("age", "expected"),
    [
        (17, EligibilityState.FAIL),
        (18, EligibilityState.PASS),
        (19, EligibilityState.PASS),
    ],
)
def test_gte_boundary_is_inclusive(age: int, expected: EligibilityState) -> None:
    rules = [_rule(key="age", op=RuleOperator.GTE, value_numeric=18)]
    result = evaluate_scheme("SCH_X", rules, {"age": age})
    assert result.state is expected


@pytest.mark.parametrize(
    ("income", "expected"),
    [
        (250001, EligibilityState.FAIL),
        (250000, EligibilityState.PASS),
        (249999, EligibilityState.PASS),
    ],
)
def test_lte_boundary_is_inclusive(income: int, expected: EligibilityState) -> None:
    rules = [
        _rule(
            group=RuleGroup.ANY,
            key="annual_income",
            op=RuleOperator.LTE,
            value_numeric=250000,
        )
    ]
    result = evaluate_scheme("SCH_X", rules, {"annual_income": income})
    assert result.state is expected


def test_numeric_rule_is_unknown_when_attribute_missing() -> None:
    rules = [_rule(key="age", op=RuleOperator.GTE, value_numeric=18)]
    result = evaluate_scheme("SCH_X", rules, {})
    assert result.state is EligibilityState.UNKNOWN


def test_min_and_max_age_both_apply() -> None:
    rules = [
        _rule(key="age", op=RuleOperator.GTE, value_numeric=18),
        _rule(key="age", op=RuleOperator.LTE, value_numeric=60),
    ]
    assert evaluate_scheme("SCH_X", rules, {"age": 30}).state is EligibilityState.PASS
    assert evaluate_scheme("SCH_X", rules, {"age": 17}).state is EligibilityState.FAIL
    assert evaluate_scheme("SCH_X", rules, {"age": 61}).state is EligibilityState.FAIL


# ---------------------------------------------------------------------------
# must_match_all (AND) -- FAIL dominates, then UNKNOWN, then PASS
# ---------------------------------------------------------------------------


def test_all_group_fails_if_any_rule_fails_even_with_unknowns() -> None:
    rules = [
        _rule(key="is_farmer", value_bool=True),
        _rule(key="is_taxpayer", value_bool=True),  # unknown
        _rule(key="owns_cultivable_land", value_bool=True),  # known false
    ]
    result = evaluate_scheme(
        "SCH_X", rules, {"is_farmer": True, "owns_cultivable_land": False}
    )
    assert result.must_match_all.state is EligibilityState.FAIL
    assert result.state is EligibilityState.FAIL


def test_all_group_is_unknown_if_nothing_fails_but_something_is_unknown() -> None:
    rules = [
        _rule(key="is_farmer", value_bool=True),
        _rule(key="is_taxpayer", value_bool=True),
    ]
    result = evaluate_scheme("SCH_X", rules, {"is_farmer": True})
    assert result.must_match_all.state is EligibilityState.UNKNOWN


def test_all_group_passes_when_every_rule_passes() -> None:
    rules = [
        _rule(key="is_farmer", value_bool=True),
        _rule(key="is_woman", value_bool=True),
    ]
    result = evaluate_scheme("SCH_X", rules, {"is_farmer": True, "is_woman": True})
    assert result.must_match_all.state is EligibilityState.PASS


# ---------------------------------------------------------------------------
# must_match_one_of (OR) -- PASS dominates, then UNKNOWN, then FAIL
# ---------------------------------------------------------------------------


def test_any_group_passes_if_one_rule_passes_even_with_failures() -> None:
    rules = [
        _rule(group=RuleGroup.ANY, key="is_sc_st", value_bool=True),
        _rule(group=RuleGroup.ANY, key="is_lig", value_bool=True),
    ]
    result = evaluate_scheme("SCH_X", rules, {"is_sc_st": True, "is_lig": False})
    assert result.must_match_one_of.state is EligibilityState.PASS


def test_any_group_is_unknown_if_nothing_passes_but_something_is_unknown() -> None:
    rules = [
        _rule(group=RuleGroup.ANY, key="is_sc_st", value_bool=True),
        _rule(group=RuleGroup.ANY, key="is_lig", value_bool=True),
    ]
    result = evaluate_scheme("SCH_X", rules, {"is_sc_st": False})
    assert result.must_match_one_of.state is EligibilityState.UNKNOWN


def test_any_group_fails_only_when_everything_is_known_and_false() -> None:
    rules = [
        _rule(group=RuleGroup.ANY, key="is_sc_st", value_bool=True),
        _rule(group=RuleGroup.ANY, key="is_lig", value_bool=True),
    ]
    result = evaluate_scheme("SCH_X", rules, {"is_sc_st": False, "is_lig": False})
    assert result.must_match_one_of.state is EligibilityState.FAIL


# ---------------------------------------------------------------------------
# Empty groups and no-rule schemes -- NOT_APPLICABLE
# ---------------------------------------------------------------------------


def test_scheme_with_no_rules_at_all_is_not_applicable() -> None:
    """REAL: 53 of 1,000 schemes yield zero rules after translation."""
    result = evaluate_scheme("SCH_X", [], {"is_farmer": True})
    assert result.state is EligibilityState.NOT_APPLICABLE
    assert result.must_match_all.state is EligibilityState.NOT_APPLICABLE
    assert result.must_match_one_of.state is EligibilityState.NOT_APPLICABLE


def test_empty_any_group_does_not_fail_the_scheme() -> None:
    """REAL: 80 of 1,000 schemes have no true value in must_match_one_of.

    Reading an empty OR group as "matches nobody" is exactly the bug
    REBUILD_PLAN D.4 warns about -- an empty group must be NOT_APPLICABLE,
    never FAIL, and must not drag down an otherwise-passing ALL group.
    """
    rules = [_rule(group=RuleGroup.ALL, key="is_farmer", value_bool=True)]
    result = evaluate_scheme("SCH_X", rules, {"is_farmer": True})
    assert result.must_match_one_of.state is EligibilityState.NOT_APPLICABLE
    assert result.state is EligibilityState.PASS


def test_empty_all_group_does_not_block_a_passing_any_group() -> None:
    rules = [_rule(group=RuleGroup.ANY, key="is_sc_st", value_bool=True)]
    result = evaluate_scheme("SCH_X", rules, {"is_sc_st": True})
    assert result.must_match_all.state is EligibilityState.NOT_APPLICABLE
    assert result.state is EligibilityState.PASS


# ---------------------------------------------------------------------------
# Contradictory rules
# ---------------------------------------------------------------------------


def test_contradictory_rules_for_the_same_attribute_resolve_to_fail() -> None:
    """The current import pipeline never produces this (translator +
    the DB's own unique constraint on (scheme, group, attribute, operator)
    prevent it -- see eligibility_translator's contradiction handling), but
    the engine is given whatever rules it is given and must not crash or
    silently pick a side if it ever receives two rules asserting opposite
    values for the same attribute. Kleene AND makes the honest, unsurprising
    call: an unsatisfiable pair is a known failure, not an unknown.
    """
    rules = [
        _rule(key="is_govt_employee", value_bool=True),
        _rule(key="is_govt_employee", value_bool=False),
    ]
    result = evaluate_scheme("SCH_X", rules, {"is_govt_employee": True})
    assert result.state is EligibilityState.FAIL


# ---------------------------------------------------------------------------
# Unknown profile attributes -- never looked at, never raise
# ---------------------------------------------------------------------------


def test_unknown_profile_keys_are_ignored_not_erroring() -> None:
    rules = [_rule(key="is_farmer", value_bool=True)]
    result = evaluate_scheme(
        "SCH_X",
        rules,
        {"is_farmer": True, "favourite_colour": "blue", "typo_atribute": 1},
    )
    assert result.state is EligibilityState.PASS


def test_missing_attributes_helper_lists_only_unknowns() -> None:
    rules = [
        _rule(key="is_farmer", value_bool=True),
        _rule(key="is_taxpayer", value_bool=True),
        _rule(group=RuleGroup.ANY, key="is_sc_st", value_bool=True),
    ]
    result = evaluate_scheme("SCH_X", rules, {"is_farmer": True})
    assert missing_attributes(result) == ["is_sc_st", "is_taxpayer"]


# ---------------------------------------------------------------------------
# Explanations -- every rule, every state
# ---------------------------------------------------------------------------


def test_every_rule_gets_an_explanation_regardless_of_state() -> None:
    rules = [
        _rule(key="is_farmer", value_bool=True, label="You are a farmer"),
        _rule(key="is_taxpayer", value_bool=True, label="You pay income tax"),
        _rule(key="is_woman", value_bool=True, label="You are a woman"),
    ]
    result = evaluate_scheme("SCH_X", rules, {"is_farmer": True, "is_woman": False})
    explanations = {r.attribute_key: r.explanation for r in result.rules}
    assert "Matches" in explanations["is_farmer"]
    assert "Unknown" in explanations["is_taxpayer"]
    assert "Does not match" in explanations["is_woman"]
    assert all(r.explanation for r in result.rules)


def test_needs_review_is_threaded_through_unexamined() -> None:
    result = evaluate_scheme("SCH_X", [], {}, needs_review=True)
    assert result.needs_review is True


# ---------------------------------------------------------------------------
# Validated against the real dataset
# ---------------------------------------------------------------------------

TEST_DATABASE_URL = resolve_test_database_url()
DATABASE_AVAILABLE = database_is_reachable(TEST_DATABASE_URL)
REPO_ROOT = Path(__file__).resolve().parents[3]
SCHEMES_JSON = REPO_ROOT / "schemes.json"

pytestmark_real = pytest.mark.skipif(
    not (DATABASE_AVAILABLE and SCHEMES_JSON.exists()),
    reason="PostgreSQL unreachable or schemes.json missing; see README section 1",
)


@pytest.fixture(scope="module")
def real_rules_by_scheme() -> dict[str, list[SchemeEligibilityRule]]:
    """Every rule for every real scheme, exactly as the importer wrote it.

    Self-contained -- imports schemes.json itself (mirroring test_import.py)
    rather than assuming another test module has already populated the
    database. pytest does not guarantee cross-file ordering, and this file's
    real-data assertions (53 zero-rule schemes, the 3 contradictory scheme
    ids, ...) need the actual import to have happened, not whatever the
    database happens to contain.
    """
    from schememedia.importer.pipeline import run_import

    engine = create_engine(sync_database_url(TEST_DATABASE_URL), future=True)
    with Session(engine) as session:
        session.execute(
            text(
                "TRUNCATE schemes, categories, tags, scheme_tags, "
                "scheme_benefits, scheme_documents, scheme_eligibility_rules "
                "CASCADE"
            )
        )
        session.commit()
        run_import(session, SCHEMES_JSON)
        session.commit()

        rows = session.execute(select(SchemeEligibilityRule)).scalars().all()
        by_scheme: dict[str, list[SchemeEligibilityRule]] = {}
        for row in rows:
            by_scheme.setdefault(row.scheme_id, []).append(row)
        yield by_scheme

        session.execute(
            text(
                "TRUNCATE schemes, categories, tags, scheme_tags, "
                "scheme_benefits, scheme_documents, scheme_eligibility_rules "
                "CASCADE"
            )
        )
        session.commit()
    engine.dispose()


@pytest.fixture(scope="module")
def real_data_present(
    real_rules_by_scheme: dict[str, list[SchemeEligibilityRule]],
) -> bool:
    return len(real_rules_by_scheme) > 0


@pytestmark_real
def test_every_real_rule_evaluates_without_exception(
    real_rules_by_scheme: dict[str, list[SchemeEligibilityRule]],
    real_data_present: bool,
) -> None:
    if not real_data_present:
        pytest.skip("no rules in the test database -- run dev.py import-data first")

    # A representative but incomplete profile -- some attributes known, most
    # not, matching a realistic partially-filled-in user.
    profile = {
        "age": 35,
        "is_woman": True,
        "is_sc_st": True,
        "annual_income": 200000,
        "is_farmer": False,
    }
    total_rules = 0
    total_schemes = 0
    for scheme_id, rules in real_rules_by_scheme.items():
        result = evaluate_scheme(scheme_id, rules, profile)
        total_schemes += 1
        total_rules += len(result.rules)
        assert result.state in EligibilityState
        for rule_eval in result.rules:
            assert rule_eval.state in (
                EligibilityState.PASS,
                EligibilityState.FAIL,
                EligibilityState.UNKNOWN,
            )
            assert rule_eval.explanation

    assert total_schemes == len(real_rules_by_scheme)
    assert total_rules == sum(len(v) for v in real_rules_by_scheme.values())


@pytestmark_real
def test_real_schemes_with_zero_rules_are_not_applicable(
    real_rules_by_scheme: dict[str, list[SchemeEligibilityRule]],
    real_data_present: bool,
) -> None:
    """REAL: 53 of 1,000 schemes yield zero rules."""
    if not real_data_present:
        pytest.skip("no rules in the test database -- run dev.py import-data first")
    engine = create_engine(sync_database_url(TEST_DATABASE_URL), future=True)
    with Session(engine) as session:
        all_scheme_ids = set(session.execute(select(Scheme.scheme_id)).scalars().all())
    engine.dispose()

    zero_rule_ids = all_scheme_ids - real_rules_by_scheme.keys()
    assert len(zero_rule_ids) == 53

    for scheme_id in zero_rule_ids:
        result = evaluate_scheme(scheme_id, [], {})
        assert result.state is EligibilityState.NOT_APPLICABLE


@pytestmark_real
def test_the_three_contradictory_schemes_have_no_govt_employee_rule(
    real_rules_by_scheme: dict[str, list[SchemeEligibilityRule]],
    real_data_present: bool,
) -> None:
    """REAL: SCH_38603FF1, SCH_EBE5D9CA, SCH_DF093CC3.

    Both source flags (is_govt_employee=true, not_govt_employee=true) were
    voided at import time -- neither rule exists -- so evaluating any of
    these schemes contributes nothing for is_govt_employee regardless of
    profile, and needs_review must be true.
    """
    if not real_data_present:
        pytest.skip("no rules in the test database -- run dev.py import-data first")
    engine = create_engine(sync_database_url(TEST_DATABASE_URL), future=True)
    with Session(engine) as session:
        for scheme_id in ("SCH_38603FF1", "SCH_EBE5D9CA", "SCH_DF093CC3"):
            rules = real_rules_by_scheme.get(scheme_id, [])
            assert all(r.attribute_key != "is_govt_employee" for r in rules)

            needs_review = session.scalar(
                select(Scheme.needs_review).where(Scheme.scheme_id == scheme_id)
            )
            assert needs_review is True
            result = evaluate_scheme(
                scheme_id, rules, {"is_govt_employee": True}, needs_review=needs_review
            )
            assert result.needs_review is True
    engine.dispose()


@pytestmark_real
def test_an_implausible_income_threshold_is_evaluated_as_stored(
    real_rules_by_scheme: dict[str, list[SchemeEligibilityRule]],
    real_data_present: bool,
) -> None:
    """REAL: SCH_58532113 carries max_income <= 1 -- almost certainly lakhs
    recorded as rupees, per the translator's own flag on this rule at
    import. The engine does not correct it: any realistic income fails it.
    """
    if not real_data_present:
        pytest.skip("no rules in the test database -- run dev.py import-data first")
    rules = real_rules_by_scheme.get("SCH_58532113", [])
    income_rules = [r for r in rules if r.attribute_key == "annual_income"]
    assert income_rules, "fixture assumption changed -- re-check the scheme id"
    assert income_rules[0].value_numeric == 1

    result = evaluate_scheme("SCH_58532113", rules, {"annual_income": 250000})
    matching_eval = next(r for r in result.rules if r.attribute_key == "annual_income")
    assert matching_eval.state is EligibilityState.FAIL


@pytestmark_real
def test_a_known_real_scheme_matches_the_expected_profile(
    real_rules_by_scheme: dict[str, list[SchemeEligibilityRule]],
    real_data_present: bool,
) -> None:
    """REAL: SCH_1F47743B -- Biju Patnaik Sports Award. any-group only:
    is_sc_st / is_ews / is_lig. No must_match_all rules at all.
    """
    if not real_data_present:
        pytest.skip("no rules in the test database -- run dev.py import-data first")
    rules = real_rules_by_scheme.get("SCH_1F47743B", [])

    matching = evaluate_scheme("SCH_1F47743B", rules, {"is_sc_st": True})
    assert matching.state is EligibilityState.PASS
    assert matching.must_match_all.state is EligibilityState.NOT_APPLICABLE

    unknown_profile = evaluate_scheme("SCH_1F47743B", rules, {})
    assert unknown_profile.state is EligibilityState.UNKNOWN

    non_matching = evaluate_scheme(
        "SCH_1F47743B", rules, {"is_sc_st": False, "is_ews": False, "is_lig": False}
    )
    assert non_matching.state is EligibilityState.FAIL
