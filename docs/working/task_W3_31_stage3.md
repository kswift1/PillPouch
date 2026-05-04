# task_W3_31_stage3.md — Stage 3 seed 검수 + 깊은 WebSearch 정정

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#31](https://github.com/kswift1/PillPouch/issues/31) |
| Stage | 3 / 5 |
| 완료 | 2026-05-04 |
| 영역 | server/seed (작업지시자 검수 결과 + 깊은 WebSearch 재추출) |

## 결과 요약

작업지시자 발언 *"이건 웹서치 해서 나온 결과야?"* 계기로 Stage 1 결과의 정확도 검증 + 깊은 WebSearch 재추출. 식약처 출처 / 권장량 명시 강화 (작업지시자 결정 (γ) "WebSearch 다시 돌림 — 카테고리별 더 깊게").

## 검증된 정정 사항 (5건)

| # | 항목 | Before (Stage 1) | After (Stage 3) | 출처 |
|---|---|---|---|---|
| 1 | 코엔자임Q10 권장량 | 100~200mg | **90~100mg (식약처 건강기능식품 인정 일일섭취량)** | 식약처 건강기능식품 항산화/혈압 기능성 인정 |
| 2 | 대두 이소플라본 권장량 | (명시 X) | **40~50mg/일** | 식약처 건강기능식품 기능성 (재평가 중) |
| 3 | 임산부 DHA | 200mg+ | **200~300mg/일** | 한국영양학회 KDRIs 2020 임산부 권장 |
| 4 | 비타민 D | (명시 X) | **충분섭취량 400IU/일, 상한 4,000IU** | 한국영양학회 KDRIs 2020 / 코메디 |
| 5 | 칼슘 (40~60대 여성) | (명시 X) | **권장섭취량 800mg/일 (50+)** | 한국영양학회 KDRIs 2020 |

## 추가 출처 명시

각 카테고리 source 필드 강화:

- 한국영양학회 / 보건복지부 **KDRIs 2020** (공식 한국인 영양소 섭취기준)
- **식약처 건강기능식품 일일섭취량 인정 기준** (코엔자임Q10, 이소플라본 등)
- **식약처 임산부 5대 필수 영양소 (2021)** — 보도자료 출처 확정
- **질병관리청 국가건강정보포털**
- 서울아산병원 / 삼성서울병원 / 약사공론 (의료기관 / 약사 단체)

## disclaimer 강화

40~60대 남성 카테고리에 추가:
> *"특히 코엔자임Q10은 항응고제와 상호작용 가능."*

40~60대 여성 카테고리에 추가:
> *"이소플라본은 식약처 재평가 중이라 향후 권장량 변경 가능."*

## 미해결 사항 (한계)

### 1. 식약처 PDF 직접 fetch 실패

`https://www.mfds.go.kr/brd/m_74/down.do?...&seq=44891` (코엔자임Q10) / `health.seoulmc.or.kr/...2025_한국인영양소섭취기준_활용.pdf` 두 PDF는 binary 데이터로 WebFetch가 텍스트 추출 못 함. PDF 직접 파싱은 본 PR 스코프 밖.

→ 권장량 수치는 보조 출처 (필라이즈 / 마이영양제 / 코메디 / 약사공론 등)에서 인용된 식약처 / 한국영양학회 기준을 채택. 원문 PDF 검수는 V1 출시 전 별도 spot check 권장.

### 2. KDRIs 2025 갱신 미반영

검색 결과 *"2025 한국인 영양소 섭취기준"*이 발간됨이 확인되나 PDF 직접 추출 실패. 2026-05 기준 KDRIs 2020 인용. KDRIs 2025로 갱신은 V1 출시 후 또는 후속 PR.

### 3. 식약처 임산부 5대 영양소 보도자료 직접 링크 미확보

학술 논문(대한모성건강학회지 2022) 및 다수 의료 매체에서 *"식약처가 2021년 임산부 5대 필수 영양소 발표"* 인용 일치 → 출처로 확정. 식약처 원본 보도자료 URL은 추후 검수 시 추가.

## 검증

### JSON 형식
```
$ python3 -c "import json; d = json.load(open('server/seed/recommendations.json')); print(f'OK — {len(d)} categories, {sum(len(c[\"supplements\"]) for c in d)} supplements total')"
OK — 5 categories, 29 supplements total
```

### 런타임 검증 (Stage 2 환경 재실행)
```
$ DATABASE_URL=sqlite::memory: cargo run --bin pillpouch-api &
INFO: seeded 5 recommendations from server/seed/recommendations.json
INFO: listening on 127.0.0.1:18081

$ curl /v1/recommendations/male_40s_60s
{"category":"male_40s_60s",
 "display_name":"40~60대 남성",
 "supplements":[
   {"name":"코엔자임Q10 (식약처 인정 90~100mg/일)", "priority":1, ...},
   ...
 ],
 "source":"한국영양학회 KDRIs 2020 / 식약처 건강기능식품 일일섭취량 인정 기준 (코엔자임Q10) / 서울아산병원 (2026-05-04 추출)",
 "disclaimer":"인구통계 기반 일반 정보. 개인 진단·처방 X. 만성질환·복약 중인 경우 의사·약사 상담 권장 (특히 코엔자임Q10은 항응고제와 상호작용 가능)."}
```

### `cargo test --workspace`
변경 없음 (코드 변경 X, seed JSON만 변경) → Stage 2 9건 그대로 통과.

## 변경 파일

| 파일 | 변경 |
|---|---|
| `server/seed/recommendations.json` | 5 카테고리 권장량/출처/disclaimer 정정 (~73 → ~77 LOC) |
| `docs/working/task_W3_31_stage3.md` | 신설 (본 파일) |

## 가설 검증 게이트

- [x] Anti-Promise §1·§2·§4 정합 — 권장량 수치는 인구통계 기반 식약처/한국영양학회 평균 권장, 개인 진단 X
- [x] Anti-Promise §5 정합 — 사용자 데이터 외부 송신 0
- [x] Identity §본질 / §차별점 / §정서 변경 X
- [x] 출처 명시 강화 — disclaimer 내 의사·약사 상담 권장 추가 (40+ / 임산부)

## Stage 3 추가 — 영양제별 상세 설명 4필드 박제

작업지시자 결정 *"이거 설명도 추후에 같이 표시 / 지금하자"* 계기로 영양제별 상세 설명을 V1.x → V1으로 당겨 본 PR 안에 통합.

### 데이터 모델 확장

`Supplement`에 optional 필드 4개 추가 (후방 호환):

```rust
pub struct Supplement {
    pub name: String,
    pub reason: String,
    pub priority: u8,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub dosage: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub timing: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub side_effects: Option<String>,
}
```

`source_url`은 본 PR 제외 (식약처 PDF URL이 영양제별 분산되어 추적 부담 큼). 카테고리 단위 `source` 필드로 충분.

### 도메인 테스트 추가 3건

- `확장_필드가_None인_supplement_직렬화_시_optional_필드는_생략된다` — `skip_serializing_if` 검증
- `확장_필드가_없는_legacy_json도_default로_역직렬화된다` — 후방 호환 검증
- `확장_필드가_채워진_supplement_왕복으로_의미가_보존된다` — full round-trip

### WebSearch 5 카테고리 병렬 추출

각 카테고리별 영양제 복용시기 / 부작용 / 권장량 / 주의사항 깊은 정보 추출. 출처:
- 하이닥 / 코메디 / 필라이즈 (대중 매체)
- 한국영양학회 KDRIs / 식약처 (공식)
- MSD 매뉴얼 / 서울아산병원 / 삼성서울병원 (의료기관)
- 약사공론 / 굿대디 / 위기브 / 메디셜 (전문 / 임산부)

### seed 갱신 — 116 optional fields 박제

```
$ python3 ... -c "..."
OK — 5 categories, 29 supplements, 116 optional fields filled (target: 116)
```

29 영양제 × 4 필드 = 116. 모두 채움 (None X).

### Anti-Promise §2 정합 (side_effects)

각 카테고리 disclaimer에 명시 추가:
> *"부작용·복용시기는 일반적 안내 — 개인 체질·증상에 따라 다를 수 있음. 만성질환·복약 중인 경우 의사·약사 상담 권장."*

40~60대 남성 disclaimer 강화:
> *"특히 항응고제(와파린·아스피린) 복용 중이면 코엔자임Q10·오메가3·비타민E 복용 전 의사 상담 필수."*

40~60대 여성 disclaimer 강화:
> *"호르몬 민감 질환(유방암·자궁근종 등) 병력자는 이소플라본 복용 전 의사 상담 필수."*

임산부 disclaimer 강화:
> *"임신 주수·체질·기존 질환에 따라 다를 수 있음 — 산부인과 의사·약사 상담 필수."*

### 검증

- `cargo fmt` ✅
- `cargo clippy --workspace --all-targets -- -D warnings` ✅
- `cargo test --workspace` ✅ (domain 6 tests + storage 5 tests + placeholders)
- 런타임 smoke test ✅:
  ```
  $ curl /v1/recommendations/male_40s_60s
  name: 코엔자임Q10 (식약처 인정 90~100mg/일)
  description: 미토콘드리아 에너지 생성·항산화의 핵심. 20대부터 감소, 40대 70% 수준. 심혈관·체력·노화 보완.
  dosage: 90~100mg/일 (식약처 인정 일일섭취량). 유비퀴놀 형태 흡수율 ↑.
  timing: 아침 식후 (지용성, 흡수율 ↑)
  side_effects: 복통·설사·메스꺼움·두통·불면 가능. 와파린 효과 감소 — 항응고제 복용자 의사 상담 필수.
  ```

## Stage 3 승인 게이트 ⛔

작업지시자 검수 항목:
1. 정정 5건 (코엔자임Q10 / 이소플라본 / DHA / 비타민D / 칼슘 권장량) 정확도 OK?
2. 출처 표기 강화 OK? (한국영양학회 KDRIs 2020 / 식약처 / 질병관리청 등)
3. disclaimer 강화 OK? (40+ / 임산부 의사 상담 권장 / 코엔자임Q10 약물 상호작용)
4. **영양제별 4필드 (description / dosage / timing / side_effects) 박제 OK?**
5. **side_effects Anti-Promise §2 정합 disclaimer 강화 OK?**
6. KDRIs 2025 갱신 / 식약처 PDF 원본 spot check / source_url 매핑은 후속 PR로 미룸 OK?

승인 후 **Stage 4 (Identity §표면 §핵심 기능 박제 + brief.md cross-link)** 진입.
