# task_W3_18_stage1.md — category schema/seed/domain 보고서

## Issue

[#18](https://github.com/kswift1/PillPouch/issues/18) — 백엔드 catalog endpoint + 시드 마이그레이션 + 이미지 hosting

## Stage 1 범위

계획서 기준 Stage 1: category schema, 16종 seed, domain type, migration smoke test.

## 한 일

- `domain::Category`, `CategoryError` 추가.
- `category` table schema migration 추가.
- ADR-0007/#17 기준 16종 seed migration 추가.
- `server/seed/categories.json` 추가.
- migration smoke test를 `recommendations` + `category` table 존재, category 16 row 확인으로 확장.

## 변경 파일

- Added
  - `server/crates/domain/src/category.rs`
  - `server/migrations/0002_category.sql`
  - `server/migrations/0003_seed_categories.sql`
  - `server/seed/categories.json`
- Modified
  - `server/crates/domain/src/lib.rs`
  - `server/crates/storage/src/lib.rs`

## 검증 결과

- [x] `category` table migration 생성
- [x] 16종 seed migration 생성
- [x] `Category` serde roundtrip test 통과
- [x] migration 후 `category` table 존재 확인
- [x] migration 후 `category` row count 16 확인
- [x] `cargo fmt`
- [x] `cargo test` — 14 tests passed

## 발견한 이슈 / 추가 작업

- Stage 1에서는 storage repository/API/static route는 아직 구현하지 않았다. 다음 Stage 2에서 `storage::categories`, `/v1/categories`, static asset serving을 붙인다.
- #18 본문은 12종 기준이나, Stage 1 seed는 계획서 승인 내용대로 #17 최종 16종 기준으로 작성했다.

## 승인 요청

Stage 2로 진행하려면 `storage::categories`, `/v1/categories`, `/assets/category-icons/{key}.png` 정적 서빙과 통합 테스트를 구현한다.
