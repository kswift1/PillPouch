# task_W2_25_stage2.md — Stage 2 보고서: 알약 시각 + 정적 배치

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#25](https://github.com/kswift1/PillPouch/issues/25) |
| 마일스톤 | W2 |
| 크기 | L — Stage 2/5 |
| 브랜치 | `kswift1/task25-pouch-component` |
| 수행계획서 | [`task_W2_25.md`](../plans/task_W2_25.md) |
| 구현계획서 | [`task_W2_25_impl.md`](../plans/task_W2_25_impl.md) |
| Stage 1 보고서 | [`task_W2_25_stage1.md`](task_W2_25_stage1.md) |

## 산출물

### 신규 파일

| 파일 | 역할 |
|---|---|
| `ios/PillPouch/Features/Pouch/Pills/PillBody.swift` | 알약 데이터 모델 + `PillMix` enum + mock factory |
| `ios/PillPouch/Features/Pouch/Pills/PillView.swift` | 알약 1개 시각 — capsuleType 6종 분기 |

### 수정 파일

| 파일 | 변경 |
|---|---|
| `ios/PillPouch/Models/Enums.swift` | `CapsuleType` enum 추가 (tablet/softgel/capsule/powder/liquid/gummy), case별 doc-comment |
| `ios/PillPouch/Features/Pouch/PouchView.swift` | `pills: [PillBody]` props 추가. ZStack 아래에 `ForEach { PillView }` + `.blur(0.4) + .opacity(0.94)` 으로 봉지 너머 비침 시뮬. `pillBounds(in:)` static helper로 알약 배치 영역 계산 (perforation 아래 ~ 하단 heat-seal 위) |
| `ios/PillPouch/Features/Showcase/PouchShowcaseView.swift` | 알약 컨트롤 추가 — pill count Slider (0~8), mix Picker (혼합/정제/캡슐/연질/가루/젤리), Reset 버튼. `id(resetToken)` 으로 강제 재생성 |
| `ios/PillPouch/Features/Pouch/PouchPaperLayer.swift` | 라이트 모드 봉지 fill opacity `0.92 → 0.78` (알약 비침 가시성 확보) |

## 알약 시각 사양

| 타입 | 시각 구성 | 색 (warm 약품 톤) |
|---|---|---|
| `tablet` | Circle + 가장자리 0.5pt ring + 좌상단 RadialGradient highlight | warm white `#F8F2EA` 또는 베이지 `#E8DCC4` |
| `softgel` | Ellipse (2.4×1.6) + 좌상단 흰 highlight + 가장자리 ring | 코랄 `#E8997A` |
| `capsule` | 두 톤 Capsule (좌측 색 + 우측 warm white) + 양 끝 둥근 마감 + 상단 white 광택 | 빨강 `#C75D55` / 골드 `#E5B450` |
| `powder` | Canvas로 작은 원 7개 군집, 중심 spread 기반 분산 | warm grey `#C8C0B0` |
| `gummy` | RoundedRectangle (32% radius) + 반투명 fill 0.78 + 좌상단 흰 highlight | 코랄/골드/올리브 3종 round-robin |
| `liquid` | EmptyView (V1 미지원, 마커만) | — |

기본 알약 반지름 13pt. 회전: index 기반 -30° ~ +30° 범위에서 deterministic.

## 봉지 안 비침 효과

PouchView 의 ZStack 구성:
```
ZStack {
    ForEach(pills) { PillView }
        .blur(radius: 0.4)   // 종이 너머 살짝 흐려짐
        .opacity(0.94)       // 인쇄 너머 살짝 옅게
    PouchPaperLayer(slot:)   // 알약 위에 종이 합성
}
```

라이트 fill 0.78 + 알약 blur 0.4 + opacity 0.94 조합으로 실제 plastic 약봉지 너머 비침과 정합.
다크 fill 0.18 (그대로) — 어두운 배경에서 알약이 더 또렷하게 보임 (translucent 효과 유지).

## 알약 배치 알고리즘

`PillBody.mock(count:mix:bounds:)`:
- bounds는 `PouchView.pillBounds(in:)` 반환 — perforation 아래 ~ 하단 heat-seal 위 영역
- 한 줄 cell size = `radius * 2 + 2pt spacing`
- cols = `bounds.width / cellSize`
- 알약은 **하단 정렬** (yEnd = `bounds.maxY - radius`) — 중력으로 가라앉은 듯한 시각
- 좌우 가운데 정렬 (잉여 공간 양쪽 균등 분배)
- 각 알약 회전: `index * 47 % 60 - 30` deterministic 각도

Stage 3에서 이 정적 배치를 초기 상태로 사용 + 물리 엔진이 인계받음.

## Showcase 컨트롤

- **슬롯 Picker** (segmented): 아침/점심/저녁
- **알약 개수 Slider**: 0 ~ 8 (정수 step)
- **조합 Picker** (menu): 혼합 / 정제 / 캡슐 / 연질 / 가루 / 젤리
- **Reset 버튼**: `resetToken &+= 1` → ZStack `.id()` 변경 → 강제 view 재생성 (알약 random rotation 재계산 등)

## 검증

### 빌드
```
xcodebuild -scheme PillPouch -sdk iphonesimulator build
** BUILD SUCCEEDED **
```

### 스크린샷

| 파일 | 설명 |
|---|---|
| `pills-mixed.png` | 라이트 / 5개 / 혼합 — tablet+capsule+softgel+gummy+powder |
| `pills-mixed-dark.png` | 다크 / 5개 / 혼합 — 알약 또렷하게 비침 |
| `pills-allcapsule-8.png` | 라이트 / 8개 / 캡슐만 — 두 톤 캡슐 8개 봉지 바닥 정착 |

### 시각 평가

| 항목 | 결과 |
|---|---|
| 6종 시각 분기 | ✅ liquid 제외 5종 모두 표시. capsule 두 톤 마감 + 알약별 회전 자연스러움 |
| 봉지 너머 비침 | ✅ 라이트는 흐릿하게, 다크는 또렷하게 — 실제 plastic 약봉지 톤 정합 |
| 알약 배치 | ✅ 봉지 바닥에 가라앉은 듯, perforation 아래 영역에만 위치 |
| 슬롯 색조와의 조화 | ✅ warm 약품 톤이 cream 배경 + 슬롯 색조와 충돌 없음 |
| 컨트롤 인터랙션 | ✅ Slider/Picker/Reset 즉각 반영, ID 기반 재생성 안정적 |
| 알약 8개 시 봉지 공간 | ✅ 한 줄에 8개 적정 배치 (overflow 없음, 좌우 inset 안정) |

남은 미세 issue:
- 라이트에서 흰 정제(`tablet warm white`)가 봉지 색과 비슷해 거의 안 보임 — 실제 봉지에서도 흰 정제는 흐림. 의도된 트레이드오프.
- 8개 초과 시 두 줄 처리는 코드는 가능하나 UX상 V1은 ≤8 가정 (이슈 #25 비목표)

## 위험 진행 상황

| 위험 (impl §위험) | 상태 |
|---|---|
| #1 알약 색이 봉지 너머로 흐림 → 인지 어려움 | 발현. opacity/blur 조정으로 자연스러운 비침 확보. 트레이드오프 박제. |
| #2 6종 시각 일관성 부재 | 모든 타입이 미세 highlight + 가장자리 ring 패턴 공유 — 통일감 ✅ |
| #3 알약 색 saturation이 cream 배경과 충돌 | warm 약품 톤으로 의도적 조정 — 충돌 없음 ✅ |

## 의사결정 박제

| 결정 | 값 | 이유 |
|---|---|---|
| 알약 비침 구현 | `.blur(0.4) + .opacity(0.94)` (PouchView 측) + 라이트 fill `0.78` (PaperLayer 측) | 두 layer 결합으로 실제 plastic 너머 효과 정합. 단일 layer만 조정하면 부자연 |
| liquid 처리 | EmptyView | V1 봉지 시각 표현 X. 추후 약병 모델 별도 |
| 알약 회전 | index 기반 deterministic | random 시 매 redraw마다 다른 회전 → 깜빡임. 시드 고정 |
| 배치 정렬 | 봉지 하단 정렬 | 중력 정착 시각. Stage 3 물리 초기 상태로 자연스러움 |
| 알약 max | 8 | 봉지 공간/UX 한계, ≤ 8 가정 (#25 비목표) |

## 커밋

```
feat(ios): add CapsuleType enum and PillBody/PillMix model
feat(ios): add PillView with 5 capsule type shapes (tablet/softgel/capsule/powder/gummy)
feat(ios): wire pills layer into PouchView with translucent show-through effect
feat(ios): add Showcase pill count slider and mix picker
fix(ios): tune light pouch fill opacity for pill visibility through paper
docs: add Stage 2 screenshots (mixed light/dark, capsule 8)
docs: add Stage 2 report
```

## 다음

작업지시자 검토 후 **Stage 3 (중력 모션 + 물리 + Mock auto/manual)** 진입.
- `MotionEngine` (CMMotionManager wrapper) + `MotionEngineMock`
- `PillPhysicsEngine` — gravity / damping / bounds collision / pair collision
- `TimelineView(.animation)` 60Hz tick
- Showcase에 motion 모드 토글 + manual gravity 슬라이더

## 승인 ⛔
