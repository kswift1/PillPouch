# report/ — 최종 결과보고서 (M·L 모두)

태스크 완료 시점, PR 머지 직전에 작성. **작업지시자 승인 후 머지**.

## 파일명
`task_W{N}_{이슈}_report.md`

## 형식

```markdown
# task_W{N}_{이슈}_report.md

## Issue (링크)

## 한 일 (구현계획서 §단계별로 무엇을 했는지)
- Step 1: ...
- Step 2: ...

## 변경 파일 (요약)
- Added: N개
- Modified: M개
- Deleted: K개

## 검증 결과 (Issue 마감 조건 체크리스트 — 구현계획서에서 복사 + 결과)
- [x] xcodebuild build 성공
- [x] cargo test 성공 (15 passed)
- [ ] (실패한 항목 + 사유)

## 발견한 이슈 / 추가 작업
- 다음 task로 이월할 항목

## 메모
- 의외로 막혔던 부분, 배운 점
```

## 작성 후
1. PR 본문에 이 보고서 링크
2. 작업지시자 승인 ⛔
3. Squash merge
4. Issue 자동 close (PR `Closes #N`)
