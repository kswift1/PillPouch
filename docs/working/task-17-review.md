# #17 카테고리 시드 자산 — 운동 후 리뷰 문서

작업지시자가 운동 후 5분 안에 파악 가능하도록 정리. **2026-04-28 운동 시간 동안 Claude 작업 결과 요약**.

## 핵심 결정 변경 (한국 시장 조사 후)

**12종 → 17종 확장**. 이유:
- 한국 시장 조사 결과 핵심 카테고리 누락 다수 발견
- V1.1 SKU 카탈로그 도입 시 카테고리 facet으로 살아남으므로 V1.0에서 시드 충실하게 박는 게 경제적

### 주요 변경

| 변경 | 사유 |
|---|---|
| **calciumMagnesium 분리** → calcium + magnesium | 한국 시장 단독 마그네슘 / 단독 칼슘 둘 다 매우 흔함, 사용자 인지도 단독 |
| **redGinseng 신규** ⭐ | 한국 시장 단일 카테고리 30% 점유, 정관장 70% — 빠지면 한국 사용자 90%+의 등록 경험 누락 |
| **milkThistle 신규** | 간 건강 카테고리 핵심 (실리마린), 사용자 명확 인지 |
| **glucosamine 신규** | 관절 5060 시장 핵심, 5060 재구매율 1위 카테고리 |
| **coq10 신규** | 항산화/에너지, 30~40대 직장인 인기 |

### V1.1 후순위 (시장조사 후 의도적 제외)

- biotin: vitaminD/multivitamin과 색 충돌 + collagen으로 모발 건강 어느 정도 커버
- BCAA/단백질: 분말 형태 다수, 정제/캡슐 픽토그램 부적합 → V1.1 헬스 카테고리 별도
- 후코이단/녹용: 시장 점유 낮음

## 17종 최종

| # | key | 한글 | 형태 | 색 | 식별 핵심 | 도착 |
|---|---|---|---|---|---|---|
| 1 | omega3 | 오메가-3 | 글로시 oval softgel | 골든 앰버 | 글로시 + 따뜻한 amber | ✅ |
| 2 | probiotics | 유산균 | 작은 캡슐 | 파스텔 핑크 | 캡슐 형태 + 작음 | ⏳ |
| 3 | vitaminC | 비타민 C | matte oblong | 옅은 노랑 | 세로 score | ✅ |
| 4 | multivitamin | 종합 비타민 | 큰 oval | tan | 표면 점박이 | ✅ |
| 5 | redGinseng ⭐ | 홍삼 | round disc | 짙은 마호가니 | 진한 적갈색 | ⏳ |
| 6 | vitaminD | 비타민 D | 작은 round disc | 머스타드 노랑 | 작은 사이즈 | ✅ |
| 7 | vitaminB | 비타민 B | matte oblong | 핑크 레드 | 세로 score | ✅ |
| 8 | milkThistle | 밀크씨슬 | 캡슐 | 올리브 황녹 | 단색 캡슐 | ⏳ |
| 9 | glucosamine | 글루코사민 | 큰 matte oblong | 라이트 베이지 | 가로 score | ⏳ |
| 10 | lutein | 루테인 | semi-gloss oval softgel | 골든 머스타드 | 살짝 글로시 | ⏳ |
| 11 | collagen | 콜라겐 | semi-gloss oval softgel | 핑크 베이지 | 핑크 톤 softgel | ⏳ |
| 12 | magnesium | 마그네슘 | round disc | 쿨 슬레이트 | 차가운 회청색 | ⏳ |
| 13 | calcium | 칼슘 | 큰 두툼 oval | 화이트 크림 | 가장 큼 + 두툼 | ⏳ |
| 14 | iron | 철분 | round disc | 다크 그레이-갈색 | 가장 어두움 | ⏳ |
| 15 | zinc | 아연 | round disc | 라이트 taupe | 라이트 그레이-베이지 | ⏳ |
| 16 | coq10 | 코엔자임 Q10 | 글로시 oval softgel | 진한 코랄 | 글로시 + 코랄 | ⏳ |
| 17 | other | 기타 | round disc | 베이지 (v4) | 시드 외 폴백 | ✅ |

**현재 도착**: 6장 / **남은 작업**: 11장

## 변경된 파일 (Claude 작업)

| 파일 | 변경 내용 |
|---|---|
| `docs/plans/task_W2_17_impl.md` | 12 → 17종 확장 + 시장조사 기반 결정 박제 + 17개 프롬프트 + 시각 변별 시스템 재정립 |
| `docs/adr/0007-server-catalog-as-source-of-truth.md` | 12 → 17종 확장 amendment 박제 |
| `scripts/category-spec.json` | 12 → 17 row, `_form` 필드 추가 (재질/형태 그룹 명시) |
| `scripts/imageset-categories.sh` | 17종 인자 + 주석 갱신 |
| `ios/PillPouch/Resources/category-seed.json` | 12 → 17 row, displayOrder 시장 점유율 기반 재정렬 |
| `docs/working/category-prompts.md` (NEW) | 11개 신규 프롬프트 박제 (운동 후 작업지시자가 바로 사용) |
| `docs/working/task-17-review.md` (NEW) | 본 문서 |

`design/categories/raw/`, `ios/PillPouch/Assets.xcassets/Categories/` 폴더는 변경 없음 — 작업지시자가 11장 도착시킨 후 Claude가 일괄 변환.

## 시각 변별 시스템 (재정립)

### 4 변별 축

1. **형태**: round disc / oval-oblong tablet / softgel / capsule (4 그룹)
2. **재질**: strict matte / semi-gloss / glossy translucent (3 그룹)
3. **색**: 노랑-오렌지 / 레드-핑크 / 베이지-탠 / 다크 갈색-녹 / 그레이-메탈 (5 그룹)
4. **표면 detail**: 세로 score (vitaminC/B) / 가로 score (glucosamine) / 점박이 (multivitamin) / 매끈 (그 외)

같은 색 그룹 내에선 형태·재질·표면이 모두 변별 보강.

### 32pt 변별 위험 페어 + 완화

| 위험 페어 | 위험 | 완화 |
|---|---|---|
| omega3 vs coq10 | 둘 다 글로시 oval softgel + 따뜻한 톤 | 색 톤 차 (omega3 노랑끼 amber, coq10 빨강끼 코랄) |
| redGinseng vs iron | 둘 다 어두운 톤 | 채도/명도 (redGinseng 따뜻 적갈, iron 차가운 다크그레이) |
| calcium vs glucosamine | 둘 다 옅은 베이지 | 형태 (calcium 두툼, glucosamine 일반 + 가로 score) |
| probiotics vs collagen | 둘 다 핑크 | 형태 (probiotics 캡슐, collagen oval softgel) + 사이즈 |
| milkThistle vs redGinseng | 둘 다 어두운 갈색 | 색조 (milkThistle 녹 끼, redGinseng 적 끼) + 형태 (milkThistle 캡슐, redGinseng disc) |
| magnesium vs zinc vs iron | 그레이 3종 | 색 톤 (magnesium 쿨슬레이트, zinc 따뜻 taupe, iron 다크 갈색-그레이) |

## 운동 후 작업지시자 작업 순서

### Step 1: 11장 raw PNG 생성 (1~2시간)

`docs/working/category-prompts.md` 열어서 권장 순서대로:

1. **redGinseng** ⭐ (시장 30%, 가장 distinctive)
2. **probiotics** (구매율 1위)
3. **calcium** (사이즈 baseline)
4. **glucosamine** (가로 score 첫 시도)
5. **coq10** (omega3 변별 검증)
6. **lutein** (omega3 재질 변별)
7. **collagen** (probiotics 핑크 변별)
8. **iron** (다크 baseline)
9. **milkThistle** (iron 갈색 변별)
10. **magnesium** (그레이 분리)
11. **zinc** (그레이 그룹 마지막)

각 4~8장 → best 1장 → `design/categories/raw/{key}.png`로 저장.

ChatGPT에 첨부할 reference 이미지: `design/categories/raw/other.png` (v4 매트 베이지 정제).

### Step 2: 도착 알림 (Claude에게)

11장 모두 저장하시고 "11장 다 받음" 또는 "calcium만 받음" 등 알려주시면 Claude가 `./scripts/imageset-categories.sh` 실행해서 imageset 일괄 생성.

### Step 3: 시리즈 일관성 검증 (작업지시자)

**자동 그리드 생성 스크립트 사용**:

```bash
./scripts/preview-categories.sh
# → docs/screenshots/categories/ 안에 5개 그리드 자동 생성:
#    - grid-32pt.png (변별 검증)
#    - grid-64pt.png
#    - grid-96pt.png
#    - grid-128pt.png (시리즈 일관성 검증)
#    - grid-by-color.png (색 그룹별 분리)
```

각 PNG는 PPColor.background(#FAF7F2) 위에 합성됨 — 봉지/Today 화면 실제 배경에서 어떻게 보이는지 시각 검증 가능.

**검증 체크**:
- `grid-128pt.png`: 17장 톤·카메라·shadow 일관성
- `grid-32pt.png`: 32pt 작은 사이즈에서 카테고리 식별성
- `grid-by-color.png`: 같은 색 그룹 내 카테고리 변별

어긋난 1~2종만 재생성 후 스크립트 재실행으로 즉시 비교.

### Step 4: PR ready 전환 + 머지

- 빌드 ✅ 확인
- 보고서 작성 (Claude)
- Draft → Ready
- squash merge

## 잠재 결정 항목 (작업지시자 판단)

운동 후 결정하실 만한 것:

1. **17종이 너무 많다 → 줄이기**
   - 가장 약한 카테고리: zinc (구매율 데이터 없음, iron과 비슷)
   - 줄인다면 zinc 빼고 16종도 가능
2. **17종에 빠진 것 추가**
   - biotin (모발) — collagen과 구별 약함, 권장 안 함
   - 단백질/BCAA — 분말 형태 부적합, V1.1 권장
   - 후코이단/녹용/홍경천 — 시장 점유 낮음, V1.1 권장
3. **변별 시스템 — score line 방향이 헷갈리는지**
   - vitaminC: 세로
   - vitaminB: 세로
   - glucosamine: 가로
   - 직관 검증 후 변경 가능

## 시장조사 출처 (Claude 검색)

- [HealthU — 2026 한국 건강기능식품 시장](https://healthu.kr/health-functional-food-market-size-trend-2026/)
- [오픈서베이 트렌드 리포트](https://blog.opensurvey.co.kr/trendreport/health-supplement-2026/)
- [한국건강기능식품협회](https://www.khff.or.kr/)
- [필라이즈 인기 영양제 BEST10 (2026)](https://www.pillyze.com/ranking/gender-age)
- [정관장 시장 점유율 70%](https://www.hankookilbo.com/News/Read/A2021060116160004668)
- [건강기능식품 약사공론](https://www.kpanews.co.kr/article/show.asp?category=B&idx=246807)

## 빌드 검증 (이번 세션 끝에서)

이미지 변경 없으므로 빌드는 영향 없을 예정. 다만 category-seed.json은 ios/PillPouch/Resources/ 안에 있어 번들 포함됨. 빌드 통과 검증 마지막에 실행.

## 결론 한 줄

**작업지시자 운동 시간 동안 Claude가 시장조사 + 17종 확장 + 11개 프롬프트 정제 + 시각 변별 시스템 재정립 + 모든 인프라 문서 갱신 완료**. 운동 후엔 `docs/working/category-prompts.md` 보고 11장 raw 생성만 하시면 17종 시드 완성.
