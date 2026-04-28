<!--
  Pill Pouch PR 템플릿 — RHWP 적응형 사이클 따름.
  S 태스크: 본문만, Linked docs 생략 가능.
  M/L 태스크: Linked docs 필수.
-->

## Why
<!-- 이 PR이 왜 필요한가? 어떤 문제를 푸는가? -->

## What
<!-- 무엇을 했나? 변경 요약 (어떻게는 코드와 보고서 참조) -->

## Test plan
- [ ] 로컬 빌드 통과
- [ ] (해당 시) 신규 테스트 추가 → 통과
- [ ] (UI 변경) Snapshot 테스트 PNG 갱신
- [ ] CI 통과

## PR 메타 (M/L 필수)
- [ ] 이슈와 동일한 **라벨**(size:* / area:* / type:*) PR에도 부착
- [ ] 이슈와 동일한 **마일스톤**(W{N}) PR에도 부여
- [ ] (이 PR로 마일스톤의 마지막 이슈가 닫히면) 마일스톤 close 환기

자세한 룰: [`docs/conventions/response-patterns.md` §4](../docs/conventions/response-patterns.md#4-pr-메타-동기화-라벨마일스톤)

## Screenshots
<!-- UI 변경 시 docs/screenshots/<feature>/ 에 커밋한 PNG 링크 또는 직접 첨부 -->

## Linked docs (M/L 필수)
- 구현계획서: `docs/plans/task_W{N}_{이슈}_impl.md`
- 최종보고서: `docs/report/task_W{N}_{이슈}_report.md`
- (L 한정) 수행계획서: `docs/plans/task_W{N}_{이슈}.md`
- (L 한정) 단계보고서: `docs/working/task_W{N}_{이슈}_stage*.md`

## 가설 검증 체크 (Pill Pouch 정체성 보호)
- [ ] 이 변경은 가설 B(기록 신뢰성)를 강화한다 — 또는 무관한 인프라/리팩토링이다
- [ ] Non-goals(`docs/brief.md` §Non-goals)에 해당하지 않는다
- [ ] 가설 약화 가능성이 있으면 ADR 작성 후 작업지시자 승인 받았다

## 기타
- PR 사이즈가 +500 LOC 넘으면 분할 고민 (강제는 아님)
- 머지 방식: **Squash merge** (settings 강제)

Closes #
