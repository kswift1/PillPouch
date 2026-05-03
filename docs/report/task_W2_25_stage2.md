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

---

# 추가: Redesign (카테고리 자산 사용)

## 트리거

작업지시자 지적: Stage 2 1차 구현이 직전 PR #22 (`375dcb4` — 카테고리 16종 시드 자산)를 참조하지 않음.

확인 결과 카테고리 자산이 **단순 라벨 아이콘이 아니라 실제 알약 일러스트** (omega3 = 노란 softgel, vitaminD = 노란 tablet, probiotics = 흰 capsule, vitaminB = 빨강 큰 capsule-tablet 등 16종). SwiftUI Shape으로 직접 그린 결과물보다 사실성/카테고리 시각 표현 양면에서 우월. 통째 교체.

## 변경 사항

### PillBody 모델 단순화
- `capsuleType: CapsuleType` 폐기
- `color: Color` 폐기
- 신규: `categoryKey: String` — `Supplement.categoryKey` 와 매핑되는 lowerCamel id
- radius 13 → 16 (자산 시각이 더 풍부해 표시 frame 약간 키움)

### PillView 통째 재작성
- 기존: switch capsuleType 로 6종 SwiftUI Shape 분기 + RadialGradient + Capsule + Canvas
- 신규: `Image(pill.categoryKey).resizable().scaledToFit().frame(width: radius * 2.4, height: radius * 2.4)`

코드량 ~120줄 → ~10줄. 카테고리 시드 자산이 형태/색/디테일 모두 baked-in.

### PillMix 재정의
6종 기본 + 단일 2종 = 7개 옵션:
- 혼합 (16종 round-robin)
- 비타민 (vitaminD/C/B + multivitamin)
- 오메가 (omega3 + lutein + coq10 + collagen)
- 미네랄 (calcium + magnesium + iron + zinc)
- 캡슐 (probiotics + milkThistle + glucosamine)
- 단일 오메가3
- 단일 비타민D

기존 `.allTablet/.allCapsule/.allSoftgel/.allPowder/.allGummy` 폐기 (capsuleType 기반 → 카테고리 기반 mix로 의미 단위 재구성).

### Asset Catalog 접근 경로
`Categories/` 폴더 namespace 미설정 (`provides-namespace` X). 따라서 `Image("Categories/omega3")` 가 아닌 **`Image("omega3")`** 로 직접 키 접근. 1차 시도 시 namespace 가정으로 자산 못 찾아 빈 봉지 렌더 발생 → namespace 미설정 발견 후 즉시 수정.

### 폐기된 파일/코드
- `PillView` 의 6종 SwiftUI Shape 헬퍼 (tabletView/softgelView/capsuleView/powderView/gummyView)
- `PillMix.color(for:type:)` + `tabletColors` / `capsuleColors` / `gummyColors` 색 팔레트
- `CapsuleType` enum 자체는 유지 (도메인 모델, brief.md 데이터 모델 스케치 호환)

## 검증

### 빌드
```
** BUILD SUCCEEDED **
```

### 스크린샷 (3장 갱신)

| 파일 | 상태 |
|---|---|
| `pills-mixed.png` | 라이트 / 5개 / 혼합 — 카테고리 자산 omega3+probiotics+vitaminC+multivitamin+vitaminD round-robin |
| `pills-mixed-dark.png` | 다크 / 5개 / 혼합 — 알약 또렷, 다양한 형태 식별 |
| `pills-vitamins-8.png` | 라이트 / 8개 / 비타민 — vitaminD/C/B/multivitamin 4종 round-robin × 2 |
| ~~`pills-allcapsule-8.png`~~ | 삭제 (구식 SwiftUI Shape 결과물) |

### 시각 평가 (1차 vs 2차)

| 항목 | 1차 (SwiftUI Shape) | 2차 (카테고리 자산) | 평가 |
|---|---|---|---|
| 사실성 | 평면적 / 일러스트풍 | **사실적 3D 톤** (광택, 그림자) | ✅ |
| 카테고리 시각 표현 | 색만 다름, 형태 동일 | **각 카테고리마다 고유 형태** | ✅ |
| 시각 다양성 | 형태 6종 | **16종 자산** (작은 tablet/큰 가로/capsule/softgel) | ✅ |
| Today/Live Activity 호환 | Shape 그대로 사용 가능 | **자산 그대로 사용 가능 (#11 자산 별도 task 불필요)** | ✅ |
| 알약 ↔ Supplement 연결 | capsuleType (별도 분기 필요) | **categoryKey 직접 매핑 (이미 모델에 있음)** | ✅ |
| 코드량 | ~120 LOC | **~10 LOC** | ✅ |

남은 미세 issue:
- 라이트에서 흰/베이지 알약은 봉지 색과 비슷해 흐리게 비침 — 의도된 트레이드오프 유지
- 자산 비율이 카테고리별로 달라 한 줄에 8개 배치 시 너비 편차 있음 — 자연스러운 다양성으로 작용

## 의사결정 박제

| 결정 | 값 | 이유 |
|---|---|---|
| 알약 시각 source | **카테고리 시드 자산 (PR #22)** | 단순 라벨이 아니라 실제 알약 일러스트. SwiftUI Shape보다 사실성·카테고리 표현·코드량 모두 우수 |
| categoryKey 데이터 흐름 | **`Supplement.categoryKey` 직접 매핑** | 향후 실 데이터 연결 시 변환 0. ADR-0007 정합 |
| Asset Catalog 접근 | **namespace 없이 `Image(key)` 직접** | Categories 폴더가 namespace 미설정. 호환성 위해 그대로 두되 PillView가 직접 키 접근 |
| `CapsuleType` enum | **유지** | 도메인 모델 + brief.md 데이터 모델 스케치 호환. 알약 시각 분기 책임은 categoryKey가 인계 |
| `#11 캡슐 자산` task | **이번 task에서 자연 해소** | 카테고리 시드 자산이 이미 알약 일러스트라 별도 task 불필요. #11 close 또는 scope 재정의 가능 |

## 추가 커밋

```
feat(ios): redo Stage 2 pills using category seed assets (#22)
docs: update Stage 2 screenshots with category assets
docs: append Stage 2 redesign section to report
```

## 승인 ⛔ (재)

---

# 추가: Polish (리뷰 피드백 반영)

## 트리거

Stage 3 진입 전 작업지시자 시각 검토. 결함 4 + 1 식별:
- C1: 라이트 알약 가시성 너무 약함
- C2: 알약 사이즈 너무 작음
- C3: 상단 heat seal serration 흐림
- C4: perforation 점선 옅음
- M2: 아침 도장만 사이즈가 다름

## 변경

### C1 — 라이트 알약 가시성
- 봉지 라이트 fill opacity `0.78 → 0.65`
- PillView blur `0.4 → 제거`, opacity `0.94 → 0.96`
- 결과: 라이트에서도 알약 형태/색 식별 가능 (가설 B 강화)

### C2 — 알약 사이즈
- PillBody radius `16 → 22` (default + mock factory 둘 다)
- mock spacing `2 → 3` (큰 알약끼리 약간 더 호흡)
- 결과: frame 38pt → 53pt. 봉지 너비의 14% → 20%. 8개는 두 줄로 자동 배치.

### C3 — 상단 heat seal serration
- serration stroke lineWidth `0.7 → 1.0`
- heatSealEdge opacity `0.65 → 0.85`
- 결과: 상하단 톱니 모두 또렷

### C4 — perforation 점선
- perforationColor opacity `0.40 → 0.55`
- 점선 lineWidth `0.7 → 0.9`
- 결과: "여기 절취선" 시그널 강화

### M2 — 아침 도장 사이즈 정규화 (자산 처리)
원인 진단:

| 자산 | trimmed | 캔버스 비율 |
|---|---|---|
| 아침 (원본) | 892×897 | 71% (작음) |
| 점심 (원본) | 1015×1033 | 80% |
| 저녁 (원본) | 1022×1060 | 81% |

자산 자체가 캔버스 안에서 아침만 13% 작게 그려져 있음. SwiftUI `.scaledToFit()` + 동일 frame이라 시각 사이즈 차이 발생.

수정: ImageMagick 으로 3개 자산 모두 trim → 1024×1024 resize → 1280×1280 캔버스 중앙 배치 → 모든 도장 trimmed ~1024px로 균일화.

```bash
magick "Slot{Morning,Lunch,Evening}.imageset/slot_*.png" \
  -trim +repage -resize 1024x1024 \
  -gravity center -background none -extent 1280x1280 \
  "$src"
```

결과: 3개 도장 모두 동일한 visual size로 표시. 코드 변경 0.

## 검증

### 빌드
```
** BUILD SUCCEEDED **
```

### 스크린샷 갱신 (8장)
- `sealed-{morning,lunch,evening}-{light,dark}.png` (6장) — 도장 정규화 + perforation/heat seal 강화 반영
- `pills-mixed.png` + `pills-mixed-dark.png` — 알약 사이즈/가시성 fix
- `pills-vitamins-8.png` — 큰 알약으로 두 줄 배치

### 비교 (Polish 전/후)

| 항목 | 전 | 후 |
|---|---|---|
| 라이트 알약 가시성 | "흐릿한 얼룩" | **각 형태 명확 식별** |
| 알약 차지 영역 | 봉지 너비 14% | **봉지 너비 20%** |
| 상단 heat seal | 흐릿 | **또렷한 톱니** |
| perforation 점선 | 거의 안 보임 | **명확한 dashed** |
| 아침 도장 vs 점심/저녁 | 13% 작음 | **균일** |

## 보류

| 항목 | 사유 |
|---|---|
| M1 봉지 비율 (세로형 vs 가로형) | 띠 task에서 결정 |
| M3 봉지 그림자 강화 | 작업지시자 보류 |

## 추가 커밋

```
fix(ios): boost light pouch translucency and pill size for visibility (#25 polish)
chore(assets): normalize slot stamp asset canvas sizes
docs: append polish section to Stage 2 report
```

## 승인 ⛔ (3차) — Stage 3 진입 전 최종 게이트
