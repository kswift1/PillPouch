//
//  SlotStamp.swift
//  PillPouch
//

import SwiftUI

/// 봉지 헤더 좌측 시간대 도장. 원형 프레임 + 아이콘 + 한글 텍스트(자산 baked-in).
/// 자산은 베이지 단색 PNG, Template 렌더링으로 슬롯별 색조 동적 적용.
struct SlotStamp: View {
    let slot: TimeSlot

    var body: some View {
        Image("SlotStamps/\(assetName)")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(color)
            .frame(width: Const.size, height: Const.size)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
    }

    private var assetName: String {
        switch slot {
        case .morning: "SlotMorning"
        case .lunch:   "SlotLunch"
        case .evening: "SlotEvening"
        }
    }

    private var color: Color {
        switch slot {
        case .morning: PPColor.morning
        case .lunch:   PPColor.lunch
        case .evening: PPColor.evening
        }
    }

    /// 슬롯별로 다른 회전 각도 — 손으로 매번 다르게 찍은 도장 느낌.
    private var rotation: Double {
        switch slot {
        case .morning: -3.0
        case .lunch:   +1.5
        case .evening: -1.5
        }
    }

    /// 인주 살짝 옅은 느낌. 저녁 퍼플은 따뜻한 크림 배경에서 살짝 튈 수 있어 한 단계 더 누름.
    private var opacity: Double {
        switch slot {
        case .morning, .lunch: 0.78
        case .evening:         0.72
        }
    }

    private enum Const {
        static let size: CGFloat = 56
    }
}

#Preview("Slot stamps · light") {
    HStack(spacing: PPSpacing.md) {
        SlotStamp(slot: .morning)
        SlotStamp(slot: .lunch)
        SlotStamp(slot: .evening)
    }
    .padding(PPSpacing.lg)
    .background(PPColor.background)
    .preferredColorScheme(.light)
}

#Preview("Slot stamps · dark") {
    HStack(spacing: PPSpacing.md) {
        SlotStamp(slot: .morning)
        SlotStamp(slot: .lunch)
        SlotStamp(slot: .evening)
    }
    .padding(PPSpacing.lg)
    .background(PPColor.background)
    .preferredColorScheme(.dark)
}
