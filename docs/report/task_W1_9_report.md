# task_W1_9_report.md — design-system.md + 색 토큰 코드화 최종보고서

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#9](https://github.com/kswift1/PillPouch/issues/9) |
| 마일스톤 | W1 |
| 크기 | M |
| 영역 | area:design + area:ios |
| 브랜치 | `kswift1/task9-tokens` |
| 구현계획서 | [`task_W1_9_impl.md`](../plans/task_W1_9_impl.md) |

## 한 일 (구현계획서 §단계별)

### Step 1: `docs/design-system.md` 본문 채움 ✅

stub → 11개 본문 섹션:

| § | 섹션 | 핵심 내용 |
|---|---|---|
| 1 | 목적 & SoT 위계 | brief(1) → design-system(2) → Swift 토큰(3) 위계 박제, 변경 정책 |
| 2 | 톤 / 금기 / 지향 | Things 3 + Streaks 결, 의료/형광 색/체크 마크 금기 |
| 3 | 색 토큰 | background/surface/stroke/text + morning/lunch/evening 라이트+다크 hex 표 + 채도 감소 공식 `S × (1-p)` |
| 4 | 타이포그래피 | 시스템 `.rounded` Dynamic Type 5 토큰 |
| 5 | 스페이싱 | 8pt grid xs..xxl 6 토큰 |
| 6 | 봉지 5상태 | 비율 100:32, V컷 22%, sine 2.0pt, 5상태 변형 표, 도그푸딩 D7 게이트 |
| 7 | 캡슐 6종 | SVG 명세 + GPT Image 2 프롬프트 6개 (공통 라벨 블록 + Subject/Details) + 정리 워크플로우 |
| 8 | 햅틱 시퀀스 | 진행도별 generator/intensity/횟수 표 + 50% 임계 + Undo |
| 9 | 하지 말아야 할 시각 결정 | 14개 항목 박제 |
| 10 | 변경 이력 | W1-4 초기 작성 항목 |
| 11 | 참고 | brief / 토큰 폴더 / ADR-0005 / Issue #11 / W2 task 링크 |

### Step 2: iOS 토큰 코드 ✅

`ios/PillPouch/DesignSystem/Tokens/` 신규 폴더 + 3 파일:

| 파일 | 토큰 | 라인 수 |
|---|---|---|
| `Color+Tokens.swift` | `PPColor` enum + `dynamic(light:dark:)` helper. 8개 토큰 (background/surface/stroke/textPrimary/textSecondary + morning/lunch/evening). UIColor hex initializer extension. UITraitCollection 기반 라이트/다크 분기 | 30 |
| `Spacing.swift` | `PPSpacing` enum, 8pt grid: xs=4, sm=8, md=16, lg=24, xl=32, xxl=48 | 10 |
| `Typography.swift` | `PPFont` enum, 5 토큰: titleL/titleM (rounded semibold), body/caption (rounded), mono (monospaced) | 9 |

PBXFileSystemSynchronizedRootGroup 자동 등록 — pbxproj 수정 0회.

### Step 3: 빌드 검증 + Conventional Commits ✅

- `xcodebuild -scheme PillPouch -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` → **BUILD SUCCEEDED**
- 워닝 0개 (AppIntents/AppShortcuts 관련 안내 메시지는 미사용 표시 — 워닝 X)
- 토큰 3 파일 모두 정상 컴파일 + 링크

## 커밋 단위

계획서의 5 commit 안 → **3 commit** 으로 단순화 (design-system.md 11개 섹션을 한 commit으로 묶음 — split 가치 낮음):

```
82adbd5 docs: add W1-4 (#9) implementation plan
69f602c docs(design-system): expand SoT — colors, typography, spacing, pouch states, capsule prompts, haptics
3726bc1 feat(ios): add PPColor / PPSpacing / PPFont design tokens
```

Squash merge 시 main에 1 커밋. 본 보고서 commit 추가 시 4 commit → squash 1.

## 검증 (Issue #9 마감 조건)

- [x] `docs/design-system.md` — 11개 섹션 채움, stub의 "## 채울 항목" 체크리스트 제거
- [x] `ios/PillPouch/DesignSystem/Tokens/Color+Tokens.swift` — `PPColor` 8 토큰
- [x] `ios/PillPouch/DesignSystem/Tokens/Spacing.swift` — `PPSpacing` 6 토큰
- [x] `ios/PillPouch/DesignSystem/Tokens/Typography.swift` — `PPFont` 5 토큰
- [x] `xcodebuild ... build` 로컬 통과 (CI 자동 trigger 예정)
- [ ] PR squash merge → Issue #9 자동 close (PR 생성 후)

## 가설 B 체크

- ✅ 시간대 색조 + 봉지 5상태 명세 박제 = 가설 B 강화 (찢김 = 비가역적 시각 증거)
- ✅ "하지 말아야 할 시각 결정" 14개로 후속 PR 가드레일 (체크 마크/카루셀/단순 탭/의료 톤 회피)
- ✅ Non-goals 미저촉 — TCA·Carousel·단순 탭 어느 항목도 코드/문서에 추가 X
- ✅ 캡슐 자산 task #11 분리 — 본 task는 명세+프롬프트까지만, 자산은 W2 별도 사이클

## 한 의외 발견

1. **Xcode `PBXFileSystemSynchronizedRootGroup`** — Xcode 16+의 새 기능. `ios/PillPouch/` 하위에 새 폴더만 만들면 자동으로 빌드 대상 포함. pbxproj 수정 불필요. W2 봉지 컴포넌트도 같은 방식으로 추가 가능.
2. **GPT Image 2 (2026-04-21 출시)** — Midjourney와 다른 prompting 패턴 (`Style → Subject → Details → Constraints` 라벨 구조). `--style raw` 플래그 X. 본 task §7에 형식 박제했으므로 #11 진행 시 작업지시자 그대로 사용 가능.
3. **워크스페이스 A(W1-3 SwiftData 모델) 충돌 0건** — 신규 폴더 + 신규 파일 + pbxproj 미수정 → 면이 안 겹침. main rebase 시에도 conflict 없을 것으로 예상.

## 다음 (이 task 완료 후)

- **Issue #11 (W2)**: 작업지시자가 §7의 GPT Image 2 프롬프트 6개로 캡슐 SVG 생성 → Asset Catalog 등록
- **W1-5 (등록 예정)**: Today 정적 레이아웃 — 본 task의 토큰들을 첫 화면에 import
- **W2 (M) 봉지 5상태 컴포넌트**: §6 봉지 수치 + #11 캡슐 자산 + `PPColor.morning/lunch/evening` 결합한 `PouchView`
- **W2 (L) 가로 드래그**: §8 햅틱 시퀀스 + 50% 임계 + 4단계 시각 코드화 (TDD)

## 변경 이력

- 2026-04-28: 초기 작성 (PR TBD)
