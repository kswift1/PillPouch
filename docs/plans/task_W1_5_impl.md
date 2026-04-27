# task_W1_5_impl.md — ADR 6종 + Runbook 4종 stub 구현계획서

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#5](https://github.com/kswift1/PillPouch/issues/5) |
| 마일스톤 | W1 |
| 크기 | M |
| 영역 | area:docs |
| 브랜치 | `local/task5` |
| 예상 시간 | 2~3시간 |

## 목표

W1까지 확정된 결정 사항을 ADR 6종으로 박제. 코드 외부 절차는 Runbook 4종 stub으로 자리 잡기. 이후 모든 결정 변경/도전은 ADR 참조 후 새 ADR로만.

## 구현 단계 (3단계, 순차)

### Step 1: ADR 6종 작성

각 ADR = 5분 안에 읽힘. 형식: `# ADR-NNNN: 제목` + Status / Context / Decision / Consequences.

| 파일 | 결정 | 핵심 출처 |
|---|---|---|
| `docs/adr/0001-rust-axum-backend.md` | Rust + Axum (Tokio 표준, tower 생태계) | 기획서 §기술 스택 + plan §결정사항 |
| `docs/adr/0002-sqlite-litestream.md` | SQLite + Litestream (R2 자동 백업, $0~$1/mo) | plan §결정사항 + 설명 대화 |
| `docs/adr/0003-fly-io-hosting.md` | Fly.io 도쿄 리전 (Litestream 친화, Rust micro VM) | plan §결정사항 |
| `docs/adr/0004-monorepo.md` | ios/ + server/ + docs/ 한 repo | plan §결정사항 |
| `docs/adr/0005-no-tca-swiftui-native.md` | SwiftUI 네이티브 + SwiftData (TCA 미사용, V2 검토) | 기획서 §기술 스택 |
| `docs/adr/0006-hyper-waterfall-adaptive.md` | RHWP 적응형 (S/M/L 사이클) | plan §RHWP + edwardkim/rhwp 차용 |

각 ADR Consequences에는 트레이드오프(긍정/부정) + 재검토 조건 명시.

### Step 2: Runbook 4종 stub 작성

각 stub = "Status: stub. W{N}에서 채움" + 채워야 할 섹션 목차 + 위험 메모.

| 파일 | 채움 시점 | stub에 들어갈 목차 |
|---|---|---|
| `docs/runbooks/apns-cert-setup.md` | W3 | .p8 발급 절차, Topic, Key ID, Bundle ID, Team ID, sandbox vs production, Bundle ID 대문자 함정 |
| `docs/runbooks/deploy.md` | W3 | `fly deploy`, 환경 변수 주입, Litestream 사이드카, 롤백 절차, 로그 확인 |
| `docs/runbooks/ios-pts-debug.md` | W5 | iOS 18.x PTS 토큰 미수신 케이스, 로컬 노티 폴백, 사용자 알림 UX |
| `docs/runbooks/litestream-restore.md` | W3 | R2 백업 확인, `litestream restore`, PITR, 재시작 후 정합성 검증 |

### Step 3: 색인 갱신 + 검증 + 보고서 + PR

- `docs/adr/README.md` — 목록 [x] 6개
- `docs/runbooks/README.md` — 목록 [x] 4개 (stub 표시)
- `docs/report/task_W1_5_report.md` 작성 → 승인 ⛔
- PR squash merge

## 커밋 단위 (Conventional Commits)

```
docs: add W1-2 (#5) implementation plan
docs(adr): add ADR-0001 Rust + Axum backend
docs(adr): add ADR-0002 SQLite + Litestream
docs(adr): add ADR-0003 Fly.io hosting
docs(adr): add ADR-0004 Monorepo
docs(adr): add ADR-0005 no TCA, SwiftUI native
docs(adr): add ADR-0006 Hyper-Waterfall adaptive
docs(runbooks): add 4 runbook stubs (apns/deploy/ios-pts-debug/litestream)
docs: update adr and runbooks README index
docs: add W1-2 final report
```

10개 commit. Squash 후 main에 1커밋.

## 위험 요소

1. **ADR 본문이 plan/기획서 중복** — ADR은 "결정의 핵심 이유"만 (5분 가독성 유지). 상세는 기획서/plan 링크.
2. **Runbook stub이 너무 빈약하면 W3에서 잊힘** — stub에 채워야 할 항목을 미리 목차로 박아둠 (위험 메모 포함).
3. **CI trigger 안 됨** — docs-only PR이라 paths filter로 ios-build/server-build 모두 skip. PR #4에서 같은 케이스 처리. Monitor는 `NO_CHECKS_TICKS` 표준 패턴(`response-patterns.md` §3) 사용.

## 검증 (Issue #5 마감 조건)

- [ ] `docs/adr/0001~0006-*.md` 6개 파일 존재, 각각 Status/Context/Decision/Consequences 섹션
- [ ] `docs/adr/README.md` 목록 [x] 6개
- [ ] `docs/runbooks/{apns-cert-setup,deploy,ios-pts-debug,litestream-restore}.md` 4개 stub 존재, "Status: stub" 명시
- [ ] `docs/runbooks/README.md` 목록 [x] 4개
- [ ] PR Squash merge

## 다음 (이 task 완료 후)

- task #4 (W1-3): SwiftData 모델 4종 + Item 제거 — `local/task6`
- task #5 (W1-4): design-system + 색 토큰 — `local/task7`
- 둘은 의존성 없음 → 병렬 가능
