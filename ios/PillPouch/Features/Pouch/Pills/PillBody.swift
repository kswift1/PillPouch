//
//  PillBody.swift
//  PillPouch
//

import SwiftUI

/// 봉지 안 알약 1개의 데이터. 알약 시각은 PR #22로 머지된 카테고리 시드 자산을 그대로 사용 —
/// categoryKey 가 형태/색/크기를 모두 결정. Categories 폴더는 namespace 미설정이라 `Image(categoryKey)` 로 직접 접근.
/// Stage 2: 정적 위치 + Stage 3: velocity/충돌 추가. Stage 5: isFalling 추가.
struct PillBody: Identifiable, Equatable {
    let id: UUID
    /// `Supplement.categoryKey` 와 매핑되는 lowerCamel id. `Categories/{key}` Asset Catalog 키와 1:1.
    var categoryKey: String
    var position: CGPoint
    /// 픽셀/초 (pt/s). Stage 3 물리 엔진이 매 tick 갱신.
    var velocity: CGVector
    /// 시각 frame 의 절반. `frame = radius * 2 * sizeMultiplier` 로 표시. 충돌 반지름.
    var radius: CGFloat
    /// 도(degree) 단위 누적 회전. PillView 가 `.rotationEffect(.degrees(rotation))` 으로 적용.
    var rotation: Double
    /// 도/초 (deg/s). 충돌/벽 마찰로 부여, angularDamping 으로 감쇠.
    var angularVelocity: Double

    init(
        id: UUID = UUID(),
        categoryKey: String,
        position: CGPoint,
        velocity: CGVector = .zero,
        radius: CGFloat = 22,
        rotation: Double = 0,
        angularVelocity: Double = 0
    ) {
        self.id = id
        self.categoryKey = categoryKey
        self.position = position
        self.velocity = velocity
        self.radius = radius
        self.rotation = rotation
        self.angularVelocity = angularVelocity
    }
}

extension PillBody {
    /// Showcase 데모용 알약 mock 생성. mix 에 따라 카테고리 round-robin 또는 단일.
    /// 봉지 내부 영역(`bounds`)에 자동 배치 (perforation 아래 ~ 하단 heat-seal 위, 봉지 바닥 정렬).
    static func mock(count: Int, mix: PillMix, bounds: CGRect) -> [PillBody] {
        guard count > 0 else { return [] }

        let radius: CGFloat = 22
        let spacing: CGFloat = 1
        let cellSize = radius * 2 + spacing

        let cols = max(Int(bounds.width / cellSize), 1)
        let usableWidth = CGFloat(cols) * cellSize - spacing
        let xStart = bounds.minX + (bounds.width - usableWidth) / 2 + radius

        let totalRows = Int(ceil(Double(count) / Double(cols)))
        let usableHeight = CGFloat(totalRows) * cellSize - spacing
        let yEnd = bounds.maxY - radius
        let yStart = yEnd - usableHeight + radius

        return (0 ..< count).map { index in
            let row = index / cols
            let col = index % cols
            let x = xStart + CGFloat(col) * cellSize
            let y = yStart + CGFloat(row) * cellSize
            let key = mix.categoryKey(for: index)
            let rot = (Double(index) * 47.0).truncatingRemainder(dividingBy: 60.0) - 30.0
            // 시작 시 미세 horizontal jitter — gravity 적용 시 자연 spread.
            // index 기반 deterministic, ±8 pt/s 범위.
            let dxJitter = CGFloat(((index &* 73) % 17) - 8)
            return PillBody(
                categoryKey: key,
                position: CGPoint(x: x, y: y),
                velocity: CGVector(dx: dxJitter, dy: 0),
                radius: radius,
                rotation: rot
            )
        }
    }
}

/// Showcase 컨트롤이 사용하는 알약 조합. 카테고리 시드 16종 (PR #22) 기반.
enum PillMix: String, CaseIterable, Identifiable {
    /// 혼합 — 16종 round-robin.
    case mixed

    /// 비타민 4종 — vitaminD / vitaminC / vitaminB / multivitamin.
    case vitamins

    /// 오메가/지용성 4종 — omega3 / lutein / coq10 / collagen.
    case omega

    /// 미네랄 4종 — calcium / magnesium / iron / zinc.
    case minerals

    /// 캡슐 3종 — probiotics / milkThistle / glucosamine.
    case capsules

    /// 단일 — omega3 만.
    case singleOmega3

    /// 단일 — vitaminD 만.
    case singleVitaminD

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mixed:          "혼합"
        case .vitamins:       "비타민"
        case .omega:          "오메가"
        case .minerals:       "미네랄"
        case .capsules:       "캡슐"
        case .singleOmega3:   "오메가3"
        case .singleVitaminD: "비타민D"
        }
    }

    func categoryKey(for index: Int) -> String {
        let pool = keys
        return pool[index % pool.count]
    }

    private var keys: [String] {
        switch self {
        case .mixed: Self.allCategoryKeys
        case .vitamins:       ["vitaminD", "vitaminC", "vitaminB", "multivitamin"]
        case .omega:          ["omega3", "lutein", "coq10", "collagen"]
        case .minerals:       ["calcium", "magnesium", "iron", "zinc"]
        case .capsules:       ["probiotics", "milkThistle", "glucosamine"]
        case .singleOmega3:   ["omega3"]
        case .singleVitaminD: ["vitaminD"]
        }
    }

    /// `Resources/category-seed.json` 기준 16종. 시드 변경 시 동기화.
    private static let allCategoryKeys: [String] = [
        "omega3", "probiotics", "vitaminC", "multivitamin",
        "vitaminD", "vitaminB", "milkThistle", "glucosamine",
        "lutein", "collagen", "magnesium", "calcium",
        "iron", "zinc", "coq10", "other",
    ]
}
