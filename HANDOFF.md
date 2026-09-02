# SchemeMedia v2 — Handoff Prompt

Give this file to any AI assistant to continue the project. Upload it together
with the current project folder (or a zip of it).

Everything below is established fact or an approved decision — not a starting
suggestion. Section 9 is the only open work.

---

# PART A — SHORT KICKOFF (paste this if the model has a small context window)

> I'm building **SchemeMedia v2**, a rebuild of a government-scheme discovery
> platform for India. Stack: **Python 3.12 + FastAPI + PostgreSQL 16 +
> pgvector**, SQLAlchemy 2.0 async + Alembic. I develop natively on **Windows
> with no Docker**.
>
> Phases 1 (foundation) and 2 (database schema) are **complete and tested** —
> 23 passing tests against real PostgreSQL. I'm now on **Phase 3: data
> ingestion** — loading 1,000 schemes from `schemes.json` into the database.
>
> The attached `HANDOFF.md` has the full context: architecture, approved
> decisions, data-quality findings, and the exact Phase 3 specification.
> **Read it before writing any code.** Do not redesign what is already built
> and tested. Do not add Docker requirements.
>
> Work in this order: understand → propose → implement → test → report.
> Never mark something complete without running it.

---

# PART B — FULL CONTEXT

## 1. How I want you to work

You are acting as a **senior software architect and full-stack engineer**.

**Rules, in priority order:**

1. **Verify by executing, never by reading.** If you can run code, run it. If
   you cannot, give me exact commands and ask me to paste the output. A file
   that looks correct is not a file that works.
2. **Do not rewrite working, tested code.** Phases 1–2 are done. Touch them
   only to fix a demonstrated bug.
3. **Do not add Docker as a requirement.** I develop natively on Windows.
   Docker exists in the repo for CI and deployment only.
4. **Do not invent facts.** No fabricated APIs, schema columns, file paths, or
   library behaviour. If something is undetermined, say `ASSUMPTION REQUIRED`,
   state the options, and recommend one.
5. **Never hardcode secrets.** Everything through environment variables.
6. **Report in this shape:** what you discovered → what you changed → how you
   verified it → what's next. When something breaks:
   **Problem → Root Cause → Fix → Verification.**
7. **Work in phases.** Finish and test one before starting the next.
8. **Tell me when you disagree with me.** I would rather be corrected than
   agreed with. If a decision below looks wrong, argue it.

If you cannot execute code, say so up front and give me commands to run instead
of claiming things work.

## 2. What the product is

A discovery platform for Indian government welfare schemes. India runs
thousands of central and state schemes; citizens don't know which exist or
which they qualify for. The product makes discovery feel like a social feed
rather than a government portal.

Target user: a citizen on a low-end Android phone, often with limited English.
Mobile-first, bilingual (English + Hindi).

**Three discovery mechanisms:**
1. **Eligibility-matched feed** — a profile of ~25 attributes (farmer, SC/ST,
   BPL, income band, rural, disability…) matched against per-scheme rules
2. **Hybrid search** — pgvector semantic search fused with PostgreSQL full-text
3. **RAG chatbot** — retrieves nearest schemes, grounds an LLM on them

Plus a social layer: likes, saves, 1–5 ratings, threaded comments, reports,
notifications.

## 3. Why this is a rebuild

v1 existed and did not work. The audit found:

- **No database schema anywhere** — no SQL, no migrations, no models. The
  recommendation feed depended on a SQL function `user_matches_scheme` that was
  never committed.
- **Live credentials hardcoded** in five files (Neon database password, Gemini
  API key), in a public repo. **Both have been rotated.**
- **`.env` never loaded** — code read `os.getenv` with no dotenv and no
  dependency, so every endpoint returned 500.
- **Connection pool poisoning** — sessions never committed or rolled back, so
  connections returned to the pool mid-transaction and later requests failed
  with `current transaction is aborted`.
- **No authentication at all** — user identity was a text box in the header.
  Anyone could rewrite anyone's profile, including caste and income data.
- **Fake implementations** — `POST /comment` and `POST /report` returned
  success and wrote nothing; the UI rendered comments optimistically, so users
  lost data and were told it saved. `POST /rate` was called by the frontend and
  **did not exist**.
- **Frontend** was HTML string concatenation with incomplete escaping, broken
  click handlers, and no routing (so no deep links and no SEO).

## 4. Approved decisions — do not relitigate without new evidence

| # | Decision |
|---|---|
| **Fresh database** | Nothing in the old Neon DB is worth preserving. Designed from scratch. |
| **Eligibility semantics** | `false` and `null` in the source data both mean **"not a requirement"** and produce no rule. See §5. |
| **Eligibility never hides a scheme** | It is a *ranking signal* plus an optional user-toggled filter. Rationale in §6 — this is a safety decision, not a preference. |
| **Auth** | Email + password, JWT access (15 min) + rotating refresh token in an httpOnly cookie, Argon2id hashing. Behind an interface so phone/OTP can be added. |
| **Roles** | anonymous / user / moderator / admin |
| **Languages** | English + Hindi at launch, i18n-ready |
| **Scheme IDs** | Original `scheme_id` values preserved from the source dataset |
| **Comments** | Public immediately, reactive moderation via reports |
| **Dropped** | A `TweetRequest` social-post feature from v1 — no endpoint, no table, no UI |
| **Frontend framework** | **STILL OPEN.** Next.js is recommended (SEO is the acquisition channel for a public-information product). Not needed until Phase 9. |

**Stack, settled:**

Backend: Python 3.12, FastAPI, SQLAlchemy 2.0 async + asyncpg, Alembic,
pydantic-settings, structlog, PostgreSQL 16 + pgvector.
Embeddings: `all-MiniLM-L6-v2` (384-dim) via **fastembed** (ONNX — no PyTorch;
image ~200 MB instead of ~1 GB, cold start ~2 s instead of ~30 s).
LLM: **google-genai** SDK behind an adapter — the old `google-generativeai`
SDK's support ended 30 November 2025 and `gemini-1.5-flash` is retired.
Testing: pytest + httpx + real PostgreSQL. Lint/format: ruff. Types: mypy.

**Deliberately excluded** (do not add): Redis, Celery, Elasticsearch,
Kubernetes, GraphQL, microservices. All defensible at 10× the traffic, all dead
weight now. Cache and LLM sit behind interfaces so they can be swapped later.

## 5. Data-quality findings — these drive the design

I measured `schemes.json` (1,000 records) rather than trusting it. **These are
verified numbers, not guesses.** They constrain what is achievable:

- **All 1,000 `description_short` values are the same generated template**,
  with only the scheme name substituted. Embedding them yields 1,000
  near-identical vectors — semantic search becomes title-matching with extra
  steps. **Therefore embed `name + category + tags + benefits + ministry`, not
  the description.**
- **633 of 1,000 benefit strings are truncated mid-word** at ~200 characters,
  e.g. `"...a scroll of honor, and a blazer with a tie shall be "`. Flag these
  rather than presenting them as complete.
- **997 of 1,000 `documents_required` arrays contain one unsplit blob** —
  median 307 characters, max 8,155. Split them; flag anything unsplittable.
- **No `official_url` field exists.** For a scheme-discovery product this is
  arguably the most valuable missing field. Schema has a column ready for it.
- **Eligibility flags are generator defaults, not assertions.** In
  `must_match_all`: **8,651 `false` values against 349 `true`** (25:1), and
  **709 of 1,000 schemes have every boolean set to `false`**. Reading `false`
  as "must be false" would require a user to be simultaneously not-a-farmer,
  not-a-taxpayer, not-a-government-employee and homeless to qualify for a
  journalism award. Hence the decision in §4.
- **80 schemes have no `true` in `must_match_one_of`** — under a strict OR rule
  they match nobody, ever. (Separately, **53 schemes yield no rules at all**.)
- `is_sc_st` is true on 758/1,000 and `is_lig` on 511 — the feed would be
  dominated by caste and income gating.

**Consequence:** the dataset is a scaffold, not truth. Ingestion must be
re-runnable, provenance must be visible in the UI, and users must be able to
report outdated data.

## 6. Why eligibility ranks instead of filters

Telling a citizen they don't qualify for a welfare benefit — based on
machine-generated rules of unknown provenance, in a dataset where 80 schemes
match nobody — is a real harm, not a UX inconvenience.

The design is "**You may be eligible** — here's why", with the matched rule
labels shown and a link to the official portal. A mis-mapped rule can then only
mis-rank a scheme; it can never hide one from someone who qualifies.

**Do not change this to a hard filter.**

## 7. What is already built and tested

**Phase 1 — Foundation (complete).** Application factory, typed config that
fails at boot on a missing secret, structlog JSON logging with request IDs,
consistent error envelope that never leaks internals, `/health` (no
dependencies) and `/ready` (checks the database, returns 503 when degraded),
CORS from config, session dependency that always commits or rolls back.

**Phase 2 — Schema (complete).** 16 tables, 50 indexes, 9 enums, 4 triggers.
Two Alembic migrations. `upgrade head` → `downgrade base` → `upgrade head`
verified twice and enforced in CI.

**Status: 23 tests passing** against real PostgreSQL 16 + pgvector. ruff clean,
mypy strict clean.

```
schememedia/
├── scripts/dev.py                    cross-platform task runner (no Docker)
├── docs/adr/                         architecture decision records
├── .env.example  .gitattributes  docker-compose.yml (optional)
└── apps/api/
    ├── migrations/versions/          initial_schema, counter_triggers
    ├── pyproject.toml
    └── src/schememedia/
        ├── main.py                   app factory, no business logic
        ├── core/                     config, logging, errors, middleware, deps
        ├── db/session.py             engine + session lifecycle
        ├── db/models/                base, enums, user, scheme, interaction, content
        └── api/v1/routers/health.py
```

**Layering rule: routers → services → repositories → database.** Routers
validate and delegate. Business logic in services. SQL in repositories. Nothing
skips a layer. Services take repositories by injection so they unit-test
against fakes.

### Schema highlights

**`scheme_eligibility_rules`** is the central design change. v1 kept rules in an
opaque JSONB blob; they are now rows:

```
scheme_id, rule_group ('all'|'any'), attribute_key, operator ('eq'|'gte'|'lte'),
value_bool | value_numeric | value_text  (exactly one, CHECK-enforced),
label, label_hi
```

This makes matching a join, lets an admin correct a bad rule, and — because
every rule carries a `label` — lets the API answer *"why did this match?"*.
A CHECK constraint restricts `attribute_key` to a known vocabulary, so an
importer typo fails at insert instead of creating an unmatchable rule.

**Other decisions:**
- Likes / saves / ratings are **three tables**, not one overloaded table.
  Composite PKs make double-likes impossible; `CHECK (rating BETWEEN 1 AND 5)`.
- **Denormalised counters** on `schemes` (`like_count`, `save_count`,
  `comment_count`, `rating_sum`, `rating_count`) maintained by **triggers** —
  v1 ran correlated subqueries per scheme per request.
- Ratings store **sum and count**, not an average, so updates are O(1).
- `search_vector` is a **generated** `tsvector` (GIN indexed) — it cannot drift.
- `embedding vector(384)` with an **HNSW** index (`vector_cosine_ops`).
- `raw_eligibility` JSONB preserves the original blob for audit.
- `user_profiles` has its own PK plus a **unique** `user_id` — one-to-one today,
  but relaxing to household profiles later means dropping one constraint rather
  than restructuring a table.

### Two Alembic gaps already worked around — don't "fix" them again

1. Autogenerate **omits the `pgvector` import**; the migration adds it manually.
2. Alembic **never drops enum types on downgrade**, so `downgrade base` then
   `upgrade head` failed with `DuplicateObjectError`. Explicit `DROP TYPE`
   statements were added.

### Bugs already found and fixed — do not reintroduce

- Module-level `app = create_app()` broke settings injection → use
  `uvicorn schememedia.main:create_app --factory`
- A route calling global `get_settings()` instead of the injected settings →
  use the `SettingsDep` dependency
- `Index(..., func.now().desc())` where `text("created_at DESC")` was meant →
  PostgreSQL rejects non-immutable index expressions
- `CORS_ORIGINS=http://localhost:3000` in `.env` crashed at boot —
  pydantic-settings JSON-decodes `list[str]` before validators run → fixed with
  the `NoDecode` annotation
- A test passing for the wrong reason because `DATABASE_URL` was exported →
  suppress both the env file **and** the process environment

## 8. My environment — respect these constraints

- **Windows laptop, no Docker** (insufficient storage). Native development only.
- Python 3.12+, PostgreSQL 16 installed locally, pgvector compiled with
  Visual Studio Build Tools + `nmake /F Makefile.win`.
- Everything runs through `python scripts/dev.py <command>`:
  `doctor`, `init-db`, `migrate`, `test`, `check`, `run`, `reset-db`.
- `dev.py` is plain Python — no make, no bash — and talks to PostgreSQL via
  asyncpg rather than shelling out to `psql`, because `psql` is often not on
  PATH on Windows. It reads `.env` itself.
- **Never** tell me to add pgvector to `shared_preload_libraries`. It is wrong
  and stops PostgreSQL from starting. Several blog posts say to; they're wrong.

**Give me PowerShell-compatible commands.** No `&&` chaining, no `export`, no
`source`.

## 9. NEXT TASK — Phase 3: Ingestion

Build a re-runnable importer that loads `schemes.json` (1,000 records) into the
database, plus an embedding generator.

**Deliverables**

1. `apps/api/src/schememedia/cli/import_schemes.py`
   - Idempotent: upsert on `scheme_id`, safe to run repeatedly
   - Map the free-text `category` column onto proper `categories` rows
   - Normalise ~1,470 freeform tags into `tags` + `scheme_tags`
   - Split the 997 single-blob document strings; flag unsplittable ones
     `needs_review`
   - Parse benefits into `scheme_benefits`; set `is_truncated` on the 633
     truncated strings
   - Translate `eligibility_json` into `scheme_eligibility_rules` under the
     approved semantics (§4, §5) — expect **2,622 rules**
     (must_match_all: 349 true + 250 numeric = 599; must_match_one_of:
     1,812 true + 211 numeric = 2,023). Median 2 per scheme, max 8, and
     **53 schemes yield zero rules**
   - Preserve the original blob in `schemes.raw_eligibility`
   - Generate a URL-safe unique `slug` per scheme
   - Handle the state/jurisdiction CHECK constraint: a `state` scheme requires
     `state_code` (594/1,000 records have one)

2. `apps/api/src/schememedia/cli/generate_embeddings.py`
   - **fastembed**, model `all-MiniLM-L6-v2`, 384 dimensions
   - Embed `name + category + tags + benefits + ministry` — **not** the
     boilerplate description (§5)
   - Batched, resumable, only rows where `embedding IS NULL` unless `--force`

3. **A data-quality report** printed at the end: rules created, documents
   split vs. flagged, benefits truncated, schemes missing `official_url`,
   schemes that would match nobody.

4. **Tests** in `apps/api/tests/test_import.py` — idempotency (import twice,
   same row counts), rule translation correctness, document splitting,
   truncation detection.

5. Wire both into `scripts/dev.py` as `import-data` and `embed`.

**Approach:** propose the design first — especially the document-splitting
heuristic and the eligibility-key mapping — and let me approve before you write
the full implementation.

## 10. Roadmap after Phase 3

4. Auth (register, login, refresh, RBAC)
5. Core read API (schemes, categories, hybrid search via **Reciprocal Rank
   Fusion**, not the arithmetically unsound formula v1 used)
6. Eligibility matching + match explanations
7. Social features (likes, saves, ratings, comments, reports, notifications)
8. AI assistant (chat with memory, citations, rate limits, graceful degradation)
9. Frontend foundation — **framework decision needed here**
10. Frontend features
11. Admin (scheme CRUD, report queue)
12. Hardening (security review, a11y audit, load test, Playwright E2E)
13. Deployment

## 11. Feature ideas already discussed, not yet approved

Worth folding in early **because they affect the schema**: household profiles
(one account, multiple eligibility profiles — matches how Indian families
actually make these decisions); a document wallet (tick off documents you hold →
"you have 4 of 5 required"); shareable scheme URLs with WhatsApp OpenGraph cards.

Later, no schema impact: read-aloud via `SpeechSynthesis` (works in Hindi),
voice search, "explain simply" mode, anonymous quick eligibility check,
near-miss explanations ("add your income to match 12 more"), zero-result query
logging for catalogue gaps, PWA offline access to saved schemes.

**Deliberately excluded:** document OCR of Aadhaar / income certificates
(materially different DPDP Act compliance posture), government API integration
(mostly doesn't exist), and the chatbot drafting actual applications
(hallucination risk on a document submitted to a government office).

## 12. Non-negotiables

- **DPDP Act 2023** applies — this handles caste, disability, income, and
  pregnancy data. Collect only what eligibility needs, every field optional,
  encrypted in transit and at rest, explicit consent, data export and account
  deletion, no sensitive fields in logs.
- **Always link the official government source.** Never let the product be the
  final authority on a benefit.
- **Show provenance** — `data_source`, `last_verified_at`, and a visible
  disclaimer that the data is unofficial and must be verified.
- **Accessibility is a product requirement**, not polish. WCAG 2.1 AA.
