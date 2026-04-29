//
//  PouchTearLayer.swift
//  PillPouch
//

import SwiftUI

/// 찢김 시각 — perforation Y 라인 따라 좌→우 zigzag path 가 progress 비율만큼 노출.
/// `.sealed` 일 땐 그리지 않음 (PaperLayer 의 dashed line 만 보임).
/// `.tearing(progress)` 진행도 따라 zigzag 길이 늘어남.
/// `.torn` 일 땐 zigzag full + 윗부분 살짝 어둑한 cut-edge overlay.
struct PouchTearLayer: View {
    let state: PouchState
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        GeometryReader { geo in
            let y = PouchView.perforationY(in: geo.size)
            if let progress = activeProgress() {
                ZigZagTear(progress: progress, y: y, inset: Const.inset)
                    .stroke(strokeColor, lineWidth: Const.lineWidth)
                    .allowsHitTesting(false)
                if progress >= 0.99 {
                    Rectangle()
                        .fill(cutEdgeShade)
                        .frame(height: Const.cutEdgeHeight)
                        .position(x: geo.size.width / 2, y: y - Const.cutEdgeHeight / 2)
                        .blendMode(.multiply)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private func activeProgress() -> Double? {
        switch state {
        case .sealed: return nil
        case .tearing(let p): return p
        case .torn: return 1.0
        }
    }

    private var strokeColor: Color {
        scheme == .dark ? Color.white.opacity(0.55) : Color.black.opacity(0.45)
    }

    private var cutEdgeShade: Color {
        scheme == .dark ? Color.black.opacity(0.30) : Color.black.opacity(0.06)
    }

    private enum Const {
        static let inset: CGFloat = 16
        static let lineWidth: CGFloat = 1.2
        static let cutEdgeHeight: CGFloat = 6
    }
}

/// 좌→우 zigzag — `progress` 비율만큼 path 그림. amplitude 3pt, half-period 6pt.
private struct ZigZagTear: Shape {
    var progress: Double
    let y: CGFloat
    let inset: CGFloat

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let usableWidth = max(0, rect.width - inset * 2)
        let endX = inset + usableWidth * CGFloat(max(0, min(1, progress)))
        let amp: CGFloat = 3
        let halfPeriod: CGFloat = 6

        var x = inset
        var step = 0
        p.move(to: CGPoint(x: x, y: y))
        while x < endX {
            let nextX = min(x + halfPeriod, endX)
            let dy = step.isMultiple(of: 2) ? amp : -amp
            p.addLine(to: CGPoint(x: nextX, y: y + dy))
            x = nextX
            step += 1
        }
        return p
    }
}

#Preview("PouchTearLayer · tearing 50%") {
    PouchTearLayer(state: .tearing(progress: 0.5))
        .frame(width: 240, height: 320)
        .background(.gray.opacity(0.1))
}

#Preview("PouchTearLayer · torn") {
    PouchTearLayer(state: .torn)
        .frame(width: 240, height: 320)
        .background(.gray.opacity(0.1))
}
