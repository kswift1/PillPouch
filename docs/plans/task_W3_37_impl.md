# task_W3_37_impl.md - Railway 첫 배포 + GitHub 연결 + SQLite 백업 구현계획서

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#37](https://github.com/kswift1/PillPouch/issues/37) |
| 마일스톤 | W3 |
| 크기 | L |
| 영역 | area:server / area:infra |
| 타입 | type:feat |
| 현재 브랜치 | `kswift1/review-current-state` |
| 기준 브랜치 | `origin/main` |
| 수행계획서 | [`task_W3_37.md`](task_W3_37.md) |

## 구현 원칙

- Fly 배포 파일을 만들지 않는다.
- Railway Hobby 결제 중인 workspace를 우선 활용한다.
- Railway GitHub 연결 배포를 표준 경로로 삼는다.
- Railway가 주입하는 `PORT`를 서버가 읽도록 한다.
- APNs/PTS는 이번 task에서 다루지 않는다.
- 서버 동작에 필요한 파일(`migrations`, `seed`, `assets`)이 Docker image에 포함되는지 smoke test로 확인한다.

## 변경 파일 예상

| 파일 | 변경 |
|---|---|
| `docs/adr/0012-railway-hosting.md` | ADR-0003 supersede |
| `docs/adr/0003-fly-io-hosting.md` | Superseded 표기만 추가 |
| `server/Dockerfile` | Rust release build + runtime image |
| `server/.dockerignore` | target/불필요 파일 제외 |
| `server/railway.toml` 또는 `railway.toml` | Railway config-as-code |
| `server/crates/api/src/main.rs` | `PORT` fallback |
| `docs/runbooks/deploy.md` | Railway 첫 배포/일상 배포/롤백 절차 |
| `docs/runbooks/litestream-restore.md` | Railway volume backup 또는 Litestream 보류 기준 정합 |
| `README.md`, `server/README.md` | hosting 표기 Railway 기준 갱신 |
| `docs/report/task_W3_37_stage{0~4}.md` | 단계 보고서 |
| `docs/report/task_W3_37_report.md` | 최종 보고서 |

## Stage 0 - ADR/계획 정합

### 0.1 ADR-0012 작성

내용:

- Context: Railway Hobby $5 결제 중, 운영 비용 중복 회피
- Decision: V1 backend hosting을 Railway로 변경
- Consequences:
  - 장점: 결제 중인 플랫폼 활용, GitHub 연결 배포 단순, volume 제공
  - 단점: 기존 Fly 도쿄 리전 결정 폐기, PTS latency 우려
  - 재검토: PTS latency가 사용자 체감/스케줄 정확성에 영향 주면 Fly 도쿄 또는 다른 Asia region 재검토

### 0.2 ADR-0003 정리

ADR-0003 본문 대수정은 하지 않는다.
상단 Status만 `Superseded by ADR-0012 - 2026-06-17`로 바꾼다.

### 0.3 stale 문구 목록

이번 PR에서 최소 정합할 문서:

- `README.md` hosting 표기
- `server/README.md` deploy section
- `docs/runbooks/deploy.md`
- `docs/runbooks/litestream-restore.md`

ADR-0008의 "Fly static"은 static asset serving 결정으로 해석하고, 필요하면 ADR-0012에서 Railway runtime static serving으로 정합한다.

## Stage 1 - Docker image + Railway PORT 정합

### 1.1 `main.rs` 수정

현재:

```rust
let bind_addr: SocketAddr = env::var("BIND_ADDR")
    .unwrap_or_else(|_| "0.0.0.0:8080".to_string())
    .parse()?;
```

변경:

```text
BIND_ADDR 있으면 그대로 사용
없고 PORT 있으면 0.0.0.0:{PORT}
둘 다 없으면 0.0.0.0:8080
```

검증:

- `PORT=18080 DATABASE_URL=sqlite::memory: cargo run -p api`
- `/healthz` smoke

### 1.2 Dockerfile 작성

구성:

- builder: Rust stable 계열 (`rust:1-bookworm`)
- `cargo build --release -p api --bin pillpouch-api`
- runtime: Debian slim 계열
- `WORKDIR /app`
- copy:
  - `pillpouch-api`
  - `migrations/`
  - `seed/`
  - `assets/`

CMD:

```text
pillpouch-api
```

Railway가 `PORT`를 주입하므로 Dockerfile에서 `BIND_ADDR`를 고정하지 않는다.

### 1.3 `.dockerignore`

제외:

- `target/`
- `.git/`
- `.env*`
- local temp/cache

### 1.4 로컬 컨테이너 검증

```bash
cd server
cargo test --workspace --all-targets
docker build -t pillpouch-api:railway .
docker run --rm -p 18080:18080 \
  -e PORT=18080 \
  -e DATABASE_URL=sqlite:///data/pillpouch.db \
  -e SEED_RECOMMENDATIONS_PATH=seed/recommendations.json \
  -e SEED_CATEGORIES_PATH=seed/categories.json \
  -e STATIC_ASSETS_DIR=assets \
  -v "$(pwd)/.tmp-data:/data" \
  pillpouch-api:railway
```

확인:

```bash
curl -sS http://127.0.0.1:18080/healthz
curl -sS http://127.0.0.1:18080/v1/recommendations | jq '.recommendations | length'
curl -sS http://127.0.0.1:18080/v1/categories | jq '.categories | length, .serverVersion'
curl -I http://127.0.0.1:18080/assets/category-icons/omega3.png
```

## Stage 2 - Railway config/project/service/volume

### 2.1 config-as-code

Railway docs 기준 `railway.toml` 또는 `railway.json`을 사용한다.
Dockerfile path가 `server/Dockerfile`이면 repo root config가 유리하다.
구현 시 둘 중 하나로 확정한다.

예상 설정:

```toml
[build]
builder = "DOCKERFILE"
dockerfilePath = "server/Dockerfile"

[deploy]
healthcheckPath = "/healthz"
healthcheckTimeout = 100
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 10
```

Railway service variables:

```text
DATABASE_URL=sqlite:///data/pillpouch.db
SEED_RECOMMENDATIONS_PATH=seed/recommendations.json
SEED_CATEGORIES_PATH=seed/categories.json
STATIC_ASSETS_DIR=assets
RUST_LOG=info
```

### 2.2 Railway login/link

현재 CLI auth가 만료되어 있다.

```bash
railway login
railway link
railway status
```

기존 결제 중인 project가 있으면 그 project에 link한다.
없으면 작업지시자 확인 후 새 project를 만든다.

### 2.3 Volume

Railway dashboard에서 service에 volume을 붙이고 mount path를 `/data`로 설정한다.
Railway docs 기준 volume은 runtime에만 mount되므로 DB 작업은 app start 이후에만 수행한다.

### 2.4 첫 배포

선호:

- Railway dashboard에서 GitHub repo 연결
- production branch `main`
- watch path는 `server/**`, `railway.toml`, `.github/workflows/server-build.yml` 등으로 제한 검토

CLI fallback:

```bash
railway up --service api --environment production
```

### 2.5 smoke

```bash
railway logs --service api
curl -sS https://<railway-domain>/healthz
curl -sS https://<railway-domain>/v1/recommendations | jq '.recommendations | length'
curl -sS https://<railway-domain>/v1/categories | jq '.categories | length, .serverVersion'
curl -I https://<railway-domain>/assets/category-icons/omega3.png
```

## Stage 3 - SQLite backup/restore

### 3.1 결정

두 옵션을 비교한다.

1. Railway volume backup 사용
2. 기존 ADR-0002대로 Litestream + R2 유지

V1에서는 Railway volume backup이 충분하면 Litestream/R2는 보류한다.
단, PITR 요구가 살아 있으면 Litestream을 유지한다.

### 3.2 검증

CLI/SSH 가능 범위에서 확인:

```bash
railway ssh --service api
sqlite3 /data/pillpouch.db "PRAGMA integrity_check;"
sqlite3 /data/pillpouch.db "SELECT COUNT(*) FROM category;"
```

Railway volume backup을 쓸 경우:

- dashboard backup 생성/복구 절차 캡처 또는 명령 기록
- restore 후 smoke test

Litestream을 유지할 경우:

- `server/litestream.yml`
- R2 secrets
- restore dry-run

## Stage 4 - GitHub 연결 배포와 runbook

### 4.1 GitHub 연결 배포

Railway dashboard에서 GitHub repo 연결을 표준으로 한다.
GitHub Actions deploy workflow는 기본 생성하지 않는다.

GitHub Actions가 필요한 경우:

- `RAILWAY_TOKEN` project token을 GitHub secret으로 등록
- `railway up --ci --service api --environment production`

### 4.2 runbook 갱신

`docs/runbooks/deploy.md`:

- Railway login/link
- GitHub repo 연결
- variables
- volume
- deploy
- public domain
- rollback/redeploy/logs

`docs/runbooks/litestream-restore.md`:

- Railway volume backup 사용 시 문서명/내용 정합
- Litestream 보류 시 보류 사유와 재개 조건

### 4.3 문서 정합

- `README.md`: hosting Railway
- `server/README.md`: Railway deploy 명령/variables
- `docs/api.md`: health check 표현에서 Fly 제거 또는 일반화

## Stage 5 - 최종 검증 / 보고서

### 5.1 로컬 검증

```bash
cd server
cargo fmt --all --check
cargo clippy --workspace --all-targets -- -D warnings
cargo test --workspace --all-targets
```

### 5.2 운영 smoke

```bash
curl -sS https://<railway-domain>/healthz
curl -sS https://<railway-domain>/v1/recommendations | jq '.recommendations | length'
curl -sS https://<railway-domain>/v1/categories | jq '.categories | length, .serverVersion'
curl -I https://<railway-domain>/assets/category-icons/omega3.png
```

### 5.3 최종 보고서

파일:

- `docs/report/task_W3_37_report.md`

포함:

- Railway project/service 이름
- public domain
- volume mount path
- endpoint smoke 결과
- GitHub 연결 배포 상태
- 백업/복구 결정
- 남은 수동 작업(custom domain, APNs 등)

## 커밋 단위

1. `docs: supersede Fly hosting ADR with Railway`
2. `ci: add Railway Docker deployment config`
3. `fix: support Railway PORT binding`
4. `docs: document Railway deploy and SQLite restore runbooks`
5. `docs: add task W3 37 reports`

커밋/PR 생성은 최종 보고서 승인 후 별도 승인으로 진행한다.

## 열린 결정

- 기존 Railway project가 있으면 link할지, 새 project를 만들지
- Railway service 이름: 기본 `api`
- public domain을 Railway-provided domain으로 둘지 `api.pillpouch.app` custom domain까지 붙일지
- SQLite backup: Railway volume backup vs Litestream/R2

## 승인 요청

본 구현계획서 승인 전에는 Dockerfile, Railway config, ADR supersede, 서버 코드 수정을 진행하지 않는다.
