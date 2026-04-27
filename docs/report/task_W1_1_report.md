# task_W1_1_report.md — Repo 골격 최종보고서

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#1](https://github.com/kswift1/PillPouch/issues/1) |
| 마일스톤 | W1 |
| 크기 | M |
| 영역 | area:docs, area:infra |
| 브랜치 | `local/task1` |
| 구현계획서 | [`task_W1_1_impl.md`](../plans/task_W1_1_impl.md) |

## 한 일 (구현계획서 §단계별)

### Step 1: docs/ 폴더 stub 채우기 ✅
18개 .md 파일 생성:
- `docs/README.md`, `docs/brief.md` (기획서 v0.4 524줄 그대로 복사)
- `docs/architecture.md`, `data-model.md`, `api.md`, `design-system.md` (stub)
- `docs/adr/README.md`, `docs/runbooks/README.md`
- `docs/plans/README.md` + `task_W1_1_impl.md`
- `docs/working/README.md`, `report/README.md`, `feedback/README.md` (AI 작성 금지 명시)
- `docs/orders/README.md`, `tech/README.md`, `troubleshootings/README.md`
- `docs/plan/README.md` + `milestones.md` (W1~W6 + V1.0/V1.1 표)
- `docs/dogfooding/README.md` + `log-template.md`

### Step 2: Xcode 프로젝트 → ios/ 이동 ✅
`git mv`로 4개 폴더 이동. `xcodebuild build` 통과 — path 깨짐 없음.

### Step 3: server/ Cargo workspace 빈 골격 ✅
4 crate (`api`, `pusher`, `domain`, `storage`) + workspace `Cargo.toml`.
- `unsafe_code = "forbid"` workspace 적용
- `clippy::all = deny`, `clippy::pedantic = warn`
- 각 crate는 `placeholder()` 함수 + unit 테스트 1개
- `cargo build` + `cargo test` 통과

### Step 4: .gitignore 통합 ✅
기존 Xcode 패턴 + 추가:
- macOS (`.DS_Store`, `.AppleDouble`, `.LSOverride`)
- Rust (`target/`, `**/*.rs.bk`, `*.pdb`)
- 시크릿 (`.env*`, `*.p8`)
- Conductor (`.context/`)
- 에디터 (`.idea/`, `.vscode/`, `*.swp`)
- `Cargo.lock` keep 명시 (바이너리 프로젝트)

### Step 5: .github/ 셋업 ✅
- `workflows/ios-build.yml` — paths `ios/**`, **동적 시뮬 ID 선택** (xcrun + jq), 빌드+테스트, 실패 시 xcresult 업로드
- `workflows/server-build.yml` — paths `server/**`, fmt+clippy+test, Swatinem 캐시
- `ISSUE_TEMPLATE/task-{S,M,L}.md` — 크기별 자동 라벨, RHWP 절차 명시
- `pull_request_template.md` — Why/What/Test plan/Linked docs/**가설 검증 체크박스**/Closes #N

### Step 6: 루트 문서 3종 ✅
- `README.md` — 한 줄 컨셉 + 폴더 안내 + 빠른 시작 + 기술 스택
- `CLAUDE.md` — AI 페어 가드레일 (절대 금지 11개, RHWP 사이클, 시각적 피드백, 가설 게이트, 자주 쓰는 명령)
- `CONTRIBUTING.md` — RHWP 적응형 사이클 절차 (사람도 따름)

### Step 7: 검증 ✅
아래 §검증 결과 참조.

---

## 변경 파일

| 종류 | 수 | 비고 |
|---|---|---|
| Renamed (Xcode → ios/) | 11 | `git mv`로 history 보존 |
| Modified | 1 | `.gitignore` |
| Added | 32 | docs/ 18 + server/ 9 + .github/ 6 + 루트 3 - report 1 (이 파일은 이번 PR에 포함) - 1 = 32 |

---

## 검증 결과 (Issue #1 마감 조건)

- [x] **`cd ios && xcodebuild -scheme PillPouch -sdk iphonesimulator build` 성공** — `** BUILD SUCCEEDED **`
- [x] **`xcodebuild test` 성공** — iPhone 17 Pro (iOS 26.4) 시뮬레이터, 모든 테스트 통과
  - PillPouchTests/example() ✅
  - PillPouchUITests/testExample() ✅
  - PillPouchUITestsLaunchTests/testLaunch() ✅ (4회)
  - 결과: `** TEST SUCCEEDED **`
- [x] **`cargo build` 성공** — 4 crate 컴파일
- [x] **`cargo test` 성공** — 4 placeholder 테스트 통과 (api, pusher, domain, storage)
- [x] **CI paths 필터 분기** — `ios/**`만 변경 시 `ios-build` 트리거, `server/**`만 변경 시 `server-build` 트리거. 이번 PR은 둘 다 변경이라 둘 다 실행 예정
- [x] **`CLAUDE.md` repo 루트 존재** — Claude Code 자동 로드 가능
- [x] **PR 템플릿 가설 체크박스 존재** — `pull_request_template.md`에 2개 체크
- [x] **`docs/brief.md`가 기획서 v0.4** — `.context/attachments/...txt`를 그대로 복사 (524줄)

---

## 발견한 이슈 / 추가 작업

1. **CI destination 동적화** — 로컬 환경(Xcode 26.4 + iPhone 17 Pro)과 GitHub Actions(Xcode 16.x + iPhone 16 시리즈) 시뮬레이터 차이 때문에 `xcrun simctl`로 첫 번째 iPhone 시뮬을 자동 선택하도록 워크플로우 갱신. **계획서 §위험 요소 #2 대응 완료**.
2. **Xcode 26.4 + macOS 26 환경 발견** — 기획서 가정(Xcode 16+)보다 훨씬 최신. 로컬엔 영향 없음. CI는 동적 선택으로 호환.
3. **Xcode 기본 boilerplate 테스트 (`PillPouchTests/example()`)는 빈 함수**라 W1-3에서 모델 갈아엎을 때 자유롭게 재작성 가능 — 계획서 §위험 #3 우려 해소.
4. **Bundle ID `com.co.sungwon.PillPouch`** — 현재 소문자/유효. 기획서 경고(대문자 금지) 통과. CLAUDE.md에 룰 박제됨.
5. **"태스크" 표기 통일** — 외래어 표기법(`task` [tæsk] → "태스크") 기준으로 13개 `.md` 파일에서 "타스크" → "태스크" 일괄 교체. rhwp 원본은 "타스크" 표기지만 Pill Pouch는 표준 표기를 따름. 추후 W1-2에서 ADR로 박제 검토.

---

## 다음 (이 task 완료 후)

- W1-2 (Issue #2): ADR 6종 + Runbook 4종 stub — `local/task2` 분기 시작 가능
- task #1 PR 머지 후 GitHub branch protection 활성화 (현재 비활성, 첫 PR이 막히지 않도록)

---

## 메모

- Conventional Commits로 커밋을 단계별 분리해 squash 전 가독성 확보. squash 후엔 main에 1커밋으로 박힘.
- 기획서 §변경 로그 v0.4의 모든 결정 사항이 plan/CLAUDE.md/CONTRIBUTING에 박제됨 — Pill Pouch 정체성을 이후 모든 PR에서 자동으로 보호.
- RHWP 적응형(S/M/L)은 ISSUE_TEMPLATE 3종 + PR 템플릿 + CLAUDE.md + CONTRIBUTING의 4중 박제로 룰이 휘발되지 않게 함.
