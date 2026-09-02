"""Anthropic implementation of LLMProvider. Optional -- see get_provider()
in providers/__init__.py. Requires ANTHROPIC_API_KEY (paid, no free tier);
Gemini is the default development provider precisely so nobody needs this
one just to run the test suite or try the assistant locally.

The `# type: ignore[call-overload]` below is a known mypy overload-
resolution false positive against messages.create()'s dict-literal params
(verified against the SDK's documented shapes), not a real type error.
"""

from __future__ import annotations

from typing import Any

import anthropic

from schememedia.services.providers.base import ToolCall

DEFAULT_MODEL = "claude-opus-5"

# Audit finding H1: an unconfigured client falls back to the SDK's own
# default (several minutes), far longer than a synchronous, threadpool-
# bound web request should ever block for. See gemini_provider.py's
# matching constant for the full reasoning -- both providers get the same
# per-call budget so the assistant's behaviour doesn't depend on which one
# is configured. Raised from the original 20.0 to 30.0 after live testing
# measured real Gemini call latency within a hair of 20s (see
# gemini_provider.py's DEFAULT_TIMEOUT_MS comment for the actual numbers).
DEFAULT_TIMEOUT_SECONDS = 30.0


class AnthropicProvider:
    def __init__(
        self,
        *,
        client: anthropic.Anthropic | None = None,
        model: str = DEFAULT_MODEL,
        timeout_seconds: float = DEFAULT_TIMEOUT_SECONDS,
    ):
        self._client = client or anthropic.Anthropic(timeout=timeout_seconds)
        self._model = model

    def call_with_forced_tool(
        self, *, system_prompt: str, user_message: str, tool: dict[str, Any]
    ) -> ToolCall:
        response = self._client.messages.create(  # type: ignore[call-overload]
            model=self._model,
            max_tokens=16000,
            thinking={"type": "adaptive"},
            system=system_prompt,
            tools=[tool],
            tool_choice={"type": "tool", "name": tool["name"]},
            messages=[{"role": "user", "content": user_message}],
        )
        block = next(b for b in response.content if b.type == "tool_use")
        # `raw` carries the full assistant content (all blocks, not just the
        # tool_use one) -- Anthropic's API requires the exact prior turn
        # echoed back in generate_reply. See ToolCall's own docstring.
        return ToolCall(
            id=block.id, name=block.name, input=dict(block.input), raw=response.content
        )

    def generate_reply(
        self,
        *,
        system_prompt: str,
        user_message: str,
        tool_call: ToolCall,
        tool_result_json: str,
    ) -> str:
        response = self._client.messages.create(
            model=self._model,
            max_tokens=16000,
            thinking={"type": "adaptive"},
            system=system_prompt,
            messages=[
                {"role": "user", "content": user_message},
                {"role": "assistant", "content": tool_call.raw},
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "tool_result",
                            "tool_use_id": tool_call.id,
                            "content": tool_result_json,
                        }
                    ],
                },
            ],
        )
        return "".join(b.text for b in response.content if b.type == "text")
