"""LLM provider construction: request timeouts.

Audit finding H1: an unconfigured Gemini/Anthropic client has no request
timeout at all (Gemini: none; Anthropic SDK default: several minutes). The
assistant route runs both provider calls inside one `run_in_threadpool`
call on the same threadpool search/recommendations/scheme-detail also use
-- a hung LLM request blocks that worker thread indefinitely, and enough of
them exhausts the whole pool and stalls unrelated endpoints. These tests
only verify a finite timeout reaches the constructed SDK client -- they
never call the network, matching core/deps.py's own note that constructing
a provider makes no network call.
"""

from __future__ import annotations

import anthropic
import pytest
from google import genai

from schememedia.core.config import Settings
from schememedia.services.providers import get_provider
from schememedia.services.providers.anthropic_provider import (
    DEFAULT_TIMEOUT_SECONDS as ANTHROPIC_DEFAULT_TIMEOUT_SECONDS,
)
from schememedia.services.providers.anthropic_provider import AnthropicProvider
from schememedia.services.providers.gemini_provider import (
    DEFAULT_TIMEOUT_MS as GEMINI_DEFAULT_TIMEOUT_MS,
)
from schememedia.services.providers.gemini_provider import GeminiProvider


def _database_url_only(**overrides: object) -> Settings:
    return Settings(database_url="postgresql://u:p@localhost:5432/db", **overrides)  # type: ignore[arg-type]


class TestGeminiProviderTimeout:
    def test_default_construction_sets_a_finite_timeout(self) -> None:
        provider = GeminiProvider(api_key="dummy-key")
        client: genai.Client = provider._client
        assert client._api_client._http_options.timeout == GEMINI_DEFAULT_TIMEOUT_MS

    def test_timeout_is_overridable(self) -> None:
        provider = GeminiProvider(api_key="dummy-key", timeout_ms=5_000)
        client: genai.Client = provider._client
        assert client._api_client._http_options.timeout == 5_000

    def test_an_explicitly_supplied_client_is_used_as_is(self) -> None:
        """Constructor-injected clients (as tests elsewhere use) are never
        second-guessed or reconfigured -- only the *default* construction
        path gets the timeout applied.
        """
        client = genai.Client(api_key="dummy-key")
        provider = GeminiProvider(client=client)
        assert provider._client is client


class TestAnthropicProviderTimeout:
    def test_default_construction_sets_a_finite_timeout(self) -> None:
        provider = AnthropicProvider()
        client: anthropic.Anthropic = provider._client
        assert client.timeout == ANTHROPIC_DEFAULT_TIMEOUT_SECONDS

    def test_timeout_is_overridable(self) -> None:
        provider = AnthropicProvider(timeout_seconds=5.0)
        client: anthropic.Anthropic = provider._client
        assert client.timeout == 5.0

    def test_an_explicitly_supplied_client_is_used_as_is(self) -> None:
        client = anthropic.Anthropic(api_key="dummy-key")
        provider = AnthropicProvider(client=client)
        assert provider._client is client


class TestGetProviderFactoryAppliesTimeouts:
    """Regression coverage for the actual bug: get_provider()'s Anthropic
    branch always constructs its own client and passes it in explicitly, so
    AnthropicProvider's own default-timeout fallback path never ran for a
    provider built the way the real app builds one. Gemini's factory branch
    never passed a client, so it was never affected the same way -- both
    are covered here so a future regression on either provider is caught.
    """

    def test_gemini_provider_from_settings_has_a_timeout(self) -> None:
        settings = _database_url_only(llm_provider="gemini", gemini_api_key="dummy-key")
        provider = get_provider(settings)
        assert isinstance(provider, GeminiProvider)
        client: genai.Client = provider._client
        assert client._api_client._http_options.timeout == GEMINI_DEFAULT_TIMEOUT_MS

    @pytest.mark.parametrize("api_key", ["dummy-key", None])
    def test_anthropic_provider_from_settings_has_a_timeout(
        self, api_key: str | None
    ) -> None:
        settings = _database_url_only(llm_provider="anthropic", anthropic_api_key=api_key)
        provider = get_provider(settings)
        assert isinstance(provider, AnthropicProvider)
        client: anthropic.Anthropic = provider._client
        assert client.timeout == ANTHROPIC_DEFAULT_TIMEOUT_SECONDS
