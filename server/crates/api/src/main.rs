//! `pillpouch-api` 바이너리 — Axum HTTP 서버 진입점.
//!
//! 환경 변수:
//! - `DATABASE_URL` — sqlx 연결 문자열. 기본 `sqlite::memory:` (개발/테스트).
//! - `SEED_RECOMMENDATIONS_PATH` — repo seed JSON 경로. 있으면 부팅 시 import.
//!   기본 `server/seed/recommendations.json` 상대 경로.
//! - `SEED_CATEGORIES_PATH` — 카테고리 seed JSON 경로. 있으면 부팅 시 import.
//!   기본 `server/seed/categories.json` 상대 경로.
//! - `STATIC_ASSETS_DIR` — `/assets/...` 정적 파일 루트. 기본 `server/assets`.
//! - `BIND_ADDR` — listen 주소. 기본 `0.0.0.0:8080` (Fly.io 표준).

use std::env;
use std::net::SocketAddr;
use std::path::Path;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| tracing_subscriber::EnvFilter::new("info")),
        )
        .init();

    let database_url = env::var("DATABASE_URL").unwrap_or_else(|_| "sqlite::memory:".to_string());
    let recommendations_seed_path = env::var("SEED_RECOMMENDATIONS_PATH").unwrap_or_else(|_| {
        first_existing_path(&[
            "server/seed/recommendations.json",
            "seed/recommendations.json",
        ])
    });
    let categories_seed_path = env::var("SEED_CATEGORIES_PATH").unwrap_or_else(|_| {
        first_existing_path(&["server/seed/categories.json", "seed/categories.json"])
    });
    let assets_dir = env::var("STATIC_ASSETS_DIR")
        .unwrap_or_else(|_| first_existing_path(&["server/assets", "assets"]));
    let bind_addr: SocketAddr = env::var("BIND_ADDR")
        .unwrap_or_else(|_| "0.0.0.0:8080".to_string())
        .parse()?;

    tracing::info!("connecting db: {database_url}");
    let pool = storage::connect(&database_url).await?;
    storage::migrate(&pool).await?;

    if Path::new(&recommendations_seed_path).exists() {
        match storage::seed_recommendations_from_path(&pool, &recommendations_seed_path).await {
            Ok(n) => tracing::info!("seeded {n} recommendations from {recommendations_seed_path}"),
            Err(e) => tracing::warn!("seed skipped ({recommendations_seed_path}): {e}"),
        }
    } else {
        tracing::warn!("seed file not found, skipping: {recommendations_seed_path}");
    }

    if Path::new(&categories_seed_path).exists() {
        match storage::seed_categories_from_path(&pool, &categories_seed_path).await {
            Ok(n) => tracing::info!("seeded {n} categories from {categories_seed_path}"),
            Err(e) => tracing::warn!("seed skipped ({categories_seed_path}): {e}"),
        }
    } else {
        tracing::warn!("seed file not found, skipping: {categories_seed_path}");
    }

    if !Path::new(&assets_dir).exists() {
        tracing::warn!("static assets dir not found: {assets_dir}");
    }

    let app = api::router_with_assets(pool, assets_dir);

    tracing::info!("listening on {bind_addr}");
    let listener = tokio::net::TcpListener::bind(bind_addr).await?;
    axum::serve(listener, app).await?;
    Ok(())
}

fn first_existing_path(candidates: &[&str]) -> String {
    candidates
        .iter()
        .find(|path| Path::new(path).exists())
        .unwrap_or_else(|| {
            candidates
                .first()
                .expect("first_existing_path requires candidates")
        })
        .to_string()
}
