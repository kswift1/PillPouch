//
//  IntakeSchedule.swift
//  PillPouch
//

import Foundation
import SwiftData

/// "어떤 영양제를 어느 슬롯에 몇 알 먹는가"의 정의. 행동 기록(`IntakeLog`)이 아니라 **계획**.
/// 한 Supplement가 여러 슬롯에 걸치면 row가 여러 개 (예: 비타민C 아침+저녁).
@Model
final class IntakeSchedule {
    /// 식별자 — CloudKit 충돌 해소 키.
    @Attribute(.unique) var id: UUID

    /// 대상 영양제. `inverse: \Supplement.schedules`로 양방향 연결, cascade 삭제.
    /// optional은 SwiftData 관계 요구사항 (Supplement 삭제 직전 일시적 nil 허용).
    var supplement: Supplement?

    /// `TimeSlot` raw 저장 — `timeSlot` computed로 접근.
    var timeSlotRaw: String

    /// 1회 복용 알 수 (기본 1). 0 이하는 호출자 책임으로 검증.
    var dose: Int

    /// `timeSlotRaw`를 enum으로 노출. 잘못된 raw일 경우 `.morning` 폴백.
    var timeSlot: TimeSlot {
        get { TimeSlot(rawValue: timeSlotRaw) ?? .morning }
        set { timeSlotRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        supplement: Supplement,
        timeSlot: TimeSlot,
        dose: Int = 1
    ) {
        self.id = id
        self.supplement = supplement
        self.timeSlotRaw = timeSlot.rawValue
        self.dose = dose
    }
}
