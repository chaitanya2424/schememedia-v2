"""Pure unit tests for services/user_profile.py -- no database, no HTTP.

`UserProfile()` is constructed directly (never added to a session or
flushed) purely as a plain attribute bag; every function under test here is
ordinary Python over that object's attributes, so this is legitimate,
fast, precise unit testing of the conversion logic in isolation.

This is where "missing vs false eligibility semantics" -- an explicit
requirement -- gets its most direct, fastest coverage; tests/test_
profile_routes.py separately proves the same rule holds through the real
HTTP + database round trip.
"""

from __future__ import annotations

import pytest

from schememedia.db.models.enums import ALL_ATTRIBUTE_KEYS
from schememedia.db.models.user import UserProfile
from schememedia.services.user_profile import (
    ProfileUpdateError,
    apply_partial_update,
    completion_count,
    to_recommendation_profile,
    to_wire_dict,
)


def _blank_profile() -> UserProfile:
    import uuid

    return UserProfile(user_id=uuid.uuid4())


# ---------------------------------------------------------------------------
# to_wire_dict -- every key present, unanswered stays null
# ---------------------------------------------------------------------------


def test_wire_dict_has_every_eligibility_attribute_key() -> None:
    wire = to_wire_dict(_blank_profile())
    assert set(wire.keys()) == set(ALL_ATTRIBUTE_KEYS)


def test_a_blank_profile_is_entirely_null_in_the_wire_dict() -> None:
    wire = to_wire_dict(_blank_profile())
    assert all(v is None for v in wire.values())


def test_an_answered_boolean_appears_as_a_real_boolean_not_a_string() -> None:
    profile = _blank_profile()
    profile.is_farmer = True
    wire = to_wire_dict(profile)
    assert wire["is_farmer"] is True


def test_an_answered_boolean_false_is_a_real_false_not_null() -> None:
    """The other half of the honesty rule: a user who explicitly answered
    "no" must be distinguishable from a user who never answered.
    """
    profile = _blank_profile()
    profile.is_farmer = False
    wire = to_wire_dict(profile)
    assert wire["is_farmer"] is False
    assert wire["is_farmer"] is not None


def test_annual_income_round_trips_as_a_plain_float_not_a_decimal_string() -> None:
    from decimal import Decimal

    profile = _blank_profile()
    profile.annual_income = Decimal("85000.00")
    wire = to_wire_dict(profile)
    assert wire["annual_income"] == 85000.0
    assert isinstance(wire["annual_income"], float)


def test_state_code_round_trips_as_text() -> None:
    profile = _blank_profile()
    profile.state_code = "KL"
    wire = to_wire_dict(profile)
    assert wire["state_code"] == "KL"


# ---------------------------------------------------------------------------
# to_recommendation_profile -- THE core "missing vs false" contract:
# unanswered attributes are OMITTED, never coerced to False/0.
# ---------------------------------------------------------------------------


def test_blank_profile_produces_an_empty_recommendation_profile() -> None:
    """Not a dict full of Falses -- an empty dict, so evaluate_scheme sees
    every rule's attribute as genuinely missing (UNKNOWN), not failed.
    """
    assert to_recommendation_profile(_blank_profile()) == {}


def test_only_answered_attributes_appear_in_the_recommendation_profile() -> None:
    profile = _blank_profile()
    profile.is_sc_st = True
    profile.age = 34
    # Every other attribute stays None (unanswered).
    result = to_recommendation_profile(profile)
    assert result == {"is_sc_st": True, "age": 34}


def test_an_explicit_false_is_present_in_the_recommendation_profile() -> None:
    """A real "no" answer must reach the eligibility engine as False, not
    be filtered out alongside genuinely unanswered attributes.
    """
    profile = _blank_profile()
    profile.is_taxpayer = False
    result = to_recommendation_profile(profile)
    assert result == {"is_taxpayer": False}


def test_zero_income_is_present_not_treated_as_falsy_and_omitted() -> None:
    """0 is a real, meaningful answer (no income) -- `if value:` would
    wrongly drop it; the implementation must check `is not None` instead.
    """
    profile = _blank_profile()
    profile.annual_income = 0
    result = to_recommendation_profile(profile)
    assert result == {"annual_income": 0.0}


# ---------------------------------------------------------------------------
# completion_count
# ---------------------------------------------------------------------------


def test_completion_count_of_a_blank_profile_is_zero() -> None:
    assert completion_count(_blank_profile()) == 0


def test_completion_count_reflects_answered_attributes_only() -> None:
    profile = _blank_profile()
    profile.is_farmer = True
    profile.is_woman = False  # a real "no" still counts as answered
    profile.state_code = "KL"
    assert completion_count(profile) == 3


def test_completion_count_never_exceeds_the_full_vocabulary() -> None:
    profile = _blank_profile()
    for key in ALL_ATTRIBUTE_KEYS:
        setattr(
            profile, key, True if key not in ("age", "annual_income", "state_code") else 1
        )
    assert completion_count(profile) == len(ALL_ATTRIBUTE_KEYS)


# ---------------------------------------------------------------------------
# apply_partial_update -- PATCH semantics: present-with-null clears,
# absent leaves untouched.
# ---------------------------------------------------------------------------


def test_update_sets_a_previously_unanswered_attribute() -> None:
    profile = _blank_profile()
    apply_partial_update(profile, {"is_farmer": True})
    assert profile.is_farmer is True


def test_update_overwrites_a_previously_answered_attribute() -> None:
    profile = _blank_profile()
    profile.is_farmer = True
    apply_partial_update(profile, {"is_farmer": False})
    assert profile.is_farmer is False


def test_a_key_present_with_null_clears_it_back_to_unknown() -> None:
    profile = _blank_profile()
    profile.is_farmer = True
    apply_partial_update(profile, {"is_farmer": None})
    assert profile.is_farmer is None


def test_a_key_not_present_in_the_update_is_left_untouched() -> None:
    profile = _blank_profile()
    profile.is_farmer = True
    profile.is_woman = True
    apply_partial_update(profile, {"is_woman": False})  # is_farmer not mentioned
    assert profile.is_farmer is True  # unchanged
    assert profile.is_woman is False


def test_update_ignores_unrecognised_keys_without_raising() -> None:
    profile = _blank_profile()
    apply_partial_update(profile, {"totally_made_up_field": "xyz", "is_farmer": True})
    assert profile.is_farmer is True


def test_update_rejects_a_string_for_a_boolean_attribute() -> None:
    profile = _blank_profile()
    with pytest.raises(ProfileUpdateError):
        apply_partial_update(profile, {"is_farmer": "yes"})


def test_update_rejects_a_number_for_a_boolean_attribute() -> None:
    """1/0 are not booleans here -- see eligibility_matcher.py's own
    _coerce_boolean, which this mirrors: never guess a truthy number means
    True.
    """
    profile = _blank_profile()
    with pytest.raises(ProfileUpdateError):
        apply_partial_update(profile, {"is_farmer": 1})


def test_update_rejects_a_string_for_age() -> None:
    profile = _blank_profile()
    with pytest.raises(ProfileUpdateError):
        apply_partial_update(profile, {"age": "thirty"})


def test_update_rejects_a_boolean_for_age() -> None:
    """`isinstance(True, int)` is True in Python -- age's validation must
    explicitly exclude bool, not just check `isinstance(value, int | float)`.
    """
    profile = _blank_profile()
    with pytest.raises(ProfileUpdateError):
        apply_partial_update(profile, {"age": True})


def test_update_accepts_a_numeric_age_and_stores_it_as_int() -> None:
    profile = _blank_profile()
    apply_partial_update(profile, {"age": 42})
    assert profile.age == 42
    assert isinstance(profile.age, int)


def test_update_accepts_annual_income_as_a_float() -> None:
    profile = _blank_profile()
    apply_partial_update(profile, {"annual_income": 55000.5})
    assert profile.annual_income == 55000.5


def test_update_rejects_a_number_for_state_code() -> None:
    profile = _blank_profile()
    with pytest.raises(ProfileUpdateError):
        apply_partial_update(profile, {"state_code": 123})


def test_update_accepts_state_code_as_text() -> None:
    profile = _blank_profile()
    apply_partial_update(profile, {"state_code": "MH"})
    assert profile.state_code == "MH"


def test_multiple_fields_update_together() -> None:
    profile = _blank_profile()
    apply_partial_update(
        profile,
        {"is_farmer": True, "age": 30, "state_code": "KL", "annual_income": 120000},
    )
    assert profile.is_farmer is True
    assert profile.age == 30
    assert profile.state_code == "KL"
    assert profile.annual_income == 120000.0
