# task_W2_16_impl.md — Supplement 모델 마이그레이션 (CapsuleType → categoryKey + CategoryMirror) 구현계획서

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#16](https://github.com/kswift1/PillPouch/issues/16) |
| 마일스톤 | W2 |
| 크기 | M |
| 영역 | area:ios |
| 타입 | type:refactor |
| 브랜치 | `local/task16` |
| 의존 | [#15](https://github.com/kswift1/PillPouch/issues/15) merged (ADR-0007/0008) |
| 예상 시간 | 2~3시간 (모델 변경 + 테스트 업데이트 + 빌드 검증) |

## 목표

[ADR-0007](../adr/0007-server-catalog-as-source-of-truth.md) 결정에 따라 W1-10 데이터 모델을 갱신:
- **`CapsuleType` enum 폐기** (형태 분류는 사용자 인지 본질이 아님)
- **`Supplement.capsuleTypeRaw` 필드 제거** + **`categoryKey: String` 필드 신설** (서버 카탈로그 row의 lowerCamel key 참조)
- **`CategoryMirror` SwiftData @Model 신설** — 서버 SoT 카탈로그의 클라이언트 mirror

#17(시드 자산)·#18(백엔드)·#19(모바일 동기화) 모두의 의존 — 본 task 머지가 후속 task의 시작점.

## 비목표 (이번 task에서 안 하는 것)

- ❌ 시드 동봉 (별도 issue [#17](https://github.com/kswift1/PillPouch/issues/17))
- ❌ Mirror 동기화 로직 (별도 issue [#19](https://github.com/kswift1/PillPouch/issues/19))
- ❌ 검색 UI (별도 issue [#19](https://github.com/kswift1/PillPouch/issues/19))
- ❌ 백엔드 endpoint (별도 issue [#18](https://github.com/kswift1/PillPouch/issues/18))
- ❌ ADR 본문 갱신 (#15에서 박제 완료)
- ❌ Supplement에 SKU 참조 추가 (V1.1 별도 task)

## 변경 사항

### 1. `ios/PillPouch/Models/Enums.swift` — `CapsuleType` 삭제

기존 파일에서 `CapsuleType` enum 블록 제거 (line 8~28). `TimeSlot`, `IntakeStatus`는 그대로 유지.

### 2. `ios/PillPouch/Models/Supplement.swift` — 필드 교체

**제거**:
- `var capsuleTypeRaw: String`
- `var capsuleType: CapsuleType { get/set }` computed property
- `init` 파라미터 `capsuleType: CapsuleType`

**추가**:
- `var categoryKey: String` — `CategoryMirror.key` 참조 (clientside FK, V1.0 시드 12종 + 서버 추가 카테고리)
- `init` 파라미터 `categoryKey: String`

**문서**:
- 클래스 `///` 주석에 "categoryKey는 서버 카탈로그 row의 lowerCamel key (예: `vitaminD`)" 명시
- ADR-0007 링크

### 3. `ios/PillPouch/Models/CategoryMirror.swift` — 신설

[ADR-0007](../adr/0007-server-catalog-as-source-of-truth.md) §데이터 모델 schema 그대로:

```swift
import Foundation
import SwiftData

/// 서버 카탈로그(영양제 카테고리)의 클라이언트 mirror.
/// 첫 실행 시 번들 시드(JSON 12 row)에서 import, 이후 서버 동기화로 갱신.
/// `Supplement.categoryKey`가 본 모델의 `key`를 참조 (clientside FK).
/// 서버 SoT — 본 mirror는 read-only 캐시 (사용자 직접 편집 X).
@Model
final class CategoryMirror {
    /// 서버 카탈로그 PRIMARY KEY (lowerCamel, 예: "vitaminD").
    @Attribute(.unique) var key: String

    /// 한글 표시명 (예: "비타민 D"). 서버에서 내려오는 사용자 노출 텍스트.
    var displayName: String

    /// 다운로드된 이미지의 로컬 파일 path. 미다운로드 시 nil → `iconRemoteURL` fallback.
    var iconLocalPath: String?

    /// 서버 hosting 이미지 URL (Fly static, ADR-0008).
    var iconRemoteURL: URL

    /// 검색/리스트 UI 정렬 순서. 작을수록 위.
    var displayOrder: Int

    /// 서버 카탈로그 row 버전 (cache invalidation, since 파라미터).
    var version: Int

    /// 마지막 동기화 시각.
    var updatedAt: Date

    init(
        key: String,
        displayName: String,
        iconLocalPath: String? = nil,
        iconRemoteURL: URL,
        displayOrder: Int,
        version: Int,
        updatedAt: Date = .now
    ) {
        self.key = key
        self.displayName = displayName
        self.iconLocalPath = iconLocalPath
        self.iconRemoteURL = iconRemoteURL
        self.displayOrder = displayOrder
        self.version = version
        self.updatedAt = updatedAt
    }
}
```

`@Relationship` 양방향 X — `Supplement.categoryKey`는 단순 String 참조 (clientside FK). 서버 카탈로그가 SoT라 mirror에서 row 삭제돼도 historical supplement는 보존 (UI에서 fallback "기타" 표시).

### 4. `ios/PillPouch/PillPouchApp.swift` — Schema 갱신

```swift
let schema = Schema([
    Supplement.self,
    IntakeSchedule.self,
    IntakeLog.self,
    UserSettings.self,
    CategoryMirror.self,   // 추가
])
```

V1 출시 전이라 마이그레이션 SQL 불필요. `isStoredInMemoryOnly: false`라도 사용자 데이터 0이라 단순 schema reset.

### 5. `ios/PillPouchTests/PillPouchTests.swift` — 테스트 업데이트

#### 제거할 테스트 (CapsuleType 의존)
- `EnumRoundtripTests.캡슐타입_raw값_왕복_복원` (line 12~15)
- `EnumRoundtripTests.캡슐타입_raw값_안정성_고정` (line 30~37)
- `SupplementComputedTests` 전체 Suite (line 53~66, 2 tests) — `capsuleType` computed property 제거로 의미 없어짐

#### 수정할 fixtures (`Supplement(capsuleType:)` → `Supplement(categoryKey:)`)
- line 70: `Supplement(name: "비타민C", capsuleType: .tablet)` → `Supplement(name: "비타민C", categoryKey: "vitaminC")`
- line 79: 동일
- line 136: `Supplement(name: "오메가-3", capsuleType: .softgel)` → `Supplement(name: "오메가-3", categoryKey: "omega3")`
- line 142: `fetched.first?.capsuleType == .softgel` → `fetched.first?.categoryKey == "omega3"`
- line 148: 동일 패턴

#### 신규 테스트 — `CategoryMirrorTests` Suite
```swift
@Suite struct CategoryMirrorTests {
    @Test func 카테고리미러_초기화_필드_보존()
    @Test func 카테고리미러_저장_후_조회()    // ModelContainer 사용
    @Test func 카테고리미러_key_unique_제약()
}
```

테스트 메서드명은 `docs/conventions/code-style.md` §1 한글+언더바 패턴 준수.

### 6. SwiftData fetch / @Query 영향 점검

기존 코드에서 `Supplement.capsuleType` 또는 `capsuleTypeRaw`를 참조하는 view/logic 있으면 동시 갱신 필요. **현재 main에 `ContentView.swift` placeholder만 있어 영향 없음** (W1-10 보고서 확인). #14 Today 화면이 시작되기 전이라 안전.

## 위험 요소

1. **W1-10 보고서의 W1 도메인 unit test 14건이 8건으로 줄어듦** — `EnumRoundtripTests` 6건 + `SupplementComputedTests` 2건이 제거되고 `CategoryMirrorTests` 3건이 추가되어 11건. 단순 카운트 줄어듦은 회귀 X (기능 분기 자체가 사라짐). 보고서에 명시.
2. **`@Attribute(.unique) var key: String`이 SwiftData에서 supported인지** — `Supplement.id`(UUID)가 이미 unique attribute로 사용 중이라 String 타입에도 동작 가정. 빌드 단계에서 검증. 안 되면 `@Attribute(.unique)` 빼고 application-level uniqueness 강제.
3. **`URL`을 SwiftData 필드로 직접 저장** — SwiftData가 `URL` 타입 직접 지원. 안 되면 `String`으로 저장 후 computed property로 노출.
4. **#17/19 등 후속 task가 `CategoryMirror` API 가정과 어긋날 가능성** — ADR-0007 §schema와 100% 일치하므로 위험 낮음. 발견 시 본 task에 follow-up 커밋 또는 후속 task에서 모델 보강.
5. **`PBXFileSystemSynchronizedRootGroup` 사용 중** — `ios/PillPouch/Models/CategoryMirror.swift` 신규 파일은 자동 빌드 포함, pbxproj 수정 불필요.

## 구현 단계 (단일 PR)

### Step 1: 모델 파일 변경
- `Enums.swift` — `CapsuleType` 블록 제거
- `Supplement.swift` — 필드/init 갱신
- `CategoryMirror.swift` — 신규 파일

### Step 2: Schema 갱신
- `PillPouchApp.swift` — `CategoryMirror.self` 추가

### Step 3: 테스트 업데이트
- `PillPouchTests.swift` — `CapsuleType` 의존 테스트 제거 + fixtures 갱신
- `CategoryMirrorTests` 신규 Suite 추가 (3 test)

### Step 4: 빌드 + 테스트 검증
- `xcodebuild build -scheme PillPouch -sdk iphonesimulator` 통과
- `xcodebuild test ...` 모든 Suite pass
- `Item.swift` 부재 그대로 (W1-10 결과 유지)
- 새로 추가한 `CategoryMirror` SwiftData 모델이 ModelContainer 초기화에서 fail 안 함

### Step 5: 보고서 + PR
- `docs/report/task_W2_16_report.md` 작성 → 작업지시자 승인 ⛔
- PR 본문에 계획서/보고서 링크 + 가설 B 체크 + Non-goals 체크
- `Closes #16`

## 커밋 단위 (Conventional Commits)

```
docs: add W2-16 (#16) implementation plan
refactor(ios): remove CapsuleType enum (superseded by ADR-0007)
feat(ios): add CategoryMirror @Model + categoryKey field on Supplement
test(ios): replace CapsuleType tests with CategoryMirror suite
docs: add W2-16 final report
```

5 commit, squash 후 main에 1 commit.

## 검증 (Issue #16 마감 조건)

- [ ] `CapsuleType` enum 부재 (`grep -r "CapsuleType" ios/` → 결과 0)
- [ ] `Supplement.categoryKey: String` 필드 존재
- [ ] `Supplement.capsuleTypeRaw`, `capsuleType` 부재
- [ ] `CategoryMirror` SwiftData @Model 존재 + Schema 등록
- [ ] `xcodebuild build` ✅, `xcodebuild test` ✅ (모든 Suite pass)
- [ ] `docs/report/task_W2_16_report.md` 작성 + 작업지시자 승인
- [ ] PR squash merge, Issue #16 자동 close

## 가설 B 정합성

- ✅ 데이터 모델 변경, 가설 B(기록 신뢰성) 강화 무관 — 인프라 정합성 작업
- ✅ Non-goals(TCA, Carousel, 단순 탭) 어느 항목도 추가하지 않음
- ✅ `IntakeLog` 비가역 행동 기록 모델은 그대로 유지 — 가설 B 핵심 변경 없음

## 다음 (이 task 완료 후)

- [#17](https://github.com/kswift1/PillPouch/issues/17) (시드 자산): 본 task의 `CategoryMirror.key` 매핑 그대로 12 row 박제
- [#18](https://github.com/kswift1/PillPouch/issues/18) (백엔드): 같은 schema의 SQLite `category` 테이블 + endpoint
- [#19](https://github.com/kswift1/PillPouch/issues/19) (모바일 동기화/UI): 본 task `CategoryMirror`에 서버 응답 upsert + 검색 UI에 `@Query<CategoryMirror>`
- [#14](https://github.com/kswift1/PillPouch/issues/14) (Today 정적 레이아웃): 본 task 마무리 후 자연스러운 후속 — 봉지 띠에 `Supplement.categoryKey` → `CategoryMirror` 조회 → 이미지 표시
