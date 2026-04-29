//
//  PouchView.swift
//  PillPouch
//

import SwiftUI

/// 단일 약봉지 컴포넌트. 플라스틱 봉지 + 알약 + 찢기 인터랙션의 조립체.
/// Stage 2: Sealed + 알약 정적 배치. 모션 Stage 3, 찢기 Stage 4, 낙하 Stage 5.
struct PouchView: View {
    let state: PouchState
    let slot: TimeSlot
    let pills: [PillBody]

    var body: some View {
        ZStack {
            ForEach(pills) { pill in
                PillView(pill: pill)
            }
            .blur(radius: 0.4)
            .opacity(0.94)
            PouchPaperLayer(slot: slot)
        }
    }
}

#Preview("Pouch · Morning · light · 5 pills") {
    GeometryReader { geo in
        let bounds = PouchView.pillBounds(in: geo.size)
        PouchView(
            state: .sealed,
            slot: .morning,
            pills: PillBody.mock(count: 5, mix: .mixed, bounds: bounds)
        )
    }
    .frame(width: 240, height: 320)
    .padding(40)
    .background(PPColor.background)
    .preferredColorScheme(.light)
}

extension PouchView {
    /// 봉지 안 알약이 위치 가능한 사각 영역 (perforation 아래 ~ 하단 heat-seal 위).
    /// `PouchPaperLayer.Const`와 짝을 맞춰야 함.
    static func pillBounds(in size: CGSize) -> CGRect {
        let topInset: CGFloat = 14 + 38 + 36 + 8 // topSeal + headerCenter + headerDivider + padding
        let bottomInset: CGFloat = 12 + 6        // bottomSeal + padding
        let sideInset: CGFloat = 12
        return CGRect(
            x: sideInset,
            y: topInset,
            width: size.width - sideInset * 2,
            height: size.height - topInset - bottomInset
        )
    }
}
