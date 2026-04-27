# Pill Pouch V1 — 6주 마일스톤

기획서 §V1 일정 + Plan §9 기준. GitHub Milestones와 동기화.

| 주차 | 핵심 deliverable | 주요 태스크 (S/M/L) | GitHub Milestone |
|---|---|---|---|
| **W1** | Repo 정렬 + iOS 모델/기본 화면 | (M) Repo 골격 #1, (M) ADR + Runbook stub #2, (M) SwiftData 4모델 #3, (M) design-system + 색 토큰 #4, (M) Today 정적 레이아웃 #5 | [W1](https://github.com/kswift1/PillPouch/milestone/1) |
| **W2** | 봉지 찢기 시그니처 인터랙션 + Widget/LA 골격 | **(L) 가로 드래그 4단계 시각/햅틱/50% 임계** (TDD), (M) 봉지 5상태 컴포넌트, **(L) Widget Extension + LA ContentState** | [W2](https://github.com/kswift1/PillPouch/milestone/2) |
| **W3** | 백엔드 + APNs + PTS 통합 | (M) Cargo workspace + Axum 골격, (L) APNs `.p8` 발급/세팅 → runbook, **(L) `/v1/devices` + Fly 첫 배포 + iOS PTS 등록 → 자동 LA E2E** | [W3](https://github.com/kswift1/PillPouch/milestone/3) |
| **W4** | 주간 뷰 + 폴리싱 + Undo/건너뛰기 | (M) 7×3 그리드, (M) 5초 Undo 토스트, (M) 길게 누르기 시트, (M) 쌓인 증거 영역, (L) CloudKit 동기화 | [W4](https://github.com/kswift1/PillPouch/milestone/4) |
| **W5** | 버그 + iOS 18 PTS 우회 + 도그푸딩 시작 | **(L) iOS 18.x PTS 토큰 미수신 폴백** + troubleshooting, (M) 로컬 노티 폴백 검증, (M) 도그푸딩 D1 | [W5](https://github.com/kswift1/PillPouch/milestone/5) |
| **W6** | App Store 제출 + 도그푸딩 D6 검토 | (M) 스크린샷·메타데이터, (M) fastlane TestFlight, (S) 푸시 정당성 description, (M) 도그푸딩 1주차 회고 | [W6](https://github.com/kswift1/PillPouch/milestone/6) |

## 검증 게이트

- **W3 끝**: "백엔드가 내 폰에 자동 푸시로 Live Activity 시작" E2E 동작 (실기기)
- **W5 끝**: "30일 도그푸딩 D1" 시작 가능
- **W6 끝**: TestFlight 업로드 + App Store 심사 제출

## 출시 후 마일스톤

| 마일스톤 | 내용 |
|---|---|
| [V1.0](https://github.com/kswift1/PillPouch/milestone/7) | App Store 출시 (W6 끝) |
| [V1.1](https://github.com/kswift1/PillPouch/milestone/8) | 30일 도그푸딩 결과 기반 다음 방향 |
