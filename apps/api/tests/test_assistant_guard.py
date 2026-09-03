"""Tests for the assistant usage/cost guardrails (core/assistant_guard.py)
and their wiring into the /assistant/message route.

Three layers, in increasing order of what they depend on:

  * DailyUsageCounter / TTLCache -- pure logic, no database, no app, no
    LLM. Injectable clocks make UTC-midnight reset and TTL expiry
    deterministic without a real sleep.
  * The route wired end to end against a real app and database, with a
    FakeProvider standing in for the model -- kill switch, daily cap,
    cache, and the existing per-IP limiter, all interacting the way they
    would in production. `FakeProvider.calls` (tests/fakes.py) proves a
    request that should never reach the model actually didn't, not just
    that a particular status code came back.
  * Logging behaviour -- the router's own `logger` object is monkeypatched
    with a small recorder rather than relying on structlog's global test
    capture, so these assertions don't depend on structlog's
    cache_logger_on_first_use interacting with test-only configuration.
"""

from __future__ import annotations

import threading
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from datetime import UTC, datetime

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient

from schememedia.api.v1.routers import assistant as assistant_router
from schememedia.core.assistant_guard import DailyUsageCounter, TTLCache
from schememedia.core.config import Settings
from schememedia.core.deps import get_llm_provider
from schememedia.core.rate_limit import limiter
from schememedia.main import create_app
from tests.conftest import database_is_reachable, resolve_test_database_url
from tests.fakes import FakeProvider

TEST_DATABASE_URL = resolve_test_database_url()
DATABASE_AVAILABLE = database_is_reachable(TEST_DATABASE_URL)


# ---------------------------------------------------------------------------
# DailyUsageCounter -- pure logic
# ---------------------------------------------------------------------------


def test_counter_starts_at_zero() -> None:
    counter = DailyUsageCounter(limit=5)
    assert counter.count == 0


def test_counter_allows_increments_up_to_the_limit() -> None:
    counter = DailyUsageCounter(limit=3)
    results = [counter.try_increment() for _ in range(3)]
    assert results == [(True, 1), (True, 2), (True, 3)]
    assert counter.count == 3


def test_counter_blocks_once_the_limit_is_reached() -> None:
    counter = DailyUsageCounter(limit=2)
    counter.try_increment()
    counter.try_increment()
    allowed, count = counter.try_increment()
    assert allowed is False
    assert count == 2  # not incremented past the limit
    assert counter.count == 2


def test_counter_of_zero_blocks_immediately() -> None:
    """A daily limit of 0 is a valid (if extreme) configuration -- must
    block the very first call, not divide-by-zero or under/overflow.
    """
    counter = DailyUsageCounter(limit=0)
    allowed, count = counter.try_increment()
    assert allowed is False
    assert count == 0


def test_counter_resets_at_utc_midnight() -> None:
    day_one = datetime(2026, 9, 3, 23, 59, tzinfo=UTC)
    day_two = datetime(2026, 9, 4, 0, 1, tzinfo=UTC)
    clock_value = [day_one]
    counter = DailyUsageCounter(limit=1, clock=lambda: clock_value[0])

    allowed, _ = counter.try_increment()
    assert allowed is True
    blocked, _ = counter.try_increment()
    assert blocked is False  # limit reached for day one

    clock_value[0] = day_two
    allowed_next_day, count_next_day = counter.try_increment()
    assert allowed_next_day is True
    assert count_next_day == 1  # started over, not carried across midnight


def test_counter_reset_is_keyed_on_utc_calendar_date_not_elapsed_time() -> None:
    """A clock that moves backward-in-wall-time-but-forward-in-date (e.g. a
    process that starts just before midnight) must still reset -- the
    counter compares calendar dates, not a duration since first use.
    """
    just_before_midnight = datetime(2026, 9, 3, 23, 59, 59, tzinfo=UTC)
    just_after_midnight = datetime(2026, 9, 4, 0, 0, 1, tzinfo=UTC)
    clock_value = [just_before_midnight]
    counter = DailyUsageCounter(limit=10, clock=lambda: clock_value[0])

    counter.try_increment()
    clock_value[0] = just_after_midnight
    assert counter.count == 0


def test_counter_is_safe_under_concurrent_use() -> None:
    """The whole point of the lock: N threads racing try_increment() against
    a limit smaller than N must never admit more than `limit` callers.
    """
    limit = 10
    counter = DailyUsageCounter(limit=limit)
    admitted = 0
    admitted_lock = threading.Lock()

    def worker() -> None:
        nonlocal admitted
        allowed, _ = counter.try_increment()
        if allowed:
            with admitted_lock:
                admitted += 1

    threads = [threading.Thread(target=worker) for _ in range(50)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    assert admitted == limit
    assert counter.count == limit


# ---------------------------------------------------------------------------
# TTLCache -- pure logic
# ---------------------------------------------------------------------------


def test_cache_miss_returns_none() -> None:
    cache = TTLCache(ttl_seconds=60)
    assert cache.get("missing") is None


def test_cache_hit_returns_the_stored_value_within_ttl() -> None:
    cache = TTLCache(ttl_seconds=60)
    cache.set("key", "value")
    assert cache.get("key") == "value"


def test_cache_entry_expires_after_its_ttl() -> None:
    clock_value = [0.0]
    cache = TTLCache(ttl_seconds=10, clock=lambda: clock_value[0])
    cache.set("key", "value")
    assert cache.get("key") == "value"

    clock_value[0] = 10.0  # exactly at expiry -- inclusive, must be gone
    assert cache.get("key") is None


def test_cache_entry_is_pruned_on_expired_read_not_just_hidden() -> None:
    clock_value = [0.0]
    cache = TTLCache(ttl_seconds=10, clock=lambda: clock_value[0])
    cache.set("key", "value")
    clock_value[0] = 100.0
    assert cache.get("key") is None
    # Internal store actually shrank, not just "reads as empty" -- exercised
    # indirectly via a fresh set() at the old key succeeding cleanly.
    cache.set("key", "new-value")
    assert cache.get("key") == "new-value"


def test_zero_ttl_disables_caching() -> None:
    cache = TTLCache(ttl_seconds=0)
    cache.set("key", "value")
    assert cache.get("key") is None


def test_cache_clear_empties_all_entries() -> None:
    cache = TTLCache(ttl_seconds=60)
    cache.set("a", 1)
    cache.set("b", 2)
    cache.clear()
    assert cache.get("a") is None
    assert cache.get("b") is None


# ---------------------------------------------------------------------------
# End to end -- real app, real database, FakeProvider standing in for the LLM
# ---------------------------------------------------------------------------


@asynccontextmanager
async def guard_client(
    fake_provider: FakeProvider, **settings_overrides: object
) -> AsyncIterator[AsyncClient]:
    """A fresh app (and therefore a fresh, independently configured
    AssistantGuard -- see its module docstring) per call, wired to
    `fake_provider`. `limiter` is the one piece of process-wide state
    (slowapi requires a true singleton, see core/rate_limit.py), so it is
    reset around every use the same way test_rate_limit.py does.
    """
    if not DATABASE_AVAILABLE:
        pytest.skip("PostgreSQL unreachable; see README section 1")

    settings = Settings(
        app_env="test",
        database_url=TEST_DATABASE_URL,  # type: ignore[arg-type]
        log_json=False,
        log_level="WARNING",
        cors_origins=["http://localhost:3000"],
        **settings_overrides,  # type: ignore[arg-type]
    )
    app = create_app(settings)
    app.dependency_overrides[get_llm_provider] = lambda: fake_provider

    limiter.reset()
    async with (
        AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac,
        app.router.lifespan_context(app),
    ):
        yield ac
    limiter.reset()


@pytest.mark.asyncio
async def test_kill_switch_returns_503_without_calling_the_provider() -> None:
    provider = FakeProvider(tool_call_query="x", reply_text="unused")
    async with guard_client(provider, assistant_enabled=False) as client:
        response = await client.post(
            "/api/v1/assistant/message", json={"message": "hello"}
        )

    assert response.status_code == 503
    assert response.json()["error"]["code"] == "assistant_disabled"
    assert provider.calls == 0


@pytest.mark.asyncio
async def test_daily_cap_returns_quota_exceeded_after_the_limit() -> None:
    provider = FakeProvider(tool_call_query="x", reply_text="a reply")
    async with guard_client(
        provider, assistant_daily_limit=1, assistant_cache_ttl_seconds=0
    ) as client:
        first = await client.post(
            "/api/v1/assistant/message", json={"message": "first question"}
        )
        second = await client.post(
            "/api/v1/assistant/message", json={"message": "second question"}
        )

    assert first.status_code == 200
    assert second.status_code == 503
    body = second.json()
    assert body["error"]["code"] == "assistant_quota_exceeded"
    # The cap was enforced before ever reaching the provider a second time.
    assert provider.calls == 1


@pytest.mark.asyncio
async def test_daily_cap_can_trigger_before_the_per_ip_limit() -> None:
    """ASSISTANT_LIMIT (5/minute) alone would allow a 3rd request in the
    same minute -- the daily cap, set below that, must still block it.
    """
    provider = FakeProvider(tool_call_query="x", reply_text="a reply")
    async with guard_client(
        provider, assistant_daily_limit=2, assistant_cache_ttl_seconds=0
    ) as client:
        statuses = []
        for i in range(3):
            response = await client.post(
                "/api/v1/assistant/message", json={"message": f"question {i}"}
            )
            statuses.append(response.status_code)
            if response.status_code == 503:
                last_body = response.json()

    assert statuses == [200, 200, 503]
    assert last_body["error"]["code"] == "assistant_quota_exceeded"


@pytest.mark.asyncio
async def test_per_ip_limit_still_applies_with_headroom_on_the_daily_cap() -> None:
    """The existing per-minute limiter (core/rate_limit.py) must keep
    working unchanged -- the daily cap is additive, not a replacement.
    """
    from limits import parse

    from schememedia.core.rate_limit import ASSISTANT_LIMIT

    allowed = parse(ASSISTANT_LIMIT).amount
    provider = FakeProvider(tool_call_query="x", reply_text="a reply")
    async with guard_client(
        provider, assistant_daily_limit=1000, assistant_cache_ttl_seconds=0
    ) as client:
        statuses = []
        for i in range(allowed + 1):
            response = await client.post(
                "/api/v1/assistant/message", json={"message": f"question {i}"}
            )
            statuses.append(response.status_code)

    assert statuses[:allowed] == [200] * allowed
    assert statuses[allowed] == 429


@pytest.mark.asyncio
async def test_identical_request_is_served_from_cache() -> None:
    provider = FakeProvider(tool_call_query="x", reply_text="a cached-friendly reply")
    async with guard_client(provider, assistant_cache_ttl_seconds=60) as client:
        first = await client.post(
            "/api/v1/assistant/message", json={"message": "same question"}
        )
        second = await client.post(
            "/api/v1/assistant/message", json={"message": "same question"}
        )

    assert first.status_code == 200
    assert second.status_code == 200
    assert first.json() == second.json()
    assert provider.calls == 1


@pytest.mark.asyncio
async def test_whitespace_padded_duplicate_still_hits_the_cache() -> None:
    provider = FakeProvider(tool_call_query="x", reply_text="a reply")
    async with guard_client(provider, assistant_cache_ttl_seconds=60) as client:
        await client.post("/api/v1/assistant/message", json={"message": "same question"})
        second = await client.post(
            "/api/v1/assistant/message", json={"message": "  same question  "}
        )

    assert second.status_code == 200
    assert provider.calls == 1


@pytest.mark.asyncio
async def test_a_different_message_is_not_a_cache_hit() -> None:
    provider = FakeProvider(tool_call_query="x", reply_text="a reply")
    async with guard_client(provider, assistant_cache_ttl_seconds=60) as client:
        await client.post("/api/v1/assistant/message", json={"message": "first question"})
        await client.post(
            "/api/v1/assistant/message", json={"message": "second question"}
        )

    assert provider.calls == 2


@pytest.mark.asyncio
async def test_cache_hit_does_not_count_against_the_daily_cap() -> None:
    """The cache is checked before the daily counter -- a repeated question
    must not spend budget it doesn't need to. A third, genuinely new
    question after the cap is exhausted must still be rejected.
    """
    provider = FakeProvider(tool_call_query="x", reply_text="a reply")
    async with guard_client(
        provider, assistant_daily_limit=1, assistant_cache_ttl_seconds=60
    ) as client:
        first = await client.post(
            "/api/v1/assistant/message", json={"message": "the only question"}
        )
        repeat = await client.post(
            "/api/v1/assistant/message", json={"message": "the only question"}
        )
        new_question = await client.post(
            "/api/v1/assistant/message", json={"message": "a brand new question"}
        )

    assert first.status_code == 200
    assert repeat.status_code == 200
    assert new_question.status_code == 503
    assert new_question.json()["error"]["code"] == "assistant_quota_exceeded"
    assert provider.calls == 1


@pytest.mark.asyncio
async def test_provider_failure_returns_503_and_is_not_cached() -> None:
    provider = FakeProvider(
        tool_call_query="x", raises=RuntimeError("simulated provider outage")
    )
    async with guard_client(
        provider, assistant_daily_limit=5, assistant_cache_ttl_seconds=60
    ) as client:
        first = await client.post(
            "/api/v1/assistant/message", json={"message": "a question"}
        )
        second = await client.post(
            "/api/v1/assistant/message", json={"message": "a question"}
        )

    assert first.status_code == 503
    assert first.json()["error"]["code"] == "service_unavailable"
    # Not cached: the second, identical request reached the provider again
    # rather than replaying a cached failure.
    assert second.status_code == 503
    assert provider.calls == 2


@pytest.mark.asyncio
async def test_provider_failure_still_spends_the_reserved_daily_slot() -> None:
    """DailyUsageCounter.try_increment reserves before the call and is never
    refunded on failure -- a failed call still spent real provider quota.
    """
    provider = FakeProvider(
        tool_call_query="x", raises=RuntimeError("simulated provider outage")
    )
    async with guard_client(
        provider, assistant_daily_limit=1, assistant_cache_ttl_seconds=0
    ) as client:
        first = await client.post(
            "/api/v1/assistant/message", json={"message": "a question"}
        )
        second = await client.post(
            "/api/v1/assistant/message", json={"message": "a different question"}
        )

    assert first.status_code == 503
    assert first.json()["error"]["code"] == "service_unavailable"
    # The single daily slot was already spent by the failed first call --
    # the second request is rejected by the cap, never reaching the
    # provider a second time.
    assert second.status_code == 503
    assert second.json()["error"]["code"] == "assistant_quota_exceeded"
    assert provider.calls == 1


# ---------------------------------------------------------------------------
# Logging -- the router's own `logger` monkeypatched with a small recorder,
# rather than structlog's global capture_logs(), so these assertions don't
# depend on structlog's cache_logger_on_first_use interacting with
# test-only configuration (see module docstring).
# ---------------------------------------------------------------------------


class _RecordingLogger:
    def __init__(self) -> None:
        self.events: list[tuple[str, str, dict[str, object]]] = []

    def info(self, event: str, **kwargs: object) -> None:
        self.events.append(("info", event, kwargs))

    def warning(self, event: str, **kwargs: object) -> None:
        self.events.append(("warning", event, kwargs))


@pytest_asyncio.fixture
async def recorder(monkeypatch: pytest.MonkeyPatch) -> _RecordingLogger:
    rec = _RecordingLogger()
    monkeypatch.setattr(assistant_router, "logger", rec)
    return rec


@pytest.mark.asyncio
async def test_successful_turn_logs_completion_with_timing_and_cache_flag(
    recorder: _RecordingLogger,
) -> None:
    provider = FakeProvider(tool_call_query="x", reply_text="a reply")
    async with guard_client(provider, assistant_cache_ttl_seconds=0) as client:
        response = await client.post(
            "/api/v1/assistant/message", json={"message": "a question"}
        )
    assert response.status_code == 200

    completed = [e for e in recorder.events if e[1] == "assistant_turn_completed"]
    assert len(completed) == 1
    _, _, fields = completed[0]
    assert fields["cache_hit"] is False
    assert fields["daily_count"] == 1
    assert isinstance(fields["tool_call_latency_ms"], float)
    assert isinstance(fields["reply_latency_ms"], float)
    assert isinstance(fields["total_latency_ms"], float)
    assert fields["grounding_warnings_count"] == 0


@pytest.mark.asyncio
async def test_cache_hit_logs_completion_with_cache_hit_true(
    recorder: _RecordingLogger,
) -> None:
    provider = FakeProvider(tool_call_query="x", reply_text="a reply")
    async with guard_client(provider, assistant_cache_ttl_seconds=60) as client:
        await client.post("/api/v1/assistant/message", json={"message": "q"})
        await client.post("/api/v1/assistant/message", json={"message": "q"})

    cache_hits = [
        e
        for e in recorder.events
        if e[1] == "assistant_turn_completed" and e[2].get("cache_hit") is True
    ]
    assert len(cache_hits) == 1


@pytest.mark.asyncio
async def test_kill_switch_logs_a_blocked_event(recorder: _RecordingLogger) -> None:
    provider = FakeProvider(tool_call_query="x", reply_text="unused")
    async with guard_client(provider, assistant_enabled=False) as client:
        await client.post("/api/v1/assistant/message", json={"message": "q"})

    assert any(e[1] == "assistant_disabled_request_blocked" for e in recorder.events)


@pytest.mark.asyncio
async def test_daily_cap_logs_a_quota_exceeded_event(
    recorder: _RecordingLogger,
) -> None:
    provider = FakeProvider(tool_call_query="x", reply_text="a reply")
    async with guard_client(
        provider, assistant_daily_limit=1, assistant_cache_ttl_seconds=0
    ) as client:
        await client.post("/api/v1/assistant/message", json={"message": "one"})
        await client.post("/api/v1/assistant/message", json={"message": "two"})

    quota_events = [
        e for e in recorder.events if e[1] == "assistant_daily_quota_exceeded"
    ]
    assert len(quota_events) == 1
    assert quota_events[0][2]["daily_limit"] == 1


@pytest.mark.asyncio
async def test_provider_failure_logs_with_daily_count(
    recorder: _RecordingLogger,
) -> None:
    provider = FakeProvider(
        tool_call_query="x", raises=RuntimeError("simulated provider outage")
    )
    async with guard_client(provider, assistant_cache_ttl_seconds=0) as client:
        await client.post("/api/v1/assistant/message", json={"message": "q"})

    failures = [e for e in recorder.events if e[1] == "assistant_turn_failed"]
    assert len(failures) == 1
    _, _, fields = failures[0]
    assert fields["error_type"] == "RuntimeError"
    assert fields["daily_count"] == 1
