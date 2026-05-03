# task_W1_14_impl.md — Today 정적 레이아웃 (헤더 + 봉지 띠 + 쌓인 증거 placeholder)

> **SUPERSEDED (2026-04-29)** — 작업 시작 전 스코프 재정의됨. #14 close → 새 이슈 [#25](https://github.com/kswift1/PillPouch/issues/25)("[L] 단일 봉지 컴포넌트 — 글라싱지 재현 + 중력 알약 + 찢기 인터랙션")로 분리. 본 파일은 의사결정 흔적용으로만 유지. 새 계획서는 `task_W2_25.md` (수행) + `task_W2_25_impl.md` (구현).

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#14](https://github.com/kswift1/PillPouch/issues/14) |
| 마일스톤 | W1 |
| 크기 | M |
| 영역 | area:ios |
| 브랜치 | `kswift1/task14-today-static` |
| 예상 시간 | 4~6시간 |

## 목표

W1 마지막 deliverable. 봉지 찢기 인터랙션(W2 L) / Live Activity(W2) / 캡슐 자산(#11) 들어가기 전에 **정적 레이아웃 베이스**를 세움.
후속 W2 가로 드래그 작업이 시각 위에서 바로 시작 가능하도록 슬롯/봉지 자리·시간대 색조·"쌓인 증거" 영역을 선 구축.

**가설 B 정합성**: 정적 레이아웃은 인프라 — 가설 B 직접 강화 X. 다만 (a) 모든 슬롯이 한 화면에 보임(Carousel X), (b) "쌓인 증거" 영역이 본질, (c) 알람 시계/체크 마크 회피를 코드 레벨에서 박제 → 후속 작업의 가드레일.

## 범위

### 화면 (`docs/brief.md` §화면 구조)

1. **헤더** — 날짜 + "오늘" + 우상단 진행도 도트 7개(정적 mockup) + 톱니 아이콘(액션 X)
2. **세로 약봉지 띠** — 아침/점심/저녁 봉지 3개, 절취선으로 연결. 봉지는 Sealed 상태 placeholder Shape만(W2 봉지 컴포넌트로 교체)
3. **"쌓인 증거" placeholder** — "이번 주 N개" 카피 + 어제·그제 자리 표시(실 데이터 X)
4. **하단 탭바 3탭** — 오늘 / 기록 / 영양제. Tab 전환만 가능, 기록·영양제 콘텐츠는 placeholder
5. **설정** — Today 우상단 톱니 아이콘 자리(액션 X)

### 코드

신규(전부 `ios/PillPouch/Features/`):

```
Features/
├── Root/
│   └── RootTabView.swift           # 3탭 컨테이너
├── Today/
│   ├── TodayView.swift             # Today 메인 (헤더 + 띠 + 쌓인 증거)
│   ├── TodayHeaderView.swift       # 날짜 + 진행도 도트 7개 + 톱니
│   ├── PouchStripPlaceholder.swift # 세로 봉지 띠 (3봉지 + 절취선)
│   ├── PouchPlaceholder.swift      # 단일 봉지 Sealed placeholder
│   └── EvidencePlaceholder.swift   # "쌓인 증거" 영역
├── History/
│   └── HistoryPlaceholderView.swift # "기록 — 곧 추가됩니다" 정도
└── Supplements/
    └── SupplementsPlaceholderView.swift # "영양제 — 곧 추가됩니다"
```

수정:
- `ContentView.swift` → `body`를 `RootTabView()` 호출로 교체(파일 자체는 유지, Preview 컨테이너 보존)

폴더 등록: 프로젝트가 PBXFileSystemSynchronizedRootGroup 사용 — `Features/` 추가만 하면 자동 등록됨(project.pbxproj 수정 불필요).

### 토큰 적용 룰

- 색: `PPColor.background/surface/stroke/textPrimary/textSecondary` + 봉지 시간대 색조 `PPColor.morning/lunch/evening`
- 간격: `PPSpacing.xs ~ xxl`만 사용. 매직 넘버 금지(절취선 간격 등 봉지 내부 시각 디테일은 컴포넌트 내부 상수로 고립)
- 폰트: `PPFont.titleL/titleM/body/caption/mono`만 사용

### 봉지 placeholder 시각 룰

- Shape: `RoundedRectangle(cornerRadius: 14)` + `PPColor.surface` fill + `PPColor.stroke` 1px stroke
- 윗부분에 V자 컷 자국(절취선) 점선 1줄
- 봉지 좌측에 시간대 색조 6pt 두께 세로 띠(아침=`PPColor.morning` 등)
- 내부 텍스트: 슬롯 명("아침"/"점심"/"저녁") + 캡슐 카운트 mock("3알")
- ❌ 체크 마크/알람 아이콘/✓ 절대 금지(`docs/design-system.md` §9, `docs/brief.md` §하지 말아야 할 시각 결정)

봉지 사이는 점선(`StrokeStyle(dash: [4,4])`) 가로선으로 절취선 표현.

### 진행도 도트 7개

- 가로 7개 원(직경 8pt, gap `PPSpacing.xs`)
- 정적 mockup: 앞 3개 = 채워진 `PPColor.textPrimary`, 4번째 = stroke `PPColor.morning`(오늘), 뒤 3개 = `PPColor.stroke`
- 실 데이터 연결 X(주간 진행 모델은 W2+)

## 비목표 (안 하는 것)

- ❌ 봉지 5상태 시각(W2 (M))
- ❌ 가로 드래그/햅틱(W2 (L))
- ❌ 캡슐 자산(#11) — placeholder Shape만
- ❌ 실 SwiftData `@Query` 연결 — mock 데이터만(model 자체는 import만, query 호출 X)
- ❌ 주간 뷰 / 영양제 CRUD(별도 task)
- ❌ Live Activity / Widget(W2)
- ❌ 진행도 도트 7개 실 데이터
- ❌ 다크/라이트 외 테마 변형, 접근성 동적 타입 별도 검증

## 구현 단계 (5단계, 순차)

### Step 1 — Features 폴더 + Root 탭바 + Placeholder 2종
- `Features/Root/RootTabView.swift` (3탭, `TabView`)
- `Features/History/HistoryPlaceholderView.swift`
- `Features/Supplements/SupplementsPlaceholderView.swift`
- `ContentView.swift` body → `RootTabView()`
- 빌드 통과 확인

### Step 2 — Today 헤더
- `TodayHeaderView.swift`
- 날짜(오늘 = `Date()`, `formatted(date: .complete, time: .omitted)` 한국어 로캘) + "오늘" 라벨 + 진행도 도트 7개(정적) + 우측 톱니(`Image(systemName: "gear")`, button 비활성)

### Step 3 — 봉지 placeholder + 띠
- `PouchPlaceholder.swift` — 단일 봉지(slot enum 받음 → 색조 분기)
- `PouchStripPlaceholder.swift` — `VStack` 안에 봉지 3개 + 사이에 점선 절취선

### Step 4 — "쌓인 증거" placeholder + Today 통합
- `EvidencePlaceholder.swift` — "이번 주 0개" + 어제/그제 자리(빈 RoundedRectangle 2개)
- `TodayView.swift` — 헤더 + 띠 + 쌓인 증거를 `ScrollView` + `VStack(spacing: PPSpacing.lg)` 로 통합. 배경 `PPColor.background`

### Step 5 — 스크린샷 + 보고서 + PR
- iPhone 15 Pro 시뮬레이터로 라이트/다크 빌드 → 수동 스크린샷 2장 → `docs/screenshots/today/{light,dark}.png` 커밋
- `docs/report/task_W1_14_report.md` 작성 → **승인 ⛔**
- PR 본문에 가설 B/Non-goals 체크 + 계획서/보고서 링크 → Squash merge

## 커밋 단위 (Conventional Commits)

```
docs: add W1-14 (#14) implementation plan
feat(ios): add RootTabView with 3 placeholder tabs
feat(ios): add TodayHeaderView with date and progress dots
feat(ios): add pouch placeholder shapes and vertical strip
feat(ios): add evidence placeholder and integrate TodayView
docs: add Today screen light/dark screenshots
docs: add W1-14 final report
```

7 commit. Squash 후 main에 1 commit.

## 위험 요소

1. **PBXFileSystemSynchronizedRootGroup 인식 실패** — 일부 Xcode 버전이 새 폴더 자동 등록 못 함. 빌드 깨지면 `xcodebuild build` 로그 확인 후 트러블슈팅(`docs/troubleshootings/`에 박제). 우회 X.
2. **봉지 placeholder가 너무 예뻐서 W2 교체 비용 증가** — Shape는 의도적으로 미니멀(둥근 사각형 + V컷). 디테일 욕심 금지.
3. **시간대 색조가 라이트/다크에서 대비 부족** — 스크린샷 단계에서 둘 다 확인. 부족하면 별도 토큰 PR(이 task 외).
4. **진행도 도트 정적 mockup이 가설 B를 약화** — 도트는 본질적으로 "체크" 메타포에 가까움. 다만 본질은 봉지 띠 — 도트는 보조 위치/크기로만 존재(8pt 직경, 헤더 우상단). 향후 W2에서 "주간 봉지 미니어처"로 교체 검토.

## 검증 (Issue #14 Done 조건)

- [ ] `cd ios && xcodebuild -scheme PillPouch -sdk iphonesimulator build` 통과
- [ ] iPhone 15 Pro 시뮬레이터 라이트/다크 모드 스크린샷 `docs/screenshots/today/{light,dark}.png` 커밋
- [ ] PR 본문 가설 B 체크 + Non-goals 체크
- [ ] 계획서/보고서 링크
- [ ] PR squash merge 후 Issue #14 자동 close

## 다음 (이 task 완료 후)

- W2 진입: #18 (L 백엔드 catalog endpoint) 또는 #11 (캡슐 자산) 작업지시자 결정
- W2 (M) 봉지 5상태 컴포넌트가 본 task의 `PouchPlaceholder`를 교체하는 첫 작업이 됨
