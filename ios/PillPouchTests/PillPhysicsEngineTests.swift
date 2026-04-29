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
        // gravity 0 이라 damping 만 적용. 100 * 0.92 = 92.
        #expect(abs(pills[0].velocity.dx - 92) < 0.01)
    }

    @Test func 중력_없을때_60틱_후_velocity_거의_0() {
        var pills = [PillBody(categoryKey: "magnesium", position: .init(x: 100, y: 100), velocity: .init(dx: 100, dy: 100), radius: 22)]
        for _ in 0 ..< 60 {
            PillPhysicsEngine.tick(
                dt: 1.0 / 60.0,
                gravity: SIMD2(0, 0),
                bounds: CGRect(x: 0, y: 0, width: 1000, height: 1000),
                pills: &pills
            )
        }
        // 100 * 0.92^60 ≈ 0.69 — 사실상 정지에 가까움
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
        // velocity는 damping 먼저 적용 → 60 * 0.92 = 55.2. position 변화 = 55.2 * (1/60) = 0.92.
        #expect(abs(pills[0].position.x - 100.92) < 0.01)
        #expect(pills[0].position.y == 100)
    }
}

@Suite struct PillPhysicsEngineBoundsCollisionTests {
    private let bounds = CGRect(x: 0, y: 0, width: 200, height: 400)

    @Test func 좌측_벽_침범시_안쪽으로_밀어내고_velocity_반사() {
        var pills = [PillBody(categoryKey: "iron", position: .init(x: 5, y: 100), velocity: .init(dx: -50, dy: 0), radius: 22)]
        // collision 이전 r = radius * 0.5 = 11. position.x - r = -6 < bounds.minX(0).
        PillPhysicsEngine.resolveBoundsCollision(&pills, in: bounds)
        #expect(pills[0].position.x == 11)  // bounds.minX + r
        #expect(pills[0].velocity.dx == 15) // -(-50) * 0.3 = 15 (반사 + 30% 감쇠)
    }

    @Test func 우측_벽_침범시_안쪽으로_밀어내고_velocity_반사() {
        var pills = [PillBody(categoryKey: "iron", position: .init(x: 195, y: 100), velocity: .init(dx: 50, dy: 0), radius: 22)]
        PillPhysicsEngine.resolveBoundsCollision(&pills, in: bounds)
        #expect(pills[0].position.x == 189) // bounds.maxX - r = 200 - 11
        #expect(pills[0].velocity.dx == -15) // -50 * 0.3 = -15
    }

    @Test func 하단_벽_침범시_위로_밀어내고_velocity_반사() {
        var pills = [PillBody(categoryKey: "iron", position: .init(x: 100, y: 395), velocity: .init(dx: 0, dy: 50), radius: 22)]
        PillPhysicsEngine.resolveBoundsCollision(&pills, in: bounds)
        #expect(pills[0].position.y == 389) // bounds.maxY - r
        #expect(pills[0].velocity.dy == -15)
    }

    @Test func 상단_벽_침범시_아래로_밀어내고_velocity_반사() {
        var pills = [PillBody(categoryKey: "iron", position: .init(x: 100, y: 5), velocity: .init(dx: 0, dy: -50), radius: 22)]
        PillPhysicsEngine.resolveBoundsCollision(&pills, in: bounds)
        #expect(pills[0].position.y == 11) // bounds.minY + r
        #expect(pills[0].velocity.dy == 15)
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
        // gScale 40 + damping 0.92 조합의 terminal velocity 가 ~8.3pt/s 라
        // "살짝" 흔들림 의도. 시작 350 (바닥에서 39pt 위) + 30초 시뮬로 정착 확인.
        var pills = [PillBody(categoryKey: "lutein", position: .init(x: 100, y: 350), radius: 22)]
        for _ in 0 ..< 1800 {
            PillPhysicsEngine.tick(
                dt: 1.0 / 60.0,
                gravity: SIMD2(0, 1),
                bounds: bounds,
                pills: &pills
            )
        }
        // 알약은 봉지 바닥(maxY - r = 389) 부근에 정착
        #expect(pills[0].position.y > 380)
        #expect(pills[0].position.y <= 389)
    }
}

@Suite struct PillPhysicsEnginePairCollisionTests {
    @Test func 두_알약이_겹치면_분리된다() {
        var pills = [
            PillBody(categoryKey: "vitaminD", position: .init(x: 100, y: 100), radius: 22),
            PillBody(categoryKey: "vitaminC", position: .init(x: 105, y: 100), radius: 22),
        ]
        let dist0 = pills[1].position.x - pills[0].position.x
        PillPhysicsEngine.resolvePairCollisions(&pills)
        let dist1 = pills[1].position.x - pills[0].position.x
        #expect(dist1 > dist0)
    }

    @Test func 멀리_떨어진_알약은_변화_없음() {
        var pills = [
            PillBody(categoryKey: "vitaminD", position: .init(x: 50, y: 100), radius: 22),
            PillBody(categoryKey: "vitaminC", position: .init(x: 200, y: 100), radius: 22),
        ]
        let snapshot = pills.map(\.position)
        PillPhysicsEngine.resolvePairCollisions(&pills)
        #expect(pills[0].position == snapshot[0])
        #expect(pills[1].position == snapshot[1])
    }

    @Test func 한_개만_있으면_변화_없음() {
        var pills = [PillBody(categoryKey: "omega3", position: .init(x: 100, y: 100), radius: 22)]
        let snapshot = pills[0]
        PillPhysicsEngine.resolvePairCollisions(&pills)
        #expect(pills[0].position == snapshot.position)
    }

    @Test func 정확히_같은_위치에_있으면_dist_0_가드로_안전() {
        var pills = [
            PillBody(categoryKey: "vitaminD", position: .init(x: 100, y: 100), radius: 22),
            PillBody(categoryKey: "vitaminC", position: .init(x: 100, y: 100), radius: 22),
        ]
        PillPhysicsEngine.resolvePairCollisions(&pills)
        // dist == 0 가드로 nan/inf 분리 없이 그대로 둠
        #expect(pills[0].position.x == 100)
        #expect(pills[1].position.x == 100)
    }
}
