# ai-collab-meta.md — AI 협업 메타 컨벤션

AI(LLM)와 사람이 협업할 때 따르는 메타-룰. "어떻게 일하느냐"에 대한 룰.

---

## 1. 결함 진단 시 재발 방지 조치 필수

응답/작업/판단의 결함을 인지하거나 사용자에게 지적받았을 때, **같은 응답 안에** 다음을 모두 포함해야 한다:

| 항목 | 내용 |
|---|---|
| 1. 진단 | 어떤 패턴이 잘못됐고 왜 잘못됐는지 |
| 2. 올바른 방법 | 무엇을 했어야 하는지 |
| 3. **박제 조치** | 구체적으로 어디에 룰을 박을 것인지 + 즉시 박제 실행 |

### 왜 필요한가

진단으로만 끝나면 같은 결함이 반복된다. "다음부턴 조심하겠습니다" 같은 약속은 휘발성이라 무의미.
박제 위치를 명시하고 즉시 박제까지 해야 한다.

### 박제 위치 우선순위

| | 위치 | 적용 범위 | 추적 |
|---|---|---|---|
| 1순위 | `docs/conventions/<주제>.md` | 모든 LLM + 사람 공통 | git PR |
| 2순위 | `CLAUDE.md` (또는 `AGENTS.md`/`.cursorrules`) | 해당 LLM만 자동 로드 | git PR |
| 3순위 | `docs/runbooks/<주제>.md` | 운영 절차 | git PR |
| 회피 | LLM 내부 메모리 시스템 | 해당 LLM만 + 사용자 제어 X + git X | — |

**원칙: 협업 룰은 repo 안에. 메모리 시스템은 회피.**

### 박제 절차

1. 결함 인지/지적 받음
2. 같은 응답에 "진단 + 올바른 방법 + 박제 위치" 명시
3. **그 응답에서 즉시 파일 생성/수정** (다음 응답으로 미루지 말 것)
4. 사용자 승인 후 PR/commit으로 영구화

---

## 2. 협업 룰은 LLM 무관하게 박제

LLM 전용 위치(메모리 시스템, ChatGPT custom instructions 등)에 박제 금지.
이유:
- 다른 LLM이 못 봄 → 협업 결함 재발
- 사용자가 직접 검토/수정 불가
- git history에서 추적 불가
- 다른 워크스페이스/팀원에게 전수 불가

대신 `docs/conventions/`에 박제 + LLM별 진입점(`CLAUDE.md` 등)은 짧게 그 폴더를 참조.

---

## 3. 결함 박제 사례 (자기 추적용)

| 날짜 | 결함 | 박제 위치 |
|---|---|---|
| 2026-04-27 | "곧 드릴게요" 응답 분리 | [`response-patterns.md` §1](response-patterns.md#1-보고와-승인-요청은-한-응답에-묶기) |
| 2026-04-27 | 결함 진단 후 박제 안 함 | [`ai-collab-meta.md` §1](ai-collab-meta.md#1-결함-진단-시-재발-방지-조치-필수) (이 파일) |
| 2026-04-27 | LLM 메모리 시스템에 협업 룰 박제 (다른 LLM 못 봄) | [`ai-collab-meta.md` §2](ai-collab-meta.md#2-협업-룰은-llm-무관하게-박제) (이 파일) |
| 2026-04-27 | Background Monitor 셋업 후 smoke test 안 함 | [`response-patterns.md` §3](response-patterns.md#3-백그라운드-작업-셋업-후-smoke-test) |
| 2026-04-27 | Monitor 종료 조건이 `TOTAL=0` 케이스 미처리 — docs-only PR이 paths filter로 CI skip되면 무한 polling | [`response-patterns.md` §3 — Monitor 종료 조건 표준 패턴](response-patterns.md#monitor-종료-조건-표준-패턴-pr-ci-watch) |
| 2026-04-27 | GitHub 메타 변경(가시성/protection 등)이 git history에 안 남는다는 것을 의식 못 함 — 박제 안 하면 휘발 | [`docs/runbooks/github-repo-setup.md`](../runbooks/github-repo-setup.md) (SoT) |
| 2026-04-27 | 시스템 알림(stream ended)에 "(대기 중)" 짧게 답해서 직전 머지 승인 요청을 가림 — 사용자가 "머지승인요청 오는거야?" 재확인 필요 | [`response-patterns.md` §1 — 시스템 알림에 짧게 응답할 때](response-patterns.md#시스템-알림에-짧게-응답할-때--미해결-결정-환기) |

새 결함이 발견될 때마다 이 표에 1줄 추가.

---

## 변경 이력

- 2026-04-27: 초기 작성 (PR #2)
