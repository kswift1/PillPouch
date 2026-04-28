//
//  PouchPaperLayer.swift
//  PillPouch
//

import SwiftUI

/// 플라스틱 약봉지 합성. 참조: `.context/attachments/image.png` (실제 한국 약국 봉지).
/// 본체 + 플라스틱 sheen + 상하단 굵은 serrated heat-seal + 옆구리 V노치 + 헤더(슬롯 도장 + 약국 정보).
/// 알약은 PouchView가 ZStack 아래에 깔아 봉지 너머로 비치게 함.
struct PouchPaperLayer: View {
    let slot: TimeSlot
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            pouchBody()
            plasticSheen()
            topHeatSeal()
            bottomHeatSeal()
            sideTearNotches()
            headerArea()
        }
    }

    // MARK: - 본체

    private func pouchBody() -> some View {
        RoundedRectangle(cornerRadius: Const.cornerRadius, style: .continuous)
            .fill(bodyFill)
            .overlay(
                RoundedRectangle(cornerRadius: Const.cornerRadius, style: .continuous)
                    .strokeBorder(bodyOutline, lineWidth: 0.5)
            )
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
    }

    private func plasticSheen() -> some View {
        LinearGradient(
            stops: [
                .init(color: .white.opacity(sheenAlpha * 0.0), location: 0.0),
                .init(color: .white.opacity(sheenAlpha * 1.0), location: 0.18),
                .init(color: .white.opacity(sheenAlpha * 0.0), location: 0.42),
                .init(color: .white.opacity(sheenAlpha * 0.6), location: 0.65),
                .init(color: .white.opacity(sheenAlpha * 0.0), location: 1.0),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .blendMode(.overlay)
        .clipShape(RoundedRectangle(cornerRadius: Const.cornerRadius, style: .continuous))
        .allowsHitTesting(false)
    }

    // MARK: - 열압착 띠

    private func topHeatSeal() -> some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(heatSealFill)
                    .frame(height: Const.topSealHeight)
                serration(width: geo.size.width, facingDown: true)
                    .stroke(heatSealEdge, lineWidth: 0.7)
                    .frame(width: geo.size.width, height: Const.serrationAmplitude)
                    .offset(y: Const.topSealHeight - Const.serrationAmplitude / 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: Const.cornerRadius, style: .continuous))
        }
        .allowsHitTesting(false)
    }

    private func bottomHeatSeal() -> some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(heatSealFill)
                    .frame(height: Const.bottomSealHeight)
                serration(width: geo.size.width, facingDown: false)
                    .stroke(heatSealEdge, lineWidth: 0.7)
                    .frame(width: geo.size.width, height: Const.serrationAmplitude)
                    .offset(y: -Const.bottomSealHeight + Const.serrationAmplitude / 2)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
            .clipShape(RoundedRectangle(cornerRadius: Const.cornerRadius, style: .continuous))
        }
        .allowsHitTesting(false)
    }

    /// 톱니(pinking-shears) 패턴. `facingDown=true`이면 위→아래로 V들이 향함(상단 띠 하단 가장자리).
    private func serration(width: CGFloat, facingDown: Bool) -> Path {
        Path { path in
            let amp = Const.serrationAmplitude
            let period = Const.serrationPeriod
            let count = Int(ceil(width / period)) + 1
            let baselineY: CGFloat = facingDown ? 0 : amp
            let peakY: CGFloat = facingDown ? amp : 0

            path.move(to: CGPoint(x: 0, y: baselineY))
            for i in 0 ..< count {
                let x1 = CGFloat(i) * period + period / 2
                let x2 = CGFloat(i + 1) * period
                path.addLine(to: CGPoint(x: x1, y: peakY))
                path.addLine(to: CGPoint(x: min(x2, width), y: baselineY))
            }
        }
    }

    // MARK: - 옆구리 V노치 (찢기 시작점)

    private func sideTearNotches() -> some View {
        GeometryReader { geo in
            let y = Const.topSealHeight + Const.serrationAmplitude + Const.notchYOffset
            ZStack {
                notchPath(at: CGPoint(x: 0, y: y), facingRight: true)
                    .stroke(notchColor, lineWidth: 0.7)
                notchPath(at: CGPoint(x: geo.size.width, y: y), facingRight: false)
                    .stroke(notchColor, lineWidth: 0.7)
            }
        }
        .allowsHitTesting(false)
    }

    private func notchPath(at origin: CGPoint, facingRight: Bool) -> Path {
        Path { path in
            let w: CGFloat = Const.notchWidth
            let h: CGFloat = Const.notchHeight
            let xSign: CGFloat = facingRight ? 1 : -1
            path.move(to: CGPoint(x: origin.x, y: origin.y - h / 2))
            path.addLine(to: CGPoint(x: origin.x + xSign * w, y: origin.y))
            path.addLine(to: CGPoint(x: origin.x, y: origin.y + h / 2))
        }
    }

    // MARK: - 헤더 (도장 + 약국 정보)

    private func headerArea() -> some View {
        GeometryReader { geo in
            HStack(alignment: .center, spacing: PPSpacing.sm) {
                SlotStamp(slot: slot)
                VStack(alignment: .leading, spacing: 2) {
                    Text("PillPouch 약국")
                        .font(PPFont.caption.weight(.semibold))
                        .foregroundStyle(headerPrimaryColor)
                    Text("환자: 사용자")
                        .font(PPFont.caption)
                        .foregroundStyle(headerSecondaryColor)
                    Text("1일 1회 / 식후 30분")
                        .font(.system(size: 9.5, design: .monospaced))
                        .foregroundStyle(headerSecondaryColor)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, PPSpacing.sm)
            .frame(width: geo.size.width)
            .position(
                x: geo.size.width / 2,
                y: Const.topSealHeight + Const.headerCenterOffset
            )
            .overlay(
                Rectangle()
                    .fill(headerSecondaryColor.opacity(0.30))
                    .frame(height: 0.5)
                    .padding(.horizontal, PPSpacing.md)
                    .position(
                        x: geo.size.width / 2,
                        y: Const.topSealHeight + Const.headerCenterOffset + Const.headerDividerOffset
                    )
            )
        }
        .allowsHitTesting(false)
    }

    // MARK: - 색 (모드별 분기)

    private var bodyFill: Color {
        scheme == .dark
            ? Color(red: 0.85, green: 0.83, blue: 0.78).opacity(0.18)
            : Color(red: 0.99, green: 0.98, blue: 0.96).opacity(0.92)
    }
    private var bodyOutline: Color {
        scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)
    }
    private var shadowColor: Color {
        scheme == .dark ? Color.black.opacity(0.45) : Color.black.opacity(0.10)
    }
    private var shadowRadius: CGFloat { scheme == .dark ? 12 : 8 }
    private var shadowY: CGFloat { scheme == .dark ? 4 : 3 }

    private var sheenAlpha: Double { scheme == .dark ? 0.05 : 0.10 }

    private var heatSealFill: Color {
        scheme == .dark
            ? Color(red: 0.29, green: 0.27, blue: 0.24).opacity(0.55)
            : Color(red: 0.85, green: 0.82, blue: 0.75).opacity(0.55)
    }
    private var heatSealEdge: Color {
        scheme == .dark
            ? Color(red: 0.36, green: 0.34, blue: 0.31).opacity(0.65)
            : Color(red: 0.72, green: 0.68, blue: 0.60).opacity(0.65)
    }

    private var notchColor: Color {
        scheme == .dark
            ? Color(red: 0.85, green: 0.82, blue: 0.78).opacity(0.30)
            : Color(red: 0.36, green: 0.34, blue: 0.31).opacity(0.30)
    }

    private var headerPrimaryColor: Color { PPColor.textPrimary.opacity(0.55) }
    private var headerSecondaryColor: Color { PPColor.textSecondary.opacity(0.55) }

    // MARK: - 상수

    private enum Const {
        static let cornerRadius: CGFloat = 3
        static let topSealHeight: CGFloat = 14
        static let bottomSealHeight: CGFloat = 12
        static let serrationAmplitude: CGFloat = 3
        static let serrationPeriod: CGFloat = 6
        static let notchWidth: CGFloat = 6
        static let notchHeight: CGFloat = 8
        static let notchYOffset: CGFloat = 4
        static let headerCenterOffset: CGFloat = 38
        static let headerDividerOffset: CGFloat = 36
    }
}

#Preview("Pouch · Morning · light") {
    PouchPaperLayer(slot: .morning)
        .frame(width: 240, height: 320)
        .padding(40)
        .background(PPColor.background)
        .preferredColorScheme(.light)
}

#Preview("Pouch · Lunch · light") {
    PouchPaperLayer(slot: .lunch)
        .frame(width: 240, height: 320)
        .padding(40)
        .background(PPColor.background)
        .preferredColorScheme(.light)
}

#Preview("Pouch · Evening · dark") {
    PouchPaperLayer(slot: .evening)
        .frame(width: 240, height: 320)
        .padding(40)
        .background(PPColor.background)
        .preferredColorScheme(.dark)
}
