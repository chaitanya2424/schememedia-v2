# SchemeMedia v2 — Rebuild Specification & Architecture Plan

**Status:** Proposal — awaiting approval before any implementation
**Date:** 24 August 2026
**Scope:** Full rebuild, preserving purpose and functionality of SchemeMedia v1

---

# A. Project Understanding

SchemeMedia is a **discovery platform for Indian government welfare schemes**. India runs thousands of central and state schemes; citizens generally don't know which ones exist or which they qualify for. The product's thesis is that discovery should feel like a social feed rather than a government portal — you scroll, filter, like, save, comment, and ask an assistant in plain language.

Three discovery mechanisms exist in v1, and all three should survive the rebuild:

1. **Eligibility-matched feed** — a personalised list driven by a stored profile of ~25 attributes (farmer, SC/ST, BPL card holder, income band, rural, disability status, etc.) matched against per-scheme eligibility rules.
2. **Hybrid search** — semantic vector search (384-dim MiniLM embeddings in pgvector) blended with keyword matching, plus category filtering.
3. **RAG chatbot** — retrieves the top-3 nearest schemes by embedding and passes them to Gemini as grounding context.

A social layer sits on top: likes, saves, 1–5 star ratings, threaded comments, reports, and notifications.

The target user is a citizen with a low-end Android phone and possibly limited English. The UI is mobile-first with a bottom nav, and the hero copy is bilingual (Hindi + English) — a signal that **localisation is a product requirement, not a nice-to-have**.

---

# B. Existing Functionality

## Working end-to-end (assuming a schema exists)

| Feature | Endpoint | Notes |
|---|---|---|
| Personalised feed | `GET /recommendations/{user_id}` | Depends on a missing SQL function `user_matches_scheme` |
| Hybrid search | `GET /schemes/search` | Vector distance minus a flat 0.5 keyword boost |
| Scheme detail | `GET /scheme/{id}` | `SELECT *` — ships the 384-dim embedding to the browser |
| Similar schemes | `GET /scheme/{id}/similar` | Cosine nearest neighbours |
| Like / unlike | `POST /like` | Toggles server-side |
| Save | `POST /save` | Fire-and-forget background task |
| Saved list | `GET /user/{id}/saved` | |
| Profile read/write | `GET`/`PUT /user/{id}/profile` | Backend complete, **no UI** |
| Notifications | `GET /user/{id}/notifications`, `PUT /notifications/{id}/read` | Backend complete, **no UI** |
| RAG chat | `POST /chat` | Retrieval + Gemini |
| Infinite scroll | — | IntersectionObserver, works |

## Declared but non-functional

- **`POST /comment`** — returns `{"message": "Comment added"}` and writes nothing. The UI optimistically renders the comment, so it looks like it worked.
- **`POST /report`** — identical no-op stub.
- **`POST /rate`** — the frontend calls it; **the endpoint does not exist**. Every rating 404s silently.
- **Comments are never read back** — `GET /scheme/{id}` returns no `comments` key, so the list renders "No comments yet" permanently.
- **Profile and Alerts tabs** — hardcoded placeholder strings ("Notifications system active").
- **`TweetRequest`** — a Pydantic model for a social-post feature with no endpoint, no table, no UI. Abandoned scope.
- **Similar-scheme cards** — rendered with `.info-card.explore-btn` but the click handler queries `.card, .similar-card`, a class that exists nowhere. Completely unclickable.

## Not present at all

**The database schema.** No `.sql`, no migrations, no ORM models — and `user_matches_scheme`, the function the entire feed depends on, exists nowhere in the repo. The project's own `test.py` opens by checking whether that function exists, which suggests it may never have been created.

---

# C. Required Functionality (v2 specification)

## C.1 User roles

| Role | Capabilities |
|---|---|
| **Anonymous** | Browse feed, search, view scheme details, use chat (rate-limited). No writes. |
| **Registered user** | Everything above + profile, personalised feed, like/save/rate/comment/report, notifications |
| **Moderator** | + resolve reports, hide comments |
| **Admin** | + scheme CRUD, category/tag management, trigger re-embedding, view metrics |

> v1 had **no authentication whatsoever** — the user ID was a free-text box in the header. Any visitor could act as, and rewrite the profile of, any user by typing their UUID.

## C.2 Functional requirements

**Discovery**
- FR-1 Browse a paginated scheme feed; personalised when authenticated, popularity-ranked when not
- FR-2 Full-text + semantic hybrid search with pagination
- FR-3 Filter by category, jurisdiction (central/state), state, scheme type; combinable with search
- FR-4 Scheme detail: description, benefits, required documents, tags, official link, stats
- FR-5 Similar schemes on the detail page
- FR-6 **Eligibility explanation** — *why* a scheme was matched ("matched: farmer, rural, income under ₹2L"). New; v1 gave an opaque yes/no.

**Profile & eligibility**
- FR-7 Structured profile capture across the ~25 attributes, in grouped steps rather than one wall of checkboxes
- FR-8 Profile completeness indicator + prompts, since matching quality depends on it
- FR-9 Eligibility as a **ranking signal and optional filter**, never a hard hide (see Assumption 3)

**Social**
- FR-10 Like / unlike, with correct persisted state on load
- FR-11 Save / unsave, with a Saved collection
- FR-12 Rate 1–5, one rating per user per scheme, updatable
- FR-13 Threaded comments: post, read, edit within a window, soft-delete own
- FR-14 Report schemes and comments; moderation queue
- FR-15 Notifications: reply to your comment, new scheme in a followed category, deadline reminders

**AI assistant**
- FR-16 Grounded chat with citations back to scheme detail pages
- FR-17 Multi-turn conversation memory (v1 sent `history=[]` every turn — every message started cold)
- FR-18 Profile-aware answers when authenticated (v1 accepted `user_id` and ignored it)
- FR-19 Explicit refusal to invent scheme facts; always link the official source

**Auth**
- FR-20 Register, log in, log out, refresh session, password reset
- FR-21 Delete account and export data (India's DPDP Act, 2023 — this handles caste, disability, and income data)

**Admin**
- FR-22 Scheme CRUD + bulk import from JSON
- FR-23 Re-embedding trigger
- FR-24 Report queue

## C.3 Non-functional requirements

| | Target |
|---|---|
| Performance | Feed/search p95 < 400 ms server-side; chat < 3 s to first token |
| Scale | 10k schemes, 100k users, 50 req/s on a single small instance |
| Availability | Graceful degradation — if Gemini or the embedding model is down, keyword search and browsing still work |
| Security | OWASP Top 10 addressed; no secret in source; least-privilege DB role |
| Accessibility | WCAG 2.1 AA — keyboard navigable, labelled inputs, 4.5:1 contrast, screen-reader landmarks |
| i18n | English + Hindi at launch; string catalogue ready for more |
| Observability | Structured JSON logs with request IDs, `/health` + `/ready`, error tracking |
| Offline tolerance | Low-bandwidth friendly; no multi-MB payloads (v1 shipped a 384-float embedding per scheme detail) |

---

# D. Problems With the Existing Implementation

## D.1 Critical

**D-1 — No schema, no migrations.** The database cannot be reproduced. Onboarding a developer, running CI, or recovering from a Neon incident are all impossible. This is the root cause of the project being un-runnable.

**D-2 — Hardcoded live credentials.** The Neon connection string (with password) is in four scripts; the Replit variant of `main.py` also hardcodes a live Gemini API key. Both are in a public repo. Both must be rotated.

**D-3 — Broken configuration.** The GitHub `main.py` reads `os.getenv("DATABASE_URL", "")` but nothing loads a `.env` and `python-dotenv` isn't a dependency. Result: the pool is never built and **every endpoint returns 500**. The refactor from hardcoded literals to env vars was left half-finished.

**D-4 — Connection pool poisoning.** `get_db()` yields a connection and never commits or rolls back. Read endpoints return connections to the pool *idle in transaction*, holding snapshots open; after any error the aborted transaction rides along and every later request on that connection fails with `current transaction is aborted`. Under load the app degrades until restart.

**D-5 — No authentication or authorisation.** Identity is a text input. Any visitor can act as any user, including rewriting profiles containing caste, disability, and income data. Under the DPDP Act this is a reportable exposure, not just a bug.

**D-6 — Fake implementations reported as success.** `/comment` and `/report` return 200 and persist nothing; the UI renders the comment as if saved. Users lose data and are told it worked.

## D.2 Architecture & code quality

**D-7 — No layering.** `main.py` is 403 lines of routes containing raw SQL, business logic, caching, and Gemini calls. Nothing is unit-testable without a live database.

**D-8 — Zero tests.** `test.py` is a manual diagnostic script against production, not a test suite. No CI.

**D-9 — Four overlapping data scripts** (`seed_data.py`, `gen_vec.py`, `generate_embeddings.py`, `load_schemes_from_json.py`) with contradictory logic. `generate_embeddings.py` passes a raw Python list to a `vector` column without the `::vector` cast that `gen_vec.py` correctly uses. Two of them insert dummy schemes that duplicate real records.

**D-10 — Frontend built from HTML string concatenation.** No components, no state management, no router. The detail view is one 120-line template literal. Escaping is hand-rolled and **incomplete** — `escapeHtml` covers `&`, `<`, `>` but not quotes, while values are interpolated into unquoted-adjacent attribute contexts (`style="background:${bgColor}"`, `onclick="postDetailComment('${id}')"`). Today the data is trusted; once comments are real, that's an XSS vector.

**D-11 — Dead code.** `TweetRequest`, `getCategoryStyles` returning a fake CSS string that's immediately re-parsed with a regex, `RatingRequest` with no endpoint.

## D.3 Data model

**D-12 — Overloaded interaction table.** `user_scheme_interactions(interaction_type, rating_value)` stores likes, saves, and ratings in one table. Nothing prevents `rating_value = 47`, a like carrying a rating, or duplicate likes. Constraints are impossible to express.

**D-13 — Counts recomputed per row per request.** The search query runs two correlated subqueries over the interactions table for every scheme returned. At 10k schemes and real traffic this is the first thing to fall over.

**D-14 — `eligibility_json` is a junk drawer.** It holds eligibility rules, benefits, required documents, warnings, deadlines, and search tags in one opaque blob. Benefits and documents are display data, tags belong in a join table, and rules need to be queryable.

**D-15 — Eligibility rules are unqueryable and their semantics are undefined.** Matching lives in a SQL function that isn't in the repo. Nobody can read the rules, explain a match, or validate the data.

## D.4 Data quality (measured against `schemes.json`)

This is the most consequential category and it isn't visible from the code alone.

- **All 1,000 `description_short` values are the same generated template** — *"[Name] is a government scheme providing financial and/or administrative support to eligible beneficiaries. Eligible applicants can avail benefits by applying through the designated government portal or office."* Nothing else. **Embedding these produces 1,000 near-identical vectors**; semantic search is effectively title-matching with extra steps. This alone caps the quality of search, similar-schemes, and RAG.
- **633 of 1,000 benefit strings are truncated at ~200 characters**, mid-word — e.g. `"...a scroll of honor, and a blazer with a tie shall be "`.
- **997 of 1,000 `documents_required` arrays contain a single unsplit blob** — median 307 characters, max 8,155 — rendered as one giant bullet point.
- **Eligibility semantics are ambiguous and skewed.** In `must_match_all`, nearly every flag is `false`; if the matcher reads `false` as *"must be false"* rather than *"not a requirement"*, matching collapses. In `must_match_one_of`, **80 schemes have no `true` value at all** and can match nobody under an OR rule, while `is_sc_st` is true on 758/1,000 and `is_lig` on 511 — so the feed is dominated by caste and income gating.
- **No `official_url` field.** For a scheme-discovery product, the link to the government application page is arguably the single most valuable field, and it isn't captured.

**Implication:** the dataset is a scaffold, not a source of truth. v2 must (a) treat it as provisional, (b) show provenance and a verification disclaimer, and (c) make re-ingestion from better sources a first-class, repeatable operation.

## D.5 Search & AI

- **D-16** Hybrid ranking is arithmetically unsound — it subtracts a flat `0.5` from a cosine distance bounded in `[0, 2]`, so any keyword hit outranks every semantic match regardless of relevance.
- **D-17** No vector index. Fine at 1,000 rows (sequential scan), a wall at 10k+.
- **D-18** No full-text index; keyword matching is `ILIKE '%word%'`, which cannot use a B-tree and ignores stemming.
- **D-19** Category buttons filter by **tag**, but tags are freeform (1,470 distinct values). `tag ILIKE '%housing%'` matches **8** schemes while the `category` column holds **107** Housing schemes. Rural: 9 vs. real coverage. The category row is largely broken.
- **D-20** `google-generativeai` is deprecated — support ended 30 November 2025 — and `gemini-1.5-flash` is retired. The chat path will stop working if it hasn't already.
- **D-21** The chatbot has no memory (`history=[]` every call), ignores the `user_id` it accepts, retrieves only 3 documents with no relevance threshold, and returns citations the UI discards.
- **D-22** `/chat` is unauthenticated and unthrottled — a metered, billable Gemini endpoint open to the internet.

## D.6 Operational

- **D-23** In-process dict cache: breaks with more than one worker, and `invalidate_user_cache` only clears the acting user's entries, so a like never updates anyone else's cached feed.
- **D-24** `allow_origins=["*"]` with `allow_credentials=True` — an invalid combination browsers reject, and unsafe regardless.
- **D-25** The embedding model loads at startup inside the API process, pulling in PyTorch (~800 MB image) and blocking readiness for tens of seconds; every worker holds its own copy.
- **D-26** `print()` for logging, no request IDs, no health checks, no error tracking.
- **D-27** Raw exception detail returned to clients (`detail=f"Gemini error: {e}"`) — leaks internals.

## D.7 UX

- **D-28** Clicking a card mostly does nothing — the handler tests `e.target.classList.contains('explore-btn')`, but `e.target` is whichever child was clicked. Only the "View Details" link works.
- **D-29** Similar schemes are entirely unclickable (D above).
- **D-30** Like button always increments and disables — no unlike, no persisted state.
- **D-31** Search fires on every keystroke after 400 ms, and each request runs a transformer encode server-side.
- **D-32** No URL routing. The detail view is a `display:none` swap — no deep links, no shareable scheme URLs, no back-button support, and **no SEO**, which for a public-information product is a serious acquisition problem.
- **D-33** No empty/error/offline states beyond "Failed to load. Is backend running?" shown to end users.
- **D-34** Hindi appears only in the hero. The rest is English-only.

---

# E. Proposed New Architecture

## E.1 Shape

```
┌──────────────────────────────────────────────┐
│  Web client (React + TypeScript, SSR-ready)  │
│  routes · components · TanStack Query cache  │
└───────────────────────┬──────────────────────┘
                        │ HTTPS / JSON
┌───────────────────────▼──────────────────────┐
│  API layer — FastAPI                         │
│  routers · request/response schemas · authn  │
│  authz · rate limit · error envelope         │
├──────────────────────────────────────────────┤
│  Service layer — business logic              │
│  SchemeService · EligibilityService           │
│  SearchService · RecommendationService        │
│  InteractionService · ChatService · AuthService│
├──────────────────────────────────────────────┤
│  Repository layer — data access               │
│  SQLAlchemy 2.0 async · raw SQL for vectors   │
├──────────────────────────────────────────────┤
│  Adapters — external boundaries               │
│  EmbeddingProvider · LLMProvider · CacheBackend│
└───────────────────────┬──────────────────────┘
                        │
        ┌───────────────┴───────────────┐
        ▼                               ▼
┌──────────────────┐          ┌──────────────────┐
│ PostgreSQL 16    │          │ Gemini API       │
│ + pgvector       │          │ (via adapter)    │
│ + tsvector FTS   │          └──────────────────┘
└──────────────────┘
```

## E.2 Principles

1. **Routers contain no business logic** — they validate, delegate to a service, and shape the response.
2. **Services are database-agnostic** and take repositories via dependency injection, so they unit-test against fakes.
3. **External systems sit behind adapter interfaces.** `EmbeddingProvider` and `LLMProvider` are protocols; tests use deterministic fakes, and swapping Gemini for another model touches one file.
4. **Every external call degrades gracefully.** LLM down → chat returns retrieved schemes without prose. Embedder down → search falls back to full-text.
5. **Schema changes only through migrations.** Alembic is the sole source of truth; D-1 becomes structurally impossible.
6. **Stateless API.** No in-process state that breaks under horizontal scaling; caching goes behind `CacheBackend` (in-memory now, Redis later without touching callers).
7. **Embedding runs out-of-process.** A CLI worker owns the model; the API calls a lightweight ONNX encoder for query-time embedding only.

## E.3 Deliberately deferred

Not building now, and why: **Redis** (single instance doesn't need it — interface is ready), **Celery/queues** (no long-running jobs; ingestion is a CLI), **microservices** (one team, one deployable), **Elasticsearch** (Postgres FTS + pgvector covers this scale), **GraphQL** (REST fits the access patterns), **Kubernetes** (a container on a managed host is sufficient).

---

# F. Proposed Technology Stack

| Layer | v1 | v2 | Rationale |
|---|---|---|---|
| API framework | FastAPI | **FastAPI (keep)** | Right choice already — async, Pydantic validation, OpenAPI for free |
| DB | Postgres + pgvector | **Keep** | Vectors, JSONB, FTS, and relational integrity in one engine. Correct call. |
| DB access | raw psycopg2 | **SQLAlchemy 2.0 async + asyncpg**, raw SQL for vector ranking | Typed models, relationship management, and — critically — Alembic |
| Migrations | *none* | **Alembic** | Directly fixes D-1 |
| Validation | Pydantic v2 | **Keep** | |
| Config | broken env vars | **pydantic-settings** | Typed, validated at boot, fails loudly on a missing secret |
| Embeddings | sentence-transformers (PyTorch, in-process) | **fastembed** (ONNX) | *Same* MiniLM model, no PyTorch — image drops from ~1 GB to ~200 MB, cold start from ~30 s to ~2 s. Big win on free tiers. |
| LLM | google-generativeai (EOL) | **google-genai SDK** behind an adapter | Old SDK's support ended 30 Nov 2025; model pinned in config |
| Auth | *none* | **JWT access (15 min) + rotating refresh in httpOnly cookie; Argon2id** | Stateless verification, revocable sessions, XSS-resistant refresh storage |
| Caching | in-process dict | **`CacheBackend` interface, in-memory impl** | Redis-swappable without touching callers |
| Rate limiting | *none* | **slowapi** (per-IP + per-user; strict on `/chat`) | Fixes D-22 |
| Logging | `print()` | **structlog** JSON + request IDs | |
| Frontend | vanilla JS strings | **React 18 + TypeScript + Vite** | 25-field profile forms, auth state, cached infinite feeds — all painful hand-rolled |
| Data fetching | raw `fetch` | **TanStack Query** | Caching, dedupe, optimistic like/save with rollback (fixes D-30) |
| Routing | none | **React Router** | Real URLs → deep links, back button, shareable schemes, SEO (fixes D-32) |
| Styling | hand-written CSS | **Tailwind CSS** | Keeps the existing saffron/green visual language, removes ~500 lines of bespoke CSS |
| i18n | none | **react-i18next** | Hindi is a product requirement, not polish |
| Testing | none | **pytest + httpx + testcontainers; Vitest + RTL; Playwright** | Real Postgres in CI, not mocks |
| Local dev | manual | **Docker Compose** (`pgvector/pgvector:pg16` + API + web) | One command to a working stack |
| CI | none | **GitHub Actions** — lint, type-check, test, build | |

**Two decisions worth challenging** (flagged as decision points, not settled):

- **React vs. staying vanilla.** React is the recommendation, but it adds a Node toolchain and a build step. If you want to keep the zero-build simplicity, the fallback is vanilla ES modules + a small router + a template library — cheaper, but forms and cache invalidation stay manual. *Your call.*
- **SQLAlchemy vs. raw SQL + psycopg3.** Raw SQL is simpler for vector queries and this codebase already speaks SQL. SQLAlchemy wins mainly because Alembic comes with it. Vector-ranking queries will be raw SQL either way.

---

# G. Database Design

## G.1 Entity overview

```
users ──1:1── user_profiles
  │
  ├──1:N── refresh_tokens
  ├──1:N── scheme_likes ──N:1── schemes
  ├──1:N── scheme_saves ──N:1── schemes
  ├──1:N── scheme_ratings ─N:1── schemes
  ├──1:N── comments ──N:1── schemes   (self-referencing parent_id)
  ├──1:N── reports (polymorphic: scheme | comment)
  └──1:N── notifications

schemes ──N:1── categories
  ├──N:M── tags  (via scheme_tags)
  ├──1:N── scheme_benefits
  ├──1:N── scheme_documents
  └──1:N── scheme_eligibility_rules
```

## G.2 Key design decisions

**1. Split the overloaded interaction table** (fixes D-12). Three tables — `scheme_likes`, `scheme_saves`, `scheme_ratings` — each with a composite PK on `(user_id, scheme_id)`. A duplicate like becomes impossible at the storage layer, `rating BETWEEN 1 AND 5` becomes a CHECK constraint, and each table indexes independently.

**2. Denormalised counters on `schemes`, maintained by triggers** (fixes D-13): `like_count`, `save_count`, `comment_count`, `rating_sum`, `rating_count`. This is deliberate redundancy with a clear performance justification — feed queries stop running correlated subqueries per row, and sorting by popularity becomes an indexed B-tree scan.

**3. Eligibility rules normalised into rows** (fixes D-14, D-15) — the most important schema change:

```sql
CREATE TYPE rule_group AS ENUM ('all', 'any');
CREATE TYPE rule_operator AS ENUM ('eq', 'gte', 'lte', 'in');

CREATE TABLE scheme_eligibility_rules (
    id            BIGSERIAL PRIMARY KEY,
    scheme_id     TEXT NOT NULL REFERENCES schemes(scheme_id) ON DELETE CASCADE,
    rule_group    rule_group    NOT NULL,
    attribute_key TEXT          NOT NULL,   -- 'is_farmer', 'annual_income', 'min_age'
    operator      rule_operator NOT NULL,
    value_bool    BOOLEAN,
    value_num     NUMERIC,
    value_text    TEXT,
    label         TEXT NOT NULL,            -- human-readable, for explanations
    CHECK (num_nonnulls(value_bool, value_num, value_text) = 1)
);
```

This buys three things v1 couldn't have: matching becomes a **join instead of JSONB spelunking**; rules are **inspectable and correctable** by an admin; and because each rule carries a `label`, the API can return *why* a user matched (FR-6) instead of an opaque boolean. The original `eligibility_json` is retained verbatim on `schemes` as an archival column for provenance.

**4. Benefits and documents become real rows** — `scheme_benefits(stage, amount_text, amount_numeric, currency)` and `scheme_documents(name, is_mandatory, display_order)`. The importer splits the 997 single-blob document strings on delimiters; anything it can't split is preserved whole and flagged `needs_review`.

**5. Categories become a table** (fixes D-19). The nine hardcoded frontend categories become rows with `slug`, `name`, `name_hi`, `icon`, `display_order`, and schemes get a real `category_id` FK. Category browsing then filters on an indexed FK instead of fuzzy-matching freeform tags.

**6. Tags normalised** — `tags(id, name, slug)` + `scheme_tags(scheme_id, tag_id)`, deduplicating the 1,470 freeform strings.

**7. Profile attributes stay as typed columns**, not a JSONB blob or an EAV table. Rationale: these ~25 attributes are the join key for eligibility matching and must be queryable, indexable, and type-checked. A `custom_attributes JSONB` column absorbs future rare flags without a migration. The attribute vocabulary lives in one shared enum used by both `user_profiles` columns and `scheme_eligibility_rules.attribute_key`, so the two sides cannot drift.

**8. Generated `tsvector` column with a GIN index** (fixes D-18):

```sql
search_vector tsvector GENERATED ALWAYS AS (
    setweight(to_tsvector('english', coalesce(name, '')), 'A') ||
    setweight(to_tsvector('english', coalesce(description_long, '')), 'B') ||
    setweight(to_tsvector('english', coalesce(ministry, '')), 'C')
) STORED
```

**9. HNSW index on the embedding** (fixes D-17): `USING hnsw (embedding vector_cosine_ops)`.

**10. New columns the product needs**: `official_url`, `slug` (for SEO-friendly URLs), `description_long`, `application_deadline`, `is_active`, `data_source`, `last_verified_at`. The last two support the provenance disclaimer the data quality demands.

## G.3 Ranking: replacing the broken hybrid formula

v1 subtracted a flat `0.5` from a cosine distance (D-16). v2 uses **Reciprocal Rank Fusion** — run the full-text query and the vector query independently, then fuse by rank:

```
score(d) = Σ  1 / (k + rank_i(d))        with k = 60
```

RRF is scale-free, so it doesn't care that BM25 scores and cosine distances live on different scales, and it's the standard approach for exactly this hybrid case. It's expressible as a single Postgres CTE.

## G.4 Indexes

| Table | Index | Purpose |
|---|---|---|
| schemes | HNSW (embedding vector_cosine_ops) | Semantic search |
| schemes | GIN (search_vector) | Full-text |
| schemes | btree (category_id, is_active) | Category browse |
| schemes | btree (jurisdiction, state_code) | Regional filter |
| schemes | btree (like_count DESC) | Popularity sort |
| scheme_eligibility_rules | btree (scheme_id, rule_group) | Matching join |
| scheme_likes/saves/ratings | PK (user_id, scheme_id) + btree (scheme_id) | Both directions |
| comments | btree (scheme_id, created_at DESC), (parent_id) | Threading |
| notifications | partial btree (user_id) WHERE read_at IS NULL | Unread badge |

## G.5 Migration from v1 data

Idempotent, re-runnable importer: read `schemes.json` → map categories → normalise tags → split documents → parse benefits (flagging the 633 truncated ones) → translate `eligibility_json` into rules under the agreed semantics → embed → upsert on `scheme_id`. **Original `scheme_id` values are preserved** so any existing likes/saves can be carried over.

---

# H. Project Structure

```
schememedia/
├── docker-compose.yml            # postgres+pgvector, api, web
├── README.md
├── docs/
│   ├── architecture.md
│   ├── data-quality.md           # dataset caveats, provenance
│   └── adr/                      # architecture decision records
│
├── apps/api/
│   ├── pyproject.toml
│   ├── Dockerfile
│   ├── alembic.ini
│   ├── migrations/versions/
│   ├── src/schememedia/
│   │   ├── main.py               # app factory only
│   │   ├── core/
│   │   │   ├── config.py         # pydantic-settings
│   │   │   ├── security.py       # Argon2, JWT
│   │   │   ├── logging.py
│   │   │   ├── errors.py         # exception → HTTP envelope
│   │   │   └── deps.py
│   │   ├── db/
│   │   │   ├── session.py
│   │   │   └── models/           # user, scheme, interaction, comment...
│   │   ├── schemas/              # request/response DTOs
│   │   ├── repositories/
│   │   ├── services/
│   │   │   ├── eligibility.py    # rule matching + explanations
│   │   │   ├── search.py         # RRF hybrid
│   │   │   ├── recommendation.py
│   │   │   └── chat.py           # RAG orchestration
│   │   ├── adapters/
│   │   │   ├── embedding/        # protocol + fastembed + fake
│   │   │   ├── llm/              # protocol + gemini + fake
│   │   │   └── cache/            # protocol + memory (+ redis later)
│   │   ├── api/v1/routers/       # auth, schemes, search, interactions,
│   │   │                         # comments, profile, chat, admin
│   │   └── cli/
│   │       ├── import_schemes.py
│   │       └── generate_embeddings.py
│   └── tests/{unit,integration,conftest.py}
│
└── apps/web/
    ├── package.json
    ├── vite.config.ts
    ├── src/
    │   ├── main.tsx
    │   ├── routes/               # Feed, SchemeDetail, Search, Saved,
    │   │                         # Profile, Notifications, Login, Admin
    │   ├── components/
    │   │   ├── ui/               # Button, Card, Input, Skeleton...
    │   │   ├── scheme/           # SchemeCard, EligibilityBadge,
    │   │   │                     # BenefitList, CommentThread
    │   │   └── layout/           # Header, MobileNav, ChatWidget
    │   ├── hooks/                # useSchemes, useAuth, useInteractions
    │   ├── api/                  # typed client generated from OpenAPI
    │   ├── i18n/                 # en.json, hi.json
    │   └── lib/
    └── tests/  +  e2e/           # Vitest + Playwright
```

---

# I. Development Roadmap

| Phase | Deliverable | Definition of done |
|---|---|---|
| **0. Secure** *(you)* | Rotate Neon password + Gemini key; purge git history or make repo private | Old credentials dead |
| **1. Foundation** | Monorepo, Docker Compose, config, logging, error envelope, health checks, CI skeleton | `docker compose up` → API responds on `/health`; CI green |
| **2. Schema** | Full Alembic migration set; SQLAlchemy models; seed script | `alembic upgrade head` builds the schema from empty; downgrade works |
| **3. Ingestion** | Importer + embedding CLI; data-quality report | 1,000 schemes + rules + tags + benefits + docs + embeddings loaded, re-runnable |
| **4. Auth** | Register, login, refresh, logout, password reset, RBAC | Integration tests cover happy path, bad credentials, expired/reused token, privilege escalation |
| **5. Core read API** | Schemes list/detail/similar, categories, hybrid search (RRF) | p95 < 400 ms on 1k schemes; search relevance smoke-tested against a fixture query set |
| **6. Eligibility & recommendations** | Rule matching, explanations, personalised feed | Given a fixture profile, matches and explanations are asserted exactly |
| **7. Social** | Likes, saves, ratings, comments, reports, notifications | Concurrency tested (double-like, double-rate); authz tested (edit another's comment → 403) |
| **8. AI assistant** | Chat with memory, citations, profile awareness, rate limits, graceful degradation | Fake LLM in tests; live smoke test; LLM-down path returns retrieved schemes |
| **9. Frontend foundation** | Vite app, routing, design system, auth flows, i18n scaffold | Login → protected route → refresh survives reload |
| **10. Frontend features** | Feed, search, detail, saved, profile wizard, notifications, chat | Every route has loading / empty / error states |
| **11. Admin** | Scheme CRUD, report queue, re-embed trigger | Admin-only enforced server-side, verified by test |
| **12. Hardening** | Security review, a11y audit, perf profiling, load test, Playwright E2E | OWASP checklist signed off; axe clean; 5 critical journeys green |
| **13. Ship** | Deployment config, runbook, backups, monitoring, README | Fresh clone → running app by following the README alone |

**Verification discipline:** every phase ends with tests written *and passing* before the next begins. I'll maintain a running checklist (completed / in progress / blocked / known debt / decisions) and re-run the full suite at each phase boundary.

---

# J. Potential Risks

| # | Risk | Severity | Mitigation |
|---|---|---|---|
| **R-1** | **Eligibility misinformation.** Telling a citizen they don't qualify for a benefit, based on machine-generated rules of unknown provenance, can cause real harm. | **Critical** | Never hard-hide schemes on eligibility (Assumption 3). Frame as "You may be eligible" with the reasons shown. Always link the official source. Persistent disclaimer that data is unofficial and must be verified. |
| **R-2** | **Data quality caps product quality.** Identical boilerplate descriptions, 633 truncated benefits, 997 unsplit document blobs, no official URLs. | **Critical** | Treat the dataset as provisional. Build the ingestion pipeline to be re-runnable so better data drops in. Ship a `docs/data-quality.md` and surface `last_verified_at` in the UI. Consider re-scraping from the official portal (see R-3). |
| **R-3** | **Re-scraping raises legal and operational questions** (terms of use, rate limits, ongoing maintenance). | High | Out of scope for the rebuild; flag as a follow-on project. Design the importer against a documented interface so a new source plugs in. |
| **R-4** | **Semantic search may underperform even after the rebuild**, because embeddings of identical templates carry little signal. | High | Embed `name + category + tags + benefits + ministry` rather than the boilerplate description. RRF fusion means full-text carries the load where vectors are weak. Build a fixture query set to measure, not guess. |
| **R-5** | **The production Neon database may already hold data and a schema I can't see** — including a `user_matches_scheme` I'd be reinventing. | High | Get a `pg_dump --schema-only` before Phase 2. If real users/interactions exist, Phase 3 needs a data-migration path, not just an import. |
| **R-6** | **Neon's pooler runs PgBouncer in transaction mode**, which breaks prepared statements — asyncpg fails cryptically unless `statement_cache_size=0`. | Medium | Configure explicitly in Phase 1 and document it. Use the direct (non-pooled) endpoint for migrations. |
| **R-7** | **Neon free tier cold starts** add seconds to the first request after idle. | Medium | Keep-alive ping or accept it in dev; note it in the deployment runbook. |
| **R-8** | **Gemini cost and abuse** on a public chat endpoint. | Medium | Strict per-IP and per-user rate limits, max token caps, daily budget alarm, auth required above a low anonymous quota. |
| **R-9** | **Model/SDK churn** — the old SDK already died mid-project. | Medium | `LLMProvider` adapter + model name in config; swapping is a one-file change. |
| **R-10** | **Scope inflation.** Auth + admin + i18n + a11y + tests is genuinely larger than v1. | Medium | Phases 1–10 are the shippable core; 11 is deferrable. Cut admin UI to CLI commands if time is tight. |
| **R-11** | **Frontend rewrite risk** — the visual design is decent and worth preserving even though the code isn't. | Medium | Port the existing design tokens (saffron `#ea580c`, card radii, spacing) into Tailwind config first, so v2 looks like v1 on day one and improves from there. |
| **R-12** | **I cannot reach your Neon database from this environment** (network is whitelist-restricted to package registries). | Medium | I'll run Postgres 16 + pgvector locally, load all 1,000 schemes, and test the full stack end-to-end here. You point it at Neon with a one-line config change. |
| **R-13** | **Handling sensitive personal data** — caste, disability, income, pregnancy status — under India's DPDP Act, 2023. | High | Collect only what eligibility needs, every field optional, encryption in transit and at rest, explicit consent copy, data export and account deletion (FR-21), no sensitive fields in logs. |

---

# ASSUMPTIONS REQUIRING YOUR APPROVAL

These cannot be determined from the code. Each has a default I'll proceed with unless you say otherwise.

| # | Question | Proposed default | Why |
|---|---|---|---|
| **A-1** | Auth method | **Email + password**, behind an interface so phone/OTP can be added | OTP needs a paid SMS provider and KYC; email works day one |
| **A-2** | `false` in `must_match_all` | **"Not a requirement"** | The alternative makes ~all schemes unmatchable — clearly not the intent |
| **A-3** | Eligibility as filter or signal | **Ranking signal + optional user-toggled filter; never hides schemes** | See R-1. Also fixes the 80 schemes that match nobody |
| **A-4** | Admin UI in scope | **Yes, minimal** — scheme CRUD + report queue. Deferrable to CLI if time is tight | Reports and moderation are meaningless without somewhere to action them |
| **A-5** | User-submitted schemes | **No** — curated catalogue only | Nothing in v1 suggests otherwise |
| **A-6** | Languages at launch | **English + Hindi**, i18n-ready for more | The hero is already bilingual; the audience requires it |
| **A-7** | Preserve original `scheme_id` values | **Yes** | Keeps existing likes/saves portable |
| **A-8** | Comment moderation | **Public immediately, reactive moderation** via reports | Matches v1's report-based intent |
| **A-9** | Deployment target | **Docker-first**, host-agnostic (Fly/Render/Railway all work) | Not specified anywhere |
| **A-10** | The `TweetRequest` social-post feature | **Drop it** | No endpoint, no table, no UI — abandoned scope |

---

# WHAT I NEED FROM YOU BEFORE PHASE 1

1. **Confirm the credentials are rotated** (Neon password + Gemini key).
2. **`pg_dump --schema-only "$DATABASE_URL"`** — or confirm there's nothing to preserve and I should design fresh. Also: does the production database contain real users or interactions?
3. **Approve or amend A-1 through A-10.**
4. **Decide React vs. vanilla** for the frontend (Section F).
5. **Confirm the priority order** if scope must be cut — my recommendation: ship Phases 1–10, defer 11.
