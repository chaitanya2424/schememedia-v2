"""Tests for the AI assistant layer.

Four layers, in increasing order of what they depend on:

  * Tool schema -- pure logic, no database, no LLM. Confirms the profile
    schema can never drift from the eligibility attribute vocabulary.
  * verify_grounded() -- pure logic, no database, no LLM. This is where the
    bulk of hallucination/unsupported-claim coverage lives, using synthetic
    reply text standing in for both well-behaved and hallucinated model
    output -- fast, deterministic, no API key required.
  * execute_find_matching_schemes() -- real database, real 1,000-scheme
    dataset, no LLM. Confirms the evidence handed to the model is itself
    correct and complete.
  * run_assistant_turn() full orchestration -- real database, a scripted
    FakeProvider standing in for the model. No network, no SDK, no API key,
    and it exercises the actual control flow (not just its pieces in
    isolation). This is where "test the full assistant logic without
    making API calls" is satisfied concretely.
  * run_assistant_turn() end-to-end against a real provider -- optional,
    gated independently on GEMINI_API_KEY/GOOGLE_API_KEY or
    ANTHROPIC_API_KEY; skips cleanly without one, same pattern as every
    other optional-dependency test in this suite.
"""

from __future__ import annotations

import os
from pathlib import Path

import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session

from schememedia.db.models.enums import ALL_ATTRIBUTE_KEYS
from schememedia.importer.pipeline import run_import, sync_database_url
from schememedia.repositories.eligibility import SqlEligibilityRuleRepository
from schememedia.repositories.search import PgVectorRetriever, SqlKeywordRetriever
from schememedia.services.assistant import (
    FIND_SCHEMES_TOOL,
    execute_find_matching_schemes,
    run_assistant_turn,
    verify_grounded,
)
from schememedia.services.providers.base import LLMProvider
from schememedia.services.recommendation import RecommendationService
from schememedia.services.search import SearchService
from tests.conftest import database_is_reachable, resolve_test_database_url
from tests.fakes import FakeProvider

TEST_DATABASE_URL = resolve_test_database_url()
DATABASE_AVAILABLE = database_is_reachable(TEST_DATABASE_URL)
REPO_ROOT = Path(__file__).resolve().parents[3]
SCHEMES_JSON = REPO_ROOT / "schemes.json"

pytestmark = pytest.mark.skipif(
    not (DATABASE_AVAILABLE and SCHEMES_JSON.exists()),
    reason="PostgreSQL unreachable or schemes.json missing; see README section 1",
)

_TRUNCATE = text(
    "TRUNCATE schemes, categories, tags, scheme_tags, "
    "scheme_benefits, scheme_documents, scheme_eligibility_rules CASCADE"
)


# ---------------------------------------------------------------------------
# Tool schema -- no database, no LLM
# ---------------------------------------------------------------------------


def test_profile_schema_matches_the_eligibility_attribute_vocabulary() -> None:
    """Generated from EligibilityAttribute, not hand-duplicated -- this test
    is what would catch drift if a future attribute were added to one place
    and not the other.
    """
    schema_keys = set(
        FIND_SCHEMES_TOOL["input_schema"]["properties"]["profile"]["properties"]
    )
    assert schema_keys == set(ALL_ATTRIBUTE_KEYS)


def test_tool_schema_requires_only_query() -> None:
    assert FIND_SCHEMES_TOOL["input_schema"]["required"] == ["query"]


def test_tool_schema_rejects_additional_properties() -> None:
    assert FIND_SCHEMES_TOOL["input_schema"]["additionalProperties"] is False
    profile_schema = FIND_SCHEMES_TOOL["input_schema"]["properties"]["profile"]
    assert profile_schema["additionalProperties"] is False


# ---------------------------------------------------------------------------
# verify_grounded -- pure logic, synthetic evidence and reply text
# ---------------------------------------------------------------------------

_EVIDENCE = {
    "results": [
        {
            "name": "Farmers Training",
            "eligibility_state": "pass",
            "verification_status": "unverified",
            "needs_review": False,
            "official_url": None,
        },
        {
            "name": "State Disability Scholarship",
            "eligibility_state": "unknown",
            "verification_status": "unverified",
            "needs_review": True,
            "official_url": "https://example.gov.in/disability-scholarship",
        },
    ]
}


def test_clean_reply_produces_no_warnings() -> None:
    reply = (
        "Farmers Training: you may be eligible based on what you've told me. "
        "State Disability Scholarship: I can't tell yet -- what's your disability "
        "status? This scheme has a known data-quality flag and no official link "
        "is available for it, so double-check the details before applying."
    )
    assert verify_grounded(reply, _EVIDENCE) == []


def test_correct_url_is_not_flagged() -> None:
    reply = "See https://example.gov.in/disability-scholarship for details."
    assert verify_grounded(reply, _EVIDENCE) == []


def test_fabricated_url_is_flagged() -> None:
    reply = "Apply here: https://not-a-real-government-site.example.com/apply"
    warnings = verify_grounded(reply, _EVIDENCE)
    assert any("fabricated or unsupported URL" in w for w in warnings)


def test_url_not_in_evidence_at_all_is_flagged_even_if_plausible() -> None:
    """A URL for a *different real government scheme* is still fabricated in
    this context -- the model must not substitute one real fact for another.
    """
    reply = "Try https://example.gov.in/some-other-scheme instead."
    warnings = verify_grounded(reply, _EVIDENCE)
    assert any("fabricated or unsupported URL" in w for w in warnings)


def test_claiming_official_verification_without_support_is_flagged() -> None:
    reply = "Farmers Training is officially verified by the government."
    warnings = verify_grounded(reply, _EVIDENCE)
    assert any("official verification" in w for w in warnings)


def test_officially_verified_claim_is_allowed_when_supported() -> None:
    evidence = {
        "results": [
            {
                "name": "Farmers Training",
                "eligibility_state": "pass",
                "verification_status": "officially_verified",
                "needs_review": False,
                "official_url": None,
            }
        ]
    }
    reply = "Farmers Training is officially verified."
    assert verify_grounded(reply, evidence) == []


def test_overclaiming_certainty_on_unknown_eligibility_is_flagged() -> None:
    reply = "For the State Disability Scholarship, you are eligible."
    warnings = verify_grounded(reply, _EVIDENCE)
    assert any("overclaims certainty" in w for w in warnings)


def test_hedged_language_on_unknown_eligibility_is_not_flagged() -> None:
    reply = (
        "For the State Disability Scholarship, I can't tell if you are eligible "
        "yet -- it's unknown without more information."
    )
    assert verify_grounded(reply, _EVIDENCE) == []


def test_pass_state_is_never_flagged_for_certainty_language() -> None:
    """Only "unknown" results trigger the overclaim check -- a "pass" result
    saying "you are eligible" is not itself a violation this checker covers
    (the system prompt separately asks for "may be eligible" phrasing, but
    that is a style rule, not a groundedness rule)."""
    reply = "Farmers Training: you are eligible!"
    assert verify_grounded(reply, _EVIDENCE) == []


def test_zero_results_with_a_referenced_scheme_id_is_flagged() -> None:
    warnings = verify_grounded(
        "You might like SCH_1F47743B, a great scholarship!", {"results": []}
    )
    assert any("despite zero search results" in w for w in warnings)


def test_zero_results_with_an_honest_reply_is_not_flagged() -> None:
    reply = "I couldn't find any schemes matching that. Could you add more detail?"
    assert verify_grounded(reply, {"results": []}) == []


def test_multiple_violations_are_all_reported() -> None:
    reply = (
        "This is officially verified! Apply at https://fake.example.com now -- "
        "you are eligible for the State Disability Scholarship."
    )
    warnings = verify_grounded(reply, _EVIDENCE)
    assert len(warnings) >= 3


# ---------------------------------------------------------------------------
# execute_find_matching_schemes -- real database, real dataset, no LLM
# ---------------------------------------------------------------------------


@pytest.fixture(scope="module")
def recommendation_service():
    from schememedia.cli.generate_embeddings import run as generate_embeddings

    engine = create_engine(sync_database_url(TEST_DATABASE_URL), future=True)
    with Session(engine) as session:
        session.execute(_TRUNCATE)
        session.commit()
        run_import(session, SCHEMES_JSON)
        session.commit()
        generate_embeddings(session)
        session.commit()

        yield RecommendationService(
            search=SearchService(
                keyword=SqlKeywordRetriever(session),
                semantic=PgVectorRetriever(session),
            ),
            rules=SqlEligibilityRuleRepository(session),
        )

        session.execute(_TRUNCATE)
        session.commit()
    engine.dispose()


def test_evidence_contains_only_real_scheme_facts(recommendation_service) -> None:
    """REAL: SCH_1F47743B ranks #1 for this query."""
    evidence = execute_find_matching_schemes(
        recommendation_service, "sports journalism award", {"is_sc_st": True}
    )
    scheme_ids = [r["scheme_id"] for r in evidence["results"]]
    assert "SCH_1F47743B" in scheme_ids
    match = next(r for r in evidence["results"] if r["scheme_id"] == "SCH_1F47743B")
    assert match["eligibility_state"] == "pass"
    assert match["eligibility_explanations"]
    assert "verification_status" in match
    assert "needs_review" in match
    assert "official_url" in match  # present as a key even when None


def test_evidence_reports_missing_attributes_for_unknown_results(
    recommendation_service,
) -> None:
    evidence = execute_find_matching_schemes(
        recommendation_service, "sports journalism award", None
    )
    match = next(r for r in evidence["results"] if r["scheme_id"] == "SCH_1F47743B")
    assert match["eligibility_state"] == "unknown"
    assert set(match["missing_attributes"]) == {"is_sc_st", "is_ews", "is_lig"}


def test_evidence_is_empty_for_a_nonsense_query(recommendation_service) -> None:
    evidence = execute_find_matching_schemes(
        recommendation_service, "zzzqqqxwv", {"is_farmer": True}
    )
    assert evidence["results"] == []
    assert evidence["total_returned"] == 0


def test_unrecognised_profile_keys_are_dropped_before_evaluation(
    recommendation_service,
) -> None:
    """A key outside ALL_ATTRIBUTE_KEYS (e.g. a schema slip) must never
    reach evaluate_scheme -- it would just be ignored there too, but this
    keeps the evidence payload honest about what was actually used.
    """
    evidence = execute_find_matching_schemes(
        recommendation_service,
        "sports journalism award",
        {"is_sc_st": True, "totally_made_up_field": "xyz"},
    )
    assert evidence["profile_provided"] is True
    match = next(r for r in evidence["results"] if r["scheme_id"] == "SCH_1F47743B")
    assert match["eligibility_state"] == "pass"  # is_sc_st still applied


# ---------------------------------------------------------------------------
# Full orchestration, no API calls -- a scripted LLMProvider double
# ---------------------------------------------------------------------------
#
# This is what "test the full assistant logic without making API calls"
# means concretely: run_assistant_turn's real control flow (call the
# provider, execute_find_matching_schemes against the REAL database, feed
# the result back, verify_grounded the reply) runs exactly as it would in
# production. Only the two model calls are replaced with scripted,
# deterministic responses -- so these tests exercise the actual
# orchestration, on every CI run, with no provider credentials at all.
# FakeProvider itself lives in tests/fakes.py -- test_api_routes.py reuses
# it too.


def test_fake_provider_satisfies_the_llm_provider_protocol() -> None:
    provider: LLMProvider = FakeProvider(tool_call_query="x")
    assert provider is not None  # the real assertion is that mypy accepts this


def test_orchestration_calls_the_real_recommendation_engine(
    recommendation_service,
) -> None:
    """REAL: SCH_1F47743B, scripted as if the model had extracted this
    query and profile from the user's message.
    """
    provider = FakeProvider(
        tool_call_query="sports journalism award",
        tool_call_profile={"is_sc_st": True},
        reply_text="You may be eligible for the Biju Patnaik Sports Award.",
    )
    result = run_assistant_turn(provider, recommendation_service, "anything")

    scheme_ids = [r["scheme_id"] for r in result.evidence["results"]]
    assert "SCH_1F47743B" in scheme_ids
    match = next(
        r for r in result.evidence["results"] if r["scheme_id"] == "SCH_1F47743B"
    )
    assert match["eligibility_state"] == "pass"
    assert result.reply_text == "You may be eligible for the Biju Patnaik Sports Award."
    assert result.grounding_warnings == []
    # The fake "model" really was shown the real evidence, not a stub.
    assert provider.received_tool_result_json is not None
    assert "SCH_1F47743B" in provider.received_tool_result_json


def test_orchestration_surfaces_grounding_warnings_for_a_bad_reply(
    recommendation_service,
) -> None:
    """A scripted hallucinated reply must still be caught end-to-end, not
    just by calling verify_grounded directly.
    """
    provider = FakeProvider(
        tool_call_query="sports journalism award",
        tool_call_profile={"is_sc_st": True},
        reply_text="Apply now at https://totally-made-up-site.example.com/apply",
    )
    result = run_assistant_turn(provider, recommendation_service, "anything")
    assert any("fabricated or unsupported URL" in w for w in result.grounding_warnings)


def test_orchestration_falls_back_to_user_message_when_query_is_missing(
    recommendation_service,
) -> None:
    """A defensive case: if a provider's tool call somehow omits `query`
    (should never happen given the tool's required field, but the fake can
    still express it), the user's raw message is used instead of failing.
    """
    provider = FakeProvider(tool_call_query="", reply_text="ok")
    result = run_assistant_turn(
        provider, recommendation_service, "sports journalism award"
    )
    assert result.evidence["query"] == "sports journalism award"


def test_orchestration_handles_zero_results_without_error(
    recommendation_service,
) -> None:
    provider = FakeProvider(
        tool_call_query="zzzqqqxwv",
        reply_text="I couldn't find any matching schemes. Could you add more detail?",
    )
    result = run_assistant_turn(provider, recommendation_service, "zzzqqqxwv")
    assert result.evidence["results"] == []
    assert result.grounding_warnings == []


# ---------------------------------------------------------------------------
# End-to-end -- real database AND a real provider (optional, key-gated)
# ---------------------------------------------------------------------------
#
# Neither of these runs without its own credentials. Both are here so
# whichever provider is actually configured gets a real smoke test; neither
# blocks the other, and neither blocks the suite when unset -- same
# skip-cleanly-with-a-reason pattern as every DB-dependent test in this
# project.

GEMINI_AVAILABLE = bool(
    os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
)
ANTHROPIC_AVAILABLE = bool(os.environ.get("ANTHROPIC_API_KEY"))


@pytest.mark.skipif(
    not GEMINI_AVAILABLE,
    reason="GEMINI_API_KEY/GOOGLE_API_KEY not set; live Gemini test skipped",
)
def test_assistant_turn_is_grounded_with_real_gemini(recommendation_service) -> None:
    from google.genai.errors import ClientError, ServerError

    from schememedia.services.providers.gemini_provider import GeminiProvider

    provider = GeminiProvider()
    try:
        result = run_assistant_turn(
            provider,
            recommendation_service,
            "I'm SC/ST, are there any sports or journalism awards for me?",
        )
    except ClientError as exc:
        # A 4xx from Gemini is normally this app's own fault (a malformed
        # request, bad auth) -- RESOURCE_EXHAUSTED is the one documented
        # exception: gemini-3.6-flash's free tier is 20 requests/DAY per
        # project (confirmed by direct diagnosis, not assumed), easy to
        # exhaust during a day of live-testing this exact call. A real,
        # expected quota limit, not a regression -- see assistant.py's
        # route for how a caller sees this (a clean 503, never this raw
        # exception). `.code`/`.status` are the SDK's own structured
        # fields (google.genai.errors.APIError), not a string match
        # against exc's repr. Anything else re-raises: this test must fail
        # loudly on a genuine application regression, not swallow it as
        # "probably Gemini's fault".
        if exc.code == 429 and exc.status == "RESOURCE_EXHAUSTED":
            pytest.skip(f"Gemini free-tier quota exhausted for today: {exc}")
        raise
    except ServerError as exc:
        # A 5xx here is Google's own infrastructure reporting a fault --
        # observed live as both 503 UNAVAILABLE ("This model is currently
        # experiencing high demand") and 504 DEADLINE_EXCEEDED (the
        # request timed out on Google's own side, not this app's 30s
        # client-side budget -- see gemini_provider.py's DEFAULT_TIMEOUT_MS
        # -- a client-side timeout would surface as an httpx exception, not
        # an APIError at all). The SDK's own class hierarchy already draws
        # this exact line (ClientError = 4xx = normally this app's fault,
        # ServerError = 5xx = the provider's own fault -- see
        # google.genai.errors.raise_error), so treating ServerError as a
        # whole as "externally caused" is the SDK-authoritative boundary,
        # not an arbitrary catch-all -- nothing in this codebase can make
        # Gemini's own infrastructure available, and retrying later is the
        # only remedy, exactly like the quota case above.
        pytest.skip(f"Gemini API server-side error ({exc.code} {exc.status}): {exc}")
    assert result.reply_text
    assert result.grounding_warnings == []
    assert "results" in result.evidence


@pytest.mark.skipif(
    not ANTHROPIC_AVAILABLE,
    reason="ANTHROPIC_API_KEY not set; live Anthropic test skipped",
)
def test_assistant_turn_is_grounded_with_real_anthropic(recommendation_service) -> None:
    from schememedia.services.providers.anthropic_provider import AnthropicProvider

    provider = AnthropicProvider()
    result = run_assistant_turn(
        provider,
        recommendation_service,
        "I'm SC/ST, are there any sports or journalism awards for me?",
    )
    assert result.reply_text
    assert result.grounding_warnings == []
    assert "results" in result.evidence
