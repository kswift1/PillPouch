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

---

# 추가: Polish — Lift redesign / Jagged mask / Progress hold / Gap 제거

## 트리거

작업지시자 시뮬 검증 4 사이클 — 원래 zigzag 만 그어진 시각이 약했고 이후
실 약봉지 톤까지 보강. 최종적으로 lift 단일 모드만 남김.

## 변경 (4 사이클)

### 1) Lift / Gap 두 스타일 비교 (commit `93b937c`)

기존 single-line zigzag 가 약함. 두 가지 시각 비교용으로 추가:
- `TearStyle.lift`: 봉지 위쪽 조각 mask + transform (PaperLayer 복제본 위쪽만 잘라 transform)
- `TearStyle.gap`: perforation 라인에 어두운 rect 가 좌→우 점진적 확대
- ShowcaseView Picker (segmented) 토글

### 2) Approach A 채택: PaperLayer 자체 분리 (commit `0c7722e`)

작업지시자 결정 — Approach B (PaperLayer 복제본) 는 본체와 복제본이 이중
그리기로 들린 자리에 본체 위쪽이 그대로 보임 → 진정한 분리 X.

A 적용:
- `PouchPaperTop` / `PouchPaperBottom` wrapper view 신규
- 각자 PaperLayer 그리고 horizontal Rectangle mask 로 위/아래만 노출
- PouchView: lift 모드 → PaperBottom + PaperTop(transform) 두 조각.
  gap 모드 → 단일 PaperLayer.
- 위쪽 transform: progress * 8pt offset + progress * 6° rotation + 0~0.20 shadow
- PouchTearLayer.liftView 단순화 (본체 측 jagged edge 만)

이제 위쪽 조각이 들리면 그 자리에 알약 영역 노출 — 진짜 분리감.

### 3) Jagged mask + interlocking 단면 (commit `a5423c6`)

기존 mask 가 직선 + 위에 zigzag stroke 만. "찢어졌다" 가 시각으로 안 와닿음
+ 위/아래 단면 mismatch.

해결:
- `JaggedTearPath` Shape — seeded RNG 기반 무작위 jagged path
  - `periodJitter 0.6~1.4` + `ampJitter 0.35~1.30` + alternating direction
  - progress 비율만큼 좌→우 진행, 나머지는 perforation Y 직선
  - `region: .top/.bottom` 으로 위/아래 mask 영역 결정
- `JaggedRNG` (xorshift) — deterministic, 매 frame 같은 path → flicker X
- `PouchPaperSplit.tearSeed` 공유 — PaperTop/Bottom 동일 seed → 단면 정확히 맞물림
- PaperTop/Bottom 의 mask 를 horizontal Rectangle → JaggedTearPath 로 교체
- PouchTearLayer.liftView 빈 view (mask 가 시각 표현)

### 4) Progress hold + resume (commit `9e97309`)

50% 임계 snap 이 어색 — 30% drag 후 손 떼면 0% 로 점프 (확 줄어듦) 또는
50% 넘으면 100% 로 점프 (확 찢김).

해결:
- 50% 임계 폐기. snap-back / auto-torn 제거.
- `dragBaseProgress` State 추가 — 새 drag 의 시작 progress base
- `handleTearChanged`: `progress = clamp(dragBaseProgress + dragDelta)`.
  100% 도달 시에만 자동 .torn (success haptic + spring)
- `handleTearEnded`: 진행도 유지, dragBaseProgress 만 갱신 (다음 drag 의 base)
- `onChange(of: state)`: 외부 .sealed/.torn 변경 (Showcase 버튼) 시 base 동기화.
  drag 중 .tearing 갱신은 자기 자신이라 무시.

이제 30% 까지 찢고 손 떼면 30% 유지, 다시 drag 하면 30% 부터 이어짐.

### 5) Gap 제거 (commit `2edee29`)

작업지시자 결정 — lift 단일 모드만 채택.

- TearStyle enum, .gap case, gapView, ZigZagEdge Shape 제거
- PouchTearLayer view 자체 제거 (mask 가 시각 표현 — view 불필요)
- PouchTearLayer.swift 는 JaggedTearPath + JaggedRNG 만 보유
- PouchView: tearStyle props 제거, paperLayerStack 단순화 (항상 PaperBottom + PaperTop transform)
- ShowcaseView: tearStyle State + Picker 제거

3 files / 10 insertions / **169 deletions**.

## 검증

```
xcodebuild -scheme PillPouch -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4' build
** BUILD SUCCEEDED **
```

기존 PillPhysicsEngine 25/25 테스트 그대로 통과. Stage 4 신규 unit test 없음
(gesture / mask 시각은 UI 영역).

## 의사결정 박제

| 결정 | 값 | 이유 |
|---|---|---|
| Approach A (PaperLayer 분리) | 채택 | B 의 이중 그리기로 들린 자리에 본체 보임 — 진정한 분리 X |
| `wallContactEpsilon` 같은 mask path | seeded 동일 jagged | 위/아래 단면 정확히 맞물림 |
| `tearSeed` `0xC0FFEE_BEEF` | fixed | 매 봉지 동일 jagged. 봉지마다 다른 패턴 원하면 supplement.id 기반 변경 가능 |
| Jagged `basePeriod 6` / `baseAmp 3.5` | 현재 폭/높이 | 너무 세밀하면 노이즈, 너무 크면 만화 |
| `periodJitter 0.6~1.4` / `ampJitter 0.35~1.30` | 무작위 강도 | 좁히면 규칙적, 넓히면 들쭉날쭉 |
| 50% snap 폐기 | progress hold | drag 끝나도 진행도 유지 — 사용자 의도와 정합 |
| 100% 자동 .torn + success haptic | drag 중 trigger | 명시적 완료 — sealed 로 가는 건 봉합 버튼 (또는 Today 의 toast 등) |
| Gap 제거 | lift 단일 | 비교 결과 lift 채택 — 코드 단순화 |

## 누적 커밋 (Stage 4 전체)

```
5fd0201 feat(ios): add PouchTearLayer with progressive zigzag along perforation (#25 stage4)
f052f75 feat(ios): wire tear DragGesture into PouchView with 50% threshold and haptics (#25 stage4)
8cbf75f feat(ios): add tear/seal debug buttons to Showcase (#25 stage4)
c1e2184 docs: add Stage 4 report (#25 stage4)
93b937c feat(ios): add Lift/Gap tear styles for visual comparison (#25 stage4 redesign)
0c7722e refactor(ios): split PaperLayer into top/bottom for true tear separation (#25 stage4 approach A)
a5423c6 feat(ios): replace regular zigzag with seeded random jagged tear edge (#25 stage4 jagged mask)
9e97309 feat(ios): keep tear progress on drag end and resume from where left off (#25 stage4 progress hold)
2edee29 refactor(ios): remove gap tear style and PouchTearLayer view (#25 stage4 cleanup)
```

## 승인 ⛔ (재) — Stage 4 최종
