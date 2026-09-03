"""API rate limiting.

Per-endpoint limits via slowapi (github.com/laurentS/slowapi), keyed by
client IP address. The actual `@limiter.limit(...)` call sites live on
each router (api/v1/routers/*.py); the `RateLimitExceeded` -> this app's
own `{"error": {...}}` envelope translation lives in core/errors.py,
alongside every other exception handler.

The assistant endpoint gets the strictest limit, deliberately: a single
burst of requests can exhaust Gemini's entire daily free-tier quota (20
requests/day) in seconds, so that one limit protects an external, metered,
shared dependency -- not just this app's own database, the way the other
limits do.

This limit alone only bounds *burst rate*, not daily volume -- 5/minute
sustained is still up to 7,200 requests/day from one client, far past a
~20/day free tier. core/assistant_guard.py's DailyUsageCounter closes that
gap with a separate, configurable, process-wide daily cap; both apply
together on the assistant route (see api/v1/routers/assistant.py).
"""

from __future__ import annotations

from slowapi import Limiter
from slowapi.util import get_remote_address

# In-memory storage (the slowapi/limits default, since no `storage_uri` is
# given) resets on every redeploy and does not coordinate across multiple
# instances -- correct for exactly the single-instance deployment this app
# runs today (see the deployment blueprint's rate-limiting section). The
# moment a second instance is added, pass storage_uri="redis://..." here;
# every call site below is unaffected.
limiter = Limiter(key_func=get_remote_address)

# Documented limits -- keep this comment in sync with the @limiter.limit(...)
# call on each route; a mismatch here is a stale comment, not a bug, but
# it's the one place meant to answer "what are the limits?" without reading
# five files.
#
#   POST /api/v1/assistant/message   5/minute   -- protects Gemini's quota
#   POST /api/v1/recommendations     20/minute  -- DB-only, still bounded
#   GET  /api/v1/search               30/minute  -- DB-only, cheapest call
#   GET  /api/v1/schemes/{identifier} 30/minute
#   POST /api/v1/auth/register        5/minute   -- bounds account-creation abuse
#   POST /api/v1/auth/login           10/minute  -- bounds password-guessing
#   POST /api/v1/auth/refresh         20/minute  -- routine, but still bounded
#   POST /api/v1/schemes/{id}/comments 10/minute -- bounds public-comment spam
ASSISTANT_LIMIT = "5/minute"
RECOMMENDATIONS_LIMIT = "20/minute"
SEARCH_LIMIT = "30/minute"
SCHEME_DETAIL_LIMIT = "30/minute"
AUTH_REGISTER_LIMIT = "5/minute"
AUTH_LOGIN_LIMIT = "10/minute"
AUTH_REFRESH_LIMIT = "20/minute"
COMMENT_CREATE_LIMIT = "10/minute"
