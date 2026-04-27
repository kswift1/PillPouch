# conventions/ — 협업 컨벤션 (LLM/사람 공통)

이 폴더는 **단일 소스**다. 모든 LLM(Claude/Codex/Cursor/Gemini 등)과 사람이 같은 룰을 따른다.

LLM별 진입점 파일(`CLAUDE.md`, 추후 `AGENTS.md`/`.cursorrules` 등)은 짧게 이 폴더를 참조만 한다.

## 목록

| 파일 | 룰 |
|---|---|
| [`response-patterns.md`](response-patterns.md) | 응답 패턴 (보고+승인 묶기, "곧 ~" 금지 등) |
| [`ai-collab-meta.md`](ai-collab-meta.md) | AI 협업 메타-룰 (결함 진단 시 재발 방지 조치 강제 등) |

## 추가 룰

새 룰이 생기면:
1. `docs/conventions/<주제>.md` 신설 (또는 기존 파일에 섹션 추가)
2. 위 표에 1줄 추가
3. PR로 변경 — git history에서 추적 + 사용자 review 가능

## 왜 메모리 시스템 대신 여기인가

- 메모리 시스템은 **Claude 전용** — Codex/Cursor/Gemini 등 다른 LLM이 못 봄
- 메모리 시스템은 **사용자 제어 불가** — PR 없이 AI 로컬에 박힘, git 추적 X
- repo 안 docs/conventions/는 **모든 도구가 읽음 + PR 추적 + 사용자 review/롤백 가능**
