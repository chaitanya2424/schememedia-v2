"""HTTP middleware."""

from __future__ import annotations

import json
import time
import uuid

from starlette.datastructures import Headers
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import Response
from starlette.types import ASGIApp, Message, Receive, Scope, Send

from schememedia.core.logging import get_logger, request_id_ctx

logger = get_logger(__name__)

REQUEST_ID_HEADER = "X-Request-ID"


class RequestContextMiddleware(BaseHTTPMiddleware):
    """Assign a request ID, bind it to the log context, emit an access log.

    An inbound X-Request-ID is honoured so a trace can span the frontend and
    the API; otherwise one is generated. It is always echoed back, giving a
    user-reported error a single searchable identifier.
    """

    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        request_id = request.headers.get(REQUEST_ID_HEADER) or uuid.uuid4().hex
        token = request_id_ctx.set(request_id)
        started = time.perf_counter()

        try:
            response = await call_next(request)
        except Exception:
            # Logged in full by the unhandled-exception handler; recorded here
            # with timing so failures still appear in the access log.
            logger.warning(
                "request_failed",
                method=request.method,
                path=request.url.path,
                duration_ms=round((time.perf_counter() - started) * 1000, 2),
            )
            raise
        finally:
            request_id_ctx.reset(token)

        duration_ms = round((time.perf_counter() - started) * 1000, 2)
        response.headers[REQUEST_ID_HEADER] = request_id

        # Health probes would otherwise dominate the log volume.
        if request.url.path not in ("/health", "/ready"):
            logger.info(
                "request_completed",
                method=request.method,
                path=request.url.path,
                status_code=response.status_code,
                duration_ms=duration_ms,
            )

        return response


class _BodyTooLargeError(Exception):
    """Raised inside `limited_receive` below, never outside this module --
    it exists purely to unwind the app's own body-reading loop early,
    matching how starlette.middleware.body_limit's own (private) equivalent
    works internally.
    """


class MaxBodySizeMiddleware:
    """Rejects a request whose body exceeds `max_body_size`, in this app's
    own error envelope.

    Starlette ships an equivalent (`starlette.middleware.body_limit.
    RequestBodyLimitMiddleware`, available via FastAPI/Starlette but not
    exposed as a constructor kwarg on this installed FastAPI version) --
    verified directly against the installed package, not assumed. It was
    not reused here because it constructs and sends a bare
    `PlainTextResponse` itself, entirely outside this app's registered
    exception handlers, which breaks the "every error response has the
    same JSON shape" guarantee core/errors.py exists to keep. This mirrors
    its actual mechanism -- a Content-Length fast path, plus a streaming
    byte-count for a body that omits it (chunked transfer-encoding) -- but
    replies through the same envelope as every other error in this app.

    A raw ASGI middleware, not `BaseHTTPMiddleware`: the latter has to read
    the entire body into memory before your code sees it, which defeats
    the point of rejecting an oversized one early.
    """

    def __init__(self, app: ASGIApp, max_body_size: int) -> None:
        self.app = app
        self.max_body_size = max_body_size

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        headers = Headers(scope=scope)
        content_length = headers.get("content-length")
        if (
            content_length is not None
            and content_length.isdigit()
            and int(content_length) > self.max_body_size
        ):
            await self._reject(send)
            return

        total = 0
        response_started = False

        async def limited_receive() -> Message:
            nonlocal total
            message = await receive()
            if message["type"] == "http.request":
                total += len(message.get("body", b""))
                if total > self.max_body_size:
                    raise _BodyTooLargeError
            return message

        async def guarded_send(message: Message) -> None:
            nonlocal response_started
            if message["type"] == "http.response.start":
                response_started = True
            await send(message)

        try:
            await self.app(scope, limited_receive, guarded_send)
        except _BodyTooLargeError:
            if response_started:
                # The app had already started streaming a response by the
                # time the body limit was hit -- too late to send a
                # different one instead, so let it surface as a real error
                # rather than silently sending two responses.
                raise
            await self._reject(send)

    async def _reject(self, send: Send) -> None:
        logger.info("request_body_too_large", max_body_size=self.max_body_size)
        error: dict[str, object] = {
            "code": "request_too_large",
            "message": f"Request body exceeds the {self.max_body_size}-byte limit.",
        }
        # Matches core/errors.py's _envelope() exactly (same request_id_ctx
        # source) without importing a "private" (leading-underscore) helper
        # across modules -- this is the one other place in the app that
        # builds an error envelope by hand, and it stays this small.
        request_id = request_id_ctx.get()
        if request_id:
            error["request_id"] = request_id
        body = json.dumps({"error": error}).encode("utf-8")
        await send(
            {
                "type": "http.response.start",
                "status": 413,
                "headers": [(b"content-type", b"application/json")],
            }
        )
        await send({"type": "http.response.body", "body": body})
