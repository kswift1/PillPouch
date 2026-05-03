//
//  PillPhysicsEngine.swift
//  PillPouch
//

import CoreGraphics
import Foundation

/// 봉지 안 알약의 2D 물리 엔진. 순수 함수형 — 외부 상태 X.
/// gravity / damping / bounds collision (RoundedRect 근사) / pair collision (sphere-sphere).
/// 실제 강체 시뮬레이터가 아니라 약봉지 안 알약처럼 보이기 위한 2D 근사.
enum PillPhysicsEngine {
    struct StepResult: Equatable {
        fileprivate(set) var maxImpactSpeed: CGFloat = 0

        var hapticIntensity: Double {
            guard maxImpactSpeed >= PillPhysicsEngine.hapticImpactThreshold else { return 0 }
            let normalized = min(
                1,
                max(
                    0,
                    Double(maxImpactSpeed - PillPhysicsEngine.hapticImpactThreshold)
                        / Double(PillPhysicsEngine.hapticImpactFullScale - PillPhysicsEngine.hapticImpactThreshold)
                )
            )
            return 0.18 + normalized * 0.37
        }

        var shouldPlayHaptic: Bool {
            hapticIntensity > 0
        }

        fileprivate mutating func recordImpact(speed: CGFloat) {
            maxImpactSpeed = max(maxImpactSpeed, speed)
        }

        fileprivate mutating func merge(_ other: StepResult) {
            maxImpactSpeed = max(maxImpactSpeed, other.maxImpactSpeed)
        }
    }

    /// 중력 가속도 스케일 (pt/s²). terminal velocity ≈ gScale * dt / (1 - damping).
    /// 1500 + damping 0.95 면 gravity=1.0 에서 terminal ~500pt/s, gravity=0.5 에서 ~250pt/s
    /// — 봉지 가로(~240pt) 를 0.5~1초 안에 가로지름.
    static let gScale: Double = 1500

    /// 매 tick 적용되는 속도 감쇠 (1보다 작음). 0.95 ^ 60 ≈ 0.046 → 1초면 사실상 정지.
    static let damping: Double = 0.95

    /// 거의 평평하게 든 상태의 센서 노이즈 / 작은 기울기는 정지 마찰로 무시.
    static let staticFrictionGravityThreshold: Double = 0.08

    /// 이미 움직이는 알약에는 더 낮은 동마찰 threshold 를 적용해 갑자기 붙는 느낌을 줄임.
    static let kineticFrictionGravityThreshold: Double = 0.03

    /// 이 속도보다 느리면 정지 마찰 후보로 본다.
    static let staticFrictionVelocityThreshold: CGFloat = 5

    /// 아주 낮은 잔류 속도는 0으로 붙여 센서 노이즈 creep 을 막는다.
    static let sleepVelocity: CGFloat = 0.8

    /// 중력 한 프레임 누적으로 생기는 벽 침범은 튕김이 아니라 접촉 정착으로 처리.
    static let settlingNormalVelocity: CGFloat = 45

    /// 벽 충돌 시 반사 계수 (0~1). 0 = 정지, 1 = 완전 탄성.
    /// 0.2 면 bounce 작게 — 부딪히고 안정. 약봉지 안 알약 거동에 정합.
    static let restitution: CGFloat = 0.2

    /// 알약 간 충돌 시 position push-apart 비율 (1.0 = 한 번에 완전 분리).
    static let pairSeparation: CGFloat = 1.0

    /// 알약 간 충돌 시 velocity 교환 탄성 계수 (0~1). 0.7 = 탱탱한 알약 충돌.
    static let pairRestitution: CGFloat = 0.7

    /// 시각 frame 대비 충돌 반지름 비율. capsule 가로 자산은 시각 두께가 frame 의 ~50%.
    /// 0.6 으로 두면 시각상 알약끼리 거의 닿은 상태에서 충돌. 1층-2층 여백 자연스러움.
    static let collisionRadiusRatio: CGFloat = 0.6

    /// 큰 overlap에서 안정 분리를 위한 pair collision iteration 횟수.
    static let pairCollisionIterations: Int = 2

    /// 매 tick 회전 감쇠. 0.80 ^ 60 ≈ 1e-6 — 0.5초 안에 사실상 정지.
    /// translation damping 0.95 보다 강함 — 자유 비행 알약은 회전 거의 즉시 죽음.
    static let angularDamping: Double = 0.80

    /// 이 값보다 낮은 회전 속도는 시각적으로 의미 없으므로 0으로 붙인다.
    static let sleepAngularVelocity: Double = 0.2

    /// pair collision 시 tangential relative velocity → angular velocity 변환 계수.
    /// 0.3 으로 약하게 — 충돌 시 살짝만 회전 부여, 뺑글뺑글 누적 방지.
    static let pairSpinTransfer: Double = 0.3

    /// 벽 contact 시 매 tick angular velocity 가 target ω = v_tangent / r 로 수렴하는 비율.
    /// rolling-without-slipping 모델 — 알약이 벽 따라 굴러갈 때만 회전 발생.
    /// 0.3 = 매 tick 30% target 으로 lerp.
    static let wallSpinLerp: Double = 0.3

    /// 벽 contact 검사 epsilon (pt). 침범 후 reflect 로 정확히 벽에 붙은 알약 검출.
    static let wallContactEpsilon: CGFloat = 1.0

    /// 햅틱을 발생시킬 최소 충돌 속도. 센서 노이즈는 걸러내되 정착성 접촉도 느껴지도록 낮게 둔다.
    static let hapticImpactThreshold: CGFloat = 35

    /// 이 속도 이상은 soft haptic 최대 강도에 가깝게 매핑.
    static let hapticImpactFullScale: CGFloat = 220

    /// pair collision normal 이 gravity 방향과 거의 평행하면 (|n · ĝ| > 이 값) stack 으로 간주.
    /// sphere-sphere 모델은 stack 시 perpendicular spread 가 안 일어나는데, 실제 약봉지 알약은
    /// 길쭉해 stack 시 미끄러져 옆으로 흩어짐. 이 case 에서 perpendicular nudge 부여.
    /// 0.7 = gravity 와 normal 사이 각도 45° 이내. 대각 gravity 시 corner 에 모인 알약이
    /// wall-aligned (수평/수직) stack 으로 정착해도 ±45° 이내라 catch 됨.
    static let stackParallelDotThreshold: CGFloat = 0.7

    /// stack 시 upper 알약에 부여하는 perpendicular velocity 크기 (pt/s). 부호는 id hash 로 결정.
    /// 18 = corner 모임 spread 가 자연스럽게 일어날 강도.
    static let stackBreakingNudge: CGFloat = 18

    /// 한 프레임 물리 진행. `pills` 배열을 in-place 갱신.
    /// - Parameters:
    ///   - dt: 경과 시간 (초). 보통 1/60.
    ///   - gravity: 화면 좌표계 (x: 우, y: 하) 단위 벡터. CMMotionManager.gravity 매핑 결과.
    ///   - bounds: 알약이 머물 수 있는 사각 영역 (봉지 로컬 좌표).
    @discardableResult
    static func tick(
        dt: TimeInterval,
        gravity: SIMD2<Double>,
        bounds: CGRect,
        pills: inout [PillBody]
    ) -> StepResult {
        guard dt > 0 else { return StepResult() }
        var result = StepResult()
        for i in pills.indices {
            applyGravity(&pills[i], dt: dt, gravity: gravity)
            applyDamping(&pills[i], dt: dt)
            integratePosition(&pills[i], dt: dt)
            integrateRotation(&pills[i], dt: dt)
            sleepIfNeeded(&pills[i])
        }
        result.merge(resolveBoundsCollision(&pills, in: bounds, gravity: gravity))
        result.merge(resolvePairCollisions(&pills, gravity: gravity))
        // Pair push-apart can move a pill outside the pouch after bounds were already solved.
        // A final clamp keeps constraints coherent without adding another pair impulse pass.
        result.merge(resolveBoundsCollision(&pills, in: bounds, gravity: gravity))
        return result
    }

    // MARK: - Forces / integration

    private static func applyGravity(_ pill: inout PillBody, dt: TimeInterval, gravity: SIMD2<Double>) {
        let effectiveGravity = gravityAfterFriction(for: pill, gravity: gravity)
        pill.velocity.dx += CGFloat(effectiveGravity.x * gScale * dt)
        pill.velocity.dy += CGFloat(effectiveGravity.y * gScale * dt)
    }

    private static func gravityAfterFriction(for pill: PillBody, gravity: SIMD2<Double>) -> SIMD2<Double> {
        let magnitude = sqrt(gravity.x * gravity.x + gravity.y * gravity.y)
        guard magnitude > 0 else { return SIMD2(0, 0) }

        let speed = hypot(pill.velocity.dx, pill.velocity.dy)
        let threshold = speed < staticFrictionVelocityThreshold
            ? staticFrictionGravityThreshold
            : kineticFrictionGravityThreshold
        guard magnitude > threshold else { return SIMD2(0, 0) }

        let scale = (magnitude - threshold) / magnitude
        return SIMD2(gravity.x * scale, gravity.y * scale)
    }

    private static func applyDamping(_ pill: inout PillBody, dt: TimeInterval) {
        let frameScaledDamping = pow(damping, max(0, dt * 60.0))
        pill.velocity.dx *= CGFloat(frameScaledDamping)
        pill.velocity.dy *= CGFloat(frameScaledDamping)
    }

    private static func integratePosition(_ pill: inout PillBody, dt: TimeInterval) {
        pill.position.x += pill.velocity.dx * CGFloat(dt)
        pill.position.y += pill.velocity.dy * CGFloat(dt)
    }

    private static func integrateRotation(_ pill: inout PillBody, dt: TimeInterval) {
        pill.rotation += pill.angularVelocity * dt
        pill.angularVelocity *= pow(angularDamping, max(0, dt * 60.0))
    }

    private static func sleepIfNeeded(_ pill: inout PillBody) {
        if hypot(pill.velocity.dx, pill.velocity.dy) < sleepVelocity {
            pill.velocity = .zero
        }
        if abs(pill.angularVelocity) < sleepAngularVelocity {
            pill.angularVelocity = 0
        }
    }

    // MARK: - Collisions

    /// 봉지 내부 사각 영역 충돌. 모서리는 단순 AABB로 근사.
    /// 1) 침범 시 position 클램프 + velocity 반사
    /// 2) Contact 인 동안 매 tick ω 를 v_tangent / r 로 lerp (rolling-without-slipping)
    /// 회전은 벽 contact 가 지속되는 동안만 발생. 자유 비행은 angularDamping 으로 즉시 죽음.
    @discardableResult
    static func resolveBoundsCollision(
        _ pills: inout [PillBody],
        in bounds: CGRect,
        gravity: SIMD2<Double> = SIMD2(0, 0)
    ) -> StepResult {
        let toDeg = 180.0 / .pi
        var result = StepResult()

        for i in pills.indices {
            let r = pills[i].radius * collisionRadiusRatio

            // 1) 침범 처리
            if pills[i].position.x - r < bounds.minX {
                pills[i].position.x = bounds.minX + r
                settleOrBounceLowerNormalVelocity(&pills[i].velocity.dx, result: &result)
            } else if pills[i].position.x + r > bounds.maxX {
                pills[i].position.x = bounds.maxX - r
                settleOrBounceUpperNormalVelocity(&pills[i].velocity.dx, result: &result)
            }
            if pills[i].position.y - r < bounds.minY {
                pills[i].position.y = bounds.minY + r
                settleOrBounceLowerNormalVelocity(&pills[i].velocity.dy, result: &result)
            } else if pills[i].position.y + r > bounds.maxY {
                pills[i].position.y = bounds.maxY - r
                settleOrBounceUpperNormalVelocity(&pills[i].velocity.dy, result: &result)
            }

            // 2) Contact rolling
            let onLeft   = pills[i].position.x - r <= bounds.minX + wallContactEpsilon
            let onRight  = pills[i].position.x + r >= bounds.maxX - wallContactEpsilon
            let onTop    = pills[i].position.y - r <= bounds.minY + wallContactEpsilon
            let onBottom = pills[i].position.y + r >= bounds.maxY - wallContactEpsilon

            // target ω = v_tangent / radius (시각 반지름 사용 — 시각상 굴러가는 속도 일치)
            // 부호: 좌측벽+dy>0 → 시계방향(+), 우측벽+dy>0 → 반시계(-),
            //       하단+dx>0 → 시계(+), 상단+dx>0 → 반시계(-)
            var targetOmega: Double? = nil
            if onLeft {
                targetOmega = Double(pills[i].velocity.dy) / Double(pills[i].radius) * toDeg
            } else if onRight {
                targetOmega = -Double(pills[i].velocity.dy) / Double(pills[i].radius) * toDeg
            }
            if onBottom {
                // 좌/우 + 하단 corner contact 시 하단이 우선 — 봉지 바닥 굴러가는 게 시각 dominant
                targetOmega = Double(pills[i].velocity.dx) / Double(pills[i].radius) * toDeg
            } else if onTop {
                targetOmega = -Double(pills[i].velocity.dx) / Double(pills[i].radius) * toDeg
            }

            if let target = targetOmega {
                pills[i].angularVelocity += (target - pills[i].angularVelocity) * wallSpinLerp
            }

            // 접촉면 안쪽으로 향하는 잔류 normal velocity 는 normal force 로 상쇄.
            if onLeft, gravity.x < 0, pills[i].velocity.dx < settlingNormalVelocity {
                pills[i].velocity.dx = max(0, pills[i].velocity.dx)
            } else if onRight, gravity.x > 0, pills[i].velocity.dx > -settlingNormalVelocity {
                pills[i].velocity.dx = min(0, pills[i].velocity.dx)
            }
            if onTop, gravity.y < 0, pills[i].velocity.dy < settlingNormalVelocity {
                pills[i].velocity.dy = max(0, pills[i].velocity.dy)
            } else if onBottom, gravity.y > 0, pills[i].velocity.dy > -settlingNormalVelocity {
                pills[i].velocity.dy = min(0, pills[i].velocity.dy)
            }
        }

        return result
    }

    private static func settleOrBounceLowerNormalVelocity(_ velocity: inout CGFloat, result: inout StepResult) {
        guard velocity < 0 else { return }
        let incomingSpeed = -velocity
        result.recordImpact(speed: incomingSpeed)
        if incomingSpeed > settlingNormalVelocity {
            velocity = incomingSpeed * restitution
        } else {
            velocity = 0
        }
    }

    private static func settleOrBounceUpperNormalVelocity(_ velocity: inout CGFloat, result: inout StepResult) {
        guard velocity > 0 else { return }
        let incomingSpeed = velocity
        result.recordImpact(speed: incomingSpeed)
        if incomingSpeed > settlingNormalVelocity {
            velocity = -incomingSpeed * restitution
        } else {
            velocity = 0
        }
    }

    /// 알약 간 sphere-sphere 충돌. O(N²) — N ≤ 8 이라 무시 가능.
    /// position push-apart + 침투 중일 때 normal 방향 velocity impulse 교환 (equal mass 가정).
    /// iteration 2회 — 큰 overlap에서 한 번에 안 풀리는 경우 안정화.
    /// gravity 방향 stack(`|n · ĝ| > stackParallelDotThreshold`) 시 perpendicular nudge 적용.
    @discardableResult
    static func resolvePairCollisions(_ pills: inout [PillBody], gravity: SIMD2<Double>) -> StepResult {
        var result = StepResult()
        // gravity 정규화 (크기 너무 작으면 stack-breaking 의미 없으니 skip)
        let gNorm = sqrt(gravity.x * gravity.x + gravity.y * gravity.y)
        let hasGravity = gNorm > 0.1
        let gx = hasGravity ? gravity.x / gNorm : 0
        let gy = hasGravity ? gravity.y / gNorm : 0

        let count = pills.count
        guard count >= 2 else { return result }
        for _ in 0 ..< pairCollisionIterations {
            for i in 0 ..< count - 1 {
                for j in (i + 1) ..< count {
                    let dx = pills[j].position.x - pills[i].position.x
                    let dy = pills[j].position.y - pills[i].position.y
                    let rawDist = sqrt(dx * dx + dy * dy)
                    let minDist = (pills[i].radius + pills[j].radius) * collisionRadiusRatio
                    guard rawDist < minDist else { continue }
                    let dist: CGFloat
                    let nx: CGFloat
                    let ny: CGFloat
                    if rawDist > 0.001 {
                        dist = rawDist
                        nx = dx / rawDist
                        ny = dy / rawDist
                    } else {
                        // 같은 좌표에서 시작한 알약도 deterministic 하게 분리한다.
                        dist = 0.001
                        nx = ((i + j) & 1 == 0) ? -1 : 1
                        ny = 0
                    }

                    let overlap = (minDist - dist) * pairSeparation * 0.5
                    pills[i].position.x -= nx * overlap
                    pills[i].position.y -= ny * overlap
                    pills[j].position.x += nx * overlap
                    pills[j].position.y += ny * overlap

                    // tangential relative velocity → angular velocity (스쳐 지나갈 때 회전).
                    // tangent = (-ny, nx) — normal을 시계방향 90° 회전. vRelN 가드 전 — 정확한
                    // 스침(vRelN=0)에서도 회전이 발생하도록.
                    let vRelT = (pills[j].velocity.dx - pills[i].velocity.dx) * Double(-ny)
                              + (pills[j].velocity.dy - pills[i].velocity.dy) * Double(nx)
                    pills[i].angularVelocity -= vRelT * pairSpinTransfer
                    pills[j].angularVelocity += vRelT * pairSpinTransfer

                    // Stack breaking — sphere-sphere 모델 한계 보완.
                    // normal 이 gravity 방향과 거의 평행하면 (어느 방향 gravity 든) stack 으로 간주.
                    // upper = gravity 반대편 알약. nudge 는 gravity 의 perpendicular 방향(±).
                    if hasGravity {
                        let dotNG = nx * CGFloat(gx) + ny * CGFloat(gy)
                        if abs(dotNG) > stackParallelDotThreshold {
                            // upper = pos · g 가 작은 쪽 (gravity 반대 방향에 위치)
                            let dotIG = pills[i].position.x * CGFloat(gx) + pills[i].position.y * CGFloat(gy)
                            let dotJG = pills[j].position.x * CGFloat(gx) + pills[j].position.y * CGFloat(gy)
                            let upperIdx = dotIG < dotJG ? i : j
                            let lowerIdx = upperIdx == i ? j : i
                            // perpendicular = (-gy, gx) — gravity 시계방향 90°
                            let perpX = -CGFloat(gy)
                            let perpY = CGFloat(gx)
                            let sign: CGFloat = (pills[upperIdx].id.hashValue & 1 == 0) ? 1 : -1
                            pills[upperIdx].velocity.dx += stackBreakingNudge * sign * perpX
                            pills[upperIdx].velocity.dy += stackBreakingNudge * sign * perpY
                            pills[lowerIdx].velocity.dx -= stackBreakingNudge * sign * perpX
                            pills[lowerIdx].velocity.dy -= stackBreakingNudge * sign * perpY
                        }
                    }

                    // 1D elastic collision along normal (equal mass m=1) — 침투 중에만 적용.
                    let vRelN = (pills[j].velocity.dx - pills[i].velocity.dx) * nx
                              + (pills[j].velocity.dy - pills[i].velocity.dy) * ny
                    guard vRelN < 0 else { continue }
                    result.recordImpact(speed: -vRelN)
                    let impulse = -(1 + pairRestitution) * vRelN * 0.5
                    pills[i].velocity.dx -= impulse * nx
                    pills[i].velocity.dy -= impulse * ny
                    pills[j].velocity.dx += impulse * nx
                    pills[j].velocity.dy += impulse * ny
                }
            }
        }
        return result
    }
}
