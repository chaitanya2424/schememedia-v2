# ADR 0001 — Eligibility rules as rows, not JSONB

**Status:** Accepted · **Date:** 2026-08-25

## Context

v1 stored eligibility inside `schemes.eligibility_json`, matched by a SQL
function `user_matches_scheme` that was never committed to the repository.
Nobody could read the rules, correct a bad one, or explain a match to a user.

The source data is machine-generated and skewed: `must_match_all` contains
8,651 `false` values against 349 `true`, and 709 of 1,000 schemes have every
boolean set to `false`.

## Decision

Eligibility rules are rows in `scheme_eligibility_rules`, one per asserted
condition, each carrying a human-readable `label`.

`false` and `null` in the source both mean "not a requirement" and produce no
row. Of roughly 12,000 source flag values, about 599 become rules.

## Consequences

**Good.** Matching is a join rather than JSONB traversal. Rules are inspectable
and correctable by an admin. A `label` on every rule lets the API answer "why
did this match?" — a feature v1 could not offer at all. A CHECK constraint on
`attribute_key` makes an importer typo fail at insert time.

**Cost.** The importer must translate the blob, and the mapping is only as good
as our reading of the source. `schemes.raw_eligibility` preserves the original
for audit and re-translation.

**Safety net.** Because eligibility ranks rather than filters (see the rebuild
plan, Assumption A-3), a mis-mapped rule can only mis-rank a scheme — it can
never hide one from someone who qualifies.
