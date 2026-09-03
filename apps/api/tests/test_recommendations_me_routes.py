"""HTTP-level tests for POST /api/v1/recommendations/me -- the
authenticated variant that ranks against the caller's own persisted
profile, and for confirming the existing public /api/v1/recommendations
endpoint is unaffected by any of this.

REAL: SCH_08134B86 (the small fixture's first record) has must_match_one_of
{is_divyang, is_lig, annual_income<=100000} and no must_match_all rules --
setting is_divyang=True in a profile is enough to make its overall
eligibility_state "pass" (an empty ALL group is NOT_APPLICABLE, which
_and_combine drops, leaving the ANY group's PASS as the overall result;
see services/eligibility_matcher.py).
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

REAL_SCHEME_ID = "SCH_08134B86"
QUERY = "scholarship for disabled students"


def _find(recommendations: list[dict], scheme_id: str) -> dict | None:
    return next((r for r in recommendations if r["scheme_id"] == scheme_id), None)


async def test_my_recommendations_requires_authentication(client: AsyncClient) -> None:
    response = await client.post("/api/v1/recommendations/me", json={"query": QUERY})
    assert response.status_code == 401


async def test_a_blank_profile_reports_profile_provided_false(
    client: AsyncClient,
) -> None:
    session = await register(client, "blank.reco@example.com")
    response = await client.post(
        "/api/v1/recommendations/me",
        headers=auth_headers(session),
        json={"query": QUERY, "limit": 20},
    )
    assert response.status_code == 200, response.text
    assert response.json()["profile_provided"] is False


async def test_recommendations_use_the_persisted_profile(client: AsyncClient) -> None:
    session = await register(client, "persisted.reco@example.com")
    await client.put(
        "/api/v1/me/profile",
        headers=auth_headers(session),
        json={"attributes": {"is_divyang": True}},
    )

    response = await client.post(
        "/api/v1/recommendations/me",
        headers=auth_headers(session),
        json={"query": QUERY, "limit": 20},
    )
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["profile_provided"] is True

    match = _find(body["recommendations"], REAL_SCHEME_ID)
    assert match is not None, body["recommendations"]
    assert match["eligibility_state"] == "pass"


async def test_a_client_supplied_profile_field_is_ignored(client: AsyncClient) -> None:
    """The authenticated endpoint's request schema has no `profile` field
    at all (MyRecommendationRequest) -- a caller attempting to send one
    must have zero effect; the persisted profile is always what's used.
    """
    session = await register(client, "ignored.client.profile@example.com")
    await client.put(
        "/api/v1/me/profile",
        headers=auth_headers(session),
        json={"attributes": {"is_divyang": True}},
    )

    response = await client.post(
        "/api/v1/recommendations/me",
        headers=auth_headers(session),
        json={
            "query": QUERY,
            "limit": 20,
            "profile": {"is_divyang": False, "is_lig": False},  # ignored
        },
    )
    assert response.status_code == 200, response.text
    match = _find(response.json()["recommendations"], REAL_SCHEME_ID)
    assert match is not None
    # Still "pass" -- reflects the real, persisted is_divyang=True, not the
    # discarded client-supplied is_divyang=False.
    assert match["eligibility_state"] == "pass"


async def test_recommendations_never_hard_filter_by_eligibility(
    client: AsyncClient,
) -> None:
    """The authenticated endpoint calls the exact same RecommendationService
    the public one does -- eligibility only ever demotes, never removes a
    result. A profile engineered to FAIL this scheme's rules must still
    return it.
    """
    session = await register(client, "no.filter.reco@example.com")
    await client.put(
        "/api/v1/me/profile",
        headers=auth_headers(session),
        json={
            "attributes": {"is_divyang": False, "is_lig": False, "annual_income": 500000}
        },
    )
    response = await client.post(
        "/api/v1/recommendations/me",
        headers=auth_headers(session),
        json={"query": QUERY, "limit": 20},
    )
    match = _find(response.json()["recommendations"], REAL_SCHEME_ID)
    assert match is not None  # still present
    assert match["eligibility_state"] == "fail"  # just correctly marked


# ---------------------------------------------------------------------------
# Cross-user isolation
# ---------------------------------------------------------------------------


async def test_two_users_get_recommendations_from_their_own_profiles(
    client: AsyncClient,
) -> None:
    alice = await register(client, "alice.reco@example.com")
    bob = await register(client, "bob.reco@example.com")

    await client.put(
        "/api/v1/me/profile",
        headers=auth_headers(alice),
        json={"attributes": {"is_divyang": True}},
    )
    await client.put(
        "/api/v1/me/profile",
        headers=auth_headers(bob),
        json={
            "attributes": {"is_divyang": False, "is_lig": False, "annual_income": 900000}
        },
    )

    alice_response = (
        await client.post(
            "/api/v1/recommendations/me",
            headers=auth_headers(alice),
            json={"query": QUERY, "limit": 20},
        )
    ).json()
    bob_response = (
        await client.post(
            "/api/v1/recommendations/me",
            headers=auth_headers(bob),
            json={"query": QUERY, "limit": 20},
        )
    ).json()

    assert (
        _find(alice_response["recommendations"], REAL_SCHEME_ID)["eligibility_state"]
        == "pass"
    )
    assert (
        _find(bob_response["recommendations"], REAL_SCHEME_ID)["eligibility_state"]
        == "fail"
    )


# ---------------------------------------------------------------------------
# Signed-out behaviour -- the existing public endpoint is unaffected
# ---------------------------------------------------------------------------


async def test_public_recommendations_endpoint_still_works_without_auth(
    client: AsyncClient,
) -> None:
    response = await client.post(
        "/api/v1/recommendations",
        json={"query": QUERY, "profile": {"is_divyang": True}, "limit": 20},
    )
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["profile_provided"] is True
    match = _find(body["recommendations"], REAL_SCHEME_ID)
    assert match is not None
    assert match["eligibility_state"] == "pass"


async def test_public_endpoint_with_no_profile_behaves_as_before(
    client: AsyncClient,
) -> None:
    response = await client.post(
        "/api/v1/recommendations", json={"query": QUERY, "limit": 20}
    )
    assert response.status_code == 200
    body = response.json()
    assert body["profile_provided"] is False
    match = _find(body["recommendations"], REAL_SCHEME_ID)
    assert match is not None
    assert match["eligibility_state"] == "unknown"


async def test_public_and_authenticated_endpoints_return_the_same_candidate_set(
    client: AsyncClient,
) -> None:
    """Confirms the authenticated path adds a profile source, not a second
    ranking/retrieval implementation -- the same schemes come back either
    way, only eligibility_state differs with the profile.
    """
    session = await register(client, "same.candidates@example.com")
    public_ids = {
        r["scheme_id"]
        for r in (
            await client.post(
                "/api/v1/recommendations", json={"query": QUERY, "limit": 20}
            )
        ).json()["recommendations"]
    }
    mine_ids = {
        r["scheme_id"]
        for r in (
            await client.post(
                "/api/v1/recommendations/me",
                headers=auth_headers(session),
                json={"query": QUERY, "limit": 20},
            )
        ).json()["recommendations"]
    }
    assert public_ids == mine_ids
