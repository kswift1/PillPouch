# task_W2_25_stage5.md — Stage 5 보고서: Torn → List Transition

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#25](https://github.com/kswift1/PillPouch/issues/25) |
| 마일스톤 | W2 |
| 크기 | L — Stage 5/5 (최종) |
| 브랜치 | `kswift1/task25-pouch-component` |
| 수행계획서 | [`task_W2_25.md`](../plans/task_W2_25.md) |
| 구현계획서 | [`task_W2_25_impl.md`](../plans/task_W2_25_impl.md) |
| 이전 보고서 | [stage1](task_W2_25_stage1.md) / [stage2](task_W2_25_stage2.md) / [stage3](task_W2_25_stage3.md) / [stage4](task_W2_25_stage4.md) |

## 스코프 변경

원래 구현계획서 §Stage 5 = "알약 낙하 애니메이션 + V컷 구멍 통과". 작업지시자 검토 결과:

> "낙하 말고 다른 방법은 없을까? 알약이 나와서 리스트로 보여지는 형태?"

낙하 → **list mode 전환** 으로 스코프 재정의. 기획 정합성:
- 가설 B 강화: 단순 시각 효과(낙하)보다 정보 전달(리스트) 가치 큼
- "기록 신뢰성" — 사용자가 무엇을 먹었는지 즉각 확인 가능

5개 transition 옵션 비교 후 작업지시자 결정: **옵션 1 + 4 결합**
- 옵션 1: 봉지가 통째로 fade-out + 자리에 리스트
- 옵션 4: 알약이 stagger 로 list slot 안착

## 산출물

### 신규 / 수정 파일

| 파일 | 변경 |
|---|---|
| `PillBody.swift` (수정) | `dose: Int` (회차) + `takenAt: Date?` (복용 시각) 필드 추가. mock factory: 1/3 알약은 2정. |
| `PouchView.swift` (수정) | `listMode: Bool` State + `pillsBeforeTear` 백업 + `syncListMode/startListLayout/restorePhysicsLayout` 함수. PaperTop/Bottom fade + offset transition. 알약 옆 라벨 layout B (이름 · 회차 + 우측 시각). |
| `Pills/PillBody.swift` (`PillCategoryDisplayName`) | 16종 카테고리 → 한글 라벨 mapping. CategoryMirror 미통합 시점이라 mock. |

## 동작 사양

### Transition (sealed → torn)

1. 사용자가 perforation 100% 까지 drag (또는 "찢기" 버튼) → `state = .torn`
2. `syncListMode` 호출 → `startListLayout(bounds:)`:
   - `pillsBeforeTear = pills` 백업 (봉합 시 복원용)
   - `listMode = true`
   - 모든 알약에 `takenAt = Date()` set (한 봉지 = 한 슬롯 = 동시 복용)
   - 알약별로 `withAnimation(.spring(0.55, 0.72).delay(index * 0.08))` 으로 list slot 위치로 spring
3. `paperLayerStack` 의 PaperTop/Bottom 이 `listMode` 따라 `opacity 0 + offset y -30, easeOut 0.45초` fade-out
4. 알약 옆 HStack 라벨 fade-in (`.transition(.opacity.combined(with: .offset(x: -8, y: 0)))`)

### Layout B (라벨 시각)

```
[💊]  오메가3 · 1정              7:23
[💊]  유산균 · 2정               7:23
[💊]  비타민 C · 1정             7:23
```

- HStack(width: 180): 좌측 `name · dose정` + Spacer + 우측 시각
- 좌측: `PPFont.body` + `PPColor.textPrimary`
- 우측: `.system(.callout, design: .monospaced)` + `PPColor.textSecondary`
- 시각 표시: `Text(takenAt, format: .dateTime.hour().minute())` — locale 자동 (한국 24h, 미국 12h)
- 알약 우측 30pt 부터 라벨 영역 시작

### Transition (torn → sealed)

1. "봉합" 버튼 → `state = .sealed`
2. `syncListMode` → `restorePhysicsLayout(bounds:)`:
   - `listMode = false`
   - `takenAt = nil` reset
   - 알약별 `withAnimation(.spring(0.45, 0.78))` 로 mock 위치 복원 (`pillsBeforeTear[i].position` 사용)
3. PaperTop/Bottom 이 fade-in + offset 복귀

### List Slot 위치 계산

```swift
private func listSlotPosition(index: Int, count: Int, bounds: CGRect) -> CGPoint {
    let rowSpacing = max(bounds.height / CGFloat(count + 1), 36)
    let x = bounds.minX + 30  // 좌측 정렬
    let y = bounds.minY + rowSpacing * CGFloat(index + 1)
    return CGPoint(x: x, y: y)
}
```

세로 균등 배치 (rowSpacing = height / (count+1)). 알약 8개일 때 알약끼리 너무 가깝지 않게 minRowSpacing 36pt 가드.

### Physics 정지

`advancePhysics(to:bounds:)` 에서 `guard !listMode else { return }` — torn 상태에선 `PillPhysicsEngine.tick` 호출 X. 알약 회전/속도/충돌 모두 정지. 라벨이 흔들리지 않음.

## 검증

### 빌드

```
xcodebuild -scheme PillPouch -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4' build
** BUILD SUCCEEDED **
```

### 테스트

`PillPhysicsEngine` 28/28 그대로 통과. List mode 는 SwiftUI animation/transition 영역 — UI 테스트 별도 (이번 stage 신규 unit test 없음).

### 시각 검증 (작업지시자 시뮬, image-v32)

- 알약 5개 list 정렬 자연스러움 ✅
- 한글 라벨 정확 ✅
- spring stagger 0.08초 부드러움 ✅
- 봉지 fade-out + slide up 깔끔 ✅

## 위험 / 박제

| 항목 | 상태 |
|---|---|
| 포물선 (옵션 4 사양) | spring 직선 보간으로 우선 시작. 시뮬 검증 결과 자연스럽다는 작업지시자 피드백 — KeyframeAnimator 업그레이드 보류 |
| takenAt 동시값 | 한 봉지 = 한 슬롯 동시 복용이라 모두 같은 시각. 실 사용 시 ±몇 초 차이는 무의미 |
| dose mock | `index.isMultiple(of: 3) ? 2 : 1` — 1/3 알약 2정. 실 데이터 (`Supplement.dose` 또는 `IntakeSchedule.dose`) 통합은 별도 task |
| 외부 UI (Today 화면) | "별도 task 로 미룸" 작업지시자 결정 — 이번 #25 외 |
| CategoryMirror.displayName 와 PillCategoryDisplayName 중복 | mock 한정 — Today 통합 시 CategoryMirror 사용 |

## 의사결정 박제

| 결정 | 값 | 이유 |
|---|---|---|
| 낙하 → list mode | 스코프 변경 | 가설 B 강화 — 정보 전달 > 시각 효과 |
| 옵션 1+4 결합 | 봉지 fade + stagger spring | 작업지시자 5개 옵션 비교 후 선택 |
| Stagger delay 0.08초 | spring + delay 자연스러운 흐름 | 0.05 너무 빠름, 0.12 늘어짐 |
| Spring response 0.55 / damping 0.72 | 부드러운 안착 | 0.4 너무 빠름, 0.7 늘어짐 |
| Layout B (이름 · 회차 + 시각) | 가설 B 강화 + 미니멀 균형 | A 너무 적음 (시각만), C timeline 별도 task, D 너무 풍부 |
| takenAt 동시값 | 단순 mock | 실제로는 봉지 단위 = 단일 시각 |
| dose 1/3 비율 2정 | mock 다양성 | 실 데이터 들어오면 Supplement 따라 |
| `physics tick` listMode 시 정지 | 라벨 안정성 | 라벨이 알약 따라가는데 알약 흔들리면 라벨도 흔들림 — 정지 |

## 누적 커밋 (Stage 5 전체)

```
55be703 feat(ios): add torn → list transition with stagger spring + paper fade (#25 stage5 prototype 1+4)
cb1c92b feat(ios): list mode label B — name·dose + time (#25 stage5 layout B)
```

## 다음 (Task #25 마무리 절차)

1. **Cleanup (B)** — perforationY magic number 통일 / PouchTearLayer.swift 파일명
2. **CI 검증 + PR description** — 모든 stage 통합, 가설 B 체크
3. **main squash merge**

이후 별도 task:
- 외부 UI / Today 화면 (3봉지 띠) — `docs/brief.md` §화면 + 작업지시자 외부 UI 논의 그대로 가져감
- 실 데이터 통합 — Supplement, IntakeSchedule, IntakeLog 와 PouchView 연결

## 승인 ⛔
