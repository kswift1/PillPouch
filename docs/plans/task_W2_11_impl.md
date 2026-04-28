# task_W2_11_impl.md — 캡슐 6종 자산 (AI 생성 + Asset Catalog 등록) 구현계획서

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#11](https://github.com/kswift1/PillPouch/issues/11) |
| 마일스톤 | W2 |
| 크기 | M (PR 2개 분할) |
| 영역 | area:design + area:ios |
| 브랜치 | `local/task11` (PR-1), `local/task11-batch` (PR-2) |
| 예상 시간 | PR-1 2~3시간 (Claude) + 작업지시자 GPT 작업 별도 / PR-2 1~2시간 (Claude) + 작업지시자 5종 자산 작업 별도 |
| 의존 | [#9](https://github.com/kswift1/PillPouch/issues/9) merged (`PPColor`, `docs/design-system.md` §7), [#10](https://github.com/kswift1/PillPouch/issues/10) merged (`CapsuleType` enum 등) |

## 목표

GPT Image 2로 생성한 캡슐 픽토그램 6종을 Xcode Asset Catalog Image Set으로 등록해 SwiftUI에서 `Image(.tablet)` 형태로 사용 가능하게 한다. W2 (M) 봉지 5상태 컴포넌트와 W2 (L) 가로 드래그 task의 시각 입력값.

## 비목표 (이번 task에서 안 하는 것)

- ❌ 봉지 껍데기 SwiftUI 컴포넌트 (W2 (M) 봉지 5상태 컴포넌트 task 책임)
- ❌ 6×3시간대 색조 변형 사전 렌더 — **시간대 색조 시각 단서는 봉지/헤더에서 표현**, 캡슐 자체는 변하지 않음
- ❌ Today 화면 통합 (W1-5)
- ❌ 봉지 안 캡슐 물리 시뮬레이션 (검토 후 V1.1로 미룸 — 본 task §검토 이력 참조)
- ❌ Metal 직접 렌더링 (검토 후 V1.1로 미룸 — 본 task §검토 이력 참조)

## 톤·색조 결정 (작업지시자 2026-04-28 승인)

검토 과정에서 GPT Image 2의 stylization 한계 확인 + Metal 직접 렌더링 프로토타입 폐기 후 다음으로 확정:

- **자산 기반 6종 PNG** 채택. Metal 직접 렌더링은 V1 비목표.
- **톤**: GPT Image 2의 v4 결(매트 베이지 3D, photoreal 회피)로 6종 시리즈 일관 생성. claymorphism / chunky cell-shading은 GPT Image 2가 못 따라옴 → V1.1 polish로 미룸.
- **색 포기 — 6종 단색 1세트**: 캡슐별 고정 색(예: tablet 베이지, softgel 앰버, capsule 코랄/로즈 2-tone, powder 세이지, liquid 스카이블루, gummy 플럼). 시간대 색조 시각 단서는 **봉지 띠/헤더에서 표현**, 캡슐 자체는 변하지 않음. 18 variant 사전 렌더 안 함.
- 결과적으로 `Image(.tablet).foregroundStyle(...)` 동적 색 주입은 V1에선 의미 없음 → SVG/`currentColor` 변환 흐름 폐기, **PNG 그대로 Asset Catalog Image Set 등록**.

### Asset Catalog 형식: Symbol Image → Image Set

기존(W1-9 ADR 시점)은 SVG Symbol Image + Template Image + `currentColor` 흐름이었음. 본 결정으로 다음으로 변경:

- **Image Set (PNG @1x/@2x/@3x)** — Universal, Single Scale 아닌 멀티 스케일
- **Symbol Image 포기** — Dynamic Type 자동 스케일 손실(미미), `.foregroundStyle()` 색 주입 손실(이미 포기)
- 이점: Xcode GUI 협조 불필요(Image Set 메타 JSON은 텍스트 작성만으로 충분), v4 시각 특성(cell-shading·shadow) 100% 보존, 변환 단계 단순화

## 분할 결정 (작업지시자 2026-04-28 승인)

**B안: 2 PR로 분할**.

- **PR-1 (`local/task11`): 파이프라인 검증** — 1종(`tablet`)으로 끝-끝 흐름 dry-run. Asset Catalog Image Set 메타·`enum CapsuleAsset` API·Preview·기본 테스트 인프라까지 박제. 6종 일괄 작업 전 누락 항목 조기 검출.
- **PR-2 (`local/task11-batch`): 5종 일괄 추가** — `softgel`, `capsule`, `powder`, `liquid`, `gummy`. PR-1에서 검증된 흐름을 반복. 시리즈 일관성 자체 검증(6종 동시 표시)을 PR-2 마감 조건으로.

## 작업지시자 / Claude 분담

| 단계 | 담당 | 산출물 |
|---|---|---|
| 1. GPT Image 2 프롬프트 실행 (`quality="high"`, 1024×1024, white BG) | **작업지시자** | PNG (`design/capsules/raw/{name}.png`) |
| 2. CLI 자동 파이프라인: 배경 제거(`imagemagick`) → resize @1x/@2x/@3x → Image Set 메타 작성 | **Claude** | `ios/PillPouch/Assets.xcassets/Capsules/{name}.imageset/` + 변환 스크립트 (`scripts/imageset-capsules.sh`) |
| 3. `enum CapsuleAsset` + 사용처 노출 | **Claude** | `ios/PillPouch/DesignSystem/Capsules/CapsuleAsset.swift` |
| 4. SwiftUI Preview + 빌드 검증 + `xcodebuild test` | **Claude** | `ios/PillPouchTests/CapsuleAssetTests.swift` + Preview 캡처 요청 |
| 5. 시리즈 일관성·식별성 자체 검증 (6종 동시 그리드 캡처) | **작업지시자** (PR-2 리뷰 단계) | PR 본문 코멘트 + `docs/screenshots/capsules/grid-6@32pt.png` |

**Claude는 GPT Image 2 호출 못 함.** 작업지시자가 1·5단계는 반드시 막아야 진행 가능. 2~4단계는 Claude 자동.

## GPT Image 2 제약 + CLI 변환 파이프라인

`docs/design-system.md` §7.3 프롬프트는 "plain pure white background"를 명시하는데, 이는 **GPT Image 2가 `background: "transparent"` 파라미터를 지원하지 않기 때문**. 산출물은 항상 white BG PNG → **배경 제거가 필수**, `scripts/imageset-capsules.sh`가 자동 처리.

### 자동 파이프라인 (`scripts/imageset-capsules.sh`)

```bash
# 1. 배경 제거 — fuzz 5%로 거의 흰(≥#F2F2F2) 픽셀만 투명화
#    v4 베이지 highlight(~#EFE2C2)·회색/보랏빛 shadow는 안전하게 보존
magick "design/capsules/raw/${name}.png" -fuzz 5% -transparent white "/tmp/${name}-cut.png"

# 2. resize @1x/@2x/@3x (Lanczos, alpha 보존)
#    base 128pt 통일 — list 32pt + Today hero 96~128pt 모두 커버
magick "/tmp/${name}-cut.png" -filter Lanczos -resize "${w1}x${h1}!" \
  "ios/PillPouch/Assets.xcassets/Capsules/${name}.imageset/${name}@1x.png"

# 3. Contents.json 표준 형식 작성 (Universal Image Set, 1x/2x/3x)
```

### `scripts/capsule-spec.json` (§7.2 표 박제)

```json
{
  "_base_size": 128,
  "tablet":  { "ratio": "1:1",   "tone": "single" },
  "softgel": { "ratio": "1:1",   "tone": "single" },
  "capsule": { "ratio": "1:1",   "tone": "two" },
  "powder":  { "ratio": "20:28", "tone": "single" },
  "liquid":  { "ratio": "20:28", "tone": "single" },
  "gummy":   { "ratio": "1:1",   "tone": "single" }
}
```

ratio는 `docs/design-system.md` §7.2(viewBox 표) 비율 그대로 — `1:1` 정사각, `20:28` 세로 길쭉.

### 도구 설치

```bash
brew install imagemagick   # macOS, 필수
```

`potrace`/`vtracer`/`python3 normalize_svg.py` 모두 SVG 변환 폐기로 **불필요**해짐. PR-1에서 의존성 정리 완료 (`scripts/README.md`).

### 자동 trace 품질 미달 시 폴백

PNG 그대로 사용 흐름이라 트레이싱 아티팩트 없음. fuzz 5% 배경 제거에서 v4의 highlight가 같이 투명되는 케이스 발견 시 fuzz 임계 조정(권장 3~7% 범위) 또는 `rembg` 도입 검토 — V1.0에선 v4 베이지 톤이 흰색과 충분히 떨어져 있어 발생 가능성 낮음.

## 폴더 구조

```
design/
└── capsules/
    └── raw/                                        # GPT Image 2 산출물 PNG (커밋)
        ├── tablet.png
        └── ...

scripts/
├── imageset-capsules.sh                            # 자동 변환 파이프라인 (PR-1 박제)
├── capsule-spec.json                               # §7.2 base size + ratio
└── README.md                                       # 의존성/사용법

ios/PillPouch/
├── Assets.xcassets/
│   └── Capsules/                                   # 그룹 (namespace 없음)
│       ├── Contents.json
│       ├── tablet.imageset/                        # PR-1: tablet, PR-2: 나머지 5종
│       │   ├── Contents.json
│       │   ├── tablet@1x.png                       # 128×128
│       │   ├── tablet@2x.png                       # 256×256
│       │   └── tablet@3x.png                       # 384×384
│       └── ...
└── DesignSystem/
    └── Capsules/
        └── CapsuleAsset.swift                      # PR-1 신설

ios/PillPouchTests/
└── CapsuleAssetTests.swift                         # PR-1 신설

docs/screenshots/
└── capsules/
    └── grid-6@32pt.png                             # PR-2에서 6종 그리드
```

**raw PNG는 커밋한다** (작업지시자 2026-04-28 결정). 1024×1024 PNG 6장 ≈ 수 MB 수준. 향후 프롬프트 변경 시 비교 자산. `design/capsules/raw/`는 `.gitignore`에 추가하지 않음.

## 구현 단계

### PR-1: 파이프라인 검증 (1종 = tablet)

#### Step 1-1: 인프라 (Claude, raw PNG 도착 전 가능)

**`ios/PillPouch/DesignSystem/Capsules/CapsuleAsset.swift`**
```swift
enum CapsuleAsset: String, CaseIterable {
    case tablet, softgel, capsule, powder, liquid, gummy
}

extension CapsuleAsset {
    var imageName: String { rawValue }
}
```

PR-1에서 **enum 6종 모두 선언** (인터페이스 안정). 다만 PR-1에서 Asset Catalog에 등록되는 건 `tablet`뿐. PR-2 머지 전에 다른 종을 호출하면 Image가 비어 보임 — Today 화면에서 호출 시점이 PR-2 이후이므로 문제 없음.

`PBXFileSystemSynchronizedRootGroup` 사용 중 — 새 폴더는 자동 빌드 포함, pbxproj 수정 불필요.

#### Step 1-2: 자동 변환 파이프라인 (Claude, raw PNG 도착 후)

작업지시자가 `design/capsules/raw/tablet.png` 드롭 → Claude가:
1. `brew install imagemagick` 의존성 확보 (이미 있으면 skip)
2. `./scripts/imageset-capsules.sh tablet` 실행
3. 산출 imageset의 @2x를 베이지 배경 위에 합성해 시각 검사 (Preview에서 확인하기 전 sanity check)
4. 미달 시 fuzz 임계 조정 또는 작업지시자에게 raw 재생성 요청

`scripts/imageset-capsules.sh`, `scripts/capsule-spec.json`, `scripts/README.md` 3개 파일을 PR-1에서 박제. PR-2는 같은 스크립트로 5종 일괄 변환.

#### Step 1-3: SwiftUI Preview + 테스트 (Claude)

`CapsuleAsset.swift`에 #Preview 2개:
- `tablet — 사이즈 비교` (32/64/128pt 동시 표시, `PPColor.background` 위에)
- `6종 식별성 @ 32pt — PR-1 시점은 tablet만 등록, 나머지는 빈칸`

**`ios/PillPouchTests/CapsuleAssetTests.swift`**
```swift
@Test("CaseIterable이_6종을_노출한다")
@Test("rawValue가_Asset_파일명과_일치한다")
@Test("tablet_이미지_자산_로드_가능")  // PR-1에서 추가 — UIImage(named: "tablet") non-nil
```

테스트 메서드명은 `docs/conventions/code-style.md` §1 한글+언더바 패턴 준수.

#### Step 1-4: 검증 + 보고서

- [ ] `xcodebuild build` 통과
- [ ] `xcodebuild test` — `CapsuleAssetTests` 3건 pass
- [ ] Asset Catalog Image Set으로 `tablet`이 등록되고, Preview에서 베이지 배경 위 자연스럽게 렌더되는지 **작업지시자 시각 확인**
- [ ] 32pt에서 정제로 식별 가능한지 확인
- [ ] `docs/report/task_W2_11_pr1_report.md` 작성 → 작업지시자 승인 ⛔

#### PR-1 커밋 단위

```
docs: add W2-11 (#11) implementation plan
chore(scripts): add capsule PNG conversion pipeline (imageset, spec)
feat(ios): add CapsuleAsset enum + imageName helper
chore(assets): register tablet imageset (1x/2x/3x with bg removal)
test(ios): cover CapsuleAsset cases + tablet asset load
docs: add W2-11 PR-1 (pipeline validation) report
```

6 commit, squash 후 main에 1 commit.

---

### PR-2: 5종 일괄 추가 (`softgel`, `capsule`, `powder`, `liquid`, `gummy`)

#### Step 2-1: 자산 등록 (Claude)

PR-1에서 검증된 절차 5종 반복:
- `design/capsules/raw/{name}.png` (작업지시자)
- `./scripts/imageset-capsules.sh softgel capsule powder liquid gummy` (Claude, 일괄 자동)
- `ios/PillPouch/Assets.xcassets/Capsules/{name}.imageset/Contents.json` + 3 PNG (스크립트 자동 생성)

**capsule 2-tone 처리**: PNG 그대로 사용이라 2-tone seam이 baked-in 상태. SVG 시절의 `currentColor` 분리 처리 불필요. GPT Image 2 산출물의 톤 분리만 작업지시자 시각 검증.

#### Step 2-2: 6종 그리드 Preview + 식별성 검증 (Claude + 작업지시자)

`CapsuleAsset.swift`의 `#Preview "6종 식별성 @ 32pt"`가 PR-2 시점엔 6종 모두 채워짐.

작업지시자가 Preview 캡처 → `docs/screenshots/capsules/grid-6@32pt.png` 커밋 → PR 본문 마크다운 링크.

**자체 식별성 검증**: 솔로 V1이라 "5명 중 4명" 기준은 비현실적 → **작업지시자 단독 검증으로 완화** (작업지시자 2026-04-28 결정). 라벨 가린 그리드를 보고 6종 모두 즉시 식별 가능하면 통과. 1종이라도 헷갈리면 프롬프트 조정 후 재생성 → 자산 재변환 → PR 업데이트. V1 베타 도그푸딩 시 외부 검증으로 보완 → 부족하면 V1.1에서 재생성.

**시리즈 일관성 검증**: 6장이 **동일 카메라 각도·조명·shadow 결·매트 베이지 톤 패밀리**에서 떨어졌는지. 1장만 톤이 어긋나면 그 1종만 재생성. PR-2 마감 전 작업지시자가 6장을 한 화면에 띄워 시리즈로 묶이는지 확인.

#### Step 2-3: 검증 + 보고서

- [ ] 6개 `*.imageset/` 등록 완료
- [ ] `xcodebuild build` + `xcodebuild test` 통과
- [ ] `docs/screenshots/capsules/grid-6@32pt.png` 커밋
- [ ] 작업지시자 식별성·시리즈 일관성 검증 통과
- [ ] 프롬프트 조정 발생 시 `docs/design-system.md` §변경 이력에 추가
- [ ] `docs/report/task_W2_11_pr2_report.md` 작성 → 승인 ⛔

#### PR-2 커밋 단위

```
chore(assets): register 5 capsule imagesets (softgel, capsule, powder, liquid, gummy)
test(ios): extend CapsuleAsset tests for all 6 cases
docs(screenshots): add 32pt identifiability grid
docs(design-system): record prompt adjustments from #11 (if any)
docs: add W2-11 PR-2 (batch) report
```

---

## 검토 이력 (Metal · 물리 시뮬레이션 폐기 사유)

본 task 진행 중 다음 두 옵션을 검토 후 V1 비목표로 결정:

### Metal 직접 렌더링 검토 (2026-04-28)

- **목표**: SDF 셰이더로 캡슐을 픽셀-퍼펙트 렌더, 시간대 색조도 uniform으로 동적 주입.
- **프로토타입**: `MetalPillPreview.swift` 작성 → SDF + cell-shading + ellipse shadow 구현. 빌드/Preview 동작 확인.
- **결과**: 큰 사이즈에서 zone 경계가 swirl/curl artifact 생성 → 셰이더 단순화로 개선했지만 claymorphism 톤 자체는 GPT Image 2 v4 결과 큰 차이 없음.
- **폐기 사유**: 6종 SDF·셰이더 튜닝·SwiftUI 합성·드래그/봉지 통합 비용 1~2주, V1 솔로 일정에 비례한 ROI 낮음. 가설 B(기록 신뢰성) 강화 무관. V1.1 polish 단계에서 도그푸딩 결과 부족 시 재검토.

### 물리 시뮬레이션(SpriteKit) 검토 (2026-04-28)

- **목표**: 봉지 안 캡슐이 디바이스 기울기(`CMMotionManager.deviceMotion.gravity`)에 따라 sloshing — 비가역 행동 기록 비유 강화.
- **검토 결과**: 기술적 가능. SpriteKit이 정확히 이 use case에 맞음(2D 강체 + gravity + 충돌 + 60fps 자동). 4~5일 추가 작업이면 W2 안에서 흡수 가능.
- **폐기 사유**: V1.0 발사 우선. 봉지 5상태 + 가로 드래그가 W2 (M)/(L)에서 이미 충분한 가설 B 강화 인터랙션. 물리 sloshing은 polish 영역 → V1.0 도그푸딩 후 needed 측정되면 V1.1 ADR 작성 후 도입.

---

## 위험 요소

1. **fuzz 5% 배경 제거 한계** — v4의 highlight zone이 흰에 너무 가까우면 같이 투명될 가능성. **완화**: PR-1 tablet에서 dry-run으로 검증 완료(highlight #EFE2C2가 fuzz 임계 #F2F2F2 아래라 안전). 다른 종에서 발생 시 fuzz 3~7% 조정.
2. **ratio 비율 차이로 imageset 사이즈 다양** — `1:1`(tablet 등 4종)와 `20:28`(powder/liquid)이 다름. SwiftUI 사용처에서 `.scaledToFit()` + 명시 frame 사용 권장.
3. **PR-2 의존 — PR-1이 머지 안 되면 PR-2 시작 불가** — 분할 비용. **완화**: PR-1을 작게 유지(1종 + 인프라 + 변환 스크립트). 합의된 흐름 어긋나면 분할을 1 PR로 합쳐도 무방 (작업지시자 결정).
4. **솔로 식별성 검증의 약점** — 작업지시자 단독 검증은 친숙도 편향 위험. **완화**: V1 베타 도그푸딩 시 외부 검증 → 부족하면 V1.1에서 재생성.
5. **raw PNG 커밋** — 작업지시자 2026-04-28 결정으로 커밋 확정. 향후 PNG 파일 수가 늘어 repo가 비대해지면 V1.1에서 git LFS 도입 검토.
6. **CLI 의존성** — `brew install imagemagick` 한 번이면 끝. macOS 가정. CI는 자동 변환 안 하므로 영향 없음 (커밋된 imageset만 사용).
7. **v4 톤 한계** — claymorphism / chunky 결을 GPT Image 2가 못 따라옴 (v1~v4 검증 결과). 본 task는 v4 결을 그대로 시리즈화. polish는 V1.1 후순위.

## 검증 (Issue #11 마감 조건)

PR-1 + PR-2 합쳐서:
- [ ] 6개 `*.imageset/` 등록 + base 128pt @1x/@2x/@3x 사이즈 일치
- [ ] `Image(.tablet)` (auto-generated `ImageResource`) 사용 가능
- [ ] 6종 식별성 32pt에서 작업지시자 단독 검증 통과
- [ ] 6종 시리즈 일관성(카메라/조명/material) 작업지시자 검증 통과
- [ ] 양 PR squash merge, Issue #11 자동 close (`Closes #11`은 PR-2에)

## 가설 B 정합성

- 6종 식별성은 가설 B 자체 강화는 아니지만 **약화 안 함** (Pokemon Sleep 결의 친근함은 의료 톤 회피에 기여 — `docs/brief.md` §시각 언어 정합)
- Non-goals(TCA, Carousel, 단순 탭) 어느 항목도 추가하지 않음
- 시간대 색조 시각 단서는 봉지/헤더에서 표현(본 task 범위 밖) — 캡슐 자산은 단색 1세트로 단순화

## 다음 (이 task 완료 후)

- W2 (M) 봉지 5상태 컴포넌트 task: 본 task의 `Image(.tablet)` 등을 봉지 안 캡슐 표현에 사용
- W1-5 Today 정적 레이아웃 (#14): 봉지 띠 placeholder에 6종 캡슐 노출
- W2 (L) 가로 드래그 task: 찢긴 봉지 안 캡슐 노출 시 본 task 자산 사용
- V1.1 후순위: Metal SDF 렌더링 / 봉지 안 물리 sloshing — 도그푸딩 결과 부족 시 ADR 작성 후 도입
