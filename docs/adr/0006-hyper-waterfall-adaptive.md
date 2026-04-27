# ADR-0006: Hyper-Waterfall 적응형 (S/M/L)

## Status
Accepted — 2026-04-27

## Context
[edwardkim/rhwp](https://github.com/edwardkim/rhwp)의 **Hyper-Waterfall 방법론**을 차용. 핵심 원칙:
- 거시: 워터폴 (계획→설계→구현→검증→배포)
- 미시: 애자일 (단계 안에서 빠른 반복)
- 13단계 풀 사이클 (Issue → 브랜치 → 수행계획서 → 구현계획서 → 단계별 진행 + 보고서 → 최종보고서 → 머지)
- 3개 승인 게이트 (계획 / 단계별 / 최종)

문제: 13단계 풀 사이클을 모든 작업에 적용하면 솔로 6주 일정에 코드 < 문서가 됨 ("오타 수정"도 4종 문서 작성).

후보:
- **풀 사이클 (13단계 모든 태스크)**: 엄격, 검증 최고, 일정 부담 큼
- **모두 경량 (구현계획서+최종보고서만)**: 빠름, 단계별 검증 게이트 사라짐 → 위험 작업에 위험
- **적응형 (S/M/L)**: 태스크 크기에 따라 강도 조절

## Decision
**적응형 (S/M/L)** 채택. 판단 기준: **불확실성** (기능 크기 X).

| 크기 | 정의 | 문서 | 승인 게이트 |
|---|---|---|---|
| **S** | 반나절 미만 (오타·작은 버그·lint·deps) | PR 본문만 | PR 리뷰 1회 |
| **M** | 반나절~3일 (1화면·1API·1모델·CRUD) | 구현계획서 + 최종보고서 | 2회 (계획·최종) |
| **L** | 3일~1주 (큰 통합·위험 작업) | 수행계획서 + 구현계획서 + 단계보고서 + 최종보고서 | 3+회 (계획·단계별·최종) |

판단 어려우면 작업지시자에게 분류 묻기.

마일스톤 명명: 기획서 일정 그대로 **W1~W6 + V1.0/V1.1** (rhwp의 m100 형식 미채택, 직관성 우선).

브랜치 명명: `local/task{이슈번호}` (rhwp 패턴 차용).

문서 폴더: `docs/{plans, working, report, feedback, orders, tech, troubleshootings, adr, runbooks, plan, dogfooding}` + `docs/conventions/` (LLM 무관 협업 룰).

머지 방식: **Squash merge only** (repo 설정 강제), Conventional Commits.

## Consequences

### 긍정
- 솔로 6주 일정과 RHWP 가치(승인 게이트) 동시 보존
- AI 페어 가드레일 4중 박제 (`CLAUDE.md`, `CONTRIBUTING.md`, ISSUE_TEMPLATE 3종, PR 템플릿)
- 위험한 작업(L)엔 단계별 검증 게이트 살림
- 가벼운 작업(S)엔 문서 부담 최소
- 결함 박제 절차 명문화 (`docs/conventions/ai-collab-meta.md` §1)

### 부정 / 트레이드오프
- 분류 판단 비용 (S/M/L 결정에 매번 작은 고민)
- rhwp 원본과 명명/구조 일부 불일치 (마일스톤 W1 vs m100, 폴더 구조 다름) — 외부에 방법론 공개/공유 시 별도 변환 필요
- "M인지 L인지" 모호한 회색지대 존재 → "판단 어려우면 묻기" 룰로 대응

### 재검토 조건
- 협업자 합류 → 풀 사이클 채택 검토 (검증 게이트 강화)
- 6주+ 장기 일정 또는 V2 본격 개발 → 풀 사이클 검토
- 결함이 반복되면 분류 기준/체크리스트 보강 (이는 ADR 변경 없이 `docs/conventions/` 보강으로 처리)

## 참고
- 원본: [edwardkim/rhwp](https://github.com/edwardkim/rhwp)
- `docs/conventions/` (협업 컨벤션)
- `CONTRIBUTING.md` (절차 상세)
- `CLAUDE.md` (AI 가드레일)
