# Pill Pouch

> **오늘 먹었나? 헷갈리지 마세요.**
> 영양제를 먹은 기록이 명확하게 남는 iOS 앱.

알람으로 챙겨주는 앱이 아니다. **먹었다는 사실에 대한 신뢰감**을 만드는 앱이다.
한국 약봉지 띠를 매일 가로로 찢어가며 영양제 복용을 기록한다.

## 폴더 구조

| 폴더 | 내용 |
|---|---|
| [`ios/`](ios/) | iOS 앱 (SwiftUI + SwiftData + ActivityKit + WidgetKit) |
| [`server/`](server/) | Rust 백엔드 (Axum + sqlx + APNs) — Push to Start |
| [`docs/`](docs/) | 기획서·ADR·Runbook·작업 사이클 문서 (단일 소스) |
| [`design/`](design/) | 색 토큰, 봉지 5상태 아이콘, Figma 익스포트 |
| `.github/` | CI 워크플로우, Issue/PR 템플릿 |

## 빠른 시작

### iOS
```bash
open ios/PillPouch.xcodeproj
# Xcode 16+ 필요 (Swift Testing)
# iOS 17.2+ 타깃 (Push to Start)
```

### 서버 (W3부터)
```bash
cd server
cargo build
cargo test
```

## 작업 사이클

이 프로젝트는 **AI 페어 프로그래밍**으로 개발한다 — 바이브 코딩이 아니다.
모든 계획은 검토되고, 모든 결과물은 검증되며, 모든 결정의 뒤에는 사람이 있다.

자세한 절차는 [`CONTRIBUTING.md`](CONTRIBUTING.md) 참조. AI 페어 가드레일은 [`CLAUDE.md`](CLAUDE.md).

## 핵심 문서

- [`docs/brief.md`](docs/brief.md) — 기획서 v0.4 (헌법)
- [`docs/plan/milestones.md`](docs/plan/milestones.md) — 6주 마일스톤
- [`docs/adr/`](docs/adr/) — 의사결정 기록
- [`docs/runbooks/`](docs/runbooks/) — 운영 절차

## 기술 스택 요약

- **iOS**: SwiftUI 네이티브, SwiftData, ActivityKit, WidgetKit, AppIntent (iOS 17.2+)
- **백엔드**: Rust + Axum + sqlx + APNs HTTP/2
- **DB**: SQLite + Litestream (R2 자동 백업)
- **호스팅**: Fly.io (도쿄 리전)
- **CI**: GitHub Actions

## 라이선스

Proprietary. © 2026.
