# task_W3_31_stage4.md — Stage 4 Identity / brief.md 박제 + ADR-0011

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#31](https://github.com/kswift1/PillPouch/issues/31) |
| Stage | 4 / 5 |
| 완료 | 2026-05-04 |
| 영역 | docs (Identity / brief.md / ADR-0011) |

## 결과 요약

본 PR (#31) 안에서 Stage 1~3로 박제된 백엔드 + seed + 도메인 타입을 **정체성 SoT 2층에 cross-link 박제**.

### 박제 항목

#### 1. ADR-0011 신설 (`docs/adr/0011-recommendations-feature.md`)
- Status: Accepted — 2026-05-04
- Context: PR #28 Anti-Promise §4 정밀화 → α-2 합법 확인 → V1 추가 결정
- Decision: §표면 §핵심 기능 5번째 항목 추가 (Identity v1.1) + brief.md V1 스코프 §Must 추가 (v0.8) + 백엔드 endpoint + 작업지시자 큐레이션 + AI WebSearch 추출 + iOS UI는 #35
- Consequences: Positive / Negative / Neutral 3분류 + 후속 결정 영역 5건

#### 2. Identity v1.0 → v1.1 (`docs/identity.md`)
- Status v1.0 → v1.1
- §표면 §핵심 기능에 5번째 항목 추가:
  > 인구통계 기반 권장 영양제 정보 (연령대·성별별 일반 가이드, Anti-Promise §4 정합 — ADR-0011)
- §변경 로그 v1.1 신설:
  - §본질 / 차별점 / 정서 변경 X 명시 (*"거의 불변" 원칙 보존*)
  - 분류 축 / 데이터 흐름 / Anti-Promise §4 정합 박제

#### 3. brief.md v0.7 → v0.8 (`docs/brief.md`)
- 메타 헤더 갱신 + Major changes 추가
- §V1 스코프 §Must에 항목 추가:
  > 인구통계 기반 권장 영양제 정보 — 5 카테고리 × 영양제 5~7종 × 4필드. 백엔드 endpoint + iOS 화면 fetch (UI는 #35).
- §변경 로그 v0.8 신설

### "거의 불변" 원칙 영향 평가

Identity §변경 정책 박제: *"본질(Why) 변경 = 사실상 새 프로젝트"*. v1.0 박제 직후 v1.1 진화는 미세 위반 우려. 검증:

| 변경 항목 | 영향 layer | 평가 |
|---|---|---|
| §표면 §핵심 기능 5번째 추가 | 표면(What) | ✅ 허용 — 표면 layer는 V1 진화 |
| §본질 (Why) | 본질 | ✅ 변경 X |
| §차별점 3가지 | 본질-차별 | ✅ 변경 X |
| §정서 (Tone & Feel) | 정체성 | ✅ 변경 X |
| §비전 (Vision V2+) | 비전 | ✅ 변경 X |
| §약속 / Anti-Promise | 정체성 | ✅ 변경 X (PR #28에서 §4 정밀화는 이미 v1.0 박제) |

→ 본질 / 차별점 / 정서 / 비전 / 약속 모두 변경 X. **§표면 §핵심 기능 추가만** = "거의 불변" 원칙 보존 범위. ADR-0011 §Negative에 명시 박제.

### Anti-Promise §4 정합 (재검증)

PR #28에서 Anti-Promise §4를 다음으로 정밀화:
> *"개인 맞춤 처방·자문을 하지 않는다 — 인구통계 일반 권장(연령대·성별별 표준 영양제 가이드)은 정보 제공이지 의료 자문이 아니다"*

본 PR seed 데이터:
- ✅ 연령대+성별+임산부 5 카테고리 = 인구통계 기반
- ✅ 식약처 KDRIs / 한국영양학회 / 식약처 건강기능식품 인정 기준 출처
- ✅ 개인 진단 / 처방 / 자문 X
- ✅ 각 카테고리 disclaimer에 *"인구통계 기반 일반 정보. 개인 진단·처방 X."* 명시
- ✅ 의사·약사 상담 권장 disclaimer (40+ / 임산부 / 항응고제 복용자 / 호르몬 민감자)

→ Anti-Promise §4 정의에 정확히 정합.

## 변경 파일

| 파일 | 변경 |
|---|---|
| `docs/adr/0011-recommendations-feature.md` | 신설 (~110 LOC) |
| `docs/identity.md` | Status v1.0 → v1.1 / §핵심 기능 1줄 추가 / §변경 로그 v1.1 신설 (~10 LOC) |
| `docs/brief.md` | 메타 헤더 v0.7 → v0.8 / §V1 스코프 §Must 1+2 줄 추가 / §변경 로그 v0.8 신설 (~15 LOC) |
| `docs/working/task_W3_31_stage4.md` | 신설 (본 파일) |

## 검증

- ADR-0011 cross-link이 실제 파일과 매핑 ✅
- Identity §변경 로그 v1.1 본문이 §표면 §핵심 기능 추가와 일치 ✅
- brief.md §V1 스코프 §Must 항목이 ADR-0011 §Decision §V1 스코프와 일치 ✅
- brief.md §변경 로그 v0.8 본문이 메타 헤더 Major changes와 일치 ✅
- 코드/seed 변경 X — Stage 1~3에서 이미 박제

## 가설 검증 게이트

- [x] 가설 B 약화 X — 권장 정보는 본질(기록 신뢰성)과 별개 layer
- [x] Identity §본질 / §차별점 / §정서 변경 X
- [x] §표면 §핵심 기능 추가만 — "거의 불변" 원칙 보존
- [x] Anti-Promise §1·§2·§4·§5 정합
- [x] Non-goals 미해당 — V1 스코프에 추가, 기존 Non-goals 유지

## Stage 4 승인 게이트 ⛔

작업지시자 검수 항목:
1. ADR-0011 본문 (Context / Decision / Consequences) OK?
2. Identity v1.0 → v1.1 진화 — "거의 불변" 원칙 미세 위반 허용 OK? (§표면 §핵심 기능 추가만)
3. brief.md §V1 스코프 §Must 항목 표현 OK? (Must vs Nice)
4. 메타 헤더 / 변경 로그 박제 OK?

승인 후 **Stage 5 (최종보고서 + PR 메타 + 머지)** 진입.
