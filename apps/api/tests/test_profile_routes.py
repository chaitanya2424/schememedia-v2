"""HTTP-level tests for GET/PUT /api/v1/me/profile.

The core "missing vs false" semantics get their most direct unit-level
coverage in tests/test_user_profile_conversion.py; this file proves the
same rule holds through the real HTTP + database round trip, plus
authorization and cross-user isolation.
"""

from __future__ import annotations

from httpx import AsyncClient

from tests._account_fixtures import (  # noqa: F401 -- fixtures
    auth_headers,
    client,
    fastapi_app,
    pytestmark,
    register,
)


async def test_profile_requires_authentication(client: AsyncClient) -> None:
    response = await client.get("/api/v1/me/profile")
    assert response.status_code == 401


async def test_a_new_users_profile_is_entirely_unanswered(client: AsyncClient) -> None:
    session = await register(client, "blank.profile@example.com")
    response = await client.get("/api/v1/me/profile", headers=auth_headers(session))
    assert response.status_code == 200
    body = response.json()
    assert body["answered_count"] == 0
    assert all(v is None for v in body["attributes"].values())
    assert body["total_count"] == len(body["attributes"])


async def test_update_sets_attributes_and_they_are_readable_afterwards(
    client: AsyncClient,
) -> None:
    session = await register(client, "update.profile@example.com")
    update = await client.put(
        "/api/v1/me/profile",
        headers=auth_headers(session),
        json={"attributes": {"is_farmer": True, "age": 34, "state_code": "KL"}},
    )
    assert update.status_code == 200, update.text
    body = update.json()
    assert body["attributes"]["is_farmer"] is True
    assert body["attributes"]["age"] == 34
    assert body["attributes"]["state_code"] == "KL"
    assert body["answered_count"] == 3

    fetched = await client.get("/api/v1/me/profile", headers=auth_headers(session))
    assert fetched.json()["attributes"]["is_farmer"] is True


async def test_a_real_false_answer_is_distinguishable_from_unanswered(
    client: AsyncClient,
) -> None:
    session = await register(client, "false.answer@example.com")
    await client.put(
        "/api/v1/me/profile",
        headers=auth_headers(session),
        json={"attributes": {"is_taxpayer": False}},
    )
    fetched = (
        await client.get("/api/v1/me/profile", headers=auth_headers(session))
    ).json()
    assert fetched["attributes"]["is_taxpayer"] is False
    assert fetched["answered_count"] == 1  # a real "no" counts as answered
    # Every other attribute is still genuinely unanswered.
    other_values = {k: v for k, v in fetched["attributes"].items() if k != "is_taxpayer"}
    assert all(v is None for v in other_values.values())


async def test_a_second_update_only_touches_the_keys_it_mentions(
    client: AsyncClient,
) -> None:
    session = await register(client, "partial.update@example.com")
    await client.put(
        "/api/v1/me/profile",
        headers=auth_headers(session),
        json={"attributes": {"is_farmer": True, "is_woman": True}},
    )
    second = await client.put(
        "/api/v1/me/profile",
        headers=auth_headers(session),
        json={"attributes": {"is_woman": False}},
    )
    assert second.status_code == 200
    attrs = second.json()["attributes"]
    assert attrs["is_farmer"] is True  # untouched by the second update
    assert attrs["is_woman"] is False  # updated


async def test_a_present_null_clears_an_attribute_back_to_unknown(
    client: AsyncClient,
) -> None:
    session = await register(client, "clear.attribute@example.com")
    await client.put(
        "/api/v1/me/profile",
        headers=auth_headers(session),
        json={"attributes": {"is_farmer": True}},
    )
    cleared = await client.put(
        "/api/v1/me/profile",
        headers=auth_headers(session),
        json={"attributes": {"is_farmer": None}},
    )
    assert cleared.json()["attributes"]["is_farmer"] is None
    assert cleared.json()["answered_count"] == 0


async def test_an_unrecognised_key_is_ignored_not_an_error(client: AsyncClient) -> None:
    session = await register(client, "unknown.key@example.com")
    response = await client.put(
        "/api/v1/me/profile",
        headers=auth_headers(session),
        json={"attributes": {"totally_made_up_field": "xyz", "is_farmer": True}},
    )
    assert response.status_code == 200
    assert response.json()["attributes"]["is_farmer"] is True
    assert "totally_made_up_field" not in response.json()["attributes"]


async def test_a_string_for_a_boolean_attribute_is_rejected(client: AsyncClient) -> None:
    session = await register(client, "bad.type.bool@example.com")
    response = await client.put(
        "/api/v1/me/profile",
        headers=auth_headers(session),
        json={"attributes": {"is_farmer": "yes"}},
    )
    assert response.status_code == 422
    assert response.json()["error"]["code"] == "validation_error"


async def test_a_string_for_age_is_rejected(client: AsyncClient) -> None:
    session = await register(client, "bad.type.age@example.com")
    response = await client.put(
        "/api/v1/me/profile",
        headers=auth_headers(session),
        json={"attributes": {"age": "thirty"}},
    )
    assert response.status_code == 422


async def test_profile_update_requires_authentication(client: AsyncClient) -> None:
    response = await client.put(
        "/api/v1/me/profile", json={"attributes": {"is_farmer": True}}
    )
    assert response.status_code == 401


# ---------------------------------------------------------------------------
# Cross-user isolation
# ---------------------------------------------------------------------------


async def test_two_users_have_independent_profiles(client: AsyncClient) -> None:
    alice = await register(client, "alice.profile@example.com")
    bob = await register(client, "bob.profile@example.com")

    await client.put(
        "/api/v1/me/profile",
        headers=auth_headers(alice),
        json={"attributes": {"is_farmer": True, "state_code": "KL"}},
    )
    await client.put(
        "/api/v1/me/profile",
        headers=auth_headers(bob),
        json={"attributes": {"is_student": True, "state_code": "MH"}},
    )

    alice_profile = (
        await client.get("/api/v1/me/profile", headers=auth_headers(alice))
    ).json()
    bob_profile = (
        await client.get("/api/v1/me/profile", headers=auth_headers(bob))
    ).json()

    assert alice_profile["attributes"]["is_farmer"] is True
    assert alice_profile["attributes"]["is_student"] is None
    assert alice_profile["attributes"]["state_code"] == "KL"

    assert bob_profile["attributes"]["is_student"] is True
    assert bob_profile["attributes"]["is_farmer"] is None
    assert bob_profile["attributes"]["state_code"] == "MH"


async def test_bobs_token_cannot_read_alices_profile_changes_as_its_own(
    client: AsyncClient,
) -> None:
    """A more adversarial framing of the same isolation guarantee: even
    right after Alice updates her profile, Bob's own authenticated request
    must never reflect it -- there is no code path here that could confuse
    the two, since the user id always comes from each caller's own token
    (core/deps.py:get_current_user_id), never from a request parameter.
    """
    alice = await register(client, "alice.isolation@example.com")
    bob = await register(client, "bob.isolation@example.com")

    await client.put(
        "/api/v1/me/profile",
        headers=auth_headers(alice),
        json={"attributes": {"is_pregnant_or_lactating": True}},
    )

    bob_profile = (
        await client.get("/api/v1/me/profile", headers=auth_headers(bob))
    ).json()
    assert bob_profile["attributes"]["is_pregnant_or_lactating"] is None
