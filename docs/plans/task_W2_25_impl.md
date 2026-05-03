# task_W2_25_impl.md — 단일 봉지 컴포넌트 구현계획서

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#25](https://github.com/kswift1/PillPouch/issues/25) |
| 마일스톤 | W2 |
| 크기 | L (5 stage) |
| 영역 | area:ios |
| 브랜치 | `kswift1/task25-pouch-component` |
| 수행계획서 | [`task_W2_25.md`](task_W2_25.md) |
| Supersedes | #14 (closed) |

## 목표

수행계획서 §목표 그대로. 본 문서는 stage별 파일/코드/커밋/검증을 정의.

## 공통 규칙

- 모든 색: `PPColor.*`. 종이 색은 `PPColor.surface` 기반 + opacity. 알약 색은 `Supplement.colorToken` 또는 mock hex.
- 모든 간격: `PPSpacing.*` (xs 4 / sm 8 / md 16 / lg 24 / xl 32 / xxl 48). 봉지 내부 시각 디테일(찢김 zigzag amplitude 등)은 컴포넌트 파일 내 `private enum Const` 로 고립.
- 모든 폰트: `PPFont.*`. 인쇄 띠 placeholder 텍스트는 `PPFont.caption` + `PPColor.textSecondary` opacity 0.5.
- Magic number 금지 — 모두 `private enum Const` 로.
- 폴더 등록: PBXFileSystemSynchronizedRootGroup 자동 인식. project.pbxproj 수정 X.
- 햅틱: `UIImpactFeedbackGenerator(.light)` + 임계 도달 시 `UINotificationFeedbackGenerator().notificationOccurred(.success)`.
- 60Hz 갱신: `TimelineView(.animation)` (≥ iOS 15).
- 테스트: `crates/domain` 같은 순수 도메인 레이어가 없으니 Swift Testing 으로 `PillPhysicsEngine` tick 함수만 unit test (충돌, gravity 적용, damping). 시각 컴포넌트는 스크린샷 검증으로 대체.
- 모든 enum case에 `///` doc-comment (`docs/conventions/code-style.md`).
- 테스트 메서드명: 한글 + 언더바 (`docs/conventions/code-style.md`).

---

## Stage 1 — 봉지 시각 (정적, Sealed만)

### 신규 파일

**`ios/PillPouch/Features/Pouch/PouchView.swift`**
- 퍼블릭 컴포넌트
- props: `state: PouchState` (이번 stage엔 `.sealed` 만), `pills: [PillBody]` (이번 stage엔 빈 배열)
- 내부: `ZStack` — pills 배경(빈) → `PouchPaperLayer`
- 크기 외부 주입(`.frame(width:, height:)` 호출자가 결정)

**`ios/PillPouch/Features/Pouch/PouchPaperLayer.swift`**
- 7-layer 합성 (L2~L7, L1 알약은 PouchView가 ZStack 아래에 깔음)
- 내부 함수 분리:
  - `paperBody()` → L2 RoundedRectangle + opacity 0.78
  - `fiberTexture()` → L3 Canvas — 짧은 세로 fiber 라인 ~120개 랜덤 (시드 고정으로 stable)
  - `topPrintBand()` → L4 상단 28% 영역 — placeholder 텍스트 3줄 (회색 25% opacity)
  - `wrinkleHighlight()` → L5 LinearGradient (좌상단→우하단 미세 highlight) + soft shadow
  - `heatSeal()` → L6 좌/우/하단에 dashed 1px 라인 (`StrokeStyle(lineWidth: 0.5, dash: [2, 1])`)
  - `tearMarker()` → L7 우상단에 V컷 + 미세 화살표(SF Symbol 또는 Path)

**`ios/PillPouch/Features/Pouch/PouchState.swift`**
- enum: `sealed`, `tearing(progress: Double)`, `torn`
- 각 case `///` doc-comment

**`ios/PillPouch/Features/Showcase/PouchShowcaseView.swift`**
- 골격: `NavigationStack` + 중앙에 `PouchView(state: .sealed, pills: [])` 200×280 frame
- 배경 `PPColor.background`
- 라이트/다크 둘 다 자연스럽도록 `.preferredColorScheme` 토글 미적용 (시뮬 옵션으로)

**`ios/PillPouch/ContentView.swift`** (수정)
- body → `PouchShowcaseView()` 호출

### 검증
- `cd ios && xcodebuild -scheme PillPouch -sdk iphonesimulator build` 통과
- iPhone 15 Pro 시뮬레이터 라이트/다크 스크린샷 → `docs/screenshots/pouch/sealed-light.png`, `sealed-dark.png` 커밋
- Stage 보고서 `docs/report/task_W2_25_stage1.md` 작성 → **승인 ⛔**

### 커밋
```
docs: add task #25 plan and impl
feat(ios): add PouchState enum
feat(ios): add PouchPaperLayer with 7-layer glassine composition
feat(ios): add PouchView shell + PouchShowcaseView entry
docs: add Stage 1 sealed pouch screenshots
docs: add Stage 1 report
```

---

## Stage 2 — 알약 시각 + 정적 배치

### 신규 파일

**`ios/PillPouch/Features/Pouch/Pills/PillBody.swift`**
```swift
struct PillBody: Identifiable {
    let id: UUID
    var capsuleType: CapsuleType  // 기존 enum 재사용
    var color: Color
    var position: CGPoint  // 봉지 로컬 좌표
    var velocity: CGVector  // 이번 stage엔 .zero
    let radius: CGFloat
    let mass: CGFloat
    var isFalling: Bool  // Stage 5에서 사용
}
```
- `static func mock(count:, mix:) -> [PillBody]` — Showcase 컨트롤이 호출

**`ios/PillPouch/Features/Pouch/Pills/PillView.swift`**
- props: `pill: PillBody`
- `switch pill.capsuleType` 로 Shape 분기:
  - `.capsule` — 두 톤 `Capsule` (상하 반반 색, 양 끝 highlight Ellipse)
  - `.tablet` — `Circle` + 가장자리 어두운 ring 0.5pt
  - `.softgel` — `Ellipse` + 좌상단 작은 흰 highlight
  - `.gummy` — `RoundedRectangle(cornerRadius: 6)` + opacity 0.85
  - `.powder` — 작은 `Circle` 4~6개 군집 (상대 위치 고정)
  - `.liquid` — `EmptyView` (V1 미지원, 마커만)
- 크기는 `pill.radius * 2` 기반

**`ios/PillPouch/Features/Pouch/PouchView.swift`** (수정)
- `pills` 배열을 ZStack 아래(L1)에 `ForEach { PillView($0).position($0.position) }` 로 깔기
- 종이 layer가 위에 덮이면 자동 비침 (paper opacity 0.78)

**`ios/PillPouch/Features/Showcase/PouchShowcaseView.swift`** (수정)
- `@State pillCount: Double = 3`
- `@State capsuleMix: CapsuleMix = .mixed` (`.allCapsule`, `.allTablet`, `.mixed` 등)
- 하단 컨트롤 패널: Slider(1~8) + Picker(mix) + Button("Reset")
- pills 배열은 `pillCount`/`capsuleMix` 변경 시 mock 재생성 → 봉지 내부 정적 위치(바닥에서 반지름×2 간격으로 좌→우)

### 검증
- 빌드 통과
- 알약 6종(liquid 제외 5종) 모두 표시되는 스크린샷 → `docs/screenshots/pouch/pills-mix.png`
- Stage 보고서 `docs/report/task_W2_25_stage2.md` → **승인 ⛔**

### 커밋
```
feat(ios): add PillBody model with mock factory
feat(ios): add PillView with 6 capsule type shapes
feat(ios): wire pills into PouchView ZStack
feat(ios): add Showcase controls (slider, picker, reset)
docs: add Stage 2 pill mix screenshot
docs: add Stage 2 report
```

---

## Stage 3 — 중력 모션 + 물리

### 신규 파일

**`ios/PillPouch/Features/Pouch/Motion/MotionEngine.swift`**
```swift
@Observable
final class MotionEngine {
    private(set) var gravity: SIMD2<Double> = .zero  // 화면 좌표계 (x: 우, y: 하)
    private let manager = CMMotionManager()

    func start() { /* startDeviceMotionUpdates 60Hz */ }
    func stop() { manager.stopDeviceMotionUpdates() }
}
```
- iOS device motion gravity 벡터 → SwiftUI 좌표계로 매핑 (gravity.x, -gravity.y)
- 시뮬레이터 감지: `targetEnvironment(simulator)` → `MotionEngineMock` 인스턴스 반환하는 factory

**`ios/PillPouch/Features/Pouch/Motion/MotionEngineMock.swift`**
- 같은 인터페이스
- 모드:
  - `.auto` — Timer 0.05s 마다 sin/cos 기반 천천히 회전하는 gravity (period 8s)
  - `.manual(SIMD2<Double>)` — Showcase 슬라이더가 직접 set
- Showcase에서 모드 토글 가능

**`ios/PillPouch/Features/Pouch/Pills/PillPhysicsEngine.swift`**
```swift
enum PillPhysicsEngine {
    static let G_SCALE: Double = 40   // pt/s² (실 중력 9.8m/s² × 40 ≈ 392 → 1/30 수준 '살짝')
    static let damping: Double = 0.92
    static let restitution: Double = 0.3

    static func tick(dt: TimeInterval, gravity: SIMD2<Double>, bounds: CGRect, pills: inout [PillBody]) {
        for i in pills.indices {
            // velocity update
            // position update
        }
        resolveBoundsCollision(&pills, in: bounds)
        resolvePairCollisions(&pills)
    }

    private static func resolveBoundsCollision(...) { /* RoundedRect 내부 — 단순 AABB로 근사 후 모서리는 코너 원 충돌로 별도 처리 */ }
    private static func resolvePairCollisions(...) { /* O(N²) sphere-sphere — N≤8이라 충분 */ }
}
```

**`ios/PillPouch/Features/Pouch/PouchView.swift`** (수정)
- `TimelineView(.animation)` 로 감싸서 `context.date` 변할 때마다 `PillPhysicsEngine.tick` 호출
- `dt`는 prev frame 시각과의 차이
- bounds = 봉지 내부 영역 (인쇄 띠 아래 ~ 바닥, 좌우 패딩 considered)
- pills를 `@State`로 보유 → Showcase에서 reset 시 새 mock으로 교체

**`ios/PillPouch/Features/Showcase/PouchShowcaseView.swift`** (수정)
- `@State motionMode: MotionMode = .auto` 토글 (Picker)
- `.manual` 선택 시 gravity X/Y 슬라이더 2개 (-1.0 ~ +1.0)
- `.task { engine.start() } .onDisappear { engine.stop() }`

### 신규 테스트

**`ios/PillPouchTests/PillPhysicsEngineTests.swift`**
- `@Test func 중력_적용_후_velocity_가_증가한다()` — gravity (0,1), dt 0.016 → velocity.dy 양수
- `@Test func damping_으로_velocity_가_감소한다()` — gravity 0, 초기 velocity 100 → 1초 후 < 50
- `@Test func 바닥_충돌_시_velocity_y_가_반전된다()` — pill을 바닥에 두고 속도 +y → 충돌 후 -y * restitution
- `@Test func 두_알약이_겹치면_서로_밀어낸다()` — 같은 위치 2개 → tick 후 거리 ≥ 반지름 합

### 검증
- 빌드 + `cd ios && xcodebuild test -scheme PillPouch -destination 'platform=iOS Simulator,name=iPhone 15 Pro'` 통과
- 시뮬레이터에서 motion mock auto 모드로 알약 흔들리는 스크린레코딩 → `docs/screenshots/pouch/motion.mov`
- 작업지시자 실 기기 검증 (별도)
- Stage 보고서 `docs/report/task_W2_25_stage3.md` → **승인 ⛔**

### 커밋
```
feat(ios): add MotionEngine wrapping CMMotionManager
feat(ios): add MotionEngineMock with auto + manual modes
feat(ios): add PillPhysicsEngine with gravity, damping, collisions
test(ios): cover PillPhysicsEngine tick semantics
feat(ios): wire physics tick into PouchView TimelineView
feat(ios): add motion mode toggle and gravity sliders to Showcase
docs: add Stage 3 motion screenrecording
docs: add Stage 3 report
```

---

## Stage 4 — 찢기 UX (Sealed↔Torn 전환만)

### 신규 파일

**`ios/PillPouch/Features/Pouch/PouchTearLayer.swift`**
- props: `progress: Double` (0~1), `width: CGFloat`
- `progress > 0` 일 때 보임:
  - 0~30% — 종이 윗부분이 살짝 위로 말림 (top edge 12pt까지 offset + slight rotation)
  - 30~70% — `Path` 로 지그재그 가로 라인 (`amplitude 3pt, frequency progress * width / 6`). progress에 따라 좌→우 길이 증가.
  - 70~100% — 윗 조각이 거의 분리, 조금 매달려 있음 (8° 기울어짐)
- 종이 결 노이즈는 시드 고정으로 매 진행도에서 stable

**`ios/PillPouch/Features/Pouch/PouchTearGesture.swift`**
- `DragGesture` viewModifier
- 시작점이 봉지 상단 ±20pt 안쪽일 때만 `state` → `.tearing(progress)` 갱신
- 햅틱:
  - 매 진행도 10% 도달 시 `UIImpactFeedbackGenerator(.light).impactOccurred()`
  - 100% 도달 시 `UINotificationFeedbackGenerator().notificationOccurred(.success)` + `state = .torn`
- 릴리즈 시:
  - progress ≥ 50% → `.torn` snap (`withAnimation(.spring(response: 0.3, dampingFraction: 0.7))`)
  - progress < 50% → `.sealed` snap

**`ios/PillPouch/Features/Pouch/PouchState.swift`** (수정 X — enum 그대로 사용)

**`ios/PillPouch/Features/Pouch/PouchView.swift`** (수정)
- `state` 가 `.tearing` / `.torn` 이면 `PouchTearLayer` 위에 합성
- `.gesture(PouchTearGesture(...))` 부착
- `.torn` 상태에서 알약은 그대로 봉지 안에 머무름 (Stage 5에서 낙하 추가)

**`ios/PillPouch/Features/Showcase/PouchShowcaseView.swift`** (수정)
- "Force Tear" / "Reset to Sealed" 디버그 버튼 추가

### 검증
- 빌드 통과
- 시뮬레이터에서 드래그로 찢기 진행 스크린샷 (~50% 시점) → `docs/screenshots/pouch/tearing.png`
- Torn 정착 라이트/다크 스크린샷 → `docs/screenshots/pouch/torn-light.png`, `torn-dark.png`
- Stage 보고서 `docs/report/task_W2_25_stage4.md` → **승인 ⛔**

### 커밋
```
feat(ios): add PouchTearLayer with progressive jagged path
feat(ios): add PouchTearGesture with thresholds and haptics
feat(ios): wire tear state machine into PouchView
feat(ios): add force-tear debug button to Showcase
docs: add Stage 4 tearing and torn screenshots
docs: add Stage 4 report
```

---

## Stage 5 — 알약 낙하 애니메이션

### 수정 파일

**`ios/PillPouch/Features/Pouch/Pills/PillBody.swift`** — `isFalling` 플래그 활용 시작

**`ios/PillPouch/Features/Pouch/Pills/PillPhysicsEngine.swift`** (수정)
- tick 함수: `if pill.isFalling`:
  - bounds 충돌 비활성 (또는 우상단 찢김 구멍을 통과 가능하게)
  - gravity 강제 (0, +1) overlay (실제 화면 중력 X — 자연 낙하 느낌)
  - position.y > screenHeight + radius * 2 → pills 배열에서 제거
- 새 함수 `markAllFalling(initialPunch:)` — torn 시 모든 알약에 `isFalling = true` + 초기 velocity (-50~+50 random x, +200 y) 부여

**`ios/PillPouch/Features/Pouch/PouchView.swift`** (수정)
- `state` 가 `.torn` 으로 전환되는 순간 (`.onChange(of: state)`) `PillPhysicsEngine.markAllFalling(&pills)` 호출
- 낙하 알약은 `.opacity(falling ? max(0, 1 - distance_below_pouch/200) : 1)` 로 페이드
- 낙하 알약은 봉지 layer 위에 그려야 자연스러움 (z-index 변경) — `pill.isFalling ? layer = above paper : below paper`

**`ios/PillPouch/Features/Showcase/PouchShowcaseView.swift`** (수정)
- "Reset" 버튼이 pills 재생성 + state `.sealed` 복원 모두 수행
- 낙하 진행 중 Reset 시 즉시 새 봉지 + 새 알약

### 신규 테스트

**`ios/PillPouchTests/PillPhysicsEngineTests.swift`** (확장)
- `@Test func 낙하_시작_시_모든_알약에_isFalling_플래그가_세팅된다()`
- `@Test func 낙하_중인_알약은_바닥_충돌을_무시한다()`
- `@Test func 화면_밖으로_나간_알약은_제거된다()`

### 검증
- 빌드 + 테스트 통과
- 찢기 → 낙하 → 화면 밖으로 사라지는 시퀀스 스크린레코딩 → `docs/screenshots/pouch/falling.mov`
- Stage 보고서 `docs/report/task_W2_25_stage5.md` → **승인 ⛔**

### 커밋
```
feat(ios): extend PillPhysicsEngine with falling state
test(ios): cover falling state and removal
feat(ios): trigger fall on torn transition with z-index swap
feat(ios): unify Showcase Reset to fully reset pouch and pills
docs: add Stage 5 falling sequence recording
docs: add Stage 5 report
```

---

## 최종 통합

### 정리
- 모든 스크린샷/영상이 `docs/screenshots/pouch/` 하에 정렬되어 있는지 확인
- Showcase에서 전체 시나리오(생성 → 흔들림 → 찢기 → 낙하 → Reset) 1회 풀 재생 영상 추가 → `docs/screenshots/pouch/full-demo.mov`
- README 또는 `docs/screenshots/pouch/README.md` 추가 — 각 영상/스크린샷 목적 1줄 설명
- ContentView가 PouchShowcaseView로 잘 연결돼 있는지 최종 빌드/실행 확인

### 보고서
**`docs/report/task_W2_25_report.md`** 작성 → **승인 ⛔**
- 5개 stage 보고서 링크
- 가설 B 강화 evidence (스크린샷)
- 비목표 미진입 확인
- 다음 task 추천 (#11 캡슐 자산, Today 화면, 5상태 일반화)

### PR
- 본문: 가설 B 체크 + 비목표 체크 + 수행계획서/구현계획서/5개 stage 보고서/최종 보고서 링크
- Squash merge → Issue #25 자동 close

### 최종 커밋
```
docs: add Stage 5 falling sequence recording
docs: add Stage 5 report
docs: add full demo recording and screenshots index
docs: add task #25 final report
```

---

## 위험 요소 (구현계획서 수준)

1. **Canvas fiber 텍스처 노이즈가 매 프레임 재생성되면 깜빡임** — 시드 고정 + `drawingGroup()` 또는 `drawing(.image)` 으로 캐싱.
2. **TimelineView + Canvas 조합에서 dt 계산 정확도** — `context.date.timeIntervalSince(prevDate)` 사용. prev는 `@State`.
3. **알약 간 충돌 O(N²) — N≤8이라 무시 가능. 그래도 broadphase 없이 매 tick 모든 쌍 검사** — 의도적 단순화. 명시.
4. **RoundedRect 내부 충돌의 코너 처리** — 코너에서 알약이 끼는 현상. 단순화: 코너 반지름 영역에서는 코너 중심으로부터의 거리 기반 충돌. Stage 3 보고서에서 시각 검토.
5. **드래그 시작점 hit-test 영역이 너무 좁음** — 봉지 상단 ±20pt 안에서만 시작 인식. 사용자가 헤맬 가능성. Stage 4 보고서에서 작업지시자 실기기 검증 후 조정 가능.
6. **Torn 후 z-index 변경 시 깜빡임** — pills 배열을 falling/notFalling으로 분리해서 ZStack 두 군데에 그리기. 단일 array 내 z-index 토글보다 안전.
7. **낙하 알약이 봉지 V컷 구멍에서 자연스럽게 빠지는 시각** — 봉지 우상단 V컷 위치 기억해두고 그 영역만 통과 가능하게 bounds 예외 처리. 안 하면 알약이 봉지 옆/아래로 빠지는 부자연스러움. Stage 5 보고서 핵심 검토 포인트.
8. **PBXFileSystemSynchronizedRootGroup 인식 실패** — 빌드 깨지면 `docs/troubleshootings/` 박제 후 작업지시자 에스컬레이션. 우회 X.

## 검증 (Issue #25 Done 조건 종합)

- [ ] 5 stage 보고서 모두 작성 + 승인
- [ ] xcodebuild build 통과
- [ ] xcodebuild test 통과 (PillPhysicsEngine 7+ 테스트)
- [ ] 7개 시각 산출물 커밋:
  - sealed-light.png, sealed-dark.png
  - pills-mix.png
  - motion.mov
  - tearing.png, torn-light.png, torn-dark.png
  - falling.mov
  - full-demo.mov
- [ ] PR 본문 가설 B/비목표 체크 + 모든 문서 링크
- [ ] PR squash merge 후 Issue #25 자동 close

## 다음 (이 task 완료 후)

- 후속 우선순위 (W2):
  1. **#11 캡슐 자산** — 본 task의 `PillView` 내부 Shape을 디자이너 일러스트로 교체
  2. **Today 화면 task (신규 이슈)** — 본 컴포넌트 3개를 절취선으로 연결
  3. **봉지 5상태 일반화** — Skipped(점선), Missed(반투명), NOW 강조
- 후속 (W3+): Live Activity / Widget — 본 컴포넌트의 ActivityKit 환경 호환성 검증
