# ADR-0011: 인구통계 기반 권장 영양제 정보 기능 (V1 추가)

## Status
Accepted — 2026-05-04

## Context

PR #28 (SoT 2층 분리) 진행 중 작업지시자가 *"기본적인 오메가, 비타민, 마그네슘 같은건 권장 할 수 있는거 아니야? 여자면 철분 추가"* 발언으로 의료법 경계 재분류:

- **(α-1) 개인 진단 기반 추천** — 의료법 §27 회색지대, 안 함
- **(α-2) 인구통계 기반 일반 권장** — 식약처 영양소섭취기준 / 약국 카운터 안내문 수준, 합법

PR #28에서 Identity §Anti-Promise §4를 *"개인 맞충 처방·자문 X / 인구통계 일반 권장은 정보 제공"* 으로 정밀화 — (α-2) 합법성 박제. 박제 위치는 본 ADR로 처리.

본 PR (#31) 진행 중 추가 결정 (작업지시자 합의):
- Framing: 신규 사용자 시작 가이드 X / 사용자가 언제든 진입해서 보는 **개별 기능** O
- 분류 축: Stage 1 AI WebSearch 시범 추출 후 **연령대+성별 + 임산부/수유부 5 카테고리** 확정
  - 20~30대 남성 / 20~30대 여성 / 임산부·수유부 / 40~60대 남성 / 40~60대 여성
- 데이터 입력: 작업지시자 큐레이션 + AI WebSearch 추출 → repo `server/seed/recommendations.json` commit → Fly.io 자동 배포
- iOS fetch: 화면 로드 시 항상 fetch (캐시 X)
- 영양제별 상세 4필드 (description / dosage / timing / side_effects) 박제 (V1.x 미루지 않고 V1에 통합)

## Decision

V1에 **인구통계 기반 권장 영양제 정보 기능**을 추가한다.

### 정체성 영향

- **Identity §표면 §핵심 기능 5번째 항목 추가** — *"인구통계 기반 권장 영양제 정보 (연령대·성별별 일반 가이드, Anti-Promise §4 정합)"*
- **본질(Why) / 차별점 / 정서 변경 X** — 표면 layer 추가만
- Identity v1.0 → v1.1 (§표면 §핵심 기능 추가, §변경 로그 v1.1 신설)

### V1 스코프

- brief.md §V1 스코프 §Must에 추가 (Must, Nice 아님 — 표면 핵심 기능 위치)
- brief.md v0.7 → v0.8 (§V1 스코프 + §변경 로그 v0.8 신설)

### 백엔드

- `recommendations` 테이블 (JSON column 단순) + 마이그레이션
- `GET /v1/recommendations` (전체) + `GET /v1/recommendations/:category` (단일)
- `server/seed/recommendations.json` 빌드 타임 import
- 갱신 워크플로우: repo commit → Fly.io 자동 배포 (App Store 재배포 X)

### iOS

- 별도 Issue [#35](https://github.com/kswift1/PillPouch/issues/35) (iOS 앱 틀 구축)에서 별도 워크스페이스로 처리
- 화면 로드 시 항상 fetch + JSON 파싱 + 화면 표시

### Anti-Promise 정합

- §1 처방 X / §2 진단·자문 X / §4 개인 맞춤 추천 X — 모두 정합
- 인구통계 평균 권장 / 식약처 KDRIs / 한국영양학회 출처
- side_effects 필드는 일반 정보 톤 + disclaimer 강화 (개인 체질 차이 / 의사·약사 상담 권장)

## Consequences

### Positive
- V1 사용자 가치 ↑ — 신규/기존 사용자 모두 카테고리별 권장 영양제 + 4필드 상세 정보 열람
- 본질(기록 신뢰성) 무관 — A 보조 도구 영역
- App Store 재배포 X — 백엔드 데이터만 갱신으로 즉시 반영
- API 비용 0 — 작업지시자 큐레이션 + AI WebSearch 일회성 추출
- 본 PR이 백엔드 첫 본격 PR — Cargo workspace + Axum + sqlx + tracing 골격 함께 박제

### Negative
- Identity v1.0 박제 직후 v1.1 진화 — "거의 불변" 원칙 미세 위반. 다만 §본질 / §차별점 / §정서 변경 X / §표면 추가만이라 허용 범위.
- side_effects 필드는 Anti-Promise §2 회색지대 인접 — disclaimer 강화로 완화
- ADR-0001 §"compile-time checked queries" 정합 미완 — 본 PR은 `query_as / query` 런타임 검증 사용. 후속 PR에서 sqlx prepare 셋업 후 마이그레이트
- 데이터 갱신은 작업지시자 trigger (자동 cron X) — 식약처 KDRIs 갱신 / 식약처 재평가 결과 / 새 영양제 트렌드 반영은 수동

### Neutral
- 분류 축 (연령대+성별+임산부 5 카테고리)는 V1 시작점. V1.x에 65+ 시니어 / 라이프스테이지 (직장인·학생) / 컨디션 추가 검토 가능
- iOS UI 형태 (별도 탭 / 카탈로그 통합)는 #35에서 결정 — 본 ADR 무관

## 후속 결정 영역

- **영양제별 `source_url` 필드 매핑** — 식약처/KDRIs PDF 직접 링크 (V1.x)
- **KDRIs 2025 갱신 반영** — 2026-05 시점 발간 확인됨, PDF fetch 실패로 V1 미반영 (후속 PR)
- **식약처 임산부 보도자료 원본 URL 확인** — 학술 논문 다수 인용 확정, 원본 URL 추후
- **카테고리 확장** — 65+ 시니어 / 라이프스테이지 / 임상 영역 (V1.x / V2+)
- **자동 갱신 cron** — 작업지시자 수동 trigger → 백엔드 cron (V1.x — γ 옵션, ADR 별도)

## 참조

- PR [#28](https://github.com/kswift1/PillPouch/pull/28) — Anti-Promise §4 정밀화 박제
- PR [#31 / 본 PR] — 본 ADR 박제 + 백엔드 endpoint + seed 5 카테고리 박제
- Issue [#35](https://github.com/kswift1/PillPouch/issues/35) — iOS UI 통합 (별도 워크스페이스)
- 수행계획서 `docs/plans/task_W3_31.md`
- Stage 1 단계보고서 `docs/working/task_W3_31_stage1.md`
- Stage 2 단계보고서 `docs/working/task_W3_31_stage2.md`
- Stage 3 단계보고서 `docs/working/task_W3_31_stage3.md`
