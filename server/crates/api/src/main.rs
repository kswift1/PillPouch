//! `pillpouch-api` 바이너리 — Axum HTTP 서버 진입점.
//!
//! 환경 변수:
//! - `DATABASE_URL` — sqlx 연결 문자열. 기본 `sqlite::memory:` (개발/테스트).
//! - `SEED_RECOMMENDATIONS_PATH` — repo seed JSON 경로. 있으면 부팅 시 import.
//!   기본 `server/seed/recommendations.json` 상대 경로.
//! - `BIND_ADDR` — listen 주소. 기본 `0.0.0.0:8080` (Fly.io 표준).

use std::env;
use std::net::SocketAddr;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| tracing_subscriber::EnvFilter::new("info")),
        )
        .init();

    let database_url = env::var("DATABASE_URL").unwrap_or_else(|_| "sqlite::memory:".to_string());
    let seed_path = env::var("SEED_RECOMMENDATIONS_PATH")
        .unwrap_or_else(|_| "server/seed/recommendations.json".to_string());
    let bind_addr: SocketAddr = env::var("BIND_ADDR")
        .unwrap_or_else(|_| "0.0.0.0:8080".to_string())
        .parse()?;

    tracing::info!("connecting db: {database_url}");
    let pool = storage::connect(&database_url).await?;
    storage::migrate(&pool).await?;

    if std::path::Path::new(&seed_path).exists() {
        match storage::seed_recommendations_from_path(&pool, &seed_path).await {
            Ok(n) => tracing::info!("seeded {n} recommendations from {seed_path}"),
            Err(e) => tracing::warn!("seed skipped ({seed_path}): {e}"),
        }
    } else {
        tracing::warn!("seed file not found, skipping: {seed_path}");
    }

    let app = api::router(pool);

    tracing::info!("listening on {bind_addr}");
    let listener = tokio::net::TcpListener::bind(bind_addr).await?;
    axum::serve(listener, app).await?;
    Ok(())
}
