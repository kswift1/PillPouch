//
//  PouchView.swift
//  PillPouch
//

import SwiftUI

/// 단일 약봉지 컴포넌트. 플라스틱 봉지 + 알약 + 찢기 인터랙션의 조립체.
/// Stage 3: 알약이 motion gravity 따라 봉지 안에서 움직임. 찢기 Stage 4, 낙하 Stage 5.
struct PouchView: View {
    let state: PouchState
    let slot: TimeSlot
    @Binding var pills: [PillBody]
    /// 화면 좌표계 (x: 우, y: 하) 단위 중력 벡터. ShowcaseView/Today 가 MotionEngine 으로 주입.
    let gravity: SIMD2<Double>

    var body: some View {
        GeometryReader { geo in
            let bounds = PouchView.pillBounds(in: geo.size)
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
                ZStack {
                    ForEach(pills) { pill in
                        PillView(pill: pill)
                    }
                    .opacity(0.96)
                    PouchPaperLayer(slot: slot)
                }
                .onChange(of: context.date) { _, newDate in
                    advancePhysics(to: newDate, bounds: bounds)
                }
            }
        }
    }

    @State private var lastTickDate: Date?

    private func advancePhysics(to newDate: Date, bounds: CGRect) {
        let prev = lastTickDate ?? newDate
        let dt = min(newDate.timeIntervalSince(prev), 1.0 / 30.0) // dt 상한 — 백그라운드 복귀 시 점프 방지
        lastTickDate = newDate
        guard dt > 0 else { return }
        PillPhysicsEngine.tick(dt: dt, gravity: gravity, bounds: bounds, pills: &pills)
    }
}

extension PouchView {
    /// 봉지 안 알약이 위치 가능한 사각 영역 (perforation 아래 ~ 하단 heat-seal 위).
    /// `PouchPaperLayer.Const`와 짝을 맞춰야 함.
    static func pillBounds(in size: CGSize) -> CGRect {
        let topInset: CGFloat = 14 + 38 + 36 + 8 // topSeal + headerCenter + headerDivider + padding
        let bottomInset: CGFloat = 12 + 6        // bottomSeal + padding
        let sideInset: CGFloat = 12
        return CGRect(
            x: sideInset,
            y: topInset,
            width: size.width - sideInset * 2,
            height: size.height - topInset - bottomInset
        )
    }
}

#Preview("Pouch · Morning · light · 5 pills static") {
    StatePreview()
        .frame(width: 240, height: 320)
        .padding(40)
        .background(PPColor.background)
        .preferredColorScheme(.light)
}

private struct StatePreview: View {
    @State private var pills: [PillBody] = {
        let bounds = PouchView.pillBounds(in: CGSize(width: 240, height: 320))
        return PillBody.mock(count: 5, mix: .mixed, bounds: bounds)
    }()
    var body: some View {
        PouchView(state: .sealed, slot: .morning, pills: $pills, gravity: SIMD2(0, 1))
    }
}
