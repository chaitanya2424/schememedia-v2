# ADR 0003 — A `verification_status` column, separate from `needs_review`

**Status:** Accepted · **Date:** 2026-08-31

## Context

`schemes` already carries `needs_review` (set by the importer when it hits a
contradiction or an implausible value while translating one record) and
`data_source` / `last_verified_at` (free-text provenance). None of these tell
a caller how much a *shown* record can be trusted, and the search layer
(services/search.py, repositories/search.py) needs exactly that: per REBUILD
PLAN D.4, the dataset is machine-generated and partly unreliable (identical
boilerplate descriptions, 633 truncated benefit strings, no `official_url`),
so a UI must never present an imported record as authoritative without
saying so.

`needs_review` is not a substitute: it flags an *importer-side* data problem
(a contradiction, an implausible number) on a specific record, not the
record's general provenance. A scheme can be `needs_review = false` and still
be entirely unverified against any primary source, which is the normal case
for all 1,000 imported records.

## Decision

Add `verification_status` (enum: `unverified`, `source_provided`,
`officially_verified`) to `schemes`, defaulting to `unverified`. The importer
always writes `unverified` — it never claims a higher status on its own.
`officially_verified` is reserved for a future manual/admin verification
workflow, not set anywhere yet.

Every search result and scheme-detail response carries this field
(`SearchResult.verification_status`), so a caller cannot render a scheme
without knowing how much to trust it.

## Consequences

**Good.** The trust signal is explicit and queryable rather than inferred
client-side from `needs_review`/`data_source`. Sorting or filtering by
verification becomes a plain column predicate.

**Cost.** One more enum, one more migration. Justified: this is exactly the
kind of provenance signal R-2 (REBUILD_PLAN, data quality caps product
quality) calls for, and it is cheap now versus retrofitting once search and
detail responses already ship without it.

**Downgrade gap.** Same autogenerate limitation as the initial migration
(§ "Two Alembic gaps already worked around"): the enum type is created
implicitly and never dropped on `downgrade`, so this migration explicitly
`DROP TYPE`s it — otherwise a subsequent `upgrade head` fails with
`DuplicateObjectError`.
