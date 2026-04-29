//
//  PouchTearLayer.swift
//  PillPouch
//
//  찢김 시각은 PouchPaperTop/Bottom 의 JaggedTearPath mask 가 담당.
//  이 파일은 두 mask 가 공유하는 Shape + RNG 만 보유.
//

import SwiftUI

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
