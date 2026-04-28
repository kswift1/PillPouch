# task_W2_17_impl.md — 카테고리 16종 시드 자산 + JSON 동봉 구현계획서

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#17](https://github.com/kswift1/PillPouch/issues/17) |
| 마일스톤 | W2 |
| 크기 | M (시장조사 후 12 → 16종 확장) |
| 영역 | area:design + area:ios |
| 타입 | type:feat |
| 브랜치 | `local/task17` |
| 의존 (느슨) | [#15](https://github.com/kswift1/PillPouch/issues/15) merged (ADR-0007), [#16](https://github.com/kswift1/PillPouch/issues/16) merged (`CategoryMirror` @Model) |
| 예상 시간 | Claude 인프라/문서 ~2시간 + 작업지시자 GPT Image 2 11장 생성 ~3시간 |

## 목표

ADR-0007 결정에 따라 영양제 카테고리 시드 자산 + JSON을 앱 번들에 동봉. **본 task 진행 중 한국 시장 조사로 12종 → 17종 확장 검토 → 작업지시자 결정으로 redGinseng(홍삼) 제거 → 16종 최종** — 간 건강 밀크씨슬·관절 5060 핵심 글루코사민·항산화 CoQ10·단독 마그네슘 추가.

## 비목표

- ❌ 서버 endpoint (#18)
- ❌ Mirror 동기화 (#19)
- ❌ 시드 JSON → `CategoryMirror` import 코드 (#19)
- ❌ Supplement 모델 변경 (#16, 머지 완료)
- ❌ 검색 UI (#19)
- ❌ V1.1 후순위 카테고리: biotin, BCAA, 단백질, 후코이단, 녹용 등

## 시장조사 핵심 (2026-04-28, 운동 시간 동안 조사)

- **매출 상위 3대 카테고리**: 프로바이오틱스, 비타민/미네랄, 오메가3 ([HealthU 2026](https://healthu.kr/health-functional-food-market-size-trend-2026/), [오픈서베이](https://blog.opensurvey.co.kr/trendreport/health-supplement-2026/))
- **구매율 상위 성분**: 프로바이오틱스(25.2%) > 비타민C(23.7%) > 복합비타민(23.2%) > 홍삼(21.4%)
- **시니어 핵심**: 글루코사민·콘드로이친·MSM (5060 재구매율 1위 카테고리), 루테인(눈)
- **간 건강**: 밀크씨슬 (실리마린 130mg/일 권장)
- **항산화/에너지**: CoQ10 (지용성)
- **한국 특화**: 홍삼이 단일 카테고리로 시장 30% 점유 (정관장 70% 단일 브랜드 점유) — 본 카탈로그에서는 작업지시자 결정으로 제외 (V1.1 검토)
- **마그네슘 단독 vs 칼슘마그네슘 합제**: 시장에 둘 다 흔함. 사용자 인지는 단독 마그네슘이 더 직관적 → calciumMagnesium 분리 결정
- **정제 색 컨벤션**: 흰색이 80%, 색 자체는 큰 의미 없음 (식약처) — 색은 시각 변별용으로 자유롭게 사용 가능

V1.1 후순위 (시장조사 후 제외):
- biotin: vitaminD/multivitamin과 색 충돌 + 모발 건강은 collagen으로 어느 정도 커버
- BCAA/단백질: 분말 형태가 다수 → 정제/캡슐 픽토그램과 안 맞음. V1.1 헬스 카테고리 별도
- 후코이단/녹용: 시장 점유 낮음
- **redGinseng (홍삼)**: 작업지시자 2026-04-28 결정으로 본 카탈로그 범위 밖 — V1.1 검토

## 16종 카테고리 (V1.0 시드)

| # | key | 한글 | 형태 | 색 hex | 식별 핵심 |
|---|---|---|---|---|---|
| 1 | `omega3` | 오메가-3 | oval softgel (글로시 translucent) | #E5B570 골든 앰버 | 글로시 + 따뜻한 amber |
| 2 | `vitaminC` | 비타민 C | oblong tablet (matte) | #E5C547 옅은 노랑 | 가운데 세로 score line |
| 3 | `vitaminD` | 비타민 D | 작은 round disc (matte) | #D6B547 머스타드 노랑 | 작은 사이즈 + 매끈 |
| 4 | `vitaminB` | 비타민 B | oblong tablet (matte) | #C5705A 따뜻한 핑크 레드 | 가운데 세로 score line |
| 5 | `multivitamin` | 종합 비타민 | 큰 oval tablet (matte) | #C9A878 tan | 표면 점박이 5~8개 |
| 6 | `calcium` | 칼슘 | 큰 두툼 oval (matte chalky) | #E5DCCC 화이트 크림 | 가장 큰 + 두툼 + 매끈 |
| 7 | `magnesium` | 마그네슘 | round disc (matte) | #A8AABE 쿨 슬레이트 | 차가운 회청색 |
| 8 | `probiotics` | 유산균 | 작은 캡슐 (matte 단색) | #E5B0B5 파스텔 핑크 | 캡슐 형태 (반원 양끝) |
| 9 | `iron` | 철분 | round disc (matte) | #5E4E45 다크 그레이-갈색 | 매우 어두운 단색 |
| 10 | `zinc` | 아연 | round disc (matte) | #B8A595 따뜻한 taupe | 라이트 그레이-베이지 |
| 11 | `lutein` | 루테인 | oval softgel (semi-gloss) | #C9B068 골든 머스타드 | softgel + 약간 글로시 |
| 12 | `collagen` | 콜라겐 | oval softgel (semi-gloss/translucent) | #E5C8B0 핑크 베이지 | softgel + 핑크 톤 |
| 13 | `milkThistle` | 밀크씨슬 | 캡슐 (matte) | #7A6E3A 올리브 황녹 | 짙은 황녹 캡슐 |
| 14 | `glucosamine` | 글루코사민 | 큰 oblong tablet (matte) | #E8DCB8 라이트 베이지 노랑 | 가운데 가로 score line + 큰 사이즈 |
| 15 | `coq10` | 코엔자임 Q10 | oval softgel (글로시 translucent) | #E5704A 진한 코랄 | 글로시 + 진한 코랄 (omega3 amber와 색 변별) |
| 16 | `other` | 기타 | round disc (matte) | #D9C9A8 베이지 | v4 tablet 재활용 (시드 외 폴백) |

## 시각 변별 시스템 (재정립)

본 task 진행 중 발견된 핵심 변별 축 (이전 "전 12종 매트" 단순화에서 확장):

### 변별 축 1: 형태 (4 그룹)

- **round disc**: vitaminD(작음), magnesium, iron, zinc, other
- **oval/oblong tablet**: vitaminC, vitaminB, multivitamin(큼), calcium(큼+두툼), glucosamine(큼)
- **softgel**: omega3, lutein, collagen, coq10
- **capsule**: probiotics, milkThistle

### 변별 축 2: 재질

- **strict matte**: 모든 정제(tablet) 카테고리, 캡슐 카테고리(probiotics, milkThistle), magnesium, iron, zinc, calcium, glucosamine, multivitamin, vitaminC/B, vitaminD, other
- **semi-gloss**: lutein, collagen (살짝 반투명, 매트보다 살짝 빛 반사)
- **glossy translucent**: omega3, coq10 (어유/CoQ10 실물 정합)

### 변별 축 3: 색 (5 그룹)

- **노랑/오렌지/앰버**: omega3, vitaminC, vitaminD, lutein
- **레드/핑크/코랄**: vitaminB, probiotics, collagen, coq10
- **탠/베이지/크림**: multivitamin, calcium, glucosamine, other
- **올리브 황녹**: milkThistle (단독)
- **그레이/메탈**: magnesium, iron, zinc

### 변별 축 4: 표면 detail

- **score line 가운데 세로**: vitaminC, vitaminB
- **score line 가운데 가로**: glucosamine
- **점박이**: multivitamin
- **매끈 (no detail)**: 그 외 모두

같은 색 그룹 내에선 형태·재질·표면이 모두 변별 보강. 32pt에서 헷갈리는 페어 시뮬레이션 필요 시 색조 미세 조정 가능.

## 작업지시자 / Claude 분담

| 단계 | 담당 | 산출물 |
|---|---|---|
| 1. 시장조사 + 카테고리 16종 결정 | **Claude** | 본 계획서 §시장조사 + 16종 표 |
| 2. 인프라 rename (`capsules/` → `categories/`) | **Claude** | `scripts/imageset-categories.sh`, `scripts/category-spec.json` (16 row), `scripts/README.md` |
| 3. `other` 폴백 자산 재활용 | **Claude** | `design/categories/raw/other.png` ← `tablet.png` rename |
| 4. GPT Image 2 16종 프롬프트 정제·박제 | **Claude** | 본 계획서 §프롬프트 시리즈 17개 |
| 5. GPT Image 2로 16종 PNG 생성 (other 제외) | **작업지시자** | `design/categories/raw/{key}.png` × 16 |
| 6. `imageset-categories.sh` 일괄 실행 | **Claude** | `ios/PillPouch/Assets.xcassets/Categories/{key}.imageset/` × 17 |
| 7. `category-seed.json` 16 row 박제 | **Claude** | `ios/PillPouch/Resources/category-seed.json` |
| 8. 16종 시리즈 일관성 + 식별성 검증 | **작업지시자** | PR 본문 캡처 + 검증 코멘트 |
| 9. 빌드 검증 + 보고서 + PR ready 전환 | **Claude** | `xcodebuild build` ✅ + `docs/report/task_W2_17_report.md` |

**현재 진행 상태**: omega3·vitaminC·vitaminD·vitaminB·multivitamin·other 6종 raw PNG 도착 → 16종 중 11종 도착 대기.

## 폴더 구조

```
design/
└── categories/
    └── raw/                                        # 16종 raw PNG (커밋)
        ├── omega3.png       ✅
        ├── vitaminC.png     ✅
        ├── vitaminD.png     ✅
        ├── vitaminB.png     ✅
        ├── multivitamin.png ✅
        ├── calcium.png      ⏳ (작업지시자)
        ├── magnesium.png    ⏳
        ├── probiotics.png   ⏳
        ├── iron.png         ⏳
        ├── zinc.png         ⏳
        ├── lutein.png       ⏳
        ├── collagen.png     ⏳
        ├── milkThistle.png  ⏳
        ├── glucosamine.png  ⏳
        ├── coq10.png        ⏳
        └── other.png        ✅ (v4 재활용)

scripts/
├── imageset-categories.sh                          # 16종 인자
├── category-spec.json                              # 16 row
└── README.md

ios/PillPouch/
├── Assets.xcassets/Categories/                     # 16 imageset
└── Resources/category-seed.json                    # 16 row metadata
```

## `category-seed.json` 형식

```json
{
  "version": 1,
  "categories": [
    { "key": "omega3", "displayName": "오메가-3", "iconAssetName": "omega3", "iconRemoteURL": "...", "displayOrder": 1 },
    { "key": "vitaminC", "displayName": "비타민 C", "iconAssetName": "vitaminC", ..., "displayOrder": 2 },
    ... (16 row total),
    { "key": "other", "displayName": "기타", "iconAssetName": "other", ..., "displayOrder": 99 }
  ]
}
```

### displayOrder (시장 점유율 + 도그푸딩 빈도 기반)

1. omega3 (매출 상위 3대)
2. probiotics (구매율 1위 25.2%)
3. vitaminC (구매율 2위 23.7%)
4. multivitamin (구매율 3위 23.2%)
5. vitaminD
6. vitaminB
7. milkThistle (간 건강)
8. glucosamine (관절 5060)
9. lutein (눈)
10. collagen (뷰티)
11. magnesium
12. calcium
13. iron
14. zinc
15. coq10
16. other (99, 시드 외 폴백)

## GPT Image 2 16종 프롬프트 시리즈

### 공통 잠금 블록 (모든 프롬프트 머리에 박기)

```
Match EXACTLY the visual style, material, lighting, shading, camera angle, and shadow style of the attached reference image (a beige tablet pill, design/categories/raw/other.png). The new image must look like a sibling in the same 17-icon series — same upper-left soft lighting, same simple ellipse drop shadow directly below the subject, same gentle stylization, same composition. Camera at about 25° elevation (looking down at a slight angle), same as the reference.

DO NOT copy the COLOR or SHAPE of the reference. Copy the matte material baseline, camera angle, shadow style, and overall composition only.

Style: soft 3D rendered icon for a mobile app, gentle stylization. NOT a photograph, NOT a pharmaceutical catalog product shot. Friendly adult-vitamin tone.

Background: solid pure white (#FFFFFF), seamless, no gradient, no ground plane.

Composition: front-facing with slight elevation (camera at about 25° above the subject — IDENTICAL to the attached reference). Single centered subject. Generous padding around the subject. IDENTICAL camera angle, lighting direction, and shadow style to the attached reference.

Shadow: a single soft ellipse drop shadow directly below the subject, low opacity (~20%), no sharp edge.

Constraints: NO text, NO watermark, NO logos, NO printed marks, NO embossed letters, NO faces, NO characters, NO multiple objects, NO medical iconography (no cross, no Rx, no caduceus), NO photographic realism.

Use case: pictogram for an adult vitamin tracking app, displayed at 32–96 px. This is one of a 17-icon series — visual consistency with the attached reference is critical.

Output: square 1024×1024.
```

### 16종 Subject (other 제외, 공통 잠금 블록 뒤에 추가)

각 카테고리는 **시장 실물 기반**으로 정제. 다음은 카테고리별 프롬프트.

#### 1. omega3 (오메가-3) — 이미 도착 ✅

```
Subject: a single oval softgel capsule resembling a fish oil pill — smooth elongated egg shape (horizontal orientation, like an elongated egg or olive shape, ~1.7:1 width-to-height ratio), GLOSSY translucent gelatin-like surface (like a real fish oil softgel, slightly see-through). Solid muted golden amber color (#E5B570), warm tone evoking fish oil. One small soft white specular highlight on the upper-left of the surface (small, NOT a sharp mirror reflection — soft diffuse highlight only). The capsule has no seam, no print, no logos, just a smooth glossy oval.

Material override for this category: GLOSSY softgel — translucent gelatin appearance with one soft highlight is REQUIRED (overrides general matte rule).
```

#### 2. vitaminC (비타민 C) — 이미 도착 ✅

```
Material: STRICTLY matte, non-glossy, no specular shine, no plastic highlights, no glossy reflections, no translucent gelatin look. Surface should look soft and slightly powdery — like the reference tablet.

Subject: a single OBLONG vitamin C pill tablet — an elongated horizontal pill shape with rounded ends (capsule-like silhouette but as a solid matte tablet, NOT a softgel). Shape proportions about 1.6:1 width-to-height ratio. Solid muted soft yellow color (#E5C547), evoking a vitamin C tablet. The tablet has ONE subtle vertical score line carved across the exact middle of the front face — a thin shallow groove running top to bottom, perpendicular to the long axis. The score line is a fine line carved across one continuous pill body, NOT splitting the tablet into halves, NOT a deep cut. NO logos, NO printed text, NO embossed letters, NO speckles, NO other markings.

Constraints (extra): NO round disc, NO softgel, NO glossy, NO speckled surface.
```

#### 3. vitaminD (비타민 D) — 이미 도착 ✅

```
Material: STRICTLY matte, non-glossy, no specular shine, no plastic highlights, no glossy reflections, no translucent gelatin look.

Subject: a single SMALL round vitamin D pill tablet — flat short cylindrical disc with softly rounded edges, deliberately small (about 60-65% of the reference tablet's size). The shape is a simple round disc — NOT oval, NOT oblong, NOT a softgel capsule. Surface is completely smooth and uniform — NO score line, NO ornaments, NO sun symbols, NO embossed letters, NO printed marks, NO logos, NO etchings. Just a clean smooth muted mustard yellow disc. Solid muted warm mustard yellow color (#D6B547), evoking sunlight warmth.

Constraints (extra): NO oval, NO oblong, NO softgel, NO surface details whatsoever.
```

#### 4. vitaminB (비타민 B) — 이미 도착 ✅

```
Material: STRICTLY matte, non-glossy.

Subject: a single OBLONG vitamin B complex pill tablet — an elongated horizontal pill shape with rounded ends (capsule-like silhouette but solid matte tablet, NOT softgel). Shape proportions about 1.6:1 width-to-height ratio. Solid muted warm pink-red color (#C5705A), evoking a B-complex vitamin tablet. The tablet has ONE subtle vertical score line carved across the exact middle of the front face — same direction as vitaminC's score (perpendicular to long axis). NO logos, NO printed text, NO embossed letters, NO speckles, NO other markings.

Constraints (extra): NO round disc, NO softgel, NO glossy.
```

#### 5. multivitamin (종합 비타민) — 이미 도착 ✅

```
Material: STRICTLY matte, non-glossy.

Subject: a single LARGE OBLONG multivitamin pill tablet — an elongated horizontal pill shape with rounded ends, NOTICEABLY LARGER than the reference tablet (about 1.7:1 width-to-height, about 110% of the reference's frame width). Solid muted warm tan color (#C9A878), evoking a Centrum-style multivitamin. The tablet has a SPECKLED surface — 5 to 8 tiny dark speckles scattered randomly across the front face, suggesting multiple ingredients mixed together. Each speckle is a tiny dot (no more than 4% of the tablet's longer dimension), drawn as a faint matte dark spot (slightly darker than the base color, like #8C7048). NO score line, NO logos, NO printed text.

Constraints (extra): NO round disc, NO softgel, NO glossy, score line MUST NOT be present (speckles only).
```

#### 6. calcium (칼슘) — 신규

시장 정합: 한국 칼슘 정제는 거의 모두 큰 두툼한 oval 형태 (calcium은 흡수율 낮아 양이 많음 → 큰 알약). 색은 흰색/크림 (탄산칼슘·구연산칼슘 모두 흰색). 가장 큰 카테고리.

```
Material: STRICTLY matte, slightly chalky/powdery (more matte than other tablets — calcium minerals are inherently chalky-looking).

Subject: a single LARGE THICK OVAL calcium pill tablet — an elongated horizontal pill shape with rounded ends, NOTICEABLY THICKER (taller cross-section/depth) than other oblong tablets in the series, evoking a dense mineral pill. Shape about 1.7:1 width-to-height proportions BUT with extra vertical thickness/depth visible at the 25° elevation angle (the side profile of the tablet should be visibly chunky). The subject occupies ~65% of the frame width — DELIBERATELY THE LARGEST tablet in the series (calcium tablets are typically the biggest). Solid muted off-white cream color (#E5DCCC), like bone or chalk. Surface is smooth and uniform — NO score line, NO speckles, NO logos, NO embossed letters, NO printed text, NO surface details.

Constraints (extra): NO round disc, NO softgel, NO glossy, NO surface details. The pill must look noticeably larger AND thicker than other tablets in the series.
```

#### 7. magnesium (마그네슘) — 신규

시장 정합: 마그네슘 단독 영양제는 대체로 일반 round disc 또는 작은 oblong tablet. 산화마그네슘은 흰색이나 옅은 회색. 변별을 위해 차가운 회청색 채택 (다른 카테고리와 색 거리 ↑).

```
Material: STRICTLY matte, non-glossy.

Subject: a single round magnesium pill tablet — flat short cylindrical disc with softly rounded edges, similar size to the reference tablet. The shape is a simple round disc. Solid muted cool slate color (#A8AABE), a cool blue-grey hue evoking a mineral / metallic feel. Surface is smooth and uniform — NO score line, NO speckles, NO logos, NO surface details.

Constraints (extra): NO oval, NO oblong, NO softgel, NO glossy, NO warm tones (the color must be a cool blue-grey, NOT beige or yellow). NO surface details.
```

#### 8. probiotics (유산균) — 신규

시장 정합: 한국 유산균 영양제는 대체로 **작은 캡슐** 형태 (가루를 캡슐에 담음). 색은 흰색·옅은 핑크·연두 등 다양하지만 식별 cue로 파스텔 핑크 채택 (probiotic = 친근/뷰티 연상).

```
Material: STRICTLY matte, non-glossy. Single uniform color across the whole capsule (NOT two-tone, NOT split-color).

Subject: a single SMALL capsule resembling a probiotic supplement — a short cylindrical capsule shape with two perfectly rounded semicircular ends (the classic capsule silhouette), horizontal orientation, ~1.8:1 width-to-height ratio, but DELIBERATELY SMALLER than the reference tablet (about 80% of the reference's frame width). The capsule is a single solid uniform color across both halves (NO color split, NO two-tone). Solid muted pastel pink color (#E5B0B5), evoking a friendly probiotic supplement. Surface is smooth — NO seam line visible, NO logos, NO printed text, NO speckles.

Constraints (extra): NO round disc, NO softgel, NO oblong tablet (with sharp ends — the ends must be perfectly rounded semicircles), NO glossy, NO two-tone color, NO seam visible.
```

#### 9. iron (철분) — 신규

시장 정합: 철분 영양제는 대체로 작은 round 또는 oblong 정제. 색은 짙은 갈색·다크 그레이가 흔함 (철 산화물 색).

```
Material: STRICTLY matte, non-glossy.

Subject: a single round iron pill tablet — flat short cylindrical disc with softly rounded edges, similar size to the reference tablet. The shape is a simple round disc. Solid VERY DARK gray-brown color (#5E4E45), evoking iron oxide / heavy mineral feel. The color must be the darkest in the series — almost charcoal but with a subtle warm brown undertone. Surface is smooth and uniform — NO score line, NO logos.

Constraints (extra): NO oval, NO oblong, NO softgel, NO glossy. Color must be MUCH darker than any other category in the series.
```

#### 10. zinc (아연) — 신규

시장 정합: 아연 정제는 흰색·연한 갈색·연한 회색 다양. iron보다 옅은 톤으로 매트한 라이트 taupe 채택.

```
Material: STRICTLY matte, non-glossy.

Subject: a single round zinc pill tablet — flat short cylindrical disc with softly rounded edges, similar size to the reference tablet (or slightly smaller). The shape is a simple round disc. Solid muted warm light taupe color (#B8A595), a warm light grey-beige. Surface is smooth and uniform — NO score line, NO logos, NO surface details.

Constraints (extra): NO oval, NO oblong, NO softgel, NO glossy, NO dark colors (must be a light warm taupe, NOT dark brown like iron, NOT cool blue-grey like magnesium).
```

#### 11. lutein (루테인) — 신규 (재배치: tablet → softgel)

시장 정합: 한국 루테인 영양제는 거의 100% softgel 형태 (지용성 추출물). 색은 따뜻한 골든 머스타드 (마리골드 추출).

```
Material: SEMI-GLOSS softgel — translucent gelatin appearance allowed but LESS GLOSSY than omega3 (lutein softgels are typically more matte than fish oil). One soft diffuse highlight on the upper-left.

Subject: a single oval lutein softgel capsule — smooth elongated egg shape (horizontal orientation, ~1.7:1 width-to-height ratio), slightly translucent semi-glossy gelatin surface. Solid muted golden mustard color (#C9B068), a cooler/yellow-green tinted golden than omega3's warm amber. One small soft white highlight on the upper-left of the surface (smaller and softer than omega3's highlight). NO seam, NO print, NO logos.

Constraints (extra): NO tablet, NO round disc, NO oblong tablet (must be softgel), NO sharp specular reflection. The softgel must look slightly LESS glossy and slightly MORE matte than an omega3 fish oil softgel.
```

#### 12. collagen (콜라겐) — 신규

시장 정합: 한국 콜라겐 영양제는 분말·액상 스틱·정제·softgel 다양. 형태 cue로 softgel 채택 (액상 콜라겐 스틱은 형태가 vitaminC와 너무 다름). 색은 핑크 베이지 (콜라겐 = 피부 톤 연상).

```
Material: SEMI-GLOSS to MATTE softgel — softer/dustier surface than omega3 or coq10 (collagen capsules can be more matte). One very subtle highlight allowed.

Subject: a single oval collagen softgel capsule — smooth elongated egg shape (horizontal orientation, ~1.7:1 width-to-height ratio), slightly matte to semi-translucent surface. Solid muted soft pink-beige color (#E5C8B0), evoking a skin-tone-like beauty supplement. One small very soft highlight on the upper-left (smaller and dustier than omega3 or coq10). NO seam, NO print, NO logos.

Constraints (extra): NO tablet, NO round disc, NO sharp glossy reflections. Softgel surface should look softer and more matte than fish oil omega3.
```

#### 13. milkThistle (밀크씨슬) — 신규

시장 정합: 한국 밀크씨슬 영양제는 캡슐 형태가 다수 (가루 추출물을 캡슐에 담음). 색은 짙은 황녹/올리브 (실리마린 추출물 색).

```
Material: STRICTLY matte, non-glossy. Single uniform color across the whole capsule.

Subject: a single capsule resembling a milk thistle supplement — a short cylindrical capsule shape with two perfectly rounded semicircular ends (the classic capsule silhouette), horizontal orientation, ~1.8:1 width-to-height ratio, similar size to the reference tablet. Single solid uniform color across both halves (NO color split, NO two-tone). Solid muted dark olive-yellow-green color (#7A6E3A), a deep olive/khaki tone evoking dried herbal extract. Surface is smooth — NO seam line visible, NO logos, NO printed text.

Constraints (extra): NO round disc tablet, NO softgel (translucent gelatin), NO oblong tablet (must be capsule), NO glossy, NO two-tone color, NO seam visible. The color must be distinctly olive-green-brown — NOT pure pink (probiotics), NOT charcoal (iron).
```

#### 14. glucosamine (글루코사민) — 신규

시장 정합: 한국 글루코사민 영양제는 대체로 큰 oblong tablet (관절 영양제는 큰 알약 cliché, 콘드로이친·MSM 합제도 흔함). 색은 흰색/연한 베이지가 흔함.

```
Material: STRICTLY matte, non-glossy.

Subject: a single LARGE OBLONG glucosamine pill tablet — an elongated horizontal pill shape with rounded ends (similar size to multivitamin, NOT thicker like calcium). Shape about 1.7:1 width-to-height ratio, occupying ~60% of the frame width (slightly larger than reference). Solid muted light beige-yellow color (#E8DCB8), a soft creamy beige with a faint warm yellow tint (lighter than multivitamin's tan, evoking a joint-health supplement). The tablet has ONE subtle HORIZONTAL score line carved across the exact middle of the front face — a thin shallow groove running parallel to the long axis (NOT vertical like vitaminC/B — the long axis is horizontal, so this score line runs horizontally across the top face). NO logos, NO printed text, NO speckles.

Constraints (extra): NO round disc, NO softgel, NO glossy, NO speckles, NO vertical score (must be HORIZONTAL score along the long axis). The tablet must NOT be as thick/chunky as calcium.
```

#### 15. coq10 (코엔자임 Q10) — 신규

시장 정합: CoQ10는 지용성이라 거의 100% softgel. 색은 짙은 코랄/오렌지 레드 (CoQ10 결정 색). omega3와 변별 위해 색 톤 차이 강조 (omega3는 따뜻한 amber, coq10은 진한 코랄).

```
Material: GLOSSY translucent softgel — like omega3 but with different color. Translucent gelatin appearance with one soft highlight.

Subject: a single oval CoQ10 softgel capsule — smooth elongated egg shape (horizontal orientation, ~1.7:1 width-to-height ratio), GLOSSY translucent gelatin-like surface (similar to omega3's glossiness). Solid muted DEEP CORAL-ORANGE color (#E5704A), a warm reddish-orange distinct from omega3's golden amber (coq10 is darker, more red-tinged). One small soft white highlight on the upper-left of the surface. NO seam, NO print, NO logos.

Constraints (extra): NO tablet, NO round disc, NO matte (must be glossy translucent softgel like omega3). Color must be distinctly deep coral-red-orange — NOT golden amber (omega3 is more yellow-golden, coq10 must be more red-coral).
```

#### 16. other (기타) — v4 tablet 재활용 ✅

`design/categories/raw/other.png`에 이미 #11에서 받은 v4 매트 베이지 정제. 추가 생성 불필요.

## 위험 요소

1. **시리즈 일관성 — 16장 다양 형태/재질 사이 결속력** — 카메라 각도(25°)와 그림자 결로만 묶임. 재질이 매트/세미글로시/글로시 3 그룹으로 나뉘므로 시리즈 결속 약화 가능. **완화**: 작업지시자가 16장 그리드 캡처해 한 화면에서 점검, 어긋난 종만 재생성.
2. **milkThistle vs iron 색 충돌** — 둘 다 어두운 톤. **완화**: milkThistle은 올리브 황녹(#7A6E3A, 캡슐 형태), iron은 다크 그레이-갈색(#5E4E45, round disc) — 색조 + 형태 차이. 32pt에서 충분 변별.
3. **omega3 vs coq10 글로시 softgel 색 충돌** — 둘 다 글로시 oval softgel + 따뜻한 톤. **완화**: omega3는 골든 amber(#E5B570, 노랑끼), coq10은 진한 코랄(#E5704A, 빨강끼) — 색조 차이 명확. 식별성 검증 단계에서 헷갈리면 coq10을 더 진한 색(#D55A38)으로 조정.
4. **calcium vs glucosamine 색 충돌** — 둘 다 옅은 베이지/크림. **완화**: calcium 화이트크림(#E5DCCC), glucosamine 라이트 베이지 노랑(#E8DCB8) — 색 살짝 다름. 형태/사이즈/표면 차이로 보완 (calcium 두툼 매끈, glucosamine 일반 두께 + 가로 score).
5. **probiotics vs collagen 핑크 충돌** — 둘 다 핑크 톤. **완화**: probiotics 작은 캡슐(파스텔 핑크 #E5B0B5), collagen 일반 oval softgel(핑크 베이지 #E5C8B0) — 형태/사이즈/재질 모두 다름.
6. **multivitamin oval + 점박이가 32pt에서 점박이 안 보일 가능성** — 점박이가 1픽셀 이하로 떨어질 수 있음. **완화**: 점박이를 4-6%로 조정 (큰 점), 작업지시자가 32pt 미리 보기로 가시성 검증.
7. **16종 GPT Image 2 호출 톤 일관성** — 17번 호출 사이 카메라 각도 미세 어긋남. **완화**: 모든 프롬프트에 reference 첨부 + "IDENTICAL camera angle" 강조.
8. **Korean market의 새 카테고리 추가/축소 가능성** — 도그푸딩 후 `other` 비율이 30%+면 V1.1에 더 추가. 현재 16종은 V1.0 시드.

## 검증 (Issue #17 마감 조건)

- [ ] 17 `*.imageset/` 등록
- [ ] `category-seed.json` 16 row 박제, JSON valid
- [ ] `xcodebuild build` ✅
- [ ] 17장 raw PNG 시리즈 일관성 작업지시자 검증 통과
- [ ] 32pt 식별성 단독 검증 통과
- [ ] `docs/report/task_W2_17_report.md` 작성 + 작업지시자 승인
- [ ] PR squash merge, Issue #17 자동 close

## 가설 B 정합성

- ✅ 사용자 인지 단위(성분)에 정합한 시각 표현
- ✅ Non-goals 위반 없음
- ✅ `IntakeLog` 비가역 행동 기록 모델 변경 없음
- ✅ 한국 시장 1차 사용자가 첫 등록 시 시드 16종으로 90%+ 커버 추정 (V1.0 도그푸딩에서 검증)

## 다음 (이 task 완료 후)

- #18 (백엔드): 16 row를 SQLite `category` 시드 마이그레이션 + Fly static 17 PNG 업로드
- #19 (모바일 동기화/UI): `category-seed.json` import + 검색 UI에 16종 정렬 표시
- #14 (Today 정적 레이아웃): 봉지 띠에 16종 카테고리 이미지 일부 표시
- V1.1 후순위: biotin·BCAA·단백질·후코이단 등 카테고리 추가 검토 (도그푸딩 결과 기반)
