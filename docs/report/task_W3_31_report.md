# task_W3_31_report.md — 인구통계 기반 권장 영양제 정보 기능 최종보고서

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#31](https://github.com/kswift1/PillPouch/issues/31) |
| 마일스톤 | W3 |
| 크기 | L |
| 영역 | area:docs / area:server |
| 타입 | type:feat / type:docs |
| 브랜치 | `kswift1/recommendations` |
| 수행계획서 | [`task_W3_31.md`](../plans/task_W3_31.md) |
| ADR | [`0011-recommendations-feature.md`](../adr/0011-recommendations-feature.md) |
| 완료 | 2026-05-04 |

## 결과 요약

V1에 **인구통계 기반 권장 영양제 정보 기능** 추가. 본 PR은 동시에 **백엔드 첫 본격 PR** — Cargo workspace + Axum + sqlx + tracing + chrono 골격을 함께 박제.

### 핵심 결정

- **Framing**: 신규 사용자 시작 가이드 X / 사용자가 언제든 진입해서 보는 **개별 기능** O
- **분류 축**: 연령대+성별+임산부 5 카테고리 — male_20s_30s / female_20s_30s / pregnant_lactating / male_40s_60s / female_40s_60s
- **데이터 소스**: 식약처 KDRIs 2020 / 한국영양학회 / 식약처 건강기능식품 인정 기준 + AI WebSearch 큐레이션
- **API 비용**: 0 (작업지시자 ChatGPT 구독 또는 본 워크스페이스 AI WebSearch 일회성 추출)
- **데이터 흐름**: repo `server/seed/recommendations.json` commit → Fly.io 자동 배포 → DB UPSERT → iOS 화면 로드 시 항상 fetch
- **iOS UI**: 별도 Issue [#35](https://github.com/kswift1/PillPouch/issues/35) (별도 워크스페이스)
- **영양제별 4필드**: description / dosage / timing / side_effects (V1.x → V1으로 당김)

### 박제 산출물

| 영역 | 파일 | LOC |
|---|---|---|
| **ADR** | `docs/adr/0011-recommendations-feature.md` (신설) | +110 |
| **Identity** | `docs/identity.md` (v1.0 → v1.1) — §표면 §핵심 기능 5번째 + §변경 로그 v1.1 | +10 |
| **brief** | `docs/brief.md` (v0.7 → v0.8) — §V1 스코프 §Must + §변경 로그 v0.8 | +15 |
| **api docs** | `docs/api.md` — recommendations endpoint 명세 | +50, ~15 |
| **수행계획서** | `docs/plans/task_W3_31.md` (신설) | +200 |
| **단계보고서** | `docs/working/task_W3_31_stage{1~4}.md` (신설 ×4) | +400 |
| **결과보고서** | `docs/report/task_W3_31_report.md` (신설, 본 파일) | +150 |
| **Workspace** | `server/Cargo.toml` (deps 추가) | +20 |
| **DB** | `server/migrations/0001_recommendations.sql` (신설) | +21 |
| **Seed** | `server/seed/recommendations.json` (5 카테고리 × 영양제 5~7종 × 4필드) | +290 |
| **domain** | Recommendation / Supplement (4 optional 필드) / RecommendationError + 6 tests | +200 |
| **storage** | connect / migrate / seed_recommendations_from_path / list_all / get / upsert_many + 5 tests | +275 |
| **api** | router + handlers + ApiError + main 바이너리 | +130 |
| **합계** | | **+~1900 LOC** |

## 단계별 수행 내역

### Stage 1 — AI WebSearch 시범 추출 + 분류 축 결정 ✅
- 5 카테고리 (20~30대 남성/여성, 임산부, 40~60대 남성/여성) WebSearch 추출
- 식약처 KDRIs / 한국영양학회 / 보건복지부 / 필라이즈 / 하이닥 등 출처 확보
- 분류 축 정합 검증 (Anti-Promise §1·§2·§4 / Identity §정서 §금기)
- 65세+ 시니어 / 수유부 / 컨디션 축 처리 결정
- 작업자 변경: 작업지시자 ChatGPT → 본 워크스페이스 AI WebSearch (효율 + 비용 미세)

### Stage 2 — 백엔드 첫 본격 박제 ✅
- Cargo workspace 의존성 (tokio / axum / tower-http / sqlx / serde / tracing / chrono)
- 마이그레이션 시스템 + recommendations 테이블 (JSON column 단순)
- domain crate (Recommendation / Supplement / RecommendationError + 3 unit test)
- storage crate (connect / migrate / seed_from_path / CRUD + 5 통합 test)
- api crate (`pillpouch-api` 바이너리 + Axum router + handlers + ApiError + tracing)
- docs/api.md 갱신 (endpoint 명세 + 응답 스키마 + 에러 응답)
- 트레이드 박제: sqlx `query!()` → `query_as / query` 런타임 검증 (ADR-0001 §"compile-time checked"는 후속 PR sqlx prepare 셋업)

### Stage 3 — seed 검수 + 깊은 WebSearch + 영양제별 4필드 ✅
- 정정 5건: 코엔자임Q10 90~100mg / 이소플라본 40~50mg / DHA 200~300mg / 비타민D 400IU / 칼슘 800mg(50+)
- 출처 강화: 식약처 KDRIs 2020 / 한국영양학회 / 식약처 건강기능식품 / 질병관리청 / 의료기관 명시
- disclaimer 강화: 40+ 항응고제 / 임산부 산부인과 / 갱년기 호르몬 민감자 의사 상담 필수
- **Supplement 확장**: description / dosage / timing / side_effects 4 optional 필드 (V1.x → V1 당김)
- 도메인 테스트 추가 3건 (None 시 생략 / legacy JSON 호환 / full round-trip)
- seed 갱신: 29 영양제 × 4 필드 = **116 optional fields 모두 채움**
- Anti-Promise §2 정합 (side_effects): 일반 정보 톤 + 의사·약사 상담 권장 disclaimer

### Stage 4 — Identity / brief.md 박제 + ADR-0011 ✅
- ADR-0011 신설 (Status: Accepted 2026-05-04)
- Identity v1.0 → v1.1 (§표면 §핵심 기능 5번째 + §변경 로그 v1.1)
- brief.md v0.7 → v0.8 (§V1 스코프 §Must + 메타 헤더 + §변경 로그 v0.8)
- "거의 불변" 원칙 검증: 본질·차별점·정서·비전·약속 변경 X / §표면 §핵심 기능 추가만

### Stage 5 — 최종보고서 + PR 머지 ✅ (본 단계)

## 검증 결과

### 빌드
```
$ cargo fmt --check     ✅
$ cargo clippy --workspace --all-targets -- -D warnings   ✅
$ cargo test --workspace
domain:  6 passed
storage: 5 passed
api:     1 placeholder
pusher:  1 placeholder
```

### 런타임 smoke test
```
$ DATABASE_URL=sqlite::memory: cargo run --bin pillpouch-api
INFO: connecting db: sqlite::memory:
INFO: seeded 5 recommendations from server/seed/recommendations.json
INFO: listening on 127.0.0.1:18083

$ curl /healthz                                          → "ok"
$ curl /v1/recommendations                               → 5 카테고리 list (category 알파벳순)
$ curl /v1/recommendations/male_40s_60s                  → 코엔자임Q10 4필드 정상
$ curl /v1/recommendations/missing                       → 404
```

### JSON 시드 검증
```
$ python3 ... -c "..."
OK — 5 categories, 29 supplements, 116 optional fields filled (target: 116)
```

## 가설 검증 게이트

- [x] 가설 B 약화 X — 권장 정보는 본질(기록 신뢰성)과 별개 layer
- [x] Identity §본질 / §차별점 / §정서 변경 X — §표면 §핵심 기능 추가만
- [x] Anti-Promise §1·§2·§4 정합 — 인구통계 일반 권장만, 처방·진단·맞춤 추천 X, side_effects는 일반 정보 톤
- [x] Anti-Promise §5 정합 — 사용자 데이터 외부 송신 0 (read-only public endpoint, 사용자 정보 무관)
- [x] Non-goals 미해당 — 기존 Non-goals 유지, V1 스코프에 추가
- [x] "거의 불변" 원칙 보존 — Identity v1.0 → v1.1은 §표면 추가만

## 후속 검토 항목

본 PR 머지 후 별도 Issue + ADR로 분리될 영역. ADR-0011 §후속 결정 영역 cross-link.

### 1. iOS UI 통합 ([#35](https://github.com/kswift1/PillPouch/issues/35))
- 별도 워크스페이스 / 별도 PR
- `GET /v1/recommendations` endpoint는 본 PR에서 박제 완료
- 화면 로드 시 항상 fetch (캐시 X) 정책 박제됨
- 어디서 fetch (별도 탭 / 카탈로그 통합) 결정은 #35

### 2. 영양제별 source_url 필드 매핑
- 식약처/KDRIs PDF 직접 링크
- 영양제별 분산되어 추적 부담 큼
- V1.x 후속 PR

### 3. KDRIs 2025 갱신 반영
- 2026-05 시점 발간 확인됨
- PDF 직접 fetch 실패 (binary)
- KDRIs 2020 인용 → 2025로 마이그레이션은 후속 PR

### 4. 식약처 임산부 보도자료 원본 URL
- 학술 논문 다수 인용 확정
- 원본 보도자료 URL은 추후 검수

### 5. 카테고리 확장
- 65+ 시니어 (만성질환 자문 위험으로 V1 제외)
- 라이프스테이지 (직장인 / 학생 등)
- 컨디션 축 (수면 / 면역 — Anti-Promise §1·§2 회색)
- V1.x / V2+ 검토

### 6. 자동 갱신 cron (γ 옵션)
- 현재: 작업지시자 수동 trigger (repo commit)
- V1.x: 백엔드 cron 자동 갱신
- ADR 별도

### 7. ADR-0001 §"compile-time checked queries" 정합
- 본 PR: `query_as / query` 런타임 검증
- 후속 PR: sqlx prepare 셋업 + `.sqlx/` repo commit + `query!()` 마이그레이션

## 부수 결정 (본 PR 안 박제)

- 한국어 테스트 함수명 (CLAUDE.md / code-style §1) Rust 적용 — test 모듈 단위 `#[allow(non_snake_case)]`
- sqlx `query!()` → `query_as / query` 런타임 검증 (ADR-0001 정합 후속)
- pusher crate stub 그대로 (PTS 기능은 별도 PR — #30 close 결정)

## 승인 요청

본 보고서 검토 후 PR 승인 ⛔. 승인 후 라벨/마일스톤 부착 + Squash merge.
