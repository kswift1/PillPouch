# task_W1_5_report.md — ADR 6종 + Runbook 4종 stub 최종보고서

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#5](https://github.com/kswift1/PillPouch/issues/5) |
| 마일스톤 | W1 |
| 크기 | M |
| 영역 | area:docs |
| 브랜치 | `local/task5` |
| 구현계획서 | [`task_W1_5_impl.md`](../plans/task_W1_5_impl.md) |

## 한 일 (구현계획서 §단계별)

### Step 1: ADR 6종 작성 ✅
모두 5분 가독성, Status / Context / Decision / Consequences 4섹션:
| 파일 | 결정 |
|---|---|
| `docs/adr/0001-rust-axum-backend.md` | Rust + Axum + Tokio + sqlx + tower-http |
| `docs/adr/0002-sqlite-litestream.md` | SQLite + Litestream → Cloudflare R2 |
| `docs/adr/0003-fly-io-hosting.md` | Fly.io 도쿄 리전, shared-cpu-1x 256MB + 1GB 볼륨 |
| `docs/adr/0004-monorepo.md` | 단일 repo, ios/ + server/ + docs/ + design/ 분리 |
| `docs/adr/0005-no-tca-swiftui-native.md` | SwiftUI 네이티브 + SwiftData (TCA 미사용, V2 검토 조건 6개 명시) |
| `docs/adr/0006-hyper-waterfall-adaptive.md` | RHWP 적응형 (S/M/L), 마일스톤 W1~W6, Squash merge only |

각 ADR Consequences에 긍정/부정/트레이드오프 + 재검토 조건 명시.

### Step 2: Runbook 4종 stub 작성 ✅
| 파일 | stub 구성 | 채움 시점 |
|---|---|---|
| `docs/runbooks/apns-cert-setup.md` | 5단계 목차 + Bundle ID 대문자 함정 + 키 보관 룰 | W3 |
| `docs/runbooks/deploy.md` | 6단계 목차 + 첫 배포·일상 배포·롤백·모니터링 | W3 |
| `docs/runbooks/ios-pts-debug.md` | 5단계 목차 + iOS 18.x 알려진 이슈 + 폴백 패턴 | W5 |
| `docs/runbooks/litestream-restore.md` | 6단계 목차 + 정상 백업·임의 시점 PITR·정합성 검증 | W3 |

각 stub에 위험 메모와 채워야 할 항목 미리 박음 → W3/W5에서 잊힘 방지.

### Step 3: 색인 갱신 ✅
- `docs/adr/README.md`: 목록 6개 [x] + 링크
- `docs/runbooks/README.md`: 5개 표(github-repo-setup ✅ + 4 stub 🟡), 채움 시점 명시

## 변경 파일

| 종류 | 수 |
|---|---|
| Added | 11 (ADR 6 + Runbook 4 stub + 보고서 1) |
| Modified | 2 (adr/README, runbooks/README) |
| Deleted | 0 |

## 검증 결과 (Issue #5 마감 조건)

- [x] ADR 6개 파일 존재, 각각 Status/Context/Decision/Consequences 갖춤
- [x] `adr/README.md` 목록 [x] 6개 + 링크
- [x] Runbook 4개 stub 존재, "Status: stub. W{N}에서 채움" 명시
- [x] `runbooks/README.md` 갱신 (5개 표, github-repo-setup 별도 표시)
- [ ] PR Squash merge (이번 보고서 승인 후)

## 발견한 이슈 / 추가 작업

1. **CI 트리거 안 됨** — docs-only PR이라 `ios-build`/`server-build` 모두 paths filter로 skip. 의도된 동작. Monitor는 PR #4에서 박제한 `NO_CHECKS_TICKS` 표준 패턴(`docs/conventions/response-patterns.md` §3) 사용.
2. **runbooks/README 표 형식 변경** — 기존 [ ] 체크리스트에서 표(파일·상태·채움 시점)로 변경. github-repo-setup.md(완료된 SoT)와 stub 4개를 시각적으로 구분.
3. **ADR-0005 재검토 조건 6개 박제** — TCA 도입 검토 조건을 명문화 (화면 10개+, CloudKit 충돌, 가족 공유, 외부 API 다발, 테스트 커버리지 본격, 협업자 합류 중 2개 이상).

## 다음 (이 task 완료 후)

- task #4 (W1-3): SwiftData 모델 4종 + Item 제거 — `local/task6`
- task #5 (W1-4): design-system + 색 토큰 — `local/task7`
- 둘은 의존성 없음 → 병렬 가능 (Conductor 워크스페이스 분기 활용 검토)

## 메모

- ADR은 Accepted 후 수정 X 룰. 결정 변경 시 새 ADR로 Supersede.
- Runbook stub의 "위험 메모" 섹션이 향후 본문 채울 때 누락 방지 가이드 역할.
