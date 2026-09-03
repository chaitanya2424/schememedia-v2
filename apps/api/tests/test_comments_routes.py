"""HTTP-level tests for GET/POST /api/v1/schemes/{scheme_id}/comments and
DELETE /api/v1/schemes/{scheme_id}/comments/{comment_id}.

Top-level comments only -- see repositories/comments.py's module docstring.
Listing is public; creating and deleting require auth, and deleting is
scoped to the caller's own comment (test_bob_cannot_delete_alices_comment).
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


async def test_comment_list_is_public(client: AsyncClient) -> None:
    response = await client.get(f"/api/v1/schemes/{REAL_SCHEME_ID}/comments")
    assert response.status_code == 200
    assert response.json() == {"comments": [], "total_count": 0}


async def test_create_comment_requires_authentication(client: AsyncClient) -> None:
    response = await client.post(
        f"/api/v1/schemes/{REAL_SCHEME_ID}/comments", json={"content": "Hello"}
    )
    assert response.status_code == 401


async def test_commenting_on_an_unknown_scheme_id_is_rejected(
    client: AsyncClient,
) -> None:
    session = await register(client, "comment.unknown@example.com")
    response = await client.post(
        "/api/v1/schemes/SCH_DOES_NOT_EXIST/comments",
        json={"content": "Hello"},
        headers=auth_headers(session),
    )
    assert response.status_code == 404
    assert response.json()["error"]["code"] == "not_found"


async def test_empty_comment_is_rejected(client: AsyncClient) -> None:
    session = await register(client, "empty.comment@example.com")
    response = await client.post(
        f"/api/v1/schemes/{REAL_SCHEME_ID}/comments",
        json={"content": ""},
        headers=auth_headers(session),
    )
    assert response.status_code == 422


async def test_posting_a_comment_appears_in_the_list(client: AsyncClient) -> None:
    session = await register(client, "commenter@example.com", full_name="Priya Sharma")
    create = await client.post(
        f"/api/v1/schemes/{REAL_SCHEME_ID}/comments",
        json={"content": "Does this cover part-time farmers too?"},
        headers=auth_headers(session),
    )
    assert create.status_code == 201
    body = create.json()
    assert body["content"] == "Does this cover part-time farmers too?"
    assert body["author_name"] == "Priya Sharma"
    assert body["edited"] is False
    assert body["created_at"]

    listing = (await client.get(f"/api/v1/schemes/{REAL_SCHEME_ID}/comments")).json()
    assert listing["total_count"] == 1
    assert listing["comments"][0]["id"] == body["id"]


async def test_comment_increments_comment_count(client: AsyncClient) -> None:
    session = await register(client, "count.check@example.com")
    before = (await client.get(f"/api/v1/schemes/{REAL_SCHEME_ID}")).json()
    await client.post(
        f"/api/v1/schemes/{REAL_SCHEME_ID}/comments",
        json={"content": "Real comment content."},
        headers=auth_headers(session),
    )
    after = (await client.get(f"/api/v1/schemes/{REAL_SCHEME_ID}")).json()
    assert after["comment_count"] == before["comment_count"] + 1


async def test_comments_are_newest_first(client: AsyncClient) -> None:
    session = await register(client, "order.comments@example.com")
    await client.post(
        f"/api/v1/schemes/{REAL_SCHEME_ID}/comments",
        json={"content": "First comment."},
        headers=auth_headers(session),
    )
    await client.post(
        f"/api/v1/schemes/{REAL_SCHEME_ID}/comments",
        json={"content": "Second comment."},
        headers=auth_headers(session),
    )
    listing = (await client.get(f"/api/v1/schemes/{REAL_SCHEME_ID}/comments")).json()
    assert listing["comments"][0]["content"] == "Second comment."
    assert listing["comments"][1]["content"] == "First comment."


async def test_deleting_own_comment_removes_it_from_the_list(
    client: AsyncClient,
) -> None:
    session = await register(client, "delete.own@example.com")
    create = await client.post(
        f"/api/v1/schemes/{REAL_SCHEME_ID}/comments",
        json={"content": "Delete me."},
        headers=auth_headers(session),
    )
    comment_id = create.json()["id"]

    delete = await client.delete(
        f"/api/v1/schemes/{REAL_SCHEME_ID}/comments/{comment_id}",
        headers=auth_headers(session),
    )
    assert delete.status_code == 204

    listing = (await client.get(f"/api/v1/schemes/{REAL_SCHEME_ID}/comments")).json()
    assert listing["total_count"] == 0


async def test_deleting_decrements_comment_count(client: AsyncClient) -> None:
    session = await register(client, "delete.count@example.com")
    create = await client.post(
        f"/api/v1/schemes/{REAL_SCHEME_ID}/comments",
        json={"content": "Delete me too."},
        headers=auth_headers(session),
    )
    comment_id = create.json()["id"]
    before = (await client.get(f"/api/v1/schemes/{REAL_SCHEME_ID}")).json()

    await client.delete(
        f"/api/v1/schemes/{REAL_SCHEME_ID}/comments/{comment_id}",
        headers=auth_headers(session),
    )

    after = (await client.get(f"/api/v1/schemes/{REAL_SCHEME_ID}")).json()
    assert after["comment_count"] == before["comment_count"] - 1


async def test_delete_requires_authentication(client: AsyncClient) -> None:
    response = await client.delete(
        f"/api/v1/schemes/{REAL_SCHEME_ID}/comments/00000000-0000-0000-0000-000000000000"
    )
    assert response.status_code == 401


async def test_deleting_an_unknown_comment_id_is_not_found(client: AsyncClient) -> None:
    session = await register(client, "delete.unknown@example.com")
    response = await client.delete(
        f"/api/v1/schemes/{REAL_SCHEME_ID}/comments/00000000-0000-0000-0000-000000000000",
        headers=auth_headers(session),
    )
    assert response.status_code == 404


async def test_deleting_a_malformed_comment_id_is_not_found(client: AsyncClient) -> None:
    session = await register(client, "delete.malformed@example.com")
    response = await client.delete(
        f"/api/v1/schemes/{REAL_SCHEME_ID}/comments/not-a-uuid",
        headers=auth_headers(session),
    )
    assert response.status_code == 404


# ---------------------------------------------------------------------------
# viewer_is_author
# ---------------------------------------------------------------------------


async def test_viewer_is_author_is_false_for_a_signed_out_reader(
    client: AsyncClient,
) -> None:
    session = await register(client, "author.check.poster@example.com")
    await client.post(
        f"/api/v1/schemes/{REAL_SCHEME_ID}/comments",
        json={"content": "Posted while signed in."},
        headers=auth_headers(session),
    )
    listing = (await client.get(f"/api/v1/schemes/{REAL_SCHEME_ID}/comments")).json()
    assert listing["comments"][0]["viewer_is_author"] is False


async def test_viewer_is_author_is_true_for_the_poster_false_for_others(
    client: AsyncClient,
) -> None:
    alice = await register(client, "alice.author@example.com")
    bob = await register(client, "bob.author@example.com")
    await client.post(
        f"/api/v1/schemes/{REAL_SCHEME_ID}/comments",
        json={"content": "Alice wrote this."},
        headers=auth_headers(alice),
    )

    alice_view = (
        await client.get(
            f"/api/v1/schemes/{REAL_SCHEME_ID}/comments", headers=auth_headers(alice)
        )
    ).json()
    bob_view = (
        await client.get(
            f"/api/v1/schemes/{REAL_SCHEME_ID}/comments", headers=auth_headers(bob)
        )
    ).json()

    assert alice_view["comments"][0]["viewer_is_author"] is True
    assert bob_view["comments"][0]["viewer_is_author"] is False


# ---------------------------------------------------------------------------
# Cross-user isolation
# ---------------------------------------------------------------------------


async def test_bob_cannot_delete_alices_comment(client: AsyncClient) -> None:
    alice = await register(client, "alice.comments@example.com")
    bob = await register(client, "bob.comments@example.com")

    create = await client.post(
        f"/api/v1/schemes/{REAL_SCHEME_ID}/comments",
        json={"content": "Alice's comment."},
        headers=auth_headers(alice),
    )
    comment_id = create.json()["id"]

    forbidden = await client.delete(
        f"/api/v1/schemes/{REAL_SCHEME_ID}/comments/{comment_id}",
        headers=auth_headers(bob),
    )
    assert forbidden.status_code == 403
    assert forbidden.json()["error"]["code"] == "permission_denied"

    listing = (await client.get(f"/api/v1/schemes/{REAL_SCHEME_ID}/comments")).json()
    assert listing["total_count"] == 1  # untouched by Bob's request
