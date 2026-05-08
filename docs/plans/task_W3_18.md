# task_W3_18.md — 백엔드 catalog endpoint + 시드 마이그레이션 + 이미지 hosting 수행계획서

## 배경 / 동기

Issue [#18](https://github.com/kswift1/PillPouch/issues/18)은 ADR-0007/0008 결정의 백엔드 구현 단계다. 현재 main에는 #31 결과로 Rust 백엔드 골격, SQLite migration, `/healthz`, `/v1/recommendations`가 존재한다. 하지만 영양제 카테고리 서버 SoT는 아직 없다.

본 task는 카테고리 16종을 서버 DB/API/정적 이미지 자산으로 제공해, 후속 #19 모바일 `CategoryMirror` 동기화와 검색 UI가 붙을 수 있는 백엔드 표면을 만든다.

## 목표

- SQLite `category` 테이블과 16종 seed를 추가한다.
- `GET /v1/categories?since={version}` endpoint를 추가한다.
- `/assets/category-icons/{key}.png` Fly static 경로를 Axum에서 제공한다.
- API 문서와 서버 README를 실제 동작 기준으로 갱신한다.
- `cargo fmt`, `cargo clippy -- -D warnings`, `cargo test`를 통과한다.

## 범위

- `server/crates/domain`: 카테고리 도메인 타입/에러.
- `server/crates/storage`: `category` table 접근, list/get/upsert/serverVersion.
- `server/crates/api`: `/v1/categories` handler + static asset route.
- `server/migrations`: schema migration + 16종 seed migration.
- `server/seed`: 배포 시 재-seed 가능한 JSON seed.
- `server/assets/category-icons`: 16개 PNG 정적 자산.
- `docs/api.md`, `server/README.md`, `docs/report/task_W3_18_report.md`.

## 비범위

- iOS `CategoryMirror` import/sync/search UI: #19.
- Fly 실제 배포, Dockerfile, Litestream, GitHub Actions deploy: #37.
- V1.1 SKU endpoint/search/pagination.
- S3/R2/CDN 마이그레이션.
- PTS/APNs device endpoint.

## 현재 상태와 이슈 본문 보정

Issue #18 본문에는 오래된 정보가 섞여 있다.

- `12종`이라고 되어 있으나 #17이 16종으로 완료/머지되었으므로 본 task는 16종 기준으로 진행한다.
- `GET /api/v1/categories`라고 되어 있으나 현재 `docs/api.md`와 #31 구현은 `/v1/*` prefix를 사용한다. 따라서 본 task도 `GET /v1/categories?since={version}`로 구현한다.
- ADR-0007/0008 본문 일부도 12종 표현이 남아 있으나, 같은 ADR의 amendment와 #17 보고서 기준 16종을 따른다.
- 현재 Conductor workspace branch는 `kswift1/check-remaining-tasks`다. 시스템 지시상 브랜치 rename은 하지 않는다. 별도 `local/task18` 브랜치 전환이 필요하면 작업지시자 명시 지시 후 진행한다.

## 접근 방식

기존 #31 recommendations 구현 패턴을 복제한다.

- domain crate에는 순수 타입과 serde 테스트를 둔다.
- storage crate에는 SQL 접근과 migration 기반 테스트를 둔다.
- api crate에는 handler와 Axum router 통합 테스트를 둔다.
- static asset은 ADR-0008에 따라 Fly static 단순 path를 사용한다.
- 파일명에 hash가 없으므로 `Cache-Control: public, max-age=86400`을 사용한다.

## 단계 분할

### Stage 1 — 스키마/시드/도메인

- `category` table migration 추가.
- 16종 seed migration 추가.
- `server/seed/categories.json` 추가.
- `domain::Category`, `CategoryError` 추가.
- storage unit tests로 migration 후 16종 seed 확인.
- Stage 1 보고서 작성 후 승인.

### Stage 2 — API/static hosting

- `GET /v1/categories?since={version}` handler 추가.
- `serverVersion` 계산 추가.
- `/assets/category-icons/{key}.png` static serving 추가.
- 16개 PNG를 `server/assets/category-icons/`에 동봉.
- handler/static 통합 테스트 추가.
- Stage 2 보고서 작성 후 승인.

### Stage 3 — 문서/최종 검증/PR 준비

- `docs/api.md`, `server/README.md` 갱신.
- `cargo fmt --check`, `cargo clippy -- -D warnings`, `cargo test`.
- 최종 보고서 작성.
- PR 본문/라벨/마일스톤 준비. PR 생성과 머지는 별도 승인 후 진행.

## 위험 요소

- 기존 API prefix와 이슈 본문 prefix 불일치: `/v1`로 통일하고 계획서/보고서에 명시한다.
- 16종 seed와 iOS seed 불일치: `ios/PillPouch/Resources/category-seed.json` 및 asset catalog key와 대조한다.
- static asset 경로가 로컬 cwd/Fly image에서 달라질 수 있음: `server/assets`와 `assets` fallback을 둔다.
- 이미지 캐시 stale 가능성: 단순 path이므로 ADR-0008의 `max-age=86400` 선택.

## 승인 게이트

- 본 수행계획서 + 구현계획서 승인 후에만 Stage 1 구현 시작.
- Stage 1, Stage 2 완료 후 각각 보고서와 승인.
- 최종 보고서 승인 후에만 PR 생성/머지 진행.
