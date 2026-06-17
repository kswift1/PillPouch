# server/ — Pill Pouch Rust 백엔드

> **Status**: W3 진행 중. `/healthz`, `/v1/recommendations`, `/v1/categories`, category icon static hosting 구현됨.

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

## 로컬 실행

```bash
cd server
DATABASE_URL=sqlite::memory: cargo run -p api
```

기본 상대 경로는 repo root와 `server/` cwd 둘 다 지원한다.

| 환경 변수 | 기본값 | 용도 |
|---|---|---|
| `DATABASE_URL` | `sqlite::memory:` | SQLite 연결 문자열 |
| `SEED_RECOMMENDATIONS_PATH` | `server/seed/recommendations.json` 또는 `seed/recommendations.json` | recommendations seed import |
| `SEED_CATEGORIES_PATH` | `server/seed/categories.json` 또는 `seed/categories.json` | category seed import |
| `STATIC_ASSETS_DIR` | `server/assets` 또는 `assets` | `/assets/...` 정적 파일 루트 |
| `BIND_ADDR` | `0.0.0.0:8080` | listen 주소 (`PORT`보다 우선) |
| `PORT` | — | Railway 주입 포트. `BIND_ADDR`가 없으면 `0.0.0.0:{PORT}` |

## 빌드 / 테스트

```bash
cargo build           # 전체 workspace
cargo test            # 전체 테스트
cargo clippy -- -D warnings
cargo fmt --check
```

## 배포

Railway project `PillPouch` / service `api`.

현재 production URL:

```text
https://api-production-58ff5.up.railway.app
```

자세한 절차는 [`docs/runbooks/deploy.md`](../docs/runbooks/deploy.md).

## 의존성 설계 (예정 추가)
- `axum`, `tokio`, `tower-http`
- `sqlx` (SQLite, compile-time checked)
- `a2` 또는 `apns2` — APNs HTTP/2 (W3 ADR로 비교 후 결정)
- `chrono`, `chrono-tz`
- `tracing`, `tracing-subscriber`
- `serde`, `serde_json`
