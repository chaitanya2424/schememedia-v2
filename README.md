# SchemeMedia v2

Discovery platform for Indian government welfare schemes — semantic search,
eligibility matching, and a grounded AI assistant.

> **Rebuild in progress.** See `REBUILD_PLAN.md` for the full specification,
> architecture, and roadmap. Phases 1 (foundation) and 2 (schema) are complete.

**Docker is optional.** The supported default is native local development
against a normal PostgreSQL installation. See the three sections below.

---

# 1. Native local development (recommended)

Works on Windows, macOS, and Linux. Requires no containers.

## 1.1 Prerequisites

| | |
|---|---|
| Python 3.12+ | https://www.python.org/downloads/ — tick **"Add python.exe to PATH"** |
| PostgreSQL 16+ | https://www.postgresql.org/download/ — remember the password you set |
| pgvector | see 1.2 below |
| Git | https://git-scm.com/downloads |

## 1.2 Installing pgvector

Linux and macOS have packages:

```bash
sudo apt install postgresql-16-pgvector      # Debian / Ubuntu
brew install pgvector                        # macOS
```

**On Windows there is no installer — pgvector must be compiled.** It is a
one-time, roughly fifteen-minute job:

1. Install **Visual Studio Build Tools** and select the
   **"Desktop development with C++"** workload.
   https://visualstudio.microsoft.com/downloads/
2. Open **"x64 Native Tools Command Prompt for VS"** — *as Administrator*.
   This specific prompt matters; a normal PowerShell window fails with
   `nmake is not recognized`.
3. Run:

   ```bat
   set "PGROOT=C:\Program Files\PostgreSQL\16"
   cd %TEMP%
   git clone --branch v0.8.0 https://github.com/pgvector/pgvector.git
   cd pgvector
   nmake /F Makefile.win
   nmake /F Makefile.win install
   ```

> **Do not add pgvector to `shared_preload_libraries`.** Several blog posts
> tell you to. It is wrong, and PostgreSQL will refuse to start. `CREATE
> EXTENSION vector` is all that is needed, and `dev.py init-db` does it for you.

Troubleshooting, from the pgvector project:

- `error C2196: case value '4' already used` → you are not in the x64 Native
  Tools prompt. Run `nmake /F Makefile.win clean` and start again.
- `Access is denied` → the prompt is not running as Administrator.
- Linking error mentioning `float_to_shortest_decimal_bufn` on PostgreSQL
  17.0–17.2 → upgrade to 17.3+.

## 1.3 Set up the project

```powershell
git clone <your-repo-url>
cd schememedia

python -m venv .venv
.venv\Scripts\Activate.ps1          # PowerShell
# .venv\Scripts\activate.bat        # cmd
# source .venv/bin/activate         # macOS / Linux

cd apps\api
pip install -e ".[dev]" -c constraints.txt
cd ..\..

copy .env.example .env              # cp on macOS / Linux
```

Edit `.env` and set `DATABASE_URL` to your PostgreSQL password and port.

## 1.4 Verify, then build the database

```bash
python scripts/dev.py doctor        # checks everything, explains any problem
python scripts/dev.py init-db       # creates both databases, enables extensions
python scripts/dev.py migrate       # applies migrations to dev and test
python scripts/dev.py test          # 23 tests should pass
python scripts/dev.py run           # http://localhost:8000/docs
```

**Run `doctor` first whenever something is wrong.** It checks the Python
version, virtual environment, installed packages, `.env`, PostgreSQL
connectivity, pgvector availability and version, and whether both databases
exist — and prints the exact fix for whatever is missing, including the
Windows pgvector build steps.

## 1.5 All developer commands

| Command | |
|---|---|
| `python scripts/dev.py doctor` | diagnose the environment |
| `python scripts/dev.py init-db` | create databases, enable extensions |
| `python scripts/dev.py migrate` | apply migrations to dev **and** test |
| `python scripts/dev.py test` | run the suite (extra args pass to pytest) |
| `python scripts/dev.py check` | ruff lint, format check, mypy |
| `python scripts/dev.py run` | start the API with reload |
| `python scripts/dev.py reset-db` | drop and rebuild both databases |

`dev.py` is plain Python — no make, no bash, no Docker — so it behaves
identically in PowerShell, cmd, and a POSIX shell. It talks to PostgreSQL
through asyncpg rather than shelling out to `psql`, so PostgreSQL's client
tools do not need to be on your `PATH`.

It reads `.env` itself, so you never need to export variables in a new shell.

## 1.6 Common Windows problems

| Symptom | Cause and fix |
|---|---|
| `Cannot connect to PostgreSQL: ConnectionRefusedError` | The service is stopped. Services → `postgresql-x64-16` → Start. |
| `password authentication failed` | `DATABASE_URL` in `.env` disagrees with the password set during installation. |
| `type "vector" does not exist` | pgvector compiled but not enabled. Run `python scripts/dev.py init-db`. |
| `pgvector is not installed on this PostgreSQL server` | The build did not reach `nmake install`, or it targeted a different PostgreSQL version. Check `PGROOT`. |
| `running scripts is disabled on this system` | PowerShell policy. Run `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`. |
| Port 5432 already in use | An older PostgreSQL is installed. Point `DATABASE_URL` at the right port. |

---

# 2. Optional Docker development

Kept for developers who prefer containers, and reused by CI. **Not required.**

```bash
cp .env.example .env
docker compose up --build
```

This starts `pgvector/pgvector:pg16` (pgvector is prebuilt there — no
compilation) alongside the API. Migrations still run through Alembic:

```bash
docker compose exec api alembic upgrade head
```

The application is identical either way. Nothing in the codebase depends on
containers, and the schema targets a standard PostgreSQL + pgvector server.

---

# 3. Production / deployment

The API ships as a container image (`apps/api/Dockerfile`: multi-stage,
non-root, with a health check) and runs anywhere that accepts one — Fly.io,
Render, Railway, ECS, or a plain VM.

```bash
docker build -t schememedia-api ./apps/api
docker run -e DATABASE_URL=... -p 8000:8000 schememedia-api
```

**Deployment checklist**

- `APP_ENV=production` — disables `/docs` and `/openapi.json`
- `LOG_JSON=true` — structured logs for aggregation
- `CORS_ORIGINS` — your real frontend origin, never `*`
- Run `alembic upgrade head` as a release step, before traffic is served
- Point liveness checks at `/health`, readiness at `/ready`
- Database credentials from the platform's secret store, never an image layer

### Rate limiting

Every route is rate-limited per client IP (`core/rate_limit.py`), in-memory by
default — correct for a single instance; pass `storage_uri="redis://..."` to
the `Limiter` there the moment a second instance is added, no other code
changes.

| Route | Limit | Why |
|---|---|---|
| `POST /api/v1/assistant/message` | **5/minute** | Strictest — Gemini's free-tier daily quota (20 requests/day) can be exhausted by a single burst |
| `POST /api/v1/recommendations` \| `/recommendations/me` | 20/minute | Database-only, still bounded |
| `GET /api/v1/search` | 30/minute | Database-only, the cheapest call |
| `GET /api/v1/schemes/{identifier}` | 30/minute | |
| `POST /api/v1/auth/login` | 10/minute | Bounds password-guessing |
| `POST /api/v1/auth/register` | 5/minute | Bounds account-creation abuse |
| `POST /api/v1/auth/refresh` | 20/minute | Routine, but still bounded |

A request over its route's limit gets `429` in the same `{"error": {...}}`
envelope as every other error, plus a `Retry-After` header. Request bodies
over 100KB (`main.py`'s `MAX_REQUEST_BODY_BYTES` — every real payload this
API accepts is well under 10KB) get `413`, same envelope.

### Assistant usage/cost guardrails

The 5/minute limit above only bounds *burst rate* — sustained, it still
allows up to 7,200 requests/day from one client, far past a ~20/day free
tier. `core/assistant_guard.py` adds three more layers, all configurable via
`.env` (see `.env.example`), all in-memory/per-process like the rate limiter
above (same Redis upgrade path if a second instance is ever added):

| Guard | Env var | Default | Behaviour |
|---|---|---|---|
| Kill switch | `ASSISTANT_ENABLED` | `true` | `false` stops every assistant call instantly (one env var + redeploy, no code change) — `503 assistant_disabled`, provider never called. |
| Daily volume cap | `ASSISTANT_DAILY_LIMIT` | `20` | A process-wide count of calls since the last UTC midnight. Once reached: `503 assistant_quota_exceeded`, provider never called for that request. Not refunded on a failed call — a failed call still spent real provider quota. |
| Response cache | `ASSISTANT_CACHE_TTL_SECONDS` | `120` | An identical (exact, whitespace-trimmed) question within the TTL is served from cache — no provider call, and does not count against the daily cap. `0` disables caching. |

Every turn also logs a structured `assistant_turn_completed` (or
`_failed`/`_blocked`/`_daily_quota_exceeded`) event — `core/logging.py` —
carrying today's running count, per-model-call latency, total turn latency,
cache-hit status, and grounding-warning count, so usage is visible from logs
alone without a separate metrics stack.

### Authentication

Bearer tokens (`core/security.py`), not cookies -- identical on Flutter Web
and a future native Android client, no CSRF surface to defend.

- **Access token** -- HS256-signed JWT, `JWT_ACCESS_TOKEN_EXPIRE_MINUTES`
  (default 15). Verified from its signature alone, no database hit per
  request. Send it as `Authorization: Bearer <token>`.
- **Refresh token** -- opaque random string, **not** a JWT,
  `JWT_REFRESH_TOKEN_EXPIRE_DAYS` (default 30). Only its SHA-256 hash is
  ever stored (`refresh_tokens.token_hash`) -- a database leak alone
  cannot yield a usable token. Rotated on every use; presenting an
  already-rotated/revoked token is treated as theft and revokes every
  active token for that user.
- `JWT_SECRET_KEY` **must** be set to a real secret before
  `APP_ENV=production` -- the app refuses to start with the checked-in
  default otherwise (`core/config.py`).

| Route | Auth | Notes |
|---|---|---|
| `POST /api/v1/auth/register` \| `/login` \| `/refresh` \| `/logout` | — | `/logout` and a bad `/refresh` still 204/401 cleanly for an unknown token |
| `GET /api/v1/auth/me` | required | the signed-in account |
| `GET`/`PUT /api/v1/me/profile` | required | the eligibility profile, see below |
| `GET`/`POST`/`DELETE /api/v1/me/saved-schemes[/{scheme_id}]` | required | bookmarks; saving an unknown `scheme_id` is `404`, a duplicate save is a no-op |
| `POST /api/v1/recommendations/me` | required | same `RecommendationService` as the public endpoint, profile always read server-side from `/me/profile` -- the request body has no `profile` field, so nothing a client sends there can override it |

**The eligibility profile reuses the exact vocabulary the eligibility
engine already uses** (`EligibilityAttribute`, `db/models/enums.py`) --
`UserProfile`'s columns are literally named after it
(`services/user_profile.py` converts between the two generically, no
second attribute system). An unanswered attribute is `null`, never
coerced to `false`; a `PUT` is a partial update -- a key present with
value `null` clears it back to unknown, a key not present is left alone.

### Connecting to Neon or another pooled PostgreSQL

Set `DB_DISABLE_STATEMENT_CACHE=true` when using a **pooled** endpoint.
PgBouncer in transaction mode cannot support prepared statements, and asyncpg
otherwise fails intermittently with `DuplicatePreparedStatementError`.

Use the **direct** (non-pooled) endpoint for migrations.

Paste the provider's connection string as-is, `sslmode`/`channel_binding` and
all -- `Settings.sqlalchemy_url` (`core/config.py`) translates them into what
asyncpg actually accepts. Neon's copy-paste string is shaped for
libpq/psycopg (`?sslmode=require&channel_binding=require`); SQLAlchemy's
asyncpg dialect forwards a URL's query string straight through as `**kwargs`
to `asyncpg.connect()`, which has no `sslmode` or `channel_binding`
parameter -- only `ssl` -- so an untranslated string fails before ever
reaching the network with `TypeError: connect() got an unexpected keyword
argument 'sslmode'`.

---

# Project layout

```
schememedia/
├── scripts/dev.py       cross-platform task runner
├── docs/adr/            architecture decision records
├── docker-compose.yml   optional
└── apps/api/
    ├── migrations/      Alembic — the only source of schema truth
    └── src/schememedia/
        ├── main.py      application factory, no business logic
        ├── core/        config, logging, errors, middleware, dependencies
        ├── db/          engine, session, models
        └── api/v1/routers/
```

Layering rule: **routers → services → repositories → database**. Routers
validate and delegate; business logic lives in services; SQL lives in
repositories. Nothing skips a layer.

# Migrations

```bash
python scripts/dev.py migrate                       # apply to dev and test
cd apps/api && alembic downgrade base               # reverse (verified in CI)
cd apps/api && alembic revision --autogenerate -m "description"
```

The schema is defined only by migrations. `alembic.ini` deliberately has no
`sqlalchemy.url`; it comes from application settings via `migrations/env.py`,
so migrations and the running app can never target different databases.

Autogenerate has two known gaps this project works around, both documented in
the initial migration: it omits the `pgvector` import, and it never drops enum
types on downgrade.

# Tests

```bash
python scripts/dev.py test              # everything
python scripts/dev.py test -q -k schema # arguments pass through to pytest
```

Schema tests run against a **real** PostgreSQL with pgvector — check
constraints, triggers, and generated columns are database behaviour, and
testing them against a mock would prove nothing. They skip automatically when
no database is configured, so the unit tests still run standalone.

The test database URL defaults to `DATABASE_URL` with a `_test` suffix; set
`TEST_DATABASE_URL` in `.env` to override.

# Configuration

All settings come from environment variables, validated at startup by
`core/config.py`. A missing required value stops the process immediately rather
than surfacing as a 500 later.

Secrets are never committed. `.env` is gitignored; `.env.example` documents
every key with placeholder values.

# Conventions

**Error responses** share one envelope:

```json
{
  "error": {
    "code": "not_found",
    "message": "The requested resource was not found.",
    "request_id": "9c041dec32a14bdaa942be6d36b02193"
  }
}
```

Unexpected exceptions are logged in full and returned as a generic message —
internal detail is never exposed to clients.

**Request tracing.** Every response carries `X-Request-ID`, and every log line
for that request includes it. An inbound `X-Request-ID` is honoured so a trace
can span frontend and API.

**Health vs. readiness.** `/health` has no dependencies and reflects only
whether the process is alive. `/ready` checks dependencies and returns 503 when
they are unavailable. Keeping them separate prevents restart loops when the
database blips.
