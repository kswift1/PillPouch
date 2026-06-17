# task_W3_37_stage2.md - Railway config/project/service/volume 단계보고서

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#37](https://github.com/kswift1/PillPouch/issues/37) |
| Stage | 2 - Railway config/project/service/volume |
| 작성일 | 2026-06-17 |

## 한 일

- Railway config-as-code 파일을 추가했다.
  - `server/railway.toml`
- Railway project를 새로 만들었다.
  - Project: `PillPouch`
  - Project ID: `cf1ad73a-f08e-4353-933c-bfb42da2b63a`
  - Environment: `production`
- Railway service를 만들고 현재 workspace에 link했다.
  - Service: `api`
  - Service ID: `7a6df165-dc50-4a4b-89cc-dfc21481a4e5`
- Railway volume을 service에 붙였다.
  - Volume: `api-volume`
  - Mount path: `/data`
  - Size: 4.9 GB
- Railway service variables를 설정했다.
- Railway-provided public domain을 생성했다.
  - `https://api-production-58ff5.up.railway.app`
- 첫 Railway deployment와 endpoint smoke test를 완료했다.

## Railway config

```toml
[build]
builder = "DOCKERFILE"
dockerfilePath = "Dockerfile"

[deploy]
healthcheckPath = "/healthz"
healthcheckTimeout = 100
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 10
```

`railway up ./server --path-as-root`와 Railway service Root Directory `/server` 양쪽에서 같은 root를 쓰기 위해 `watchPatterns`는 두지 않았다.

## Variables

```text
DATABASE_URL=sqlite:///data/pillpouch.db
SEED_RECOMMENDATIONS_PATH=seed/recommendations.json
SEED_CATEGORIES_PATH=seed/categories.json
STATIC_ASSETS_DIR=assets
RUST_LOG=info
```

## Deployment

최종 성공 deployment:

```text
Deployment ID: caa49767-457b-41b5-92d2-d4ebc4a77c93
Status: SUCCESS
URL: https://api-production-58ff5.up.railway.app
Region: sfo
Volume: api-volume · /data
```

실행 명령:

```bash
railway up ./server \
  --path-as-root \
  --service api \
  --environment production \
  --detach \
  --json \
  --message "Stage 2 Railway smoke deploy - remove watch patterns"
```

## Build 이슈와 수정

### 1차 실패 - Rust builder version

첫 deployment `8a914018-64fb-4c3f-97e2-46d9f4d6216a`는 실패했다.

원인:

```text
home-0.5.12/Cargo.toml
feature `edition2024` is required
Cargo 1.83.0 cannot parse it
```

수정:

- `server/Dockerfile`: `rust:1.83-bookworm` -> `rust:1-bookworm`
- `server/Cargo.toml`: workspace `rust-version` `1.83` -> `1.85`
- `docs/plans/task_W3_37_impl.md`, Stage 1 보고서 builder 설명 정합

### 2차 skip - watchPatterns root mismatch

두 번째 deployment `04306232-5657-490e-bcb9-6566040494a9`는 `SKIPPED`였다.

원인:

- `railway up ./server --path-as-root`는 `server/`를 deployment root로 삼는다.
- 그런데 `server/railway.toml`에 `watchPatterns = ["server/**"]`가 있어 root mismatch로 변경 감지가 빗나갔다.

수정:

- `server/railway.toml`에서 `watchPatterns` 제거

## Runtime logs

성공 deployment 로그:

```text
Mounting volume on: ...
Starting Container
connecting db: sqlite:///data/pillpouch.db
seeded 5 recommendations from seed/recommendations.json
seeded 16 categories from seed/categories.json
listening on 0.0.0.0:8080
```

Railway domain은 target port 8080으로 생성했다.

## Smoke test

```text
GET https://api-production-58ff5.up.railway.app/healthz
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

## GitHub 연결 배포

아직 연결하지 않았다.

이유:

- 이번 deployment는 로컬 workspace의 uncommitted `server/Dockerfile`, `server/railway.toml`, `PORT` fallback 변경을 포함한다.
- 현재 `origin/main`에는 이 파일들이 없으므로 지금 GitHub autodeploy를 연결하면 main 기준 재배포가 실패할 수 있다.

Stage 4에서 PR merge 이후 또는 merge 직전 승인 하에 GitHub source 연결을 진행한다.

## 검증

- Railway project/service/volume 생성 완료
- Railway remote Docker build 검증 완료
- Railway public endpoint smoke 통과
- SQLite DB 파일은 `/data/pillpouch.db`로 생성됨

## 남은 위험

- 현재 deployment는 CLI upload 기반이며, GitHub autodeploy는 아직 미연결이다.
- region은 `sfo`로 표시된다. Railway edge는 smoke response에서 `asia-southeast1` edge를 사용했지만 app replica region 자체는 Fly Tokyo보다 멀다.
- SQLite backup/restore 정책은 Stage 3에서 결정해야 한다.
- `api.pillpouch.app` custom domain은 아직 연결하지 않았다.

## 다음 단계

Stage 3에서 다음을 진행한다.

- Railway volume DB 파일 확인
- SQLite integrity check
- Railway volume backup/restore 방식 확인
- Litestream/R2 유지 여부 결정
