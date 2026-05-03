# ADR-0010: SoT 2층 분리 — identity.md (정체성) + brief.md (V1 기획)

## Status
Accepted — 2026-05-03

## Context

`docs/brief.md` 단일 SoT (v0.5, 542줄) 안에 수명이 다른 3가지 정보가 혼재:

- 변하지 않는 것 (가설 B, 메타포, 정서, 차별점) — 앱 전 생애 유지
- 진화하는 것 (V1 스코프, 인터랙션 명세, 일정) — V1 한정
- 매우 자주 변하는 것 (변경 로그, 결정 대기 항목) — PR마다 갱신

이 혼재로 다음 갭 발생:

1. 외부 인터뷰 / 마케팅 시 *"이 앱 뭐야?"* 답할 추상 layer 닻 부족
2. 시안 평가 시 *"본질을 강화하는가?"* 평가 시 돌아갈 layer 부족
3. brief.md 변경 PR마다 *"정체성 영향인가, 단순 스코프 변경인가?"* 판단 어려움
4. 카테고리 위치선언 (영양제 트래킹·알람 카테고리 안에서 본질을 신뢰성으로 다르게 정의) 박제 부재

작업지시자가 정체성 문서 v1.0 초안을 별도 제시 (Why/What/Vision 3층 구조, `.context/attachments/pasted_text_2026-05-03_20-12-43.txt`). 첨부 원문 자체적으로 *"One-pager v0.4와 분리하여 별도 문서로 운영 시작"* 명시.

## Decision

SoT를 2층으로 분리:

- **`docs/identity.md`** (신설, v1.0) — 정체성. Why/What/Vision 3층. 앱 전 생애 유지, 거의 불변.
- **`docs/brief.md`** (기존 → v0.6) — V1 기획. 스코프/구현/일정. V1 한정, 진화.

### 변경 룰 (CLAUDE.md §SoT 변경 룰 (2층)에 박제)

#### identity.md
1. 직접 수정 절대 X
2. 본질(Why) 변경 = 사실상 새 프로젝트 — 작업지시자 직접 결정만, ADR 선행
3. 차별점 / 비전 / 약속 변경 = ADR + 작업지시자 승인
4. 변경 시 brief.md 양방향 점검 (정체성 변경 → 표면 기능 영향)

#### brief.md
1. 직접 수정 X, ADR 선행
2. ADR 승인 후 brief.md PR (변경 로그 섹션 갱신)
3. 가설 B를 약화하는 변경은 거부 (시각/기능 양쪽)

### 정합 보강 (본 ADR 묶음 처리)

본 PR에서 SoT 분리와 함께 처리되는 정합 작업:

- **brief.md §핵심 가설 어휘 정련** — *"명확한 시각적 증거(찢긴 약봉지)"* → *"명확한 시각적 증거"*. 가설을 단품 봉지에서 시각 증거 일반으로 layer-agnostic 정련 (주간/월간 뷰 등 다층 누적 포괄).
- **brief.md §한 줄 컨셉 직후 정체성 SoT cross-link 추가** — Identity layer 닻 명시.
- **brief.md 메타 헤더 v0.4 → v0.6 갱신** + Major changes 항목 박제.
- **docs/README.md 핵심 문서 목록 갱신** — 최상단에 identity.md 추가, 순서: identity → brief → architecture → data-model → api → design-system.
- **CLAUDE.md** §"기획서 변경 룰" → §"SoT 변경 룰 (2층)" 확장 + 절대 금지 1줄 갱신.

## Consequences

### Positive
- 외부 질문에 layer별 답변 가능 (Why/What/Vision 3층 표)
- PR 변경이 어느 layer를 건드리는지 즉시 분류
- 본질 변경 = 새 프로젝트 = 작업지시자 직결, 불필요한 ADR 생산 방지
- 카테고리 위치선언 ("카테고리 떠나기 X") 명시적 닻으로 박힘
- V2+ 비전 (조합 안전성 + 처방약·영양제 통합 2개) 명시적 닻

### Negative
- SoT 문서 2개로 늘어 색인 부담 증가 → README.md / CLAUDE.md 갱신으로 상쇄
- 두 문서 cross-link 정합을 매 PR 점검해야 함 → CLAUDE.md SoT 변경 룰에 박제

### Neutral
- ADR-0006(RHWP) 절차 영향 X. M 태스크 절차 그대로 적용.
- 본 PR 진행 중 발견된 후속 결정 영역은 별도 Issue + ADR로 분리. 본문은 보고서 §후속 검토 항목 참조 ([`docs/report/task_W1_27_report.md`](../report/task_W1_27_report.md)):
  1. 비즈니스 모델 결정 (광고 / 결제 / 무료)
  2. PTS / Live Activity / Remote Push 제거 검토
  3. 신규 사용자 시작 가이드 (인구통계 일반 권장 — Anti-Promise §4 정밀화 결과)
  4. 의료 추천 카테고리 전환 검토 (정체성 본질 변경 영역)
- "middle perforation" 명명 정정 (실제 봉지 세로의 ~30% 지점) — ADR-0009 / brief.md 후속 수정 영역.

## 참조
- 첨부 정체성 초안 `.context/attachments/pasted_text_2026-05-03_20-12-43.txt`
- 본 PR 구현계획서 `docs/plans/task_W1_27_impl.md`
- 본 PR 결과보고서 `docs/report/task_W1_27_report.md`
- Issue [#27](https://github.com/kswift1/PillPouch/issues/27)
