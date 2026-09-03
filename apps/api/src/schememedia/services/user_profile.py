"""Convert between UserProfile (db/models/user.py) and the plain `Profile`
dict the eligibility engine, RecommendationService, and the assistant
already accept -- see services/eligibility_matcher.py's `Profile` type and
db/models/enums.py's `EligibilityAttribute`.

THE SAME MODEL, NOT A SECOND ONE
------------------------------------
UserProfile's column names ARE the EligibilityAttribute vocabulary itself
(EligibilityAttribute.IS_WOMAN.value == "is_woman" == UserProfile.is_woman)
-- this module reads/writes those columns generically over
ALL_ATTRIBUTE_KEYS via getattr/setattr, rather than hand-writing a 27-line
mapping that could silently drift from the enum.

MISSING VS FALSE -- the one rule every function here exists to protect
--------------------------------------------------------------------------
A UserProfile column is NULL until the user actually answers that
question. `to_recommendation_profile` OMITS a None-valued attribute from
the returned dict entirely (never writes `False` or `0` in its place) --
`evaluate_scheme` (eligibility_matcher.py) already treats a missing key as
UNKNOWN, so preserving "absent" all the way through is what keeps a
skipped question UNKNOWN instead of silently becoming a failed one.
`apply_partial_update` mirrors this on the write side: a key genuinely
present in an update with value `None` clears that attribute back to
unknown; a key simply not present is left untouched -- these are different
things (PATCH semantics), and conflating them would make "I don't want to
answer this" indistinguishable from "I didn't touch this field".
"""

from __future__ import annotations

from decimal import Decimal
from typing import Any

from schememedia.db.models.enums import (
    ALL_ATTRIBUTE_KEYS,
    AttributeType,
    EligibilityAttribute,
    attribute_type,
)
from schememedia.db.models.user import UserProfile
from schememedia.services.eligibility_matcher import Profile, ProfileValue

_AGE_KEY = EligibilityAttribute.AGE.value


def _wire_value(raw: Any) -> ProfileValue:
    """A UserProfile column's Python value, in the JSON-safe shape
    ProfileValue allows -- only annual_income (a `Numeric` column,
    round-trips as `decimal.Decimal`) needs converting.
    """
    if isinstance(raw, Decimal):
        return float(raw)
    return raw  # type: ignore[no-any-return]


def to_wire_dict(profile: UserProfile) -> dict[str, ProfileValue]:
    """Every EligibilityAttribute key, present with its value or `None` --
    the full vocabulary is always in the response, so a client can render
    "not yet answered" for a key that is merely absent, without having to
    know the vocabulary itself.
    """
    return {key: _wire_value(getattr(profile, key)) for key in ALL_ATTRIBUTE_KEYS}


def to_recommendation_profile(profile: UserProfile) -> Profile:
    """See module docstring's "MISSING VS FALSE" section -- a None-valued
    attribute is omitted, never coerced.
    """
    return {
        key: _wire_value(getattr(profile, key))
        for key in ALL_ATTRIBUTE_KEYS
        if getattr(profile, key) is not None
    }


def completion_count(profile: UserProfile) -> int:
    """How many of the (currently 27) attributes the user has actually
    answered -- the same "N of 27" metric the Flutter app already computes
    client-side each session (ProfileFormController.totalAnswered); this
    is its persisted, server-side equivalent.
    """
    return sum(1 for key in ALL_ATTRIBUTE_KEYS if getattr(profile, key) is not None)


class ProfileUpdateError(ValueError):
    """A value in an update does not fit its attribute's type -- e.g. a
    string where age needs a number. Raised, not silently coerced or
    dropped -- the same "never guess a profile value" rule
    eligibility_matcher.py applies at evaluation time, applied here at
    write time instead.
    """


def apply_partial_update(profile: UserProfile, updates: dict[str, ProfileValue]) -> None:
    """Mutates `profile` in place. Only keys present in `updates` are
    touched (PATCH semantics, see module docstring); a present key with
    value `None` clears that attribute back to unknown.

    Unrecognised keys are silently ignored -- the same "never error on an
    unknown attribute" convention as
    services/assistant.py:execute_find_matching_schemes and
    routers/recommendations.py's own profile filtering, so a client on an
    older/newer attribute vocabulary degrades gracefully instead of
    failing the whole request over one stray key.
    """
    for key, value in updates.items():
        if key not in ALL_ATTRIBUTE_KEYS:
            continue
        if value is None:
            setattr(profile, key, None)
            continue

        expected = attribute_type(EligibilityAttribute(key))
        if expected is AttributeType.BOOLEAN:
            if not isinstance(value, bool):
                raise ProfileUpdateError(f"{key!r} must be a boolean.")
            setattr(profile, key, value)
        elif expected is AttributeType.NUMERIC:
            if isinstance(value, bool) or not isinstance(value, int | float):
                raise ProfileUpdateError(f"{key!r} must be a number.")
            # `age` is an Integer column; annual_income is Numeric. Both
            # are AttributeType.NUMERIC, but only age needs an int cast.
            setattr(profile, key, int(value) if key == _AGE_KEY else float(value))
        else:  # AttributeType.TEXT -- state_code today
            if not isinstance(value, str):
                raise ProfileUpdateError(f"{key!r} must be a string.")
            setattr(profile, key, value)
