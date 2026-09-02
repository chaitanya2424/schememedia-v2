"""Match a user profile against a scheme's eligibility rules.

Pure domain logic -- no database, no HTTP, no import-time side effects. This
is deliberate (see requirement in HANDOFF §10 that eligibility matching be
reusable by direct eligibility queries, search ranking, the future AI
assistant, and the future frontend): none of those callers should have to
construct a SQLAlchemy session just to ask "would this profile match this
scheme?" `evaluate_scheme` takes plain data in and returns plain data out.

FOUR-VALUED LOGIC
------------------
Every rule, group, and scheme evaluates to one of:

    PASS           the stated requirement is satisfied
    FAIL           the stated requirement is not satisfied
    UNKNOWN        the profile has no value for the attribute this rule needs
    NOT_APPLICABLE there was nothing to evaluate (an empty rule group, or a
                   scheme with no rules at all -- 53 of 1,000 real schemes)

A missing profile attribute is UNKNOWN, never FAIL -- REBUILD_PLAN Assumption
A-3 ("eligibility ranks rather than filters") means a user who has not
disclosed their income must never be treated as if they failed an income
test they were never able to take.

This is Kleene's strong three-valued logic (K3) for AND/OR, with
NOT_APPLICABLE added as an identity element for empty inputs:

    AND (must_match_all): FAIL dominates, then UNKNOWN, then PASS.
        One known failure disqualifies regardless of what else is unknown.
    OR  (must_match_one_of): PASS dominates, then UNKNOWN, then FAIL.
        One known match satisfies regardless of what else failed or is
        unknown -- and critically, an EMPTY OR group is NOT_APPLICABLE, not
        FAIL. 80 of 1,000 real schemes have no `true` value anywhere in
        must_match_one_of; reading that as "matches nobody" was exactly the
        bug REBUILD_PLAN D.4 and the translator's own docstring warn about.

WHAT THIS MODULE DOES NOT DO
------------------------------
It never invents a profile value, never corrects an implausible rule (e.g.
one of the 33 real schemes with an annual_income ceiling under Rs 1,000 --
almost certainly lakhs recorded as rupees), and never re-derives whether a
scheme's source data was contradictory. That work already happened once, at
import time, in eligibility_translator.py: a genuine contradiction (3 real
schemes assert both is_govt_employee=true and not_govt_employee=true) means
neither rule was ever written to the database, and the scheme was flagged
`needs_review`. This module evaluates exactly the rules it is given, and
threads `needs_review` through to its result unexamined, so a caller can
show "this scheme's eligibility data has a known quality issue" without the
matcher re-diagnosing something already diagnosed.
"""

# ruff: noqa: UP042 -- str+Enum (not StrEnum) is deliberate, matching
# db/models/enums.py: SQLAlchemy and Pydantic both serialise these to plain
# strings, and StrEnum changes repr() in ways that leak into API responses.

from __future__ import annotations

import enum
from collections.abc import Mapping, Sequence
from dataclasses import dataclass, field
from typing import Protocol

from schememedia.db.models.enums import RuleGroup, RuleOperator

ProfileValue = bool | int | float | str | None
Profile = Mapping[str, ProfileValue]


class EligibilityState(str, enum.Enum):
    """See module docstring for the combination logic that produces these."""

    PASS = "pass"
    FAIL = "fail"
    UNKNOWN = "unknown"
    NOT_APPLICABLE = "not_applicable"


class RuleLike(Protocol):
    """Structural shape of one stored rule -- matches SchemeEligibilityRule.

    A Protocol rather than an import of the ORM model: this module must stay
    usable without a database. A real `SchemeEligibilityRule` row satisfies
    this automatically; so does eligibility_translator.TranslatedRule, which
    is what the test suite uses.
    """

    rule_group: RuleGroup
    attribute_key: str
    operator: RuleOperator
    value_bool: bool | None
    value_numeric: float | None
    value_text: str | None
    label: str
    label_hi: str | None


@dataclass(frozen=True)
class RuleEvaluation:
    """One rule, evaluated. Always PASS, FAIL, or UNKNOWN -- never
    NOT_APPLICABLE, which only arises from an empty *group* of rules, not
    from evaluating a rule that exists.
    """

    rule_group: RuleGroup
    attribute_key: str
    operator: RuleOperator
    state: EligibilityState
    label: str
    label_hi: str | None
    explanation: str


@dataclass(frozen=True)
class GroupEvaluation:
    rule_group: RuleGroup
    state: EligibilityState
    rules: tuple[RuleEvaluation, ...] = field(default_factory=tuple)


@dataclass(frozen=True)
class SchemeEligibilityResult:
    scheme_id: str
    state: EligibilityState
    must_match_all: GroupEvaluation
    must_match_one_of: GroupEvaluation
    # Threaded through from the scheme row, unexamined -- see module
    # docstring. True for the 35 real schemes the importer flagged (3
    # genuine contradictions + 33 implausible income ceilings, with one
    # scheme, SCH_EBE5D9CA, appearing in both).
    needs_review: bool = False

    @property
    def rules(self) -> tuple[RuleEvaluation, ...]:
        """Every evaluated rule, both groups, in stored order."""
        return self.must_match_all.rules + self.must_match_one_of.rules

    @property
    def explanations(self) -> list[str]:
        return [r.explanation for r in self.rules]


def _and_combine(states: Sequence[EligibilityState]) -> EligibilityState:
    """AND: FAIL dominates, then UNKNOWN, then PASS. Empty -> NOT_APPLICABLE."""
    present = [s for s in states if s is not EligibilityState.NOT_APPLICABLE]
    if not present:
        return EligibilityState.NOT_APPLICABLE
    if EligibilityState.FAIL in present:
        return EligibilityState.FAIL
    if EligibilityState.UNKNOWN in present:
        return EligibilityState.UNKNOWN
    return EligibilityState.PASS


def _or_combine(states: Sequence[EligibilityState]) -> EligibilityState:
    """OR: PASS dominates, then UNKNOWN, then FAIL. Empty -> NOT_APPLICABLE."""
    present = [s for s in states if s is not EligibilityState.NOT_APPLICABLE]
    if not present:
        return EligibilityState.NOT_APPLICABLE
    if EligibilityState.PASS in present:
        return EligibilityState.PASS
    if EligibilityState.UNKNOWN in present:
        return EligibilityState.UNKNOWN
    return EligibilityState.FAIL


def _coerce_numeric(value: ProfileValue) -> float | None:
    if value is None or isinstance(value, bool):
        return None
    if isinstance(value, int | float):
        return float(value)
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def _coerce_boolean(value: ProfileValue) -> bool | None:
    """Audit finding H3: only an actual JSON boolean counts. `ProfileValue`
    also permits `str`, and the public `/recommendations` API accepts a
    string for any profile key -- a caller sending the JSON *string*
    `"false"` (not the JSON boolean `false`) previously reached
    `bool(raw)`, which is `True` for any non-empty Python string, silently
    inverting the caller's intent into a PASS. Never guessing a profile
    value is this module's own stated design (see module docstring), the
    same reasoning `_coerce_numeric` above already follows for an
    unparseable number -> this mirrors it for booleans: an ambiguous input
    becomes UNKNOWN, never guessed at.
    """
    if isinstance(value, bool):
        return value
    return None


def _evaluate_rule(rule: RuleLike, profile: Profile) -> RuleEvaluation:
    """Evaluate one rule. Unknown/missing profile attribute -> UNKNOWN,
    never FAIL -- see module docstring.
    """
    raw = profile.get(rule.attribute_key)

    if raw is None:
        state = EligibilityState.UNKNOWN
    elif rule.operator is RuleOperator.EQ:
        if rule.value_bool is not None:
            boolean = _coerce_boolean(raw)
            if boolean is None:
                state = EligibilityState.UNKNOWN
            else:
                state = (
                    EligibilityState.PASS
                    if boolean == rule.value_bool
                    else EligibilityState.FAIL
                )
        elif rule.value_text is not None:
            state = (
                EligibilityState.PASS
                if str(raw) == rule.value_text
                else EligibilityState.FAIL
            )
        else:  # pragma: no cover - exactly-one-value CHECK constraint
            state = EligibilityState.UNKNOWN
    elif rule.operator in (RuleOperator.GTE, RuleOperator.LTE):
        numeric = _coerce_numeric(raw)
        threshold = rule.value_numeric
        if numeric is None or threshold is None:
            state = EligibilityState.UNKNOWN
        elif rule.operator is RuleOperator.GTE:
            state = (
                EligibilityState.PASS if numeric >= threshold else EligibilityState.FAIL
            )
        else:
            state = (
                EligibilityState.PASS if numeric <= threshold else EligibilityState.FAIL
            )
    else:  # pragma: no cover - exhaustive over RuleOperator today
        state = EligibilityState.UNKNOWN

    return RuleEvaluation(
        rule_group=rule.rule_group,
        attribute_key=rule.attribute_key,
        operator=rule.operator,
        state=state,
        label=rule.label,
        label_hi=rule.label_hi,
        explanation=_explain(rule, state),
    )


_STATE_PREFIX = {
    EligibilityState.PASS: "Matches",
    EligibilityState.FAIL: "Does not match",
    EligibilityState.UNKNOWN: "Unknown",
}


def _explain(rule: RuleLike, state: EligibilityState) -> str:
    """A plain, honest sentence for every state -- not just PASS.

    eligibility_labels.py deliberately covers only the affirmative,
    already-matched case (ADR: "never assert ineligibility" is a copy rule
    for what a citizen sees). This is a different, lower-level concern: the
    engine must explain *every* rule it evaluated, including the ones that
    failed or that it could not evaluate, so a caller has the full picture
    to build citizen-facing copy from -- or a debug view, or a ranking
    signal -- without the engine silently dropping information.
    """
    if state is EligibilityState.UNKNOWN:
        return f"Unknown: {rule.label} (not in your profile)"
    return f"{_STATE_PREFIX[state]}: {rule.label}"


def evaluate_scheme(
    scheme_id: str,
    rules: Sequence[RuleLike],
    profile: Profile,
    *,
    needs_review: bool = False,
) -> SchemeEligibilityResult:
    """Evaluate every rule for one scheme against one profile.

    `rules` is every rule for the scheme, both groups mixed together --
    exactly what a `SELECT * FROM scheme_eligibility_rules WHERE scheme_id =
    ...` returns. Unknown profile keys (typos, attributes from a future
    profile version this code does not know about yet) are never looked up
    and never raise -- only `rule.attribute_key` for a rule that actually
    exists is ever read from `profile`.
    """
    all_rules = [
        _evaluate_rule(r, profile) for r in rules if r.rule_group is RuleGroup.ALL
    ]
    any_rules = [
        _evaluate_rule(r, profile) for r in rules if r.rule_group is RuleGroup.ANY
    ]

    all_group = GroupEvaluation(
        rule_group=RuleGroup.ALL,
        state=_and_combine([r.state for r in all_rules]),
        rules=tuple(all_rules),
    )
    any_group = GroupEvaluation(
        rule_group=RuleGroup.ANY,
        state=_or_combine([r.state for r in any_rules]),
        rules=tuple(any_rules),
    )

    overall = _and_combine([all_group.state, any_group.state])

    return SchemeEligibilityResult(
        scheme_id=scheme_id,
        state=overall,
        must_match_all=all_group,
        must_match_one_of=any_group,
        needs_review=needs_review,
    )


def evaluate_schemes(
    rules_by_scheme: Mapping[str, Sequence[RuleLike]],
    profile: Profile,
    *,
    needs_review_by_scheme: Mapping[str, bool] | None = None,
) -> dict[str, SchemeEligibilityResult]:
    """Batch form of evaluate_scheme -- the shape search ranking needs.

    One profile against many schemes' rules, e.g. every candidate returned
    by a search query, so eligibility can be layered on as a ranking signal
    without re-fetching or re-evaluating one scheme at a time.
    """
    reviews = needs_review_by_scheme or {}
    return {
        scheme_id: evaluate_scheme(
            scheme_id, rules, profile, needs_review=reviews.get(scheme_id, False)
        )
        for scheme_id, rules in rules_by_scheme.items()
    }


def missing_attributes(result: SchemeEligibilityResult) -> list[str]:
    """Attribute keys this scheme's rules needed but the profile lacked.

    Useful for the "near-miss" UX idea already noted as not-yet-approved in
    HANDOFF §11 ("add your income to match 12 more") -- listed here because
    it falls straight out of the evaluation, not because that feature is
    being built now.
    """
    return sorted(
        {r.attribute_key for r in result.rules if r.state is EligibilityState.UNKNOWN}
    )
