//
//  PillBody.swift
//  PillPouch
//

import SwiftUI

/// 봉지 안 알약 1개의 데이터. Stage 2: 정적 위치. Stage 3: velocity/충돌 추가. Stage 5: isFalling 추가.
struct PillBody: Identifiable, Equatable {
    let id: UUID
    var capsuleType: CapsuleType
    var color: Color
    var position: CGPoint
    var radius: CGFloat
    var rotation: Double

    init(
        id: UUID = UUID(),
        capsuleType: CapsuleType,
        color: Color,
        position: CGPoint,
        radius: CGFloat = 14,
        rotation: Double = 0
    ) {
        self.id = id
        self.capsuleType = capsuleType
        self.color = color
        self.position = position
        self.radius = radius
        self.rotation = rotation
    }
}

extension PillBody {
    /// Showcase 데모용 알약 mock 생성. capsuleType이 mix면 6종 round-robin.
    /// 봉지 내부 영역(`bounds`)에 넘치지 않게 자동 배치 (perforation 아래 ~ 하단 heat-seal 위).
    /// `bounds`는 봉지 로컬 좌표계. radius는 24pt 기준 알약 크기.
    static func mock(count: Int, mix: PillMix, bounds: CGRect) -> [PillBody] {
        guard count > 0 else { return [] }

        let radius: CGFloat = 13
        let spacing: CGFloat = 2
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
            let type = mix.capsuleType(for: index)
            let color = mix.color(for: index, type: type)
            let rot = (Double(index) * 47.0).truncatingRemainder(dividingBy: 60.0) - 30.0
            return PillBody(
                capsuleType: type,
                color: color,
                position: CGPoint(x: x, y: y),
                radius: radius,
                rotation: rot
            )
        }
    }
}

/// Showcase 컨트롤이 사용하는 알약 조합 모드.
enum PillMix: String, CaseIterable, Identifiable {
    /// 6종 (liquid 제외 5종 + gummy) 섞어 round-robin.
    case mixed

    /// 모두 정제.
    case allTablet

    /// 모두 경질 캡슐.
    case allCapsule

    /// 모두 연질 캡슐 (오메가3 톤).
    case allSoftgel

    /// 모두 가루.
    case allPowder

    /// 모두 젤리.
    case allGummy

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mixed:      "혼합"
        case .allTablet:  "정제"
        case .allCapsule: "캡슐"
        case .allSoftgel: "연질"
        case .allPowder:  "가루"
        case .allGummy:   "젤리"
        }
    }

    func capsuleType(for index: Int) -> CapsuleType {
        switch self {
        case .mixed:      Self.mixedRotation[index % Self.mixedRotation.count]
        case .allTablet:  .tablet
        case .allCapsule: .capsule
        case .allSoftgel: .softgel
        case .allPowder:  .powder
        case .allGummy:   .gummy
        }
    }

    /// warm 약품 톤 6종 — 봉지/배경 cream 팔레트와 정합.
    func color(for index: Int, type: CapsuleType) -> Color {
        switch type {
        case .tablet:  Self.tabletColors[index % Self.tabletColors.count]
        case .softgel: Color(red: 0.91, green: 0.60, blue: 0.47)
        case .capsule: Self.capsuleColors[index % Self.capsuleColors.count]
        case .powder:  Color(red: 0.78, green: 0.75, blue: 0.69)
        case .liquid:  Color(red: 0.78, green: 0.75, blue: 0.69)
        case .gummy:   Self.gummyColors[index % Self.gummyColors.count]
        }
    }

    private static let mixedRotation: [CapsuleType] = [
        .tablet, .capsule, .softgel, .gummy, .powder, .tablet,
    ]

    private static let tabletColors: [Color] = [
        Color(red: 0.97, green: 0.95, blue: 0.92),
        Color(red: 0.91, green: 0.86, blue: 0.77),
    ]

    private static let capsuleColors: [Color] = [
        Color(red: 0.78, green: 0.36, blue: 0.33),
        Color(red: 0.90, green: 0.71, blue: 0.31),
    ]

    private static let gummyColors: [Color] = [
        Color(red: 0.85, green: 0.55, blue: 0.45),
        Color(red: 0.92, green: 0.74, blue: 0.40),
        Color(red: 0.55, green: 0.62, blue: 0.45),
    ]
}
