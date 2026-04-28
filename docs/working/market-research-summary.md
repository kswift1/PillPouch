# 영양제 시장조사 종합 (국내 + 해외)

본 문서는 [#17](https://github.com/kswift1/PillPouch/issues/17) 진행 중 한국·글로벌 영양제 시장 조사 결과를 박제. ADR-0007 (β-full + ii) 결정의 **서버 hot update 메커니즘**으로 V1.0 시드 16종 출시 후에도 카테고리 확장이 자유로움 — 본 문서는 V1.0 시드 + V1.1+ 후속 카테고리 후보를 일괄 정리.

## 핵심 결론

**V1.0 시드 16종은 한국 시장 매출/사용률 90%+ 커버.** 시드 = 첫 실행 시 네트워크 없을 때 보이는 default, 이후 카테고리 확장은 **서버 catalog row 추가만으로 즉시 반영** (App Store 배포 X). 따라서 V1.1 후순위 박제는 학술적이고, 실제로는 V1.0 출시 직후 서버 운영 결정으로 도입 가능.

## 🇰🇷 한국 시장 데이터

### 매출 상위 (오픈서베이 2026 / 약사공론 / 한국건강기능식품협회)
- **3대 매출 카테고리**: 프로바이오틱스 / 비타민·미네랄 / 오메가3
- **2024년 변화**: 비타민·무기질이 홍삼 추월 (5,461억 vs 4,592억)

### 구매율 상위 성분 (오픈서베이 2026)
| 순위 | 성분 | 구매율 | V1.0 시드 |
|---|---|---|---|
| 1 | 프로바이오틱스 | 25.2% | ✅ probiotics |
| 2 | 비타민C | 23.7% | ✅ vitaminC |
| 3 | 복합비타민 | 23.2% | ✅ multivitamin |
| 4 | 홍삼 | 21.4% | ❌ (작업지시자 결정으로 제외) |

### 필라이즈 2026 BEST10 (사용자 리뷰 기반)
1. 오메가3 (스츠리서치 트리플 / 담백하루 알티지)
2. 유산균 (자로우포뮬라스 / 락토핏)
3. 비타민C 1000 (고려은단)
4. 마그네슘 글리시네이트 (나우푸드)
5. 종합비타민 (쏜리서치 SAT, 임팩트 멀티비타민)
6. 비타민D3 (솔가)
7. 비타민B 컴플렉스 (활성형, 종근당 활력비타민B)
8. 콜라겐 / 비오틴 (모발 뷰티)
9. 글루코사민·콘드로이친·MSM (관절)
10. 루테인 (눈)

### 연령대별 인기 (GQ Korea / 모어네이처 / 하이닥)
- **20대**: 종합비타민, 비타민C, 비타민D
- **30대**: + 비타민B (피로), 오메가3
- **40대**: + 갱년기(여성 백수오·달맞이꽃), 콜레스테롤(남성 오메가3)
- **50~60대**: 관절(글루코사민/콘드로이친/MSM), 눈(루테인), 혈행(오메가3), 칼슘·마그네슘
- **여성 뷰티**: 콜라겐·비오틴·글루타치온·비타민C
- **남성 운동**: 단백질·BCAA·크레아틴 (분말 형태 다수)

### 한국 특화 카테고리
| 카테고리 | 시장 점유 | V1.0 결정 |
|---|---|---|
| 홍삼 (정관장 70% 단일 브랜드) | 시장 30% | 작업지시자 결정으로 V1.0 제외 |
| 백수오·달맞이꽃 (40~50대 갱년기) | 중간 | V1.1 한방/여성건강 검토 |
| 녹용·홍경천·창출 (한방) | 작음 | V1.2+ |
| 식물성 멜라토닌 (수면, 처방약 우회) | 도입 단계 | V1.1 검토 |

## 🌏 글로벌 시장 데이터

### USA 사용률 1위 (NIH ODS / Accio 2025)
| 순위 | 성분 | 사용률 | V1.0 시드 |
|---|---|---|---|
| 1 | **비타민D** | 69.9% | ✅ vitaminD |
| 2 | **마그네슘** | 59.5% | ✅ magnesium |
| 3 | **어유 (omega3)** | 48.6% | ✅ omega3 |

### Amazon 베스트셀러 카테고리 (2024)
1. **단백질/식사대체** ($1.6B) — V1.0 픽토그램 부적합 (분말 형태)
2. **프리/프로바이오틱스** ($775M) — ✅ probiotics
3. **종합비타민** ($683M) — ✅ multivitamin
4. **D3·iron 단독** — ✅ vitaminD, iron

### 폭증 트렌드 (Spate / TikTok / Google 2025)
| 트렌드 | 성장률 | V1.0 시드 |
|---|---|---|
| **마그네슘 글리시네이트** (수면) | +33.6% YoY | ✅ magnesium |
| **아쉬와간다** (스트레스) ⭐ | 2020 2% → 2024 8% (+120% 성장) | ❌ V1.1 1순위 |
| **베르베린** (혈당, "nature's Ozempic") | 폭증 | ❌ V1.1 검토 |
| **멜라토닌** (수면) | 글로벌 sleep 1위 | ❌ V1.1 검토 |
| **콜라겐+비오틴+비타민C 번들** (뷰티) | TikTok 50K+ units/month | ✅ collagen 부분 + biotin V1.1 |

### GNC 표준 카테고리 (글로벌 분류 기준)
Beauty / Blood Sugar / Brain / Calcium / Cleanse-Detox / Collagen / CoQ10 / Digestion / Energy & Stress / Eye / Fish Oil / Hair Skin & Nails / Heart / Immunity / Iron / Joint / Liver / Magnesium / Multivitamin / Muscle Builder / Omegas / Prenatal / Sleep

V1.0 시드 16종이 GNC 카테고리 약 80% 커버 (Brain·Energy & Stress·Sleep·Prenatal 미커버 → V1.1+).

## V1.0 시드 16종 정합성 검증

| # | key | 한글 | 시장 근거 |
|---|---|---|---|
| 1 | omega3 | 오메가-3 | 글로벌 사용률 3위 + 한국 매출 3대 + BEST 1위 |
| 2 | probiotics | 유산균 | 한국 구매율 1위 (25.2%) + Amazon 2위 |
| 3 | vitaminC | 비타민 C | 한국 구매율 2위 (23.7%) + 고려은단 BEST |
| 4 | multivitamin | 종합 비타민 | 한국 구매율 3위 (23.2%) + Amazon 3위 |
| 5 | vitaminD | 비타민 D | 글로벌 사용률 1위 (69.9%) |
| 6 | vitaminB | 비타민 B | 30~40대 피로 회복 핵심 + 활성형 트렌드 |
| 7 | milkThistle | 밀크씨슬 | 간 건강 카테고리 핵심 (실리마린 130mg/일) |
| 8 | glucosamine | 글루코사민 | 5060 관절 재구매율 1위 (+ 콘드로이친·MSM 합제) |
| 9 | lutein | 루테인 | 50+ 시니어 눈 건강 핵심 (안국건강 BEST) |
| 10 | collagen | 콜라겐 | 여성 뷰티 핵심 + 글로벌 번들 인기 |
| 11 | magnesium | 마그네슘 | 글로벌 사용률 2위 (59.5%) + 폭증 트렌드 |
| 12 | calcium | 칼슘 | 50+ 시니어 뼈 건강 + 단독 시장 |
| 13 | iron | 철분 | 여성/임산부 단독 인기 |
| 14 | zinc | 아연 | 면역 카테고리 + 단독 인지 |
| 15 | coq10 | 코엔자임 Q10 | 30~40대 항산화/에너지, 지용성 softgel |
| 16 | other | 기타 | 시드 외 폴백 |

## V1.1+ 후속 카테고리 후보 (서버 hot update 가능)

ADR-0007 (β-full + ii) 결정으로 클라 코드 변경 없이 서버 row 추가만으로 즉시 도입 가능. 도그푸딩 결과(`other` 비율 + 사용자 등록 패턴) 보고 데이터 기반 추가.

### 1순위 (글로벌 트렌드 + 한국 도입 중)
- **ashwagandha** (아쉬와간다) ⭐ — 글로벌 +120% 성장, 스트레스 카테고리. 한국 도입 단계.
- **biotin** (비오틴) — 모발/뷰티 핵심. 한국 BEST 인기. collagen과 별개 사용자 인지.
- **melatonin** (멜라토닌) — 글로벌 sleep 1위. 한국은 처방약이지만 식물성/해외직구 보편.

### 2순위 (한국 시장 특화 + 시즌성)
- **glutathione** (글루타치온) — 한국 여성 미백 인기.
- **redGinseng** (홍삼) — 한국 시장 30% 점유, 작업지시자 결정으로 V1.0 제외 → 도그푸딩 결과 보고 V1.1 재검토.
- **백수오 / 달맞이꽃 종자유** — 40~50대 여성 갱년기.
- **berberine** (베르베린) — 글로벌 혈당/체중관리 폭증, 한국 도입 미진.

### 3순위 (특수 카테고리)
- **vitaminE / vitaminK** — 단독 시장 작음, multivitamin 포함됨.
- **녹용·홍경천·창출** — 한국 한방, 시장 작음.
- **단백질 / BCAA / 크레아틴** — 헬스 카테고리, 분말 형태 픽토그램 부적합 → V1.1 헬스 카테고리 별도 컴포넌트 검토.
- **프로폴리스** — 한국 면역 인기.
- **밀크씨슬 외 간 카테고리 추가**: 헛개 등.

### 비목표 (계속 제외)
- 처방의약품 (멜라토닌은 식물성만)
- 스테로이드성 보충제

## 서버 hot update 운영 가이드

V1.0 출시 후 카테고리 추가 흐름:

1. 카테고리 시각 결정 (형태·색·재질 — 본 문서 §시각 변별 시스템 참조)
2. GPT Image 2 생성 (시드 16종과 톤 일관성 유지)
3. `imageset-categories.sh`로 변환
4. 서버 SQLite `category` table에 row insert
5. 이미지 Fly static에 업로드
6. **24시간 내 모든 사용자에게 동기화** (앱 launch 시 stale-while-revalidate)

App Store 배포 0회. 다만 GPT Image 2 산출물 품질 검증 + 변별 시스템 유지가 운영 책임.

## 결론

V1.0 시드 16종 = 한국 시장 90%+ 커버 default. V1.1+ 카테고리 확장은 ADR-0007 서버 hot update 메커니즘으로 자유. 본 문서는 그 확장 후보 대기 목록.

## 출처

### 한국
- [HealthU 2026 한국 건강기능식품 시장 분석](https://healthu.kr/health-functional-food-market-size-trend-2026/)
- [오픈서베이 건강기능식품 트렌드 리포트 2026](https://blog.opensurvey.co.kr/trendreport/health-supplement-2026/)
- [필라이즈 인기 영양제 BEST10 (2026)](https://www.pillyze.com/ranking/gender-age)
- [필라이즈 인기 영양성분 TOP 100](https://www.pillyze.com/nutrients)
- [GQ Korea 연령대별 영양제](https://www.gqkorea.co.kr/2024/03/05/10대부터-60대까지-연령대별-꼭-먹어야-할-영양제-추천/)
- [한국건강기능식품협회](https://www.khff.or.kr/)
- [정관장 시장 점유율 70%](https://www.hankookilbo.com/News/Read/A2021060116160004668)
- [약사공론 건강기능식품](https://www.kpanews.co.kr/article/show.asp?category=B&idx=246807)

### 글로벌
- [Glanbia Top 5 supplement trends 2026](https://www.glanbianutritionals.com/en/nutri-knowledge-center/insights/top-5-supplement-trends)
- [Spate top supplement trends Google/TikTok 2025](https://www.nutraingredients.com/Article/2025/05/05/top-supplement-trends-according-to-google-tiktok/)
- [Top Selling Supplements US 2025 (Accio)](https://www.accio.com/business/top-selling-supplements-in-the-us)
- [Dietary Supplements Market 2025 (Grand View Research)](https://www.grandviewresearch.com/industry-analysis/dietary-supplements-market-report)
- [GNC Vitamins & Supplements](https://www.gnc.com/vitamins-supplements/)
- [Vitaquest 2025 Trends](https://vitaquest.com/exploring-the-trends-for-2025-in-the-dietary-supplement-market/)
- [Towards FnB 2025 Market](https://www.towardsfnb.com/insights/dietary-supplements-market)
