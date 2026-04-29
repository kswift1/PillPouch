//
//  PillView.swift
//  PillPouch
//

import SwiftUI

/// 알약 1개 시각. capsuleType 별 분기. 봉지 너머로 비치는 효과는 PouchView가 z-index로 처리.
/// #11 캡슐 자산 머지 시 본 View 내부만 Image로 교체.
struct PillView: View {
    let pill: PillBody

    var body: some View {
        Group {
            switch pill.capsuleType {
            case .tablet:  tabletView
            case .softgel: softgelView
            case .capsule: capsuleView
            case .powder:  powderView
            case .gummy:   gummyView
            case .liquid:  EmptyView()
            }
        }
        .rotationEffect(.degrees(pill.rotation))
        .position(pill.position)
    }

    // MARK: - 6종 시각

    /// 정제: Circle + 가장자리 dark ring + 미세 highlight (살짝 입체).
    private var tabletView: some View {
        ZStack {
            Circle()
                .fill(pill.color)
                .frame(width: pill.radius * 2, height: pill.radius * 2)
            Circle()
                .strokeBorder(Color.black.opacity(0.10), lineWidth: 0.5)
                .frame(width: pill.radius * 2, height: pill.radius * 2)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.45), Color.clear],
                        center: UnitPoint(x: 0.32, y: 0.32),
                        startRadius: 0,
                        endRadius: pill.radius * 0.9
                    )
                )
                .frame(width: pill.radius * 2, height: pill.radius * 2)
        }
    }

    /// 연질 캡슐: Ellipse + 좌상단 흰 highlight.
    private var softgelView: some View {
        ZStack {
            Ellipse()
                .fill(pill.color)
                .frame(width: pill.radius * 2.4, height: pill.radius * 1.6)
            Ellipse()
                .fill(Color.white.opacity(0.55))
                .frame(width: pill.radius * 0.8, height: pill.radius * 0.35)
                .offset(x: -pill.radius * 0.55, y: -pill.radius * 0.4)
            Ellipse()
                .strokeBorder(Color.black.opacity(0.12), lineWidth: 0.5)
                .frame(width: pill.radius * 2.4, height: pill.radius * 1.6)
        }
    }

    /// 경질 캡슐: 두 톤 (좌측 색 / 우측 흰), 양 끝 둥근 마감.
    private var capsuleView: some View {
        let length = pill.radius * 2.6
        let thickness = pill.radius * 1.2
        return ZStack {
            HStack(spacing: 0) {
                Capsule()
                    .fill(pill.color)
                    .frame(width: length / 2, height: thickness)
                    .clipShape(Rectangle().offset(x: -length / 4))
                Capsule()
                    .fill(Color(red: 0.97, green: 0.95, blue: 0.92))
                    .frame(width: length / 2, height: thickness)
                    .clipShape(Rectangle().offset(x: length / 4))
            }
            .frame(width: length, height: thickness)
            .clipShape(Capsule())

            Capsule()
                .strokeBorder(Color.black.opacity(0.12), lineWidth: 0.5)
                .frame(width: length, height: thickness)

            Capsule()
                .fill(Color.white.opacity(0.30))
                .frame(width: length * 0.7, height: thickness * 0.18)
                .offset(y: -thickness * 0.30)
        }
    }

    /// 가루: 작은 원 다수 군집 (불규칙 배치, seed 고정).
    private var powderView: some View {
        Canvas { ctx, size in
            let dotCount = 7
            let spread = pill.radius * 0.95
            let dotR: CGFloat = 1.5
            for i in 0 ..< dotCount {
                let angle = Double(i) * 0.9
                let r = sqrt(Double(i) / Double(dotCount)) * Double(spread)
                let x = size.width / 2 + r * cos(angle)
                let y = size.height / 2 + r * sin(angle)
                let path = Path(ellipseIn: CGRect(x: x - dotR, y: y - dotR, width: dotR * 2, height: dotR * 2))
                ctx.fill(path, with: .color(pill.color.opacity(0.85)))
            }
        }
        .frame(width: pill.radius * 2.2, height: pill.radius * 2.2)
    }

    /// 젤리: rounded square + 반투명 fill + 코너 highlight.
    private var gummyView: some View {
        let side = pill.radius * 1.9
        return ZStack {
            RoundedRectangle(cornerRadius: side * 0.32, style: .continuous)
                .fill(pill.color.opacity(0.78))
                .frame(width: side, height: side)
            RoundedRectangle(cornerRadius: side * 0.32, style: .continuous)
                .strokeBorder(Color.black.opacity(0.10), lineWidth: 0.5)
                .frame(width: side, height: side)
            RoundedRectangle(cornerRadius: side * 0.18, style: .continuous)
                .fill(Color.white.opacity(0.40))
                .frame(width: side * 0.32, height: side * 0.18)
                .offset(x: -side * 0.22, y: -side * 0.22)
        }
    }
}

#Preview("Pill mix · 6 types") {
    HStack(spacing: 18) {
        PillView(pill: PillBody(capsuleType: .tablet,
                                color: Color(red: 0.91, green: 0.86, blue: 0.77),
                                position: CGPoint(x: 18, y: 18)))
        PillView(pill: PillBody(capsuleType: .softgel,
                                color: Color(red: 0.91, green: 0.60, blue: 0.47),
                                position: CGPoint(x: 22, y: 18)))
        PillView(pill: PillBody(capsuleType: .capsule,
                                color: Color(red: 0.78, green: 0.36, blue: 0.33),
                                position: CGPoint(x: 22, y: 18)))
        PillView(pill: PillBody(capsuleType: .powder,
                                color: Color(red: 0.78, green: 0.75, blue: 0.69),
                                position: CGPoint(x: 22, y: 22)))
        PillView(pill: PillBody(capsuleType: .gummy,
                                color: Color(red: 0.92, green: 0.74, blue: 0.40),
                                position: CGPoint(x: 18, y: 18)))
    }
    .frame(width: 360, height: 80)
    .background(PPColor.background)
}
