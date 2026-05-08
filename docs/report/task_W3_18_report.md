# task_W3_18_report.md — 백엔드 category endpoint + 시드 + 이미지 hosting 최종보고서

## Issue

[#18](https://github.com/kswift1/PillPouch/issues/18) — `[L] 백엔드 catalog endpoint + 시드 마이그레이션 + 이미지 hosting`

## 한 일

- Step 0: RHWP 수행계획서/구현계획서 작성 후 승인.
- Stage 1: `category` schema, 16종 seed, domain type 추가.
- Stage 2: `storage::categories`, `/v1/categories`, `/assets/category-icons/{key}.png` static serving 추가.
- Stage 3: `docs/api.md`, `server/README.md` 갱신 및 최종 검증.

## 변경 파일

- Added
  - `docs/plans/task_W3_18.md`
  - `docs/plans/task_W3_18_impl.md`
  - `docs/report/task_W3_18_stage1.md`
  - `docs/report/task_W3_18_stage2.md`
  - `docs/report/task_W3_18_stage3.md`
  - `server/crates/domain/src/category.rs`
  - `server/crates/storage/src/categories.rs`
  - `server/crates/api/src/categories.rs`
  - `server/migrations/0002_category.sql`
  - `server/migrations/0003_seed_categories.sql`
  - `server/seed/categories.json`
  - `server/assets/category-icons/*.png` 16개
- Modified
  - `docs/api.md`
  - `server/README.md`
  - `server/Cargo.toml`
  - `server/Cargo.lock`
  - `server/crates/domain/src/lib.rs`
  - `server/crates/storage/src/lib.rs`
  - `server/crates/api/src/lib.rs`
  - `server/crates/api/src/main.rs`

## 검증 결과

- [x] 마이그레이션 2개 추가: `0002_category.sql`, `0003_seed_categories.sql`
- [x] category 16종 seed row 확인
- [x] `GET /v1/categories` 통합 테스트 통과
- [x] `GET /v1/categories?since=1` 증분 테스트 통과
- [x] `/assets/category-icons/omega3.png` 응답 200 + `image/png`
- [x] `Cache-Control: public, max-age=86400`
- [x] `cargo fmt --check`
- [x] `cargo clippy --workspace --all-targets -- -D warnings`
- [x] `cargo test` — 22 tests passed
- [x] `docs/api.md` 갱신
- [x] `server/README.md` 갱신
- [x] stage report + final report 작성

## 발견한 이슈 / 추가 작업

- Issue #18 본문은 오래된 12종 표현과 `/api/v1/categories` 경로를 포함한다. 현재 main의 실제 API prefix와 #17 최종 자산 기준에 맞춰 `/v1/categories`와 16종으로 구현했다.
- 실제 Fly 배포, Dockerfile, Litestream, GitHub Actions deploy는 #37 범위로 남긴다.
- iOS에서 category mirror 동기화와 검색 UI에 붙이는 작업은 #19 범위다.

## 메모

- category seed는 SQL 마이그레이션에 박아 기본 DB가 즉시 동작하게 했고, `server/seed/categories.json` upsert도 남겨 이후 배포 seed 갱신 흐름을 recommendations와 맞췄다.
- static icon은 ADR-0008에 맞춰 Fly static 단순 path를 사용한다. 파일명에 hash가 없으므로 캐시는 `max-age=86400`으로 제한했다.
