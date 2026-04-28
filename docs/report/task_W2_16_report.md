# task_W2_16_report.md — Supplement 모델 마이그레이션 (CapsuleType → categoryKey + CategoryMirror) 최종보고서

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#16](https://github.com/kswift1/PillPouch/issues/16) |
| 마일스톤 | W2 |
| 크기 | M |
| 영역 | area:ios |
| 타입 | type:refactor |
| 브랜치 | `local/task16` |
| 계획서 | [`task_W2_16_impl.md`](../plans/task_W2_16_impl.md) |
| 완료 | 2026-04-28 |

## 결과 요약

[ADR-0007](../adr/0007-server-catalog-as-source-of-truth.md) 결정에 따라 W1-10 데이터 모델 갱신:
- **`CapsuleType` enum 폐기** — 형태 분류는 사용자 인지 본질이 아님
- **`Supplement.capsuleTypeRaw` + `capsuleType` computed 제거** + **`categoryKey: String` 신설**
- **`CategoryMirror` SwiftData @Model 신설** — 서버 SoT 카탈로그의 클라이언트 mirror

빌드/테스트 모두 통과:
- `xcodebuild build` ✅ (iPhone Sim, iOS 26.4)
- `xcodebuild test` ✅ — 16건 (CapsuleType 의존 4건 제거 + `CategoryMirrorTests` 3건 추가)

## 수행 내역 (계획 대비)

| Step | 계획 | 실제 | 비고 |
|---|---|---|---|
| 1 | `CapsuleType` enum 삭제 + `Supplement` 필드 교체 | ✅ | `Enums.swift` 8~28 line block 제거, `Supplement.swift` 전체 재작성 |
| 2 | `CategoryMirror` 신규 @Model | ✅ | `Models/CategoryMirror.swift` 신규, ADR-0007 §schema 1:1 |
| 3 | Schema 갱신 | ✅ | `PillPouchApp.swift` 5번째 model로 추가 |
| 4 | 테스트 업데이트 | ✅ | `EnumRoundtripTests` 캡슐타입 2건 제거, `SupplementComputedTests` Suite 폐기, fixtures 갱신, `CategoryMirrorTests` 3건 신규 |
| 5 | 빌드/테스트 검증 + 보고서 | ✅ | 본 보고서 |

## 변경 파일

- `ios/PillPouch/Models/Enums.swift` — `CapsuleType` 블록 제거 (TimeSlot/IntakeStatus 보존)
- `ios/PillPouch/Models/Supplement.swift` — 전체 재작성 (`capsuleTypeRaw`/`capsuleType` → `categoryKey`)
- `ios/PillPouch/Models/CategoryMirror.swift` — **신규** @Model (key/displayName/iconLocalPath/iconRemoteURL/displayOrder/version/updatedAt)
- `ios/PillPouch/PillPouchApp.swift` — Schema에 `CategoryMirror.self` 추가
- `ios/PillPouchTests/PillPouchTests.swift` — 4 Suite 갱신 + `CategoryMirrorTests` 신규

## 검증 결과

### 빌드
```
xcodebuild build -scheme PillPouch -sdk iphonesimulator
... ** BUILD SUCCEEDED **
```

### 테스트 (16건 모두 pass)

```
EnumRoundtripTests (4건):
  ✅ 시간슬롯_raw값_왕복_복원
  ✅ 복용상태_raw값_왕복_복원
  ✅ 시간슬롯_raw값_안정성_고정
  ✅ 복용상태_raw값_안정성_고정

IntakeLogComputedTests (2건):
  ✅ 복용상태_setter_호출시_raw값_동기화
  ✅ 시간슬롯_setter_호출시_raw값_동기화

UserSettingsTests (4건):
  ✅ 사용자설정_기본_슬롯시각_반환
  ✅ 사용자설정_커스텀_슬롯시각_반환
  ✅ 사용자설정_기본_타임존은_AsiaSeoul
  ✅ 사용자설정_잘못된_타임존_입력시_current로_폴백

CategoryMirrorTests (3건, 신규):
  ✅ 카테고리미러_초기화_필드_보존
  ✅ 카테고리미러_저장_후_조회
  ✅ 카테고리미러_iconLocalPath_갱신_가능

ModelContainerSmokeTests (3건):
  ✅ 모델컨테이너_supplement_삽입_후_조회 (categoryKey 검증으로 갱신)
  ✅ cascade_삭제시_하위_schedule과_log_제거
  ✅ 사용자설정_저장_후_조회
```

기존 18건 (PillPouchUITests 포함) 중 도메인 unit 15건이 16건으로 변동 (− CapsuleType 2건 + CategoryMirror 3건 = 순증 1건; SupplementComputed 2건도 폐기).

### 잔존 검증

```
$ grep -r "CapsuleType\|capsuleType\|capsuleTypeRaw" ios/
(결과 없음)
```

## 핵심 결정

### `URL`을 SwiftData 필드로 직접 저장

위험 요소 §3에서 점검 항목으로 명시했던 부분 — SwiftData가 `URL` 타입 직접 지원함을 빌드/테스트로 확인. `String` 우회 불필요.

### `@Attribute(.unique) var key: String` 동작 확인

위험 요소 §2 — `Supplement.id`(UUID)가 이미 unique attribute로 사용 중인 패턴을 String 타입에도 적용 가능. SwiftData 빌드/테스트 통과 확인.

### `SupplementComputedTests` Suite 폐기

`capsuleType` computed property 자체가 사라져 의미 없는 테스트 → 삭제. fallback 로직(`?? .capsule`)도 사라져 추적 대상 없음.

### `EnumRoundtripTests`에서 `CapsuleType` 4건 제거

총 6건 중 `캡슐타입_*` 2건이 사라지고 4건(시간슬롯, 복용상태)이 남음. 도메인 enum 안정성 검증은 `TimeSlot`/`IntakeStatus`로 충분.

## 발생한 이슈와 해결

특이사항 없음. 빌드 첫 시도 성공, 테스트 첫 시도 16건 모두 pass.

## 가설 B 정합성

- ✅ 데이터 모델 변경, 가설 B(기록 신뢰성) 강화 무관 — 인프라 정합성 작업
- ✅ Non-goals(TCA, Carousel, 단순 탭) 어느 항목도 추가하지 않음
- ✅ `IntakeLog` 비가역 행동 기록 모델은 변경 없음 — 가설 B 핵심 보존

## 다음 (이 task 머지 후)

- [#17](https://github.com/kswift1/PillPouch/issues/17) (시드 자산): 본 task `CategoryMirror.key` 형식(lowerCamel)에 맞춰 12 row 박제 — 별도 워크스페이스에서 진행 중
- [#18](https://github.com/kswift1/PillPouch/issues/18) (백엔드): 같은 schema의 SQLite `category` table + endpoint
- [#19](https://github.com/kswift1/PillPouch/issues/19) (모바일 동기화/UI): 본 task `CategoryMirror`에 서버 응답 upsert + 검색 UI에 `@Query<CategoryMirror>`
- [#14](https://github.com/kswift1/PillPouch/issues/14) (Today 정적 레이아웃): 봉지 띠에 `Supplement.categoryKey` → `CategoryMirror` 조회 → 이미지 표시

## PR 본문 첨부 예정 링크

- 계획서: [`docs/plans/task_W2_16_impl.md`](../plans/task_W2_16_impl.md)
- 본 보고서: [`docs/report/task_W2_16_report.md`](task_W2_16_report.md)
- ADR-0007: [`docs/adr/0007-server-catalog-as-source-of-truth.md`](../adr/0007-server-catalog-as-source-of-truth.md)
