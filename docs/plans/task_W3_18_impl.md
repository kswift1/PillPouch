# task_W3_18_impl.md — 백엔드 category endpoint 구현계획서

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#18](https://github.com/kswift1/PillPouch/issues/18) |
| 마일스톤 | W3 |
| 크기 | L |
| 영역 | area:server |
| 타입 | type:feat |
| 현재 브랜치 | `kswift1/check-remaining-tasks` |
| 기준 브랜치 | `origin/main` |
| 선행 문서 | [`task_W3_18.md`](task_W3_18.md) |

## 목표

카테고리 16종을 서버 SoT로 제공한다. 모바일은 후속 #19에서 이 endpoint를 사용해 `CategoryMirror`를 동기화한다.

## 구현 단계

### 1. Category domain + migration

- `server/crates/domain/src/category.rs` 추가.
- `Category { key, display_name, icon_path, display_order, version, updated_at }` 정의.
- `CategoryError` 정의.
- `server/crates/domain/src/lib.rs` export 갱신.
- `server/migrations/0002_category.sql` 추가.
- `server/migrations/0003_seed_categories.sql` 추가.

검증:
- domain serde roundtrip test.
- migration test에서 `category` table 존재 + row count 16 확인.

### 2. Category storage

- `server/crates/storage/src/categories.rs` 추가.
- `list_since(pool, since)` 구현.
- `get(pool, key)` 구현.
- `server_version(pool)` 구현.
- `upsert_many(pool, categories)` 구현.
- `seed_categories_from_path` 추가.

검증:
- 전체 목록 display_order 정렬.
- `since=1`이면 빈 목록.
- version bump row만 증분 반환.
- missing key는 `NotFound`.
- 신규 category upsert 가능.

### 3. API handler + router

- `server/crates/api/src/categories.rs` 추가.
- `GET /v1/categories?since={version}` 구현.
- 응답은 camelCase:

```json
{
  "categories": [
    {
      "key": "omega3",
      "displayName": "오메가-3",
      "iconUrl": "/assets/category-icons/omega3.png",
      "displayOrder": 1,
      "version": 1,
      "updatedAt": 1777388476
    }
  ],
  "serverVersion": 1
}
```

- `server/crates/api/src/lib.rs` router에 `/v1/categories` 추가.

검증:
- `/v1/categories` 통합 테스트: 16종 + `serverVersion=1`.
- `/v1/categories?since=1` 통합 테스트: 빈 categories + `serverVersion=1`.

### 4. Static assets

- `server/assets/category-icons/{key}.png` 16개 추가.
- 원본은 iOS asset catalog의 `@3x` PNG를 사용한다.
- `tower_http::services::ServeDir` 또는 `nest_service`로 `/assets` route 추가.
- `Cache-Control: public, max-age=86400` 설정.

검증:
- `/assets/category-icons/omega3.png` 200.
- `Content-Type`이 `image/png`.
- `Cache-Control` header 확인.

### 5. Runtime seed/env

- `server/seed/categories.json` 추가.
- `SEED_CATEGORIES_PATH` env 지원.
- `STATIC_ASSETS_DIR` env 지원.
- repo root 실행과 `server/` cwd 실행 모두 지원하도록 기본 경로 fallback.

검증:
- `cargo test`로 seed parse/upsert path 검증.
- README에 env 문서화.

### 6. Docs/report

- `docs/api.md`에 `/v1/categories`와 `/assets/category-icons/{key}.png` 추가.
- `server/README.md` 로컬 실행/env 업데이트.
- `docs/report/task_W3_18_stage1.md`, `stage2`, `stage3`, 최종 `task_W3_18_report.md` 작성.

## 커밋 단위

1. `feat(server): add category catalog storage seed`
2. `feat(server): expose category endpoint and static icons`
3. `docs(server): document category catalog endpoint`

필요하면 Stage 승인 단위에 맞춰 커밋을 나눈다.

## 위험 요소 / 보정

- #18 본문은 12종 기준이나 실제 구현은 #17 최종 16종 기준.
- #18 본문은 `/api/v1` 기준이나 실제 구현은 기존 API와 docs 기준 `/v1`.
- Dockerfile/Fly image에는 아직 포함되지 않을 수 있음. 실제 배포 자산 포함은 #37에서 최종 확인한다.
- `iconUrl`을 절대 URL로 만들지 상대 URL로 둘지 결정 필요. 계획안은 환경별 host 차이를 줄이기 위해 상대 URL `/assets/...`로 둔다.

## 검증 체크리스트

- [ ] 마이그레이션 2개 추가: schema + seed.
- [ ] category 16종 seed row 확인.
- [ ] `GET /v1/categories` 통합 테스트 통과.
- [ ] `GET /v1/categories?since=1` 증분 테스트 통과.
- [ ] `/assets/category-icons/omega3.png` 응답 200 + `image/png`.
- [ ] `Cache-Control` header 설정.
- [ ] `cargo fmt --check` 통과.
- [ ] `cargo clippy -- -D warnings` 통과.
- [ ] `cargo test` 통과.
- [ ] `docs/api.md` 갱신.
- [ ] `server/README.md` 갱신.
- [ ] stage report + final report 작성.

## 다음

본 계획 승인 후 Stage 1부터 구현한다. #18 완료 후 자연스러운 다음 작업은 #37 배포 인프라 또는 #19 모바일 mirror 동기화다.
