//
//  UserSettings.swift
//  PillPouch
//

import Foundation
import SwiftData

/// 사용자별 슬롯 시각 + 타임존 — V1은 single-user 전제, 부트스트랩 시 1행만 유지.
/// 서버 PTS 스케줄러가 이 값을 기반으로 사용자 IANA 타임존에서 다음 슬롯 시각을 UTC로 환산.
@Model
final class UserSettings {
    /// 식별자 — single-user여도 CloudKit/디바이스간 동기화에서 단일 행 식별 위해 유지.
    @Attribute(.unique) var id: UUID

    /// 아침 슬롯 시 (0~23). 기본 8.
    var morningHour: Int
    /// 아침 슬롯 분 (0~59). 기본 0.
    var morningMinute: Int

    /// 점심 슬롯 시. 기본 12.
    var lunchHour: Int
    /// 점심 슬롯 분. 기본 30.
    var lunchMinute: Int

    /// 저녁 슬롯 시. 기본 19.
    var eveningHour: Int
    /// 저녁 슬롯 분. 기본 0.
    var eveningMinute: Int

    /// IANA 타임존 식별자 (예: "Asia/Seoul") — 기획서 §타임존 처리.
    /// 여행 중 변경 시 디바이스 토큰과 함께 서버에 동기화 (W3 영역).
    var timezoneIdentifier: String

    init(
        id: UUID = UUID(),
        morningHour: Int = 8,
        morningMinute: Int = 0,
        lunchHour: Int = 12,
        lunchMinute: Int = 30,
        eveningHour: Int = 19,
        eveningMinute: Int = 0,
        timezoneIdentifier: String = "Asia/Seoul"
    ) {
        self.id = id
        self.morningHour = morningHour
        self.morningMinute = morningMinute
        self.lunchHour = lunchHour
        self.lunchMinute = lunchMinute
        self.eveningHour = eveningHour
        self.eveningMinute = eveningMinute
        self.timezoneIdentifier = timezoneIdentifier
    }
}

extension UserSettings {
    /// 슬롯별 (시, 분) 튜플 반환.
    func time(for slot: TimeSlot) -> (hour: Int, minute: Int) {
        switch slot {
        case .morning: return (morningHour, morningMinute)
        case .lunch: return (lunchHour, lunchMinute)
        case .evening: return (eveningHour, eveningMinute)
        }
    }

    /// `timezoneIdentifier`를 `TimeZone`으로 변환. 잘못된 식별자일 경우 `.current` 폴백.
    var timezone: TimeZone {
        TimeZone(identifier: timezoneIdentifier) ?? .current
    }
}
