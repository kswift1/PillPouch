//
//  PouchPaperLayer.swift
//  PillPouch
//

import SwiftUI

/// 글라싱지 약봉지 7-layer 합성 (L2~L7, L1 알약은 PouchView가 ZStack 아래에 깔음).
/// 사진(.context/attachments/CleanShot 2026-04-29 at 00.11.55@2x.png) 수준 재현 목표.
struct PouchPaperLayer: View {
    var body: some View {
        ZStack {
            paperBody()
            fiberTexture()
            topPrintBand()
            wrinkleHighlight()
            heatSeal()
            tearMarker()
        }
    }

    private func paperBody() -> some View {
        RoundedRectangle(cornerRadius: Const.cornerRadius, style: .continuous)
            .fill(Color.white.opacity(Const.paperOpacity))
            .overlay(
                RoundedRectangle(cornerRadius: Const.cornerRadius, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.06), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
    }

    private func fiberTexture() -> some View {
        Canvas { ctx, size in
            for i in 0 ..< Const.fiberCount {
                let xRatio = (Double(i) * 0.6180339887).truncatingRemainder(dividingBy: 1.0)
                let yRatio = (Double(i) * 0.4142135623).truncatingRemainder(dividingBy: 1.0)
                let x = xRatio * size.width
                let y = yRatio * size.height
                let length = (sin(Double(i) * 1.7) + 1.5) * 4
                let opacity = (cos(Double(i) * 0.83) + 1) * 0.04 + 0.02
                let path = Path { p in
                    p.move(to: CGPoint(x: x, y: y))
                    p.addLine(to: CGPoint(x: x, y: y + length))
                }
                ctx.stroke(path, with: .color(.black.opacity(opacity)), lineWidth: 0.4)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Const.cornerRadius, style: .continuous))
        .allowsHitTesting(false)
    }

    private func topPrintBand() -> some View {
        GeometryReader { geo in
            let bandHeight = geo.size.height * Const.printBandRatio
            VStack(alignment: .leading, spacing: 4) {
                Text("PillPouch 약국")
                    .font(PPFont.caption.weight(.semibold))
                Text("환자: 사용자")
                    .font(PPFont.caption)
                Text("1일 3회 / 식후 30분")
                    .font(PPFont.caption)
            }
            .foregroundStyle(PPColor.textPrimary.opacity(0.42))
            .padding(.horizontal, PPSpacing.sm)
            .padding(.top, PPSpacing.sm)
            .frame(width: geo.size.width, height: bandHeight, alignment: .topLeading)
            .background(
                Rectangle()
                    .fill(Color.white.opacity(0.10))
                    .frame(height: bandHeight)
                    .frame(maxHeight: .infinity, alignment: .top)
            )
            .overlay(
                Rectangle()
                    .fill(Color.black.opacity(0.08))
                    .frame(height: 0.5)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .offset(y: bandHeight)
            )
        }
        .allowsHitTesting(false)
    }

    private func wrinkleHighlight() -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.white.opacity(0.18),
                    Color.clear,
                    Color.black.opacity(0.04),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            LinearGradient(
                colors: [Color.clear, Color.white.opacity(0.10), Color.clear],
                startPoint: UnitPoint(x: 0.2, y: 0),
                endPoint: UnitPoint(x: 0.4, y: 1)
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: Const.cornerRadius, style: .continuous))
        .allowsHitTesting(false)
    }

    private func heatSeal() -> some View {
        GeometryReader { geo in
            let inset: CGFloat = 4
            let dash: [CGFloat] = [2, 1.5]
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: inset, y: inset))
                    p.addLine(to: CGPoint(x: inset, y: geo.size.height - inset))
                }
                .stroke(Color.black.opacity(0.18), style: StrokeStyle(lineWidth: 0.5, dash: dash))

                Path { p in
                    p.move(to: CGPoint(x: geo.size.width - inset, y: inset))
                    p.addLine(to: CGPoint(x: geo.size.width - inset, y: geo.size.height - inset))
                }
                .stroke(Color.black.opacity(0.18), style: StrokeStyle(lineWidth: 0.5, dash: dash))

                Path { p in
                    p.move(to: CGPoint(x: inset, y: geo.size.height - inset))
                    p.addLine(to: CGPoint(x: geo.size.width - inset, y: geo.size.height - inset))
                }
                .stroke(Color.black.opacity(0.22), style: StrokeStyle(lineWidth: 0.7, dash: dash))
            }
        }
        .allowsHitTesting(false)
    }

    private func tearMarker() -> some View {
        GeometryReader { geo in
            let cutWidth: CGFloat = 12
            let cutDepth: CGFloat = 6
            let cx = geo.size.width - 18
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: cx - cutWidth / 2, y: 0))
                    p.addLine(to: CGPoint(x: cx, y: cutDepth))
                    p.addLine(to: CGPoint(x: cx + cutWidth / 2, y: 0))
                }
                .stroke(Color.black.opacity(0.32), lineWidth: 1.0)

                Image(systemName: "arrow.left")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(PPColor.textSecondary.opacity(0.55))
                    .position(x: cx - cutWidth, y: cutDepth + 8)
            }
        }
        .allowsHitTesting(false)
    }

    private enum Const {
        static let cornerRadius: CGFloat = 8
        static let paperOpacity: Double = 0.78
        static let fiberCount = 140
        static let printBandRatio: CGFloat = 0.28
    }
}

#Preview("Sealed light") {
    PouchPaperLayer()
        .frame(width: 220, height: 300)
        .padding(40)
        .background(PPColor.background)
        .preferredColorScheme(.light)
}

#Preview("Sealed dark") {
    PouchPaperLayer()
        .frame(width: 220, height: 300)
        .padding(40)
        .background(PPColor.background)
        .preferredColorScheme(.dark)
}
