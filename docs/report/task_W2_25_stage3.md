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

---

# 추가: Polish v2 (실 기기 검증 후 2차)

## 트리거

작업지시자 1차 polish 검증 결과 결함 2개:
1. **여전히 너무 느림** — gScale 90도 부족. terminal velocity 18.75pt/s 라 봉지 가로지르는 데 15초+
2. **알약 여전히 겹침** — root cause: bounds collision의 `r = radius * 0.5`. 충돌 반지름이 시각 frame의 절반이라 알약 frame 53pt가 22pt 거리까지 침투해도 충돌 미발생

## 변경

### gScale 90 → 250

terminal velocity 18.75 → 52 pt/s. 봉지 높이 280pt를 1초에 가로지름.

### collisionRadiusRatio 신규 (0.5 → 0.9)

기존 코드의 `radius * 0.5` 매직 넘버를 `collisionRadiusRatio` 상수로 추출. 자산이 frame을 거의 가득 채운다는 사실 반영해 0.9로 상향.

| 항목 | 전 (시각/충돌) | 후 (시각/충돌) |
|---|---|---|
| 알약 frame | 53pt | 53pt (변경 X) |
| 충돌 반지름 (radius=22 기준) | 11pt | 19.8pt |
| 충돌 발생 거리 (두 알약) | 22pt 침투 시 | 39.6pt 침투 시 |

bounds collision + pair collision 양쪽 동일 비율 적용.

### pairSeparation 0.5 → 1.0 + iteration 2회

- 한 번의 충돌에서 완전 분리 (이전엔 절반씩 천천히)
- 큰 overlap 또는 다중 침투(여러 알약 모임) 안정화 위해 iteration 2회

### MotionEngineMock auto 활발화

| 항목 | 전 | 후 |
|---|---|---|
| 주기 | 8초 | 4초 |
| amplitude | 0.7 | 1.0 (x), 0.6+0.4 (y) |

### 테스트 영향

- bounds collision 4개 케이스: expected position 19.8 / 180.2 / 380.2 / 19.8 으로 갱신 (`abs(...) < 0.001` 부동소수점 비교)
- 정착 테스트: 시작 100 + 10초 시뮬 (terminal velocity 빠르지만 bouncing 누적으로 정착까지 시간 필요)

## 검증

```
** TEST SUCCEEDED ** (18/18)
```

## 의사결정 박제

| 결정 | 값 | 이유 |
|---|---|---|
| `gScale` | **250** (40 → 90 → 250) | 1차 polish의 90도 약함. 모바일 환경에서 normalized [-1,1] gravity 신호로도 자연스러운 흔들림 만들려면 이 정도 scale 필요 |
| `collisionRadiusRatio` | **0.9** | `* 0.5` 가 시각 frame의 절반이라는 비현실적 가정. 자산은 frame ~90% 차지 — 시각/충돌 일치 |
| `pairSeparation` | **1.0** | 한 번에 완전 분리. iteration 2회와 합쳐 다중 침투 안정 |
| Mock auto 주기 4초 | 데모 활발 | 8초는 시뮬에서 너무 느슨. 실 기기 흔들림과의 차이 줄임 |

## 추가 커밋

```
fix(ios): boost shake intensity and fix pill overlap with full-radius collision (#25 stage3 polish v2)
test(ios): adjust bounds collision expected positions for new ratio
docs: append Stage 3 polish v2 section
```

## 승인 ⛔ (3차)

---

# 추가: Polish v3 (실 약봉지 UX 정합)

## 트리거

작업지시자 3차 검증 결함 3개:
1. **여전히 덜 활발** — gScale 250도 부족
2. **회전 부재** — 충돌/마찰에 따라 알약이 돌아가지 않음. 실 약봉지에서 흔들면 알약이 굴러감
3. **1층/2층 알약 사이 여백 비현실적** — 가로로 긴 capsule(vitaminB 등) 자산은 frame 의 ~50%만 시각적으로 차지하는데 충돌 반경 ratio 0.9는 이 비율을 무시해서 시각상 알약 1개 분량 여백 발생

## 변경

### gScale 250 → 400

terminal velocity 52 → 83 pt/s. 봉지 높이 280pt를 0.5초 안에 가로지름.

### collisionRadiusRatio 0.9 → 0.6

PR #22 카테고리 자산 비율 분석:
- 정사각 자산 (tablet 등): frame 100% 차지 → 시각 반지름 22pt
- 가로 capsule 자산 (vitaminB, omega3): frame 가로 100%, 세로 ~50% → 시각 세로 반지름 ~11pt

이전 ratio 0.9 (반지름 19.8pt) 는 가로 자산엔 너무 컸음. **0.6 (반지름 13.2pt)** 으로 시각 두께 평균에 정합. 두 알약 시각상 거의 닿은 상태에서 충돌.

### Mock initial spacing 3pt → 1pt

처음부터 빽빽하게 배치 — 이미지의 1층/2층 큰 여백을 자연스러운 밀집으로.

### 각운동 (angular velocity) 신규

PillBody에 `angularVelocity: Double` (deg/s) 필드 추가.

#### 매 tick integrate

```swift
pill.rotation += pill.angularVelocity * dt
pill.angularVelocity *= angularDamping  // 0.95
```

1초 후 사실상 정지 (`0.95^60 ≈ 0.046`).

#### Pair collision tangential transfer

```swift
let tangent = (-ny, nx)  // normal 시계방향 90°
let vRelT = (vj - vi) · tangent
pills[i].angularVelocity -= vRelT * pairSpinTransfer  // 1.5
pills[j].angularVelocity += vRelT * pairSpinTransfer
```

스쳐 지나가는 충돌 시 양쪽이 반대 방향으로 회전. 정면 충돌은 tangent 성분 0이라 회전 없음 — 직관적.

**중요: tangential transfer는 `vRelN < 0` 가드 위에 위치** — 정확한 스침(vRelN=0)에서도 회전이 발생하도록.

#### Bounds wall friction spin

```swift
// 좌측 벽: angularVelocity += dy * wallSpinTransfer (0.6)
// 우측 벽: -= dy * wallSpinTransfer
// 상단 벽: -= dx * wallSpinTransfer
// 하단 벽: += dx * wallSpinTransfer
```

벽 따라 미끄러지는 알약이 자연스럽게 굴러감. 부호는 시계방향 회전(+) 기준.

#### 새 상수 3개

| 상수 | 값 | 의미 |
|---|---|---|
| `angularDamping` | 0.95 | 매 tick 감쇠 |
| `pairSpinTransfer` | 1.5 (deg/s per pt/s) | 100pt/s 스침 → 150 deg/s 스핀 |
| `wallSpinTransfer` | 0.6 | 벽 마찰 spin 감도 |

### 신규 테스트 4개 (Suite `PillPhysicsEngineRotationTests`)

| 케이스 | 검증 |
|---|---|
| `angularVelocity가_매_tick_rotation에_누적된다` | rotation += 60 * (1/60) = 1.0 |
| `angularDamping이_angularVelocity를_감쇠시킨다` | 100 → 95 (0.95 비율) |
| `좌측_벽_충돌시_y_velocity가_angular에_기여` | dy 30 → angular 18 |
| `스쳐_지나가는_충돌시_양쪽_반대_부호_spin` | 두 알약 angular 곱 < 0 |

총 22/22 통과.

### 정착 테스트 expected 갱신

r 13.2로 변경 → 정착점 maxY - r = 386.8. 범위 380~387.

## 검증

```
** TEST SUCCEEDED ** (22/22, +4 회전 suite)
```

## 의사결정 박제

| 결정 | 값 | 이유 |
|---|---|---|
| `gScale` | **400** (250→400) | 모바일 일상 motion에서 충분히 활발한 동작 |
| `collisionRadiusRatio` | **0.6** | 카테고리 자산 비율(정사각~가로 2:1) 평균 시각 두께. 0.9는 가로 자산 무시 |
| Mock initial spacing | **1pt** | 빽빽하게 시작 — 흔들리면서 자연 분리 |
| `angularDamping` | **0.95** (rotation), 0.92 (translation) | 회전이 직선 운동보다 살짝 더 오래 지속 — 알약 굴러가는 느낌 |
| Tangential transfer 위치 | **`vRelN < 0` guard 위** | 정확한 스침(vRelN=0)에서도 회전 발생. 가드 안에 두면 정직각 스침 회전 사라짐 |

## 추가 커밋

```
feat(ios): add angular velocity and tighten collision radius for realistic pouch UX (#25 stage3 polish v3)
test(ios): cover rotation integration, damping, wall friction, and tangential transfer
docs: append Stage 3 polish v3 section
```

## 승인 ⛔ (4차)

---

# 추가: Polish v4 (이동 속도 + 회전 비대칭 fix)

## 트리거

작업지시자 4차 검증 결함 2개:
1. **왼쪽으로 돌릴 때만 회전하며 내려감** — 우측 회전이 약하거나 안 보임
2. **이동 너무 느림** — gScale 400도 부족

## 진단

### 회전 비대칭 root cause

기존 코드: bounds collision 시 `velocity.dx = -velocity.dx * restitution` **반사 후** 의 `velocity.dy` 로 spin 계산.

```swift
pills[i].velocity.dx = -pills[i].velocity.dx * restitution   // 먼저 반사
pills[i].angularVelocity += dy * wallSpinTransfer            // 이미 반사된 dy 사용
```

문제: dx만 반사하지만, 이전 코드 순서상 dy 도 같이 영향받지 않더라도 강한 충돌일수록 spin이 작아지는 구조 + magnitude 자체 부족.

좌측 벽은 dy=양수(아래로 내려가는 알약)로 spin 명확히 보이지만, 우측 벽은 사용자가 이미 우측 자세로 잡아 dy 가 작아 spin 사라짐.

### 이동 속도

gScale 400, gravity=1.0 에서 terminal velocity 83pt/s. 실 사용자 일상 기울임은 gravity 0.3~0.5 정도 → terminal 25~42pt/s. 봉지 가로 240pt 가로지르는 데 5~9초.

## 변경

### gScale 400 → 1000

| gravity | 전 (gScale 400) | 후 (gScale 1000) |
|---|---|---|
| 1.0 (강한 기울임) | 83 pt/s | 208 pt/s |
| 0.5 (일상) | 41 pt/s | 104 pt/s |
| 0.3 (살짝) | 25 pt/s | 62 pt/s |

봉지 가로(~240pt) 가로지르는 시간: 일상 기울임에서 5초+ → 2초 안.

### Wall spin: pre-velocity 사용

```swift
let preDx = pills[i].velocity.dx
let preDy = pills[i].velocity.dy
// 반사
pills[i].velocity.dx = -preDx * restitution
// spin은 pre-velocity 의 tangent 성분 사용
pills[i].angularVelocity += preDy * wallSpinTransfer
```

강한 충돌에서도 spin 명확. 좌/우 비대칭 제거.

### wallSpinTransfer 0.6 → 1.5, pairSpinTransfer 1.5 → 2.5

회전 magnitude 2.5배 증가. 충돌/벽 마찰 회전 효과 확실히 보이도록.

### 신규 테스트 2개

| 케이스 | 검증 |
|---|---|
| `우측_벽_충돌시_y_velocity가_반대_부호_spin` | 좌/우 대칭 보장 — 우측 spin = -45 (좌측 +45 와 부호만 반대) |
| `강한_충돌에서도_pre_velocity_spin_유지` | preDx -200, preDy 100 으로 강한 충돌 시 angular 150 (post-velocity 사용했으면 30 만) |

기존 좌측 wall test의 expected 18 → 45 갱신.

## 검증

```
** TEST SUCCEEDED ** (24/24)
```

## 의사결정 박제

| 결정 | 값 | 이유 |
|---|---|---|
| `gScale` | **1000** (400→1000) | 일상 기울임(gravity ~0.5) 에서도 1~2초 가로지르는 활발함 |
| Wall spin 시점 | **반사 전 velocity** | 강한 충돌일수록 spin 작아지는 비대칭 제거. 좌/우 동등 회전 보장 |
| `wallSpinTransfer` | **1.5** (0.6→1.5) | 시각상 회전이 명확히 보일 magnitude. 더 키우면 over-rotation |
| `pairSpinTransfer` | **2.5** (1.5→2.5) | 충돌 회전도 동등 강화 |

## 추가 커밋

```
fix(ios): boost gravity scale and use pre-velocity for symmetric wall spin (#25 stage3 polish v4)
test(ios): cover right-wall spin symmetry and pre-velocity spin magnitude
docs: append Stage 3 polish v4 section
```

## 승인 ⛔ (5차)

---

# 추가: Polish v5 — Rolling-without-slipping (현실 물리 모델)

## 트리거

작업지시자 5차 검증:
1. 좌/우 모두 회전하지만 **뺑글뺑글 비현실적** — 단순 기울임에 알약이 빙빙 돌 이유 없음
2. 이동 여전히 둔함

작업지시자 추가 질문: "벽 따라 회전 어떤 의도였나? 현실 물리 모델은?"

## 진단

### Wall spin impulse 모델의 한계

기존 모델 (v4까지): 충돌 시점에 `dy * wallSpinTransfer` 한 번에 큰 spin 부여.

문제:
- 마찰의 본질은 회전 **억제 + 미끄럼 줄이기** 인데 매 충돌마다 spin **부여** — 잘못된 방향
- magnitude 150 deg/s + angularDamping 0.95 (1초당 5%만 감쇠) → 1초 후 75도, 2초 후 113도 회전. 뺑글뺑글
- 물리적 근거 없는 부호 결정 (좌측+dy → 시계방향 등)

### 이동 둔함

gScale 1000 + damping 0.92 → terminal velocity 208pt/s @gravity=1.0. 일상 기울임(0.5)에서 104pt/s. 봉지 가로지르는 데 ~2초. 사용자 체감 둔함.

## 변경 — 옵션 C "단순 현실 모델" 채택

작업지시자가 옵션 C 선택. Rolling-without-slipping 의 단순화 버전:
- **자유 비행**: 회전 없음 (강한 angularDamping 으로 즉시 죽임)
- **벽 contact**: 매 tick `ω → v_tangent / r` lerp 수렴
- **충돌**: 약한 tangential transfer 만 유지

### 상수 변경

| 상수 | 전 | 후 | 의미 |
|---|---|---|---|
| `gScale` | 1000 | **1500** | 이동 활발 |
| `damping` | 0.92 | **0.95** | terminal multiplier 12.5 → 20 (가속 + 빠른 도달) |
| `restitution` | 0.3 | **0.2** | bounce 작게, 안정 정착 |
| `angularDamping` | 0.95 | **0.80** | 자유 비행 회전 0.5초 안에 죽음 |
| `pairSpinTransfer` | 2.5 | **0.3** | 충돌 회전 약화 |
| `wallSpinTransfer` | 1.5 | **제거** | impulse 모델 폐기 |
| `wallSpinLerp` (신규) | — | **0.3** | 매 tick ω → target 30% lerp |
| `wallContactEpsilon` (신규) | — | **1.0pt** | reflect 후 벽 붙은 알약 검출 |

### resolveBoundsCollision 재작성

```swift
// 1) 침범 처리 (기존)
if pills[i].position.x - r < bounds.minX {
    pills[i].position.x = bounds.minX + r
    pills[i].velocity.dx = -pills[i].velocity.dx * restitution
}
// ... 4면 동일

// 2) Contact rolling — 매 tick 검사
let onLeft   = pills[i].position.x - r <= bounds.minX + wallContactEpsilon
let onRight  = pills[i].position.x + r >= bounds.maxX - wallContactEpsilon
let onTop    = pills[i].position.y - r <= bounds.minY + wallContactEpsilon
let onBottom = pills[i].position.y + r >= bounds.maxY - wallContactEpsilon

var targetOmega: Double? = nil
if onLeft  { targetOmega =  v.dy / radius * toDeg }   // 좌측: 시계방향(+)
if onRight { targetOmega = -v.dy / radius * toDeg }   // 우측: 반시계(-)
if onBottom { targetOmega =  v.dx / radius * toDeg }  // 하단: 시계방향
if onTop    { targetOmega = -v.dx / radius * toDeg }  // 상단: 반시계
// corner contact 시 bottom > top > side 우선

if let target = targetOmega {
    pills[i].angularVelocity += (target - pills[i].angularVelocity) * wallSpinLerp
}
```

### 효과

| 시나리오 | 전 (v4) | 후 (v5 / C 모델) |
|---|---|---|
| 봉지 가운데 자유 비행 | 충돌 spin 누적, angularDamping 약해서 천천히 정지 | 회전 즉시 죽음 (0.5초 안) |
| 좌측으로 기울여 알약이 좌측 벽 따라 내려감 | 충돌 instant 큰 spin → 뺑글뺑글 | 매 tick `ω = dy/r` 로 수렴 → 자연스럽게 굴러감 |
| 정지 시 회전 | 잔여 spin 으로 천천히 회전 지속 | translation 정지 → contact 사라짐 + damping 으로 즉시 정지 |
| 두 알약 스침 | spin 250 deg/s | spin 30 deg/s, 살짝만 흔들림 |

### 신규 / 갱신 테스트 (Rotation Suite)

| 케이스 | 검증 |
|---|---|
| `angularDamping이_angularVelocity를_감쇠시킨다` | 100 → 80 (0.80 감쇠) |
| `좌측_벽_contact_시_target_omega로_lerp` | dy=30 → target 78.13, lerp 0.3 → 23.44 |
| `우측_벽_contact_시_반대_부호_target` | -23.44 |
| `좌측_벽_지속_contact_시_target_omega로_수렴` (신규) | 30 tick 반복 → target * 0.3 < ω < target |
| `자유_비행_시_wall_contact_없으면_lerp_미적용` (신규) | 봉지 가운데 알약 ω 변화 0 |
| `스쳐_지나가는_충돌시_양쪽_반대_부호_spin` | pairSpinTransfer 0.3 — 부호 검증만 (통과) |

### 다른 갱신 테스트

- `damping이_매_tick_velocity를_감소시킨다`: 100 * 0.92 → 100 * 0.95 = 95
- `velocity가_dt만큼_position에_적용된다`: 60 * 0.95 / 60 = 0.95 변화
- bounds collision 4개 velocity expected: ±15 → ±10 (restitution 0.3 → 0.2)
- `중력_없을때_60틱_후_velocity_거의_0` → `120틱` (damping 약해진 만큼 더 길게)

## 검증

```
** TEST SUCCEEDED ** (25/25, 신규 2개 추가)
```

## 의사결정 박제

| 결정 | 값 | 이유 |
|---|---|---|
| 회전 모델 | **Rolling lerp (옵션 C)** | 작업지시자 결정. impulse 보다 현실적이면서 코드 ~10줄 |
| Wall ω target | `v_tangent / r * (180/π)` | rolling-without-slipping kinematic constraint. 알약이 진짜 굴러가는 효과 |
| Lerp factor | **0.3** | 매 tick 30% 수렴 → 5 tick 후 거의 target 도달 (0.083초). 빠른 자연 전이 |
| 시각 반지름 사용 (`pill.radius`) vs 충돌 반지름 (`r`) | 시각 반지름 | 시각상 굴러가는 속도와 일치. collision r=13.2 사용 시 회전 너무 빠름 |
| Corner contact 우선순위 | bottom > top > side | 봉지 바닥 굴러가는 게 시각 dominant |
| `gScale` 1500 + `damping` 0.95 | 결합 | terminal multiplier 20 — 즉각 반응 + 빠른 가속 |
| `restitution` 0.2 | bounce 줄임 | 부딪히고 즉시 안정 — 약봉지 거동 정합 |

## 추가 커밋

```
feat(ios): adopt rolling-without-slipping wall contact model and tune motion responsiveness (#25 stage3 polish v5)
test(ios): cover wall contact lerp, free-flight no-rotation, and updated damping/restitution
docs: append Stage 3 polish v5 section
```

## 승인 ⛔ (6차)
