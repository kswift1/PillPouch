//
//  PouchShowcaseView.swift
//  PillPouch
//

import SwiftUI

/// 단일 봉지 컴포넌트 데모/디버그 화면. 개발 진입점.
/// Stage 1: Sealed 정적 봉지 + 슬롯 토글. 후속 stage에서 알약/모션/찢기/낙하 컨트롤 추가.
struct PouchShowcaseView: View {
    @State private var slot: TimeSlot = .morning

    var body: some View {
        ZStack {
            PPColor.background.ignoresSafeArea()
            VStack(spacing: PPSpacing.lg) {
                Spacer()
                PouchView(state: .sealed, slot: slot)
                    .frame(width: 260, height: 340)
                Spacer()
                Picker("슬롯", selection: $slot) {
                    Text("아침").tag(TimeSlot.morning)
                    Text("점심").tag(TimeSlot.lunch)
                    Text("저녁").tag(TimeSlot.evening)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, PPSpacing.lg)
                Text("Stage 1 — Sealed only")
                    .font(PPFont.caption)
                    .foregroundStyle(PPColor.textSecondary)
                    .padding(.bottom, PPSpacing.lg)
            }
        }
    }
}

#Preview("Showcase · light") {
    PouchShowcaseView()
        .preferredColorScheme(.light)
}

#Preview("Showcase · dark") {
    PouchShowcaseView()
        .preferredColorScheme(.dark)
}
