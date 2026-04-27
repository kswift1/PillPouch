# Pill Pouch — `docs/` 색인

이 폴더는 Pill Pouch V1 개발의 단일 소스(SoT)다. 모든 기획·결정·작업 진행은 여기서 일어난다.

## 핵심 문서
- [`brief.md`](brief.md) — **기획서 v0.4 (헌법, 변경은 PR + ADR 필수)**
- [`architecture.md`](architecture.md) — 시스템 다이어그램, 컴포넌트 책임
- [`data-model.md`](data-model.md) — SwiftData 모델 + 서버 SQLite 스키마
- [`api.md`](api.md) — 클라↔서버 엔드포인트 명세
- [`design-system.md`](design-system.md) — 색 토큰, 타이포, 봉지 5상태, 햅틱

## 폴더

| 폴더 | 용도 | 작성자 |
|---|---|---|
| [`adr/`](adr/) | Architecture Decision Records (5분 안에 읽힘) | AI/사람 |
| [`runbooks/`](runbooks/) | 코드 외부 절차 (인증서, 배포, 복구) | AI/사람 |
| [`plans/`](plans/) | 수행계획서·구현계획서 (RHWP) | AI |
| [`working/`](working/) | 단계별 완료보고서 (L 태스크만) | AI |
| [`report/`](report/) | 최종 결과보고서 (M·L) | AI |
| [`feedback/`](feedback/) | 작업지시자 피드백 — **AI 작성 금지** | 사람 |
| [`orders/`](orders/) | 일일 작업지시서 (`yyyymmdd.md`) | 사람 |
| [`tech/`](tech/) | 기술 조사·스펙 분석 | AI/사람 |
| [`troubleshootings/`](troubleshootings/) | 문제 해결 기록 | AI/사람 |
| [`plan/`](plan/) | 주차별 마일스톤·회고 | AI/사람 |
| [`dogfooding/`](dogfooding/) | 30일 도그푸딩 노트 (W5부터) | 사람 |

## 파일명 규칙 (RHWP)

| 종류 | 패턴 | 예시 |
|---|---|---|
| 수행계획서 | `task_W{N}_{이슈}.md` | `task_W3_12.md` |
| 구현계획서 | `task_W{N}_{이슈}_impl.md` | `task_W1_1_impl.md` |
| 단계보고서 | `task_W{N}_{이슈}_stage{M}.md` | `task_W3_12_stage2.md` |
| 최종보고서 | `task_W{N}_{이슈}_report.md` | `task_W1_1_report.md` |
| 피드백 | `task_W{N}_{이슈}_feedback.md` | `task_W1_1_feedback.md` |
| 일일지시 | `yyyymmdd.md` | `20260427.md` |

## 작업 사이클 (요약)

자세한 절차는 루트 `CONTRIBUTING.md` 참조.

- **S** (반나절 미만): PR 본문만
- **M** (반나절~3일): 구현계획서 + 최종보고서
- **L** (3일~1주): 수행계획서 + 구현계획서 + 단계보고서 + 최종보고서
