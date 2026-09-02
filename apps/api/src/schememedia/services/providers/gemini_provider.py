"""Gemini implementation of LLMProvider -- the default development
provider (see get_provider() in providers/__init__.py) because the Gemini
API has a genuinely free tier, unlike Anthropic's.

Package: `google-genai` (the current, actively maintained SDK -- NOT the
retired `google-generativeai` package. REBUILD_PLAN's own findings on the
v1 codebase (D-20) are the reason this distinction gets called out here:
v1 used `google-generativeai` and a since-retired model, and it broke.).

Model default is `gemini-3.6-flash`, overridable via the `model` argument /
GEMINI_MODEL env var (see core/config.py). This was NOT a guess: the
original default, gemini-2.5-flash, was live-tested against the real API
during integration verification and rejected outright -- HTTP 404, "This
model models/gemini-2.5-flash is no longer available to new users. ...use
models/gemini-3.6-flash" -- so the replacement came from Google's own API
response, the most authoritative source available, not from documentation
that had already proven unreliable for model names (see git history for the
web-fetch inconsistencies this replaced). Bump it freely if it changes again
-- it is not load-bearing anywhere else.

API surface below was verified directly against the installed `google-genai`
2.20.0 package (field introspection, not documentation) -- see
`FunctionDeclaration.parameters_json_schema` (accepts a raw JSON-schema
dict, mutually exclusive with the Schema-typed `parameters` field) and
`Content.role`, whose docstring is explicit: "Must be either 'user' or
'model'" -- the function-result turn uses 'user', not 'tool'.
"""

from __future__ import annotations

import json
import uuid
from typing import Any

from google import genai
from google.genai import types

from schememedia.services.providers.base import ToolCall

DEFAULT_MODEL = "gemini-3.6-flash"

# Audit finding H1: an unconfigured client has no request timeout at all.
# The assistant route runs both provider calls inside one
# `run_in_threadpool` call (api/v1/routers/assistant.py) on the same
# threadpool search/recommendations/scheme-detail also use -- a hung
# Gemini request blocks that worker thread forever, and enough of them
# exhausts the whole pool and stalls unrelated endpoints. Two calls happen
# per turn (call_with_forced_tool then generate_reply), so this is a
# per-call budget, not a whole-turn one; the client-facing timeout in
# apps/frontend accounts for both. `HttpOptions.timeout` is milliseconds
# (verified via field introspection on the installed google-genai package,
# same practice as this module's other API-shape decisions -- see the
# module docstring).
#
# 20_000 (the original H1 value) was too tight and caused a real, observed
# regression during live user testing: four measured `call_with_forced_tool`
# round trips against the real API came back at 3.40s, 6.27s, 6.43s, and
# 18.77s -- that last one is within a hair of 20s, and a real end-to-end
# request was measured failing with a spurious 503 at 19.5s. LLM API tail
# latency is genuinely this variable; 30s keeps a real, finite bound (the
# actual H1 requirement) while leaving headroom above the worst latency
# observed so far rather than sitting right at its edge.
DEFAULT_TIMEOUT_MS = 30_000


class GeminiProvider:
    def __init__(
        self,
        *,
        client: genai.Client | None = None,
        api_key: str | None = None,
        model: str = DEFAULT_MODEL,
        timeout_ms: int = DEFAULT_TIMEOUT_MS,
    ):
        # api_key=None lets the client fall back to GEMINI_API_KEY /
        # GOOGLE_API_KEY from the environment, same convenience as the
        # Anthropic client's zero-arg constructor.
        self._client = client or genai.Client(
            api_key=api_key, http_options=types.HttpOptions(timeout=timeout_ms)
        )
        self._model = model

    def _tool(self, tool: dict[str, Any]) -> types.Tool:
        return types.Tool(
            function_declarations=[
                types.FunctionDeclaration(
                    name=tool["name"],
                    description=tool["description"],
                    parameters_json_schema=tool["input_schema"],
                )
            ]
        )

    def call_with_forced_tool(
        self, *, system_prompt: str, user_message: str, tool: dict[str, Any]
    ) -> ToolCall:
        response = self._client.models.generate_content(
            model=self._model,
            contents=user_message,
            config=types.GenerateContentConfig(
                system_instruction=system_prompt,
                tools=[self._tool(tool)],
                tool_config=types.ToolConfig(
                    function_calling_config=types.FunctionCallingConfig(
                        mode=types.FunctionCallingConfigMode.ANY,
                        allowed_function_names=[tool["name"]],
                    )
                ),
                automatic_function_calling=types.AutomaticFunctionCallingConfig(
                    disable=True
                ),
            ),
        )
        calls = response.function_calls
        if not calls:
            raise RuntimeError(
                "Gemini did not return a function call despite ANY mode -- "
                f"response: {response!r}"
            )
        call = calls[0]
        args = dict(call.args) if call.args else {}
        # The response Part carrying this function call also carries a
        # thought_signature -- opaque bytes the API requires echoed back
        # verbatim on any later turn that replays this function call
        # (discovered live: omitting it is a 400, "Function call is missing
        # a thought_signature in functionCall parts"; this is not
        # documented anywhere this module's author could find in advance).
        # Storing the whole original Part, not just the FunctionCall, is
        # what makes that echo correct -- reconstructing a fresh Part from
        # only `call` silently drops the signature.
        #
        # candidates/content/parts are typed Optional by the SDK; a
        # non-empty `calls` (checked above) already proves all three are
        # populated on this response, so the asserts below are narrowing
        # for mypy, not new runtime behaviour.
        assert response.candidates and response.candidates[0].content
        parts = response.candidates[0].content.parts
        assert parts
        part = next(p for p in parts if p.function_call)
        # call.id and call.name are typed Optional by the SDK even though
        # they are always populated in practice for a forced, single-tool
        # call -- id gets a synthesised fallback (see ToolCall's docstring
        # on `raw`), name falls back to the tool we forced, since that is
        # necessarily what was called under ANY mode with
        # allowed_function_names=[tool["name"]].
        call_id = call.id or f"call_{uuid.uuid4().hex[:8]}"
        return ToolCall(
            id=call_id,
            name=call.name or tool["name"],
            input=args,
            raw={"user_message": user_message, "function_call_part": part},
        )

    def generate_reply(
        self,
        *,
        system_prompt: str,
        user_message: str,
        tool_call: ToolCall,
        tool_result_json: str,
    ) -> str:
        function_call_content = types.Content(
            role="model",
            parts=[tool_call.raw["function_call_part"]],
        )
        function_response_part = types.Part.from_function_response(
            name=tool_call.name,
            response={"result": json.loads(tool_result_json)},
        )
        # 'user', not 'tool' -- Content.role's own docstring in the
        # installed SDK is explicit: "Must be either 'user' or 'model'".
        # This is the turn that carries the function result back to the
        # model. list[Content] vs. the SDK's broader content-union
        # parameter type is a list-invariance mypy false positive, not a
        # real mismatch -- every element genuinely is a Content.
        contents: list[Any] = [
            types.Content(role="user", parts=[types.Part(text=user_message)]),
            function_call_content,
            types.Content(role="user", parts=[function_response_part]),
        ]
        response = self._client.models.generate_content(
            model=self._model,
            contents=contents,
            config=types.GenerateContentConfig(system_instruction=system_prompt),
        )
        return response.text or ""
