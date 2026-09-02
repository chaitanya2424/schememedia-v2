"""LLM provider selection.

`get_provider(settings)` is the only place in the codebase that reads
`settings.llm_provider` -- everything downstream (services/assistant.py,
RecommendationService, the eligibility engine) works against the
`LLMProvider` Protocol in base.py and never knows or asks which concrete
provider it is talking to.

Both provider SDKs (`anthropic`, `google-genai`) are imported lazily inside
their own modules, not here -- selecting "gemini" never has to construct or
even import the Anthropic client, and vice versa.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

from schememedia.services.providers.base import LLMProvider, ToolCall

if TYPE_CHECKING:
    from schememedia.core.config import Settings

__all__ = ["LLMProvider", "ToolCall", "get_provider"]


def get_provider(settings: Settings) -> LLMProvider:
    if settings.llm_provider == "gemini":
        from schememedia.services.providers.gemini_provider import GeminiProvider

        return GeminiProvider(
            api_key=settings.gemini_api_key, model=settings.gemini_model
        )
    if settings.llm_provider == "anthropic":
        import anthropic

        from schememedia.services.providers.anthropic_provider import (
            DEFAULT_TIMEOUT_SECONDS,
            AnthropicProvider,
        )

        # No explicit key -> the bare constructor, so the SDK's own
        # fallback chain runs (ANTHROPIC_API_KEY -> ANTHROPIC_AUTH_TOKEN ->
        # an `ant auth login` profile); passing api_key=None explicitly is
        # not guaranteed to be equivalent, so this branches instead.
        #
        # This constructs the client itself rather than letting
        # AnthropicProvider's own `client or anthropic.Anthropic(...)`
        # fallback run -- a `client` is always supplied below, so that
        # fallback (and its default timeout) would never actually apply
        # here without passing `timeout=` explicitly on both branches too.
        client = (
            anthropic.Anthropic(
                api_key=settings.anthropic_api_key, timeout=DEFAULT_TIMEOUT_SECONDS
            )
            if settings.anthropic_api_key
            else anthropic.Anthropic(timeout=DEFAULT_TIMEOUT_SECONDS)
        )
        return AnthropicProvider(client=client, model=settings.anthropic_model)
    # Unreachable given Settings.llm_provider's Literal type, but a runtime
    # guard costs nothing and gives a clear message if that type is ever
    # loosened without updating this function.
    raise ValueError(
        f"Unknown LLM_PROVIDER {settings.llm_provider!r}; "
        "expected 'gemini' or 'anthropic'"
    )
