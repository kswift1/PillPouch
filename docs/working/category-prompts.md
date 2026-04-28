# 카테고리 17종 GPT Image 2 프롬프트 (작업지시자용)

작업지시자가 GPT Image 2(`quality="high"`, 1024×1024)에 직접 붙여 11장 생성용. 각 프롬프트는 **공통 잠금 블록 + Subject 블록**으로 구성. 첨부 이미지는 모두 `design/categories/raw/other.png` (v4 매트 베이지 정제, 시리즈 톤 앵커).

## 진행 상태

| # | key | 상태 | 비고 |
|---|---|---|---|
| 1 | omega3 | ✅ 완료 | v7 채택 (글로시 oval softgel 골든 앰버) |
| 2 | vitaminC | ✅ 완료 | v12 채택 (oblong 옅은 노랑 + 세로 score) |
| 3 | vitaminD | ✅ 완료 | v15 채택 (작은 round disc 머스타드) |
| 4 | vitaminB | ✅ 완료 | v17 채택 (oblong 핑크레드 + 세로 score) |
| 5 | multivitamin | ✅ 완료 | v20 채택 (oval tan + 점박이) |
| 6 | calcium | ⏳ 신규 | 큰 두툼 oval, 화이트 크림 |
| 7 | magnesium | ⏳ 신규 (분리) | round disc, 쿨 슬레이트 |
| 8 | probiotics | ⏳ 신규 | 작은 캡슐, 파스텔 핑크 |
| 9 | iron | ⏳ 신규 | round disc, 다크 그레이-갈색 |
| 10 | zinc | ⏳ 신규 | round disc, 라이트 taupe |
| 11 | lutein | ⏳ 신규 | oval softgel 세미글로시, 골든 머스타드 |
| 12 | collagen | ⏳ 신규 | oval softgel 세미글로시, 핑크 베이지 |
| 13 | redGinseng | ⏳ 신규 ⭐ | round disc, 짙은 마호가니 (한국 시장 30%) |
| 14 | milkThistle | ⏳ 신규 | 캡슐, 올리브 황녹 |
| 15 | glucosamine | ⏳ 신규 | 큰 oblong, 라이트 베이지 + 가로 score |
| 16 | coq10 | ⏳ 신규 | 글로시 oval softgel, 진한 코랄 |
| 17 | other | ✅ 완료 | v4 tablet 재활용 |

**남은 작업**: 11장 (calcium, magnesium, probiotics, iron, zinc, lutein, collagen, redGinseng, milkThistle, glucosamine, coq10)

## 공통 잠금 블록 (모든 프롬프트 머리에 박기)

```
Match EXACTLY the visual style, material, lighting, shading, camera angle, and shadow style of the attached reference image (a beige tablet pill). The new image must look like a sibling in the same 17-icon series — same upper-left soft lighting, same simple ellipse drop shadow directly below the subject, same gentle stylization, same composition. Camera at about 25° elevation (looking down at a slight angle), same as the reference.

DO NOT copy the COLOR or SHAPE of the reference. Copy the matte material baseline, camera angle, shadow style, and overall composition only.

Style: soft 3D rendered icon for a mobile app, gentle stylization. NOT a photograph, NOT a pharmaceutical catalog product shot. Friendly adult-vitamin tone.

Background: solid pure white (#FFFFFF), seamless, no gradient, no ground plane.

Composition: front-facing with slight elevation (camera at about 25° above the subject — IDENTICAL to the attached reference). Single centered subject. Generous padding around the subject. IDENTICAL camera angle, lighting direction, and shadow style to the attached reference.

Shadow: a single soft ellipse drop shadow directly below the subject, low opacity (~20%), no sharp edge.

Constraints: NO text, NO watermark, NO logos, NO printed marks, NO embossed letters, NO faces, NO characters, NO multiple objects, NO medical iconography (no cross, no Rx, no caduceus), NO photographic realism.

Use case: pictogram for an adult vitamin tracking app, displayed at 32–96 px. This is one of a 17-icon series — visual consistency with the attached reference is critical.

Output: square 1024×1024.
```

---

## 11장 Subject 블록

각 프롬프트는 위 공통 잠금 블록 + 아래 Subject 블록을 합쳐서 ChatGPT에 입력.

---

### #6 calcium (칼슘) — 큰 두툼 oval, 화이트 크림

**저장**: `design/categories/raw/calcium.png`

```
Material: STRICTLY matte, slightly chalky/powdery (more matte than other tablets — calcium minerals are inherently chalky-looking).

Subject: a single LARGE THICK OVAL calcium pill tablet — an elongated horizontal pill shape with rounded ends, NOTICEABLY THICKER (taller cross-section/depth) than other oblong tablets in the series, evoking a dense mineral pill. Shape about 1.7:1 width-to-height proportions BUT with extra vertical thickness/depth visible at the 25° elevation angle (the side profile of the tablet should be visibly chunky). The subject occupies ~65% of the frame width — DELIBERATELY THE LARGEST tablet in the series (calcium tablets are typically the biggest). Solid muted off-white cream color (#E5DCCC), like bone or chalk. Surface is smooth and uniform — NO score line, NO speckles, NO logos, NO embossed letters, NO printed text, NO surface details.

Constraints (extra): NO round disc, NO softgel, NO glossy, NO surface details. The pill must look noticeably larger AND thicker than other tablets in the series.
```

**평가 체크**: 가장 큼·두툼·매끈·화이트 크림 / oval

---

### #7 magnesium (마그네슘) — round disc, 쿨 슬레이트

**저장**: `design/categories/raw/magnesium.png`

```
Material: STRICTLY matte, non-glossy.

Subject: a single round magnesium pill tablet — flat short cylindrical disc with softly rounded edges, similar size to the reference tablet. The shape is a simple round disc. Solid muted cool slate color (#A8AABE), a cool blue-grey hue evoking a mineral / metallic feel. Surface is smooth and uniform — NO score line, NO speckles, NO logos, NO surface details.

Constraints (extra): NO oval, NO oblong, NO softgel, NO glossy, NO warm tones (the color must be a cool blue-grey, NOT beige or yellow). NO surface details.
```

**평가 체크**: 차가운 회청색 (zinc taupe·iron 다크그레이와 톤 분리)

---

### #8 probiotics (유산균) — 작은 캡슐, 파스텔 핑크

**저장**: `design/categories/raw/probiotics.png`

```
Material: STRICTLY matte, non-glossy. Single uniform color across the whole capsule (NOT two-tone, NOT split-color).

Subject: a single SMALL capsule resembling a probiotic supplement — a short cylindrical capsule shape with two perfectly rounded semicircular ends (the classic capsule silhouette), horizontal orientation, ~1.8:1 width-to-height ratio, but DELIBERATELY SMALLER than the reference tablet (about 80% of the reference's frame width). The capsule is a single solid uniform color across both halves (NO color split, NO two-tone). Solid muted pastel pink color (#E5B0B5), evoking a friendly probiotic supplement. Surface is smooth — NO seam line visible, NO logos, NO printed text, NO speckles.

Constraints (extra): NO round disc, NO softgel (translucent gelatin), NO oblong tablet (the ends MUST be perfectly rounded semicircles like a capsule), NO glossy, NO two-tone color, NO seam visible.
```

**평가 체크**: 캡슐 형태 (반원 끝) + 작은 사이즈 + 파스텔 핑크 단색

---

### #9 iron (철분) — round disc, 다크 그레이-갈색

**저장**: `design/categories/raw/iron.png`

```
Material: STRICTLY matte, non-glossy.

Subject: a single round iron pill tablet — flat short cylindrical disc with softly rounded edges, similar size to the reference tablet. The shape is a simple round disc. Solid VERY DARK gray-brown color (#5E4E45), evoking iron oxide / heavy mineral feel. The color must be the darkest in the series — almost charcoal but with a subtle warm brown undertone. Surface is smooth and uniform — NO score line, NO logos.

Constraints (extra): NO oval, NO oblong, NO softgel, NO glossy. Color must be MUCH darker than any other category in the series.
```

**평가 체크**: 시리즈 중 가장 어두운 색 (redGinseng 마호가니와도 명확히 다름)

---

### #10 zinc (아연) — round disc, 라이트 taupe

**저장**: `design/categories/raw/zinc.png`

```
Material: STRICTLY matte, non-glossy.

Subject: a single round zinc pill tablet — flat short cylindrical disc with softly rounded edges, similar size to the reference tablet (or slightly smaller). The shape is a simple round disc. Solid muted warm light taupe color (#B8A595), a warm light grey-beige. Surface is smooth and uniform — NO score line, NO logos, NO surface details.

Constraints (extra): NO oval, NO oblong, NO softgel, NO glossy, NO dark colors (must be a light warm taupe, NOT dark brown like iron, NOT cool blue-grey like magnesium).
```

**평가 체크**: 따뜻한 라이트 taupe (iron 다크그레이·magnesium 쿨슬레이트와 톤 분리)

---

### #11 lutein (루테인) — oval softgel 세미글로시, 골든 머스타드

**저장**: `design/categories/raw/lutein.png`

```
Material: SEMI-GLOSS softgel — translucent gelatin appearance allowed but LESS GLOSSY than omega3 (lutein softgels are typically more matte than fish oil). One soft diffuse highlight on the upper-left.

Subject: a single oval lutein softgel capsule — smooth elongated egg shape (horizontal orientation, ~1.7:1 width-to-height ratio), slightly translucent semi-glossy gelatin surface. Solid muted golden mustard color (#C9B068), a cooler/yellow-green tinted golden than omega3's warm amber. One small soft white highlight on the upper-left of the surface (smaller and softer than omega3's highlight). NO seam, NO print, NO logos.

Constraints (extra): NO tablet, NO round disc, NO oblong tablet (must be softgel), NO sharp specular reflection. The softgel must look slightly LESS glossy and slightly MORE matte than an omega3 fish oil softgel.
```

**평가 체크**: omega3보다 살짝 매트 / 골든 머스타드 (omega3 amber보다 cool, 노랑-녹 끼)

---

### #12 collagen (콜라겐) — oval softgel 세미글로시, 핑크 베이지

**저장**: `design/categories/raw/collagen.png`

```
Material: SEMI-GLOSS to MATTE softgel — softer/dustier surface than omega3 or coq10 (collagen capsules can be more matte). One very subtle highlight allowed.

Subject: a single oval collagen softgel capsule — smooth elongated egg shape (horizontal orientation, ~1.7:1 width-to-height ratio), slightly matte to semi-translucent surface. Solid muted soft pink-beige color (#E5C8B0), evoking a skin-tone-like beauty supplement. One small very soft highlight on the upper-left (smaller and dustier than omega3 or coq10). NO seam, NO print, NO logos.

Constraints (extra): NO tablet, NO round disc, NO sharp glossy reflections. Softgel surface should look softer and more matte than fish oil omega3.
```

**평가 체크**: 핑크 베이지 톤 (probiotics 파스텔 핑크와 톤 분리: collagen은 베이지에 가까움) / softgel 형태

---

### #13 redGinseng (홍삼) — round disc, 짙은 마호가니 ⭐ (시장 30%)

**저장**: `design/categories/raw/redGinseng.png`

```
Material: STRICTLY matte, slightly woody/earthy texture (subtle, not exaggerated).

Subject: a single round red ginseng concentrated pill tablet — flat short cylindrical disc with softly rounded edges, similar size to the reference tablet. The shape is a simple round disc. Solid VERY DEEP MAHOGANY/REDDISH-BROWN color (#7A3E2A), evoking concentrated red ginseng extract — distinctly Korean, warm yet deep. Surface is smooth and uniform with NO score line, NO logos, NO printed text. The color tone should evoke the dark red-brown of Korean red ginseng concentrate (홍삼정).

Constraints (extra): NO oval, NO oblong, NO softgel, NO glossy. Color must be a distinctively deep mahogany-reddish-brown — NOT olive (milkThistle), NOT charcoal (iron), NOT golden (multivitamin).
```

**평가 체크**: 짙은 적갈색 (홍삼 농축액 색감) / iron 차가운 다크그레이와 명확히 다른 따뜻한 적갈색

---

### #14 milkThistle (밀크씨슬) — 캡슐, 올리브 황녹

**저장**: `design/categories/raw/milkThistle.png`

```
Material: STRICTLY matte, non-glossy. Single uniform color across the whole capsule.

Subject: a single capsule resembling a milk thistle supplement — a short cylindrical capsule shape with two perfectly rounded semicircular ends (the classic capsule silhouette), horizontal orientation, ~1.8:1 width-to-height ratio, similar size to the reference tablet. Single solid uniform color across both halves (NO color split, NO two-tone). Solid muted dark olive-yellow-green color (#7A6E3A), a deep olive/khaki tone evoking dried herbal extract. Surface is smooth — NO seam line visible, NO logos, NO printed text.

Constraints (extra): NO round disc tablet, NO softgel (translucent gelatin), NO oblong tablet (must be capsule), NO glossy, NO two-tone color, NO seam visible. The color must be distinctly olive-green-brown — NOT pure brown (redGinseng), NOT pure pink (probiotics).
```

**평가 체크**: 캡슐 형태 + 올리브 황녹 (redGinseng 적갈색과 명확히 다른 녹 끼)

---

### #15 glucosamine (글루코사민) — 큰 oblong, 라이트 베이지 노랑 + 가로 score

**저장**: `design/categories/raw/glucosamine.png`

```
Material: STRICTLY matte, non-glossy.

Subject: a single LARGE OBLONG glucosamine pill tablet — an elongated horizontal pill shape with rounded ends (similar size to multivitamin, NOT thicker like calcium). Shape about 1.7:1 width-to-height ratio, occupying ~60% of the frame width (slightly larger than reference). Solid muted light beige-yellow color (#E8DCB8), a soft creamy beige with a faint warm yellow tint (lighter than multivitamin's tan, evoking a joint-health supplement). The tablet has ONE subtle HORIZONTAL score line carved across the exact middle of the front face — a thin shallow groove running parallel to the long axis (NOT vertical like vitaminC/B — the long axis is horizontal, so this score line runs horizontally across the top face). NO logos, NO printed text, NO speckles.

Constraints (extra): NO round disc, NO softgel, NO glossy, NO speckles, NO vertical score (must be HORIZONTAL score along the long axis). The tablet must NOT be as thick/chunky as calcium.
```

**평가 체크**: 큰 oblong + 가로 score (vitaminC/B 세로 score와 변별) / 라이트 베이지 (multivitamin tan보다 옅음)

---

### #16 coq10 (코엔자임 Q10) — 글로시 oval softgel, 진한 코랄

**저장**: `design/categories/raw/coq10.png`

```
Material: GLOSSY translucent softgel — like omega3 but with different color. Translucent gelatin appearance with one soft highlight.

Subject: a single oval CoQ10 softgel capsule — smooth elongated egg shape (horizontal orientation, ~1.7:1 width-to-height ratio), GLOSSY translucent gelatin-like surface (similar to omega3's glossiness). Solid muted DEEP CORAL-ORANGE color (#E5704A), a warm reddish-orange distinct from omega3's golden amber (coq10 is darker, more red-tinged). One small soft white highlight on the upper-left of the surface. NO seam, NO print, NO logos.

Constraints (extra): NO tablet, NO round disc, NO matte (must be glossy translucent softgel like omega3). Color must be distinctly deep coral-red-orange — NOT golden amber (omega3 is more yellow-golden, coq10 must be more red-coral).
```

**평가 체크**: 글로시 softgel (omega3와 같은 재질) + 진한 코랄 레드 (omega3 골든 amber와 톤 변별)

---

## 작업 순서 권장

시장 우선순위 + 변별 안전성 기준:

1. **redGinseng** ⭐ (시장 30%, 가장 distinctive 색)
2. **probiotics** (구매율 1위, 캡슐 형태 첫 시도)
3. **calcium** (가장 큰 사이즈, 다른 oval과 비교 baseline)
4. **glucosamine** (가로 score 첫 시도)
5. **coq10** (omega3와 변별 검증 — 색 톤 차이)
6. **lutein** (omega3와 변별 검증 — 재질 차이)
7. **collagen** (probiotics와 변별 검증 — 핑크 톤)
8. **iron** (다크 톤 baseline)
9. **milkThistle** (iron과 변별 — 갈색 vs 녹)
10. **magnesium** (그레이 톤 분리 — iron 다크와 거리)
11. **zinc** (그레이 그룹 마지막, 다른 두 그레이와 비교)

## 각 카테고리당 4~8장 권장

- 첫 1장만으로 best 판단 어려움
- 재질/색/형태 다양한 시도 비교
- best 1장 골라 raw로 저장

## 식별성 검증 (전체 17장 도착 후)

작업지시자가 17장 그리드 캡처 (예: ChatGPT에 17장 동시 업로드해 비교 또는 Finder Quick Look 그리드).

검증 항목:
- [ ] 매트/세미글로시/글로시 3 재질 그룹이 시리즈로 묶이는 톤
- [ ] 카메라 각도(25°) 17장 일관
- [ ] shadow 결 17장 일관
- [ ] 색 변별 32pt 시뮬레이션 (sips 사용 권장)
- [ ] 형태 그룹 (round disc / oval / softgel / capsule) 명확

헷갈리는 페어 발견 시 해당 1~2종만 색조 조정 후 재생성.

## 운동 후 작업지시자가 바로 할 수 있는 흐름

1. ChatGPT에 위 11개 프롬프트 차례로 (각 4~8장)
2. best 1장 골라 `design/categories/raw/{key}.png`로 저장
3. 11장 모두 도착하면 알려주기
4. Claude가 `./scripts/imageset-categories.sh` 일괄 실행 → 17 imageset 자동 생성
5. 빌드/Preview 검증 → PR ready 전환 → squash merge
