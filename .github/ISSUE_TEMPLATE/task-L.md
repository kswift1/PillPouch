---
name: "태스크 L (3일~1주)"
about: "큰 통합/위험 작업. 풀 RHWP 사이클 (수행계획서 + 구현계획서 + 단계보고서 + 최종보고서)."
title: "[L] "
labels: ["size:L"]
---

## 배경 / 동기

## 목표 (성공 정의)

## 범위 / 비범위

## 접근 방식 (대안 비교)
<!-- 풀 사이클이 필요한 이유, 어떤 위험을 단계별 검증으로 막으려는지 -->

## RHWP 사이클 (L) — 풀
1. `docs/plans/task_W{N}_{이슈}.md` (수행계획서) → 승인 ⛔
2. `docs/plans/task_W{N}_{이슈}_impl.md` (구현계획서, 3~6단계) → 승인 ⛔
3. 단계별 진행 + `docs/working/task_W{N}_{이슈}_stage{M}.md` → 승인 ⛔ (단계마다)
4. `docs/report/task_W{N}_{이슈}_report.md` → 승인 ⛔
5. PR Squash merge

## 단계 분할 (구현계획서로 이어짐)
- Step 1: ...
- Step 2: ...
- Step 3: ...

## 검증 (마감 조건)
- [ ] ...

## 위험 요소

## 메모
- 마일스톤: W?
- 영역: area:?
- 브랜치: `local/task{이슈번호}`
