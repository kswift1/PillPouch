# task_W2_17_impl.md — 카테고리 12종 시드 자산 + JSON 동봉 구현계획서

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#17](https://github.com/kswift1/PillPouch/issues/17) |
| 마일스톤 | W2 |
| 크기 | M |
| 영역 | area:design + area:ios |
| 타입 | type:feat |
| 브랜치 | `local/task17` |
| 의존 (느슨) | [#15](https://github.com/kswift1/PillPouch/issues/15) merged (ADR-0007 — 본 task 시드 12종 key 형식 박제됨), [#16](https://github.com/kswift1/PillPouch/issues/16) — 머지 권장이지만 본 task의 자산/JSON은 Swift 모델 의존 X (mobile import는 #19 책임) |
| 예상 시간 | Claude 인프라 1~2시간 + 작업지시자 GPT Image 2 11장 생성 1~2시간 |

## 목표

[ADR-0007](../adr/0007-server-catalog-as-source-of-truth.md) 12종 카테고리(`omega3`/`vitaminC`/`vitaminD`/`vitaminB`/`multivitamin`/`calciumMagnesium`/`probiotics`/`iron`/`zinc`/`lutein`/`collagen`/`other`)의 대표 이미지 + JSON 시드를 앱 번들에 동봉.

#11에서 작성된 `scripts/imageset-capsules.sh` 변환 파이프라인을 카테고리 흐름으로 rename + 재활용. `design/capsules/raw/tablet.png`(v4 매트 베이지 톤)을 `other` 폴백으로 그대로 재활용.

## 비목표 (이번 task에서 안 하는 것)

- ❌ 서버 endpoint 구축 (별도 issue [#18](https://github.com/kswift1/PillPouch/issues/18))
- ❌ Mirror 동기화 로직 (별도 issue [#19](https://github.com/kswift1/PillPouch/issues/19))
- ❌ 시드 JSON → `CategoryMirror` import 코드 (별도 issue [#19](https://github.com/kswift1/PillPouch/issues/19) — `CategoryMirror` 의존)
- ❌ Supplement 모델 변경 (별도 issue [#16](https://github.com/kswift1/PillPouch/issues/16))
- ❌ 검색 UI (별도 issue [#19](https://github.com/kswift1/PillPouch/issues/19))
- ❌ ADR 본문 갱신 (#15에서 박제 완료)

## 변경 사항 (Claude / 작업지시자 분담)

| 단계 | 담당 | 산출물 |
|---|---|---|
| 1. 인프라 rename (`capsules/` → `categories/`) | **Claude** | `scripts/imageset-categories.sh` (구 `imageset-capsules.sh`), `scripts/category-spec.json` (12종 row, 구 `capsule-spec.json` 폐기), `scripts/README.md` 갱신, `design/categories/raw/` 신설 (구 `design/capsules/raw/` 폐기) |
| 2. `other` 폴백 자산 재활용 | **Claude** | `design/categories/raw/other.png` ← `design/capsules/raw/tablet.png` rename |
| 3. GPT Image 2 11종 프롬프트 박제 | **Claude** | 본 계획서 §프롬프트 시리즈 |
| 4. GPT Image 2로 11종 PNG 생성 | **작업지시자** | `design/categories/raw/{key}.png` × 11 |
| 5. `imageset-categories.sh` 일괄 실행 | **Claude** | `ios/PillPouch/Assets.xcassets/Categories/{key}.imageset/` × 12 |
| 6. `category-seed.json` 박제 | **Claude** | `ios/PillPouch/Resources/category-seed.json` (12 row metadata) |
| 7. 12종 그리드 Preview + 시리즈 일관성 검증 | **작업지시자** | PR 본문 캡처 + 식별성 검증 코멘트 |
| 8. 빌드 검증 + 보고서 + PR | **Claude** | `xcodebuild build` ✅ + `docs/report/task_W2_17_report.md` |

**Claude는 GPT Image 2 호출 못 함.** 4·7은 작업지시자 협조 필수.

## 인프라 rename 상세

### `scripts/imageset-categories.sh` (rename + 변경)

기존 `scripts/imageset-capsules.sh`에서:
- 기본 6종 (`tablet softgel capsule powder liquid gummy`) → 12종 (`omega3 vitaminC vitaminD vitaminB multivitamin calciumMagnesium probiotics iron zinc lutein collagen other`)
- 상수 `RAW_DIR=design/capsules/raw` → `design/categories/raw`
- 상수 `ASSET_DIR=ios/PillPouch/Assets.xcassets/Capsules` → `ios/PillPouch/Assets.xcassets/Categories`
- `SPEC=scripts/capsule-spec.json` → `scripts/category-spec.json`
- 그 외 동작 동일 (배경 제거 fuzz 5% + Lanczos resize @1x/@2x/@3x + Contents.json)

### `scripts/category-spec.json` (rename + 갱신)

```json
{
  "_comment": "ADR-0007 §데이터 모델 schema 그대로. 12종 카테고리 시드. ratio는 모두 1:1 (정사각형) — 시리즈 일관성 우선. base 128pt 통일.",
  "_base_size": 128,
  "omega3":           { "ratio": "1:1", "tone": "single" },
  "vitaminC":         { "ratio": "1:1", "tone": "single" },
  "vitaminD":         { "ratio": "1:1", "tone": "single" },
  "vitaminB":         { "ratio": "1:1", "tone": "single" },
  "multivitamin":     { "ratio": "1:1", "tone": "single" },
  "calciumMagnesium": { "ratio": "1:1", "tone": "single" },
  "probiotics":       { "ratio": "1:1", "tone": "single" },
  "iron":             { "ratio": "1:1", "tone": "single" },
  "zinc":             { "ratio": "1:1", "tone": "single" },
  "lutein":           { "ratio": "1:1", "tone": "single" },
  "collagen":         { "ratio": "1:1", "tone": "single" },
  "other":            { "ratio": "1:1", "tone": "single" }
}
```

전 12종 정사각형으로 통일 — 봉지 안 슬롯에서 시각 일관성 우선. 형태별 viewBox 분리(20:28 powder/liquid)는 카테고리 분류로 의미 사라짐. `tone: "single"`로 통일 — 2-tone capsule 분류는 아예 없음.

### `scripts/README.md` 갱신

용도가 "캡슐 형태 6종" → "영양제 카테고리 12종"으로 변경. ADR-0007 링크 추가.

## 폴더 구조 (rename 후)

```
design/
└── categories/                                     # rename: capsules → categories
    └── raw/
        ├── omega3.png       (작업지시자 제공)
        ├── vitaminC.png     (작업지시자)
        ├── vitaminD.png     (작업지시자)
        ├── vitaminB.png     (작업지시자)
        ├── multivitamin.png (작업지시자)
        ├── calciumMagnesium.png (작업지시자)
        ├── probiotics.png   (작업지시자)
        ├── iron.png         (작업지시자)
        ├── zinc.png         (작업지시자)
        ├── lutein.png       (작업지시자)
        ├── collagen.png     (작업지시자)
        └── other.png        (#11 v4 tablet 재활용)

scripts/
├── imageset-categories.sh                          # rename
├── category-spec.json                              # rename + 12 row
├── README.md                                       # 갱신
└── (capsule-spec.json, imageset-capsules.sh 폐기)

ios/PillPouch/
├── Assets.xcassets/
│   └── Categories/                                 # rename: Capsules → Categories
│       ├── Contents.json                           # group meta
│       ├── omega3.imageset/
│       │   ├── Contents.json
│       │   ├── omega3@1x.png
│       │   ├── omega3@2x.png
│       │   └── omega3@3x.png
│       └── ... × 11
└── Resources/                                      # 신설
    └── category-seed.json                          # 12 row metadata
```

## `category-seed.json` 형식

[ADR-0007](../adr/0007-server-catalog-as-source-of-truth.md) §schema와 일치. 모바일 첫 실행 시 [#19](https://github.com/kswift1/PillPouch/issues/19)에서 `CategoryMirror` import 입력.

```json
{
  "version": 1,
  "categories": [
    {
      "key": "omega3",
      "displayName": "오메가-3",
      "iconAssetName": "omega3",
      "iconRemoteURL": "https://api.pillpouch.app/assets/category-icons/omega3.png",
      "displayOrder": 1
    },
    {
      "key": "vitaminC",
      "displayName": "비타민 C",
      "iconAssetName": "vitaminC",
      "iconRemoteURL": "https://api.pillpouch.app/assets/category-icons/vitaminC.png",
      "displayOrder": 2
    },
    ...
    {
      "key": "other",
      "displayName": "기타",
      "iconAssetName": "other",
      "iconRemoteURL": "https://api.pillpouch.app/assets/category-icons/other.png",
      "displayOrder": 99
    }
  ]
}
```

`displayOrder` 정렬: 보편 영양제 우선 + `other` 마지막 (1~12 + other=99). 정확한 순서는 §displayOrder 표 참조.

`iconRemoteURL`은 V1.0 Fly static URL (ADR-0008). 본 task 시점엔 [#18](https://github.com/kswift1/PillPouch/issues/18) 백엔드 미구축이라 placeholder URL — #18에서 실제 hosting 후 본 JSON 갱신 또는 #19에서 동기화 응답으로 덮어쓰기.

### displayOrder 순서

1. `omega3` — 한국 시장 1위 도그푸딩 빈도 추정
2. `vitaminC`
3. `vitaminD`
4. `vitaminB`
5. `multivitamin`
6. `calciumMagnesium`
7. `probiotics`
8. `iron`
9. `zinc`
10. `lutein`
11. `collagen`
99. `other` (시드 외 폴백, 항상 마지막)

도그푸딩 후 사용자 등록 빈도로 V1.1에 재정렬 가능 (서버 SoT라 클라이언트 변경 0).

## GPT Image 2 12종 프롬프트 시리즈

[#11](https://github.com/kswift1/PillPouch/issues/11) v4 결의 매트 베이지 3D 톤 → 카테고리는 12색 팔레트로 다양화. 시리즈 일관성은 카메라/조명/material/shadow에서 확보.

### 공통 잠금 블록 (모든 11종 동일하게 머리에 박기, `other` 제외)

```
Style: soft 3D rendered icon for a mobile app, matte material, subtle ambient lighting from upper-left, soft simple ellipse drop shadow directly below the subject (NOT a realistic cast shadow), gentle stylization. NOT a photograph, NOT a pharmaceutical catalog product shot. Friendly adult-vitamin tone.

Background: solid pure white (#FFFFFF), seamless, no gradient, no ground plane.

Composition: front-facing with slight elevation (camera at about 15° above the subject, looking slightly down). Single centered subject occupying ~55% of the frame, generous padding. IDENTICAL camera angle, identical lighting direction, identical shadow style across this entire series of 12 supplement category icons — series consistency is critical.

Material: matte, non-glossy, no specular shine, no plastic highlights, no glossy reflections. Surface should look soft and slightly powdery.

Shadow: a single soft ellipse drop shadow directly below the subject, low opacity (~20%), no sharp edge, no realistic ground contact.

Constraints: NO text, NO watermark, NO logos, NO printed marks, NO embossed letters, NO faces, NO characters, NO multiple objects of different types, NO medical iconography (no cross, no Rx, no caduceus), NO photographic realism.

Use case: pictogram for an adult vitamin tracking app, displayed at 32–96 px. This is one of a 12-icon series — visual consistency must be maintained.

Output: square 1024×1024.
```

### 11종 Subject (위 공통 블록 뒤에 추가)

각 카테고리별 시각 단서 1종으로 단순화. 시리즈 일관성을 위해 모두 "단일 매트 3D object + soft drop shadow" 구조.

**1. omega3 (오메가-3)**
```
Subject: a single oval softgel capsule resembling a fish oil pill — smooth elongated egg shape, slightly translucent matte gelatin-like surface. Solid muted golden amber color (#E5B570), warm tone evoking fish oil, one small soft white highlight on the upper-left.
```

**2. vitaminC (비타민 C)**
```
Subject: a single round pill tablet with a slight citrus motif — flat short cylindrical disc with softly rounded edges, suggesting a vitamin C tablet. Solid muted warm orange color (#E89A6E), one small soft white highlight on the upper-left, no surface print.
```

**3. vitaminD (비타민 D)**
```
Subject: a single soft pill tablet evoking sunlight warmth — flat short cylindrical disc with softly rounded edges. Solid muted warm yellow color (#E5C76E), one small soft white highlight on the upper-left, no surface print.
```

**4. vitaminB (비타민 B)**
```
Subject: a single round pill tablet — flat short cylindrical disc with softly rounded edges. Solid muted earthy red color (#C5705A), one small soft white highlight on the upper-left, no surface print.
```

**5. multivitamin (종합 비타민)**
```
Subject: a single round pill tablet evoking a mixed multivitamin — flat short cylindrical disc with softly rounded edges. Solid muted warm tan color (#C9A878), one small soft white highlight on the upper-left, no surface print.
```

**6. calciumMagnesium (칼슘 마그네슘)**
```
Subject: a single chunky tablet evoking minerals — slightly chunkier flat short cylindrical disc with softly rounded edges. Solid muted soft white-cream color (#E5DCCC), with very subtle hint of grey, one small soft white highlight on the upper-left.
```

**7. probiotics (유산균)**
```
Subject: a single small capsule resembling a probiotic pill — short cylindrical capsule shape with rounded ends, slightly chubby. Solid muted soft pastel pink color (#E5B0B5), one small soft white highlight on the upper-left.
```

**8. iron (철분)**
```
Subject: a single round pill tablet — flat short cylindrical disc with softly rounded edges. Solid muted iron-grey color (#9A8A85), warm undertone, one small soft white highlight on the upper-left.
```

**9. zinc (아연)**
```
Subject: a single round pill tablet — flat short cylindrical disc with softly rounded edges. Solid muted warm taupe color (#B8A595), one small soft white highlight on the upper-left.
```

**10. lutein (루테인)**
```
Subject: a single soft pill tablet evoking eye health — flat short cylindrical disc with softly rounded edges. Solid muted golden mustard color (#C9B068), one small soft white highlight on the upper-left.
```

**11. collagen (콜라겐)**
```
Subject: a single small capsule evoking gelatin-like collagen — short cylindrical capsule shape with rounded ends. Solid muted soft pink-beige color (#E5C8B0), translucent matte surface, one small soft white highlight on the upper-left.
```

**12. other (기타)** — `design/categories/raw/other.png` ← `design/capsules/raw/tablet.png` 그대로 재활용 (#11 v4 결과). 별도 GPT 호출 X.

### 시각 변별 전략

12종이 32pt에서 헷갈리지 않도록 **색상 대비**가 핵심. 위 팔레트는 다음 그룹으로 의도적으로 분리:
- 오렌지/앰버 계열: omega3(앰버), vitaminC(오렌지), vitaminD(노랑), lutein(머스타드)
- 레드/핑크 계열: vitaminB(어시 레드), probiotics(파스텔 핑크), collagen(핑크 베이지)
- 뉴트럴 계열: multivitamin(탠), calciumMagnesium(크림), iron(아이언 그레이), zinc(토프), other(베이지)

같은 그룹 내에선 형태/채도로 추가 변별. PR-2(자체 식별성 검증) 단계에서 작업지시자가 32pt 그리드 보고 헷갈리는 페어 발견 시 색조 조정.

## 위험 요소

1. **12종 톤 일관성** — 11번 GPT Image 2 호출 사이 카메라 각도/조명/shadow가 미세하게 어긋날 가능성. **완화**: 공통 잠금 블록 머리에 박음 + 작업지시자가 12장을 한 화면에 띄워 일관성 검증, 어긋난 1~2장만 재생성.
2. **32pt 식별성 — 11종 + other**가 헷갈릴 가능성. **완화**: §시각 변별 전략의 색상 그룹 분리. 한 그룹 안에서 헷갈리면 색조 조정 후 재생성.
3. **`other` 톤이 다른 11종과 어긋날 가능성** — `other`는 v4 tablet 재활용이라 다른 11종과 다른 시점에 생성됨. 동일 공통 잠금 블록을 사용했으므로 톤 정합 확률 ↑. 어긋날 시 작업지시자 시각 검증 후 다른 11종에 맞춰 재생성.
4. **#16 미머지 상태에서 본 task 머지 시** — JSON/PNG/메타는 Swift 모델 의존 X (단순 Resource 파일들). 빌드 영향 0. #19에서 import 코드 작성 시 #16 + 본 task 모두 머지된 상태 가정.
5. **`@PBXFileSystemSynchronizedRootGroup`** — `ios/PillPouch/Resources/` 신규 폴더 자동 빌드 포함. pbxproj 수정 불필요.
6. **Asset Catalog group "Categories" namespace 충돌** — 자동 생성 `ImageResource.omega3` 등 11개 + `other` 12개. 다른 그룹의 같은 이름 자산이 있으면 충돌 — 현재 main에 그런 자산 없음(`Assets.xcassets/AccentColor` + `AppIcon`만). 안전.

## 구현 단계

### Step 1: 인프라 rename (Claude, 작업지시자 11장 도착 전 가능)

- `scripts/imageset-capsules.sh` → `scripts/imageset-categories.sh` (내용 갱신: 12종 + 경로 rename)
- `scripts/capsule-spec.json` → `scripts/category-spec.json` (12 row)
- `scripts/README.md` 갱신
- `design/capsules/` → `design/categories/` (`git mv`)
- `design/capsules/raw/tablet.png` → `design/categories/raw/other.png` (`git mv`)

### Step 2: `category-seed.json` 박제 (Claude)

- `ios/PillPouch/Resources/category-seed.json` 신설 (12 row, displayOrder 1~11 + other=99)
- `iconRemoteURL`은 placeholder (`https://api.pillpouch.app/assets/category-icons/{key}.png`)

### Step 3: 작업지시자 11장 PNG 생성 + 드롭

- §프롬프트 시리즈 11개 GPT Image 2 호출 (`quality="high"`, 1024×1024)
- 각 4~8장 후 1장 선택
- `design/categories/raw/{key}.png`로 저장
- 12장 일관성 검증 (작업지시자 시각)

### Step 4: 일괄 변환 (Claude)

- `./scripts/imageset-categories.sh` (인자 없으면 12종 일괄)
- 12 imageset 자동 생성

### Step 5: 빌드 + 식별성 검증 + 보고서

- `xcodebuild build` 통과
- 32pt 그리드 Preview는 [#19](https://github.com/kswift1/PillPouch/issues/19)에서 `CategoryMirror`로 동적 표시. 본 task에선 작업지시자가 12장 raw PNG를 한 화면에 띄워 식별성/일관성 검증
- `docs/report/task_W2_17_report.md` 작성 → 작업지시자 승인 ⛔

## 커밋 단위 (Conventional Commits)

```
docs: add W2-17 (#17) implementation plan
chore(infra): rename capsules → categories pipeline (scripts + design folder)
chore(assets): reuse v4 tablet as other.png fallback (ADR-0007)
chore(assets): generate 12 category imagesets from raw PNGs
feat(ios): add category-seed.json (12 row metadata for #19 import)
docs: add W2-17 final report
```

6 commit, squash 후 main에 1 commit.

## 검증 (Issue #17 마감 조건)

- [ ] 12 `*.imageset/` 등록 (`Categories/{key}.imageset/`)
- [ ] `category-seed.json` 12 row 박제, JSON valid
- [ ] `xcodebuild build` ✅
- [ ] 12장 raw PNG 시리즈 일관성 작업지시자 검증 통과
- [ ] 32pt 식별성 단독 검증 통과
- [ ] `docs/report/task_W2_17_report.md` 작성 + 작업지시자 승인
- [ ] PR squash merge, Issue #17 자동 close

## 가설 B 정합성

- ✅ 사용자 인지 단위(성분)에 정합한 시각 표현 — Pokemon Sleep 결의 친근함 강화
- ✅ Non-goals(TCA, Carousel, 단순 탭) 어느 항목도 추가하지 않음
- ✅ `IntakeLog` 비가역 행동 기록 모델 변경 없음

## 다음 (이 task 완료 후)

- [#18](https://github.com/kswift1/PillPouch/issues/18) (백엔드): 본 task `category-seed.json`과 동일 12 row를 SQLite `category` 테이블에 시드 마이그레이션. 본 task 11 PNG를 Fly static에 업로드. `iconRemoteURL` 실제 URL 확정.
- [#19](https://github.com/kswift1/PillPouch/issues/19) (모바일 동기화/UI): 본 task `category-seed.json`을 첫 실행 시 [#16](https://github.com/kswift1/PillPouch/issues/16)의 `CategoryMirror`에 import. 검색 UI 구축.
- [#14](https://github.com/kswift1/PillPouch/issues/14) (Today 정적 레이아웃): 봉지 띠 placeholder에 본 task 12종 카테고리 이미지 일부 표시 (또는 #19 머지 후).
