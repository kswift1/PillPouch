# task_W3_31_stage2.md — Stage 2 백엔드 데이터 모델 + endpoint + seed

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#31](https://github.com/kswift1/PillPouch/issues/31) |
| Stage | 2 / 5 |
| 완료 | 2026-05-04 |
| 영역 | server (Cargo workspace 첫 본격 박제 + recommendations) |

## 결과 요약

본 PR이 **백엔드 첫 본격 PR**. ADR-0001 (Rust + Axum + sqlx + tower-http + tracing + chrono) 결정 그대로 박제.

### 박제 범위

#### 1. Cargo workspace 의존성 박제 (`server/Cargo.toml`)
- tokio, axum, tower, tower-http
- sqlx (sqlite + chrono + macros + migrate, rustls TLS)
- serde / serde_json / anyhow / thiserror
- tracing / tracing-subscriber
- chrono (clock + serde, default-features 없음)

#### 2. 마이그레이션 시스템 (`server/migrations/`)
- `0001_recommendations.sql` — `recommendations` 테이블 (JSON column 단순)
- `sqlx::migrate!("../../migrations")` 매크로로 빌드 타임 SQL 검증

#### 3. domain crate (`server/crates/domain/src/recommendation.rs`)
- `Recommendation` / `Supplement` / `RecommendationError` 타입 (serde + thiserror)
- `supplements_by_priority()` view — priority 오름차순, stable sort
- 도메인 unit test 3건

#### 4. storage crate (`server/crates/storage/`)
- `connect()` + `migrate()` + `MIGRATOR` 정적
- `seed_recommendations_from_path()` — repo seed JSON → DB UPSERT
- `recommendations::list_all` / `get` / `upsert_many` (트랜잭션)
- 인메모리 SQLite 통합 test 5건

#### 5. api crate (`server/crates/api/`)
- `pillpouch-api` 바이너리 (Axum + tracing 셋업)
- `router(pool)` — `/healthz` + `/v1/recommendations` + `/v1/recommendations/:category`
- `ApiError` → HTTP 응답 매핑 (NotFound 404 / 그 외 500)
- 환경변수: `DATABASE_URL` / `SEED_RECOMMENDATIONS_PATH` / `BIND_ADDR`

#### 6. seed 시드 (`server/seed/recommendations.json`)
- Stage 1 추출 결과 5 카테고리 박제
- 빌드/배포 시 부팅 단계에서 `seed_recommendations_from_path` 호출
- Stage 3에서 작업지시자 검수/정정

#### 7. docs/api.md 갱신
- 박제 완료 endpoint + 응답 스키마 + 인증 정책 + 에러 응답 박제
- PTS 관련 endpoint는 "예정"으로 분리

## 검증

### `cargo check --workspace`
```
Finished `dev` profile [unoptimized + debuginfo] target(s) in 1.12s
```

### `cargo fmt --check`
```
(통과 — 변경 후)
```

### `cargo clippy --workspace --all-targets -- -D warnings`
```
Finished `dev` profile [unoptimized + debuginfo] target(s) in 1.19s
```

### `cargo test --workspace`
```
- domain: 3 tests passed (Recommendation 직렬화, supplements_by_priority, Supplement serde)
- storage: 5 tests passed (인메모리 마이그레이션, upsert+list, 재upsert 갱신, NotFound, 빈 입력 noop)
- api: 1 placeholder
- pusher: 1 placeholder
```

### Smoke test (실 바이너리 + curl)

```
$ DATABASE_URL=sqlite::memory: cargo run --bin pillpouch-api
INFO: connecting db: sqlite::memory:
INFO: seeded 5 recommendations from server/seed/recommendations.json
INFO: listening on 127.0.0.1:18080

$ curl /healthz
ok

$ curl /v1/recommendations | head -c 100
{"recommendations":[{"category":"female_20s_30s","display_name":"20~30대 여성","supplements":[...]

$ curl /v1/recommendations/pregnant_lactating
{"category":"pregnant_lactating","display_name":"임산부 / 수유부","supplements":[{"name":"엽산 (600μg/일)",...

$ curl -o /dev/null -w "%{http_code}" /v1/recommendations/missing
404
```

→ seed import + 정렬 + 단일 fetch + 404 모두 정상.

## 트레이드오프 박제

### sqlx `query!()` 매크로 → `query_as()` / `query()` 변경

ADR-0001은 *"sqlx (compile-time checked queries)"* 박제. 그러나 `query!()` 매크로는 빌드 타임 DATABASE_URL 또는 `.sqlx` 메타데이터 필요 → 본 PR (백엔드 첫 PR)에서 sqlx prepare 셋업 부담.

→ 본 PR은 `query_as()` + `query()` (런타임 SQL 검증)으로 시작. 모듈 doc-comment에 명시 박제. ADR-0001 §"compile-time checked queries" 정합 마이그레이션은 후속 PR에서 sqlx prepare 셋업 + `.sqlx/` repo commit으로 처리.

### 마이그레이션 디렉토리 위치

`server/migrations/` 단일 디렉토리 — 모든 crate 공유. `sqlx::migrate!("../../migrations")` 매크로가 storage crate에서 빌드 타임 SQL 파일 검증. 개별 crate 마이그레이션 분리 X.

### Workspace lints — `non_snake_case` 테스트 함수명

CLAUDE.md / `docs/conventions/code-style.md` §1 *"테스트 메서드명 한글 + 언더바"* 룰 적용. Rust clippy::non_snake_case와 충돌. test 모듈 단위로 `#[cfg(test)] #[allow(non_snake_case)]` 추가 — 본문 코드는 영향 X.

## 변경 파일 목록

| 파일 | 종류 | LOC |
|---|---|---|
| `server/Cargo.toml` | 수정 (workspace.dependencies 추가) | +20 |
| `server/migrations/0001_recommendations.sql` | 신설 | +21 |
| `server/seed/recommendations.json` | 신설 (Stage 1 결과) | +73 |
| `server/crates/domain/Cargo.toml` | 수정 (deps) | +5 |
| `server/crates/domain/src/lib.rs` | 재작성 (placeholder 제거) | ~10 |
| `server/crates/domain/src/recommendation.rs` | 신설 | +110 |
| `server/crates/storage/Cargo.toml` | 수정 (deps) | +9 |
| `server/crates/storage/src/lib.rs` | 재작성 | +75 |
| `server/crates/storage/src/recommendations.rs` | 신설 | +200 |
| `server/crates/api/Cargo.toml` | 수정 (deps + bin) | +20 |
| `server/crates/api/src/lib.rs` | 재작성 (router) | +20 |
| `server/crates/api/src/recommendations.rs` | 신설 (handler) | +60 |
| `server/crates/api/src/main.rs` | 신설 (binary) | +45 |
| `docs/api.md` | 갱신 (endpoint 박제) | +50, ~15 |
| `docs/working/task_W3_31_stage2.md` | 신설 (본 파일) | — |
| **합계** | | **+~720 LOC** |

## 다음 단계 (Stage 3)

- 작업지시자 본 추출 + `server/seed/recommendations.json` 검수
- 식약처 KDRIs 교차 검증 (필요 시 1~2 카테고리 spot check)
- Stage 1 추출 결과 정정 / 보강
- repo commit (이미 본 PR에 포함되어 있어 사실상 검수만)

→ Stage 3는 본 PR 안에서 작업지시자 직접 검수 + 정정 가능. 별도 PR 분리 X.

## 가설 검증 게이트

- [x] 가설 B 약화 X — 권장 정보는 본질(기록 신뢰성)과 별개 layer
- [x] Anti-Promise §1·§2·§4 정합 — disclaimer 매 카테고리 박제, 인구통계 일반 권장만
- [x] Anti-Promise §5 정합 — 사용자 데이터 외부 송신 0 (read-only public endpoint)
- [x] Identity §본질 / §차별점 / §정서 변경 X
- [x] Non-goals 미해당

## Stage 2 승인 게이트 ⛔

작업지시자 검수 항목:
1. Cargo workspace 의존성 박제 OK?
2. 마이그레이션 + recommendations 테이블 스키마 OK?
3. endpoint 명세 (api.md) OK?
4. seed JSON 5 카테고리 데이터 (Stage 3에서 깊은 검수 가능)
5. sqlx `query!()` → `query_as()` 트레이드 (후속 PR에서 prepare 셋업) OK?

승인 후 Stage 3 (작업지시자 본 추출 검수) → Stage 4 (Identity / brief.md 박제) → Stage 5 (PR 머지) 진행.
