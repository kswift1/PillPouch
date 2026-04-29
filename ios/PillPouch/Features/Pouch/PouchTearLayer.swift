//
//  PouchTearLayer.swift
//  PillPouch
//

import SwiftUI

/// 찢김 시각 — 두 가지 스타일 비교용. ShowcaseView Picker 로 토글.
/// - `.lift`: 봉지 위쪽 조각이 들려 회전 (PaperLayer 복제본 + transform)
/// - `.gap`: perforation 라인에 벌어진 틈이 좌→우 열림 (위/아래 jagged edge)
struct PouchTearLayer: View {
    let state: PouchState
    let slot: TimeSlot
    let style: TearStyle

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        switch style {
        case .lift: liftView
        case .gap:  gapView
        }
    }

    // MARK: - Style 1: Lift (PaperLayer 분리는 PouchView 가 처리, 여기는 본체 측 jagged edge 만)

    @ViewBuilder
    private var liftView: some View {
        GeometryReader { geo in
            if let progress = activeProgress() {
                let y = PouchView.perforationY(in: geo.size)
                ZigZagEdge(progress: progress, y: y, inset: Const.inset, amplitude: Const.jaggedAmplitude)
                    .stroke(edgeColor.opacity(0.55), lineWidth: Const.lineWidth)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Style 2: Gap (벌어진 틈 좌→우 열림)

    @ViewBuilder
    private var gapView: some View {
        GeometryReader { geo in
            if let progress = activeProgress() {
                let y = PouchView.perforationY(in: geo.size)
                let inset = Const.inset
                let usableWidth = max(0, geo.size.width - inset * 2)
                let gapWidth = usableWidth * CGFloat(progress)
                let gapHeight: CGFloat = CGFloat(progress) * Const.gapMaxHeight

                ZStack {
                    // 벌어진 틈 — 안쪽 어두움
                    Rectangle()
                        .fill(gapInnerColor)
                        .frame(width: gapWidth, height: gapHeight)
                        .position(x: inset + gapWidth / 2, y: y)
                        .allowsHitTesting(false)

                    // 위/아래 jagged edge
                    ZigZagEdge(progress: progress, y: y - gapHeight / 2, inset: inset, amplitude: Const.jaggedAmplitude)
                        .stroke(edgeColor, lineWidth: Const.lineWidth)
                        .allowsHitTesting(false)
                    ZigZagEdge(progress: progress, y: y + gapHeight / 2, inset: inset, amplitude: Const.jaggedAmplitude)
                        .stroke(edgeColor, lineWidth: Const.lineWidth)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    // MARK: - Helpers

    private func activeProgress() -> Double? {
        switch state {
        case .sealed: return nil
        case .tearing(let p): return p
        case .torn: return 1.0
        }
    }

    private var edgeColor: Color {
        scheme == .dark ? Color.white.opacity(0.55) : Color.black.opacity(0.45)
    }

    private var gapInnerColor: Color {
        scheme == .dark ? Color.black.opacity(0.55) : Color.black.opacity(0.18)
    }

    private enum Const {
        static let inset: CGFloat = 16
        static let lineWidth: CGFloat = 1.0
        static let jaggedAmplitude: CGFloat = 3
        static let liftMaxDistance: CGFloat = 8
        static let liftMaxAngle: Double = 6
        static let gapMaxHeight: CGFloat = 5
    }
}

/// 좌→우 zigzag — `progress` 비율만큼 path 그림. amplitude 가변.
private struct ZigZagEdge: Shape {
    var progress: Double
    let y: CGFloat
    let inset: CGFloat
    let amplitude: CGFloat

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let usableWidth = max(0, rect.width - inset * 2)
        let endX = inset + usableWidth * CGFloat(max(0, min(1, progress)))
        let halfPeriod: CGFloat = 6

        var x = inset
        var step = 0
        p.move(to: CGPoint(x: x, y: y))
        while x < endX {
            let nextX = min(x + halfPeriod, endX)
            let dy = step.isMultiple(of: 2) ? amplitude : -amplitude
            p.addLine(to: CGPoint(x: nextX, y: y + dy))
            x = nextX
            step += 1
        }
        return p
    }
}

/// 찢기 시각 스타일 비교용. Showcase Picker 로 토글.
enum TearStyle: String, CaseIterable, Identifiable {
    /// 봉지 위쪽 조각이 들리며 회전. PaperLayer 복제본 + transform.
    case lift
    /// perforation 라인에 벌어진 틈이 좌→우 열림. 위/아래 jagged edge.
    case gap

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .lift: "Lift"
        case .gap:  "Gap"
        }
    }
}

#Preview("Tear · Lift · 50%") {
    PouchTearLayer(state: .tearing(progress: 0.5), slot: .morning, style: .lift)
        .frame(width: 240, height: 320)
        .background(.gray.opacity(0.1))
}

#Preview("Tear · Gap · 50%") {
    PouchTearLayer(state: .tearing(progress: 0.5), slot: .morning, style: .gap)
        .frame(width: 240, height: 320)
        .background(.gray.opacity(0.1))
}
