//
//  PillPhysicsEngine.swift
//  PillPouch
//

import CoreGraphics
import Foundation

/// 봉지 안 알약의 2D 물리 엔진. 순수 함수형 — 외부 상태 X.
/// gravity / damping / bounds collision (RoundedRect 근사) / pair collision (sphere-sphere).
/// '살짝' 흔들림이 목표라 G_SCALE은 실 중력의 ~1/30 수준.
enum PillPhysicsEngine {
    /// 중력 가속도 스케일 (pt/s²). terminal velocity ≈ gScale * dt / (1 - damping).
    /// 1500 + damping 0.95 면 gravity=1.0 에서 terminal ~500pt/s, gravity=0.5 에서 ~250pt/s
    /// — 봉지 가로(~240pt) 를 0.5~1초 안에 가로지름.
    static let gScale: Double = 1500

    /// 매 tick 적용되는 속도 감쇠 (1보다 작음). 0.95 ^ 60 ≈ 0.046 → 1초면 사실상 정지.
    static let damping: Double = 0.95

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

    /// pair collision 시 tangential relative velocity → angular velocity 변환 계수.
    /// 0.3 으로 약하게 — 충돌 시 살짝만 회전 부여, 뺑글뺑글 누적 방지.
    static let pairSpinTransfer: Double = 0.3

    /// 벽 contact 시 매 tick angular velocity 가 target ω = v_tangent / r 로 수렴하는 비율.
    /// rolling-without-slipping 모델 — 알약이 벽 따라 굴러갈 때만 회전 발생.
    /// 0.3 = 매 tick 30% target 으로 lerp.
    static let wallSpinLerp: Double = 0.3

    /// 벽 contact 검사 epsilon (pt). 침범 후 reflect 로 정확히 벽에 붙은 알약 검출.
    static let wallContactEpsilon: CGFloat = 1.0

    /// pair collision normal 이 gravity 방향과 거의 평행하면 (|n · ĝ| > 이 값) stack 으로 간주.
    /// sphere-sphere 모델은 stack 시 perpendicular spread 가 안 일어나는데, 실제 약봉지 알약은
    /// 길쭉해 stack 시 미끄러져 옆으로 흩어짐. 이 case 에서 perpendicular nudge 부여.
    /// 0.95 = gravity 와 normal 사이 각도 18° 이내 (어느 방향 gravity 든 일반화).
    static let stackParallelDotThreshold: CGFloat = 0.95

    /// stack 시 upper 알약에 부여하는 perpendicular velocity 크기 (pt/s). 부호는 id hash 로 결정.
    static let stackBreakingNudge: CGFloat = 12

    /// 한 프레임 물리 진행. `pills` 배열을 in-place 갱신.
    /// - Parameters:
    ///   - dt: 경과 시간 (초). 보통 1/60.
    ///   - gravity: 화면 좌표계 (x: 우, y: 하) 단위 벡터. CMMotionManager.gravity 매핑 결과.
    ///   - bounds: 알약이 머물 수 있는 사각 영역 (봉지 로컬 좌표).
    static func tick(
        dt: TimeInterval,
        gravity: SIMD2<Double>,
        bounds: CGRect,
        pills: inout [PillBody]
    ) {
        guard dt > 0 else { return }
        for i in pills.indices {
            applyGravity(&pills[i], dt: dt, gravity: gravity)
            applyDamping(&pills[i])
            integratePosition(&pills[i], dt: dt)
            integrateRotation(&pills[i], dt: dt)
        }
        resolveBoundsCollision(&pills, in: bounds)
        resolvePairCollisions(&pills, gravity: gravity)
    }

    // MARK: - Forces / integration

    private static func applyGravity(_ pill: inout PillBody, dt: TimeInterval, gravity: SIMD2<Double>) {
        pill.velocity.dx += CGFloat(gravity.x * gScale * dt)
        pill.velocity.dy += CGFloat(gravity.y * gScale * dt)
    }

    private static func applyDamping(_ pill: inout PillBody) {
        pill.velocity.dx *= CGFloat(damping)
        pill.velocity.dy *= CGFloat(damping)
    }

    private static func integratePosition(_ pill: inout PillBody, dt: TimeInterval) {
        pill.position.x += pill.velocity.dx * CGFloat(dt)
        pill.position.y += pill.velocity.dy * CGFloat(dt)
    }

    private static func integrateRotation(_ pill: inout PillBody, dt: TimeInterval) {
        pill.rotation += pill.angularVelocity * dt
        pill.angularVelocity *= angularDamping
    }

    // MARK: - Collisions

    /// 봉지 내부 사각 영역 충돌. 모서리는 단순 AABB로 근사.
    /// 1) 침범 시 position 클램프 + velocity 반사
    /// 2) Contact 인 동안 매 tick ω 를 v_tangent / r 로 lerp (rolling-without-slipping)
    /// 회전은 벽 contact 가 지속되는 동안만 발생. 자유 비행은 angularDamping 으로 즉시 죽음.
    static func resolveBoundsCollision(_ pills: inout [PillBody], in bounds: CGRect) {
        let toDeg = 180.0 / .pi

        for i in pills.indices {
            let r = pills[i].radius * collisionRadiusRatio

            // 1) 침범 처리
            if pills[i].position.x - r < bounds.minX {
                pills[i].position.x = bounds.minX + r
                pills[i].velocity.dx = -pills[i].velocity.dx * restitution
            } else if pills[i].position.x + r > bounds.maxX {
                pills[i].position.x = bounds.maxX - r
                pills[i].velocity.dx = -pills[i].velocity.dx * restitution
            }
            if pills[i].position.y - r < bounds.minY {
                pills[i].position.y = bounds.minY + r
                pills[i].velocity.dy = -pills[i].velocity.dy * restitution
            } else if pills[i].position.y + r > bounds.maxY {
                pills[i].position.y = bounds.maxY - r
                pills[i].velocity.dy = -pills[i].velocity.dy * restitution
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
        }
    }

    /// 알약 간 sphere-sphere 충돌. O(N²) — N ≤ 8 이라 무시 가능.
    /// position push-apart + 침투 중일 때 normal 방향 velocity impulse 교환 (equal mass 가정).
    /// iteration 2회 — 큰 overlap에서 한 번에 안 풀리는 경우 안정화.
    /// gravity 방향 stack(`|n · ĝ| > stackParallelDotThreshold`) 시 perpendicular nudge 적용.
    static func resolvePairCollisions(_ pills: inout [PillBody], gravity: SIMD2<Double>) {
        // gravity 정규화 (크기 너무 작으면 stack-breaking 의미 없으니 skip)
        let gNorm = sqrt(gravity.x * gravity.x + gravity.y * gravity.y)
        let hasGravity = gNorm > 0.1
        let gx = hasGravity ? gravity.x / gNorm : 0
        let gy = hasGravity ? gravity.y / gNorm : 0

        let count = pills.count
        guard count >= 2 else { return }
        for _ in 0 ..< pairCollisionIterations {
            for i in 0 ..< count - 1 {
                for j in (i + 1) ..< count {
                    let dx = pills[j].position.x - pills[i].position.x
                    let dy = pills[j].position.y - pills[i].position.y
                    let dist = sqrt(dx * dx + dy * dy)
                    let minDist = (pills[i].radius + pills[j].radius) * collisionRadiusRatio
                    guard dist > 0, dist < minDist else { continue }
                    let nx = dx / dist
                    let ny = dy / dist

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
                    let impulse = -(1 + pairRestitution) * vRelN * 0.5
                    pills[i].velocity.dx -= impulse * nx
                    pills[i].velocity.dy -= impulse * ny
                    pills[j].velocity.dx += impulse * nx
                    pills[j].velocity.dy += impulse * ny
                }
            }
        }
    }
}
