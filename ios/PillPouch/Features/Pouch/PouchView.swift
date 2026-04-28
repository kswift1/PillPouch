//
//  PouchView.swift
//  PillPouch
//

import SwiftUI

/// 단일 약봉지 컴포넌트. 플라스틱 봉지 + 알약 + 찢기 인터랙션의 조립체.
/// Stage 1: Sealed 정적 시각만 (슬롯별 도장 포함). 알약은 Stage 2+, 모션 Stage 3, 찢기 Stage 4, 낙하 Stage 5.
struct PouchView: View {
    let state: PouchState
    let slot: TimeSlot

    var body: some View {
        ZStack {
            PouchPaperLayer(slot: slot)
        }
    }
}

#Preview("Pouch · Morning · light") {
    PouchView(state: .sealed, slot: .morning)
        .frame(width: 240, height: 320)
        .padding(40)
        .background(PPColor.background)
        .preferredColorScheme(.light)
}

#Preview("Pouch · Lunch · dark") {
    PouchView(state: .sealed, slot: .lunch)
        .frame(width: 240, height: 320)
        .padding(40)
        .background(PPColor.background)
        .preferredColorScheme(.dark)
}
