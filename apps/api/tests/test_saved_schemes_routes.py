"""HTTP-level tests for GET/POST/DELETE /api/v1/me/saved-schemes.

Built on SchemeSave's composite primary key (db/models/interaction.py) --
duplicate-save prevention is a database guarantee here, not just an
application-level check, so the test for it is really proving the API
surfaces that guarantee cleanly rather than erroring on the second call.
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

REAL_SCHEME_ID = "SCH_08134B86"  # the small fixture's first record
ANOTHER_REAL_SCHEME_ID = "SCH_53E1A21D"


async def test_saved_schemes_list_requires_authentication(client: AsyncClient) -> None:
    response = await client.get("/api/v1/me/saved-schemes")
    assert response.status_code == 401


async def test_save_requires_authentication(client: AsyncClient) -> None:
    response = await client.post(f"/api/v1/me/saved-schemes/{REAL_SCHEME_ID}")
    assert response.status_code == 401


async def test_a_new_users_saved_list_is_empty(client: AsyncClient) -> None:
    session = await register(client, "empty.saves@example.com")
    response = await client.get("/api/v1/me/saved-schemes", headers=auth_headers(session))
    assert response.status_code == 200
    body = response.json()
    assert body["schemes"] == []
    assert body["total_count"] == 0


async def test_saving_an_unknown_scheme_id_is_rejected(client: AsyncClient) -> None:
    session = await register(client, "save.unknown@example.com")
    response = await client.post(
        "/api/v1/me/saved-schemes/SCH_DOES_NOT_EXIST", headers=auth_headers(session)
    )
    assert response.status_code == 404
    assert response.json()["error"]["code"] == "not_found"


async def test_saving_a_real_scheme_succeeds_and_appears_in_the_list(
    client: AsyncClient,
) -> None:
    session = await register(client, "save.real@example.com")
    save = await client.post(
        f"/api/v1/me/saved-schemes/{REAL_SCHEME_ID}", headers=auth_headers(session)
    )
    assert save.status_code == 204

    listing = (
        await client.get("/api/v1/me/saved-schemes", headers=auth_headers(session))
    ).json()
    assert listing["total_count"] == 1
    assert listing["schemes"][0]["scheme_id"] == REAL_SCHEME_ID


async def test_saved_scheme_preserves_verification_and_provenance_fields(
    client: AsyncClient,
) -> None:
    session = await register(client, "provenance.check@example.com")
    await client.post(
        f"/api/v1/me/saved-schemes/{REAL_SCHEME_ID}", headers=auth_headers(session)
    )
    listing = (
        await client.get("/api/v1/me/saved-schemes", headers=auth_headers(session))
    ).json()
    row = listing["schemes"][0]
    # Every field a search/recommendation result also carries -- the
    # importer always writes "unverified" and needs_review is data-derived,
    # so these are the real, deterministic values for this fixture record.
    assert row["verification_status"] == "unverified"
    assert "needs_review" in row
    assert row["jurisdiction"] == "state"
    assert row["state_code"] == "KL"
    assert row.get("saved_at")


async def test_saving_the_same_scheme_twice_does_not_duplicate(
    client: AsyncClient,
) -> None:
    session = await register(client, "dedup.save@example.com")
    first = await client.post(
        f"/api/v1/me/saved-schemes/{REAL_SCHEME_ID}", headers=auth_headers(session)
    )
    second = await client.post(
        f"/api/v1/me/saved-schemes/{REAL_SCHEME_ID}", headers=auth_headers(session)
    )
    assert first.status_code == 204
    assert second.status_code == 204  # idempotent, not an error

    listing = (
        await client.get("/api/v1/me/saved-schemes", headers=auth_headers(session))
    ).json()
    assert listing["total_count"] == 1


async def test_saving_two_different_schemes_gives_two_entries(
    client: AsyncClient,
) -> None:
    session = await register(client, "two.saves@example.com")
    await client.post(
        f"/api/v1/me/saved-schemes/{REAL_SCHEME_ID}", headers=auth_headers(session)
    )
    await client.post(
        f"/api/v1/me/saved-schemes/{ANOTHER_REAL_SCHEME_ID}",
        headers=auth_headers(session),
    )
    listing = (
        await client.get("/api/v1/me/saved-schemes", headers=auth_headers(session))
    ).json()
    assert listing["total_count"] == 2
    saved_ids = {s["scheme_id"] for s in listing["schemes"]}
    assert saved_ids == {REAL_SCHEME_ID, ANOTHER_REAL_SCHEME_ID}


async def test_saved_list_is_newest_first(client: AsyncClient) -> None:
    session = await register(client, "order.saves@example.com")
    await client.post(
        f"/api/v1/me/saved-schemes/{REAL_SCHEME_ID}", headers=auth_headers(session)
    )
    await client.post(
        f"/api/v1/me/saved-schemes/{ANOTHER_REAL_SCHEME_ID}",
        headers=auth_headers(session),
    )
    listing = (
        await client.get("/api/v1/me/saved-schemes", headers=auth_headers(session))
    ).json()
    assert listing["schemes"][0]["scheme_id"] == ANOTHER_REAL_SCHEME_ID  # saved last


async def test_unsaving_removes_it_from_the_list(client: AsyncClient) -> None:
    session = await register(client, "unsave.ok@example.com")
    await client.post(
        f"/api/v1/me/saved-schemes/{REAL_SCHEME_ID}", headers=auth_headers(session)
    )
    unsave = await client.delete(
        f"/api/v1/me/saved-schemes/{REAL_SCHEME_ID}", headers=auth_headers(session)
    )
    assert unsave.status_code == 204

    listing = (
        await client.get("/api/v1/me/saved-schemes", headers=auth_headers(session))
    ).json()
    assert listing["total_count"] == 0


async def test_unsaving_something_never_saved_does_not_error(client: AsyncClient) -> None:
    session = await register(client, "unsave.never.saved@example.com")
    response = await client.delete(
        f"/api/v1/me/saved-schemes/{REAL_SCHEME_ID}", headers=auth_headers(session)
    )
    assert response.status_code == 204


async def test_unsave_requires_authentication(client: AsyncClient) -> None:
    response = await client.delete(f"/api/v1/me/saved-schemes/{REAL_SCHEME_ID}")
    assert response.status_code == 401


# ---------------------------------------------------------------------------
# Cross-user isolation
# ---------------------------------------------------------------------------


async def test_two_users_saved_lists_are_independent(client: AsyncClient) -> None:
    alice = await register(client, "alice.saves@example.com")
    bob = await register(client, "bob.saves@example.com")

    await client.post(
        f"/api/v1/me/saved-schemes/{REAL_SCHEME_ID}", headers=auth_headers(alice)
    )
    await client.post(
        f"/api/v1/me/saved-schemes/{ANOTHER_REAL_SCHEME_ID}", headers=auth_headers(bob)
    )

    alice_list = (
        await client.get("/api/v1/me/saved-schemes", headers=auth_headers(alice))
    ).json()
    bob_list = (
        await client.get("/api/v1/me/saved-schemes", headers=auth_headers(bob))
    ).json()

    assert {s["scheme_id"] for s in alice_list["schemes"]} == {REAL_SCHEME_ID}
    assert {s["scheme_id"] for s in bob_list["schemes"]} == {ANOTHER_REAL_SCHEME_ID}


async def test_bob_cannot_unsave_alices_scheme(client: AsyncClient) -> None:
    """Bob's DELETE only ever targets rows keyed by his own user id (see
    core/deps.py:get_current_user_id) -- there is no scheme_save id in the
    URL a caller could target on someone else's behalf.
    """
    alice = await register(client, "alice.protected@example.com")
    bob = await register(client, "bob.protected@example.com")
    await client.post(
        f"/api/v1/me/saved-schemes/{REAL_SCHEME_ID}", headers=auth_headers(alice)
    )

    await client.delete(
        f"/api/v1/me/saved-schemes/{REAL_SCHEME_ID}", headers=auth_headers(bob)
    )

    alice_list = (
        await client.get("/api/v1/me/saved-schemes", headers=auth_headers(alice))
    ).json()
    assert alice_list["total_count"] == 1  # untouched by Bob's request
