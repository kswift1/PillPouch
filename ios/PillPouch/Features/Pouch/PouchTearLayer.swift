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

    // MARK: - Style 1: Lift (PaperLayer 의 JaggedTearPath mask 가 jagged 단면 표현 — TearLayer 는 빈 view)

    @ViewBuilder
    private var liftView: some View {
        Color.clear
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

/// PaperTop / PaperBottom 의 mask 로 사용 — 양쪽이 같은 seed 로 같은 jagged
/// 단면을 공유해 위/아래가 정확히 맞물림. progress 비율만큼 jagged 진행 후
/// 나머지 구간은 perforation Y 직선 (아직 안 찢긴 부분).
struct JaggedTearPath: Shape {
    var progress: Double
    let perforationY: CGFloat
    let inset: CGFloat
    let region: Region
    let seed: UInt64

    enum Region { case top, bottom }

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let usableWidth = max(0, w - inset * 2)
        let endX = inset + usableWidth * CGFloat(max(0, min(1, progress)))

        // jagged 점 생성 — deterministic
        var rng = JaggedRNG(seed: seed)
        var jagged: [CGPoint] = []
        var x = inset
        var step = 0
        let basePeriod: CGFloat = 6
        let baseAmp: CGFloat = 3.5
        while x < endX {
            let periodJitter = 0.6 + rng.next() * 0.8   // 0.6 ~ 1.4
            let nextX = min(x + basePeriod * CGFloat(periodJitter), endX)
            let ampJitter = 0.35 + rng.next() * 0.95    // 0.35 ~ 1.30
            let direction: CGFloat = step.isMultiple(of: 2) ? 1 : -1
            let yOff = baseAmp * CGFloat(ampJitter) * direction
            jagged.append(CGPoint(x: nextX, y: perforationY + yOff))
            x = nextX
            step += 1
        }

        // 좌→우 boundary
        var boundary: [CGPoint] = []
        boundary.append(CGPoint(x: 0, y: perforationY))
        boundary.append(CGPoint(x: inset, y: perforationY))
        boundary.append(contentsOf: jagged)
        boundary.append(CGPoint(x: endX, y: perforationY))
        boundary.append(CGPoint(x: w - inset, y: perforationY))
        boundary.append(CGPoint(x: w, y: perforationY))

        var p = Path()
        switch region {
        case .top:
            p.move(to: CGPoint(x: 0, y: 0))
            p.addLine(to: CGPoint(x: w, y: 0))
            for pt in boundary.reversed() {
                p.addLine(to: pt)
            }
            p.closeSubpath()
        case .bottom:
            p.move(to: CGPoint(x: 0, y: h))
            p.addLine(to: CGPoint(x: 0, y: perforationY))
            for pt in boundary {
                p.addLine(to: pt)
            }
            p.addLine(to: CGPoint(x: w, y: h))
            p.closeSubpath()
        }
        return p
    }
}

/// xorshift 기반 deterministic RNG. 같은 seed → 같은 sequence.
struct JaggedRNG {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 0xDEADBEEF : seed }
    mutating func next() -> Double {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return Double(state >> 11) / Double(1 << 53)
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
