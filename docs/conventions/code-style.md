# code-style.md — 코드 스타일 컨벤션

언어/프레임워크 무관 코드 스타일 룰. LLM과 사람 모두 따른다. 이 룰은 **추후에도 계속 유지**된다 — 변경 시 PR + 이 파일 갱신.

---

## 1. 테스트 메서드명은 한글 + 언더바

Swift Testing / XCTest의 테스트 메서드 이름은 **한글 + 언더바(`_`) 구분**으로 작성한다.

### 이유

- 테스트는 명세(spec)다. 영어 camelCase는 한글 모국어 화자에게 가독성 손실.
- 테스트 실패 로그에 한글 메서드명이 그대로 박히면 무엇이 깨졌는지 한 줄 읽기로 즉시 이해.
- 한글 식별자는 Swift가 정식 지원 (Unicode identifier).

### 형식

```swift
@Test func 캡슐타입_raw값_왕복_복원() { ... }
@Test func 캡슐타입_잘못된_raw_입력시_capsule로_폴백() { ... }
@Test func 사용자설정_기본_슬롯시각_반환() { ... }
@Test func 모델컨테이너_supplement_삽입_후_조회() { ... }
@Test func cascade_삭제시_하위_schedule과_log_제거() { ... }
```

규칙:
- **언더바로 단어 구분** (camelCase X, 띄어쓰기 X)
- **주어 → 조건 → 기대결과** 순서 권장 (예: `사용자설정_잘못된_타임존_입력시_current로_폴백`)
- 영문 식별자(타입명, raw 값 등)는 그대로 둔다 (예: `CapsuleType`, `raw`, `cascade`)
- 약어는 그대로 (예: `id`, `raw`, `UUID`)

### Suite 이름

Suite는 영문 PascalCase 유지. Suite는 "도메인 묶음" 라벨이라 코드 검색·필터에서 영문이 더 안전.

```swift
@Suite struct EnumRoundtripTests {
    @Test func 캡슐타입_raw값_왕복_복원() { ... }
}
```

### 예외

- 외부 라이브러리/오픈소스 PR — 해당 프로젝트 컨벤션 따름
- 성능 테스트 (`testLaunchPerformance` 등) — Apple 표준 시그니처가 영문이면 그대로

---

## 2. Enum case 주석 — case별 doc-comment

`enum`을 정의할 때:

1. **enum 자체에 `///` 설명** — 무엇을 표현하는 enum인가
2. **각 case에도 `///` 설명** — 이 case가 무엇을 의미하는가, 언제 쓰는가

### 형식

```swift
/// 봉지 안 캡슐의 시각적 형태 — 기획서 §캡슐 일러스트 6종.
/// 봉지 SVG 렌더링과 영양제 등록 화면 Picker에서 사용.
enum CapsuleType: String, Codable, CaseIterable {
    /// 정제. 단단한 압축 형태.
    case tablet

    /// 소프트젤. 액상이 부드러운 캡슐 안에 든 형태.
    case softgel

    /// 일반 캡슐. 가루/분말이 든 단단한 캡슐.
    case capsule

    /// 가루 (스틱팩 등).
    case powder

    /// 액상 (드롭).
    case liquid

    /// 구미. 젤리 형태.
    case gummy
}
```

### 한 줄 case 묶음 금지

```swift
// ❌ 금지 — case별 의미 불명
enum TimeSlot: String { case morning, lunch, evening }

// ✅ 권장
/// 하루 3슬롯 — 기획서 §화면 구조.
enum TimeSlot: String {
    /// 아침 슬롯. `UserSettings.morningHour/Minute` 사용.
    case morning

    /// 점심 슬롯. `UserSettings.lunchHour/Minute` 사용.
    case lunch

    /// 저녁 슬롯. `UserSettings.eveningHour/Minute` 사용.
    case evening
}
```

### 예외

- **순수 내부 helper enum**으로 case 이름이 자체 설명적인 경우 (예: `enum Direction { case left, right }`) — 단, 외부 노출 가능성 있으면 작성

### 적용 범위

- Swift `enum`
- Rust `enum` (도메인 표현형)
- TypeScript `enum`/union literal type
- 같은 원칙: "타입 설명 + 각 변종 설명"

---

## 3. 박제 + 유지

이 파일은 **유지되는 룰**이다.
- 새 LLM 협업 세션에서도 참조됨 (`CLAUDE.md` → `docs/conventions/`)
- 이 룰을 위반한 코드를 발견하면 같은 PR에서 수정 + 검토자에게 룰 링크
- 룰 변경은 PR + 이 파일 직접 수정 (메모리/로컬 박제 금지 — `ai-collab-meta.md` §2 참조)

---

## 변경 이력

- 2026-04-28: 초기 작성 (W1-10 PR) — 테스트 메서드 한글 + enum case doc-comment 두 룰
