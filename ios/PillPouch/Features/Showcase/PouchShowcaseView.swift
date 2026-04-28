//
//  PouchShowcaseView.swift
//  PillPouch
//

import SwiftUI

/// 단일 봉지 컴포넌트 데모/디버그 화면. 개발 진입점.
/// Stage 1: Sealed 정적 봉지만 표시. 후속 stage에서 알약/모션/찢기/낙하 컨트롤 추가.
struct PouchShowcaseView: View {
    var body: some View {
        ZStack {
            PPColor.background.ignoresSafeArea()
            VStack(spacing: PPSpacing.lg) {
                Spacer()
                PouchView(state: .sealed)
                    .frame(width: 240, height: 320)
                Spacer()
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
