# task_W1_27_impl.md — SoT 2층 분리 (identity.md 신설 + 정합) 구현계획서

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#27](https://github.com/kswift1/PillPouch/issues/27) |
| 마일스톤 | W1 |
| 크기 | M |
| 영역 | area:docs |
| 타입 | type:docs |
| 브랜치 | `kswift1/identity-doc` (origin/main에서 분기) |
| 예상 시간 | 2~3시간 |

## 목표

`docs/brief.md` 단일 SoT 운영을 **2층 SoT**로 분리:

- **`docs/identity.md`** (신설, v1.0) — 정체성. Why/What/Vision 3층. 앱 전 생애 유지, 거의 불변.
- **`docs/brief.md`** (기존 → v0.6) — V1 기획. 스코프/구현/일정. V1 한정, 진화.

작업지시자가 정체성 문서 v1.0 초안 제시(`.context/attachments/pasted_text_2026-05-03_20-12-43.txt`). 첨부 원문 자체적으로 *"One-pager v0.4와 분리하여 별도 문서로 운영 시작"* 명시. 본 PR은 그 분리를 실제 repo에 박제 + 두 문서 정합 보강 + 색인/변경 룰 갭 메움.

## 비목표

- ❌ **brief.md 본문 광범위 변경** — 정합 cross-link 1줄 + 가설 어휘 정련(괄호 제거 7글자) + 변경 로그 v0.6 + 메타 헤더만. 본문 의미 변경 X.
- ❌ **다른 ADR(0001~0009) 수정** — ADR-0010 신설만.
- ❌ **design-system.md / architecture.md / api.md / data-model.md** 수정 — 표면 layer 문서, 본 PR 스코프 밖.
- ❌ **PR 템플릿 변경** — 가설 B 체크박스는 그대로.
- ❌ **인프라 / 코드 변경** — docs only.
- ❌ **후속 결정 영역 본문 박제** — 비즈니스 모델 / PTS 제거 검토 / α-2 시작 가이드 / α-1 의료 추천은 보고서 §후속 검토 항목으로만 박제, 별도 Issue.

## 합의된 결정 (Step 1~12 인터랙티브 결정)

대화 중 13단계 결정 게이트로 합의된 사항:

### Step 1 — 한 줄 + 3층 구조
- 한 줄: 첨부 원문 그대로 *"영양제 트래킹/알람 앱. 단, 본질은 '먹었나 헷갈리지 않게' 만드는 것."*
- 3층 도식: 본질→표면→비전 세로, 첨부 원문 그대로
- 외부 질문 표: 4행, "5년 뒤 어디 갈 거야?" → "다음 버전엔 뭐가 추가돼?"로 부드럽게

### Step 2 — §본질 (Why)
- 페인포인트 / Pill Pouch의 답: 첨부 원문 그대로
- 핵심 가설: 첨부 원문 + brief 가설 cross-link 1줄
- **brief.md §핵심 가설 어휘 정련** — *"(찢긴 약봉지)"* 괄호 제거. 가설을 layer-agnostic으로 (단품 봉지 → 시각 증거 일반)

### Step 3 — §표면 (What)
- 핵심 기능 4번째: *"복용 기록 누적 (찢긴 봉지 띠 + 주간/월간 뷰)"* — 다층 누적 명시
- 시각 메타포 2번째: *"봉지의 절취선을 따라 찢어 약을 먹는 행위 시뮬레이션"* — "윗부분" / "중간 perforation" 위치 표현 회피, ADR-0009 / 코드 정합
- 카테고리: 첨부 원문 + *"카테고리 떠나기 X — 카테고리 안에서 본질을 다르게 정의"* 추가

### Step 4 — §비전 (V2+)
- 장기 방향: *"영양제 컴패니언으로 확장"* (원문 "헬스케어 도구" → 의료 톤 회피)
- 확장 영역: 5개 → 2개 축소 — *"영양제 조합 안전성"* + *"처방약·영양제 통합"*. 가족 공유 / HealthKit / 컨디션 상관관계 V2+에서도 제외.
- 삭제 항목 안내: 본문 1줄 + 변경 로그 둘 다 박제
- V1과 관계: 원문 + brief.md §검증 가능한 명제 cross-link

### Step 5 — §차별점 3가지
- 묶음: 원문 3개 그대로 (메타포 / 인터랙션 / 누적)
- #1 한국 약봉지 띠: 원문 그대로
- #2 가로 드래그 찢기: *"실제 약봉지의 절취선을 따라 찢는 행위"* 어휘 통일
- #3 누적 기록: *"여러 시간 단위(하루·주·월)로 신뢰성 있는 기록 시각화"* 추상화 강화

### Step 6 — §정서 / §약속 / §Anti-Promise
- 정서: 원문 그대로
- 약속 4종: 원문 그대로 (락스크린 자동 등장 약속 포함 — PTS 제거 검토는 후속)
- Anti-Promise §4: *"개인 맞춤 처방·자문을 하지 않는다 — 인구통계 일반 권장(연령대·성별별 표준 영양제 가이드)은 정보 제공이지 의료 자문이 아니다"* — α-1 (의료 추천) X / α-2 (인구통계 일반 권장) OK 정의 명시

### Step 7 — §슬로건 + §페르소나
- 슬로건: 메인 확정 *"오늘 먹었나? 헷갈리지 마세요."* + 대안 후보 3개 보존. 섹션명 "슬로건 후보" → "슬로건"
- 페르소나: 원문 그대로

### Step 8 — §사용 가이드 / §변경 정책 / §변경 로그 / 마지막 문장
- 사용 가이드: *"brief.md가 닻"* + cross-link
- 변경 정책: ADR 선행 룰 추가 + ADR-0010 cross-link
- 변경 로그 v1.0 (2026-05-03): 핵심 결정 요약 + 비전 축소 명시
- 마지막 문장: 원문 그대로

### Step 9 — brief.md 변경 (4건)
- "한 줄 컨셉" 직후 정체성 SoT 전체 cross-link 추가
- §핵심 가설 *"(찢긴 약봉지)"* 괄호 제거 (Step 2-D 합의)
- §변경 로그 v0.6 신설
- 메타 헤더 v0.4 → v0.6 + Major changes 갱신

### Step 10 — docs/README.md
- 핵심 문서 목록 최상단에 identity.md 추가, brief.md v0.4 → v0.6 표기 갱신
- 표기: *"정체성 v1.0 (앱 전 생애 SoT, 본질 변경 = 새 프로젝트)"* / *"V1 기획 v0.6 (변경은 PR + ADR 필수)"*
- 순서: identity → brief → architecture → data-model → api → design-system

### Step 11 — CLAUDE.md
- "기획서 변경 룰" → "SoT 변경 룰 (2층)" 확장. identity (4룰) + brief (4룰) 분리.
- 절대 금지 1줄 갱신: *"❌ SoT(identity.md, brief.md) 직접 수정"* + 강도 차이 괄호.
- 참고 cross-link 갱신: 정체성 + V1 기획 둘 다 추가.

### Step 12 — ADR-0010
- Status: `Accepted — 2026-05-03`
- Context: brief 단일 SoT 3가지 수명 혼재 갭 + 정체성 초안 분리 의도
- Decision: SoT 2층 분리 + 변경 룰 + 정합 보강 (가설 어휘 정련, cross-link, README, CLAUDE)
- Consequences: Positive / Negative / Neutral 3분류 + 후속 결정 영역 cross-link

## 구현 단계 (단일 PR 단위)

박제 순서:

1. **`docs/adr/0010-sot-identity-brief-two-layer.md` 신설** — ADR Step 12 합의안
2. **`docs/identity.md` 신설** — Step 1~8 합의 본문
3. **`docs/brief.md` 부분 수정 4건** — Step 9 합의안
4. **`docs/README.md` 부분 수정** — Step 10 합의안
5. **`CLAUDE.md` 부분 수정 2건** — Step 11 합의안 (SoT 변경 룰 확장 + 절대 금지 1줄)
6. **`docs/plans/task_W1_27_impl.md` 갱신** — 본 파일 (Step 합의 반영)
7. **`docs/report/task_W1_27_report.md` 신설** — Step 13 합의안

## 변경 파일 목록 (실제)

| 파일 | 변경 종류 | LOC 영향 |
|---|---|---|
| `docs/identity.md` | 신설 | +~210 |
| `docs/adr/0010-sot-identity-brief-two-layer.md` | 신설 | +~80 |
| `docs/brief.md` | 메타 헤더 / cross-link 1줄 / 가설 괄호 제거 / 변경 로그 v0.6 | +12, ~5 |
| `docs/README.md` | identity.md 추가 + brief.md v0.6 갱신 | +1, ~1 |
| `CLAUDE.md` | "기획서 변경 룰" → "SoT 변경 룰 (2층)" + 절대 금지 1줄 + 참고 cross-link | +~12, ~3 |
| `docs/plans/task_W1_27_impl.md` | 갱신 (본 파일, Step 합의 반영) | +~80 |
| `docs/report/task_W1_27_report.md` | 신설 | +~120 |
| **합계** | | **+~515 LOC, ~9 라인 수정** |

PR 사이즈 +500 LOC 근처. 분할 불필요.

## 검증

본 PR은 docs only이므로 자동 테스트 변경 X. 수동 검증:

- [ ] `docs/identity.md` 모든 cross-link이 실제 anchor / 파일과 일치
- [ ] `docs/brief.md` 추가된 cross-link이 identity.md anchor와 일치
- [ ] `docs/brief.md` 가설 본문이 layer-agnostic으로 정련됨 (단품 봉지 어휘 제거)
- [ ] `docs/README.md` identity.md / brief.md 링크 클릭 가능
- [ ] `CLAUDE.md` ADR-0010 링크가 실제 파일과 일치
- [ ] `git diff origin/main` 검토 — brief.md 본문 의도치 않은 변경 zero
- [ ] ADR-0010 보고서 cross-link이 실제 보고서 파일과 일치
- [ ] 모든 변경이 Step 1~12 합의와 1:1 일치

## 가설 검증 게이트

- [x] 가설 B 강화 — SoT 정렬로 시안 평가 시 "본질을 강화하는가?" 닻이 더 또렷
- [x] Non-goals 미해당 — 기존 Non-goals 유지, 비전은 축소만 (확장 X)

## 위험 / 롤백

- **위험 1.** identity.md anchor 깨짐 → 수동 검증으로 차단
- **위험 2.** brief.md cross-link이 본문 변경으로 오해될 가능성 → ADR-0010 §Decision §정합 보강에 *"단순 색인 보강"* 명시
- **롤백:** docs only PR이므로 revert 1회로 완전 복구. 영향 범위는 README/CLAUDE.md 텍스트만, 코드/CI/배포 무관.

## 후속 결정 영역 (별도 Issue + ADR)

본 PR 진행 중 발견된 후속 영역. 본 PR 머지 후 별도 Issue 등록:

1. **비즈니스 모델 결정** (광고 / 결제 / 무료 / Pro IAP / 제휴 커미션) — V1 출시 + 30일 도그푸딩 후 결정
2. **PTS / Live Activity / Remote Push 제거 검토** — 작업지시자 1차 의향 표명, 정식 결정은 후속. 백엔드는 유지.
3. **신규 사용자 시작 가이드 (α-2 인구통계 일반 권장)** — Anti-Promise §4 정밀화로 합법 확인됨. 박제 위치(§표면/§비전, V1/V2+) + 데이터 소스(식약처 KDRIs / 자체) 결정.
4. **의료 추천 (α-1) 카테고리 전환 검토** — 정체성 본질 변경 영역, 매우 신중.
5. **"middle perforation" 명명 정정** — 실제 봉지 세로의 ~30% 지점. ADR-0009 / brief.md 후속 수정.

## 승인 요청

본 구현계획서 + 박제된 파일 6개 + 보고서 검토 후 승인 ⛔.
