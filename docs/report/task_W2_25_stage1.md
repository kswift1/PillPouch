# task_W2_25_stage1.md — Stage 1 보고서: 봉지 시각 (정적, Sealed)

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#25](https://github.com/kswift1/PillPouch/issues/25) |
| 마일스톤 | W2 |
| 크기 | L — Stage 1/5 |
| 브랜치 | `kswift1/task25-pouch-component` |
| 수행계획서 | [`docs/plans/task_W2_25.md`](../plans/task_W2_25.md) |
| 구현계획서 | [`docs/plans/task_W2_25_impl.md`](../plans/task_W2_25_impl.md) |

## 산출물

### 신규 파일

| 파일 | 역할 |
|---|---|
| `ios/PillPouch/Features/Pouch/PouchState.swift` | 상태 enum (sealed/tearing/torn) + case별 doc-comment |
| `ios/PillPouch/Features/Pouch/PouchPaperLayer.swift` | 7-layer 글라싱지 합성 (paperBody/fiberTexture/topPrintBand/wrinkleHighlight/heatSeal/tearMarker) |
| `ios/PillPouch/Features/Pouch/PouchView.swift` | 단일 봉지 컴포넌트 shell. `state` props 받음, 이번엔 paper layer만 합성 |
| `ios/PillPouch/Features/Showcase/PouchShowcaseView.swift` | 데모 화면. 240×320 frame으로 봉지 1개 노출 |

### 수정 파일

| 파일 | 변경 |
|---|---|
| `ios/PillPouch/ContentView.swift` | body → `PouchShowcaseView()` 호출 |

### 폴더 등록

PBXFileSystemSynchronizedRootGroup 자동 인식 — `Features/Pouch/`, `Features/Showcase/` 둘 다 별도 project.pbxproj 수정 없이 빌드에 포함됨. **위험 #5(인식 실패) 통과.**

## 검증

### 빌드
```
cd ios && xcodebuild -scheme PillPouch -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
** BUILD SUCCEEDED **
```

### 스크린샷

> **시뮬레이터 변경 메모**: 계획서/CLAUDE.md는 iPhone 15 Pro 명시했으나 로컬 환경에 iPhone 15 시리즈 시뮬레이터 미설치. Xcode 26.4 기본인 **iPhone 16 Pro**로 촬영. 후속 stage에서도 동일 기기 사용 예정. 필요 시 차후 작업지시자가 iPhone 15 Pro 시뮬레이터 설치 후 재촬영 가능.

| 파일 | 모드 | 비고 |
|---|---|---|
| `docs/screenshots/pouch/sealed-light.png` | Light | 베이지 배경 위 흰 봉지, 인쇄 띠/V컷 가시 |
| `docs/screenshots/pouch/sealed-dark.png` | Dark | 어두운 배경 위 회색조 봉지 |

## 시각 평가 (사진 vs. 현재 결과 비교)

### 사진 (`.context/attachments/CleanShot 2026-04-29 at 00.11.55@2x.png`) 특징
- 글라싱지 반투명 흰색
- 상단에 인쇄된 약국명/환자명 텍스트(흐릿)
- 잔주름·접힘 자국 다수
- 종이 fiber 결 visible
- 우측 가장자리 살짝 접혀 있음
- 봉지 안에 캡슐 3알이 비쳐 보임

### 현재 결과
- ✅ 인쇄 띠 — placeholder 텍스트 3줄 표시됨, opacity 0.42로 사진과 비슷한 흐림
- ✅ V컷 마커 + 좌향 화살표 우상단에 표시 (당기는 방향 안내)
- ✅ 라이트/다크 모두 본문 형태 식별 가능
- ⚠ **fiber 텍스처가 너무 미세하게 보임** — 시뮬레이터 디스플레이에서 거의 인지 불가. 라인 두께(0.4pt) + opacity(0.02~0.10)가 너무 보수적. Stage 2 진입 전 보강 권장.
- ⚠ **주름 highlight가 약함** — `wrinkleHighlight()` LinearGradient가 너무 흐림. 사진처럼 명확한 접힘 자국이 없음.
- ⚠ **heat seal 점선이 거의 안 보임** — opacity 0.18~0.22 + 0.5pt 라인이 시뮬에서 안 잡힘. 두께/대비 보강 필요.
- ⚠ **다크모드에서 흰 봉지가 너무 단단해 보임** — 종이 opacity 0.78 + 어두운 배경 합성에서 반투명 효과가 사라짐. 다크모드 별도 색조 또는 opacity 조정 필요할 수 있음.
- ❌ **알약 비침** — 이번 stage 범위 외 (Stage 2). 현재는 봉지 내부가 빈 회색.

## 의사결정 / 위험 진행 상황

| 위험 | 상태 |
|---|---|
| #1 fiber 텍스처 깜빡임 | 발생 X (deterministic sin/cos 기반) |
| #2 글라싱지 재현이 사진 수준 못 미침 | **부분 발현**. 위 ⚠ 4개 항목. 보강 필요 가능성. |
| #5 PBX 인식 실패 | 통과 |

## 다음 (Stage 2 들어가기 전)

Stage 1 결과물에 대해 작업지시자 시각 검토 후 두 갈래:

### 옵션 A: 그대로 Stage 2 진입
"이 정도면 Sealed 베이스로 충분하다" — 알약/모션/찢기를 얹은 후 전체적으로 다시 시각 polish.

### 옵션 B: Stage 1.5 보강 사이클 추가
fiber 텍스처 강화 + 주름 명확화 + heat seal 가시성 + 다크모드 색조 별도 조정 → 새 스크린샷 → 재승인. 추가 단계가 별도 보고서/승인을 늘림.

### 옵션 C: 핀포인트 보강만 즉시 반영
`PouchPaperLayer` 의 opacity/lineWidth 상수 몇 개만 즉시 조정 후 같은 stage 1 보고서로 보강 스크린샷 추가. 가장 가벼움.

**추천**: 옵션 C — fiber line opacity를 0.05→0.12, heat seal opacity 0.22→0.40, wrinkle gradient 강화. 코드 변경 작음, stage 분할 없음. 만족 안 되면 옵션 B로.

## 커밋 (이 보고서 + 코드 + 스크린샷 함께)

```
feat(ios): add PouchState enum
feat(ios): add PouchPaperLayer with 7-layer glassine composition
feat(ios): add PouchView shell + PouchShowcaseView entry
feat(ios): wire ContentView to Showcase
docs: add Stage 1 sealed pouch screenshots (light/dark)
docs: add Stage 1 report
```

## 승인 ⛔

작업지시자 검토 후 옵션 A/B/C 결정 + 승인 시 Stage 2 진입.
