# task_W1_10_report.md — SwiftData 모델 4종 + Item 제거 최종보고서

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#10](https://github.com/kswift1/PillPouch/issues/10) |
| 마일스톤 | W1 |
| 크기 | M |
| 영역 | area:ios |
| 타입 | type:feat |
| 브랜치 | `local/task10` |
| 계획서 | [`task_W1_10_impl.md`](../plans/task_W1_10_impl.md) |
| 완료 | 2026-04-28 |

## 결과 요약

기획서 §데이터 모델 스케치의 4종 SwiftData `@Model`을 정의하고 Xcode boilerplate(`Item.swift`)를 제거했다. 모든 프로퍼티/enum case에 `///` doc-comment가 박혀 후속 화면 작업자가 모델 의도를 즉시 읽을 수 있다.

부수 산출물로 **`docs/conventions/code-style.md` 신설** — 테스트 메서드 한글 + 언더바, enum case별 doc-comment 두 룰 박제. 본 PR에 즉시 적용 (테스트 14건 한글 변경, enum 12 case에 case별 주석).

빌드/테스트 모두 통과:
- `xcodebuild build` ✅ (iPhone 17 Sim, iOS 26.4)
- `xcodebuild test` ✅ — 도메인 unit 14건 (한글 식별자) + UI 6건 모두 pass

## 수행 내역 (계획 대비)

| Step | 계획 | 실제 | 비고 |
|---|---|---|---|
| 1 | enum 3종 (`Enums.swift`) | ✅ | 3 enum + 각 doc-comment |
| 2 | `Supplement` @Model | ✅ | `@Relationship(.cascade, inverse:)` 양방향 |
| 3 | `IntakeSchedule` @Model | ✅ | `supplement: Supplement?` (SwiftData 요구) |
| 4 | `IntakeLog` @Model | ✅ | computed `timeSlot`/`status` 양쪽 |
| 5 | `UserSettings` @Model + helpers | ✅ | `time(for:)` + `timezone` 폴백 |
| 6 | `Item.swift` 제거 | ✅ | `git rm` |
| 7 | `ContentView.swift` placeholder | ✅ | W1-5 통합 표면 최소화 |
| 8 | `PillPouchApp.swift` Schema 갱신 | ✅ | 4모델 등록 |
| 9 | Swift Testing unit | ✅ | 5 Suite, 14 Test |
| 10 | xcodebuild 검증 + 보고서 + PR | ✅ | 본 PR |

## 검증 결과

### 빌드
```
$ xcodebuild -scheme PillPouch -sdk iphonesimulator \
    -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4' build
** BUILD SUCCEEDED **
```

### 테스트 (14 도메인 + 6 UI = 20 통과)

| Suite | 테스트 | 결과 |
|---|---|---|
| EnumRoundtripTests | 6 (CapsuleType/TimeSlot/IntakeStatus × 왕복+raw 안정성) | ✅ |
| SupplementComputedTests | 2 (computed setter, 잘못된 raw 폴백) | ✅ |
| IntakeLogComputedTests | 2 (status, timeSlot computed setter) | ✅ |
| UserSettingsTests | 4 (기본/커스텀 시각, 타임존 폴백) | ✅ |
| ModelContainerSmokeTests | 3 (insert/fetch, cascade delete, UserSettings persist) | ✅ |
| PillPouchUITests + Launch | 6 (기존 테스트, 변경 후 회귀 없음) | ✅ |

`** TEST SUCCEEDED **` 확인.

### 정리
- `git ls-files | grep Item.swift` → 빈 결과 ✅
- `Schema([Supplement.self, IntakeSchedule.self, IntakeLog.self, UserSettings.self])` 4모델 등록 ✅
- `ContentView`는 `Text("Pill Pouch")` placeholder (W1-5에서 Today 화면으로 대체) ✅
- DesignSystem/Tokens 영역 무수정 (워크스페이스 B 충돌 회피) ✅

## 계획 대비 변경

없음. enum raw 패턴 / `@Relationship` 양방향 / Hour-Minute Int 분리 / placeholder ContentView 모두 계획 그대로.

## 위험 요소 회고

| 위험 | 결과 |
|---|---|
| PBXFileSystemSynchronizedRootGroup 자동 동기화 | `Models/` 폴더 생성만으로 빌드 포함 ✅ — pbxproj 수정 불필요 확인 |
| `@Relationship(inverse:)` 컴파일 의존성 | 한 PR에 4모델 묶었으므로 단일 빌드에서 해소 ✅ |
| enum raw vs 직접 enum | raw 채택 — CloudKit 호환성 + 백엔드 wire 호환 + 테스트 안정 ✅ |
| Item.swift 제거 후 스토어 호환 | 더미 데이터 — Production 영향 없음 ✅ |
| 워크스페이스 B(W1-4) main 충돌 | `ContentView` placeholder 전략으로 충돌 표면 0 ✅ |
| `UserSettings` 다중 인스턴스 방지 | 본 PR 비포함 (W1-5에서 부트스트랩 헬퍼 추가 예정) — 의도된 미해결 |

## 가설 검증 체크

- [x] **가설 B(기록 신뢰성) 강화** — `IntakeLog`가 비가역 행동 기록의 SoT, `Supplement`/`Schedule`/`Settings`가 그 기록의 컨텍스트를 정의
- [x] **Non-goals 미해당** — TCA 미사용, Carousel 무관, 단순 탭 체크 무관

## 후속 액션

- **W1-5 (Issue #5)**: Today 정적 레이아웃 — 본 PR이 깐 모델 위에서 `@Query` 시작점. `UserSettings` 부트스트랩 헬퍼는 거기서 추가.
- **W1-4 (다른 워크스페이스)**: design-system 색 토큰 — 본 PR과 독립, Supplement.colorToken이 W1-4 결과물 참조 예정.
- **W4**: CloudKit 동기화 — 본 PR Schema 그대로 + ModelConfiguration `cloudKitDatabase` 옵션만 추가.
- **W3 (백엔드)**: `UserSettings.timezoneIdentifier` + 슬롯 시각이 PTS 스케줄러의 입력 — wire format 정의 시 raw 그대로 사용 가능.

## 컨벤션 신설 (부수 산출)

작업 중 작업지시자 지적으로 두 룰을 [`docs/conventions/code-style.md`](../conventions/code-style.md)에 박제 + 본 PR 즉시 적용:

1. **테스트 메서드명 한글 + 언더바** — `주어_조건_기대결과` 패턴
   - 예: `캡슐타입_raw값_왕복_복원`, `사용자설정_잘못된_타임존_입력시_current로_폴백`
   - Suite는 영문 PascalCase 유지 (코드 검색 안전성)
2. **enum case별 `///` doc-comment** — enum 자체 + 모든 case 설명
   - 한 줄 case 묶음 (`case a, b, c`) 금지
   - 적용: `CapsuleType`(6 case), `TimeSlot`(3), `IntakeStatus`(3) 모두 case별 주석

`CLAUDE.md` 핵심 룰 요약에 1줄 추가, `docs/conventions/README.md` 색인 갱신.

## 커밋 (13개)

```
docs: add W1-10 implementation plan
feat(ios): add CapsuleType/TimeSlot/IntakeStatus domain enums
feat(ios): add Supplement SwiftData model with cascade relationships
feat(ios): add IntakeSchedule SwiftData model
feat(ios): add IntakeLog SwiftData model
feat(ios): add UserSettings SwiftData model with timezone helpers
chore(ios): remove Item.swift boilerplate
refactor(ios): clean ContentView placeholder, register 4 models in Schema
test(ios): add domain enum + model + ModelContainer smoke tests
docs(conventions): add code-style.md (Korean test names + enum case doc-comments)
docs(ios): add per-case doc-comments to domain enums
test(ios): rename test methods to Korean per code-style convention
docs: add W1-10 final report
```

PR squash merge 시 main에 1 commit으로 박힘.
