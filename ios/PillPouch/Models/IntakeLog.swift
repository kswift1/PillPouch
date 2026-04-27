//
//  IntakeLog.swift
//  PillPouch
//

import Foundation
import SwiftData

/// "찢음/건너뜀/누락" 행동의 비가역 기록 — 가설 B(기록 신뢰성)의 핵심 데이터.
/// 한 슬롯 1회당 1 row. Undo는 row 삭제로 처리, 수정 X.
@Model
final class IntakeLog {
    /// 식별자 — CloudKit 충돌 해소 키.
    @Attribute(.unique) var id: UUID

    /// 대상 영양제. `inverse: \Supplement.logs`로 양방향 연결, cascade 삭제.
    var supplement: Supplement?

    /// 어느 슬롯에 대한 기록인가 — `TimeSlot` raw 저장.
    var timeSlotRaw: String

    /// 사용자가 실제로 찢은 시각. 누적 통계 + "쌓인 증거" 영역 정렬에 사용.
    var takenAt: Date

    /// `IntakeStatus` raw 저장 — `status` computed로 접근.
    var statusRaw: String

    /// `timeSlotRaw`를 enum으로 노출. 잘못된 raw일 경우 `.morning` 폴백.
    var timeSlot: TimeSlot {
        get { TimeSlot(rawValue: timeSlotRaw) ?? .morning }
        set { timeSlotRaw = newValue.rawValue }
    }

    /// `statusRaw`를 enum으로 노출. 잘못된 raw일 경우 `.taken` 폴백.
    var status: IntakeStatus {
        get { IntakeStatus(rawValue: statusRaw) ?? .taken }
        set { statusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        supplement: Supplement,
        timeSlot: TimeSlot,
        takenAt: Date = .now,
        status: IntakeStatus
    ) {
        self.id = id
        self.supplement = supplement
        self.timeSlotRaw = timeSlot.rawValue
        self.takenAt = takenAt
        self.statusRaw = status.rawValue
    }
}
