//
//  Supplement.swift
//  PillPouch
//

import Foundation
import SwiftData

/// 사용자가 등록한 영양제 1종. 봉지 띠의 한 칸에 대응.
/// 삭제 시 관련 `IntakeSchedule`/`IntakeLog`는 cascade로 함께 제거.
@Model
final class Supplement {
    /// CloudKit 동기화 시 충돌 해소 키. `@Attribute(.unique)`로 중복 방지.
    @Attribute(.unique) var id: UUID

    /// 사용자 표시 이름 (예: "오메가-3", "비타민D").
    var name: String

    /// `CapsuleType` 직렬화용 raw 저장 — `capsuleType` computed property로 접근.
    /// CloudKit/백엔드 wire 호환성을 위해 String raw 패턴 채택.
    var capsuleTypeRaw: String

    /// 디자인 시스템 색 토큰 식별자 (W1-4 결과물 참조). 미지정 시 슬롯 색조 사용.
    var colorToken: String?

    /// 등록 시각 — 정렬 + 디버깅용.
    var createdAt: Date

    /// 이 영양제의 슬롯별 복용 스케줄. Supplement 삭제 시 cascade.
    @Relationship(deleteRule: .cascade, inverse: \IntakeSchedule.supplement)
    var schedules: [IntakeSchedule] = []

    /// 이 영양제의 복용 기록 누적. Supplement 삭제 시 cascade.
    @Relationship(deleteRule: .cascade, inverse: \IntakeLog.supplement)
    var logs: [IntakeLog] = []

    /// `capsuleTypeRaw`를 enum으로 노출. 잘못된 raw일 경우 `.capsule` 폴백.
    var capsuleType: CapsuleType {
        get { CapsuleType(rawValue: capsuleTypeRaw) ?? .capsule }
        set { capsuleTypeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        capsuleType: CapsuleType,
        colorToken: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.capsuleTypeRaw = capsuleType.rawValue
        self.colorToken = colorToken
        self.createdAt = createdAt
    }
}
