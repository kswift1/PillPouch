//
//  PillView.swift
//  PillPouch
//

import SwiftUI

/// 알약 1개 시각. PR #22 카테고리 시드 자산(`Assets.xcassets/Categories/{key}`)을 그대로 표시.
/// 자산 비율은 카테고리별로 다양 (작은 tablet / 큰 가로 tablet / capsule / softgel) — `.scaledToFit()` 으로 보존.
struct PillView: View {
    let pill: PillBody

    var body: some View {
        Image(pill.categoryKey)
            .resizable()
            .scaledToFit()
            .frame(width: pill.radius * 2.4, height: pill.radius * 2.4)
            .rotationEffect(.degrees(pill.rotation))
            .position(pill.position)
    }
}

#Preview("Pill assets · all 16") {
    let keys = [
        "omega3", "probiotics", "vitaminC", "multivitamin",
        "vitaminD", "vitaminB", "milkThistle", "glucosamine",
        "lutein", "collagen", "magnesium", "calcium",
        "iron", "zinc", "coq10", "other",
    ]
    return ScrollView {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4),
                  spacing: PPSpacing.sm) {
            ForEach(keys, id: \.self) { key in
                VStack(spacing: 4) {
                    Image(key)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                    Text(key)
                        .font(PPFont.caption)
                        .foregroundStyle(PPColor.textSecondary)
                }
            }
        }
        .padding()
    }
    .background(PPColor.background)
}
