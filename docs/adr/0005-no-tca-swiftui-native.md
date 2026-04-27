# ADR-0005: SwiftUI 네이티브 + SwiftData (TCA 미사용)

## Status
Accepted — 2026-04-27

## Context
기획서 v0.4 §기술 스택. iOS 앱 아키텍처 선택. 후보:

- **SwiftUI 네이티브 + SwiftData**: Apple 표준, `@Model`/`@Query`/`@Observable`, Preview 빠름
- **SwiftUI + TCA(The Composable Architecture)**: 강력한 테스트 가능성, Reducer 패턴, 학습 비용 + 보일러플레이트

기획서 §V0.4 변경에서 이미 "SwiftUI + TCA → SwiftUI 네이티브 + SwiftData" 결정됨. 이 ADR은 그 결정을 박제 + 재검토 조건 명시.

솔로 V1 6주 일정에 TCA는 과함. 기획서 §Non-goals에 명시:
> ❌ TCA — 솔로 V1엔 과함. SwiftUI 네이티브로 충분. V2 검토.

## Decision
- **UI**: SwiftUI 네이티브
- **데이터**: SwiftData (`@Model` + `@Query` + `@Environment(\.modelContext)`)
- **상태 관리**: 화면별 적응 패턴
  - 단순 화면(Supplements CRUD 등): `@Query`만으로 충분
  - 복잡 화면(Today 드래그 인터랙션): `@Observable` ViewModel
- **CloudKit 동기화**: SwiftData native 지원 사용 (W4)
- **테스트**: Swift Testing (Xcode 16+, `@Test` 매크로)
- **TCA**: **미사용**

라벨: "MV + 화면별 ViewModel" 또는 "@Observable 패턴".

## Consequences

### 긍정
- 학습/셋업 비용 0 (Apple 표준)
- Preview/iteration 빠름 (in-memory ModelContainer로 Sample 데이터)
- SwiftData CloudKit 동기화 native (W4 작업 단순화)
- iOS 17.2+ 타깃이라 모든 최신 기능 활용 가능

### 부정 / 트레이드오프
- 복잡 화면(드래그 인터랙션) 상태 관리 패턴이 화면별로 다를 수 있음 → 일관성 약함 가능 (단, 패턴 자체는 표준)
- TCA의 Reducer 테스트 가능성 부재 → 도메인 로직 unit 테스트는 별도 helper 함수로 분리 필요
- TCA 생태계의 dependency injection / navigation stack 같은 패키지 미사용

### 재검토 조건 (V2에서 TCA 도입 검토)

다음 중 **2개 이상** 충족 시:
1. 화면 10개 이상
2. CloudKit 충돌 해결 로직이 복잡해짐
3. 가족 공유 등 멀티 유저 상태 동기화
4. 외부 API 다발 (HealthKit, 식약처 등)
5. 테스트 커버리지 본격 필요 (CI 게이트 강화)
6. 협업자 합류

## 참고
- 기획서 §기술 스택 + §Non-goals + §V0.4 변경
- Plan §결정사항 §기술 스택
