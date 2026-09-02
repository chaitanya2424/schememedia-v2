"""AI assistant: a natural-language front end over RecommendationService.

DESIGN -- read before changing anything here
==============================================

The instruction this module was built under is unambiguous: the LLM must
never independently invent a scheme fact or an eligibility rule. Every fact
in the assistant's final reply must trace back to RecommendationService,
which is itself grounded in the real 1,000-scheme dataset, the deterministic
eligibility engine, and the verification/provenance layer already built and
tested. This module adds a conversational surface on top; it adds no new
source of truth.

PROVIDER-INDEPENDENT
------------------------
Everything in this module -- the tool contract, both system prompts,
execute_find_matching_schemes, verify_grounded, the orchestration in
run_assistant_turn -- depends only on the `LLMProvider` Protocol
(services/providers/base.py), never on a specific SDK. `grep` this file for
"anthropic" or "genai" and find nothing. Which concrete provider actually
runs (Gemini, the free-tier default; Anthropic, optional and paid) is
decided once, at the edge, by services/providers/get_provider() reading
Settings.llm_provider -- nothing below that call knows or cares.

CONVERSATION FLOW (two model calls, not an open agentic loop)
------------------------------------------------------------------
    user message
        -> call #1, tool_choice FORCED to find_matching_schemes
           (the model cannot answer without searching first -- see "Why
           forced tool_choice" below)
        -> our own code executes the tool: RecommendationService.recommend()
           (100% deterministic, zero LLM involvement -- this is the only
           function in the whole assistant allowed to put a scheme fact in
           front of the model)
        -> call #2, given ONLY the tool result as evidence, writes the
           reply. No tools on this call; nothing to invent from.
        -> verify_grounded() re-checks the reply against the evidence and
           returns a list of warnings (empty on a clean reply)

Why forced tool_choice, not an open agentic loop or auto tool_choice:
this is deliberately the smallest, most conservative slice. Auto
tool_choice would let the model answer a scheme question from its own
(ungrounded, possibly wrong or out of date) knowledge on turns where it
judges a tool call unnecessary -- exactly the failure mode this module
exists to prevent. A richer flow (multi-turn chat, small talk without
searching, the model asking a clarifying question *before* searching) is a
natural next iteration, deferred, not forgotten -- see module-level TODO
below.

STRUCTURED PROFILE EXTRACTION
--------------------------------
`find_matching_schemes`'s `profile` parameter is a JSON object whose
properties are generated from `EligibilityAttribute` (schememedia.db.models.
enums) -- the same single source of truth the eligibility engine and the
database CHECK constraint both use. Claude extracts values only for
attributes the user actually stated; the tool description explicitly
instructs it never to guess or default one. This mirrors the eligibility
engine's own rule (never invent a missing profile attribute) one layer up,
at extraction time rather than evaluation time.

ASKING FOR MISSING INFORMATION
----------------------------------
The assistant does not decide what to ask about. Each evaluated scheme
already carries `missing_attributes` -- attribute keys the eligibility
engine could not resolve (services/eligibility_matcher.py). The answer
system prompt instructs Claude to surface exactly those, in its own words;
it never invents a question about an attribute the engine did not actually
need.

GROUNDING VERIFICATION -- what it does and does not catch
--------------------------------------------------------------
verify_grounded() is mechanical, not a general hallucination detector.
Detecting an arbitrary invented scheme name in free text is not reliably
tractable with string matching, and this module does not pretend otherwise.
It catches the specific, nameable failure modes the requirements call out:
fabricated official_url values, claiming official verification no result
supports, and overclaiming certainty about eligibility the engine actually
reported as unknown. Forced tool_choice is the real defence against
inventing a scheme outright -- verify_grounded is a second, narrower net
under it.

TODO (explicitly deferred, not forgotten): multi-turn conversation history,
auto tool_choice once grounding has more test coverage, streaming, and a
richer "ask before searching" flow for genuinely ambiguous first messages.
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass
from typing import Any

from schememedia.db.models.enums import (
    ALL_ATTRIBUTE_KEYS,
    AttributeType,
    EligibilityAttribute,
    attribute_type,
)
from schememedia.services.eligibility_matcher import missing_attributes
from schememedia.services.providers.base import LLMProvider
from schememedia.services.recommendation import Recommendation, RecommendationService

MAX_RESULTS_FOR_ASSISTANT = 5

_ATTRIBUTE_JSON_TYPE = {
    AttributeType.BOOLEAN: "boolean",
    AttributeType.NUMERIC: "number",
    AttributeType.TEXT: "string",
}


def _profile_schema_properties() -> dict[str, dict[str, str]]:
    """One JSON Schema property per EligibilityAttribute -- generated, not
    hand-duplicated, so this can never drift from the vocabulary the
    database CHECK constraint and the eligibility engine both enforce.
    """
    return {
        attr.value: {"type": _ATTRIBUTE_JSON_TYPE[attribute_type(attr)]}
        for attr in EligibilityAttribute
    }


FIND_SCHEMES_TOOL: dict[str, Any] = {
    "name": "find_matching_schemes",
    "description": (
        "Search SchemeMedia's database of Indian government welfare schemes "
        "and evaluate eligibility against a user profile. Call this for "
        "EVERY question about schemes, benefits, subsidies, pensions, "
        "scholarships, or eligibility -- including vague or incomplete "
        "questions. This tool is the only source of scheme facts; never "
        "answer from your own knowledge. Extract any profile details the "
        "user has already mentioned (age, income, occupation, category, "
        "state, etc.) into `profile`; leave an attribute out entirely if "
        "the user has not said anything about it -- never guess or default "
        "a value."
    ),
    "input_schema": {
        "type": "object",
        "properties": {
            "query": {
                "type": "string",
                "description": (
                    "A short natural-language search query for the kind of "
                    "scheme the user wants, e.g. 'scholarship for disabled "
                    "students' or 'widow pension'."
                ),
            },
            "profile": {
                "type": "object",
                "description": (
                    "Structured facts about the user, extracted only from "
                    "what they actually said. Omit any attribute not "
                    "mentioned."
                ),
                "properties": _profile_schema_properties(),
                "additionalProperties": False,
            },
        },
        "required": ["query"],
        "additionalProperties": False,
    },
}


def _serialize_recommendation(rec: Recommendation) -> dict[str, Any]:
    return {
        "scheme_id": rec.scheme_id,
        "name": rec.result.name,
        "category": rec.result.category,
        "jurisdiction": rec.result.jurisdiction,
        "state_code": rec.result.state_code,
        "scheme_type": rec.result.scheme_type,
        "eligibility_state": rec.eligibility.state.value,
        "eligibility_explanations": list(rec.eligibility.explanations),
        "missing_attributes": missing_attributes(rec.eligibility),
        "verification_status": rec.result.verification_status,
        "needs_review": rec.result.needs_review,
        "official_url": rec.result.official_url,
    }


def execute_find_matching_schemes(
    service: RecommendationService,
    query: str,
    profile: dict[str, Any] | None,
) -> dict[str, Any]:
    """The tool's implementation. Deterministic, no LLM involved.

    Unrecognised profile keys (a typo Claude produced despite the schema, or
    a future attribute this code does not know about yet) are dropped
    rather than passed through blind -- RecommendationService/evaluate_scheme
    would simply ignore them anyway (schememedia.services.eligibility_matcher
    never looks up a key no rule needs), but filtering here keeps the
    evidence payload honest about what was actually used.
    """
    clean_profile = (
        {k: v for k, v in profile.items() if k in ALL_ATTRIBUTE_KEYS} if profile else None
    )
    response = service.recommend(
        query, profile=clean_profile, limit=MAX_RESULTS_FOR_ASSISTANT
    )
    return {
        "query": response.query,
        "profile_provided": response.profile_provided,
        "total_returned": response.total_returned,
        "eligibility_breakdown": response.eligibility_breakdown,
        "results": [_serialize_recommendation(rec) for rec in response.recommendations],
    }


TOOL_CALL_SYSTEM_PROMPT = (
    "You are SchemeMedia's assistant, helping Indian citizens find "
    "government welfare schemes. You have exactly one capability: calling "
    "find_matching_schemes. Call it now, using the user's message to build "
    "a search query and to extract any profile facts they have already "
    "stated. Always search first, even with an incomplete profile -- the "
    "tool itself determines what it can and cannot resolve."
)

ANSWER_SYSTEM_PROMPT = """\
You are SchemeMedia's assistant. You have just received results from \
find_matching_schemes -- this is the ONLY source of truth about schemes. \
Write a short, clear reply for a citizen, following every rule below \
without exception.

GROUNDING -- the most important rules:
1. Mention ONLY schemes that appear in the tool result. Never name, \
   describe, or imply the existence of any other scheme.
2. State eligibility using only the given eligibility_state, translated \
   plainly:
   - "pass" -> "you may be eligible" (never "you ARE eligible" -- this \
     data is unofficial and self-reported; it must be verified against \
     the official source)
   - "fail" -> "based on what you've told me, you likely do not currently \
     meet every requirement" -- still mention the scheme, never hide it
   - "unknown" -> "I can't tell yet -- I'd need to know: <the specific \
     missing attributes>", and ask for exactly those, in plain language
   - "not_applicable" -> "no specific eligibility criteria are on file \
     for this scheme" -- never imply this means automatic approval
3. Give the official_url exactly as provided when present. When it is \
   null, say plainly that no official link is available -- never \
   construct, guess, or search for one yourself.
4. When verification_status is not "officially_verified", say the \
   information is unverified/self-reported and should be checked against \
   the official source. When needs_review is true, add that this \
   specific record has a known data-quality flag and deserves extra \
   caution.
5. If the tool returned zero results, say so plainly and suggest the \
   user rephrase or add detail. Never invent a scheme to fill the gap.
6. If any result's eligibility is "unknown" because profile information \
   is missing, end by asking for that specific missing information -- \
   not a generic "tell me more about yourself."

Keep the reply concise: a sentence or two per scheme, not a wall of text.\
"""


@dataclass(frozen=True)
class AssistantTurnResult:
    reply_text: str
    evidence: dict[str, Any]
    grounding_warnings: list[str]


def run_assistant_turn(
    provider: LLMProvider,
    service: RecommendationService,
    user_message: str,
) -> AssistantTurnResult:
    """One full turn: search (forced), then a grounded reply. See module
    docstring for why this is two calls rather than an open tool loop, and
    for why `provider` is the only thing here that ever changes between
    Gemini and Anthropic.
    """
    tool_call = provider.call_with_forced_tool(
        system_prompt=TOOL_CALL_SYSTEM_PROMPT,
        user_message=user_message,
        tool=FIND_SCHEMES_TOOL,
    )
    query = tool_call.input.get("query") or user_message
    profile = tool_call.input.get("profile") or {}

    evidence = execute_find_matching_schemes(service, query, profile)

    reply_text = provider.generate_reply(
        system_prompt=ANSWER_SYSTEM_PROMPT,
        user_message=user_message,
        tool_call=tool_call,
        tool_result_json=json.dumps(evidence),
    )
    warnings = verify_grounded(reply_text, evidence)

    return AssistantTurnResult(
        reply_text=reply_text, evidence=evidence, grounding_warnings=warnings
    )


# ---------------------------------------------------------------------------
# Grounding verification -- see module docstring for scope and limits
# ---------------------------------------------------------------------------

_URL_PATTERN = re.compile(r"https?://[^\s)\]\"']+")
_VERIFIED_PHRASES = (
    "officially verified",
    "verified by the government",
    "government-verified",
    "government verified",
)
_CERTAINTY_PHRASES = ("you are eligible", "you qualify", "you will get", "guaranteed")
_HEDGE_WORDS = (
    "may",
    "might",
    "could",
    "possibly",
    "likely",
    "based on",
    "not sure",
    "unofficial",
    "unverified",
    "unknown",
    "can't tell",
    "cannot tell",
)


def verify_grounded(reply_text: str, evidence: dict[str, Any]) -> list[str]:
    """Mechanical, targeted checks -- not a general hallucination detector.
    See module docstring "GROUNDING VERIFICATION" for what this does and
    does not catch.
    """
    warnings: list[str] = []
    results = evidence.get("results", [])
    lowered = reply_text.lower()

    allowed_urls = {r["official_url"] for r in results if r.get("official_url")}
    for url in _URL_PATTERN.findall(reply_text):
        if url not in allowed_urls:
            warnings.append(f"fabricated or unsupported URL: {url}")

    has_officially_verified = any(
        r.get("verification_status") == "officially_verified" for r in results
    )
    if not has_officially_verified and any(p in lowered for p in _VERIFIED_PHRASES):
        warnings.append("claims official verification not supported by any result")

    for r in results:
        if r.get("eligibility_state") != "unknown":
            continue
        name = r["name"].lower()
        idx = lowered.find(name)
        if idx == -1:
            continue
        window = lowered[max(0, idx - 80) : idx + len(name) + 80]
        if any(p in window for p in _CERTAINTY_PHRASES) and not any(
            h in window for h in _HEDGE_WORDS
        ):
            warnings.append(
                f"overclaims certainty for {r['name']!r}, whose eligibility is unknown"
            )

    if not results and re.search(r"SCH_[0-9A-F]{6,}", reply_text):
        warnings.append("references a scheme id despite zero search results")

    return warnings
