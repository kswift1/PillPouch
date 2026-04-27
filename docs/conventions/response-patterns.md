# response-patterns.md — 응답 패턴 컨벤션

LLM이 사용자에게 응답할 때 반드시 따르는 패턴.

---

## 1. 보고와 승인 요청은 한 응답에 묶기

작업이 끝나거나 외부 이벤트(CI 결과, 빌드 종료 등) 결과를 받았을 때, 다음 둘을 **같은 응답** 안에 모두 보낸다:

1. **결과 보고** — 무엇이 통과/실패/완료됐는지
2. **다음 결정에 필요한 승인 요청** — 머지할까, 다음 단계 갈까, 변경 필요한가

### 금지 패턴

- ❌ "결과는 통과했습니다. 승인 요청 메시지 곧 드릴게요"
- ❌ "확인했습니다. 잠시 후 정리해드릴게요"
- ❌ "보고 정리해서 다시 답변드릴게요"

→ 사용자가 "응?", "그래서?", "다음은?" 같은 추가 입력을 보내야만 진행되는 무의미한 왕복 발생.

### 올바른 패턴

```
## CI 결과
| 워크플로우 | 결과 |
|---|---|
| iOS | ✅ pass (7m40s) |
| Rust | ✅ pass (20s) |

## 머지 승인 요청 ⛔
`gh pr merge 2 --squash --delete-branch` 진행해도 될까요?
- 진행 → "ㅇㅇ"
- 변경 필요 → 어디를 어떻게
```

→ 한 응답에 결과 + 다음 결정 요청 모두. 사용자는 "ㅇㅇ" 한 번이면 다음 단계 진입.

### 응답 끊고 사용자 답을 기다려야 하는 경우 (예외)

- 정말 추가 정보가 필요해서 묻는 AskUserQuestion (옵션 분기, 가치 판단 등)
- 그 외에 "곧"이라는 단어로 응답을 끝내지 말 것

---

## 2. 응답 패턴 결함 진단 시 재발 방지 조치 필수

응답 패턴 결함을 인지하거나 사용자에게 지적받았을 때, 같은 응답 안에 다음을 모두 포함:

1. **진단** — 어떤 패턴이 잘못됐고 왜 잘못됐는지
2. **올바른 패턴** — 무엇을 했어야 하는지
3. **재발 방지 조치** — 구체적으로 어디에 박제할 것인지 (이 파일에 추가, CLAUDE.md 갱신 등)

진단으로만 끝내면 같은 결함이 반복된다. "다음부턴 안 그러겠다"는 약속은 휘발성이라 무의미. **박제 위치를 명시하고 즉시 박제까지** 해야 한다.

상세는 [`ai-collab-meta.md`](ai-collab-meta.md) 참조.

---

## 3. 백그라운드 작업 셋업 후 smoke test

장시간 작업(CI watch, 빌드, 테스트 등)을 background로 돌릴 때:

1. 시작 직후 **1 cycle 후 동작 검증** — task output 한 번 읽어서 정상 polling 중인지 확인
2. 알림 본문 받으면 그대로 신뢰하지 말고 **한 번 더 cross-check** (예: `gh pr checks` 직접 호출)
3. 검증 안 된 알림으로 다음 작업 진행 금지

### 사례 박제

- **2026-04-27 PR #2 CI watch v1**: awk 공백 split 버그로 false positive 알림 → 즉시 stream end → 검증 없었으면 잘못된 결과 보고할 뻔
- 교훈: Monitor 셋업 직후 첫 polling cycle에서 출력 1줄이라도 직접 확인했어야

### 시스템 제약 — Bash 능동 polling 금지

이 환경에서는 다음이 차단된다 (`sleep`/`until` 직접 실행으로 polling 흉내 금지):
- 60초 이상의 leading `sleep`
- `until <check>; do sleep N; done` 같은 명시적 polling loop
- 짧은 sleep을 chain해서 우회하는 패턴

→ smoke test도 사람 polling으로 못 함. 대신:

1. **Monitor 도구가 background polling을 담당** (`while true; do ...; sleep 30; done` 안에 종료 조건 + 알림)
2. **smoke 신호는 Monitor 첫 알림으로 갈음** — 첫 알림이 정상 형식으로 오면 polling 루프와 출력 파싱이 살아있다는 증거
3. **추가 검증이 필요하면 Monitor 스크립트 첫 라인에 `echo "[smoke] poll 1"` 같은 진단 출력 추가** — 노이즈 1라인으로 alive 신호 확보 (단, 매 cycle마다 echo는 노이즈 폭주이므로 첫 cycle만)
4. **Monitor 알림이 와도 본문 그대로 신뢰 X** — `gh pr checks` 같은 명령으로 한 번 더 cross-check

### Monitor 셋업 체크리스트

- [ ] 종료 조건이 모든 terminal state(pass/fail/cancelled)를 커버하는가? "silence is not success"
- [ ] 출력 필터가 awk 탭 구분자(`-F'\t'`) 등 입력 형식을 정확히 반영하는가?
- [ ] 첫 알림 도착 시 cross-check를 실제 명령으로 한 번 더 검증할 계획이 있는가?
- [ ] 알림 본문에 사용한 escape/마크다운이 task-notification에서 깨지지 않는가? (예: `&` → `&amp;` 변환 주의)
- [ ] **`TOTAL=0` 케이스 처리** — `gh pr checks` 결과가 0줄(=CI 자체가 trigger 안 됨)일 때도 종료해야. paths filter로 docs-only PR이 CI skip되면 무한 polling됨

### Monitor 종료 조건 표준 패턴 (PR CI watch)

```bash
NO_CHECKS_TICKS=0
while true; do
  OUT=$(gh pr checks <PR_NUM> 2>&1 || true)
  PENDING=$(echo "$OUT" | awk -F'\t' '{print $2}' | grep -cE '^(pending|queued|in_progress)$' || true)
  TOTAL=$(echo "$OUT" | grep -c 'https://github' || true)
  if [ "$TOTAL" -eq 0 ]; then
    NO_CHECKS_TICKS=$((NO_CHECKS_TICKS + 1))
    if [ "$NO_CHECKS_TICKS" -ge 3 ]; then
      echo "=== PR <PR_NUM> NO CHECKS (3 ticks) — paths filter likely skipped all workflows ==="
      break
    fi
  elif [ "$PENDING" -eq 0 ]; then
    echo "=== PR <PR_NUM> CI DONE ==="
    echo "$OUT" | awk -F'\t' '{printf "%s | %s | %s\n", $1, $2, $3}'
    break
  fi
  sleep 30
done
```

3 ticks(약 90초) 동안 checks 0개면 "trigger 안 됨"으로 판단하고 종료. 30초만 기다리면 GitHub의 trigger 지연으로 false positive 가능.

---

## 변경 이력

- 2026-04-27: 초기 작성 (PR #2)
