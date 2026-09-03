"""Shared test doubles.

Not application code -- nothing under src/ imports this module. Kept here,
not inline in one test file, because more than one test module needs a
scripted LLMProvider with no network and no SDK dependency (see
test_assistant.py and test_api_routes.py).
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from schememedia.services.providers.base import ToolCall


@dataclass
class FakeProvider:
    """A scripted LLMProvider -- no network, no SDK.

    `tool_call_query`/`tool_call_profile` stand in for what a real model
    would have extracted from the user's message; `reply_text` stands in
    for its final answer. `received_tool_result_json` records what
    run_assistant_turn actually handed back, so a test can assert the fake
    "model" was shown the real evidence.

    `raises`, when set, is raised from `call_with_forced_tool` instead of
    returning a tool call -- stands in for a real provider failure (timeout,
    quota exhaustion, malformed response) so a test can exercise the
    assistant route's failure path without a real network dependency.

    `calls` counts invocations of `call_with_forced_tool` -- lets a test
    assert the provider was (or, for the kill switch / daily cap / cache,
    was NOT) actually reached, not just that a particular HTTP status came
    back.
    """

    tool_call_query: str
    tool_call_profile: dict[str, Any] = field(default_factory=dict)
    reply_text: str = "This is a fake grounded reply."
    raises: Exception | None = None
    received_tool_result_json: str | None = field(default=None, init=False)
    calls: int = field(default=0, init=False)

    def call_with_forced_tool(
        self, *, system_prompt: str, user_message: str, tool: dict[str, Any]
    ) -> ToolCall:
        self.calls += 1
        if self.raises is not None:
            raise self.raises
        return ToolCall(
            id="fake-call-1",
            name=tool["name"],
            input={"query": self.tool_call_query, "profile": self.tool_call_profile},
        )

    def generate_reply(
        self,
        *,
        system_prompt: str,
        user_message: str,
        tool_call: ToolCall,
        tool_result_json: str,
    ) -> str:
        self.received_tool_result_json = tool_result_json
        return self.reply_text
