# task_W3_37.md - Railway 첫 배포 + GitHub 연결 + SQLite 백업 수행계획서

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
| 작성일 | 2026-06-17 |

## 배경 / 동기

PR #36/#38로 Rust 백엔드와 read-only endpoint는 main에 들어갔다.
현재 서버는 로컬에서 다음 endpoint를 제공한다.

- `GET /healthz`
- `GET /v1/recommendations`
- `GET /v1/categories?since={version}`
- `GET /assets/category-icons/{key}.png`

하지만 실제 운영 배포 표면은 아직 없다.

- Dockerfile 없음
- Railway config-as-code 없음
- Railway project/service link 없음
- persistent volume 설정 없음
- GitHub 연결 배포 절차 문서 없음
- `docs/runbooks/deploy.md`, `docs/runbooks/litestream-restore.md`는 Fly 기준 stub

작업지시자 코멘트:

> 다른 플랫폼 레일웨이였나 그거 5달러 결제중이야

따라서 본 task는 기존 Fly 배포 계획을 버리고, 이미 결제 중인 Railway Hobby 플랜을 활용한다.

## 문서 충돌

현재 repo에는 Fly.io 결정이 Accepted ADR로 박혀 있다.

- `docs/adr/0003-fly-io-hosting.md`: Fly.io 도쿄 리전 선택
- `docs/adr/0008-category-image-hosting.md`: V1.0 Fly static
- `README.md`, `server/README.md`, runbook stub 일부: Fly 기준

Railway로 배포하려면 기존 ADR-0003을 직접 수정하지 않고, 신규 ADR로 supersede해야 한다.

계획:

- `docs/adr/0012-railway-hosting.md` 신설
- ADR-0003은 Accepted 상태 그대로 두되 `Superseded by ADR-0012` 표기만 추가
- ADR-0008은 "Fly static" 문구를 "app static asset serving"으로 후속 정합하거나, ADR-0012에서 Railway static serving으로 범위를 한정해 명시
- README/runbook/server docs는 구현 단계에서 Railway 기준으로 갱신

## 현재 확인 결과

- Railway CLI 설치됨: `railway 4.59.0`
- Railway CLI auth는 만료됨: `Token refresh failed: invalid_grant`
- 현재 directory는 Railway project에 link되어 있지 않음: `No linked project found`
- GitHub repo secret 목록에는 현재 표시되는 secret 없음
- 기존 build CI는 있음:
  - `.github/workflows/server-build.yml`
  - `.github/workflows/ios-build.yml`

## Railway 공식 문서 기준

확인일: 2026-06-17

- Railway는 `railway.toml` 또는 `railway.json` config-as-code를 지원한다.
- Dockerfile이 있으면 Railway가 Dockerfile build를 사용한다.
- Railway web service는 `0.0.0.0:$PORT`로 listen해야 한다. `PORT`는 Railway가 주입한다.
- Volume은 서비스에 mount path를 설정해야 하고, runtime에만 mount된다.
- Railway Hobby는 월 $5 minimum usage이며 $5 monthly usage credit을 포함한다.

## 목표

W3 서버를 Railway에 배포하고, GitHub repo 연결로 main merge 시 자동 배포되게 한다.

성공 기준:

- Railway project/service가 `PillPouch` repo와 연결된다.
- 서버가 Railway public domain에서 응답한다.
- `/healthz`가 200과 `"ok"`를 반환한다.
- `/v1/recommendations`가 5개 카테고리를 반환한다.
- `/v1/categories`가 16개 카테고리와 `serverVersion=1`을 반환한다.
- `/assets/category-icons/omega3.png`가 `image/png`와 `Cache-Control`을 반환한다.
- SQLite DB가 Railway volume에 저장된다.
- SQLite 백업/복구 절차가 실제 명령 기준으로 문서화된다.

## 범위

- Railway hosting 결정 ADR 작성
- Rust 서버가 Railway `PORT`를 우선 사용하도록 정합
- Docker image 구성
- Railway config-as-code (`railway.toml` 또는 `railway.json`)
- Railway project/service/volume 설정 절차
- GitHub-connected deploy 절차
- SQLite volume backup/restore runbook
- 첫 deploy smoke test

## 비범위

- Fly app 생성/배포
- APNs `.p8`와 Push to Start device endpoint
- `/v1/devices` 계열 API
- iOS `CategoryMirror` 동기화 UI (#19)
- iOS 앱 골격/탭/CRUD/온보딩 (#35)
- App Store/TestFlight 배포

## 접근 방식

### 배포 방식

Railway dashboard에서 기존 결제 중인 workspace/project를 사용한다.
가능하면 GitHub repo 연결 배포를 표준으로 삼는다.
CLI는 link, variable 확인, manual deploy, logs/status 확인에 사용한다.

대안으로 GitHub Actions에서 `railway up --ci`를 실행할 수 있지만, Railway가 GitHub 연결 배포를 이미 제공하므로 V1 운영 표면은 dashboard 연결을 우선한다.

### Dockerfile

처음에는 단순 multi-stage Dockerfile을 사용한다.

- builder stage: Rust toolchain으로 `pillpouch-api` release build
- runtime stage: Debian slim 계열 + `ca-certificates`
- runtime image에 포함:
  - `pillpouch-api`
  - `migrations/`
  - `seed/`
  - `assets/`

Litestream은 Railway volume/backup 정책과 충돌 가능성이 있어 Stage 3에서 별도 판단한다.
Railway volume backup으로 충분하면 Litestream/R2는 V1에서 보류하고 ADR-0002 후속 메모로 남긴다.

### Railway PORT

현재 서버는 `BIND_ADDR` 기본값 `0.0.0.0:8080`을 사용한다.
Railway에서는 `PORT`를 우선해야 하므로 서버 진입점은 다음 우선순위로 변경한다.

1. `BIND_ADDR`
2. `PORT`가 있으면 `0.0.0.0:{PORT}`
3. fallback `0.0.0.0:8080`

### SQLite

Railway volume mount path는 `/data`로 둔다.

서버 환경변수:

```text
DATABASE_URL=sqlite:///data/pillpouch.db
SEED_RECOMMENDATIONS_PATH=seed/recommendations.json
SEED_CATEGORIES_PATH=seed/categories.json
STATIC_ASSETS_DIR=assets
RUST_LOG=info
```

`BIND_ADDR`는 Railway에서 설정하지 않는다. Railway가 주입하는 `PORT`를 사용하게 한다.

## 단계 분할

### Stage 0 - ADR/계획 정합

산출물:

- `docs/adr/0012-railway-hosting.md`
- ADR-0003에 superseded 표기
- 필요 시 #37 계획서/이슈 제목 mismatch 기록

검증:

- Fly 결정이 왜 Railway로 바뀌는지 명확히 문서화
- Railway $5 결제 중이라는 운영 현실 반영

승인 게이트: Stage 0 보고 후 Stage 1 진행.

### Stage 1 - Docker image + Railway PORT 정합

산출물:

- `server/Dockerfile`
- `server/.dockerignore`
- `server/crates/api/src/main.rs` `PORT` fallback
- 관련 테스트 또는 smoke 절차

검증:

- `cargo test --workspace --all-targets`
- `docker build`
- `docker run -e PORT=18080`으로 `/healthz`, `/v1/recommendations`, `/v1/categories`, static PNG 확인

승인 게이트: Stage 1 보고 후 Stage 2 진행.

### Stage 2 - Railway project/service/volume + 첫 배포

산출물:

- `server/railway.toml` 또는 root `railway.toml`
- Railway project/service link
- Railway volume `/data`
- Railway variables 설정 절차

검증:

- `railway login`
- `railway link`
- `railway up` 또는 GitHub-connected deploy
- Railway public domain에서 endpoint smoke test

승인 게이트: Stage 2 보고 후 Stage 3 진행.

### Stage 3 - SQLite 백업/복구 결정

산출물:

- Railway volume backup 절차 문서화
- Litestream/R2를 유지할지 보류할지 결정
- 필요 시 ADR-0002 후속 note 또는 ADR-0012 consequences에 반영

검증:

- volume file 확인
- SQLite `PRAGMA integrity_check`
- 가능한 경우 backup/restore dry-run

승인 게이트: Stage 3 보고 후 Stage 4 진행.

### Stage 4 - GitHub 연결 배포와 runbook

산출물:

- GitHub-connected deploy 절차
- 필요 시 `.github/workflows/server-deploy.yml` 대신 Railway deployment status 활용 여부 결정
- `docs/runbooks/deploy.md` Railway 기준 갱신
- `docs/runbooks/litestream-restore.md` 또는 `sqlite-restore.md` 정합

검증:

- main 또는 manual deploy 로그 확인
- endpoint smoke test 재실행

승인 게이트: Stage 4 보고 후 Stage 5 진행.

### Stage 5 - 최종 보고서 / PR 준비

산출물:

- `docs/report/task_W3_37_report.md`

검증:

- `cargo fmt --check`
- `cargo clippy --workspace --all-targets -- -D warnings`
- `cargo test --workspace --all-targets`
- Railway endpoint smoke 결과 기록

최종 보고서 승인 후에만 PR 생성/머지 진행.

## 위험 요소

- 기존 ADR-0003과 충돌한다. 신규 ADR로 supersede하지 않으면 repo SoT가 깨진다.
- Railway CLI auth가 만료되어 작업지시자 `railway login`이 필요하다.
- Railway project/service가 이미 있을 수 있으므로 새로 만들지 link할지 확인해야 한다.
- Railway region/latency는 Fly 도쿄보다 불리할 수 있다. V1 read-heavy endpoint는 허용 가능하나 PTS 발송 SLA에는 영향이 있을 수 있다.
- Railway volume mount는 runtime에만 붙는다. pre-deploy에서 DB 파일을 만지면 안 된다.
- Docker image에 `seed/`, `assets/`가 누락되면 endpoint가 빈 데이터/404가 될 수 있다.
- SQLite + Litestream 기존 ADR과 Railway volume backup 정책 사이 결정이 필요하다.

## 가설 검증 게이트

- [ ] 가설 B 무관 - 인프라 작업
- [ ] Anti-Promise §5 정합 - 사용자 데이터 외부 송신 없음. 단, Railway hosting/volume backup은 운영 인프라로 명시한다.
- [ ] Non-goals 미해당
- [ ] Fly decision supersede가 ADR로 남는다.
- [ ] 이미 결제 중인 Railway Hobby 플랜을 활용한다.

## 승인 요청

본 수행계획서와 `task_W3_37_impl.md` 승인 후 Stage 0부터 구현을 시작한다.
