# architecture.md

> **Status**: stub. W3 백엔드 통합 시점에 다이어그램·시퀀스·컴포넌트 책임 채움.

## 컴포넌트 (예정)
- iOS App (SwiftUI + SwiftData + ActivityKit + WidgetKit)
- Widget Extension (Live Activity + Interactive Widget)
- Rust 백엔드 (Axum + sqlx + APNs HTTP/2)
- SQLite + Litestream (R2)
- Fly.io (도쿄 리전)

## TODO
- [ ] 시스템 다이어그램 (Mermaid)
- [ ] PTS 푸시 시퀀스 다이어그램 (앱 kill → 슬롯 시각 → APNs → 락스크린)
- [ ] 컴포넌트별 책임 표
- [ ] 의존성 방향 규칙
