# task_W2_17_report.md — 카테고리 16종 시드 자산 + JSON 동봉 최종보고서

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#17](https://github.com/kswift1/PillPouch/issues/17) |
| 마일스톤 | W2 |
| 크기 | M (시장조사 + 12 → 17 → 16종 확장) |
| 영역 | area:design + area:ios |
| 타입 | type:feat |
| 브랜치 | `local/task17` |
| 계획서 | [`task_W2_17_impl.md`](../plans/task_W2_17_impl.md) |
| 시장조사 | [`docs/working/market-research-summary.md`](../working/market-research-summary.md) |
| 완료 | 2026-04-28 |

## 결과 요약

ADR-0007 결정에 따라 영양제 카테고리 시드 자산 + JSON을 앱 번들에 동봉.

본 task 진행 중 두 차례 결정 변경:
1. **시장조사 후 12 → 17종 확장** (한국·글로벌 시장 핵심 카테고리 추가)
2. **작업지시자 결정으로 redGinseng(홍삼) 제거 → 17 → 16종**

또 진행 중 카테고리별로 시장조사 + 시판 실물 정합 검증 후 형태/색/재질 spec 갱신:
- glucosamine: tablet → capsule (Solgar 결)
- iron: flat disc → biconvex round tablet (ferrous fumarate cliché)
- probiotics: 단색 핑크 → 반투명 + 흰분말 + seam (Jarrow/Culturelle 결)
- 캡슐 카테고리(probiotics·milkThistle·glucosamine) seam 가시 spec 변경
- other: v4 (#11에서 받은) → v39로 교체 (시리즈 결속 회복)

빌드/테스트 모두 통과:
- `xcodebuild build` ✅ (iPhone 17 Pro Sim, iOS 26.4)
- `xcodebuild test` ✅ — 16건 모두 pass (CategoryMirrorTests 3 + EnumRoundtrip 4 + UserSettings 4 + IntakeLogComputed 2 + ModelContainerSmoke 3)

## 16종 최종

| # | key | 한글 | 형태 | 색 | 시장 cliché |
|---|---|---|---|---|---|
| 1 | omega3 | 오메가-3 | 글로시 oval softgel | golden amber #E5B570 | 어유 softgel |
| 2 | probiotics | 유산균 | 반투명 캡슐 + 흰분말 + seam | 오프화이트 #F5F0E8 | Jarrow/Culturelle |
| 3 | vitaminC | 비타민 C | matte oblong + 세로 score | 옅은 노랑 #E5C547 | 고려은단 |
| 4 | multivitamin | 종합 비타민 | 큰 oval + 점박이 | tan #C9A878 | Centrum |
| 5 | vitaminD | 비타민 D | 작은 round disc | 머스타드 #D6B547 | Solgar D3 |
| 6 | vitaminB | 비타민 B | matte oblong + 세로 score | 핑크 레드 #C5705A | 종근당 활력비타민B |
| 7 | milkThistle | 밀크씨슬 | matte opaque 캡슐 + seam | 짙은 olive #7A6E3A | NOW Foods/종근당 |
| 8 | glucosamine | 글루코사민 | 세미-반투명 캡슐 + seam | cream-beige #E5D8B0 | Solgar 관절 |
| 9 | lutein | 루테인 | 글로시 oval softgel | 진한 마호가니 #6B2A1A | 안국건강 루테인+빌베리 합제 |
| 10 | collagen | 콜라겐 | semi-gloss oval softgel | 옅은 핑크-베이지 #E5C8B0 | 마린 콜라겐 |
| 11 | magnesium | 마그네슘 | matte flat round disc | cool slate #C5CAD0 | NOW Magnesium Glycinate |
| 12 | calcium | 칼슘 | 큰 두툼 oblong matte chalky | 화이트 크림 #E8E0D0 | Caltrate |
| 13 | iron | 철분 | matte biconvex round tablet | 빨강끼 적갈 #9A4030 | ferrous fumarate |
| 14 | zinc | 아연 | matte flat round disc | 따뜻 light taupe #B8A595 | Solgar Zinc Picolinate |
| 15 | coq10 | 코엔자임 Q10 | 글로시 oval softgel | 진한 코랄 #E5704A | Qunol Ubiquinol |
| 16 | other | 기타 | matte flat round disc 매끈 | warm beige #D9C9A8 | generic supplement |

## 시각 변별 시스템

### 형태 그룹 5종

- **softgel** (single shell, no seam): omega3, lutein, collagen, coq10
- **capsule** (two-piece + seam 가시): probiotics, milkThistle, glucosamine
- **oblong tablet**: vitaminC, vitaminB, multivitamin, calcium
- **flat round disc**: vitaminD, magnesium, zinc, other
- **biconvex round tablet**: iron (단독)

### 재질 그룹 4종

- **glossy translucent**: omega3, lutein, coq10 (어유 softgel cliché)
- **semi-gloss**: collagen (마린 콜라겐 dustier)
- **semi-translucent**: probiotics (반투명 외피 + 흰분말 가시), glucosamine (세미-반투명 + cream-beige)
- **strict matte**: 모든 정제 + milkThistle 캡슐 (matte opaque)

### 색 그룹 5종

- **노랑/오렌지/앰버**: omega3, vitaminC, vitaminD
- **레드/핑크/코랄**: vitaminB, collagen, coq10
- **다크 톤**: lutein (마호가니), milkThistle (올리브), iron (rust)
- **베이지/탠/크림**: multivitamin, calcium, glucosamine, other
- **cool/그레이**: probiotics (오프화이트), magnesium (slate), zinc (taupe)

### 표면 detail 4종

- **세로 score**: vitaminC, vitaminB
- **점박이**: multivitamin (멀티 cue)
- **가운데 seam (캡슐)**: probiotics, milkThistle, glucosamine
- **매끈**: 그 외 모두

## 수행 내역 (계획 대비)

| Step | 계획 | 실제 | 비고 |
|---|---|---|---|
| 1 | 시장조사 + 카테고리 결정 | ✅ | 12 → 17 → 16, V1.1 후순위 박제 |
| 2 | 인프라 rename (capsules → categories) | ✅ | scripts·design 폴더·imageset 모두 |
| 3 | other 폴백 자산 재활용 | ✅ + 재교체 | v4 → v39 (시리즈 결속) |
| 4 | 17개 → 16개 프롬프트 박제 | ✅ | category-prompts.md (운동 후 작업지시자 사용) |
| 5 | 작업지시자 11장 GPT Image 2 생성 | ✅ | v22~v39 시리즈 일관 톤 |
| 6 | imageset-categories.sh 일괄 변환 | ✅ | 16 imageset (각 1x/2x/3x) |
| 7 | category-seed.json 16 row 박제 | ✅ | displayOrder 시장 점유율 기반 |
| 8 | 시리즈 일관성 + 식별성 검증 | ✅ | 5개 그리드 (32/64/96/128 + by-color) |
| 9 | 빌드/테스트 + 보고서 + PR | ✅ | 본 보고서 |

## 진행 중 결정 변경 (시장조사 정합)

각 카테고리 프롬프트 작성 전 웹서치로 시판 실물 검증. 결과로 다음 spec 변경:

1. **glucosamine**: tablet (Schiff Move Free 결) → capsule (Solgar 결)
   - 사용자 직관(시장 캡슐 형태가 흔하다는 사진 제공)
   - 캡슐 그룹 3종(probiotics·milkThistle·glucosamine)으로 변별 시스템 재조정
2. **iron**: flat disc → biconvex round tablet (ferrous fumarate cliché)
   - 두께 chunky 문제 해결 + 시장 정합 ↑
3. **probiotics**: 단색 파스텔 핑크 → 반투명 외피 + 흰분말 + seam
   - 사용자 직관(투명 캡슐+흰 분말이 더 정합) 검증 (Jarrow/Culturelle 결)
4. **모든 캡슐 카테고리에 seam 가시화** (probiotics·milkThistle·glucosamine)
   - v22 작업지시자 직관 검증 후 spec 정정 ("NO seam" → "seam MUST be visible")
5. **lutein 색**: golden mustard → 진한 마호가니 적갈
   - 한국 시장 BEST 안국건강 루테인+빌베리 합제 cliché
6. **other**: v4 (#11) → v39 (시리즈 결속 회복)
   - 작업지시자 "따로 노는 느낌" 짚어줌

각 변경 시 변별 시스템 재점검 + 충돌 페어 분석 (계획서 §위험 요소).

## 변경 파일

### 자산
- `design/categories/raw/*.png` × 16 (모두 커밋)
- `ios/PillPouch/Assets.xcassets/Categories/*.imageset/` × 16 (각 4 파일 = 64)
- `docs/screenshots/categories/grid-{32,64,96,128}pt.png` + `grid-by-color.png` × 5

### 인프라
- `scripts/imageset-categories.sh` — 16종 인자
- `scripts/category-spec.json` — 16 row + `_form` 필드
- `scripts/preview-categories.sh` — 그리드 자동 생성
- `scripts/README.md`

### 메타데이터
- `ios/PillPouch/Resources/category-seed.json` — 16 row, displayOrder 시장 점유율 기반

### 문서
- `docs/plans/task_W2_17_impl.md` — 12 → 16 갱신, 시각 변별 시스템 재정립, 위험 페어 분석
- `docs/adr/0007-server-catalog-as-source-of-truth.md` — Status Amended (12 → 17 → 16)
- `docs/working/category-prompts.md` — 16개 프롬프트 박제 (작업 흐름 정합)
- `docs/working/task-17-review.md` — 운동 후 리뷰 통합 문서
- `docs/working/market-research-summary.md` — 한국·글로벌 시장조사 출처 + 결과

## 검증 결과

### 빌드
```
xcodebuild build -scheme PillPouch -sdk iphonesimulator
... ** BUILD SUCCEEDED **
```

### 테스트 (16건 모두 pass)
```
EnumRoundtripTests (4건):           ✅
IntakeLogComputedTests (2건):       ✅
UserSettingsTests (4건):            ✅
CategoryMirrorTests (3건):          ✅
ModelContainerSmokeTests (3건):     ✅
```

### 시각 검증 (작업지시자 단독)
- ✅ `grid-128pt.png` 16종 시리즈 결속 (카메라/shadow/lighting 일관)
- ✅ `grid-by-color.png` 색 그룹별 변별 명확
- ✅ 32pt 식별성 — 색·형태·재질로 모든 카테고리 변별

### 자산 자동 변환
```
$ ./scripts/imageset-categories.sh
→ omega3 ✓
→ probiotics ✓
... × 16
done.
```

## 가설 B 정합성

- ✅ 사용자 인지 단위(성분)에 정합한 시각 표현 — Pokemon Sleep 결의 친근함 강화
- ✅ Non-goals(TCA, Carousel, 단순 탭) 어느 항목도 추가하지 않음
- ✅ `IntakeLog` 비가역 행동 기록 모델 변경 없음
- ✅ ADR-0007 서버 SoT 결정으로 V1.0 출시 후 카테고리 hot update 가능 — 시드 16종은 첫 실행 default

## 주요 결정 박제 (시장조사 출처)

- **매출 상위 3대 카테고리**: 프로바이오틱스 / 비타민·미네랄 / 오메가3
- **구매율 1위**: 프로바이오틱스 25.2% (오픈서베이 2026)
- **글로벌 사용률 1위**: 비타민D 69.9% (USA, NIH ODS)
- **마그네슘 폭증 트렌드**: +33.6% YoY (Spate Google/TikTok 2025)
- **5060 관절 핵심**: 글루코사민·콘드로이친·MSM (필라이즈 BEST)
- **간 건강 cliché**: 밀크씨슬 (실리마린 130mg/일)
- **CoQ10**: 거의 100% softgel 형태 (지용성)
- **루테인**: 한국 BEST 마리골드+빌베리 합제 → 짙은 마호가니 색
- **iron biconvex**: ferrous fumarate cliché (사용자 사진 제공)

## 다음 (이 task 머지 후)

- **#18 (백엔드)**: 16 row를 SQLite `category` 시드 마이그레이션 + Fly static 16 PNG 업로드 + endpoint
- **#19 (모바일 동기화/UI)**: `category-seed.json` 첫 실행 import → `CategoryMirror` + 검색 UI
- **#14 (Today 정적 레이아웃)**: 봉지 띠에 16종 카테고리 이미지 일부 표시
- **V1.1+ 후순위 카테고리** (서버 hot update로 즉시 도입 가능):
  - 1순위: ashwagandha, biotin, melatonin (글로벌 트렌드)
  - 2순위: glutathione, redGinseng (홍삼, 작업지시자 결정으로 제외), 백수오 (갱년기), berberine
  - 3순위: 단백질·BCAA·후코이단·녹용·홍경천 (한방/헬스 카테고리 별도 컴포넌트)

## PR 본문 첨부 예정 링크

- 계획서: [`docs/plans/task_W2_17_impl.md`](../plans/task_W2_17_impl.md)
- 본 보고서: [`docs/report/task_W2_17_report.md`](task_W2_17_report.md)
- 시장조사 종합: [`docs/working/market-research-summary.md`](../working/market-research-summary.md)
- ADR-0007: [`docs/adr/0007-server-catalog-as-source-of-truth.md`](../adr/0007-server-catalog-as-source-of-truth.md)
- 시리즈 그리드: [`docs/screenshots/categories/grid-128pt.png`](../screenshots/categories/grid-128pt.png)
- 색 그룹 그리드: [`docs/screenshots/categories/grid-by-color.png`](../screenshots/categories/grid-by-color.png)
