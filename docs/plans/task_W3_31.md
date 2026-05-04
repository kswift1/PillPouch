# task_W3_31.md — 인구통계 기반 권장 영양제 정보 기능 수행계획서

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#31](https://github.com/kswift1/PillPouch/issues/31) |
| 마일스톤 | W3 |
| 크기 | L |
| 영역 | area:docs (Stage 1·4) / area:server (Stage 2·3) |
| 타입 | type:feat / type:docs |
| 브랜치 | `kswift1/recommendations` (origin/main에서 분기) |
| 예상 시간 | 2~3일 (실제 ~1주 안전 마진) |
| 본 워크스페이스 스코프 | **iOS 제외한 기능 구현까지** (백엔드 + 문서 + 작업지시자 ChatGPT 추출) |
| iOS UI 통합 | **별도 Issue [#35](https://github.com/kswift1/PillPouch/issues/35)** 에서 별도 워크스페이스로 처리 |

## 목표

V1에 **인구통계 기반 권장 영양제 정보 기능** 추가:

- 사용자가 카탈로그/별도 화면에서 카테고리별(연령·성별 등) 권장 영양제 정보 열람
- 데이터는 작업지시자가 ChatGPT 웹서치로 큐레이션 후 백엔드 DB seed
- iOS 앱은 화면 로드 시 백엔드 API fetch (캐시 X — 항상 최신)
- App Store 재배포 없이 데이터 갱신 가능

## 핵심 결정 (Issue #31 진행 중 합의)

| 항목 | 결정 |
|---|---|
| **Framing** | 신규 시작 가이드 X / **개별 기능** O — 사용자가 언제든 진입해서 보는 정보 영역 |
| **분류 축** | Stage 1 ChatGPT 시범 추출 후 자연 분류로 결정 (대중적 구분) |
| **데이터 소스** | 식약처 KDRIs + 자체 큐레이션 + 작업지시자 ChatGPT 웹서치 |
| **API 비용** | 0 (작업지시자 ChatGPT 구독으로 추출, 자동 cron X) |
| **데이터 입력** | repo JSON seed (`server/seed/recommendations.json`) → commit → Fly.io 자동 배포 |
| **백엔드 데이터 모델** | `recommendations` 테이블 + JSON column 단순 |
| **iOS fetch 시점** | 화면 로드 시 **항상 fetch** (캐시 X — 권장 정보 즉시 최신 반영) |
| **V1 스코프** | 포함 (W3 백엔드 +0.5일 + W4 iOS +1일) |
| **사이즈** | L 승격 (5 단계 절차) |

## 비목표

- ❌ **iOS UI 통합** — 별도 Issue [#35](https://github.com/kswift1/PillPouch/issues/35)에서 별도 워크스페이스 처리. 본 PR은 백엔드 endpoint까지만.
- ❌ **자동 cron 갱신** — 작업지시자 수동 trigger만. 자동 추출 X.
- ❌ **개인 맞춤 추천 (α-1)** — Identity §Anti-Promise §4. 인구통계 일반 권장만.
- ❌ **컨디션 기반 분류** (수면/면역/관절) — Anti-Promise §1·§2 회색지대.
- ❌ **백엔드 admin auth / 웹 UI** — repo commit이 admin 흐름 대체.
- ❌ **사용자 자유 텍스트 질문** — V2+ 영역.
- ❌ **iOS 앱 안 LLM 호출** — 사용자 데이터 외부 송신 0 원칙.

## 단계 분할 (Stage 1~5)

### Stage 1 — AI WebSearch 시범 추출 + 분류 축 결정 (~0.5일)

본 워크스페이스 AI가 WebSearch 도구로 직접 5 카테고리 시범 추출 (작업지시자 ChatGPT 손대기 작업 X).

**시범 5 카테고리** (작업지시자 결정):
1. 20~30대 남성
2. 20~30대 여성
3. 임산부
4. 40~60대 남성
5. 40~60대 여성

산출물:
- `docs/working/task_W3_31_stage1.md` — 시범 결과 마크다운
  - 카테고리별 권장 영양제 5~7종 + 출처
  - Anti-Promise §1·§2·§4 정합 검증
  - Identity §정서 §금기 정합 검증
  - 65세+ 시니어 추가 여부 결정
  - 분류 축 확정 ("연령대+성별 + 임산부" 가설 검증)
- 작업지시자 검수 → 분류 축 확정

승인 게이트 ⛔ — Stage 2 진입 전.

### Stage 2 — 백엔드 데이터 모델 + endpoint + seed 스크립트 (~0.5일)

분류 축 확정 후 백엔드 작업.

산출물:
- `server/migrations/{N}_recommendations.sql` — 테이블 마이그레이션
  ```sql
  CREATE TABLE recommendations (
      category TEXT PRIMARY KEY,
      display_name TEXT NOT NULL,
      supplements_json TEXT NOT NULL,
      source TEXT NOT NULL,
      disclaimer TEXT NOT NULL,
      updated_at INTEGER NOT NULL
  );
  ```
- `server/crates/api/src/recommendations.rs` — `GET /v1/recommendations` (전체) + `GET /v1/recommendations/{category}` (단일)
- `server/crates/storage/src/recommendations.rs` — sqlx query + 도메인 함수
- `server/crates/domain/src/recommendation.rs` — 도메인 타입 (Recommendation, Supplement)
- seed 스크립트 — `server/seed/recommendations.json`을 빌드 타임에 DB import (Fly.io 배포 시 실행)
- 단계보고서 `docs/working/task_W3_31_stage2.md`

승인 게이트 ⛔.

### Stage 3 — 본 추출 + JSON seed commit (~0.5~1일)

Stage 1 분류 축 + Stage 2 데이터 모델 확정 후 작업지시자 ChatGPT 본 추출.

작업지시자 워크플로우:
1. ChatGPT 웹서치로 전체 카테고리(분류 축 결정에 따라 ~10~16개) 추출
2. 결과를 `server/seed/recommendations.json` 형식으로 정리
3. 식약처 KDRIs 교차 검증 (일부 spot check)
4. repo commit + push
5. Fly.io 자동 배포 → DB 채워짐

산출물:
- `server/seed/recommendations.json` — 전체 카테고리 데이터
- 단계보고서 `docs/working/task_W3_31_stage3.md` — 추출 시점 / 출처 / 검증 노트

승인 게이트 ⛔.

### Stage 4 — Identity §표면 §핵심 기능 박제 위치 추가 + brief.md cross-link (~0.5일)

> **Stage 4 (이전 5)** — 본 워크스페이스 스코프 변경 (2026-05-04): iOS UI 통합은 별도 Issue [#35](https://github.com/kswift1/PillPouch/issues/35)에서 별도 워크스페이스로 처리. 본 PR은 백엔드 + 문서까지만.

산출물:
- `docs/identity.md` §표면 §핵심 기능에 5번째 항목 추가:
  > 인구통계 기반 권장 영양제 정보 (연령대·성별 등 일반 가이드, Anti-Promise §4 정합)
- `docs/identity.md` §변경 로그 v1.1 신설
- `docs/brief.md` §V1 스코프 §Must 또는 §Nice에 추가
- `docs/brief.md` §변경 로그 v0.8 신설
- `docs/adr/0011-recommendations-feature.md` 신설 (필요 시)
- 단계보고서 `docs/working/task_W3_31_stage4.md`

승인 게이트 ⛔ (Identity 변경 = 본질 layer 영향, ADR 선행 필요).

→ ⚠️ **주의**: Identity v1.0 박제 직후 v1.1 진화 = "거의 불변" 원칙 미세 위반. 다만 §본질 / §차별점 변경 X / §표면 §핵심 기능 추가만이라 허용 범위. ADR-0011로 박제.

### Stage 5 — 최종보고서 + PR 메타 + 머지

- `docs/report/task_W3_31_report.md`
- PR 본문 + 라벨 / 마일스톤 / Closes #31
- Squash merge

### iOS UI 통합 (별도 Issue #35)

- 본 PR 머지 후 별도 워크스페이스에서 [#35](https://github.com/kswift1/PillPouch/issues/35) (iOS 앱 틀 구축) 안 처리
- `GET /v1/recommendations` endpoint는 본 PR Stage 2에서 박제 완료
- iOS 화면 로드 시 항상 fetch (캐시 X)
- 어디서 fetch (별도 탭 / 카탈로그 통합) 결정은 #35 §탭/화면 정보 표시 논의에서

## 변경 파일 목록 (예상)

| 영역 | 파일 | 변경 |
|---|---|---|
| docs | `task_W3_31.md` (본 파일) | 신설 |
| docs | `task_W3_31_impl.md` | 신설 (Stage 2 시점) |
| docs (Stage 1~4) | `task_W3_31_stage{1~4}.md` | 신설 ×4 |
| docs (final) | `task_W3_31_report.md` | 신설 |
| docs (Stage 4) | `identity.md` | §표면 §핵심 기능 추가 + 변경 로그 v1.1 |
| docs (Stage 4) | `brief.md` | §V1 스코프 + 변경 로그 v0.8 |
| docs (Stage 4, 선택) | `adr/0011-recommendations-feature.md` | 신설 |
| server | `migrations/{N}_recommendations.sql` | 신설 |
| server | `crates/{api,storage,domain}/...` | recommendations 모듈 추가 |
| server | `seed/recommendations.json` | 신설 |
| ~~ios~~ | (별도 Issue #35로 이전) | — |

## 검증

| Stage | 검증 |
|---|---|
| Stage 1 | ChatGPT 시범 결과 합리성 + 분류 축 Anti-Promise 정합 |
| Stage 2 | `cargo test` + `cargo clippy -- -D warnings` + sqlx compile-time check |
| Stage 3 | `server/seed/recommendations.json` 형식 valid + 작업지시자 검수 |
| Stage 4 | Identity / brief.md cross-link 정합 |

## 가설 검증 게이트

- [ ] 가설 B 약화 X — 권장 정보는 본질(기록 신뢰성)과 별개 layer
- [ ] Identity §본질 / §차별점 / §정서 변경 X — §표면 §핵심 기능 추가만
- [ ] Anti-Promise §1·§2·§4 정합 — 개인 진단 X / 인구통계 일반 정보 OK
- [ ] Anti-Promise §5 정합 — 사용자 데이터 외부 송신 0
- [ ] Non-goals 미해당 (V1 스코프에 추가, 기존 Non-goals 유지)

## 위험 / 롤백

- **위험 1** — Identity v1.0 박제 직후 v1.1 = "거의 불변" 원칙 미세 위반. 완화: ADR-0011로 명시 박제, 본질 변경 X 명시.
- **위험 2** — ChatGPT 응답 hallucination. 완화: 작업지시자 검수 + 식약처 KDRIs 교차 검증.
- **위험 3** — 백엔드 endpoint Fly.io 배포 실패. 완화: Stage 2에서 카탈로그 endpoint(#18) 패턴 따라 진행.
- **위험 4** — iOS UI 형태(탭 vs 카탈로그 통합) 결정 미정 → 별도 Issue [#35](https://github.com/kswift1/PillPouch/issues/35)에서 별도 워크스페이스로 처리. 본 PR 영향 X.
- **롤백** — Stage 단위 revert 가능. PR 분할도 검토 가능.

## 후속 후보

- 정기 갱신 자동화 (V1.x — γ 옵션 백엔드 cron)
- 사용자 자유 텍스트 질문 (V2+)
- 컨디션 기반 분류 (V2+, 의료 자문 외부 검토 후)

## 승인 요청

본 수행계획서 검토 후 승인 ⛔ — 승인 후 Stage 1 진입 (작업지시자 ChatGPT 시범 추출).
