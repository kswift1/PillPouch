//
//  PouchView.swift
//  PillPouch
//

import SwiftUI

/// 단일 약봉지 컴포넌트. 글라싱지 종이 + 알약 + 찢기 인터랙션의 조립체.
/// 이번 stage(1)에서는 Sealed 정적 시각만. 알약은 Stage 2, 모션은 Stage 3, 찢기는 Stage 4, 낙하는 Stage 5.
struct PouchView: View {
    let state: PouchState

    var body: some View {
        ZStack {
            PouchPaperLayer()
        }
    }
}

#Preview("Pouch · Sealed · light") {
    PouchView(state: .sealed)
        .frame(width: 220, height: 300)
        .padding(40)
        .background(PPColor.background)
        .preferredColorScheme(.light)
}

#Preview("Pouch · Sealed · dark") {
    PouchView(state: .sealed)
        .frame(width: 220, height: 300)
        .padding(40)
        .background(PPColor.background)
        .preferredColorScheme(.dark)
}
