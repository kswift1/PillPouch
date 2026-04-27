//
//  PillPouchTests.swift
//  PillPouchTests
//

import Testing
import SwiftData
import Foundation
@testable import PillPouch

@Suite struct EnumRoundtripTests {
    @Test func 캡슐타입_raw값_왕복_복원() {
        for c in CapsuleType.allCases {
            #expect(CapsuleType(rawValue: c.rawValue) == c)
        }
    }

    @Test func 시간슬롯_raw값_왕복_복원() {
        for s in TimeSlot.allCases {
            #expect(TimeSlot(rawValue: s.rawValue) == s)
        }
    }

    @Test func 복용상태_raw값_왕복_복원() {
        for s in IntakeStatus.allCases {
            #expect(IntakeStatus(rawValue: s.rawValue) == s)
        }
    }

    @Test func 캡슐타입_raw값_안정성_고정() {
        #expect(CapsuleType.tablet.rawValue == "tablet")
        #expect(CapsuleType.softgel.rawValue == "softgel")
        #expect(CapsuleType.capsule.rawValue == "capsule")
        #expect(CapsuleType.powder.rawValue == "powder")
        #expect(CapsuleType.liquid.rawValue == "liquid")
        #expect(CapsuleType.gummy.rawValue == "gummy")
    }

    @Test func 시간슬롯_raw값_안정성_고정() {
        #expect(TimeSlot.morning.rawValue == "morning")
        #expect(TimeSlot.lunch.rawValue == "lunch")
        #expect(TimeSlot.evening.rawValue == "evening")
    }

    @Test func 복용상태_raw값_안정성_고정() {
        #expect(IntakeStatus.taken.rawValue == "taken")
        #expect(IntakeStatus.missed.rawValue == "missed")
        #expect(IntakeStatus.skipped.rawValue == "skipped")
    }
}

@Suite struct SupplementComputedTests {
    @Test func 캡슐타입_setter_호출시_raw값_동기화() {
        let s = Supplement(name: "비타민D", capsuleType: .softgel)
        #expect(s.capsuleTypeRaw == "softgel")
        s.capsuleType = .gummy
        #expect(s.capsuleTypeRaw == "gummy")
        #expect(s.capsuleType == .gummy)
    }

    @Test func 캡슐타입_잘못된_raw_입력시_capsule로_폴백() {
        let s = Supplement(name: "오메가-3", capsuleType: .softgel)
        s.capsuleTypeRaw = "not-a-real-type"
        #expect(s.capsuleType == .capsule)
    }
}

@Suite struct IntakeLogComputedTests {
    @Test func 복용상태_setter_호출시_raw값_동기화() {
        let s = Supplement(name: "비타민C", capsuleType: .tablet)
        let log = IntakeLog(supplement: s, timeSlot: .morning, status: .taken)
        #expect(log.statusRaw == "taken")
        log.status = .skipped
        #expect(log.statusRaw == "skipped")
        #expect(log.status == .skipped)
    }

    @Test func 시간슬롯_setter_호출시_raw값_동기화() {
        let s = Supplement(name: "비타민C", capsuleType: .tablet)
        let log = IntakeLog(supplement: s, timeSlot: .morning, status: .taken)
        log.timeSlot = .evening
        #expect(log.timeSlotRaw == "evening")
        #expect(log.timeSlot == .evening)
    }
}

@Suite struct UserSettingsTests {
    @Test func 사용자설정_기본_슬롯시각_반환() {
        let s = UserSettings()
        let morning = s.time(for: .morning)
        let lunch = s.time(for: .lunch)
        let evening = s.time(for: .evening)
        #expect(morning.hour == 8 && morning.minute == 0)
        #expect(lunch.hour == 12 && lunch.minute == 30)
        #expect(evening.hour == 19 && evening.minute == 0)
    }

    @Test func 사용자설정_커스텀_슬롯시각_반환() {
        let s = UserSettings(
            morningHour: 7, morningMinute: 15,
            lunchHour: 13, lunchMinute: 0,
            eveningHour: 20, eveningMinute: 45
        )
        #expect(s.time(for: .morning) == (7, 15))
        #expect(s.time(for: .lunch) == (13, 0))
        #expect(s.time(for: .evening) == (20, 45))
    }

    @Test func 사용자설정_기본_타임존은_AsiaSeoul() {
        let s = UserSettings()
        #expect(s.timezoneIdentifier == "Asia/Seoul")
        #expect(s.timezone.identifier == "Asia/Seoul")
    }

    @Test func 사용자설정_잘못된_타임존_입력시_current로_폴백() {
        let s = UserSettings(timezoneIdentifier: "Not/AReal_Zone")
        #expect(s.timezone == TimeZone.current)
    }
}

@Suite struct ModelContainerSmokeTests {
    private func 인메모리_컨테이너_생성() throws -> ModelContainer {
        let schema = Schema([
            Supplement.self,
            IntakeSchedule.self,
            IntakeLog.self,
            UserSettings.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    @Test func 모델컨테이너_supplement_삽입_후_조회() throws {
        let container = try 인메모리_컨테이너_생성()
        let context = ModelContext(container)
        let s = Supplement(name: "오메가-3", capsuleType: .softgel)
        context.insert(s)
        try context.save()
        let fetched = try context.fetch(FetchDescriptor<Supplement>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "오메가-3")
        #expect(fetched.first?.capsuleType == .softgel)
    }

    @Test func cascade_삭제시_하위_schedule과_log_제거() throws {
        let container = try 인메모리_컨테이너_생성()
        let context = ModelContext(container)
        let s = Supplement(name: "비타민C", capsuleType: .tablet)
        context.insert(s)
        let schedule = IntakeSchedule(supplement: s, timeSlot: .morning, dose: 2)
        let log = IntakeLog(supplement: s, timeSlot: .morning, status: .taken)
        context.insert(schedule)
        context.insert(log)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<IntakeSchedule>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<IntakeLog>()).count == 1)

        context.delete(s)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<Supplement>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<IntakeSchedule>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<IntakeLog>()).isEmpty)
    }

    @Test func 사용자설정_저장_후_조회() throws {
        let container = try 인메모리_컨테이너_생성()
        let context = ModelContext(container)
        let settings = UserSettings()
        context.insert(settings)
        try context.save()
        let fetched = try context.fetch(FetchDescriptor<UserSettings>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.timezoneIdentifier == "Asia/Seoul")
    }
}
