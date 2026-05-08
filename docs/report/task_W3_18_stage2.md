# task_W3_18_stage2.md — category storage/API/static 보고서

## Issue

[#18](https://github.com/kswift1/PillPouch/issues/18) — 백엔드 catalog endpoint + 시드 마이그레이션 + 이미지 hosting

## Stage 2 범위

계획서 기준 Stage 2: category storage repository, `/v1/categories` API, `/assets/category-icons/{key}.png` static serving, 통합 테스트.

## 한 일

- `storage::categories` 추가.
  - `list_since(pool, since)`
  - `get(pool, key)`
  - `server_version(pool)`
  - `upsert_many(pool, categories)`
- `seed_categories_from_path` 추가.
- `/v1/categories?since={version}` handler 추가.
- `/assets/category-icons/{key}.png` static serving 추가.
- `Cache-Control: public, max-age=86400` 설정.
- iOS asset catalog의 `@3x` PNG 16개를 `server/assets/category-icons/{key}.png`로 동봉.
- API 통합 테스트와 static asset response 테스트 추가.

## 변경 파일

- Added
  - `server/crates/storage/src/categories.rs`
  - `server/crates/api/src/categories.rs`
  - `server/assets/category-icons/*.png` 16개
- Modified
  - `server/Cargo.toml`
  - `server/Cargo.lock`
  - `server/crates/storage/src/lib.rs`
  - `server/crates/api/src/lib.rs`
  - `server/crates/api/src/main.rs`

## 검증 결과

- [x] `storage::categories` list/get/server_version/upsert tests 통과
- [x] `GET /v1/categories` 통합 테스트: 16종 + `serverVersion=1`
- [x] `GET /v1/categories?since=1` 통합 테스트: 빈 목록 + `serverVersion=1`
- [x] `/assets/category-icons/omega3.png` 200
- [x] static response `Content-Type: image/png`
- [x] static response `Cache-Control: public, max-age=86400`
- [x] `cargo fmt`
- [x] `cargo test` — 22 tests passed

## 발견한 이슈 / 추가 작업

- `tower-http` static serving에 필요한 `fs`/`set-header` feature 활성화로 `Cargo.lock`에 `mime_guess`, `tokio-util` 등 transitive dependency가 추가됐다.
- Stage 3에서 `docs/api.md`, `server/README.md`를 endpoint/env 기준으로 갱신하고 `cargo fmt --check`, `cargo clippy -- -D warnings`, `cargo test` 최종 검증을 실행한다.

## 승인 요청

Stage 3로 진행하려면 문서 갱신, 최종 검증, 최종 보고서 작성을 수행한다.
