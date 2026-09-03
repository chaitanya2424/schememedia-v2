"""The grounded AI assistant, exposed over HTTP.

No `profile` field on the request: the whole point of services/assistant.py
is that the model extracts structured profile facts from the user's own
message (see FIND_SCHEMES_TOOL's schema) -- accepting a separate profile
parameter here would bypass that and invite two disagreeing sources of
truth about what the user said.

Provider-independent, same as the service it wraps: this route never
imports Anthropic or Gemini directly, only LLMProviderDep (core/deps.py),
which resolves to whichever LLM_PROVIDER is configured.

`evidence` is fully typed (EvidenceOut/EvidenceResultOut below), not passed
through as a raw dict: `execute_find_matching_schemes`'s return shape is
internal to services/assistant.py, and a public response field with no
schema is invisible in OpenAPI and free to change shape under callers
without warning. This is a deliberate mirror of that dict's keys, not a
reference to it -- see schemas/common.py's docstring on why the API layer
keeps its own copy of shapes like this rather than importing them.
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Body, Request
from fastapi.concurrency import run_in_threadpool
from pydantic import BaseModel, Field

from schememedia.api.v1.schemas.common import (
    EligibilityStateOut,
    JurisdictionOut,
    SchemeTypeOut,
    VerificationStatusOut,
)
from schememedia.core.deps import (
    AssistantGuardDep,
    LLMProviderDep,
    RecommendationServiceDep,
    SettingsDep,
)
from schememedia.core.errors import (
    AssistantDisabledError,
    AssistantQuotaExceededError,
    ServiceUnavailableError,
)
from schememedia.core.logging import get_logger
from schememedia.core.rate_limit import ASSISTANT_LIMIT, limiter
from schememedia.services.assistant import run_assistant_turn

logger = get_logger(__name__)

router = APIRouter(prefix="/assistant", tags=["assistant"])


class AssistantRequest(BaseModel):
    message: Annotated[str, Field(min_length=1, max_length=2000)]


class EvidenceResultOut(BaseModel):
    scheme_id: str
    name: str
    category: str | None
    jurisdiction: JurisdictionOut
    state_code: str | None
    scheme_type: SchemeTypeOut
    eligibility_state: EligibilityStateOut
    eligibility_explanations: list[str]
    missing_attributes: list[str] = Field(
        description="Attribute keys a follow-up question, if any, should ask about."
    )
    verification_status: VerificationStatusOut
    needs_review: bool
    official_url: str | None


class EvidenceOut(BaseModel):
    """Exactly what the model was shown -- present so a caller can verify
    the reply against the same facts, not just trust it.
    """

    query: str = Field(
        description="The search query the model extracted, not the raw message."
    )
    profile_provided: bool
    total_returned: int
    eligibility_breakdown: dict[str, int]
    results: list[EvidenceResultOut]


class AssistantResponseOut(BaseModel):
    reply: str
    evidence: EvidenceOut
    grounding_warnings: list[str] = Field(
        description=(
            "Mechanical checks against `evidence` -- fabricated URLs, "
            "unsupported verification claims, overclaimed certainty on "
            "unknown eligibility. Empty on a clean reply; see "
            "services/assistant.py's verify_grounded for exactly what this "
            "does and does not catch."
        )
    )


@router.post(
    "/message",
    response_model=AssistantResponseOut,
    operation_id="sendAssistantMessage",
    summary="Ask the grounded assistant a natural-language question",
    responses={
        429: {"description": f"Rate limited -- {ASSISTANT_LIMIT} per client."},
        503: {
            "description": (
                "The assistant did not run. `error.code` distinguishes why: "
                "`assistant_disabled` -- the operator has turned the "
                "assistant off (Settings.assistant_enabled); "
                "`assistant_quota_exceeded` -- today's configured daily "
                "call cap (Settings.assistant_daily_limit) has been "
                "reached, and the provider was never called; "
                "`service_unavailable` -- the configured LLM provider or a "
                "data dependency it needs failed for this request. Safe to "
                "retry later in every case; `assistant_quota_exceeded` "
                "resets at UTC midnight."
            )
        },
    },
)
@limiter.limit(ASSISTANT_LIMIT)
async def send_assistant_message(
    request: Request,  # required by @limiter.limit -- see its own docstring on why
    provider: LLMProviderDep,
    service: RecommendationServiceDep,
    settings: SettingsDep,
    guard: AssistantGuardDep,
    body: Annotated[AssistantRequest, Body()],
) -> AssistantResponseOut:
    # Kill switch first, before touching the cache or the daily counter --
    # a disabled assistant should short-circuit as cheaply as possible.
    if not settings.assistant_enabled:
        logger.info("assistant_disabled_request_blocked")
        raise AssistantDisabledError()

    # Cache before the daily cap, deliberately: a repeated identical
    # question should cost nothing against today's budget, not just save a
    # provider call.
    cache_key = body.message.strip()
    cached = guard.cache.get(cache_key)
    if cached is not None:
        logger.info(
            "assistant_turn_completed",
            cache_hit=True,
            daily_count=guard.daily_counter.count,
            daily_limit=guard.daily_limit,
        )
        return cached  # type: ignore[no-any-return]

    # Reserve a slot before ever calling the provider -- see
    # DailyUsageCounter.try_increment's own docstring for why this check
    # happens first, not after a successful call.
    allowed, daily_count = guard.daily_counter.try_increment()
    if not allowed:
        logger.warning(
            "assistant_daily_quota_exceeded",
            daily_limit=guard.daily_limit,
        )
        raise AssistantQuotaExceededError()

    # The whole turn -- both model calls plus the DB-backed tool execution
    # -- runs in one threadpool call. GeminiProvider/AnthropicProvider both
    # use blocking (sync) SDK clients, same reasoning as the DB services;
    # see db/sync_session.py and core/deps.py.
    try:
        result = await run_in_threadpool(
            run_assistant_turn, provider, service, body.message
        )
    except Exception as exc:
        # Full detail server-side only -- never the raw provider/DB
        # exception to the client. Same reasoning as health.py's /ready:
        # some driver/SDK exceptions embed sensitive-looking substrings in
        # their own class name. The reserved daily-counter slot above is
        # NOT refunded -- a failed call still spent real provider quota.
        logger.warning(
            "assistant_turn_failed",
            error_type=type(exc).__name__,
            daily_count=daily_count,
            daily_limit=guard.daily_limit,
        )
        raise ServiceUnavailableError(
            "The assistant is temporarily unavailable. Please try again shortly."
        ) from exc

    response = AssistantResponseOut(
        reply=result.reply_text,
        evidence=EvidenceOut.model_validate(result.evidence),
        grounding_warnings=result.grounding_warnings,
    )
    guard.cache.set(cache_key, response)

    logger.info(
        "assistant_turn_completed",
        cache_hit=False,
        daily_count=daily_count,
        daily_limit=guard.daily_limit,
        tool_call_latency_ms=round(result.timing.tool_call_ms, 2),
        reply_latency_ms=round(result.timing.reply_ms, 2),
        total_latency_ms=round(result.timing.total_ms, 2),
        grounding_warnings_count=len(result.grounding_warnings),
    )
    return response
