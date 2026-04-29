//
//  PillPhysicsEngineTests.swift
//  PillPouchTests
//

import Testing
import CoreGraphics
import Foundation
@testable import PillPouch

@Suite struct PillPhysicsEngineGravityTests {
    @Test func 중력벡터가_velocity에_누적된다() {
        var pills = [PillBody(categoryKey: "vitaminD", position: .init(x: 100, y: 100), radius: 22)]
        PillPhysicsEngine.tick(
            dt: 1.0 / 60.0,
            gravity: SIMD2(0, 1),
            bounds: CGRect(x: 0, y: 0, width: 200, height: 400),
            pills: &pills
        )
        // (gravity.y * gScale * dt) * damping = (1 * 40 * 1/60) * 0.92 ≈ 0.613
        #expect(pills[0].velocity.dy > 0)
        #expect(pills[0].velocity.dx == 0)
    }

    @Test func 중력_x축만_있으면_velocity_x만_증가() {
        var pills = [PillBody(categoryKey: "omega3", position: .init(x: 100, y: 100), radius: 22)]
        PillPhysicsEngine.tick(
            dt: 1.0 / 60.0,
            gravity: SIMD2(1, 0),
            bounds: CGRect(x: 0, y: 0, width: 200, height: 400),
            pills: &pills
        )
        #expect(pills[0].velocity.dx > 0)
        #expect(pills[0].velocity.dy == 0)
    }

    @Test func dt_0이면_상태_변화_없음() {
        var pills = [PillBody(categoryKey: "iron", position: .init(x: 100, y: 100), velocity: .init(dx: 5, dy: 5), radius: 22)]
        let snapshot = pills[0]
        PillPhysicsEngine.tick(
            dt: 0,
            gravity: SIMD2(0, 1),
            bounds: CGRect(x: 0, y: 0, width: 200, height: 400),
            pills: &pills
        )
        #expect(pills[0].position == snapshot.position)
        #expect(pills[0].velocity.dx == snapshot.velocity.dx)
        #expect(pills[0].velocity.dy == snapshot.velocity.dy)
    }

    @Test func 빈_배열은_crash_없이_통과() {
        var pills: [PillBody] = []
        PillPhysicsEngine.tick(
            dt: 1.0 / 60.0,
            gravity: SIMD2(0, 1),
            bounds: CGRect(x: 0, y: 0, width: 200, height: 400),
            pills: &pills
        )
        #expect(pills.isEmpty)
    }
}

@Suite struct PillPhysicsEngineDampingTests {
    @Test func damping이_매_tick_velocity를_감소시킨다() {
        var pills = [PillBody(categoryKey: "calcium", position: .init(x: 100, y: 100), velocity: .init(dx: 100, dy: 0), radius: 22)]
        PillPhysicsEngine.tick(
            dt: 1.0 / 60.0,
            gravity: SIMD2(0, 0),
            bounds: CGRect(x: 0, y: 0, width: 200, height: 400),
            pills: &pills
        )
        // gravity 0 이라 damping 만 적용. 100 * 0.95 = 95.
        #expect(abs(pills[0].velocity.dx - 95) < 0.01)
    }

    @Test func 중력_없을때_120틱_후_velocity_거의_0() {
        var pills = [PillBody(categoryKey: "magnesium", position: .init(x: 100, y: 100), velocity: .init(dx: 100, dy: 100), radius: 22)]
        for _ in 0 ..< 120 {
            PillPhysicsEngine.tick(
                dt: 1.0 / 60.0,
                gravity: SIMD2(0, 0),
                bounds: CGRect(x: 0, y: 0, width: 1000, height: 1000),
                pills: &pills
            )
        }
        // 100 * 0.95^120 ≈ 0.21 — 사실상 정지에 가까움
        #expect(abs(pills[0].velocity.dx) < 1.0)
        #expect(abs(pills[0].velocity.dy) < 1.0)
    }
}

@Suite struct PillPhysicsEngineIntegrationTests {
    @Test func velocity가_dt만큼_position에_적용된다() {
        var pills = [PillBody(categoryKey: "zinc", position: .init(x: 100, y: 100), velocity: .init(dx: 60, dy: 0), radius: 22)]
        PillPhysicsEngine.tick(
            dt: 1.0 / 60.0,
            gravity: SIMD2(0, 0),
            bounds: CGRect(x: 0, y: 0, width: 1000, height: 1000),
            pills: &pills
        )
        // velocity 는 damping 먼저 적용 → 60 * 0.95 = 57. position 변화 = 57 * (1/60) = 0.95.
        #expect(abs(pills[0].position.x - 100.95) < 0.01)
        #expect(pills[0].position.y == 100)
    }
}

@Suite struct PillPhysicsEngineBoundsCollisionTests {
    private let bounds = CGRect(x: 0, y: 0, width: 200, height: 400)

    @Test func 좌측_벽_침범시_안쪽으로_밀어내고_velocity_반사() {
        var pills = [PillBody(categoryKey: "iron", position: .init(x: 5, y: 100), velocity: .init(dx: -50, dy: 0), radius: 22)]
        // collision r = radius * 0.6 = 13.2. position.x - r = -8.2 < bounds.minX(0).
        PillPhysicsEngine.resolveBoundsCollision(&pills, in: bounds)
        #expect(abs(pills[0].position.x - 13.2) < 0.001)  // bounds.minX + r
        #expect(pills[0].velocity.dx == 10) // -(-50) * 0.2 = 10 (반사 + 80% 감쇠)
    }

    @Test func 우측_벽_침범시_안쪽으로_밀어내고_velocity_반사() {
        var pills = [PillBody(categoryKey: "iron", position: .init(x: 195, y: 100), velocity: .init(dx: 50, dy: 0), radius: 22)]
        PillPhysicsEngine.resolveBoundsCollision(&pills, in: bounds)
        #expect(abs(pills[0].position.x - 186.8) < 0.001) // bounds.maxX - r = 200 - 13.2
        #expect(pills[0].velocity.dx == -10)
    }

    @Test func 하단_벽_침범시_위로_밀어내고_velocity_반사() {
        var pills = [PillBody(categoryKey: "iron", position: .init(x: 100, y: 395), velocity: .init(dx: 0, dy: 50), radius: 22)]
        PillPhysicsEngine.resolveBoundsCollision(&pills, in: bounds)
        #expect(abs(pills[0].position.y - 386.8) < 0.001) // bounds.maxY - r
        #expect(pills[0].velocity.dy == -10)
    }

    @Test func 상단_벽_침범시_아래로_밀어내고_velocity_반사() {
        var pills = [PillBody(categoryKey: "iron", position: .init(x: 100, y: 5), velocity: .init(dx: 0, dy: -50), radius: 22)]
        PillPhysicsEngine.resolveBoundsCollision(&pills, in: bounds)
        #expect(abs(pills[0].position.y - 13.2) < 0.001) // bounds.minY + r
        #expect(pills[0].velocity.dy == 10)
    }

    @Test func 벽_안에_안전하게_있으면_상태_변화_없음() {
        var pills = [PillBody(categoryKey: "iron", position: .init(x: 100, y: 200), velocity: .init(dx: 10, dy: 10), radius: 22)]
        PillPhysicsEngine.resolveBoundsCollision(&pills, in: bounds)
        #expect(pills[0].position.x == 100)
        #expect(pills[0].position.y == 200)
        #expect(pills[0].velocity.dx == 10)
        #expect(pills[0].velocity.dy == 10)
    }

    @Test func 지속_중력_장시간_시뮬레이션_후_바닥_위에_정착() {
        // gScale 250 + damping 0.92 조합의 terminal velocity ~52pt/s.
        // restitution 0.3 으로 첫 바닥 충돌 후 살짝 튀어오름 — 정착까지 10초 시뮬.
        var pills = [PillBody(categoryKey: "lutein", position: .init(x: 100, y: 100), radius: 22)]
        for _ in 0 ..< 600 {
            PillPhysicsEngine.tick(
                dt: 1.0 / 60.0,
                gravity: SIMD2(0, 1),
                bounds: bounds,
                pills: &pills
            )
        }
        // 알약은 봉지 바닥(maxY - r = 386.8) 부근에 정착
        #expect(pills[0].position.y > 380)
        #expect(pills[0].position.y <= 387)
    }
}

@Suite struct PillPhysicsEnginePairCollisionTests {
    @Test func 두_알약이_겹치면_분리된다() {
        var pills = [
            PillBody(categoryKey: "vitaminD", position: .init(x: 100, y: 100), radius: 22),
            PillBody(categoryKey: "vitaminC", position: .init(x: 105, y: 100), radius: 22),
        ]
        let dist0 = pills[1].position.x - pills[0].position.x
        PillPhysicsEngine.resolvePairCollisions(&pills, gravity: SIMD2(0, 1))
        let dist1 = pills[1].position.x - pills[0].position.x
        #expect(dist1 > dist0)
    }

    @Test func 멀리_떨어진_알약은_변화_없음() {
        var pills = [
            PillBody(categoryKey: "vitaminD", position: .init(x: 50, y: 100), radius: 22),
            PillBody(categoryKey: "vitaminC", position: .init(x: 200, y: 100), radius: 22),
        ]
        let snapshot = pills.map(\.position)
        PillPhysicsEngine.resolvePairCollisions(&pills, gravity: SIMD2(0, 1))
        #expect(pills[0].position == snapshot[0])
        #expect(pills[1].position == snapshot[1])
    }

    @Test func 한_개만_있으면_변화_없음() {
        var pills = [PillBody(categoryKey: "omega3", position: .init(x: 100, y: 100), radius: 22)]
        let snapshot = pills[0]
        PillPhysicsEngine.resolvePairCollisions(&pills, gravity: SIMD2(0, 1))
        #expect(pills[0].position == snapshot.position)
    }

    @Test func 정확히_같은_위치에_있으면_dist_0_가드로_안전() {
        var pills = [
            PillBody(categoryKey: "vitaminD", position: .init(x: 100, y: 100), radius: 22),
            PillBody(categoryKey: "vitaminC", position: .init(x: 100, y: 100), radius: 22),
        ]
        PillPhysicsEngine.resolvePairCollisions(&pills, gravity: SIMD2(0, 1))
        // dist == 0 가드로 nan/inf 분리 없이 그대로 둠
        #expect(pills[0].position.x == 100)
        #expect(pills[1].position.x == 100)
    }

    @Test func 정면_충돌_시_velocity가_교환된다() {
        // 두 알약이 정면 충돌. 좌측은 +x로, 우측은 -x로 진행 → 침투. impulse로 부호 반전 + 0.7 감쇠.
        var pills = [
            PillBody(categoryKey: "vitaminD", position: .init(x: 100, y: 100), velocity: .init(dx: 50, dy: 0), radius: 22),
            PillBody(categoryKey: "vitaminC", position: .init(x: 110, y: 100), velocity: .init(dx: -50, dy: 0), radius: 22),
        ]
        PillPhysicsEngine.resolvePairCollisions(&pills, gravity: SIMD2(0, 1))
        // 좌측 pill velocity는 양수→음수 (튕김), 우측은 음수→양수
        #expect(pills[0].velocity.dx < 0)
        #expect(pills[1].velocity.dx > 0)
    }

    @Test func 서로_멀어지는_중이면_velocity_교환_없음() {
        // 침투 중이지만 v_rel · n > 0 (서로 멀어지는 중) — impulse 적용 X. position만 분리.
        var pills = [
            PillBody(categoryKey: "vitaminD", position: .init(x: 100, y: 100), velocity: .init(dx: -10, dy: 0), radius: 22),
            PillBody(categoryKey: "vitaminC", position: .init(x: 110, y: 100), velocity: .init(dx: 10, dy: 0), radius: 22),
        ]
        PillPhysicsEngine.resolvePairCollisions(&pills, gravity: SIMD2(0, 1))
        // velocity 부호 그대로 유지 (impulse 적용 X). 수평 stack(nx=1)이라 stack-breaking 미적용.
        #expect(pills[0].velocity.dx == -10)
        #expect(pills[1].velocity.dx == 10)
    }

    @Test func gravity_아래_방향_시_수직_stack_horizontal_kick() {
        // gravity (0,1) 에서 위/아래 stack → perpendicular(±x) 방향 nudge.
        var pills = [
            PillBody(categoryKey: "vitaminD", position: .init(x: 100, y: 100), radius: 22),
            PillBody(categoryKey: "vitaminC", position: .init(x: 100, y: 120), radius: 22),
        ]
        PillPhysicsEngine.resolvePairCollisions(&pills, gravity: SIMD2(0, 1))
        // x 방향 반대 부호 nudge, y 방향은 거의 0
        #expect(pills[0].velocity.dx != 0)
        #expect(pills[1].velocity.dx != 0)
        #expect((pills[0].velocity.dx * pills[1].velocity.dx) < 0)
        #expect(abs(pills[0].velocity.dy) < 0.001)
        #expect(abs(pills[1].velocity.dy) < 0.001)
    }

    @Test func gravity_좌측_방향_시_수평_stack_vertical_kick() {
        // gravity (-1,0) 에서 좌우 stack(좌측 벽 따라 column) → perpendicular(±y) 방향 nudge.
        var pills = [
            PillBody(categoryKey: "vitaminD", position: .init(x: 100, y: 100), radius: 22),
            PillBody(categoryKey: "vitaminC", position: .init(x: 120, y: 100), radius: 22),
        ]
        PillPhysicsEngine.resolvePairCollisions(&pills, gravity: SIMD2(-1, 0))
        // y 방향 반대 부호 nudge, x 방향은 거의 0
        #expect(pills[0].velocity.dy != 0)
        #expect(pills[1].velocity.dy != 0)
        #expect((pills[0].velocity.dy * pills[1].velocity.dy) < 0)
        #expect(abs(pills[0].velocity.dx) < 0.001)
        #expect(abs(pills[1].velocity.dx) < 0.001)
    }

    @Test func gravity_대각_방향_시_perpendicular_nudge() {
        // gravity (1,1) 정규화 (0.707, 0.707) 방향 stack → perpendicular (-0.707, 0.707) nudge.
        // 알약 (100,100) 과 (115.55, 115.55) 거리 ~22 < minDist 26.4 → 침투.
        var pills = [
            PillBody(categoryKey: "vitaminD", position: .init(x: 100, y: 100), radius: 22),
            PillBody(categoryKey: "vitaminC", position: .init(x: 115.55, y: 115.55), radius: 22),
        ]
        PillPhysicsEngine.resolvePairCollisions(&pills, gravity: SIMD2(1, 1))
        // dx, dy 모두 0이 아니고 부호 반대 (perpendicular 방향)
        #expect(pills[0].velocity.dx != 0)
        #expect(pills[0].velocity.dy != 0)
        // perpendicular = (-gy, gx) = (-0.707, 0.707) — dx 와 dy 부호 반대
        #expect((pills[0].velocity.dx * pills[0].velocity.dy) < 0)
    }

    @Test func gravity_방향과_normal이_perpendicular면_stack_breaking_미적용() {
        // gravity (0,1), 알약 수평 정렬 (nx=1) → normal · gravity = 0 → stack 아님.
        var pills = [
            PillBody(categoryKey: "vitaminD", position: .init(x: 100, y: 100), velocity: .init(dx: 0, dy: 0), radius: 22),
            PillBody(categoryKey: "vitaminC", position: .init(x: 110, y: 100), velocity: .init(dx: 0, dy: 0), radius: 22),
        ]
        PillPhysicsEngine.resolvePairCollisions(&pills, gravity: SIMD2(0, 1))
        // velocity 변화 없음 (elastic 미적용 + stack-breaking 미적용)
        #expect(pills[0].velocity.dx == 0)
        #expect(pills[0].velocity.dy == 0)
        #expect(pills[1].velocity.dx == 0)
        #expect(pills[1].velocity.dy == 0)
    }

    @Test func gravity가_거의_0이면_stack_breaking_미적용() {
        // gravity 거의 0 — stack 의미 없음, nudge 없음.
        var pills = [
            PillBody(categoryKey: "vitaminD", position: .init(x: 100, y: 100), radius: 22),
            PillBody(categoryKey: "vitaminC", position: .init(x: 100, y: 120), radius: 22),
        ]
        PillPhysicsEngine.resolvePairCollisions(&pills, gravity: SIMD2(0, 0.05))
        // velocity 변화 없음
        #expect(pills[0].velocity.dx == 0)
        #expect(pills[1].velocity.dx == 0)
    }

    @Test func 대각_gravity_와_wall_aligned_stack도_catch() {
        // gravity (1,1) 정규화 (0.707, 0.707). normal 수직(0,1)과 dot = 0.707.
        // threshold 0.7 미만이 아니라 (0.7 <)이라 stack 으로 catch — corner 에 모인
        // 알약이 wall 따라 vertical 또는 horizontal 정렬해도 nudge 발생.
        var pills = [
            PillBody(categoryKey: "vitaminD", position: .init(x: 100, y: 100), radius: 22),
            PillBody(categoryKey: "vitaminC", position: .init(x: 100, y: 120), radius: 22),
        ]
        PillPhysicsEngine.resolvePairCollisions(&pills, gravity: SIMD2(1, 1))
        // nudge 발생 — 양쪽 모두 dx, dy 변화
        #expect(pills[0].velocity.dx != 0 || pills[0].velocity.dy != 0)
        #expect(pills[1].velocity.dx != 0 || pills[1].velocity.dy != 0)
    }
}

@Suite struct PillPhysicsEngineRotationTests {
    @Test func angularVelocity가_매_tick_rotation에_누적된다() {
        var pills = [PillBody(categoryKey: "vitaminD", position: .init(x: 100, y: 100), radius: 22, angularVelocity: 60)]
        PillPhysicsEngine.tick(
            dt: 1.0 / 60.0,
            gravity: SIMD2(0, 0),
            bounds: CGRect(x: 0, y: 0, width: 1000, height: 1000),
            pills: &pills
        )
        // rotation += 60 * (1/60) = 1.0 (deg)
        #expect(abs(pills[0].rotation - 1.0) < 0.001)
    }

    @Test func angularDamping이_angularVelocity를_감쇠시킨다() {
        var pills = [PillBody(categoryKey: "vitaminD", position: .init(x: 100, y: 100), radius: 22, angularVelocity: 100)]
        PillPhysicsEngine.tick(
            dt: 1.0 / 60.0,
            gravity: SIMD2(0, 0),
            bounds: CGRect(x: 0, y: 0, width: 1000, height: 1000),
            pills: &pills
        )
        // 100 * 0.80 = 80
        #expect(abs(pills[0].angularVelocity - 80) < 0.001)
    }

    @Test func 좌측_벽_contact_시_target_omega로_lerp() {
        // 좌측 벽 contact: target ω = dy / radius * (180/π). dy=30, r=22 → target ≈ 78.13.
        // 시작 ω=0, lerp 0.3 → 0 + (78.13 - 0) * 0.3 ≈ 23.44.
        var pills = [PillBody(categoryKey: "iron", position: .init(x: 5, y: 100), velocity: .init(dx: -50, dy: 30), radius: 22)]
        PillPhysicsEngine.resolveBoundsCollision(&pills, in: CGRect(x: 0, y: 0, width: 200, height: 400))
        let expected = 30.0 / 22.0 * (180.0 / .pi) * 0.3
        #expect(abs(pills[0].angularVelocity - expected) < 0.001)
    }

    @Test func 우측_벽_contact_시_반대_부호_target() {
        // 우측 벽: target ω = -dy / r. dy=30 → target ≈ -78.13. lerp 0.3 → ≈ -23.44.
        var pills = [PillBody(categoryKey: "iron", position: .init(x: 195, y: 100), velocity: .init(dx: 50, dy: 30), radius: 22)]
        PillPhysicsEngine.resolveBoundsCollision(&pills, in: CGRect(x: 0, y: 0, width: 200, height: 400))
        let expected = -30.0 / 22.0 * (180.0 / .pi) * 0.3
        #expect(abs(pills[0].angularVelocity - expected) < 0.001)
    }

    @Test func 좌측_벽_지속_contact_시_target_omega로_수렴() {
        // 알약을 좌측 벽에 붙인 채 dy=66 으로 미끄러짐. 30 tick 반복 후 거의 target 도달.
        // target = 66/22 * 57.3 ≈ 171.9 deg/s
        var pills = [PillBody(categoryKey: "iron", position: .init(x: 13.2, y: 100), velocity: .init(dx: 0, dy: 66), radius: 22)]
        for _ in 0 ..< 30 {
            PillPhysicsEngine.resolveBoundsCollision(&pills, in: CGRect(x: 0, y: 0, width: 200, height: 400))
            // angularDamping 만 적용 (자유 비행 시 ω 죽음 — 하지만 contact 매 tick lerp 이라 유지)
            pills[0].angularVelocity *= PillPhysicsEngine.angularDamping
        }
        let target = 66.0 / 22.0 * (180.0 / .pi)
        // damping 까지 같이 작용하니 정확한 target 은 아니지만 부호 + magnitude 큰 값
        #expect(pills[0].angularVelocity > target * 0.3)
        #expect(pills[0].angularVelocity < target)
    }

    @Test func 자유_비행_시_wall_contact_없으면_lerp_미적용() {
        // 봉지 가운데에 있는 알약 — 어느 벽도 contact X. ω 변화 없음 (damping 만).
        var pills = [PillBody(categoryKey: "vitaminD", position: .init(x: 100, y: 200), velocity: .init(dx: 50, dy: 50), radius: 22, angularVelocity: 100)]
        PillPhysicsEngine.resolveBoundsCollision(&pills, in: CGRect(x: 0, y: 0, width: 200, height: 400))
        // ω 변화 없음 (lerp 미적용)
        #expect(pills[0].angularVelocity == 100)
    }

    @Test func 스쳐_지나가는_충돌시_양쪽_반대_부호_spin() {
        // 두 알약이 normal 따라 정면 충돌 X — tangent 방향으로 상대 이동
        var pills = [
            PillBody(categoryKey: "vitaminD", position: .init(x: 100, y: 100), velocity: .init(dx: 0, dy: 50), radius: 22),
            PillBody(categoryKey: "vitaminC", position: .init(x: 110, y: 100), velocity: .init(dx: 0, dy: -50), radius: 22),
        ]
        PillPhysicsEngine.resolvePairCollisions(&pills, gravity: SIMD2(0, 1))
        // tangent 방향 상대 속도가 있으니 양쪽 angular 반대 부호 (pairSpinTransfer 0.3)
        #expect(pills[0].angularVelocity != 0)
        #expect(pills[1].angularVelocity != 0)
        #expect((pills[0].angularVelocity * pills[1].angularVelocity) < 0)
    }
}
