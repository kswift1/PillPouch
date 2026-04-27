//
//  PillPouchTests.swift
//  PillPouchTests
//

import Testing
import SwiftData
import Foundation
@testable import PillPouch

@Suite struct EnumRoundtripTests {
    @Test func capsuleTypeRoundtrip() {
        for c in CapsuleType.allCases {
            #expect(CapsuleType(rawValue: c.rawValue) == c)
        }
    }

    @Test func timeSlotRoundtrip() {
        for s in TimeSlot.allCases {
            #expect(TimeSlot(rawValue: s.rawValue) == s)
        }
    }

    @Test func intakeStatusRoundtrip() {
        for s in IntakeStatus.allCases {
            #expect(IntakeStatus(rawValue: s.rawValue) == s)
        }
    }

    @Test func capsuleTypeRawIsStable() {
        #expect(CapsuleType.tablet.rawValue == "tablet")
        #expect(CapsuleType.softgel.rawValue == "softgel")
        #expect(CapsuleType.capsule.rawValue == "capsule")
        #expect(CapsuleType.powder.rawValue == "powder")
        #expect(CapsuleType.liquid.rawValue == "liquid")
        #expect(CapsuleType.gummy.rawValue == "gummy")
    }

    @Test func timeSlotRawIsStable() {
        #expect(TimeSlot.morning.rawValue == "morning")
        #expect(TimeSlot.lunch.rawValue == "lunch")
        #expect(TimeSlot.evening.rawValue == "evening")
    }

    @Test func intakeStatusRawIsStable() {
        #expect(IntakeStatus.taken.rawValue == "taken")
        #expect(IntakeStatus.missed.rawValue == "missed")
        #expect(IntakeStatus.skipped.rawValue == "skipped")
    }
}

@Suite struct SupplementComputedTests {
    @Test func capsuleTypeComputedSetUpdatesRaw() {
        let s = Supplement(name: "비타민D", capsuleType: .softgel)
        #expect(s.capsuleTypeRaw == "softgel")
        s.capsuleType = .gummy
        #expect(s.capsuleTypeRaw == "gummy")
        #expect(s.capsuleType == .gummy)
    }

    @Test func capsuleTypeFallsBackOnInvalidRaw() {
        let s = Supplement(name: "오메가-3", capsuleType: .softgel)
        s.capsuleTypeRaw = "not-a-real-type"
        #expect(s.capsuleType == .capsule)
    }
}

@Suite struct IntakeLogComputedTests {
    @Test func statusComputedSetUpdatesRaw() {
        let s = Supplement(name: "비타민C", capsuleType: .tablet)
        let log = IntakeLog(supplement: s, timeSlot: .morning, status: .taken)
        #expect(log.statusRaw == "taken")
        log.status = .skipped
        #expect(log.statusRaw == "skipped")
        #expect(log.status == .skipped)
    }

    @Test func timeSlotComputedSetUpdatesRaw() {
        let s = Supplement(name: "비타민C", capsuleType: .tablet)
        let log = IntakeLog(supplement: s, timeSlot: .morning, status: .taken)
        log.timeSlot = .evening
        #expect(log.timeSlotRaw == "evening")
        #expect(log.timeSlot == .evening)
    }
}

@Suite struct UserSettingsTests {
    @Test func defaultTimes() {
        let s = UserSettings()
        let morning = s.time(for: .morning)
        let lunch = s.time(for: .lunch)
        let evening = s.time(for: .evening)
        #expect(morning.hour == 8 && morning.minute == 0)
        #expect(lunch.hour == 12 && lunch.minute == 30)
        #expect(evening.hour == 19 && evening.minute == 0)
    }

    @Test func customTimesAreReturned() {
        let s = UserSettings(
            morningHour: 7, morningMinute: 15,
            lunchHour: 13, lunchMinute: 0,
            eveningHour: 20, eveningMinute: 45
        )
        #expect(s.time(for: .morning) == (7, 15))
        #expect(s.time(for: .lunch) == (13, 0))
        #expect(s.time(for: .evening) == (20, 45))
    }

    @Test func defaultTimezoneIsAsiaSeoul() {
        let s = UserSettings()
        #expect(s.timezoneIdentifier == "Asia/Seoul")
        #expect(s.timezone.identifier == "Asia/Seoul")
    }

    @Test func timezoneFallsBackOnInvalidIdentifier() {
        let s = UserSettings(timezoneIdentifier: "Not/AReal_Zone")
        #expect(s.timezone == TimeZone.current)
    }
}

@Suite struct ModelContainerSmokeTests {
    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            Supplement.self,
            IntakeSchedule.self,
            IntakeLog.self,
            UserSettings.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    @Test func canInsertAndFetchSupplement() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let s = Supplement(name: "오메가-3", capsuleType: .softgel)
        context.insert(s)
        try context.save()
        let fetched = try context.fetch(FetchDescriptor<Supplement>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "오메가-3")
        #expect(fetched.first?.capsuleType == .softgel)
    }

    @Test func cascadeDeleteRemovesSchedulesAndLogs() throws {
        let container = try makeInMemoryContainer()
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

    @Test func canPersistUserSettings() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let settings = UserSettings()
        context.insert(settings)
        try context.save()
        let fetched = try context.fetch(FetchDescriptor<UserSettings>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.timezoneIdentifier == "Asia/Seoul")
    }
}
