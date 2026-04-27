# task_W1_1_impl.md — Repo 골격 구현계획서

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#1](https://github.com/kswift1/PillPouch/issues/1) |
| 마일스톤 | W1 |
| 크기 | M |
| 영역 | area:docs, area:infra |
| 브랜치 | `local/task1` |
| 예상 시간 | 2~3시간 |

## 목표

Pill Pouch V1 monorepo 골격을 완성한다. 이후 모든 작업이 `docs/plans/`, `docs/report/`, `ios/`, `server/` 등 정해진 위치에서 일관되게 일어나도록 기반을 마련한다.

## 구현 단계 (7단계, 순차)

### Step 1: docs/ 폴더 stub 채우기 (이미 mkdir 완료)
이 계획서가 첫 파일. 나머지는 "목적 1줄 + TODO" 형태의 stub.

작성 파일:
- `docs/README.md` — docs/ 폴더 색인
- `docs/brief.md` — `.context/attachments/pasted_text_2026-04-27_18-23-57.txt`를 그대로 복사 (기획서 v0.4)
- `docs/architecture.md` — stub
- `docs/data-model.md` — stub
- `docs/api.md` — stub
- `docs/design-system.md` — stub (W1-4에서 채움)
- `docs/adr/README.md` — stub (W1-2에서 ADR 6종 추가)
- `docs/runbooks/README.md` — stub (W1-2에서 runbook 4종 stub)
- `docs/plans/README.md` — 사용 가이드
- `docs/working/README.md` — L 태스크용 안내
- `docs/report/README.md` — 사용 가이드
- `docs/feedback/README.md` — **AI 작성 금지** 명시
- `docs/orders/README.md` — yyyymmdd.md 형식 안내
- `docs/tech/README.md` — 자유 명명 안내
- `docs/troubleshootings/README.md` — 해결 후 기록 안내
- `docs/plan/README.md` + `docs/plan/milestones.md` (W1~W6 마일스톤 표)
- `docs/dogfooding/README.md` — W5부터 사용 명시

### Step 2: Xcode 프로젝트 → ios/ 이동
```bash
mkdir -p ios
git mv PillPouch.xcodeproj ios/PillPouch.xcodeproj
git mv PillPouch ios/PillPouch
git mv PillPouchTests ios/PillPouchTests
git mv PillPouchUITests ios/PillPouchUITests
```
검증: `cd ios && xcodebuild -scheme PillPouch -sdk iphonesimulator build`

### Step 3: server/ Cargo workspace 빈 골격
```
server/
├── Cargo.toml                 # workspace 정의
├── crates/
│   ├── api/{Cargo.toml, src/lib.rs}
│   ├── pusher/{Cargo.toml, src/lib.rs}
│   ├── domain/{Cargo.toml, src/lib.rs}
│   └── storage/{Cargo.toml, src/lib.rs}
└── README.md                  # 로컬 실행 + 배포 안내 stub
```
각 lib.rs는 `pub fn placeholder() {}` 1줄. 검증: `cd server && cargo build && cargo test`

### Step 4: .gitignore 통합
기존 Xcode 패턴 유지 + 추가:
```
# Rust
target/
**/*.rs.bk
Cargo.lock는 keep (바이너리 프로젝트)

# macOS
.DS_Store

# Env
.env
.env.local
*.p8

# Conductor
.context/
```

### Step 5: .github/ 셋업
**workflows/ios-build.yml** — paths: `ios/**`, runs-on: macos-latest
- actions/checkout
- actions/setup-xcode (필요 시 Xcode 16+)
- xcodebuild test -scheme PillPouch -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=latest'

**workflows/server-build.yml** — paths: `server/**`, runs-on: ubuntu-latest
- actions/checkout
- dtolnay/rust-toolchain@stable + components: rustfmt, clippy
- Swatinem/rust-cache
- cargo fmt --check / cargo clippy -- -D warnings / cargo test

**ISSUE_TEMPLATE/** — task-S.md, task-M.md, task-L.md (size 라벨 자동 적용)

**pull_request_template.md** — 섹션:
- ## Why
- ## What
- ## Test plan
- ## Screenshots (해당 시)
- ## Linked docs (계획서/보고서 링크)
- ## 가설 검증 체크
  - [ ] 이 변경은 가설 B(기록 신뢰성)를 강화한다
  - [ ] Non-goals(brief.md §Non-goals)에 해당하지 않는다
- Closes #N

### Step 6: 루트 문서 3종
- **README.md** — 한 줄 컨셉 + 폴더 안내(`ios/`, `server/`, `docs/`, `design/`) + 빠른 시작
- **CLAUDE.md** — Plan §8 그대로 복사 (AI 페어 가드레일)
- **CONTRIBUTING.md** — RHWP 적응형 사이클 절차 (S/M/L 정의, 13단계 매핑, 절대 금지 룰)

### Step 7: 검증 + 보고서 + PR
1. 로컬 빌드 통과 (xcodebuild + cargo build)
2. 커밋 그룹화 (Conventional Commits)
3. `docs/report/task_W1_1_report.md` 작성 → 작업지시자 승인
4. PR 생성, 본문에 plans/report 링크 + 가설 체크
5. CI 통과 후 squash merge

## 커밋 단위 (Conventional Commits)

```
docs: add W1-1 implementation plan
chore: scaffold docs/ folder structure with stubs
docs: copy brief.md from attachments (v0.4)
chore: move Xcode project into ios/
chore: scaffold server/ Cargo workspace (4 crates)
chore: unify .gitignore (Rust + macOS)
ci: add ios-build and server-build workflows with paths filter
chore: add issue templates (S/M/L) and PR template
docs: add root README, CLAUDE.md, CONTRIBUTING.md
docs: add W1-1 final report
```

10개 커밋 내외. PR squash merge 시 main에 1커밋으로 박힘.

## 위험 요소

1. **Xcode 프로젝트 이동 후 path 깨짐** — `.xcodeproj` 내부 path는 상대경로라 보통 안 깨지지만, 만약 깨지면 Xcode에서 직접 열어 path 재설정 필요. 발견: Step 2 검증.
2. **CI macos-latest의 Xcode 버전이 Swift Testing(Xcode 16+) 미지원 가능성** — `xcode-actions/setup-xcode@v1`로 명시 버전 고정.
3. **PillPouchTests의 기본 boilerplate 테스트 실패 가능성** — 기본 `Item` 모델에 의존. 이 PR에선 통과만 시키고, W1-3에서 모델 갈아엎으면서 재작성.

## 검증 (Issue #1 마감 조건)

- [ ] `cd ios && xcodebuild -scheme PillPouch -sdk iphonesimulator build` 성공
- [ ] `cd ios && xcodebuild test -scheme PillPouch -destination 'platform=iOS Simulator,name=iPhone 15 Pro'` 성공
- [ ] `cd server && cargo build` 성공
- [ ] `cd server && cargo test` 성공 (빈 테스트 통과)
- [ ] PR 올렸을 때 `ios-build` / `server-build` 워크플로우가 paths 필터로 분기 (둘 다 트리거됨, 변경 영역만 실제 빌드)
- [ ] `CLAUDE.md`가 repo 루트에 존재
- [ ] PR 템플릿에 가설 체크박스 있음
- [ ] `docs/brief.md`가 기획서 v0.4 그대로

## 다음 (이 task 완료 후)
- W1-2 (Issue #2): ADR 6종 + Runbook 4종 stub — `local/task2` 분기 시작 가능
