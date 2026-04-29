//
//  PouchShowcaseView.swift
//  PillPouch
//

import SwiftUI

/// 단일 봉지 컴포넌트 데모/디버그 화면. 개발 진입점.
/// Stage 2: 슬롯 + 알약 개수/조합 컨트롤. Stage 3+에서 motion/찢기/낙하 추가.
struct PouchShowcaseView: View {
    @State private var slot: TimeSlot = .morning
    @State private var pillCount: Double = 5
    @State private var mix: PillMix = .mixed
    @State private var resetToken: Int = 0

    private let pouchSize = CGSize(width: 260, height: 340)

    var body: some View {
        ZStack {
            PPColor.background.ignoresSafeArea()
            VStack(spacing: PPSpacing.md) {
                Spacer()
                PouchView(
                    state: .sealed,
                    slot: slot,
                    pills: pillsForCurrentSettings()
                )
                .frame(width: pouchSize.width, height: pouchSize.height)
                .id(resetToken)
                Spacer()
                controls
                Text("Stage 2 — pills static placement")
                    .font(PPFont.caption)
                    .foregroundStyle(PPColor.textSecondary)
                    .padding(.bottom, PPSpacing.lg)
            }
        }
    }

    @ViewBuilder
    private var controls: some View {
        VStack(spacing: PPSpacing.sm) {
            Picker("슬롯", selection: $slot) {
                Text("아침").tag(TimeSlot.morning)
                Text("점심").tag(TimeSlot.lunch)
                Text("저녁").tag(TimeSlot.evening)
            }
            .pickerStyle(.segmented)
            HStack(spacing: PPSpacing.sm) {
                Text("알약 \(Int(pillCount))개")
                    .font(PPFont.caption)
                    .foregroundStyle(PPColor.textSecondary)
                    .frame(width: 70, alignment: .leading)
                Slider(value: $pillCount, in: 0 ... 8, step: 1)
            }
            HStack(spacing: PPSpacing.sm) {
                Picker("조합", selection: $mix) {
                    ForEach(PillMix.allCases) { m in
                        Text(m.displayName).tag(m)
                    }
                }
                .pickerStyle(.menu)
                Spacer()
                Button("Reset") { resetToken &+= 1 }
                    .font(PPFont.caption)
                    .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, PPSpacing.lg)
    }

    private func pillsForCurrentSettings() -> [PillBody] {
        let bounds = PouchView.pillBounds(in: pouchSize)
        return PillBody.mock(count: Int(pillCount), mix: mix, bounds: bounds)
    }
}

#Preview("Showcase · light") {
    PouchShowcaseView().preferredColorScheme(.light)
}

#Preview("Showcase · dark") {
    PouchShowcaseView().preferredColorScheme(.dark)
}
