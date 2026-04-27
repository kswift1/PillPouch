# task_W1_10_impl.md — SwiftData 모델 4종 + Item 제거 구현계획서

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#10](https://github.com/kswift1/PillPouch/issues/10) |
| 마일스톤 | W1 |
| 크기 | M |
| 영역 | area:ios |
| 타입 | type:feat |
| 브랜치 | `local/task10` (origin/main에서 분기) |
| 예상 시간 | 3~4시간 |

## 목표

기획서 §데이터 모델 스케치에 정의된 4종 SwiftData `@Model`을 정의하고 Xcode 기본 boilerplate(`Item.swift`, `ContentView.swift` boilerplate)를 정리한다. ADR-0005가 박제한 "SwiftUI 네이티브 + SwiftData + `@Observable`" 패턴의 데이터 계층을 처음으로 깐다.

W1-5(Today 정적 레이아웃)와 W2(드래그 인터랙션)가 이 모델 위에서 구현되므로, **이 PR은 데이터 계층의 SoT**다. 모델 형태가 어긋나면 이후 모든 화면/상호작용 작업이 영향받는다.

## 비목표

- ❌ Today/Supplements 화면 UI — W1-5 영역 (이 PR에선 ContentView 자리는 placeholder)
- ❌ 색 토큰 / DesignSystem — W1-4 (다른 워크스페이스 진행 중, 이 PR은 그쪽 폴더 안 건드림)
- ❌ CloudKit 동기화 활성화 — W4 영역 (Schema 호환성만 확보, `cloudKitDatabase` 옵션은 W4에서 켬)
- ❌ DeviceToken (서버 측 모델) — W3 백엔드 작업
- ❌ 실 데이터 마이그레이션 — Item만 들어있던 더미 스토어, 그냥 갈아엎음

## 구현 단계 (단일 PR 단위)

### Step 1: 도메인 enum 3종 추가

`ios/PillPouch/Models/Enums.swift` 신설 (또는 각 enum이 사용되는 모델 파일에 분산도 가능하나, 여러 모델이 공유하므로 한 파일에 모음).

```swift
/// 봉지 안 캡슐의 시각적 형태 — 기획서 §캡슐 일러스트 6종.
/// 봉지 SVG 렌더링과 영양제 등록 화면 Picker에서 사용.
enum CapsuleType: String, Codable, CaseIterable {
    case tablet, softgel, capsule, powder, liquid, gummy
}

/// 하루 3슬롯 — 기획서 §화면 구조 §데이터 모델 스케치.
/// `UserSettings`의 시각과 1:1 매핑되며 Today 화면의 봉지 띠 순서를 결정.
enum TimeSlot: String, Codable, CaseIterable {
    case morning, lunch, evening
}

/// 슬롯에 대한 사용자 행동 결과 — 기획서 §봉지 상태 5종 중 데이터 측 3종.
/// `taken` = 찢김, `skipped` = 길게 누르기 → 건너뛰기, `missed` = 시간 지남 후 미체크.
enum IntakeStatus: String, Codable, CaseIterable {
    case taken, missed, skipped
}
```

근거:
- `String` raw value: SwiftData 저장 + 디버깅 가독성
- `Codable`: 추후 백엔드 직렬화 (`crates/api`와 명세 공유 시 wire format 확정에 도움)
- `CaseIterable`: SwiftUI Picker, 테스트 망라 검증

### Step 2: `Supplement` @Model

`ios/PillPouch/Models/Supplement.swift` 신설.

```swift
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

    init(id: UUID = UUID(), name: String, capsuleType: CapsuleType, colorToken: String? = nil, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.capsuleTypeRaw = capsuleType.rawValue
        self.colorToken = colorToken
        self.createdAt = createdAt
    }
}
```

**판단**:
- enum 직접 저장 vs raw + computed: SwiftData가 `@Model` 안 enum을 처음부터 안전히 저장하지만, CloudKit 동기화 호환성을 위해 raw 패턴 사용. ADR-0005 §재검토 조건에서 CloudKit 충돌 로직이 변수가 됨 — 단순 String이 가장 안전.
- `@Attribute(.unique)`: id 중복 방지. CloudKit 동기화 시 충돌 키.
- `@Relationship(.cascade, inverse:)`: Supplement 삭제 시 관련 Schedule/Log 자동 삭제.

### Step 3: `IntakeSchedule` @Model

`ios/PillPouch/Models/IntakeSchedule.swift` 신설.

```swift
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

    init(id: UUID = UUID(), supplement: Supplement, timeSlot: TimeSlot, dose: Int = 1) {
        self.id = id
        self.supplement = supplement
        self.timeSlotRaw = timeSlot.rawValue
        self.dose = dose
    }
}
```

**판단**:
- 기획서엔 `supplementId: UUID`로 적혀있지만 SwiftData는 객체 참조가 정석. `inverse: \Supplement.schedules` 양방향 관계로 `@Query` 효율 + 자동 cascade.
- `dose: Int default 1` — 기획서 그대로.

### Step 4: `IntakeLog` @Model

`ios/PillPouch/Models/IntakeLog.swift` 신설.

```swift
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

    init(id: UUID = UUID(), supplement: Supplement, timeSlot: TimeSlot, takenAt: Date = .now, status: IntakeStatus) {
        self.id = id
        self.supplement = supplement
        self.timeSlotRaw = timeSlot.rawValue
        self.takenAt = takenAt
        self.statusRaw = status.rawValue
    }
}
```

### Step 5: `UserSettings` @Model

`ios/PillPouch/Models/UserSettings.swift` 신설. 기획서: "morning/lunch/evening time" + "timezone".

```swift
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
        morningHour: Int = 8, morningMinute: Int = 0,
        lunchHour: Int = 12, lunchMinute: Int = 30,
        eveningHour: Int = 19, eveningMinute: Int = 0,
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
    func time(for slot: TimeSlot) -> (hour: Int, minute: Int) {
        switch slot {
        case .morning: return (morningHour, morningMinute)
        case .lunch: return (lunchHour, lunchMinute)
        case .evening: return (eveningHour, eveningMinute)
        }
    }

    var timezone: TimeZone {
        TimeZone(identifier: timezoneIdentifier) ?? .current
    }
}
```

**판단**:
- `Date`로 시간만 저장은 ambiguous (날짜 부분이 의미 없음). `Hour/Minute` 분리가 깔끔하고 직렬화 시 wire 호환도 좋음.
- `timezone` IANA 문자열로 저장 — 기획서 §타임존 처리 그대로.
- `UserSettings`는 단일 사용자 전제 (V1엔 multi-user 없음). 다중 인스턴스 방지는 앱 측 부트스트랩에서 처리(W1-5 또는 W1-3 부트스트랩 헬퍼).

### Step 6: `Item.swift` 삭제

```bash
git rm ios/PillPouch/Item.swift
```

### Step 7: `ContentView.swift` 정리 (placeholder)

W1-5에서 Today 정적 레이아웃이 들어오므로, 지금은 boilerplate 제거 + 빈 placeholder.

```swift
import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        Text("Pill Pouch")
            .font(.title)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Supplement.self,
            IntakeSchedule.self,
            IntakeLog.self,
            UserSettings.self,
        ], inMemory: true)
}
```

색 토큰 의존 X (W1-4 영역 안 건드림). W1-5에서 Today 화면으로 갈아엎음.

### Step 8: `PillPouchApp.swift` Schema 갱신

```swift
@main
struct PillPouchApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Supplement.self,
            IntakeSchedule.self,
            IntakeLog.self,
            UserSettings.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

### Step 9: 도메인 unit 테스트 (Swift Testing)

`ios/PillPouchTests/PillPouchTests.swift` 갈아엎고 테스트 4종.

테스트 항목:
1. **enum raw 왕복** — `CapsuleType`/`TimeSlot`/`IntakeStatus` 모든 case가 `init(rawValue:)`로 복원되는지 (SwiftData 저장 후 로드 시뮬레이션)
2. **Supplement.capsuleType computed setter** — set 후 raw 일치
3. **UserSettings.time(for:)** — 3 슬롯 모두 기본값 반환 + 변경 후 반영
4. **UserSettings.timezone** — 잘못된 식별자 → `.current` 폴백
5. **IntakeLog.status computed** — `.skipped` 설정 후 raw `"skipped"` 일치

`@Model` 객체는 `ModelContainer`가 필요한데, **in-memory ModelContext 만들어서** 정상 insert/query 1개 (Supplement 생성 후 fetch) — 컨테이너 부팅 smoke test 포함.

```swift
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
    // ... TimeSlot, IntakeStatus
}

@Suite struct UserSettingsTests {
    @Test func defaultTimes() {
        let s = UserSettings()
        #expect(s.time(for: .morning) == (8, 0))
        #expect(s.time(for: .lunch) == (12, 30))
        #expect(s.time(for: .evening) == (19, 0))
    }

    @Test func timezoneFallback() {
        let s = UserSettings(timezoneIdentifier: "Not/AReal_Zone")
        #expect(s.timezone == TimeZone.current)
    }
}

@Suite struct ModelContainerSmokeTests {
    @Test func canInsertAndFetchSupplement() throws {
        let schema = Schema([Supplement.self, IntakeSchedule.self, IntakeLog.self, UserSettings.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)
        let s = Supplement(name: "Omega-3", capsuleType: .softgel)
        context.insert(s)
        try context.save()
        let fetched = try context.fetch(FetchDescriptor<Supplement>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.capsuleType == .softgel)
    }
}
```

### Step 10: 검증 + 보고서 + PR

1. `cd ios && xcodebuild -scheme PillPouch -sdk iphonesimulator build`
2. `cd ios && xcodebuild test -scheme PillPouch -destination 'platform=iOS Simulator,name=iPhone 15 Pro'`
3. `docs/report/task_W1_10_report.md` 작성 → 작업지시자 승인
4. PR 생성 (본문에 plans/report 링크 + 가설 체크)
5. CI 통과 후 squash merge

## 커밋 단위 (Conventional Commits)

```
docs: add W1-10 implementation plan
feat(ios): add CapsuleType/TimeSlot/IntakeStatus enums
feat(ios): add Supplement SwiftData model
feat(ios): add IntakeSchedule SwiftData model
feat(ios): add IntakeLog SwiftData model
feat(ios): add UserSettings SwiftData model with timezone helpers
chore(ios): remove Item.swift boilerplate
refactor(ios): clean ContentView to placeholder, update PillPouchApp Schema
test(ios): add domain enum + UserSettings + ModelContainer smoke tests
docs: add W1-10 final report
```

10커밋 내외. PR squash merge 시 main에 1 commit.

## 위험 요소

1. **PBXFileSystemSynchronizedRootGroup 동기화** — Xcode 16+의 자동 파일 동기화 그룹이라 디렉토리에 파일 추가만으로 빌드 포함. 단, 새 디렉토리 `Models/`는 SwiftSettings 영향 없음을 확인 (xcodebuild로 검증).
2. **SwiftData @Relationship inverse 컴파일 에러** — `inverse: \Supplement.schedules` keypath가 같은 schema 내에서만 작동. 컴파일 시 양쪽 정의 필요 — 한 PR에 묶어 같이 빌드.
3. **enum raw 패턴 vs 직접 enum** — SwiftData는 `Codable` enum 직접 저장 가능하나, CloudKit + 백엔드 wire format 호환성 위해 raw 명시 패턴 채택. 트레이드오프: boilerplate 약간 증가, 안전성/이식성 증가.
4. **Item.swift 제거 후 기존 SwiftData 스토어 호환** — 기존 Item 스토어는 Xcode 더미 데이터일 뿐, 시뮬레이터 wipe로 충분. Production 데이터 없음.
5. **이중 워크스페이스 충돌** — 워크스페이스 B(W1-4 design-system)가 main에 먼저 머지되면 `git fetch origin && git rebase origin/main`. 충돌은 `ContentView.swift` 잠재 — placeholder 유지 전략으로 충돌 표면 최소화.
6. **`UserSettings` 다중 인스턴스 방지** — 앱 측에서 부트스트랩 시 `if fetch().isEmpty { insert default) }` 필요. 이 PR에선 구조만 정의, 부트스트랩은 W1-5에서. (현재는 모델 정의만)

## 검증 (Issue #10 마감 조건)

- [ ] `cd ios && xcodebuild -scheme PillPouch -sdk iphonesimulator build` 성공
- [ ] `cd ios && xcodebuild test -scheme PillPouch -destination 'platform=iOS Simulator,name=iPhone 15 Pro'` 성공 (≥ 8 테스트 통과)
- [ ] `Item.swift` 부재 (`git ls-files | grep Item.swift` 빈 결과)
- [ ] `Supplement`, `IntakeSchedule`, `IntakeLog`, `UserSettings` 4개 `@Model` 존재
- [ ] `PillPouchApp.swift`의 Schema가 4개 모델 등록
- [ ] `ContentView.swift`가 placeholder 상태 (W1-5 통합 가능)
- [ ] PR `ios-build` workflow 통과
- [ ] PR 본문 가설 체크박스 + 계획서/보고서 링크 박힘

## 다음 (이 task 완료 후)

- W1-5 (Issue #5): Today 정적 레이아웃 — 이 PR이 깐 모델 위에서 `@Query<Supplement>`, `@Query<IntakeSchedule>` 사용
- W1-4 (다른 워크스페이스): design-system 색 토큰 — 이 PR과 독립
- W4: CloudKit 동기화 — 이 PR이 깐 Schema 그대로 + ModelConfiguration `cloudKitDatabase` 옵션 추가
