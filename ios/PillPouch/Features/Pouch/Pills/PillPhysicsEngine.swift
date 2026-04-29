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
    /// 250이면 terminal ~52 pt/s — 봉지(높이 280pt)를 약 1초에 가로지름.
    static let gScale: Double = 250

    /// 매 tick 적용되는 속도 감쇠 (1보다 작음). 1초당 0.92 ^ 60 ≈ 0.007 → 정지.
    static let damping: Double = 0.92

    /// 벽 충돌 시 반사 계수 (0~1). 0 = 정지, 1 = 완전 탄성.
    static let restitution: CGFloat = 0.3

    /// 알약 간 충돌 시 position push-apart 비율 (1.0 = 한 번에 완전 분리).
    static let pairSeparation: CGFloat = 1.0

    /// 알약 간 충돌 시 velocity 교환 탄성 계수 (0~1). 0.7 = 탱탱한 알약 충돌.
    static let pairRestitution: CGFloat = 0.7

    /// 시각 frame 대비 충돌 반지름 비율. 자산이 frame을 거의 가득 채우므로 0.9.
    /// 0.5 면 충돌 반경이 시각 frame의 절반이라 시각상 겹쳐 보임.
    static let collisionRadiusRatio: CGFloat = 0.9

    /// 큰 overlap에서 안정 분리를 위한 pair collision iteration 횟수.
    static let pairCollisionIterations: Int = 2

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

    // MARK: - Collisions

    /// 봉지 내부 사각 영역 충돌. 모서리는 단순 AABB로 근사.
    static func resolveBoundsCollision(_ pills: inout [PillBody], in bounds: CGRect) {
        for i in pills.indices {
            let r = pills[i].radius * collisionRadiusRatio
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

                    // 1D elastic collision along normal (equal mass m=1).
                    // J = -(1 + e) * v_rel · n / (1/m_i + 1/m_j) — 침투 중에만 적용.
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
