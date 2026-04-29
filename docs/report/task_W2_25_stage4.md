# task_W2_25_stage4.md — Stage 4 보고서: 찢기 UX (Sealed↔Torn)

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#25](https://github.com/kswift1/PillPouch/issues/25) |
| 마일스톤 | W2 |
| 크기 | L — Stage 4/5 |
| 브랜치 | `kswift1/task25-pouch-component` |
| 수행계획서 | [`task_W2_25.md`](../plans/task_W2_25.md) |
| 구현계획서 | [`task_W2_25_impl.md`](../plans/task_W2_25_impl.md) |
| Stage 1 보고서 | [`task_W2_25_stage1.md`](task_W2_25_stage1.md) |
| Stage 2 보고서 | [`task_W2_25_stage2.md`](task_W2_25_stage2.md) |
| Stage 3 보고서 | [`task_W2_25_stage3.md`](task_W2_25_stage3.md) |
| ADR | [`0009-tear-gesture-middle-perforation.md`](../adr/0009-tear-gesture-middle-perforation.md) |

## 산출물

### 신규 파일

| 파일 | 역할 |
|---|---|
| `ios/PillPouch/Features/Pouch/PouchTearLayer.swift` | 찢김 시각 — perforation Y 라인 따라 좌→우 zigzag path. `PouchState` 따라 progress 비율만큼 노출 |

### 수정 파일

| 파일 | 변경 |
|---|---|
| `ios/PillPouch/Features/Pouch/PouchView.swift` | `state: PouchState` → `@Binding var state`. DragGesture + 50% 임계 + 햅틱 누적. `PouchTearLayer` ZStack 합성. `static func perforationY(in:)` 신규 |
| `ios/PillPouch/Features/Showcase/PouchShowcaseView.swift` | `pouchState: PouchState` State + 디버그 버튼 ("찢기" / "봉합") + tear 상태 라벨 + Reset 시 `.sealed` 복귀 |

## 인터랙션 사양

### Tear gesture (DragGesture)

| 항목 | 값 |
|---|---|
| 시작점 hit-test | `abs(startLocation.y - perforationY) <= 20pt` |
| Progress 계산 | `translation.width / (width - tearMargin*2)` (clamped 0~1) |
| Tear margin | 16pt 좌우 inset (PaperLayer 점선 inset 과 동일) |
| 임계 | 50% — 이상 릴리즈 시 `.torn`, 미만이면 `.sealed` snap back |
| Spring | response 0.32, dampingFraction 0.74 (torn) / 0.78 (sealed) |

### 햅틱 (PouchHapticDriver — Stage 3 충돌 햅틱과 통합)

| 이벤트 | API | Intensity |
|---|---|---|
| Tear 진행도 매 10% step | `UIImpactFeedbackGenerator(.light)` | 0.55 |
| 50% 임계 통과 → `.torn` | `UINotificationFeedbackGenerator().notificationOccurred(.success)` | 시스템 |
| 알약 충돌 (Stage 3) | `UIImpactFeedbackGenerator(.light)` intensity-based | 0.25~0.65 (StepResult.hapticIntensity 매핑) |

세 시스템 동시 작동 — OS 큐가 처리. Stage 3 결정 (옵션 A — 그대로 양쪽 작동) 유지.

### 시각 단계

| 진행도 | 시각 |
|---|---|
| `.sealed` (0%) | PaperLayer 의 dashed 점선만 |
| `.tearing(progress)` | dashed line 위에 jagged zigzag path 가 좌→우 progress 비율만큼 노출 (amplitude 3pt, half-period 6pt) |
| `.torn` (100%) | zigzag full + perforation 위쪽에 옅은 cut-edge shade overlay (light 0.06 / dark 0.30, blendMode `.multiply`) |

알약 거동: `.torn` 상태에서도 봉지 안에 그대로 머무름 (Stage 5 에서 낙하 추가).

## 코드 핵심

### PouchView.tearGesture

```swift
DragGesture(minimumDistance: 4)
    .onChanged { value in
        guard abs(value.startLocation.y - perforationY) <= 20 else { return }
        if case .torn = state { return }  // 이미 찢김 — 무시
        let progress = clamp(value.translation.width / (width - 32))
        // 매 10% step 도달 → light haptic
        let step = Int(progress * 10)
        if step > lastTearHapticStep {
            haptics.playTearStep()
            lastTearHapticStep = step
        }
        state = .tearing(progress: progress)
    }
    .onEnded { value in
        let progress = ...
        if progress >= 0.5 {
            haptics.playTearSuccess()
            withAnimation(.spring()) { state = .torn }
        } else {
            withAnimation(.spring()) { state = .sealed }
        }
        lastTearHapticStep = 0
    }
```

### PouchTearLayer.ZigZagTear

`Shape` + `animatableData: Double` (progress) — SwiftUI 가 progress 변화를 자동 보간. `withAnimation(.spring())` 으로 sealed↔torn 전이 시 path 길이가 자연스럽게 변함.

```swift
private struct ZigZagTear: Shape {
    var progress: Double
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    func path(in rect: CGRect) -> Path {
        let endX = inset + (rect.width - inset*2) * progress
        // 좌→우 amp 3pt, halfPeriod 6pt zigzag, x < endX 까지만
    }
}
```

### Showcase 디버그

- "찢기" 버튼 → `withAnimation { pouchState = .torn }` (애니메이션 path 진행)
- "봉합" 버튼 → `withAnimation { pouchState = .sealed }`
- "Tear: sealed/tearing 30%/torn" 라벨로 상태 가시화

## 검증

### 빌드

```
xcodebuild -scheme PillPouch -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4' build
** BUILD SUCCEEDED **
```

### 테스트

`PillPhysicsEngineTests` 25/25 그대로 통과 (gesture 로직은 SwiftUI ViewModifier — UI 테스트 별도). 이번 stage 신규 unit test 없음.

## 위험 / 박제

| 항목 | 상태 |
|---|---|
| **#5 드래그 hit-test 영역** | perforation Y ±20pt — 작업지시자 실 기기 검증 후 조정 |
| **알약 거동** | `.torn` 에서도 안에 머무름 — Stage 5 에서 낙하 |
| **Magic number 중복** | `perforationY` 식이 PouchView 와 PouchPaperLayer 양쪽에 hardcode (14+38+36). 다음 stage 에서 `PouchGeometry` namespace 로 통일 가능 |
| **gesture vs scroll** | DragGesture(minimumDistance: 4) — Today 탭/스크롤 안에 들어가도 minimumDistance 가 작아 conflict 가능. Today 통합 시 `simultaneousGesture` 또는 `.exclusively` 결정 필요 |

## 의사결정 박제

| 결정 | 값 | 이유 |
|---|---|---|
| Hit-test 시작점 ±20pt | 작은 영역 | perforation 라인 명확. 너무 크면 헤더/알약 영역 드래그도 trigger |
| 임계 50% | 사용자가 "절반 넘기면 찢기 확정" 직관 | 30% 면 너무 쉽게 찢김, 70% 면 부담 |
| Spring response 0.32 | 빠른 snap | 0.5+ 면 살짝 늘어지는 느낌 |
| Tear haptic step 10% | 진행감 5~7번 | 5% 면 너무 잦음, 20% 면 부족 |
| `.success` notification | 완료 시 강한 단발 | impact 만 쓰면 "딱" 약함 |
| `lastTearHapticStep` reset on drag end | 다음 drag 새로 시작 | 안 reset 하면 두 번째 시도부터 햅틱 누락 |

## 커밋

```
feat(ios): add PouchTearLayer with progressive zigzag along perforation (#25 stage4)
feat(ios): wire tear DragGesture into PouchView with 50% threshold and haptics (#25 stage4)
feat(ios): add tear/seal debug buttons to Showcase (#25 stage4)
docs: add Stage 4 report
```

## 다음

작업지시자 검토 후 **Stage 5 (알약 낙하 애니메이션)** 진입.
- `.torn` 상태에서 perforation 라인을 통해 알약이 봉지 밖으로 떨어지는 애니메이션
- z-index swap (낙하 시 paper 뒤 → 앞으로)
- 봉지 위 조각이 살짝 매달려 흔들리는 효과 (선택)

## 승인 ⛔
