# CLAUDE.md — Pill Pouch AI 페어 가드레일

> Claude Code가 이 repo에서 작업할 때 자동 로드되는 컨텍스트 파일.

## 핵심 철학

**바이브 코딩이 아니다.** 모든 계획은 검토되고, 모든 결과물은 검증되며,
모든 결정의 뒤에는 사람이 있다. AI는 배율기다. **사람은 절대 생각을 멈추지 않는다.**

## 협업 컨벤션 (필독)

응답 패턴, AI 협업 메타-룰은 [`docs/conventions/`](docs/conventions/)에 단일 소스로 박제됨.
이 폴더는 모든 LLM(Claude/Codex/Cursor 등)과 사람이 공통으로 따르는 룰. **메모리 시스템 같은 LLM 전용 위치엔 박제 금지** (다른 LLM이 못 보고 사용자가 제어 불가).

핵심 룰 요약:
- **보고+승인 요청은 한 응답에 묶기** — "곧 드릴게요" 분리 금지 ([`docs/conventions/response-patterns.md` §1](docs/conventions/response-patterns.md))
- **결함 진단 시 재발 방지 조치 필수** — 진단만 하고 박제 안 하면 결함 반복 ([`docs/conventions/ai-collab-meta.md` §1](docs/conventions/ai-collab-meta.md))
- **백그라운드 작업 셋업 후 smoke test** — Monitor 등 시작 후 1 cycle 검증 필수 ([`docs/conventions/response-patterns.md` §3](docs/conventions/response-patterns.md))
- **테스트 메서드명 한글 + 언더바, enum case별 `///` doc-comment** — 코드 스타일 룰 ([`docs/conventions/code-style.md`](docs/conventions/code-style.md))

새 결함이 발견되면 [`docs/conventions/ai-collab-meta.md` §3 결함 박제 사례 표](docs/conventions/ai-collab-meta.md)에 1줄 추가.

## 절대 금지

- ❌ Issue 등록·브랜치·계획서 단계 생략
- ❌ 작업지시자 승인 없이 소스 수정 (M/L 태스크)
- ❌ 각 승인 게이트(plan/단계/최종) 통과 없이 다음 단계 진행
- ❌ 임의로 "이만 끝내자/시간 한정하자/다음에 하자" 제안 — 작업 시작·종료는 작업지시자가 결정
- ❌ 우회/임시방편/주석처리/`.skip`/`#[ignore]` 추가
- ❌ `--no-verify`, `--no-gpg-sign`, hook 우회
- ❌ 가설 B(기록 신뢰성)를 약화하는 시각/기능 — 매력적이어도 V1 밖
- ❌ Non-goals(`docs/brief.md` §Non-goals)에 해당하는 항목 추가 — TCA, Carousel, 단순 탭 체크 등
- ❌ Bundle ID에 대문자 (Topic Mismatch 위험, 기획서 경고)
- ❌ `docs/feedback/` 폴더에 AI가 글 쓰기 — 작업지시자 전용
- ❌ 기획서(`docs/brief.md`) 직접 수정 — 변경은 PR + ADR 링크 필수
- ❌ ADR을 Accepted 후 수정 — 결정이 바뀌면 새 ADR로 Supersede
- ❌ APNs `.p8`, `.env` 파일 git에 추가 (`.gitignore` 강제)

## 작업 사이클 (RHWP 적응형)

모든 태스크는 **S/M/L** 분류:

| 크기 | 정의 | 문서 | 승인 게이트 |
|---|---|---|---|
| **S** | 반나절 미만 (오타·작은 버그·lint·deps) | PR 본문만 | PR 리뷰 1회 |
| **M** | 반나절~3일 (1화면·1API·1모델·CRUD) | `*_impl.md` + `*_report.md` | 2회 (계획·최종) |
| **L** | 3일~1주 (큰 통합·위험 작업) | `*.md`(plan) + `*_impl.md` + `*_stage{N}.md` + `*_report.md` | 3+회 |

판단 기준: **불확실성**. 기능이 커도 패턴이 명확하면 M, 작아도 위험하면 L.
판단 어려우면 작업지시자에게 분류 묻기.

### M 태스크 절차
1. GitHub Issue 등록 (size:M, area:*, type:*, milestone W{N})
2. `local/task{이슈번호}` 브랜치 생성
3. `docs/plans/task_W{N}_{이슈}_impl.md` 작성 → **승인 ⛔**
4. 단일 PR 단위로 구현 (Conventional Commits)
5. CI 통과 (테스트 + Clippy/SwiftLint)
6. `docs/report/task_W{N}_{이슈}_report.md` 작성 → **승인 ⛔**
7. PR 본문에 계획서/보고서 링크 → **PR에도 이슈와 동일 라벨/마일스톤 부착** (`gh pr edit --milestone W{N} --add-label ...`) → Squash merge
8. Issue 자동 close (`Closes #N`) → 마일스톤의 마지막 이슈면 마일스톤 close 환기

### L 태스크 절차
M에 더해:
- **수행계획서(`task_W{N}_{이슈}.md`) 먼저 → 승인 ⛔**
- **단계별 보고서(`*_stage{N}.md`) 매 단계 → 승인 ⛔**

## 시각적 피드백 우선

UI 작업은 스크린샷 기반.
- ❌ "이상하다", "여백이 어색하다"
- ✅ "여기 1mm 위로", "베이스라인 1px 차이"
- Snapshot 테스트로 PNG 자동 생성 → `docs/screenshots/<feature>/` 커밋 → PR 본문 마크다운 링크

## 정면 돌파, 우회 금지

막히면 `docs/troubleshootings/<증상>.md` 작성 후 작업지시자 에스컬레이션.
임시방편으로 덮지 말 것. 재발 시 가장 먼저 확인하는 곳이 troubleshootings/.

## 가설 검증 게이트

모든 PR은 다음 체크 (PR 템플릿에 박혀 있음):
- [ ] 이 변경은 가설 B(기록 신뢰성)를 강화한다 — 또는 무관한 인프라/리팩토링이다
- [ ] Non-goals에 해당하지 않는다
체크 안 되면 ADR 작성 후 작업지시자 승인 필요.

## 코딩 스타일

### 공통
- **Conventional Commits 강제**: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`, `ci:`
- **Squash merge 전용** (repo 설정 강제)
- **PR 사이즈 +500 LOC 넘으면 분할 고민** (강제는 아님)
- 도메인 로직 TDD 강제 (인터랙션 임계값, 슬롯 시각 계산, 상태 전환, 페이로드 직렬화)
- 핵심 경로만 integration 테스트 (PTS 등록 → APNs 발송 → 토큰 회전 등 1~2개)

### iOS (`ios/`)
- SwiftUI 네이티브 + SwiftData (TCA 미사용 — V2 검토)
- 상태 관리: 단순 화면 `@Query`만, 복잡 화면(드래그) `@Observable` ViewModel
- 테스트: **Swift Testing** (Xcode 16+), `@Test` 매크로
- 포맷: SwiftFormat (pre-commit)

### 백엔드 (`server/`)
- Rust + Axum + sqlx (SQLite, compile-time checked queries)
- `crates/domain/` = 순수 도메인 로직, **unit 100%**
- `crates/api/` = HTTP 핸들러
- `crates/pusher/` = APNs HTTP/2 + 스케줄러
- `crates/storage/` = SQLite 접근
- `unsafe_code = "forbid"` (workspace 전체)
- `cargo clippy -- -D warnings` 통과 필수

## 폴더 구조 (요약)

```
pillpouch/
├── ios/PillPouch{,Tests,UITests,Widget}/  # SwiftUI 앱 + Extension
├── server/crates/{api,pusher,domain,storage}/  # Rust 워크스페이스
├── docs/  # SoT (brief.md, adr/, runbooks/, plans/, working/, report/, ...)
├── design/  # 색 토큰, 봉지 SVG, Figma 익스포트
└── .github/  # workflows, ISSUE/PR 템플릿
```

## 자주 쓰는 명령

```bash
# iOS 빌드
cd ios && xcodebuild -scheme PillPouch -sdk iphonesimulator build

# iOS 테스트
cd ios && xcodebuild test -scheme PillPouch -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Rust 전체 검증
cd server && cargo fmt --check && cargo clippy -- -D warnings && cargo test

# GitHub Issue 등록 (RHWP M 시작점)
gh issue create --milestone "W{N}" --label "size:M,area:?,type:?" --title "[M] ..."

# 브랜치
git switch -c local/task{이슈번호}
```

## 환경 / 시크릿

- `.env` (server/) — 로컬 개발용. 절대 git X.
- APNs `.p8` — Fly secrets에만 보관. 원본은 1Password/Keychain.
- `*.p8`, `.env*` 모두 `.gitignore` 강제.

## 기획서 변경 룰

1. `docs/brief.md` 직접 수정 X
2. 변경 필요 시 ADR 먼저: `docs/adr/00NN-{slug}.md` (Context/Decision/Consequences)
3. ADR 승인 후 brief.md PR (변경 로그 섹션 갱신)
4. 가설 B를 약화하는 변경은 거부 (시각/기능 양쪽)

## 참고

- 방법론 원본: [edwardkim/rhwp](https://github.com/edwardkim/rhwp) (Hyper-Waterfall)
- 기획서: [`docs/brief.md`](docs/brief.md)
- 마일스톤: [`docs/plan/milestones.md`](docs/plan/milestones.md)
- 작업 사이클 상세: [`CONTRIBUTING.md`](CONTRIBUTING.md)
