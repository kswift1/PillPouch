# task_W2_25.md — 단일 봉지 컴포넌트 수행계획서

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#25](https://github.com/kswift1/PillPouch/issues/25) |
| 마일스톤 | W2 |
| 크기 | L |
| 영역 | area:ios |
| 브랜치 | `kswift1/task25-pouch-component` |
| 단계 수 | 5 stage |
| Supersedes | #14 (closed) |

## 배경 / 동기

브리프의 V1 시그니처는 두 가지: (1) **약봉지 시각의 정밀한 메타포**, (2) **봉지 윗부분 가로 드래그 찢기 인터랙션**. 둘 다 가설 B의 정면 강화 요소. 이 task는 그 두 가지를 **단일 컴포넌트** 수준에서 완결시켜, 후속 Today/Live Activity/Widget 작업이 컴포넌트를 그대로 가져다 쓸 수 있게 한다.

기존 #14는 "3봉지 정적 띠 + 헤더 + 쌓인 증거 placeholder" — 봉지 자체의 정밀도는 placeholder Shape 수준이었음. 작업지시자가 사진(글라싱지 약봉지) 첨부와 함께 "봉지 1개에 집중, 사진 수준 재현, 찢기 정확하게, 중력 알약 재미요소"를 우선 요청 → 스코프 뒤집어 단일 컴포넌트 깊이 우선으로 전환.

## 목표

1. **봉지 시각 정밀도** — 첨부 사진의 글라싱지 약봉지를 SwiftUI 네이티브 7-layer 합성으로 재현. 외부 자산 0개. (#11 캡슐 일러스트와 독립)
2. **알약 시각** — capsuleType 6종 분기, Shape 기반. 24~32pt. #11 자산 머지 시 PillView 내부만 교체 가능한 인터페이스.
3. **중력 모션** — CMMotionManager 기반, '살짝' 수준의 자연스러운 알약 이동. 자체 2D 물리.
4. **찢기 UX** — 브리프 §핵심 인터랙션 명세 그대로(좌→우 드래그, 4단계 시각, 햅틱, 50% 임계).
5. **찢기 후 알약 낙하** — torn 시 알약이 봉지 밖으로 자연 낙하 + fade out.
6. **Showcase 화면** — 알약 개수/타입 조절 + Reset + Force-Tear 디버그.

## 범위 / 비범위

### 범위
- 봉지 7-layer 합성(`PouchPaperLayer` + `PouchTearLayer`)
- 알약 6종 Shape 렌더(`PillView`) — liquid는 생략 마커만
- 자체 2D 물리 엔진(`PillPhysicsEngine`) — gravity, damping, bounds, sphere-sphere 충돌
- `MotionEngine` (실 + Mock)
- 찢기 DragGesture + 햅틱
- Sealed ↔ Torn 상태 + 낙하 애니메이션
- `PouchShowcaseView` 데모 화면 + ContentView 연결

### 비범위
- ❌ Today 전체 화면(헤더/3봉지 띠/쌓인 봉지 영역) — 별도 task
- ❌ 봉지 5상태(Skipped, Missed) — 별도 task
- ❌ Live Activity / Widget / Dynamic Island
- ❌ 5초 Undo 토스트 / 길게 누르기 시트
- ❌ 실 SwiftData 연결 — `[PillItem]` mock props만
- ❌ #11 캡슐 일러스트 자산 사용
- ❌ Apple Watch
- ❌ 접근성 동적 타입 / VoiceOver 별도 검증(폴리싱 task에서)

## 접근 방식 (대안 비교)

### A1. 봉지 합성: ZStack 7-layer vs. 단일 Canvas

| 항목 | ZStack 7-layer (선택) | 단일 Canvas |
|---|---|---|
| 가독성 | 각 layer 파일 분리 가능 | 한 함수에 명령형으로 모두 |
| 디버깅 | View Hierarchy로 layer별 검사 | 어려움 |
| 알약 z-index | 알약을 L1로 두고 종이를 L2~로 깔면 자연 비침 | 별도 레이어 합성 코드 필요 |
| 성능 | 정적 layer는 SwiftUI 캐시됨 | 매 프레임 재실행 가능성 |
| **결정** | **선택** — 가독성/유지보수 우선. 알약만 60Hz, 종이는 정적 |

### A2. 알약 컨테이너: ZStack+ForEach vs. Canvas

→ 사용자 질문에 답한 대로 **ZStack + ForEach<PillView>**. 알약 5~10개 수준이면 성능 충분 + #11 자산 교체 용이 + spring 보간 한 줄.

### A3. 물리: SpriteKit vs. SwiftUI 자체 물리

| 항목 | SpriteKit (SKPhysicsBody) | SwiftUI 자체 (선택) |
|---|---|---|
| 정확도 | 정확한 물리(중력, 마찰, 회전) | 단순화된 2D (회전 X, restitution 단순) |
| 통합 | UIViewRepresentable 래핑 필요 | 순수 SwiftUI |
| 코드량 | 셋업 적음 / 통합 비용 큼 | 통합 적음 / tick 함수 직접 |
| #11 자산 교체 | SKSpriteNode | SwiftUI Image |
| **결정** | **SwiftUI 자체** — '살짝' 수준이라 단순 물리 충분, 통합 비용 절약 |

`PillPhysicsEngine`:
```
struct PillBody {
  var position: CGPoint
  var velocity: CGVector
  let radius: CGFloat
  let mass: CGFloat = 1
}

func tick(dt: TimeInterval, gravity: SIMD2<Double>, bounds: CGRect, pills: inout [PillBody]) {
  for i in pills.indices {
    pills[i].velocity.dx += gravity.x * G_SCALE * dt
    pills[i].velocity.dy += gravity.y * G_SCALE * dt
    pills[i].velocity *= damping  // 0.92
    pills[i].position += pills[i].velocity * dt
  }
  resolveBoundsCollision(&pills, in: bounds)
  resolvePairCollisions(&pills)
}
```

### A4. 찢기 시각: SwiftUI Path 동적 그리기 vs. PNG 시퀀스 마스크

| 항목 | Path 동적 (선택) | PNG 시퀀스 |
|---|---|---|
| 자유도 | 진행도에 따라 정확히 변화 | 프레임 수 한정 |
| 디자이너 의존 | 없음 | 자산 필요 |
| 자연스러움 | 노이즈 보강 필요 | 손그림 자연스러움 |
| **결정** | **Path 동적** — V1 자산 없이도 출시 가능, 후속 PNG 시퀀스로 교체 가능 |

지그재그 찢김 라인: `Path` + 가로 진행에 따라 노이즈(Perlin 또는 단순 sin × random) 추가.

### A5. 낙하 애니메이션: 물리 엔진 연장 vs. 별도 declarative 애니메이션

| 항목 | 물리 연장 (선택) | declarative (`.offset` + `.opacity`) |
|---|---|---|
| 자연스러움 | gravity 그대로, 회전 불가 | 정해진 곡선만 |
| 코드 | tick 함수 안에 isFalling 분기 | 별도 transition |
| **결정** | **물리 연장** — torn 직후 `pill.isFalling = true` → bounds 충돌 비활성, 화면 밖 나가면 fade. `velocity.dy` 강제 +200pt/s 초기 펀치 추가 |

### A6. CMMotionManager 라이프사이클

- `MotionEngine` = `@Observable` class (singleton X — 화면별 인스턴스)
- `.task { await engine.start() } .onDisappear { engine.stop() }` 으로 수명 관리
- 시뮬레이터 환경(센서 없음) 감지 → `MotionEngineMock` 자동 주입. Mock은 두 모드 모두 지원:
  - **Auto**: 천천히 회전하는 가짜 gravity (기본)
  - **Manual**: Showcase 화면 UI 슬라이더로 gravity 벡터 직접 조절(데모/버그 재현용)
- 실 기기 검증은 작업지시자 직접 수행
- NSMotionUsageDescription 추가 X — Core Motion gravity 자체는 권한 불필요

## 단계 분할 (구현계획서로 이어짐)

상세는 `task_W2_25_impl.md`에서 단계별 파일/커밋/검증 정의. 본 수행계획서에서는 단계 윤곽만:

### Stage 1 — 봉지 시각 (정적)
**산출물**: `PouchView` (Sealed 상태만), `PouchPaperLayer` 7-layer, `PouchShowcaseView` 골격(알약 0개).
**검증**: 라이트/다크 스크린샷 2장 → `task_W2_25_stage1.md` 보고서 → **승인 ⛔**

### Stage 2 — 알약 시각 + 정적 배치
**산출물**: `PillView` 6종, `PillBody` 모델, ZStack 합성, Showcase에 Slider/Picker 추가. 알약은 정적 위치(중력 X).
**검증**: 알약 6종 모두 표시되는 스크린샷 → `task_W2_25_stage2.md` → **승인 ⛔**

### Stage 3 — 중력 모션 + 물리
**산출물**: `MotionEngine` + `MotionEngineMock`, `PillPhysicsEngine`, `TimelineView` 60Hz tick, 충돌 해결.
**검증**: 시뮬레이터 회전 영상(motion.mov) → `task_W2_25_stage3.md` → **승인 ⛔**

### Stage 4 — 찢기 UX (Sealed↔Torn 전환만, 알약은 봉지 안)
**산출물**: `PouchTearLayer` 동적 Path, `PouchTearGesture` 임계/햅틱, Sealed↔Torn 전환. 알약 낙하는 다음 stage.
**검증**: 찢기 진행 스크린샷 + Torn 정착 스크린샷 → `task_W2_25_stage4.md` → **승인 ⛔**

### Stage 5 — 알약 낙하 애니메이션
**산출물**: torn 직후 `pill.isFalling = true` → bounds 충돌 비활성, 화면 밖 fade out, 초기 펀치 velocity.
**검증**: 낙하 시퀀스 영상(falling.mov) → `task_W2_25_stage5.md` → **승인 ⛔**

### 최종 통합
- 6개 스크린샷/영상 정리
- `task_W2_25_report.md` 작성 → **승인 ⛔**
- ContentView 연결 확인
- PR 생성

## 위험 요소 (수행계획서 수준)

1. **글라싱지 재현이 사진 수준에 못 미침** — Stage 1 보고서에서 작업지시자 시각 검토 후, 부족하면 fiber 텍스처/주름 보강 별도 stage 추가 가능.
2. **CMMotionManager 권한/시뮬레이터 한계** — 시뮬레이터엔 실 센서 없음. Mock으로 개발 → 실기기 검증은 W2 후반 또는 별도 검증 task에서.
3. **2D 물리 단순화로 알약 회전 부재 → 어색함** — V1에서는 회전 X. 부족하면 Stage 3 보고서에 명시 후 별도 폴리싱 task로.
4. **낙하 애니메이션이 가설 B 시각을 약화** — "찢기"가 "터뜨림"처럼 보이면 안 됨. 낙하는 자연스럽고 절제된 것이어야 함. Stage 4 보고서에서 시각 검토 게이트.
5. **PBXFileSystemSynchronizedRootGroup 인식 실패** — 이전 메모. 빌드 깨지면 트러블슈팅(`docs/troubleshootings/`).

## 가설 B 정합성

✅ **정면 강화**. 이 task의 두 핵심(봉지 시각 + 찢는 행위)이 가설 B 그 자체. Non-goals 충돌 없음(Carousel X, 단순 탭 X, 알람 시계/체크 마크 X).

## 다음 (이 task 완료 후)

- W2 다음: #11 캡슐 자산(이번 task의 PillView 내부 교체) 또는 #18 백엔드 catalog endpoint
- 후속: Today 화면 task(헤더 + 3봉지 띠 + 쌓인 증거) — 이번 컴포넌트를 3개 사용
- 후속: 봉지 5상태 일반화(Skipped/Missed/NOW 강조)
- 후속: Live Activity / Widget — 이번 컴포넌트를 ActivityKit 환경에서 재사용
