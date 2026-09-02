# SchemeMedia v2 — Build Plan

A week-by-week schedule to finish the project. Two goals, weighted equally:
**you understand what you built**, and **bugs get caught early rather than
discovered late**.

Assumes roughly **10–15 hours a week**. Adjust the calendar, not the order —
the sequence matters because each week depends on the one before it.

---

# The rules that prevent bugs

These matter more than the schedule. Most bugs in a project like this come from
four habits, and all four are avoidable.

### 1. One vertical slice at a time

Build a feature end-to-end — database → repository → service → route → test —
before starting the next. Never build "all the repositories" then "all the
services". Broad-but-unfinished layers hide integration bugs until the end,
when they are expensive.

### 2. Write the test for the hard part first

Not full TDD. Just this: before implementing something tricky, write the test
that says what "correct" means. If you cannot state it as a test, you do not yet
understand the requirement — and that is the real bug.

The document splitter is the clearest example. Write five blobs and their
expected output *first*. Then the regex cascade has a target instead of a vibe.

### 3. Green before you move

Never start the next task on a red suite. Before every commit:

```powershell
python scripts/dev.py check    # ruff + format + mypy
python scripts/dev.py test     # full suite
git commit
```

If that takes thirty seconds, you will do it. If you skip it for two days, you
will spend an afternoon bisecting.

### 4. One migration in flight at a time

Generate it, apply it, **downgrade it, apply it again**, then commit. A
migration that has never been reversed is a migration you cannot trust. This
already caught a real bug in Phase 2 (Alembic never drops enum types).

### And when something breaks

Write it out before you start fixing:

> **Problem** — what you observed, exactly.
> **Root cause** — why, not where.
> **Fix** — the change.
> **Verification** — the command that proves it.

Most bad debugging is fixing the symptom. This forces the pause.

---

# Session rhythm

Each working session, in order:

1. **Orient** (5 min) — `git log --oneline -5`, run the tests, see green.
2. **Pick one task** from the current week. One.
3. **State the goal in a sentence.** If you cannot, the task is too big — split it.
4. **Write the test** for the tricky part.
5. **Implement** the smallest thing that passes.
6. **Verify** — `dev.py check && dev.py test`.
7. **Commit** with a message saying *why*, not *what*.

Ending a session on green means the next session starts with momentum instead
of archaeology.

---

# Week 0 — Get the machine ready (2–3 hours)

Nothing else can start until this is done.

| Task | |
|---|---|
| Install PostgreSQL 16 | README §1.1 — remember the password |
| Compile pgvector | README §1.2 — Build Tools, x64 Native Tools prompt **as Administrator** |
| `copy .env.example .env`, set the password | |
| `python scripts/dev.py doctor` | every line green |
| `python scripts/dev.py init-db && migrate` | |
| `python scripts/dev.py test` | **37 passed** |
| `git init`, first commit | |

**Learn this week:** why the schema lives in migrations rather than a `.sql`
file you run by hand. Open both migration files and read them. Then run
`alembic downgrade base`, look at the empty database, run `alembic upgrade head`
and watch it rebuild. That loop is the whole point.

✅ **Done when:** `dev.py test` reports 37 passed, and you have a first commit.

---

# Week 1 — Phase 3a: the importer

Load 1,000 schemes. No embeddings yet.

**Order matters** — later steps depend on earlier ones:

1. **Load `schemes.json`, print a summary.** No database writes. Confirm you see
   1,000 records and the shape you expect.
2. **Categories** — 11 distinct values → `categories` rows.
3. **Tags** — normalise 1,470 raw strings → ~1,450 `tags` rows + `scheme_tags`.
4. **Schemes** — upsert on `scheme_id`, with slug generation.
   ⚠️ One duplicate name (*Establishment of Goat Unit (10 +1)*) — handle the
   slug collision.
5. **Benefits** — exactly 1,000 rows, one per scheme. Set `is_truncated` where
   `len(amount) == 200` (627 rows) or 195–199 (6 rows).
6. **Documents** — the splitter cascade. **This is the hardest task of the week.
   Do it last**, when everything else is working.

**Learn this week:** idempotency. Run the importer twice and assert the row
counts are identical. This is the single most valuable test in the whole
importer, and the habit generalises to every data pipeline you ever write.

**Bug traps:**
- Slug collisions (1 known case)
- Unicode — the file contains ₹ and U+FEFF; always open with `encoding='utf-8'`
- Splitting on commas. **Don't.** 494 blobs contain commas *inside* single
  document names.

✅ **Done when:** importer runs twice, row counts identical both times, tests pass.

---

# Week 2 — Phase 3b: eligibility rules + embeddings

1. **Translate `eligibility_json` → `scheme_eligibility_rules`.**
   Expect **2,622 rules**. Median 2 per scheme, max 8, 53 schemes yield zero.
   `false` and `null` produce nothing.
   Map `not_govt_employee: true` → `is_govt_employee eq false`.
2. **Attach labels** from `services/eligibility_labels.py` (already written and
   tested — 14 tests).
3. **Flag data hazards:** 3 schemes with contradictory government-employee
   flags, 33 income values below ₹1,000.
   ⚠️ Needs a small migration to add `needs_review` to
   `scheme_eligibility_rules` — do the full up/down/up cycle.
4. **Data-quality report** — rules created, documents split vs. flagged,
   benefits truncated, schemes with no `official_url`.
5. **Embeddings** — fastembed, `all-MiniLM-L6-v2`, 384-dim. Embed
   `name + category + tags + benefits + ministry`, **not** the boilerplate
   description. Batched and resumable.

**Learn this week:** what an embedding actually is. After generating them, run a
few similarity queries by hand in psql and look at the results. Then look at
what happens if you embed `description_short` instead — the vectors collapse.
Seeing that is worth more than reading about it.

✅ **Done when:** 2,622 rules exist, every scheme has an embedding, the quality
report prints, and a manual similarity query returns sensible neighbours.

---

# Week 3 — Phase 4: authentication

The first week with real security consequences.

1. Password hashing (Argon2id) — service + tests
2. JWT access tokens — create, verify, expiry
3. Refresh tokens — rotation and reuse detection
4. Routes: register, login, refresh, logout, me
5. RBAC dependency (`require_role`)
6. **Negative tests** — this is the point of the week

**Learn this week:** why the refresh token is stored **hashed**, and why reuse
of a rotated token means the token was stolen. Also why the access token is
short-lived and the refresh token lives in an httpOnly cookie. Understand the
threat each choice defends against — these are the questions you will be asked
in interviews, and the reasoning is genuinely interesting.

**Test the failures, not just the happy path:**
wrong password · expired token · reused refresh token · a user editing another
user's profile → 403 · missing token → 401.

✅ **Done when:** a normal user cannot reach an admin route, proven by a test.

---

# Week 4 — Phase 5a: the read API

Now the layering pays off.

1. `SchemeRepository` — data access only
2. `SchemeService` — business logic, takes the repository by injection
3. Pydantic response schemas — **whitelisted fields**, never `SELECT *`
   (v1 shipped a 384-float embedding to the browser)
4. Routes: list, detail by slug, similar, categories
5. Cursor pagination

**Learn this week:** why services take repositories by injection. Write one
service test using a fake repository and no database. When it runs in
milliseconds without Postgres, the reason for the whole layering rule becomes
obvious.

✅ **Done when:** a service test passes with no database, and `/schemes` returns
paginated results in under 400 ms.

---

# Week 5 — Phase 5b: search

1. Full-text search over the generated `tsvector`
2. Vector search over the HNSW index
3. **Reciprocal Rank Fusion** to combine them
4. Filters: category, jurisdiction, state, type
5. A fixture query set — 10 queries with expected top results

**Learn this week:** why RRF instead of adding scores. BM25 ranks and cosine
distances live on completely different scales; v1 subtracted a flat 0.5 from a
distance and any keyword hit beat every semantic match. RRF uses **rank**, not
score, so scale stops mattering. This is a genuinely elegant idea and it is
five lines of SQL.

✅ **Done when:** the fixture queries return sensible results, and you can
explain why fusion beats either method alone.

---

# Week 6 — Phase 6: eligibility matching

The feature the whole product is named for.

1. `EligibilityService.match(profile, scheme)` → matched rules + unmatched rules
2. Explanations built from rule labels
3. Feed ranking: eligibility as a **signal**, never a filter
4. Near-miss: "add your income to match 12 more schemes"
5. Profile completeness percentage

**Learn this week:** why this ranks instead of filtering. Re-read
`REBUILD_PLAN.md` §6. The reasoning is a product-safety argument, not a
technical one — and it is the kind of judgement that separates an engineer from
a code generator.

**Test with fixture profiles:** a farmer, a student, an empty profile. The empty
profile must still see schemes.

✅ **Done when:** given a fixture profile, matched rules and explanations are
asserted exactly, and an empty profile still returns a full feed.

---

# Week 7 — Phase 7: social features

Straightforward after Week 6. One vertical slice each:

likes (toggle) · saves · ratings (upsert) · comments (threaded, soft delete) ·
reports · notifications

**Learn this week:** concurrency. Write a test that likes the same scheme twice
simultaneously and confirm the counter stays correct. The database constraint
does the work — that is why the constraint exists.

✅ **Done when:** double-like and double-rate are handled, and editing another
user's comment returns 403.

---

# Week 8 — Phase 8: the AI assistant

1. `LLMProvider` protocol + a fake for tests
2. Gemini adapter (`google-genai`)
3. RAG: retrieve → build context → generate → cite
4. Conversation memory (v1 sent an empty history every turn)
5. Rate limiting — `/chat` costs money
6. **Graceful degradation** — LLM down → return the retrieved schemes anyway

**Learn this week:** why the LLM sits behind an interface. Your tests will use
the fake and run instantly with no API key and no cost. Then note that the old
SDK died mid-project — the adapter is why that is a one-file change.

✅ **Done when:** the whole chat path is tested with a fake LLM, and the
LLM-unavailable path still returns useful results.

---

# Weeks 9–11 — Frontend

**Decide the framework before Week 9.** Next.js is the recommendation; the
reasoning is SEO, which for a public-information product is the acquisition
channel.

- **Week 9** — project setup, routing, design system, auth flows, i18n scaffold
- **Week 10** — feed, search, scheme detail, saved
- **Week 11** — profile wizard, notifications, chat widget

**Learn across these weeks:** why every screen needs four states — loading,
empty, error, success. v1 had one: success. Everything else showed
*"Failed to load. Is backend running?"* to actual citizens.

✅ **Done when:** every route has all four states, and a scheme page has a real
shareable URL.

---

# Week 12 — Admin and hardening

Scheme CRUD · report queue · security review · accessibility audit (axe) ·
load test · Playwright E2E for five critical journeys.

---

# Week 13 — Ship

Deployment config · run migrations as a release step · monitoring · backups ·
a README a stranger can follow from clone to running app.

✅ **Done when:** someone who has never seen the project can get it running from
the README alone.

---

# Tracking

Keep a `PROGRESS.md` and update it at the end of each week:

```markdown
## Week 1 — Importer
- [x] Categories, tags, schemes, benefits
- [ ] Document splitter — 185 blobs still unsplit, needs the numbered-list rule
- Decision: excluded commas from splitting (shreds document names)
- Bug: slug collision on duplicate scheme name → suffix on collision only
```

The **decisions** and **bugs** lines matter most. In three months you will not
remember why commas were excluded, and future-you will "fix" it.

---

# If you fall behind

Cut scope, not quality. In priority order, the project is still worth shipping
without: the admin UI (Week 12 — use CLI commands), the AI assistant (Week 8 —
search alone is useful), and Hindi at launch (keep the i18n scaffold, add
translations later).

Do **not** cut: tests, authentication, or the eligibility-ranks-not-filters
design. Those are load-bearing.

---

# A note on pace

Fourteen weeks looks long. It is a real application with authentication,
vector search, an LLM integration, and a database designed properly — that is
genuinely a few months of part-time work, and anyone who tells you otherwise is
describing a demo, not a product.

The thing that will actually slow you down is not difficulty. It is starting a
new feature while the last one is half-finished. One slice at a time, green
before you move.
