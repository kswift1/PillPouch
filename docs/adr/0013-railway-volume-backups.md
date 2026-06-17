# ADR-0013: Railway Volume Backups for V1 SQLite

## Status
Accepted — 2026-06-17

Supersedes the backup mechanism portion of [ADR-0002: SQLite + Litestream](0002-sqlite-litestream.md) for Railway V1.

## Context

ADR-0002 selected SQLite + Litestream + Cloudflare R2. That decision assumed Fly.io deployment and a Litestream-friendly single VM path.

ADR-0012 changed V1 hosting to Railway because the Railway Hobby plan is already paid for. Railway services can attach persistent volumes, and Railway supports native manual and scheduled backups for volume contents, including SQLite files.

Current W3 production data is small:

- `recommendations`: 5 rows
- `category`: 16 rows
- no device token table yet
- no user-generated production data yet

Stage 2 deployed the API to Railway with:

- project: `PillPouch`
- service: `api`
- volume: `api-volume`
- mount: `/data`
- SQLite file: `/data/pillpouch.db`

Stage 3 verified the database by downloading `/pillpouch.db` from the Railway volume and running local SQLite checks.

## Decision

For V1 on Railway, use Railway volume-native backups as the primary backup mechanism.

- **Primary backup**: Railway volume backups
  - manual backup before risky maintenance
  - scheduled backup from Railway dashboard once production data exists
- **Ad-hoc verification/export**: Railway CLI volume file download
- **DB integrity check**: download DB snapshot, run `sqlite3 ... 'PRAGMA integrity_check;'`
- **Litestream + R2**: deferred until PITR or cross-provider backup becomes necessary

Do not add Litestream to the runtime image in this task.

## Consequences

### Positive

- Fewer moving parts for first production deployment.
- No R2 bucket/credential setup during W3.
- Backup flow matches the selected Railway hosting platform.
- Railway native backups cover all content stored in the mounted volume.
- CLI volume file download gives a simple verification path.

### Negative

- No continuous point-in-time recovery for SQLite in V1.
- Native backup restore is dashboard/API-driven, not yet fully automated in repo scripts.
- Railway platform dependency increases: hosting and volume backup are both Railway-owned.
- Before device/user data exists, this is low risk; after PTS/user data lands, RPO/RTO must be revisited.

### Revisit

Revisit Litestream/R2 or another external backup when any of these happen:

- `/v1/devices` stores production PTS tokens
- user-generated schedules/logs are synced to backend
- manual/scheduled Railway backups do not satisfy desired RPO
- cross-provider disaster recovery becomes a requirement
- Railway volume restore drill fails

## References

- Issue [#37](https://github.com/kswift1/PillPouch/issues/37)
- Stage 3 report `docs/report/task_W3_37_stage3.md`
- Railway Volume Backups: https://docs.railway.com/volumes/backups
- Railway Volumes: https://docs.railway.com/volumes
- Railway volume CLI: https://docs.railway.com/cli/volume
