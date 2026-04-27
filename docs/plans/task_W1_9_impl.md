# task_W1_9_impl.md — design-system.md + 색 토큰 코드화 구현계획서

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#9](https://github.com/kswift1/PillPouch/issues/9) |
| 마일스톤 | W1 |
| 크기 | M |
| 영역 | area:design + area:ios |
| 브랜치 | `kswift1/task9-tokens` |
| 예상 시간 | 3~4시간 |

## 목표

W1까지 합의된 시각 언어를 `docs/design-system.md` SoT로 박제하고, 그중 색·스페이싱·타이포그래피만 iOS Swift 토큰으로 코드화한다. 봉지 5상태/캡슐 6종/햅틱 시퀀스는 W2에서 컴포넌트화하므로 V1 본문에서는 명세까지만 — 코드는 W2 작업.

## 비목표 (이번 task에서 안 하는 것)

- ❌ 봉지 5상태 SwiftUI 컴포넌트 (W2 (M) 봉지 5상태 컴포넌트 task 책임)
- ❌ 캡슐 6종 SVG 실제 제작/등록 — **별도 issue [#11](https://github.com/kswift1/PillPouch/issues/11) (W2)** 로 분리. 본 task는 §7에 **AI 생성 프롬프트 + 정리 가이드 + 작업지시자 작업 흐름**까지 박제
- ❌ 봉지 텍스처/노이즈 overlay (V1.1, 본 task §6에 "추후" 표시만)
- ❌ 햅틱 코드 구현 (W2 (L) 가로 드래그 task)
- ❌ Today 화면 통합 (W1-5 task 책임)
- ❌ `TimeSlot` enum 정의 — W1-3 (다른 워크스페이스, `ios/PillPouch/Models/` 영역). 본 task의 색 토큰은 모델 의존 없이 독립적으로 노출 (`PPColor.morning/.lunch/.evening`)

## 봉지/캡슐 구현 결정 (작업지시자 2026-04-27 승인)

**하이브리드 3-레이어** 채택:
- **L1 봉지 껍데기**: SwiftUI Shape + Path + Canvas (찢기 progress 동적 변형, 다크/시간대 색조 동적 적용)
- **L2 캡슐 6종**: SVG 자산 (모노크롬 + 1 hint, `.foregroundStyle()` 색 주입). **AI 생성** (Midjourney/Ideogram) → 작업지시자 정리 → Asset Catalog 등록 (#11에서 진행)
- **L3 텍스처/종이결**: V1.1 후순위, V1.0 미포함

본 task는 명세 SoT만 박제. 실제 봉지 SwiftUI 컴포넌트는 W2, 캡슐 SVG는 #11.

## 구현 단계 (3단계, 순차)

### Step 1: `docs/design-system.md` 본문 채움

기존 stub의 "## 채울 항목" 체크리스트를 모두 본문 섹션으로 풀어쓴다. 기획서 §시각 언어 / §봉지 상태 5종 / §핵심 인터랙션 명세 / §하지 말아야 할 시각 결정의 **요약 + 명세 정밀화** — 기획서를 그대로 베끼지 말고, 디자인 시스템 SoT 관점에서 토큰명·수치·매핑 표를 추가.

본문 섹션 (위→아래):

1. **목적 & SoT 위계 선언** — 위계 명시:
   - **상위 SoT**: `docs/brief.md` §시각 언어 (전략·가설 B 정합성). 변경 시 ADR 필수 (CLAUDE.md 정책)
   - **시각 수치 SoT**: 본 문서 (`docs/design-system.md`). brief를 풀어쓴 sub-SoT. 색 hex·수치·5상태 변형은 본 문서가 권위
   - **변경 정책**: 수치/hex 변경은 PR만으로 가능. 단, 가설 B를 약화하는 시각 결정이거나 brief 본문과 모순되면 ADR 필수. 모든 변경은 §변경 이력 추가.
2. **톤 / 금기 / 지향** — 기획서 §시각 언어 §톤 압축 + 금기 색 hex 예시 (형광 그린/레드 → `#FF3B30`, `#34C759` 회피 사례).
3. **색 토큰**
   - 배경 (라이트 오프화이트 `#FAF7F2`, 다크 차콜 `#1C1A17` — 순수 검정 X)
   - 시간대 색조 표: 토큰명 / 라이트 hex / 다크 hex (살짝 채도 낮춤) / 사용처
     - 아침 `#F5C56B` (warm yellow) / 다크 `#C9A157`
     - 점심 `#E89A78` (mid coral / apricot) / 다크 `#B97155`
     - 저녁 `#7B6BA8` (cool indigo / lavender) / 다크 `#5E5283`
   - Surface / Stroke / Text 토큰 (일반)
   - 다크모드 정책: "차콜 베이스, 시간대 색조는 채도 낮춰 유지"
4. **타이포그래피 스케일** — 시스템 폰트(Pretendard 미사용 V1) + Dynamic Type 매핑 표 (Title L / Title M / Body / Caption / Mono — 슬롯 시각 표시 한정)
5. **스페이싱 토큰** — 8pt grid (`xs=4, sm=8, md=16, lg=24, xl=32, xxl=48`)
6. **봉지 상태 5종 시각 명세** — 기획서 §봉지 상태 5종 표를 풀어쓰고, **봉지 수치 SoT 표** 박제 (W2 (L) 가로 드래그 task의 입력값):
   - 봉지 비율 가로 100% : 세로 32% (한국 1일분 봉지 + iPhone 세로 화면 3봉지 스택 시 캡슐 식별 가능 마진. 100:28은 너무 납작 → 100:32로 살짝 높임. W2 시뮬레이션 후 ±2%pt 조정 가능)
   - 비닐 반투명도: 라이트 알파 0.85 / 다크 0.75 → 안 캡슐 60% 비침. **도그푸딩 D7 후 ±0.05 조정 게이트** 메모 (V1.0 출시는 0.85/0.75로 고정)
   - V자 컷 위치: 상단 좌측에서 12% 안쪽 / V자 깊이: 봉지 높이의 22% (98pt × 22% ≈ 22pt → 32pt 표시 시 시각 확보)
   - 찢김 경로: 베지어 + sine 노이즈 (amplitude 2.0pt, period 8pt — @2x도 보이도록 1.5→2.0)
   - 찢긴 윗 조각 매달림 각도: 12~18° (랜덤, seed = 봉지 ID)
   - 100% 찢김 시 캡슐 노출 면적: 봉지 면적의 약 65%
   - 그림자: y=2 blur=4 alpha=0.08 (시간대 색조 X, 모드 무관 고정)
   - **채도 감소 공식 (Skipped/Missed)**: HSB 색공간에서 `S_new = S_base × (1 - p)`. p=0.40(Skipped), p=0.50(Missed). 명도 V는 그대로.
   - 5상태별 추가 변형:
     - **Sealed**: 기본
     - **Active**: 그림자 alpha 0.16, 미세 글로우 (시간대 색조 alpha 0.12 outer ring)
     - **Torn**: 상단 path 분리 + 하단 path 캡슐 노출 + 매달림 각도 적용
     - **Skipped**: stroke dashed 4-2pt, 채도 ×0.6, 봉지 봉인 유지
     - **Missed**: 정적 상태에서만 rotation -3°(드래그 중 0°), 채도 ×0.5, 알파 0.7
7. **캡슐 일러스트 6종 가이드** — 자산 제작은 [#11](https://github.com/kswift1/PillPouch/issues/11)에서. 본 섹션은 (a) 공통 SVG 명세 (b) 6종 명세 표 (c) **GPT Image 2 프롬프트 6개** (d) 정리·등록 워크플로우를 박제.

   **(a) 공통 SVG 명세**
   - 라인 두께 1.5pt, 코너 라운드 2pt
   - 모노크롬 단색 fill (캡슐만 예외 — 2-tone 허용) + 1 hint dot (흰색, 광점)
   - Template Image (`fill="currentColor"`) — `.foregroundStyle(PPColor.morning)` 동적 색 주입
   - Asset Catalog Symbol Image 등록 (`Capsules/<name>.symbolset/`)

   **(b) 6종 명세 표**
   | 캡슐 | viewBox | 색 정책 | 식별 핵심 |
   |---|---|---|---|
   | tablet (정제) | 24×24 | 단색 | 원통 옆면, 가운데 score line |
   | softgel (소프트젤) | 24×24 | 단색 + 흰 광점 | 길쭉 타원, 광택 |
   | capsule (캡슐) | 24×24 | **2-tone 상하 분리** | 양쪽 반원 + 깔끔한 접합선 |
   | powder (가루) | 20×28 | 단색 + 작은 dot pattern | 스틱팩 직사각, 톱니 상단, 안쪽 작은 점 5~8개 |
   | liquid (액상) | 20×28 | 단색 + 작은 inner highlight | 물방울, 안쪽 살짝 fill (hollow 아님 — 식별성) |
   | gummy (구미) | 24×24 | 단색 + 흰 광점 | **rounded blob 실루엣** (곰돌이/별 X — 성인 친화 중립) |

   **(c) GPT Image 2 프롬프트 6개 (작업지시자 사용)**

   GPT Image 2 (2026-04-21 출시)는 OpenAI 공식 가이드의 `Style → Subject → Details → Constraints → Use case` 라벨 구조 권장. Midjourney 플래그(`--style raw`) 사용 안 함. Quality는 `high` 권장 (small icon).

   **공통 라벨 블록 (각 프롬프트 머리/꼬리에 그대로 사용)**
   ```
   Style: minimalist flat pictogram, vector-like clean shapes, no gradients, no shadows, no outlines except 1.5pt stroke if needed, plain pure white background
   Use case: mobile app pictogram for an adult vitamin tracking app, must read clearly at 24px
   Constraints: single centered subject with generous padding (subject occupies ~60% of frame), no text, no watermark, no logos, no medical iconography (no cross, no Rx), no shadow, friendly but not childish, scalable silhouette
   ```

   **개별 Subject + Details**

   1. **tablet (정제)**
      ```
      Subject: a round white pill tablet viewed from the side
      Details: short cylinder shape, soft rounded edges, a single horizontal score line across the middle, single fill color
      ```

   2. **softgel (소프트젤)**
      ```
      Subject: an oval softgel capsule, slightly glossy
      Details: smooth elongated egg shape, one small white highlight dot in the upper-left, single fill color, line weight 1.5pt
      ```

   3. **capsule (캡슐)** — *2-tone 명시, 공통 라벨의 "single fill color"는 본 항목에서 무시 명시*
      ```
      Subject: a two-tone medication capsule, horizontal orientation
      Details: pill capsule split into two equal halves by a clean vertical seam line, top half one color, bottom half a slightly darker shade, no other detail
      Override: two fill colors allowed for this icon (not single color)
      ```

   4. **powder (스틱팩 가루)**
      ```
      Subject: a vertical powder stick pack sachet
      Details: tall rectangular pouch (proportions 20:28), small zigzag serrated edge on the top, 5 to 8 tiny solid dots scattered inside the lower two-thirds suggesting powder, single fill color for the pouch outline
      ```

   5. **liquid (액상 드롭)**
      ```
      Subject: a single liquid droplet
      Details: classic teardrop shape with rounded bottom and pointed top, a small lighter fill area inside near the upper-left as inner highlight (not hollow), single fill color outline
      ```

   6. **gummy (구미)**
      ```
      Subject: a soft rounded blob of gummy candy
      Details: irregular but symmetric pebble shape with smooth rounded edges, one small white highlight dot near the top, single fill color, no facial features, no animal shape
      ```

   **(d) 정리·등록 워크플로우 (#11에서 작업지시자 진행)**
   1. 작업지시자가 GPT Image 2로 위 6개 프롬프트 실행 (`quality="high"`, 각 4~8장 후 1개 선택)
   2. Figma/Illustrator import → outline 단순화 → 단색 path만 남기고 SVG export (viewBox 통일 24×24 또는 20×28, `fill="currentColor"`)
   3. `ios/PillPouch/Assets.xcassets/Capsules/{tablet,softgel,capsule,powder,liquid,gummy}.symbolset/` 등록 (Symbol Image, Template)
   4. 32pt 표시 시 6종 식별성 자체 검증 (다른 사람 5명에게 라벨 없이 보여주고 4종 이상 맞히는지) → 부족하면 프롬프트 조정 후 재생성
   - **검증 기준**: Pokemon Sleep / Bearable 픽토그램 결의 친근함, 의료 톤 X, 한 색으로 인쇄 가능한 단순도
8. **햅틱 시퀀스 표** — 드래그 진행도 0~30/30~70/70~100/100% 별 generator 종류·강도·횟수 (기획서 §핵심 인터랙션 명세 표를 SoT로 박제). 코드 구현은 W2.
9. **하지 말아야 할 시각 결정** — 기획서 §하지 말아야 할 시각 결정 그대로 + 추가 (의료 톤 색·알람 시계 아이콘·처방전 폰트 등).
10. **변경 이력** — `## 변경 이력` 섹션 + W1 (이 PR) 항목.

수치/hex는 SoT. iOS 토큰 코드와 1:1 일치해야.

### Step 2: iOS 토큰 코드 (`ios/PillPouch/DesignSystem/Tokens/`)

Xcode 프로젝트는 `PBXFileSystemSynchronizedRootGroup`(pbxproj line 32~48) 사용 — `ios/PillPouch/` 하위에 새 폴더/파일을 추가하면 자동으로 빌드 대상 포함. **pbxproj 수정 불필요.**

#### 2-a. `Color+Tokens.swift`

- Namespace enum `PPColor` (`enum`, no instances) — `Color.pp.morning` 식 접근 위해 `extension ShapeStyle where Self == Color`도 같이 쓸까 고민 → **단순화: `enum PPColor { static let morning: Color = ... }` 만 노출**. 사용처: `RoundedRectangle().fill(PPColor.morning)`.
- 다크모드 동적: `Color(uiColor: UIColor { trait in trait.userInterfaceStyle == .dark ? UIColor(...darkHex) : UIColor(...lightHex) })`
- 노출 토큰: `background`, `surface`, `stroke`, `textPrimary`, `textSecondary`, `morning`, `lunch`, `evening`
- 내부 helper: `static func dynamic(light: UInt32, dark: UInt32) -> Color` — hex int → UIColor 변환 + trait collection 분기.
- `unsafe_code` 류 없음, `import SwiftUI` + `import UIKit`만.

#### 2-b. `Spacing.swift`

- `enum PPSpacing { static let xs: CGFloat = 4; static let sm: CGFloat = 8; ... static let xxl: CGFloat = 48 }`
- 보너스 도우미 X (`@ScaledMetric` 등은 W2 컴포넌트에서 필요할 때 도입). 지금은 단순 상수만.

#### 2-c. `Typography.swift`

- `enum PPFont { static let titleL: Font = .system(.largeTitle, design: .rounded).weight(.semibold); ... }`
- `design: .rounded` 강제 (Things 3 결).
- `Dynamic Type 지원`을 위해 `.system(_ textStyle:)` 사용 — fixed point size X.
- 토큰: `titleL`, `titleM`, `body`, `caption`, `mono` (mono는 슬롯 시각 표시용 `.system(.body, design: .monospaced)`).

#### 2-d. preview 안전성

3개 파일은 모두 view를 export하지 않음 (토큰만). Preview struct 추가 X. `#Preview` 매크로 X.

### Step 3: 빌드 검증 + README 색인 + 보고서 + PR

- `xcodebuild -scheme PillPouch -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 통과 확인 (CI와 동일 옵션).
- 테스트는 옵션 — 기존 `PillPouchTests`/`PillPouchUITests`가 default 그대로면 통과. 새 테스트 추가 X (토큰 상수에 unit test는 과함, W2 컴포넌트와 함께 snapshot test 도입).
- `docs/design-system.md` 자체가 README 역할 — `docs/README.md` 인덱스에 이미 링크가 있는지 확인하고 누락 시 추가.
- `docs/report/task_W1_9_report.md` 작성 → 작업지시자 승인 ⛔
- PR 생성 (가설 B 체크박스 + Non-goals 체크 포함) → squash merge.

## 커밋 단위 (Conventional Commits)

```
docs: add W1-4 (#9) implementation plan
docs(design-system): expand color, typography, spacing tokens
docs(design-system): add pouch states, capsule, haptic specs
feat(ios): add color, spacing, typography design tokens
docs: add W1-4 final report
```

5 commit. Squash 후 main에 1 commit.

## 위험 요소

1. **워크스페이스 A(W1-3 SwiftData) 동시 작업 충돌** — `ios/PillPouch/DesignSystem/Tokens/` 신규 폴더라 충돌 없음. main에 A가 먼저 머지되면 `git fetch origin && git rebase origin/main`. pbxproj 직접 수정 안 하므로 충돌면이 거의 없음.
2. **다크모드 hex 채도 낮춤 — 디자이너 검증 부재** — 솔로 V1, 작업지시자가 디자이너 역할. 1차 hex는 라이트 hex의 V값을 70~80%로 낮추는 휴리스틱. 도그푸딩에서 부족하면 V1.1 조정.
3. **iOS 17.2+ API 사용 — `Color(uiColor:)`는 iOS 15+ OK** — 호환성 이슈 없음. `Font.system(_:design:)`은 iOS 13+, `.rounded` 디자인 iOS 13+, weight modifier iOS 13+.
4. **CI ios-build paths filter** — `ios/**` 변경 있으므로 trigger됨. docs-only가 아니므로 NO_CHECKS 케이스 아님. Monitor 표준 패턴 그대로 사용.
5. **워크스페이스 A 영역 침범 우려** — 절대 `ios/PillPouch/{Models,App,Item.swift,ContentView.swift,PillPouchApp.swift}` 수정 X. 토큰만 노출, 적용은 W1-5 (#5)에서.

## 검증 (Issue #9 마감 조건)

- [ ] `docs/design-system.md` — 위 Step 1의 10개 본문 섹션 모두 채움, "## 채울 항목" 체크리스트 제거 또는 [x] 처리
- [ ] `ios/PillPouch/DesignSystem/Tokens/Color+Tokens.swift` 존재, `PPColor` enum + 8개 이상 토큰
- [ ] `ios/PillPouch/DesignSystem/Tokens/Spacing.swift` 존재, `PPSpacing` enum + 6개 토큰 (xs~xxl)
- [ ] `ios/PillPouch/DesignSystem/Tokens/Typography.swift` 존재, `PPFont` enum + 5개 토큰
- [ ] `xcodebuild ... build` 로컬 통과 (CI도 자동 trigger)
- [ ] `docs/report/task_W1_9_report.md` 작성, 작업지시자 승인
- [ ] PR squash merge, Issue #9 자동 close

## 가설 B 체크

- ✅ 시간대 색조·봉지 5상태 명세 박제는 "찢긴 봉지 = 비가역적 시각 증거" 가설을 시각 토큰 단계에서 강화
- ✅ 의료 톤·형광색·체크 메타포 회피를 코드/문서 양쪽에서 박제 → 후속 PR이 가설 약화 시각 결정을 못 하도록 가드레일
- ✅ Non-goals(TCA, Carousel, 단순 탭) 어느 항목도 추가하지 않음

## 다음 (이 task 완료 후)

- W1-5 (향후 등록될 Today 정적 레이아웃 task)에서 본 토큰들을 import하여 첫 화면 구성
- [#11](https://github.com/kswift1/PillPouch/issues/11) (W2): 작업지시자가 본 task §7의 AI 프롬프트로 캡슐 6종 생성 → SVG 정리 → Asset Catalog 등록
- W2 (M) 봉지 5상태 컴포넌트 task에서 `PPColor.morning/lunch/evening` + 본 task §6 봉지 수치 SoT + #11 캡슐 자산을 결합한 `PouchView` 컴포넌트 구현
- W2 (L) 가로 드래그 task에서 본 task §6 햅틱 시퀀스 + 50% 임계 + 4단계 시각 코드화
