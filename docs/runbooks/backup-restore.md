# Database backup and restore

This procedure was executed and verified against a real PostgreSQL 16 +
pgvector database standing in for staging (no staging server is
provisioned yet, so this ran against the local dev database). It is not
a design on paper — every step below actually ran; results are recorded
at the bottom.

## Backup

Use `pg_dump`'s custom format (`-Fc`): compressed, and restorable with
`pg_restore` (selective table/schema restore, parallel jobs), unlike a
plain SQL dump.

```bash
pg_dump -h HOST -U USER -Fc -f schememedia_backup.dump DATABASE_NAME
```

- Run this against the platform's **direct** (non-pooled) connection
  string, same as migrations — see README's "Connecting to Neon" note.
- The dump captures schema and data together; a separate `alembic`
  migration state is not needed since `alembic_version` is itself a
  table in the dump.
- Store the resulting file in the hosting platform's backup storage
  (e.g. object storage), not on the application server's own disk —
  a backup that lives next to what it backs up is lost with it.

**Schedule:** daily, automated, at minimum — most managed Postgres
providers (Neon, Render, RDS) offer this natively as point-in-time
recovery on top of manual dumps; prefer enabling that over relying on
this manual procedure alone once a real production database exists.
This document covers the manual procedure so it is understood and has
been proven to work, independent of which platform ends up hosting it.

## Restore

```bash
createdb -h HOST -U USER TARGET_DATABASE_NAME
pg_restore -h HOST -U USER -d TARGET_DATABASE_NAME --no-owner --no-privileges schememedia_backup.dump
```

- `--no-owner --no-privileges`: the dump's role names won't exist on a
  different server/environment; omitting them lets restore run as
  whatever user is connecting, rather than failing on role lookups.
- Restoring into a **new** database name first (never directly over a
  live one) is what makes this safe to rehearse — verify the restored
  data, then cut traffic over, rather than restoring in place and
  finding out afterward that the dump was bad.

## What "restore succeeded" actually means

Row counts alone can lie (e.g. a truncated dump that still has the
right table shapes). This procedure was verified with two checks, from
weakest to strongest:

1. Row counts per table, source vs. restored.
2. A whole-table content checksum, order-independent, including the
   `pgvector` embedding column specifically (the one column most likely
   to silently corrupt across a dump/restore, since it isn't
   human-readable to spot-check by eye):

   ```sql
   SELECT md5(string_agg(md5(schemes.*::text), '' ORDER BY scheme_id)) FROM schemes;
   ```

   Run against both databases; the two hashes must match exactly.

## Verification run — 2026-09-02

Executed against the local dev database (1,000 real schemes, standing
in for staging pending a provisioned staging server):

| Table | Source count | Restored count |
|---|---|---|
| schemes | 1000 | 1000 |
| scheme_benefits | 1000 | 1000 |
| scheme_documents | 5342 | 5342 |
| scheme_eligibility_rules | 2616 | 2616 |
| categories | 11 | 11 |
| tags | 1450 | 1450 |

Whole-table checksum on `schemes` (all columns, including `embedding`):
identical on source and restored databases. `pg_restore` completed with
no errors. The throwaway restore-target database was dropped afterward.

**Not yet verified against real staging infrastructure** — this ran
against a local database because no staging server exists yet (see
Phase 4). Re-run this exact procedure once staging is actually
provisioned, before relying on it for production.
