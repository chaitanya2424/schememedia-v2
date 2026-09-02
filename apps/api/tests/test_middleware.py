"""App-level middleware behaviour that doesn't need a live database.

Audit finding M2: no response compression at all -- a 20-result
/recommendations response measured ~30KB uncompressed during frontend
testing. /openapi.json is used here as a DB-independent endpoint that is
comfortably over GZipMiddleware's 500-byte floor (this API documents
several routers' worth of schemas), so this doesn't need the real dataset
or a live database to prove compression is actually wired in.
"""

from __future__ import annotations

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_a_large_response_is_gzip_compressed_when_requested(
    client: AsyncClient,
) -> None:
    response = await client.get("/openapi.json", headers={"Accept-Encoding": "gzip"})
    assert response.status_code == 200
    assert response.headers.get("content-encoding") == "gzip"
    # httpx transparently decodes gzip for .content/.json() -- the
    # Content-Encoding header above is the only place the compression
    # itself is actually observable, but the body must still be the real,
    # correctly-decoded response underneath it.
    assert response.json()["info"]["title"] == "SchemeMedia API"


@pytest.mark.asyncio
async def test_a_small_response_still_decodes_correctly(client: AsyncClient) -> None:
    """/health's body (60 bytes) is well under GZipMiddleware's 500-byte
    `minimum_size` floor -- but that floor only takes effect when GZip sees
    the whole body in one un-chunked message, and RequestContextMiddleware
    (a BaseHTTPMiddleware, positioned outside GZip in the stack -- see
    main.py) re-streams everything that passes through it in a way that
    defeats that fast path, so small responses get gzip'd anyway. Harmless
    (a few bytes of frame overhead on a low-volume, infrequently-polled
    endpoint) and out of scope for the finding this middleware fixes (large
    search/recommendations payloads); documented here, not "fixed", since
    correctness -- not the exact byte count -- is what actually matters and
    is what this test verifies.
    """
    response = await client.get("/health", headers={"Accept-Encoding": "gzip"})
    assert response.status_code == 200
    assert response.json() == {
        "status": "ok",
        "app": "SchemeMedia API",
        "environment": "test",
    }


@pytest.mark.asyncio
async def test_a_large_response_is_uncompressed_without_accept_encoding(
    client: AsyncClient,
) -> None:
    """A client that never asked for gzip must never receive it -- GZipMiddleware
    is content-negotiated, not unconditional.
    """
    response = await client.get("/openapi.json", headers={"Accept-Encoding": "identity"})
    assert response.status_code == 200
    assert "content-encoding" not in response.headers
