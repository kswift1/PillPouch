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
    /// 1000이면 gravity=1.0 에서 terminal ~208pt/s, gravity=0.5(일상 기울임)에서도 ~104pt/s
    /// — 봉지 가로(~240pt)를 1~2초에 가로지름.
    static let gScale: Double = 1000

    /// 매 tick 적용되는 속도 감쇠 (1보다 작음). 1초당 0.92 ^ 60 ≈ 0.007 → 정지.
    static let damping: Double = 0.92

    /// 벽 충돌 시 반사 계수 (0~1). 0 = 정지, 1 = 완전 탄성.
    static let restitution: CGFloat = 0.3

    /// 알약 간 충돌 시 position push-apart 비율 (1.0 = 한 번에 완전 분리).
    static let pairSeparation: CGFloat = 1.0

    /// 알약 간 충돌 시 velocity 교환 탄성 계수 (0~1). 0.7 = 탱탱한 알약 충돌.
    static let pairRestitution: CGFloat = 0.7

    /// 시각 frame 대비 충돌 반지름 비율. capsule 가로 자산은 시각 두께가 frame 의 ~50%.
    /// 0.6 으로 두면 시각상 알약끼리 거의 닿은 상태에서 충돌. 1층-2층 여백 자연스러움.
    static let collisionRadiusRatio: CGFloat = 0.6

    /// 큰 overlap에서 안정 분리를 위한 pair collision iteration 횟수.
    static let pairCollisionIterations: Int = 2

    /// 매 tick 회전 감쇠. 0.95 ^ 60 ≈ 0.046 — 1초 후 사실상 정지.
    static let angularDamping: Double = 0.95

    /// pair collision 시 tangential relative velocity → angular velocity 변환 계수 (deg/s per pt/s).
    /// 2.5 면 100pt/s 스침에서 250 deg/s 스핀.
    static let pairSpinTransfer: Double = 2.5

    /// bounds collision 시 벽 평행 velocity → angular velocity (벽 따라 미끄러져 굴러가는 효과).
    /// reflection 전 velocity 기준이라 강한 충돌에서도 spin 명확.
    static let wallSpinTransfer: Double = 1.5

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
        resolvePairCollisions(&pills)
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
    /// 벽과 평행한 velocity 성분(반사 전)은 angular velocity 에 기여 (벽 따라 굴러가는 효과).
    /// 반사 후 velocity 로 계산하면 강한 충돌일수록 spin 이 작아지는 비대칭 발생 — pre-velocity 사용.
    static func resolveBoundsCollision(_ pills: inout [PillBody], in bounds: CGRect) {
        for i in pills.indices {
            let r = pills[i].radius * collisionRadiusRatio
            let preDx = pills[i].velocity.dx
            let preDy = pills[i].velocity.dy
            if pills[i].position.x - r < bounds.minX {
                pills[i].position.x = bounds.minX + r
                pills[i].velocity.dx = -preDx * restitution
                pills[i].angularVelocity += Double(preDy) * wallSpinTransfer
            } else if pills[i].position.x + r > bounds.maxX {
                pills[i].position.x = bounds.maxX - r
                pills[i].velocity.dx = -preDx * restitution
                pills[i].angularVelocity -= Double(preDy) * wallSpinTransfer
            }
            if pills[i].position.y - r < bounds.minY {
                pills[i].position.y = bounds.minY + r
                pills[i].velocity.dy = -preDy * restitution
                pills[i].angularVelocity -= Double(preDx) * wallSpinTransfer
            } else if pills[i].position.y + r > bounds.maxY {
                pills[i].position.y = bounds.maxY - r
                pills[i].velocity.dy = -preDy * restitution
                pills[i].angularVelocity += Double(preDx) * wallSpinTransfer
            }
        }
    }

    /// 알약 간 sphere-sphere 충돌. O(N²) — N ≤ 8 이라 무시 가능.
    /// position push-apart + 침투 중일 때 normal 방향 velocity impulse 교환 (equal mass 가정).
    /// iteration 2회 — 큰 overlap에서 한 번에 안 풀리는 경우 안정화.
    static func resolvePairCollisions(_ pills: inout [PillBody]) {
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
