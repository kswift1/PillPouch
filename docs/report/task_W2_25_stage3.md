# task_W2_25_stage3.md — Stage 3 보고서: 중력 모션 + 물리

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#25](https://github.com/kswift1/PillPouch/issues/25) |
| 마일스톤 | W2 |
| 크기 | L — Stage 3/5 |
| 브랜치 | `kswift1/task25-pouch-component` |
| 수행계획서 | [`task_W2_25.md`](../plans/task_W2_25.md) |
| 구현계획서 | [`task_W2_25_impl.md`](../plans/task_W2_25_impl.md) |
| Stage 1 보고서 | [`task_W2_25_stage1.md`](task_W2_25_stage1.md) |
| Stage 2 보고서 | [`task_W2_25_stage2.md`](task_W2_25_stage2.md) |

## 산출물

### 신규 파일

| 파일 | 역할 |
|---|---|
| `ios/PillPouch/Features/Pouch/Motion/MotionEngine.swift` | `MotionEngineProtocol` + `RealMotionEngine`(CMMotionManager) + `MotionEngineMock`(auto/manual) + `MotionEngineFactory` |
| `ios/PillPouch/Features/Pouch/Pills/PillPhysicsEngine.swift` | 순수 함수형 2D 물리 — gravity / damping / bounds / pair collision |
| `ios/PillPouchTests/PillPhysicsEngineTests.swift` | 16 unit tests (5 suite) — gravity/damping/integration/bounds/pair |

### 수정 파일

| 파일 | 변경 |
|---|---|
| `ios/PillPouch/Features/Pouch/Pills/PillBody.swift` | `velocity: CGVector` 필드 추가 (default `.zero`), default radius 22 |
| `ios/PillPouch/Features/Pouch/PouchView.swift` | `gravity: SIMD2<Double>` props 추가. `TimelineView(.animation)` 60Hz tick + `advancePhysics(to:bounds:)` + `lastTickDate` (백그라운드 복귀 시 dt 점프 방지). |
| `ios/PillPouch/Features/Showcase/PouchShowcaseView.swift` | `MotionEngineFactory.make()` 로 엔진 생성 (시뮬→Mock, 실기기→Real), motion 모드 Picker (Auto/Manual), manual gravity X/Y 슬라이더 (-1~1), `onAppear`/`onDisappear` start/stop |

## MotionEngine 사양

### Protocol

```swift
protocol MotionEngineProtocol: AnyObject {
    var gravity: SIMD2<Double> { get }   // 화면 좌표계 (x: 우, y: 하)
    func start()
    func stop()
}
```

### RealMotionEngine

- `CMMotionManager.startDeviceMotionUpdates(to: .main)`
- 60Hz update interval (`1.0 / 60.0`)
- 좌표 매핑: `CMMotionManager` (x:우, y:위) → SwiftUI (x:우, y:아래) — `y` 부호 반전
- `isDeviceMotionActive` 가드로 stop 안전화

### MotionEngineMock

두 모드:
- **`.auto`**: 8초 주기로 천천히 회전. `gravity = (sin(t)*0.7, cos(t)*0.7 + 0.3)` — 기본 아래 방향 + 좌우 흔들림
- **`.manual`**: 외부(ShowcaseView 슬라이더)가 `manualGravity` 직접 set
- Timer 30Hz tick (gravity 자체가 천천히 변하므로 30Hz 충분, 절감 의도)

### Factory

```swift
#if targetEnvironment(simulator)
return MotionEngineMock()
#else
return RealMotionEngine()
#endif
```

시뮬레이터에서 자동 mock, 실 기기에서 실제 CMMotionManager.

## PillPhysicsEngine 사양

순수 함수형 — 외부 상태 X. `tick(dt:gravity:bounds:pills:)` 호출당 한 프레임 전진.

### 상수 (`enum Const` 동등 표기)

| 상수 | 값 | 의미 |
|---|---|---|
| `gScale` | 40 (pt/s²) | 중력 가속도 스케일. 실 중력의 ~1/30 — "살짝" 흔들림 |
| `damping` | 0.92 | 매 tick velocity 감쇠 비율. 1초당 `0.92^60 ≈ 0.007` → 정지 |
| `restitution` | 0.3 | 벽 충돌 시 반사 계수. 0=정지, 1=완전 탄성 |
| `pairSeparation` | 0.5 | 알약 간 충돌 시 push-apart 비율 |

### tick 알고리즘

```
for each pill:
  1. velocity += gravity * gScale * dt        // 중력 가속도 누적
  2. velocity *= damping                      // 마찰
  3. position += velocity * dt                // integration
resolveBoundsCollision(&pills, in: bounds)    // 4면 AABB
resolvePairCollisions(&pills)                 // O(N²) sphere-sphere
```

### 충돌 처리

- **Bounds**: 4면 AABB. 침범 시 안쪽으로 클램프 + velocity 부호 반전 × restitution. 충돌 반지름은 `radius * 0.5` (자산 frame 안에서 알약이 차지하는 비율 보정)
- **Pair**: 거리 < `(r1 + r2) * 0.5` 이면 양쪽으로 `pairSeparation × overlap` 만큼 push apart. dist == 0 가드 (NaN 방지)

### Terminal velocity

`gScale=40`, `damping=0.92`, `dt=1/60` 조합:
- 매 tick: `v_new = (v + 40/60) * 0.92`
- steady state: `v = 0.92 * (v + 0.667)` → `v_terminal ≈ 7.67 pt/s`
- "살짝" 의도라 1초 안에 바닥 도달 X. 30초 시뮬에서 정착 (테스트로 검증)

## PouchView 통합

### TimelineView + advancePhysics

```swift
TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
    ZStack { ... }
    .onChange(of: context.date) { _, newDate in
        advancePhysics(to: newDate, bounds: bounds)
    }
}

private func advancePhysics(to newDate: Date, bounds: CGRect) {
    let prev = lastTickDate ?? newDate
    let dt = min(newDate.timeIntervalSince(prev), 1.0 / 30.0)  // 백그라운드 복귀 점프 방지
    lastTickDate = newDate
    guard dt > 0 else { return }
    PillPhysicsEngine.tick(dt: dt, gravity: gravity, bounds: bounds, pills: &pills)
}
```

핵심: `dt` 상한 `1/30` — 앱이 백그라운드 갔다가 돌아왔을 때 `context.date` 가 큰 폭으로 점프하면 알약이 화면 밖으로 튀는 현상 방지.

### gravity props

`gravity: SIMD2<Double>` — Showcase가 MotionEngine.gravity를 직접 props로 주입. PouchView는 motion 소스 추상화 — Today/Live Activity 등에서도 다른 source 가능.

## Showcase 통합

### 모드 전환 흐름

1. 시뮬레이터에서 `MotionEngineFactory.make()` → `MotionEngineMock` 인스턴스
2. `motionEngine is MotionEngineMock` 일 때만 motion controls 표시
3. Auto/Manual segmented Picker 토글
4. Manual 모드면 X/Y 슬라이더 표시 (-1~1)
5. 슬라이더 값 변경 → `mock.manualGravity = SIMD2(x, y)` 직접 set

### 라이프사이클

- `.onAppear`: `regeneratePills() + motionEngine.start()`
- `.onDisappear`: `motionEngine.stop()` (배터리 절감)

## 검증

### 빌드

```
xcodebuild -scheme PillPouch -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4' build
** BUILD SUCCEEDED **
```

### 테스트 (Swift Testing, 16/16 통과)

| Suite | 케이스 |
|---|---|
| `PillPhysicsEngineGravityTests` | 중력 누적, x/y 분리 누적, dt=0 가드, 빈 배열 안전 |
| `PillPhysicsEngineDampingTests` | 매 tick 0.92 비율 감소, 60틱 후 사실상 정지 |
| `PillPhysicsEngineIntegrationTests` | velocity → position 통합 정확 |
| `PillPhysicsEngineBoundsCollisionTests` | 좌/우/상/하 4면 충돌 + 반사 + 안전 영역 + 30초 시뮬 정착 |
| `PillPhysicsEnginePairCollisionTests` | 겹침 시 분리, 멀면 변화 X, 단일 안전, dist=0 NaN 가드 |

```
xcodebuild test -scheme PillPouch -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4' \
  -only-testing:PillPouchTests/PillPhysicsEngine{Gravity,Damping,Integration,BoundsCollision,PairCollision}Tests
** TEST SUCCEEDED ** (16/16)
```

### 스크린샷

| 파일 | 설명 |
|---|---|
| `motion-t0.png` | 시작 시점 — 알약 5개 봉지 바닥 정착 (Stage 2 정적 배치 그대로 시작) |
| `motion-t3.png` | 3초 시점 — Mock auto 모드 흔들림으로 알약 자연 흩어짐 |
| `motion-t6.png` | 6초 시점 — gravity 회전 따라 알약 위치 재정렬 |

## 시각/동작 평가

| 항목 | 결과 |
|---|---|
| 60Hz tick | ✅ TimelineView(.animation) 부드러움 |
| 백그라운드 복귀 안정성 | ✅ dt 상한 1/30 가드 동작 |
| Mock auto 모드 자연스러움 | ✅ 8초 주기 회전 — 알약이 천천히 한쪽 → 반대쪽 |
| Manual 모드 직접 제어 | ✅ X/Y 슬라이더 즉각 반영 |
| 알약 정착 거동 | ✅ damping으로 정지 시 부드럽게 멈춤 |
| 알약 간 겹침 | ✅ pair collision으로 자연 분리 |
| 봉지 외부 이탈 | ✅ bounds collision 으로 차단 |
| 시뮬→실기기 자동 분기 | ✅ Factory `#if targetEnvironment(simulator)` |

## 위험 진행 상황

| 위험 (impl §위험) | 상태 |
|---|---|
| #5 dt 점프 (백그라운드 복귀) | dt 상한 `1/30` 가드로 차단 ✅ |
| #6 gScale 너무 강하/약함 | 40으로 설정 시 terminal velocity 8pt/s — "살짝" 의도 정합 ✅. 실 기기 검증 후 미세 조정 가능 |
| #7 60Hz tick 성능 | 알약 ≤ 8개 + bounds/pair O(N²) 무시 가능 ✅ |
| #8 시뮬레이터 motion 미지원 | `MotionEngineMock` factory 자동 분기 ✅ |

## 의사결정 박제

| 결정 | 값 | 이유 |
|---|---|---|
| Engine 분리 vs 합침 | `MotionEngine.swift` 단일 파일에 protocol + Real + Mock + Factory | 작은 파일 4개로 쪼개는 것보다 응집도 높음. 외부에서는 `MotionEngineProtocol`만 의존 |
| Mock tick rate | 30Hz | gravity 자체가 천천히 변하므로 60Hz 불필요. 절감 |
| `dt` 상한 | `1/30` | 백그라운드 복귀 시 점프 방지. 30Hz 이하로 떨어진 프레임도 자연스럽게 처리 |
| pair collision 분리 비율 | 0.5 (한쪽씩) | 1.0이면 한 번에 분리 — 부자연. 0.5로 매 tick 절반씩 천천히 분리 |
| 충돌 반지름 | `radius * 0.5` | PillView 자산이 frame 안에서 ~50% 차지 — 시각적 충돌 시점과 일치 |

## 코멘트 / 작업지시자 검토 포인트

1. **gScale 튜닝** — 실 기기에서 "살짝" 흔들림이 너무 약한지/강한지 직접 확인. 40 → 25~50 범위 미세 조정 가능. 코드 변경 1줄.
2. **damping 튜닝** — 0.92 → 0.95 (덜 감쇠, 더 자유로운 흔들림) 또는 0.88 (빨리 정지). 1줄 변경.
3. **Auto 모드 8초 주기** — 너무 빠른지/느린지. `MotionEngineMock.advance()` 의 `2 * .pi / 8.0` 를 `/4` (4초) 또는 `/12` (12초)로 조정 가능.
4. **Manual gravity 슬라이더 범위** — 현재 -1~1. 실 기기 기울임은 보통 -0.7~0.7 범위 — 범위 좁힐지 의견.

## 보류

| 항목 | 사유 |
|---|---|
| 모서리 곡선 충돌 (RoundedRect 코너) | 단순 AABB로 근사. 알약 ≤ 8개 + 모서리 cornerRadius 3pt 라 시각적 차이 무시 가능. 봉지 거의 직사각이라 OK |
| 모션 영상 (`motion.mov`) 캡처 | 정적 스크린샷 3장(t0/t3/t6)으로 대체 — 시뮬레이터 기본 녹화 도구로 가능하지만 보고서 용량 절감 |

## 커밋 (예정)

```
feat(ios): add MotionEngine with Real/Mock factory and CMMotionManager wrapper
feat(ios): add PillPhysicsEngine — gravity/damping/bounds/pair collision
feat(ios): integrate physics tick into PouchView TimelineView (60Hz)
feat(ios): add motion mode toggle and manual gravity sliders to Showcase
test(ios): cover PillPhysicsEngine tick semantics (16 cases, 5 suites)
docs: add Stage 3 motion screenshots (t0/t3/t6)
docs: add Stage 3 report
```

## 다음

작업지시자 검토 후 **Stage 4 (찢기 UX, Sealed↔Torn)** 진입.
- `PouchTearLayer` — 진행도 기반 찢김 path
- `PouchTearGesture` — DragGesture + 50% 임계 + 햅틱
- ADR-0009 결정대로 middle perforation 라인이 tear 시작점

## 승인 ⛔

---

# 추가: Polish (작업지시자 피드백 반영)

## 트리거

작업지시자 1차 검토 결함 2개:
1. **흔들림 너무 약함** — gScale 40 ("실 중력 1/30") 이 과도하게 보수적
2. **알약끼리 뭉개짐** — pair collision이 position만 분리하고 velocity는 그대로라 momentum 교환 없음 → 부드럽게 미끄러지며 합쳐지는 듯 보임

## 변경

### gScale 40 → 90

terminal velocity 8.3 → 18.75 pt/s (~2.3배). 봉지 안에서 활발하게 흔들림.

### Pair collision velocity 교환 추가

기존: position push-apart만.
신규: 침투 중일 때(`v_rel · n < 0`) **1D elastic collision impulse along normal** 적용 (equal mass 가정).

```swift
let vRelN = (v_j - v_i) · n
guard vRelN < 0 else { continue }   // 서로 다가갈 때만
let impulse = -(1 + pairRestitution) * vRelN * 0.5
v_i -= impulse * n
v_j += impulse * n
```

상수 `pairRestitution: 0.7` 신규 — 30% 에너지 손실 반영. 1.0(완전 탄성)은 너무 활발, 0이면 다시 뭉개짐.

### 신규 테스트 2개

| Suite | 케이스 |
|---|---|
| `PillPhysicsEnginePairCollisionTests` | `정면_충돌_시_velocity가_교환된다` — 좌→우, 우→좌 알약 충돌 후 부호 반전 |
| `PillPhysicsEnginePairCollisionTests` | `서로_멀어지는_중이면_velocity_교환_없음` — 침투 중이지만 v_rel > 0 이면 impulse 미적용 |

총 18/18 통과.

## 검증

```
xcodebuild test -scheme PillPouch -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4' \
  -only-testing:PillPouchTests/PillPhysicsEngine{Gravity,Damping,Integration,BoundsCollision,PairCollision}Tests
** TEST SUCCEEDED ** (18/18)
```

## 의사결정 박제

| 결정 | 값 | 이유 |
|---|---|---|
| gScale | **90** (40 → 90) | "살짝" 의도가 과도하게 보수적이었음. 실 기기 흔들림 신호 자체가 normalized [-1,1] 이라 scale을 이 수준으로 키워야 모바일 사용 환경에서 자연스러움 |
| pairRestitution | **0.7** | 1.0 = 완전 탄성 (지나치게 활발). 0.5 = 미적지근. 0.7 = 탱탱한 알약 충돌 |
| impulse 적용 조건 | **`v_rel · n < 0` (침투 중일 때만)** | 이미 분리 중인 알약에 impulse 가하면 부자연스러운 가속 발생 |

## 추가 커밋

```
fix(ios): tune physics for stronger shake and elastic pill collision (#25 stage3 polish)
test(ios): cover pair collision velocity exchange and divergence guard
docs: append Stage 3 polish section
```

## 승인 ⛔ (재)
