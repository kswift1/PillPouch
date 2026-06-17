# task_W3_37_report.md - Railway first deploy final report

## Meta

| Item | Value |
|---|---|
| Issue | [#37](https://github.com/kswift1/PillPouch/issues/37) |
| Milestone | W3 |
| Size | L |
| Area | area:server / area:infra |
| Type | type:feat |
| Branch | `kswift1/review-current-state` |
| Base | `origin/main` |
| Completed | 2026-06-17 |

## Scope correction

Issue #37 still says Fly.io + GitHub Actions CI + Litestream. During planning, the task scope was corrected to Railway because the Railway Hobby plan is already paid for.

The corrected scope is:

- Railway first production deployment
- Railway Docker/config-as-code setup
- Railway volume-backed SQLite
- Railway native volume backup + ad-hoc DB export runbook
- GitHub autodeploy prepared, but not connected until this PR is merged

## Result summary

The Pill Pouch backend is deployed and running on Railway.

| Item | Value |
|---|---|
| Railway project | `PillPouch` |
| Project ID | `cf1ad73a-f08e-4353-933c-bfb42da2b63a` |
| Environment | `production` |
| Environment ID | `cd22b416-9491-4e77-8aea-38bd1da54612` |
| Service | `api` |
| Service ID | `7a6df165-dc50-4a4b-89cc-dfc21481a4e5` |
| Public URL | `https://api-production-58ff5.up.railway.app` |
| Deployment ID | `caa49767-457b-41b5-92d2-d4ebc4a77c93` |
| Deployment status | `SUCCESS`, instance `RUNNING` |
| Replica region | `sfo` |
| Volume | `api-volume` |
| Volume ID | `158911b4-e5e0-48a1-9a66-c265140d6f1e` |
| Mount path | `/data` |
| SQLite URL | `sqlite:///data/pillpouch.db` |

GitHub source is intentionally still disconnected:

```text
source.repo = null
```

Reason: the deployment-critical files in this PR are not on `main` yet. Connecting `main` before merge can trigger a failed Railway deployment from stale source.

## Stage summary

### Stage 0 - ADR / plan alignment

- Added [ADR-0012: Railway 호스팅](../adr/0012-railway-hosting.md).
- Marked [ADR-0003: Fly.io 호스팅](../adr/0003-fly-io-hosting.md) as superseded by ADR-0012.
- Updated the ADR index.
- Documented the issue-title mismatch and Railway scope correction.

Report: [task_W3_37_stage0.md](task_W3_37_stage0.md)

### Stage 1 - Docker image + Railway PORT

- Added Railway-compatible bind address resolution:
  - `BIND_ADDR` wins when present.
  - otherwise Railway `PORT` becomes `0.0.0.0:{PORT}`.
  - otherwise fallback remains `0.0.0.0:8080`.
- Added 3 unit tests for bind address behavior.
- Added `server/Dockerfile`.
- Added `server/.dockerignore`.
- Updated workspace `rust-version` to `1.85` after Railway remote build exposed the Cargo/edition2024 floor.

Report: [task_W3_37_stage1.md](task_W3_37_stage1.md)

### Stage 2 - Railway project / service / volume / deploy

- Added `server/railway.toml`.
- Created Railway project `PillPouch`.
- Created Railway service `api`.
- Attached volume `api-volume` at `/data`.
- Set Railway variables:

```text
DATABASE_URL=sqlite:///data/pillpouch.db
SEED_RECOMMENDATIONS_PATH=seed/recommendations.json
SEED_CATEGORIES_PATH=seed/categories.json
STATIC_ASSETS_DIR=assets
RUST_LOG=info
```

- Deployed with local CLI upload:

```bash
railway up ./server \
  --path-as-root \
  --service api \
  --environment production \
  --detach \
  --json \
  --message "Stage 2 Railway smoke deploy - remove watch patterns"
```

- Verified Railway remote Docker build and public endpoint smoke.

Report: [task_W3_37_stage2.md](task_W3_37_stage2.md)

### Stage 3 - SQLite backup / restore decision

- Registered a Railway SSH key for volume file inspection.
  - Key name: `railway-pillpouch-codex-20260617`
  - Fingerprint: `SHA256:ese2eS5x/SSriIwlKIb3hCrR7FPxPlIEwjSEs87QmW8`
- Downloaded `/pillpouch.db` from the Railway volume.
- Verified SQLite integrity and row counts.
- Added [ADR-0013: Railway Volume Backups for V1 SQLite](../adr/0013-railway-volume-backups.md).
- Marked the backup mechanism part of ADR-0002 as partially superseded.
- Rewrote [litestream-restore.md](../runbooks/litestream-restore.md) as the Railway SQLite backup/restore runbook.

Decision: use Railway native volume backups + ad-hoc verified DB export for V1. Defer Litestream/R2 until production user data, PITR, cross-provider backup, or restore drill requirements justify the added runtime complexity.

Report: [task_W3_37_stage3.md](task_W3_37_stage3.md)

### Stage 4 - Docs / runbooks / GitHub autodeploy prep

- Rewrote [deploy.md](../runbooks/deploy.md) as the Railway deploy runbook.
- Updated runbook index and operating docs to Railway wording.
- Documented the post-merge GitHub autodeploy command:

```bash
railway service source connect \
  --service api \
  --repo kswift1/PillPouch \
  --branch main \
  --json
```

- Did not connect GitHub source yet because `main` does not have the deployment files until this PR merges.

Report: [task_W3_37_stage4.md](task_W3_37_stage4.md)

### Stage 5 - Final verification / PR prep

- Re-ran full Rust validation.
- Re-ran Railway smoke tests against production URL.
- Confirmed Railway service is still `SUCCESS` / `RUNNING`.
- Prepared PR body in `.context/task_W3_37_pr_body.md`.

## Verification

### Local Rust checks

```text
cargo fmt --all --check
=> passed

cargo test --workspace --all-targets
=> passed, 25 tests

cargo clippy --workspace --all-targets -- -D warnings
=> passed

cargo build --release -p api --bin pillpouch-api
=> passed
```

### Railway smoke

Base URL:

```text
https://api-production-58ff5.up.railway.app
```

Results:

```text
GET /healthz
=> ok

GET /v1/recommendations | jq '.recommendations | length'
=> 5

GET /v1/categories | jq '(.categories | length), .serverVersion'
=> 16
=> 1

HEAD /assets/category-icons/omega3.png
=> HTTP/2 200
=> content-type: image/png
=> cache-control: public, max-age=86400
=> server: railway-hikari
```

### Railway status

```text
Project: PillPouch
Service: api
Latest deployment: caa49767-457b-41b5-92d2-d4ebc4a77c93
Deployment status: SUCCESS
Instance status: RUNNING
Public domain: api-production-58ff5.up.railway.app
Volume: api-volume /data
GitHub source: not connected
```

### SQLite backup verification

Downloaded DB:

```text
.context/task_W3_37_stage3/pillpouch.db
```

Checks:

```text
PRAGMA integrity_check
=> ok

tables
=> _sqlx_migrations
=> category
=> recommendations

row counts
=> category|16
=> recommendations|5

sha256
=> d31ff98fba1d0bc17646c4d93c0ed41034b056ec2710acf2edbf5485453b829b
```

## Changed files

Added:

- `docs/adr/0012-railway-hosting.md`
- `docs/adr/0013-railway-volume-backups.md`
- `docs/plans/task_W3_37.md`
- `docs/plans/task_W3_37_impl.md`
- `docs/report/task_W3_37_stage0.md`
- `docs/report/task_W3_37_stage1.md`
- `docs/report/task_W3_37_stage2.md`
- `docs/report/task_W3_37_stage3.md`
- `docs/report/task_W3_37_stage4.md`
- `docs/report/task_W3_37_report.md`
- `server/.dockerignore`
- `server/Dockerfile`
- `server/railway.toml`

Modified:

- `README.md`
- `docs/adr/0002-sqlite-litestream.md`
- `docs/adr/0003-fly-io-hosting.md`
- `docs/adr/README.md`
- `docs/api.md`
- `docs/architecture.md`
- `docs/runbooks/README.md`
- `docs/runbooks/deploy.md`
- `docs/runbooks/litestream-restore.md`
- `server/Cargo.toml`
- `server/README.md`
- `server/crates/api/src/lib.rs`
- `server/crates/api/src/main.rs`

Local-only helper artifact:

- `.context/task_W3_37_pr_body.md`

## Open risks / remaining manual work

- GitHub autodeploy is not connected yet. Connect after this PR is merged into `main`.
- Custom domain `api.pillpouch.app` is not connected yet.
- APNs secrets are not configured in Railway yet. This belongs with the PTS/device endpoint work.
- Railway replica region is currently `sfo`; PTS latency should be revisited when push delivery becomes part of production behavior.
- Docker local smoke was not possible because Docker CLI is not installed in this environment. Railway remote Docker build succeeded and local release build passed.
- Railway native backup restore was documented and DB export was verified, but a full native restore drill was not executed from Dashboard/API.
- The registered Railway SSH key remains on the account for volume inspection. Remove it from Railway account settings if it is no longer needed.

## Hypothesis / non-goal gate

- [x] This change is infra/deploy work and does not weaken hypothesis B.
- [x] This change does not add a non-goal from `docs/brief.md`.
- [x] No product-surface or medical-claim behavior was added.

## PR readiness

PR body draft:

- `.context/task_W3_37_pr_body.md`

Before PR creation:

1. Review this final report.
2. Approve PR creation.
3. Create PR with labels `size:L`, `area:server`, `area:infra`, `type:feat`.
4. Assign milestone `W3`.
5. Use `Closes #37`.

After PR merge:

1. Connect Railway GitHub source:

```bash
railway service source connect \
  --service api \
  --repo kswift1/PillPouch \
  --branch main \
  --json
```

2. Confirm a GitHub-source deployment succeeds.
3. Re-run production smoke tests.

## Approval request

Final RHWP approval is required before creating the PR.
