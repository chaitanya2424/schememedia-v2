"""The authenticated user's eligibility profile.

Persists using the exact same EligibilityAttribute vocabulary the
eligibility engine and /recommendations already use -- see
services/user_profile.py for the conversion. Every write here is scoped to
`user.id` from the access token (core/deps.py:get_current_user); no request
here ever accepts a user id.
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Body
from pydantic import BaseModel, Field

from schememedia.core.deps import CurrentUserDep, UserProfileRepositoryDep
from schememedia.core.errors import ValidationError
from schememedia.db.models.user import UserProfile
from schememedia.services.user_profile import (
    ProfileUpdateError,
    apply_partial_update,
    completion_count,
    to_wire_dict,
)

router = APIRouter(prefix="/me/profile", tags=["profile"])

# A wire-safe mirror of services.eligibility_matcher.ProfileValue (which
# also allows `int` -- collapsed into `float` here, same as every other
# numeric field on this API's public schemas).
ProfileValueOut = bool | float | str | None


class ProfileResponseOut(BaseModel):
    attributes: dict[str, ProfileValueOut] = Field(
        description=(
            "Every EligibilityAttribute key, with its stored value or null "
            "if not yet answered. Null is a genuine 'unknown', never a "
            "false -- see services/user_profile.py."
        )
    )
    answered_count: int
    total_count: int

    @classmethod
    def from_domain(cls, profile: UserProfile) -> ProfileResponseOut:
        wire = to_wire_dict(profile)
        return cls(
            attributes=wire,
            answered_count=completion_count(profile),
            total_count=len(wire),
        )


class ProfileUpdateRequest(BaseModel):
    attributes: dict[str, ProfileValueOut] = Field(
        description=(
            "Partial update -- only the keys present are changed. A key "
            "present with value null clears that attribute back to "
            "unknown; a key not present is left untouched. Unrecognised "
            "keys are ignored."
        )
    )


@router.get(
    "",
    response_model=ProfileResponseOut,
    operation_id="getMyProfile",
    summary="The signed-in user's eligibility profile",
)
async def get_profile(
    user: CurrentUserDep, profiles: UserProfileRepositoryDep
) -> ProfileResponseOut:
    profile = await profiles.get_or_create(user.id)
    return ProfileResponseOut.from_domain(profile)


@router.put(
    "",
    response_model=ProfileResponseOut,
    operation_id="updateMyProfile",
    summary="Update the signed-in user's eligibility profile (partial)",
    responses={422: {"description": "A value did not match its attribute's type."}},
)
async def update_profile(
    user: CurrentUserDep,
    profiles: UserProfileRepositoryDep,
    body: Annotated[ProfileUpdateRequest, Body()],
) -> ProfileResponseOut:
    profile = await profiles.get_or_create(user.id)
    try:
        apply_partial_update(profile, body.attributes)
    except ProfileUpdateError as exc:
        raise ValidationError(str(exc)) from exc
    return ProfileResponseOut.from_domain(profile)
