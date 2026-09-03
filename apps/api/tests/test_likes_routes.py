"""HTTP-level tests for POST/DELETE /api/v1/schemes/{scheme_id}/like, and the
viewer_has_liked field on GET /api/v1/schemes/{identifier}.

Built on SchemeLike's composite primary key (db/models/interaction.py) --
same shape and same guarantee as saved schemes (test_saved_schemes_routes.py).
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


async def test_like_requires_authentication(client: AsyncClient) -> None:
    response = await client.post(f"/api/v1/schemes/{REAL_SCHEME_ID}/like")
    assert response.status_code == 401


async def test_unlike_requires_authentication(client: AsyncClient) -> None:
    response = await client.delete(f"/api/v1/schemes/{REAL_SCHEME_ID}/like")
    assert response.status_code == 401


async def test_liking_an_unknown_scheme_id_is_rejected(client: AsyncClient) -> None:
    session = await register(client, "like.unknown@example.com")
    response = await client.post(
        "/api/v1/schemes/SCH_DOES_NOT_EXIST/like", headers=auth_headers(session)
    )
    assert response.status_code == 404
    assert response.json()["error"]["code"] == "not_found"


async def test_liking_a_real_scheme_increments_like_count(client: AsyncClient) -> None:
    session = await register(client, "like.real@example.com")
    before = (await client.get(f"/api/v1/schemes/{REAL_SCHEME_ID}")).json()
    like = await client.post(
        f"/api/v1/schemes/{REAL_SCHEME_ID}/like", headers=auth_headers(session)
    )
    assert like.status_code == 204

    after = (await client.get(f"/api/v1/schemes/{REAL_SCHEME_ID}")).json()
    assert after["like_count"] == before["like_count"] + 1


async def test_liking_the_same_scheme_twice_does_not_double_count(
    client: AsyncClient,
) -> None:
    session = await register(client, "dedup.like@example.com")
    before = (await client.get(f"/api/v1/schemes/{REAL_SCHEME_ID}")).json()
    await client.post(
        f"/api/v1/schemes/{REAL_SCHEME_ID}/like", headers=auth_headers(session)
    )
    second = await client.post(
        f"/api/v1/schemes/{REAL_SCHEME_ID}/like", headers=auth_headers(session)
    )
    assert second.status_code == 204  # idempotent, not an error

    after = (await client.get(f"/api/v1/schemes/{REAL_SCHEME_ID}")).json()
    assert after["like_count"] == before["like_count"] + 1


async def test_unliking_decrements_like_count(client: AsyncClient) -> None:
    session = await register(client, "unlike.ok@example.com")
    before = (await client.get(f"/api/v1/schemes/{REAL_SCHEME_ID}")).json()
    await client.post(
        f"/api/v1/schemes/{REAL_SCHEME_ID}/like", headers=auth_headers(session)
    )
    unlike = await client.delete(
        f"/api/v1/schemes/{REAL_SCHEME_ID}/like", headers=auth_headers(session)
    )
    assert unlike.status_code == 204

    after = (await client.get(f"/api/v1/schemes/{REAL_SCHEME_ID}")).json()
    assert after["like_count"] == before["like_count"]


async def test_unliking_something_never_liked_does_not_error(client: AsyncClient) -> None:
    session = await register(client, "unlike.never.liked@example.com")
    response = await client.delete(
        f"/api/v1/schemes/{REAL_SCHEME_ID}/like", headers=auth_headers(session)
    )
    assert response.status_code == 204


# ---------------------------------------------------------------------------
# viewer_has_liked on scheme detail
# ---------------------------------------------------------------------------


async def test_viewer_has_liked_is_null_when_signed_out(client: AsyncClient) -> None:
    detail = (await client.get(f"/api/v1/schemes/{REAL_SCHEME_ID}")).json()
    assert detail["viewer_has_liked"] is None


async def test_viewer_has_liked_is_false_before_liking(client: AsyncClient) -> None:
    session = await register(client, "not.liked.yet@example.com")
    detail = (
        await client.get(
            f"/api/v1/schemes/{REAL_SCHEME_ID}", headers=auth_headers(session)
        )
    ).json()
    assert detail["viewer_has_liked"] is False


async def test_viewer_has_liked_is_true_after_liking(client: AsyncClient) -> None:
    session = await register(client, "liked.now@example.com")
    await client.post(
        f"/api/v1/schemes/{REAL_SCHEME_ID}/like", headers=auth_headers(session)
    )
    detail = (
        await client.get(
            f"/api/v1/schemes/{REAL_SCHEME_ID}", headers=auth_headers(session)
        )
    ).json()
    assert detail["viewer_has_liked"] is True


# ---------------------------------------------------------------------------
# Cross-user isolation
# ---------------------------------------------------------------------------


async def test_two_users_likes_are_independent(client: AsyncClient) -> None:
    alice = await register(client, "alice.likes@example.com")
    bob = await register(client, "bob.likes@example.com")

    # like_count is a DB-trigger-maintained counter that TRUNCATE (this
    # fixture's per-test reset) doesn't fire a row-level trigger for, so it
    # isn't reset to 0 between tests -- compare against a fresh baseline
    # rather than an absolute value (see repositories/likes.py).
    before = (await client.get(f"/api/v1/schemes/{REAL_SCHEME_ID}")).json()
    await client.post(
        f"/api/v1/schemes/{REAL_SCHEME_ID}/like", headers=auth_headers(alice)
    )

    alice_detail = (
        await client.get(f"/api/v1/schemes/{REAL_SCHEME_ID}", headers=auth_headers(alice))
    ).json()
    bob_detail = (
        await client.get(f"/api/v1/schemes/{REAL_SCHEME_ID}", headers=auth_headers(bob))
    ).json()

    assert alice_detail["viewer_has_liked"] is True
    assert bob_detail["viewer_has_liked"] is False
    assert (
        alice_detail["like_count"] == bob_detail["like_count"] == before["like_count"] + 1
    )


async def test_bob_cannot_unlike_alices_like(client: AsyncClient) -> None:
    alice = await register(client, "alice.like.protected@example.com")
    bob = await register(client, "bob.like.protected@example.com")
    await client.post(
        f"/api/v1/schemes/{ANOTHER_REAL_SCHEME_ID}/like", headers=auth_headers(alice)
    )

    await client.delete(
        f"/api/v1/schemes/{ANOTHER_REAL_SCHEME_ID}/like", headers=auth_headers(bob)
    )

    alice_detail = (
        await client.get(
            f"/api/v1/schemes/{ANOTHER_REAL_SCHEME_ID}", headers=auth_headers(alice)
        )
    ).json()
    assert alice_detail["viewer_has_liked"] is True  # untouched by Bob's request
