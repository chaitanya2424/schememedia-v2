"""The provider boundary the AI assistant is built against.

Everything specific to Anthropic or Gemini -- request shapes, content block
types, SDK client classes -- stays inside one provider module and never
crosses this line. services/assistant.py (the tool contract, the grounding
system prompts, execute_find_matching_schemes, verify_grounded) depends only
on `LLMProvider` and `ToolCall`, both defined here, and never imports an SDK
directly. That is what "no business logic depends on the provider" means in
practice: grep services/assistant.py for "anthropic" or "genai" and find
nothing.

Two methods, matching the two-call grounded flow exactly (see
services/assistant.py's module docstring for why it is two calls, not an
open tool loop):

    call_with_forced_tool   -- the model must call the given tool; it
                                cannot answer with free text on this turn.
    generate_reply          -- given the tool call and its result, the
                                model writes the final reply. No tools on
                                this call -- nothing left to invent from.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Protocol


@dataclass(frozen=True)
class ToolCall:
    """Provider-neutral shape of "the model decided to call this tool with
    these arguments". Anthropic's tool_use content block and Gemini's
    function_call Part both collapse to this on the way out of their
    respective provider modules.

    `raw` is an escape hatch, not part of the neutral contract: a provider
    may stash whatever it needs to correctly replay the conversation turn
    in its own `generate_reply` (e.g. the exact content blocks Anthropic's
    API requires echoed back). Nothing outside that same provider's module
    -- not services/assistant.py, not tests, not another provider -- may
    read it. Kept on ToolCall rather than instance state on the provider so
    a provider stays reentrant: each call produces its own self-contained
    ToolCall instead of mutating shared state between the two calls.
    """

    id: str
    name: str
    input: dict[str, Any]
    raw: Any = None


class LLMProvider(Protocol):
    def call_with_forced_tool(
        self, *, system_prompt: str, user_message: str, tool: dict[str, Any]
    ) -> ToolCall:
        """Ask the model to call `tool` -- and only `tool` -- given the user
        message. Implementations must force this at the API level (e.g.
        Anthropic's tool_choice, Gemini's FunctionCallingConfigMode.ANY),
        not merely request it in the prompt; the whole grounding guarantee
        rests on this never silently falling back to free text.
        """
        ...

    def generate_reply(
        self,
        *,
        system_prompt: str,
        user_message: str,
        tool_call: ToolCall,
        tool_result_json: str,
    ) -> str:
        """Ask the model for its final natural-language reply, given the
        tool call it made and the JSON-serialised result that came back.
        """
        ...
