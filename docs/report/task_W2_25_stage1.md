# task_W2_25_stage1.md — Stage 1 보고서: 봉지 시각 (정적, Sealed)

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#25](https://github.com/kswift1/PillPouch/issues/25) |
| 마일스톤 | W2 |
| 크기 | L — Stage 1/5 |
| 브랜치 | `kswift1/task25-pouch-component` |
| 수행계획서 | [`docs/plans/task_W2_25.md`](../plans/task_W2_25.md) |
| 구현계획서 | [`docs/plans/task_W2_25_impl.md`](../plans/task_W2_25_impl.md) |

## 산출물

### 신규 파일

| 파일 | 역할 |
|---|---|
| `ios/PillPouch/Features/Pouch/PouchState.swift` | 상태 enum (sealed/tearing/torn) + case별 doc-comment |
| `ios/PillPouch/Features/Pouch/PouchPaperLayer.swift` | 7-layer 글라싱지 합성 (paperBody/fiberTexture/topPrintBand/wrinkleHighlight/heatSeal/tearMarker) |
| `ios/PillPouch/Features/Pouch/PouchView.swift` | 단일 봉지 컴포넌트 shell. `state` props 받음, 이번엔 paper layer만 합성 |
| `ios/PillPouch/Features/Showcase/PouchShowcaseView.swift` | 데모 화면. 240×320 frame으로 봉지 1개 노출 |

### 수정 파일

| 파일 | 변경 |
|---|---|
| `ios/PillPouch/ContentView.swift` | body → `PouchShowcaseView()` 호출 |

### 폴더 등록

PBXFileSystemSynchronizedRootGroup 자동 인식 — `Features/Pouch/`, `Features/Showcase/` 둘 다 별도 project.pbxproj 수정 없이 빌드에 포함됨. **위험 #5(인식 실패) 통과.**

## 검증

### 빌드
```
cd ios && xcodebuild -scheme PillPouch -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
** BUILD SUCCEEDED **
```

### 스크린샷

> **시뮬레이터 변경 메모**: 계획서/CLAUDE.md는 iPhone 15 Pro 명시했으나 로컬 환경에 iPhone 15 시리즈 시뮬레이터 미설치. Xcode 26.4 기본인 **iPhone 16 Pro**로 촬영. 후속 stage에서도 동일 기기 사용 예정. 필요 시 차후 작업지시자가 iPhone 15 Pro 시뮬레이터 설치 후 재촬영 가능.

| 파일 | 모드 | 비고 |
|---|---|---|
| `docs/screenshots/pouch/sealed-light.png` | Light | 베이지 배경 위 흰 봉지, 인쇄 띠/V컷 가시 |
| `docs/screenshots/pouch/sealed-dark.png` | Dark | 어두운 배경 위 회색조 봉지 |

## 시각 평가 (사진 vs. 현재 결과 비교)

### 사진 (`.context/attachments/CleanShot 2026-04-29 at 00.11.55@2x.png`) 특징
- 글라싱지 반투명 흰색
- 상단에 인쇄된 약국명/환자명 텍스트(흐릿)
- 잔주름·접힘 자국 다수
- 종이 fiber 결 visible
- 우측 가장자리 살짝 접혀 있음
- 봉지 안에 캡슐 3알이 비쳐 보임

### 현재 결과
- ✅ 인쇄 띠 — placeholder 텍스트 3줄 표시됨, opacity 0.42로 사진과 비슷한 흐림
- ✅ V컷 마커 + 좌향 화살표 우상단에 표시 (당기는 방향 안내)
- ✅ 라이트/다크 모두 본문 형태 식별 가능
- ⚠ **fiber 텍스처가 너무 미세하게 보임** — 시뮬레이터 디스플레이에서 거의 인지 불가. 라인 두께(0.4pt) + opacity(0.02~0.10)가 너무 보수적. Stage 2 진입 전 보강 권장.
- ⚠ **주름 highlight가 약함** — `wrinkleHighlight()` LinearGradient가 너무 흐림. 사진처럼 명확한 접힘 자국이 없음.
- ⚠ **heat seal 점선이 거의 안 보임** — opacity 0.18~0.22 + 0.5pt 라인이 시뮬에서 안 잡힘. 두께/대비 보강 필요.
- ⚠ **다크모드에서 흰 봉지가 너무 단단해 보임** — 종이 opacity 0.78 + 어두운 배경 합성에서 반투명 효과가 사라짐. 다크모드 별도 색조 또는 opacity 조정 필요할 수 있음.
- ❌ **알약 비침** — 이번 stage 범위 외 (Stage 2). 현재는 봉지 내부가 빈 회색.

## 의사결정 / 위험 진행 상황

| 위험 | 상태 |
|---|---|
| #1 fiber 텍스처 깜빡임 | 발생 X (deterministic sin/cos 기반) |
| #2 글라싱지 재현이 사진 수준 못 미침 | **부분 발현**. 위 ⚠ 4개 항목. 보강 필요 가능성. |
| #5 PBX 인식 실패 | 통과 |

## 다음 (Stage 2 들어가기 전)

Stage 1 결과물에 대해 작업지시자 시각 검토 후 두 갈래:

### 옵션 A: 그대로 Stage 2 진입
"이 정도면 Sealed 베이스로 충분하다" — 알약/모션/찢기를 얹은 후 전체적으로 다시 시각 polish.

### 옵션 B: Stage 1.5 보강 사이클 추가
fiber 텍스처 강화 + 주름 명확화 + heat seal 가시성 + 다크모드 색조 별도 조정 → 새 스크린샷 → 재승인. 추가 단계가 별도 보고서/승인을 늘림.

### 옵션 C: 핀포인트 보강만 즉시 반영
`PouchPaperLayer` 의 opacity/lineWidth 상수 몇 개만 즉시 조정 후 같은 stage 1 보고서로 보강 스크린샷 추가. 가장 가벼움.

**추천**: 옵션 C — fiber line opacity를 0.05→0.12, heat seal opacity 0.22→0.40, wrinkle gradient 강화. 코드 변경 작음, stage 분할 없음. 만족 안 되면 옵션 B로.

## 커밋 (이 보고서 + 코드 + 스크린샷 함께)

```
feat(ios): add PouchState enum
feat(ios): add PouchPaperLayer with 7-layer glassine composition
feat(ios): add PouchView shell + PouchShowcaseView entry
feat(ios): wire ContentView to Showcase
docs: add Stage 1 sealed pouch screenshots (light/dark)
docs: add Stage 1 report
```

## 승인 ⛔

작업지시자 검토 후 옵션 A/B/C 결정 + 승인 시 Stage 2 진입.

---

# 추가: Redesign 1차 (글라싱지 → 플라스틱 봉지 + 슬롯 도장)

## 트리거

작업지시자 1차 시각 검토 — 실제 약봉지 사진 추가 첨부 후 다음 진단:
1. 글라싱지 paper 스타일이 아닌 **플라스틱 약국 봉지** (열압착 plastic)이 정답
2. 우상단 V컷 + 화살표 마커가 어색 → 실제는 **옆구리 V노치** (찢기 시작점)
3. 시간대 표시 추가 — 원형 도장 스타일 (아이콘 + 한글 텍스트, baked-in PNG)

옵션 A/B/C 중 **C(같은 stage 내 핀포인트 redesign)** 선택. Stage 분리 없이 처리.

## 작업 내역

### 자산 (사용자 제공 + 처리)

| 자산 | 원본 | 처리 (white→transparent) | 최종 위치 |
|---|---|---|---|
| 아침 도장 (한글) | `image-v4.png` | `magick -fuzz 8% -transparent white` | `Assets.xcassets/SlotStamps/SlotMorning.imageset/slot_morning.png` |
| 점심 도장 (한글) | `image-v8.png` | 동일 | `SlotLunch.imageset/slot_lunch.png` |
| 저녁 도장 (한글) | `image-v10.png` | 동일 | `SlotEvening.imageset/slot_evening.png` |
| 영문 변형 (보관) | `image-v5/v9/v11.png` | `.context/attachments/`에 transparent 보관 | 미사용 (B3 결정: 한글 고정) |

각 imageset Contents.json: `template-rendering-intent: template` 설정 → SwiftUI에서 `.foregroundStyle(slotColor)` 동적 적용.

### 결정 박제

| 결정 | 값 | 이유 |
|---|---|---|
| A. 색 처리 방식 | **A2: Template + 슬롯 색조** | 베이지 단색 자산 1세트로 morning/lunch/evening 색 자동 분기. 봉지 위에서 색 신호 강함 |
| B. 한글/영문 분기 | **B3: 한글 고정** | 영문 자산 보관, 추후 i18n 시 사용. 현재 한국 사용자 대상 |

### 신규 / 수정 파일

| 파일 | 변경 |
|---|---|
| `Features/Pouch/SlotStamp.swift` | 신규 — Image template + 슬롯 색조/회전/opacity |
| `Features/Pouch/PouchPaperLayer.swift` | 전면 redesign — 플라스틱 본체 + plastic sheen + 굵은 serrated heat-seal (top 14pt + bottom 12pt) + 옆 V노치 + 헤더(SlotStamp + 약국 정보 + monospace 용법 라인 + dotted divider) |
| `Features/Pouch/PouchView.swift` | `slot: TimeSlot` props 추가 → `PouchPaperLayer(slot:)` 전달 |
| `Features/Showcase/PouchShowcaseView.swift` | 슬롯 토글 Picker 추가 (아침/점심/저녁) |
| `Assets.xcassets/SlotStamps/` | 신규 — 3개 imageset + namespace Contents.json |

기존 `fiberTexture()`, `tearMarker()` (모서리 V컷+화살표) 완전 제거.

### 색 스펙 (Light / Dark 모드별)

| 요소 | Light | Dark |
|---|---|---|
| Pouch fill | `#FCFAF5 ×0.92` | `#D8D2C8 ×0.18` |
| Heat-seal fill | `#D9D1BF ×0.55` | `#4A453E ×0.55` |
| Heat-seal serration edge | `#B8AE99 ×0.65` | `#5C5650 ×0.65` |
| 옆 V노치 line | `#5C5650 ×0.30, 0.7pt` | `#D8D2C8 ×0.30, 0.7pt` |
| 헤더 약국명 | `PPColor.textPrimary ×0.55` | 동일 (다크 텍스트 자동) |
| 헤더 환자/용법 | `PPColor.textSecondary ×0.55` | 동일 |
| 헤더 구분선 | `textSecondary ×0.30, 0.5pt` | 동일 |
| Slot stamp morning/lunch | slot color × 0.78 | 동일 |
| Slot stamp evening | slot color × **0.72** | 동일 (퍼플 따뜻한 배경에서 살짝 누름) |

## 검증

### 빌드
```
xcodebuild -scheme PillPouch -sdk iphonesimulator build
** BUILD SUCCEEDED **
```

### 스크린샷 (6장, iPhone 16 Pro)

| 파일 | 슬롯 | 모드 |
|---|---|---|
| `sealed-morning-light.png` | 아침 (골드) | Light |
| `sealed-morning-dark.png` | 아침 (골드) | Dark |
| `sealed-lunch-light.png` | 점심 (테라코타) | Light |
| `sealed-lunch-dark.png` | 점심 (테라코타) | Dark |
| `sealed-evening-light.png` | 저녁 (퍼플) | Light |
| `sealed-evening-dark.png` | 저녁 (퍼플) | Dark |

기존 `sealed-light.png` / `sealed-dark.png` → `sealed-v1-{light,dark}.png` 로 rename(legacy 보존).

### 시각 평가 (사진 vs. 현재 결과)

| 항목 | 1차 (글라싱지) | 2차 (플라스틱 + 도장) | 평가 |
|---|---|---|---|
| 봉지 재질 | 페이퍼 종이 | **플라스틱 + 따뜻한 sheen** | ✅ 사진과 일치 |
| 상하단 가장자리 | 가는 dashed | **굵은 serrated 띠** (zigzag pinking-shears) | ✅ 사진과 일치 |
| 찢기 시작점 | 우상단 V컷 + 화살표 | **옆구리 V노치 좌/우** | ✅ 사진과 일치 |
| 헤더 위치 | 본체 안 상단 | **상단 열압착 띠 아래** (별도 영역) | ✅ 정합 |
| 시간대 표시 | 없음 | **원형 슬롯 도장 (아이콘 + 한글 + 슬롯 색조)** | ✅ 추가 |
| 용법 라인 typography | 일반 | **monospace** (처방전 인쇄 느낌) | ✅ 디테일 살림 |
| 라이트 가독성 | 충분 | **충분, 도장이 색 신호로 즉각 인지** | ✅ |
| 다크 반투명 효과 | 흰 봉지가 단단함 | **반투명 overlay (0.18) — 어두운 배경 비침** | ✅ 자연스러움 |
| 도장 회전 | — | morning -3° / lunch +1.5° / evening -1.5° 손도장 느낌 | ✅ |

남은 미세 issue:
- 상단 heat-seal serration이 하단 대비 약간 흐림 (offset 계산 미세 조정 가능, 후속 polish)
- 헤더 정보 텍스트 — placeholder copy ("PillPouch 약국", "환자: 사용자")는 mock. 실 데이터 연결은 별도 task.

## 결론

Stage 1 redesign으로 사진 수준 재현 + 슬롯 시간대 표시 동시 달성. **Stage 2 (알약 시각 + 정적 배치) 진입 준비 완료.**

## 추가 커밋

```
feat(ios): redesign pouch as plastic with serrated heat-seal and side notches
feat(ios): add SlotStamp asset set (morning/lunch/evening) with template rendering
feat(ios): wire slot color and rotation into pouch header
docs: add 6 redesign screenshots (3 slots × 2 modes)
docs: rename legacy v1 screenshots to sealed-v1-{light,dark}.png
docs: append redesign 1차 section to Stage 1 report
```

## 승인 ⛔ (재)

작업지시자 검토 후 Stage 2 진입.

---

# 추가: Redesign 2차 (옆 V노치 → 중간 perforation)

## 트리거

작업지시자 1차 redesign 검토 결과:
1. 옆구리 V노치(`> <`)가 "꺽쇠/화살표"로 읽힘 — 의도(찢기 시작점) 전달 실패
2. 헤더 정보와 알약 사이 dotted divider가 단순 정보 구분으로 낭비
3. **제안**: middle divider를 진짜 perforation으로 강화 → swipe gesture target으로 활용 → 가설 B 강화

## ADR-0009 신규 작성

`docs/adr/0009-tear-gesture-middle-perforation.md` — 찢기 인터랙션 위치를 봉지 상단(top edge)에서 중간 perforation 라인으로 이동.

핵심:
- 시각/인터랙션/알약 흐름이 한 라인에 정렬 → 학습 비용 최소화
- perforation = 좌/우 반원 노치 + 점선 (즉각 "여기 뜯음" 인지)
- 알약은 perforation 아래에 위치 → 찢기 시 자연 낙하 (Stage 5에서 구현)
- 옆 V노치 시각 혼란 자연 해결

브리프 §핵심 인터랙션 명세 갱신 (v0.5 변경 로그) — drag → swipe, top → middle perforation.

## 코드 변경

### 신규
- `NotchedPouchShape: Shape` — 봉지 outline 에서 좌/우 perforation 반원을 빼는 단일 source. fill/mask/stroke 모두에 사용. `Path.subtracting()` 활용.
- `perforationDashLine()` — 좌측 노치 안쪽 끝 ~ 우측 노치 안쪽 끝까지 horizontal dash `[3, 3]`.
- `perforationY(width:height:)` — top heat-seal + 헤더 영역 직후 위치 계산.

### 삭제
- `sideTearNotches()` 함수 + `notchPath()` helper — 옆구리 V노치 stroke 그리기
- `notchColor` 속성, `notchWidth/notchHeight/notchYOffset` Const
- `headerArea()` 의 dotted divider overlay (perforation으로 대체)

### 수정
- `body` — `GeometryReader` 로 감싸서 `NotchedPouchShape` 인스턴스 1개 만들고 fill (본체) + mask (decorations) 양쪽에 재사용
- `pouchBody()` 함수 제거 — `NotchedPouchShape.fill().shadow()` 로 인라인
- 모든 decoration layer (sheen/heatSeal/header) `.mask(shape)` — 노치 영역 자동 비움

## 시각 사양 (확정)

| 항목 | 값 |
|---|---|
| 노치 모양 | 반원 ⌒ (Circle subtract) |
| 노치 반지름 | 4pt → diameter 8pt (봉지 너비 240pt 대비 ~3.3%) |
| 노치 위치 | 좌/우 가장자리, perforation y 라인 |
| Perforation y | top heat-seal(14) + headerCenterOffset(38) + headerDividerOffset(36) = 88pt from top |
| 점선 dash | `[3, 3]` |
| 점선 lineWidth | 0.7pt |
| 점선 color | `PPColor.textSecondary opacity 0.40` |
| 점선 inset | 노치 반지름 + PPSpacing.xs (8pt) |

## 검증

빌드: `** BUILD SUCCEEDED **` 통과.

스크린샷 6장 (3 slots × 2 modes) 갱신:
- `sealed-morning-{light,dark}.png`
- `sealed-lunch-{light,dark}.png`
- `sealed-evening-{light,dark}.png`

이전 redesign 1차 스크린샷은 같은 파일명에 덮어써짐. 1차 시각이 필요하면 git history에서 확인.

### 시각 평가 (1차 vs 2차)

| 항목 | 1차 (옆 V노치) | 2차 (중간 perforation) | 평가 |
|---|---|---|---|
| 옆구리 `> <` 의문 | 시각 혼란 | **제거됨** | ✅ |
| 찢기 시작점 시그널 | 약함 (그려진 stroke) | **강함 (봉지 형태 자체 깎임)** | ✅ |
| 헤더 ↔ 알약 구분 | 단순 dotted line | **기능적 perforation 라인** | ✅ |
| 가설 B 강화 | 보통 | **강화 — swipe target 자명** | ✅ |
| 시각/인터랙션/알약 정렬 | 미흡 | **한 라인에 정렬** | ✅ |
| Stage 4/5 구현 용이 | 보통 | **직선 swipe + 자연 낙하** | ✅ |

## 추가 커밋

```
docs(adr): add ADR-0009 tear gesture middle perforation
docs: update brief.md tear interaction spec (top → middle perforation)
feat(ios): replace side V-notches with middle perforation (notched shape + dotted line)
docs: update redesign 2차 screenshots (3 slots × 2 modes)
docs: append redesign 2차 section to Stage 1 report
```

## 승인 ⛔ (3차)

작업지시자 검토 후 **Stage 2 (알약 시각 + 정적 배치)** 진입.
