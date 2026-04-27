# server/ — Pill Pouch Rust 백엔드

> **Status**: 빈 골격 (W1). 본격 구현은 W3.

## 구조

```
server/
├── Cargo.toml         # workspace
└── crates/
    ├── api/           # Axum HTTP 라우터
    ├── pusher/        # APNs HTTP/2 + 스케줄러
    ├── domain/        # 순수 도메인 로직 (TDD 강제)
    └── storage/       # SQLite (sqlx) + 마이그레이션
```

## 로컬 실행 (예정, W3)

```bash
cd server
cp .env.example .env   # APNs 키, DB 경로 등 설정
cargo run -p api
```

## 빌드 / 테스트

```bash
cargo build           # 전체 workspace
cargo test            # 전체 테스트
cargo clippy -- -D warnings
cargo fmt --check
```

## 배포 (예정, W3)

Fly.io (도쿄 리전, `nrt`). 자세한 절차는 [`docs/runbooks/deploy.md`](../docs/runbooks/deploy.md).

## 의존성 설계 (예정 추가)
- `axum`, `tokio`, `tower-http`
- `sqlx` (SQLite, compile-time checked)
- `a2` 또는 `apns2` — APNs HTTP/2 (W3 ADR로 비교 후 결정)
- `chrono`, `chrono-tz`
- `tracing`, `tracing-subscriber`
- `serde`, `serde_json`
