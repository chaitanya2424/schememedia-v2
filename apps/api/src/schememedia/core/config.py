"""Application configuration.

Loaded once at import time from environment variables and an optional .env file.
Validation failures raise at startup rather than surfacing as 500s at request
time -- v1 read `os.getenv("DATABASE_URL", "")`, never loaded a .env, and every
endpoint failed with "Database pool not initialized".
"""

from __future__ import annotations

from functools import lru_cache
from typing import Annotated, Literal
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

from pydantic import Field, PostgresDsn, field_validator
from pydantic_settings import BaseSettings, NoDecode, SettingsConfigDict

Environment = Literal["local", "test", "staging", "production"]


def _translate_libpq_ssl_params(url: str) -> str:
    """Rewrite libpq-style `sslmode`/`channel_binding` query params into
    what asyncpg's SQLAlchemy dialect actually accepts.

    Providers that hand out ready-to-paste connection strings (Neon
    included) format them for libpq/psycopg -- `?sslmode=require&
    channel_binding=require`. SQLAlchemy's asyncpg dialect passes a URL's
    query string straight through as **kwargs to `asyncpg.connect()`,
    which has no `sslmode` or `channel_binding` parameter (only `ssl`,
    which happens to accept the same mode names -- see asyncpg's
    `SSLMode`) -- so an unmodified provider connection string fails
    before ever reaching the network with `TypeError: connect() got an
    unexpected keyword argument 'sslmode'`. `channel_binding` has no
    asyncpg equivalent at all and is simply dropped; the connection is
    still fully TLS-encrypted and SCRAM-authenticated via `ssl=require`.
    """
    split = urlsplit(url)
    query = dict(parse_qsl(split.query))
    if "sslmode" in query:
        query["ssl"] = query.pop("sslmode")
    query.pop("channel_binding", None)
    return urlunsplit(split._replace(query=urlencode(query)))


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
    )

    # ---------- Application ----------
    app_name: str = "SchemeMedia API"
    app_env: Environment = "local"
    debug: bool = False
    api_v1_prefix: str = "/api/v1"

    # ---------- Database ----------
    # Required. No default -- a missing value must stop the process, not
    # produce a half-initialised app.
    database_url: PostgresDsn

    db_pool_size: int = 10
    db_max_overflow: int = 5
    db_pool_timeout_seconds: int = 30
    db_pool_recycle_seconds: int = 1800
    db_echo: bool = False

    # Neon (and any PgBouncer in transaction mode) cannot use prepared
    # statements. asyncpg fails with a confusing DuplicatePreparedStatementError
    # unless its statement cache is disabled. See docs/adr/0002-database.md.
    db_disable_statement_cache: bool = False

    # ---------- Logging ----------
    log_level: Literal["DEBUG", "INFO", "WARNING", "ERROR"] = "INFO"
    log_json: bool = True

    # ---------- AI assistant (services/assistant.py) ----------
    # Gemini is the default: it has a genuine free tier, so local dev and
    # the test suite never require a paid Anthropic key. See
    # services/providers/__init__.py -- no business logic reads this field
    # directly, only the provider factory.
    llm_provider: Literal["gemini", "anthropic"] = "gemini"
    gemini_api_key: str | None = None
    gemini_model: str = "gemini-3.6-flash"
    anthropic_api_key: str | None = None
    anthropic_model: str = "claude-opus-5"

    # ---------- CORS ----------
    # Explicit origins only. v1 used allow_origins=["*"] together with
    # allow_credentials=True, a combination browsers reject outright.
    #
    # NoDecode is required: without it pydantic-settings tries to JSON-decode
    # any list-typed field read from the environment, so a readable
    # CORS_ORIGINS=http://localhost:3000 in .env crashes at startup before the
    # validator below ever runs.
    cors_origins: Annotated[list[str], NoDecode] = Field(
        default_factory=lambda: ["http://localhost:3000"]
    )

    @field_validator("cors_origins", mode="before")
    @classmethod
    def _split_origins(cls, value: object) -> object:
        """Accept a comma-separated string so .env stays readable."""
        if isinstance(value, str):
            return [origin.strip() for origin in value.split(",") if origin.strip()]
        return value

    @property
    def is_production(self) -> bool:
        return self.app_env == "production"

    @property
    def sqlalchemy_url(self) -> str:
        """Force the asyncpg driver regardless of how the URL was supplied."""
        url = str(self.database_url)
        if not url.startswith("postgresql+"):
            url = url.replace("postgresql://", "postgresql+asyncpg://", 1)
        return _translate_libpq_ssl_params(url)


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    """Cached accessor so configuration is parsed exactly once per process."""
    return Settings()
