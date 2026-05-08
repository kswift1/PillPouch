# task_W3_18_stage3.md — docs/final verification 보고서

## Issue

[#18](https://github.com/kswift1/PillPouch/issues/18) — 백엔드 catalog endpoint + 시드 마이그레이션 + 이미지 hosting

## Stage 3 범위

계획서 기준 Stage 3: API/서버 문서 갱신, 최종 Rust 검증, 최종 보고서 작성.

## 한 일

- `docs/api.md`에 `/v1/categories?since={version}`와 `/assets/category-icons/{key}.png`를 완료 endpoint로 이동.
- `/v1/categories` 응답 schema와 `Cache-Control` 정책 문서화.
- `server/README.md`를 현재 구현 상태와 로컬 실행/env 기준으로 갱신.
- 최종 검증 3종 실행.

## 변경 파일

- Modified
  - `docs/api.md`
  - `server/README.md`

## 검증 결과

- [x] `cargo fmt --check`
- [x] `cargo clippy --workspace --all-targets -- -D warnings`
- [x] `cargo test` — 22 tests passed

## 발견한 이슈 / 추가 작업

- 실제 Fly 배포 이미지에 `server/assets`와 seed 파일이 포함되는지는 #37 Dockerfile/Fly 배포 작업에서 다시 확인해야 한다.
- iOS가 `/v1/categories`를 소비해 `CategoryMirror`에 반영하는 작업은 #19로 남는다.
