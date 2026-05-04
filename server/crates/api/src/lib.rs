//! Pill Pouch HTTP API (Axum, ADR-0001).
//!
//! V1 endpoint:
//! - `GET /healthz` — Fly health check
//! - `GET /v1/recommendations` — 인구통계 권장 영양제 전체 (Identity Anti-Promise §4 정합)
//! - `GET /v1/recommendations/:category` — 단일 카테고리

pub mod recommendations;

use axum::routing::get;
use axum::Router;
use sqlx::SqlitePool;

/// 메인 라우터 — 외부에서 listen 전에 만든 풀 + state로 조립.
pub fn router(pool: SqlitePool) -> Router {
    Router::new()
        .route("/healthz", get(|| async { "ok" }))
        .route("/v1/recommendations", get(recommendations::list))
        .route(
            "/v1/recommendations/:category",
            get(recommendations::get_one),
        )
        .with_state(pool)
}
