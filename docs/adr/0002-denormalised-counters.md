# ADR 0002 — Denormalised counters maintained by triggers

**Status:** Accepted · **Date:** 2026-08-25

## Context

v1 computed `like_count` and `avg_rating` with correlated subqueries over the
interactions table, for every scheme, on every feed and search request. At 1,000
schemes it is survivable; at 10,000 with real traffic it is the first thing to
fall over.

## Decision

`schemes` carries `like_count`, `save_count`, `comment_count`, `rating_sum`, and
`rating_count`, maintained by `AFTER` triggers on the interaction tables.

Ratings store sum and count rather than an average: an update is then O(1) and
avoids the drift of repeatedly averaging an average.

## Consequences

**Good.** Feed queries read a column instead of aggregating. Sorting by
popularity becomes an indexed B-tree scan. Counters stay correct regardless of
what writes the rows — API, importer, admin in psql, or a future background job.

**Cost.** Deliberate redundancy, justified by the read/write ratio: these
counters are read on every feed request and written rarely.

**Guarded by tests.** `tests/test_schema.py` asserts increment, decrement, the
rating-update case (5 → 2 must not change the count), and comment soft-delete.
