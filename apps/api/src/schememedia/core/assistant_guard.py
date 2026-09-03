"""Assistant usage/cost guardrails: daily volume cap, kill switch, response cache.

Three mechanisms, deliberately separate from core/rate_limit.py's per-IP
per-minute limiter rather than folded into it:

  * DailyUsageCounter -- a process-wide daily budget, independent of who is
    asking. The per-minute limiter caps *burst rate*; it does nothing to stop
    a client staying just under that rate for a full day. rate_limit.py's own
    docstring already flags this: 5/minute sustained is up to 7,200/day
    against a free tier of roughly 20/day. This closes that gap.
  * TTLCache -- a short-lived cache of complete responses, keyed on the exact
    (stripped) request message. An identical repeat question costs nothing
    against the daily budget or the LLM provider.
  * The kill switch itself (Settings.assistant_enabled) is not modelled here
    at all -- it is read directly off Settings in the route, since it is a
    single static flag for the process's lifetime, not something with state
    to own.

Both stateful pieces are constructed once per FastAPI app (app.state.
assistant_guard, see main.py) rather than as module-level globals: unlike
`limiter` in core/rate_limit.py (a true process-wide singleton slowapi
requires), nothing here needs to be shared across app instances, and keeping
it per-app makes every instance -- including each test's own -- start from a
clean, independently configured counter and cache with no `.reset()` call
required between tests.

Both classes take an injectable clock so tests can deterministically cross a
UTC midnight or expire a cache entry without a real sleep.
"""

from __future__ import annotations

import threading
import time
from collections.abc import Callable
from dataclasses import dataclass, field
from datetime import UTC, date, datetime
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from schememedia.core.config import Settings


def _utcnow() -> datetime:
    return datetime.now(UTC)


class DailyUsageCounter:
    """Thread-safe count of assistant calls since the last UTC midnight.

    UTC, not local time or "since app start": a fixed, unambiguous reset
    point that does not depend on server timezone configuration and cannot
    be reset early by a redeploy (see `count`/`try_increment`, both of which
    recompute "is this still today" from the clock on every call rather than
    relying on a background timer).
    """

    def __init__(self, limit: int, *, clock: Callable[[], datetime] = _utcnow) -> None:
        self.limit = limit
        self._clock = clock
        self._lock = threading.Lock()
        self._day: date | None = None
        self._count = 0

    def _reset_if_new_day(self) -> None:
        today = self._clock().date()
        if today != self._day:
            self._day = today
            self._count = 0

    def try_increment(self) -> tuple[bool, int]:
        """Atomically check the cap and reserve one call if under it.

        Returns `(allowed, count_after_this_attempt)`. Reserving *before* the
        provider is called (rather than incrementing only on success) is
        deliberate: the whole point is that nothing calls the provider once
        the cap is hit, so the check has to happen first, and a call that was
        attempted but failed still consumed real quota against the provider
        -- it is not refunded here.
        """
        with self._lock:
            self._reset_if_new_day()
            if self._count >= self.limit:
                return False, self._count
            self._count += 1
            return True, self._count

    @property
    def count(self) -> int:
        with self._lock:
            self._reset_if_new_day()
            return self._count


class TTLCache:
    """A tiny thread-safe in-memory cache with a fixed TTL per entry.

    `ttl_seconds <= 0` disables caching entirely (every `set` is a no-op) --
    lets the cache be turned off via configuration without a separate
    boolean flag to keep in sync.
    """

    def __init__(
        self, ttl_seconds: float, *, clock: Callable[[], float] = time.monotonic
    ) -> None:
        self.ttl_seconds = ttl_seconds
        self._clock = clock
        self._lock = threading.Lock()
        self._store: dict[str, tuple[float, Any]] = {}

    def get(self, key: str) -> Any | None:
        with self._lock:
            entry = self._store.get(key)
            if entry is None:
                return None
            expires_at, value = entry
            if self._clock() >= expires_at:
                del self._store[key]
                return None
            return value

    def set(self, key: str, value: Any) -> None:
        if self.ttl_seconds <= 0:
            return
        with self._lock:
            self._store[key] = (self._clock() + self.ttl_seconds, value)

    def clear(self) -> None:
        with self._lock:
            self._store.clear()


@dataclass
class AssistantGuard:
    """Bundles the two stateful Phase-1 safeguards behind one app.state entry.

    The kill switch is intentionally not a field here -- see module
    docstring -- routes read `settings.assistant_enabled` directly.
    """

    daily_counter: DailyUsageCounter
    cache: TTLCache
    # Kept for logging/observability call sites that want the configured
    # cap without reaching back into Settings.
    daily_limit: int = field(init=False)

    def __post_init__(self) -> None:
        self.daily_limit = self.daily_counter.limit

    @classmethod
    def from_settings(cls, settings: Settings) -> AssistantGuard:
        return cls(
            daily_counter=DailyUsageCounter(settings.assistant_daily_limit),
            cache=TTLCache(settings.assistant_cache_ttl_seconds),
        )
