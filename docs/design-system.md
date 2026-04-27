# design-system.md — Pill Pouch 디자인 시스템

> **Status**: V1 시각 SoT (W1-4, Issue [#9](https://github.com/kswift1/PillPouch/issues/9)).
> 모든 시각 결정의 단일 소스. 변경은 PR + 가설 B 체크 + 변경 이력 갱신.

---

## 1. 목적 & SoT 위계

이 문서는 Pill Pouch V1 시각 결정의 단일 소스다. 색·수치·5상태 변형·캡슐 가이드·금기·하지 말아야 할 결정을 박제한다.

**SoT 위계**

| 위계 | 위치 | 권위 | 변경 정책 |
|---|---|---|---|
| 1순위 (전략·가설) | [`docs/brief.md`](brief.md) §시각 언어 | 가설 B 정합성, 정체성, Non-goals | 변경 시 **ADR 필수** ([CLAUDE.md](../CLAUDE.md) 정책) |
| 2순위 (시각 수치) | 본 문서 | 색 hex·수치·5상태 변형 | PR만으로 변경 가능. 단, 가설 B 약화 또는 brief 본문 모순 시 **ADR 필수** |
| 3순위 (구현 토큰) | [`ios/PillPouch/DesignSystem/Tokens/`](../ios/PillPouch/DesignSystem/Tokens) | Swift 코드 토큰. 본 문서와 1:1 일치 | 본 문서 수정 시 동시 갱신 |

본 문서가 brief의 "시각 언어" 섹션을 풀어쓴 sub-SoT다. 모순 발견 시 brief가 우선이며 본 문서를 수정한다 (반대 X).

가설 B (기록 신뢰성) 강화 여부가 시각 결정의 평가 기준이다. "예쁜가?"가 아니라 "이 시각이 가설 B를 강화하는가?"

---

## 2. 톤 / 금기 / 지향

### 톤
- **결**: Things 3 + Streaks 교집합. 따뜻한 미니멀, 정보 밀도 낮음, 여백 많음.
- **레퍼런스**: Things 3 (체크 결), Streaks (누적 시각화), Pokemon Sleep (캡슐 친근함), Bearable (픽토그램), Apple Fitness (Live Activity).
- **결 X**: Pixar 풍 강한 캐릭터, 게임 UI, 스타트업 SaaS의 차가운 카드.

### 금기 (안 씀)
- ❌ 의료/병원 톤 — 흰 가운, 처방전, 청진기 메타포
- ❌ 형광 그린 (`#34C759` iOS 시스템 그린류) — "성공" 이지만 약 알람 톤 환기
- ❌ 형광 레드 (`#FF3B30` iOS 시스템 레드류) — "실패/경고" 톤 환기
- ❌ 처방전 폰트 (Courier·필기체)
- ❌ 알람 시계 아이콘 / 종 아이콘
- ❌ 체크 마크(✓) 아이콘 — 가설 B는 "체크"가 아니라 "찢김"

### 지향
- ✅ 자연광 톤 (오프화이트, 따뜻한 차콜)
- ✅ 식물성 그라디언트 (옐로우→코랄→인디고)
- ✅ 다이어리 정서 (종이 결, 절취선)
- ✅ 단색 픽토그램 (색은 토큰으로 동적 주입)

---

## 3. 색 토큰

### 3.1 배경 / Surface / Stroke / Text

| 토큰 | 라이트 hex | 다크 hex | 사용처 |
|---|---|---|---|
| `background` | `#FAF7F2` | `#1C1A17` | 앱 루트 배경. 순수 흰/검 X |
| `surface` | `#FFFFFF` | `#26231F` | 카드, 봉지 띠 컨테이너 |
| `stroke` | `#E8E2D8` | `#3A352F` | 카드 1pt 보더, 절취선 점선 |
| `textPrimary` | `#2C2823` | `#F2EEE6` | 본문 |
| `textSecondary` | `#7A736B` | `#9E978D` | 캡션, 부가 설명 |

### 3.2 시간대 색조

봉지 1일분 띠의 슬롯별 배경/스트로크 색조. 5상태 중 Active/Sealed 봉지의 비닐 hint 색으로 동적 주입.

| 시간대 | 토큰 | 라이트 hex | 다크 hex | 분위기 |
|---|---|---|---|---|
| 아침 | `morning` | `#F5C56B` | `#C9A157` | warm yellow, 자연광 |
| 점심 | `lunch` | `#E89A78` | `#B97155` | mid coral / 살구 |
| 저녁 | `evening` | `#7B6BA8` | `#5E5283` | cool indigo / 라벤더 |

**다크모드 정책**: 라이트 hex의 V값 약 70% (`HSB.V × 0.7`) + S값 5~10% 낮춤. 차콜 배경 위에서 봉지가 떠 보이도록 명도 낮추되 채도 유지하면 너무 튐 → S도 조절. 1차 휴리스틱 — 도그푸딩 D7 후 V1.1 조정 가능.

### 3.3 다크모드 베이스 정책

- 순수 검정 (`#000000`) **사용 X** — 차콜 (`#1C1A17`) 베이스
- "위에 띄운 봉지 비닐" 시각 위해 surface는 베이스보다 한 단계 밝음 (`#26231F`)
- OLED burn-in 우려는 V1 무시 (Live Activity는 시스템 배경 자체)

### 3.4 채도 감소 공식 (Skipped / Missed 봉지)

HSB 색공간에서 다음 공식 적용:

```
S_new = S_base × (1 − p)
V_new = V_base
```

| 상태 | p (감소 비율) | 설명 |
|---|---|---|
| Skipped | 0.40 | 봉지 봉인 + dashed stroke |
| Missed | 0.50 | 살짝 기울어짐 + 알파 0.7 |

곱셈식 명시 — 뺄셈 X (S=0.2일 때 S − 0.4가 음수 되는 케이스 방지).

---

## 4. 타이포그래피

### 4.1 기본 정책

- **폰트**: 시스템 폰트 (`design: .rounded`) — Pretendard 미사용 V1
- **Dynamic Type 지원 필수** — fixed point size 사용 X
- 결: Things 3의 둥근 결 + 한글 시스템 폰트 자연스러운 조합

### 4.2 토큰

| 토큰 | iOS Font | 사용처 |
|---|---|---|
| `titleL` | `.system(.largeTitle, design: .rounded).weight(.semibold)` | Today 헤더 날짜 |
| `titleM` | `.system(.title2, design: .rounded).weight(.semibold)` | 섹션 제목 ("쌓인 증거") |
| `body` | `.system(.body, design: .rounded)` | 본문, 영양제 이름 |
| `caption` | `.system(.caption, design: .rounded)` | 캡션, 부가 설명 |
| `mono` | `.system(.body, design: .monospaced)` | 슬롯 시각 표시 (`08:00` 등) — rounded와 결 다름 의도적 |

---

## 5. 스페이싱

### 5.1 정책

- **8pt grid** — Apple HIG 권장 + 4pt 보조
- 토큰 외 magic number 사용 금지 (예외: 봉지 비율 같은 시각 명세는 % 단위로 §6에 박제)

### 5.2 토큰

| 토큰 | pt | 용도 예시 |
|---|---|---|
| `xs` | 4 | 인라인 아이콘 ↔ 텍스트 |
| `sm` | 8 | 카드 내 세로 간격 |
| `md` | 16 | 섹션 내 일반 간격 |
| `lg` | 24 | 카드 ↔ 카드, 섹션 패딩 |
| `xl` | 32 | 섹션 ↔ 섹션 |
| `xxl` | 48 | 화면 상단 여백 |

---

## 6. 봉지 5상태 시각 명세

> **W2 (L) 가로 드래그 task의 입력값 SoT.** 본 섹션 변경 = W2 컴포넌트 재작업.

### 6.1 봉지 기본 수치

| 항목 | 값 | 메모 |
|---|---|---|
| 비율 (가로:세로) | **100 : 32** | iPhone 세로 화면에 봉지 3개 세로 스택 + 캡슐 식별 마진. W2 시뮬 후 ±2%pt 조정 가능 |
| 비닐 반투명도 (라이트) | 알파 **0.85** | 안 캡슐 약 60% 비침 |
| 비닐 반투명도 (다크) | 알파 **0.75** | 차콜 위 가독성 |
| V자 컷 위치 | 상단 좌측에서 가로 **12%** 안쪽 | |
| V자 컷 깊이 | 봉지 높이의 **22%** | 32pt 표시 시 시각 확보 (98pt × 22% ≈ 22pt) |
| 찢김 경로 | 베지어 + sine 노이즈 | amplitude **2.0pt**, period **8pt** — @2x도 보임 |
| 찢긴 윗 조각 매달림 각도 | **12°~18°** 랜덤 (seed = 봉지 ID) | 결정적 — 같은 봉지는 항상 같은 각도 |
| 100% 찢김 시 캡슐 노출 면적 | 봉지 면적의 약 **65%** | |
| 그림자 | y=2, blur=4, alpha **0.08** 고정 | 시간대 색조 X, 모드 무관 |

> **도그푸딩 게이트**: 비닐 알파(0.85/0.75)는 도그푸딩 D7 후 ±0.05 범위 조정 가능. V1.0 출시는 0.85/0.75 고정.

### 6.2 5상태 변형 표

| # | 상태 | 이름 | 시각 | 사용 시점 |
|---|---|---|---|---|
| 1 | Sealed | 봉인 | 기본 (위 6.1 수치 그대로). 비닐 안 캡슐 60% 비침. V자 컷 자국. | 미체크 + 시간 슬롯 도달 전 |
| 2 | Active | 활성 (NOW) | Sealed + 그림자 alpha **0.16** + 시간대 색조 alpha **0.12** outer ring (미세 글로우) | 현재 슬롯 시각 도달, 미체크 |
| 3 | Torn | 찢김 | 상단 path 분리 (찢긴 윗 조각, 매달림 각도 12~18°) + 하단 path (캡슐 노출 65%). 비가역적 시각 증거. | 사용자가 봉지 찢어 기록 |
| 4 | Skipped | 건너뜀 | Sealed + stroke `dashed 4-2pt` + 채도 `S × 0.6` (감소 0.40) | 사용자가 명시적으로 건너뛴 슬롯 |
| 5 | Missed | 누락 | Sealed + rotation **−3°** (정적 상태만, 드래그 중 0°) + 채도 `S × 0.5` + 알파 0.7 | 슬롯 시각 지났는데 미체크 |

### 6.3 가설 B 정합성 체크

- ✅ Torn 상태가 비가역적 시각 증거 — "찢김"이 본질이며 체크/원형/✓ 회피
- ✅ Sealed↔Torn 차이가 "있다/없다" 수준 (캡슐 노출 65%)으로 명확 — 의문 즉시 해소
- ✅ Skipped/Missed가 Sealed/Torn과 시각적으로 구분되어 "쌓인 증거"가 정확
- ❌ 회피: Sealed 위에 ✓ 표시, 색만 바뀌는 체크, 알파만 변하는 처리

### 6.4 텍스처 / 종이 결 (V1.1)

종이 결, 인쇄 도트 노이즈, 봉지 표면 그레인은 V1.0 미포함. V1.1 후순위. V1.0은 코드 그라디언트만으로 비닐 표현.

---

## 7. 캡슐 일러스트 6종

> **자산 제작은 [Issue #11](https://github.com/kswift1/PillPouch/issues/11) (W2)** 에서. 본 섹션은 명세 + 프롬프트 SoT.

### 7.1 공통 SVG 명세

- 라인 두께 **1.5pt**, 코너 라운드 **2pt**
- 모노크롬 단색 fill (캡슐만 예외 — 2-tone 허용) + 1 hint dot (흰색 광점)
- **Template Image** (`fill="currentColor"`) — `.foregroundStyle(PPColor.morning)` 동적 색 주입
- **Asset Catalog Symbol Image 등록** — `Capsules/<name>.symbolset/`
- 32pt 표시 시 6종 식별 가능 — 라벨 없이 5명 중 4명 이상 맞히면 통과

### 7.2 6종 명세 표

| 캡슐 | viewBox | 색 정책 | 식별 핵심 |
|---|---|---|---|
| `tablet` (정제) | 24×24 | 단색 | 원통 옆면, 가운데 score line |
| `softgel` (소프트젤) | 24×24 | 단색 + 흰 광점 | 길쭉 타원, 광택 |
| `capsule` (캡슐) | 24×24 | **2-tone 상하 분리** | 양쪽 반원 + 깔끔한 접합선 |
| `powder` (가루) | 20×28 | 단색 + 작은 dot pattern | 스틱팩 직사각, 톱니 상단, 안쪽 작은 점 5~8개 |
| `liquid` (액상) | 20×28 | 단색 + 작은 inner highlight | 물방울, 안쪽 살짝 fill (hollow 아님) |
| `gummy` (구미) | 24×24 | 단색 + 흰 광점 | **rounded blob 실루엣** (곰돌이/별 X — 성인 친화) |

### 7.3 GPT Image 2 프롬프트 6개

GPT Image 2 (2026-04-21 출시) — OpenAI 공식 가이드의 `Style → Subject → Details → Constraints → Use case` 라벨 구조 채택. `quality="high"` 권장.

#### 공통 라벨 블록 (각 프롬프트 머리/꼬리에 그대로 사용)

```
Style: minimalist flat pictogram, vector-like clean shapes, no gradients, no shadows, no outlines except 1.5pt stroke if needed, plain pure white background
Use case: mobile app pictogram for an adult vitamin tracking app, must read clearly at 24px
Constraints: single centered subject with generous padding (subject occupies ~60% of frame), no text, no watermark, no logos, no medical iconography (no cross, no Rx), no shadow, friendly but not childish, scalable silhouette
```

#### 개별 Subject + Details

**1. tablet (정제)**
```
Subject: a round white pill tablet viewed from the side
Details: short cylinder shape, soft rounded edges, a single horizontal score line across the middle, single fill color
```

**2. softgel (소프트젤)**
```
Subject: an oval softgel capsule, slightly glossy
Details: smooth elongated egg shape, one small white highlight dot in the upper-left, single fill color, line weight 1.5pt
```

**3. capsule (캡슐)** — *2-tone 명시, 공통 라벨의 "single fill color"는 본 항목에서 무시 명시*
```
Subject: a two-tone medication capsule, horizontal orientation
Details: pill capsule split into two equal halves by a clean vertical seam line, top half one color, bottom half a slightly darker shade, no other detail
Override: two fill colors allowed for this icon (not single color)
```

**4. powder (스틱팩 가루)**
```
Subject: a vertical powder stick pack sachet
Details: tall rectangular pouch (proportions 20:28), small zigzag serrated edge on the top, 5 to 8 tiny solid dots scattered inside the lower two-thirds suggesting powder, single fill color for the pouch outline
```

**5. liquid (액상 드롭)**
```
Subject: a single liquid droplet
Details: classic teardrop shape with rounded bottom and pointed top, a small lighter fill area inside near the upper-left as inner highlight (not hollow), single fill color outline
```

**6. gummy (구미)**
```
Subject: a soft rounded blob of gummy candy
Details: irregular but symmetric pebble shape with smooth rounded edges, one small white highlight dot near the top, single fill color, no facial features, no animal shape
```

### 7.4 정리·등록 워크플로우 (#11에서 진행)

1. 작업지시자가 GPT Image 2로 위 6개 프롬프트 실행 (`quality="high"`, 각 4~8장 후 1개 선택)
2. Figma/Illustrator import → outline 단순화 → 단색 path만 남기고 SVG export (viewBox 통일 24×24 또는 20×28, `fill="currentColor"`)
3. `ios/PillPouch/Assets.xcassets/Capsules/{tablet,softgel,capsule,powder,liquid,gummy}.symbolset/` 등록 (Symbol Image, Template Image)
4. 32pt 표시 시 6종 식별성 자체 검증 (5명 중 4명 이상) → 부족하면 프롬프트 조정 후 재생성

---

## 8. 햅틱 시퀀스

> **W2 (L) 가로 드래그 task의 입력값 SoT.** 코드 구현은 W2.

### 8.1 드래그 진행도별 햅틱 표

| 진행도 | 시각 변화 | 햅틱 generator | 강도 / 횟수 |
|---|---|---|---|
| 0% (대기) | 봉지 봉인. V자 컷 자국. | — | — |
| 0~30% | V자 컷에서 살짝 갈라지기 시작 | `UIImpactFeedbackGenerator(style: .soft)` | intensity 0.4, 진행도 5%마다 1회 (총 ~6회) |
| 30~70% | 봉지 윗부분이 따라 찢어짐. 종이 찢는 지그재그 가장자리. | `UIImpactFeedbackGenerator(style: .soft)` | intensity 0.7, 진행도 4%마다 1회 (총 ~10회) |
| 70~100% | 윗 조각이 살짝 들리거나 떨어짐. 캡슐 노출 시작. | `UIImpactFeedbackGenerator(style: .soft)` | intensity 1.0, 진행도 3%마다 1회 (총 ~10회) |
| 100% 도달 | 봉지 "찢김" 상태로 고정. 캡슐이 빠져나간 자리. | `UINotificationFeedbackGenerator().notificationOccurred(.success)` | 한 번 |

기획서 §핵심 인터랙션 명세 표를 수치 정밀화. 총 5~7회 → 측정 후 26회 (5%→4%→3% 진행 간격 단조감소). 도그푸딩에서 너무 많으면 W2에서 간격 조정.

### 8.2 50% 임계 (오탭 방지)

- **50% 미만에서 손 떼기** → `withAnimation(.spring(response: 0.4, dampingFraction: 0.6))` 스프링 백 (0%로). 햅틱 X.
- **50% 이상에서 손 떼기** → 자동으로 100%까지 진행, 햅틱 시퀀스 계속 + `.success` 발사.

### 8.3 Undo 토스트

- 100% 완료 후 5초 토스트 (`.success` 햅틱과 분리, 동시 X)
- 토스트 탭 시 햅틱 X (시각 reset만)

---

## 9. 하지 말아야 할 시각 결정

> 기획서 §하지 말아야 할 시각 결정 + 본 문서에서 추가.

- ❌ **봉지 위에 노란 동그라미 ✓ 표시 = 체크 메타포** — 가설 B 약화. "찢김"이 증거다.
- ❌ **찢긴 봉지 안 캡슐이 흐릿함** — "먹었음" 명확하지 않음. 캡슐은 명확히 노출.
- ❌ **Carousel/스와이프로 슬롯 전환** — 의문 해소가 즉시 일어나려면 모든 슬롯이 한 화면에.
- ❌ **단순 탭 체크** — 오탭 위험 + 의도성 부재. 드래그 찢기로만.
- ❌ **"드래그해서 찢어주세요" 안내 카피 메인 박기** — 온보딩 1회만.
- ❌ **"0% / 30% / 70% / 100%" 진행 시퀀스 메인 박기** — 봉지가 자체로 표현.
- ❌ **의료 톤 (흰 가운, 처방전, 청진기, 십자가, Rx 약자)** — 정체성 충돌.
- ❌ **알람 시계 / 종 아이콘** — A(보조) 강조 — B(메인) 약화.
- ❌ **형광 그린/레드** (`#34C759`, `#FF3B30` 류) — 따뜻한 결 깸.
- ❌ **순수 검정 / 순수 흰색 배경** — 차콜 / 오프화이트만.
- ❌ **Pixar 풍 강한 캐릭터, 게임 UI 글래스모피즘** — Things 3 결과 충돌.
- ❌ **봉지 5상태를 색만으로 구분** — 형태 변화(찢김·기울어짐·dashed)가 본질.
- ❌ **캡슐 6종을 색으로 구분** — 형태로 식별. 색은 시간대 슬롯 정보.
- ❌ **Dynamic Type 무시한 fixed point size** — 접근성 의무.

---

## 10. 변경 이력

### W1-4 (2026-04-28, Issue #9, PR TBD)
- 초기 작성
- 시간대 색조 (아침/점심/저녁) 라이트+다크 hex 박제
- 봉지 5상태 수치 SoT (비율 100:32, V컷 22%, sine 2.0pt, 채도 공식)
- 캡슐 6종 SVG 명세 + GPT Image 2 프롬프트 6개
- 햅틱 시퀀스 표 정밀화
- 하지 말아야 할 시각 결정 14개

---

## 11. 참고

- 상위 SoT: [`docs/brief.md`](brief.md) §시각 언어
- 구현 토큰: [`ios/PillPouch/DesignSystem/Tokens/`](../ios/PillPouch/DesignSystem/Tokens)
- ADR-0005: [`docs/adr/0005-no-tca-swiftui-native.md`](adr/0005-no-tca-swiftui-native.md) (SwiftUI 네이티브 전제)
- 캡슐 자산: [Issue #11](https://github.com/kswift1/PillPouch/issues/11) (W2)
- 봉지 컴포넌트: W2 (M) 봉지 5상태 컴포넌트 task (TBD)
- 가로 드래그: W2 (L) 가로 드래그 task (TBD)
