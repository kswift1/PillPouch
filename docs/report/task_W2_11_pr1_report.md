# task_W2_11_pr1_report.md — 캡슐 자산 PR-1 (파이프라인 검증, tablet 1종) 최종보고서

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#11](https://github.com/kswift1/PillPouch/issues/11) |
| 마일스톤 | W2 |
| 크기 | M (PR 2개 분할 중 PR-1) |
| 영역 | area:design + area:ios |
| 타입 | type:feat |
| 브랜치 | `local/task11` |
| 계획서 | [`task_W2_11_impl.md`](../plans/task_W2_11_impl.md) |
| 완료 | 2026-04-28 |

## 결과 요약

GPT Image 2 산출물 PNG를 Asset Catalog Image Set으로 자동 등록하는 파이프라인을 박제하고, `tablet` 1종으로 끝-끝 dry-run을 끝냈다. PR-2(나머지 5종 일괄)에서 동일 흐름을 반복하면 됨.

본 task 진행 중 작업지시자와 함께 **두 옵션을 검토 후 V1 비목표로 폐기**하여 계획서에 박제했다 (§검토 이력):
- Metal 직접 렌더링 (SDF + cell-shading 셰이더 프로토타입까지 작성 후 폐기)
- 봉지 안 캡슐 물리 sloshing (SpriteKit 기반)

또한 W1-9 ADR 시점의 SVG/Symbol Image/`currentColor` 흐름을 **PNG/Image Set 흐름으로 변경**하는 결정도 본 PR에서 박제.

빌드/테스트 모두 통과:
- `xcodebuild build` ✅ (iPhone 17 Pro Sim, iOS 26.4)
- `xcodebuild test` ✅ — `CapsuleAssetTests` 3건 + 기존 W1-10 테스트 모두 pass

## 수행 내역 (계획 대비)

| Step | 계획 | 실제 | 비고 |
|---|---|---|---|
| 1-1 | `CapsuleAsset` enum 6종 | ✅ | 각 case별 doc-comment(`docs/conventions/code-style.md` §2 준수) |
| 1-1.5 | 변환 파이프라인 박제 | ✅ | `scripts/imageset-capsules.sh` + `capsule-spec.json` + `README.md` |
| 1-2 | `tablet.imageset` Asset Catalog 등록 | ✅ | @1x 128px, @2x 256px, @3x 384px, Universal |
| 1-3 | SwiftUI Preview + 테스트 | ✅ | Preview 2종(사이즈 비교·6종 그리드), 테스트 3건 |
| 1-4 | 빌드/테스트 검증 + 보고서 | ✅ | 본 보고서 |

## 핵심 결정 (계획 변경 사항)

### 1. SVG/Symbol Image → PNG/Image Set 전환

**기존**: W1-9 ADR — SVG Symbol Image + `currentColor` 동적 색 주입.
**변경**: 색 포기(시간대 색조 시각 단서를 봉지/헤더로 이관) 결정 후 `currentColor`가 의미 없어짐 → PNG 그대로 Image Set 등록.
**이점**:
- v4 시각 특성(cell-shading·shadow·베이지 톤) 100% 보존
- Xcode GUI 협조 불필요
- 변환 단계 단순화 (배경 제거 + resize만)

### 2. Metal 직접 렌더링 폐기

`MetalPillPreview.swift` 프로토타입 작성 → SDF + 3-zone cell-shading + ellipse shadow 구현 → claymorphism 톤은 GPT Image 2 v4와 큰 차이 없음 확인 → 6종 셰이더 튜닝·SwiftUI 합성·드래그/봉지 통합 비용 1~2주, V1 솔로 일정에 ROI 낮음 → V1.1 polish로 미룸. 프로토타입 파일 삭제.

### 3. 물리 시뮬레이션 폐기

봉지 안 캡슐 sloshing(SpriteKit 기반)을 검토 — 기술적 가능, 4~5일 작업이면 W2 안에서 흡수 가능. 그러나 V1.0 발사 우선 + 봉지 5상태 + 가로 드래그가 이미 가설 B 강화 인터랙션을 제공 → V1.1 도그푸딩 후 needed 측정되면 ADR 작성 후 도입. 본 task 범위 밖.

### 4. tablet 자산 톤 결정 — v4 결로 6종 일관 생성

GPT Image 2 v1·v2·v3·v4 4번 iteration 결과:
- v1·v2: 약품 카탈로그 사진 결 → 의도 미달
- v3 보강 프롬프트(레퍼런스 첨부 동반): 시도 → 결과 v4
- v4: 매트 베이지 3D, photoreal 회피 — claymorphism은 못 따라오지만 차분한 톤. **이걸 6종 시리즈로 일관 생성**하기로 결정.

claymorphism / chunky cell-shading은 GPT Image 2의 한계로 확인. V1.1 polish 단계에서 도그푸딩 부족 시 도구 변경(Midjourney 등) 또는 Metal 도입 재검토.

## 검증 결과

### 빌드

```
xcodebuild build -scheme PillPouch -sdk iphonesimulator
... ** BUILD SUCCEEDED **
```

### 테스트 (3건 신규 + 기존 모두)

```
CapsuleAssetTests/모든_케이스_6종              ✅
CapsuleAssetTests/rawValue_파일명_일치          ✅
CapsuleAssetTests/tablet_자산_로드             ✅
EnumRoundtripTests (5건)                       ✅
ModelContainerSmokeTests (2건)                 ✅
UserSettingsTests (2건)                        ✅
PillPouchUITests (3건)                         ✅
```

### 시각 검증

- `tablet.imageset/tablet@2x.png`을 `PPColor.background`(베이지 #FAF7F2) 위에 합성 → 흰 배경 흔적 없이 자연스럽게 얹힘 ✅ (작업지시자 Preview 캡처로 OK)
- 32pt/64pt/128pt 사이즈 모두 정제로 즉시 식별 가능 ✅
- v4 톤(cell-shading·shadow·베이지) 보존 ✅

### 자동 변환 파이프라인 dry-run

```
$ ./scripts/imageset-capsules.sh tablet
→ tablet
  ✓ ios/PillPouch/Assets.xcassets/Capsules/tablet.imageset (@1x 128×128, @2x 256×256, @3x 384×384)
done.
```

## 발생한 이슈와 해결

1. **SVG 자동 변환 dry-run에서 inverse 결과** — `potrace` 입력 비트맵의 흑백 반전 누락 발견. `-negate` 추가로 해결. **이후 SVG 흐름 자체를 폐기**해 더 이상 영향 없음.
2. **PNG에 흰 배경 baked-in** — pivot 시 배경 제거 단계 누락. `magick -fuzz 5% -transparent white`를 imageset 스크립트에 추가하여 해결. v4 highlight(#EFE2C2)는 fuzz 임계 #F2F2F2 아래라 안전.
3. **`Image(.tablet)` 모호성** — Xcode 자동 생성 `ImageResource.tablet`과 `Image(_ asset: CapsuleAsset)` 확장이 충돌. Image 확장 제거하고 `imageName` 헬퍼만 노출. `Image(.tablet)`은 자동 생성 ImageResource로 동작.
4. **Xcode Preview 캐시** — Asset Catalog 변경 후 Preview에 흰 배경이 잠시 잔존. Clean Build Folder로 해결.

## 가설 B 정합성

- ✅ 6종 식별성은 가설 B 자체 강화는 아니지만 **약화 안 함** (Pokemon Sleep 결의 친근함은 의료 톤 회피에 기여)
- ✅ Non-goals(TCA, Carousel, 단순 탭) 어느 항목도 추가하지 않음
- ✅ 시간대 색조 시각 단서는 봉지/헤더에서 표현 (본 task 범위 밖)
- ✅ Metal/물리 sloshing은 V1.1로 미뤄 V1.0 발사 일정 보호

## 다음 (PR-1 머지 후)

- 작업지시자: 나머지 5종(softgel/capsule/powder/liquid/gummy) GPT Image 2 프롬프트 실행 → `design/capsules/raw/{name}.png` 5장 추가
- Claude (PR-2): `./scripts/imageset-capsules.sh softgel capsule powder liquid gummy` 일괄 변환 + 6종 그리드 Preview 검증 + 보고서

## PR 본문 첨부 예정 링크

- 계획서: [`docs/plans/task_W2_11_impl.md`](../plans/task_W2_11_impl.md)
- 본 보고서: [`docs/report/task_W2_11_pr1_report.md`](task_W2_11_pr1_report.md)
- 변환 스크립트 README: [`scripts/README.md`](../../scripts/README.md)
- 디자인 시스템 §7 (캡슐 명세): [`docs/design-system.md`](../design-system.md)
