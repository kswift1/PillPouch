//! Pill Pouch HTTP API (Axum, ADR-0001).
//!
//! V1 endpoint:
//! - `GET /healthz` — Fly health check
//! - `GET /v1/categories` — 영양제 카테고리 카탈로그
//! - `GET /v1/recommendations` — 인구통계 권장 영양제 전체 (Identity Anti-Promise §4 정합)
//! - `GET /v1/recommendations/:category` — 단일 카테고리

pub mod categories;
pub mod recommendations;

use axum::http::header::{HeaderValue, CACHE_CONTROL};
use axum::routing::get;
use axum::Router;
use sqlx::SqlitePool;
use std::path::PathBuf;
use tower::ServiceBuilder;
use tower_http::services::ServeDir;
use tower_http::set_header::SetResponseHeaderLayer;

const ASSET_CACHE_CONTROL: &str = "public, max-age=86400";

/// 메인 라우터 — 외부에서 listen 전에 만든 풀 + state로 조립.
pub fn router(pool: SqlitePool) -> Router {
    router_with_assets(pool, default_assets_dir())
}

/// 메인 라우터 — 테스트/배포에서 정적 자산 디렉토리를 명시할 수 있는 variant.
pub fn router_with_assets(pool: SqlitePool, assets_dir: impl Into<PathBuf>) -> Router {
    let assets_service = ServiceBuilder::new()
        .layer(SetResponseHeaderLayer::if_not_present(
            CACHE_CONTROL,
            HeaderValue::from_static(ASSET_CACHE_CONTROL),
        ))
        .service(ServeDir::new(assets_dir.into()));

    Router::new()
        .route("/healthz", get(|| async { "ok" }))
        .route("/v1/categories", get(categories::list))
        .route("/v1/recommendations", get(recommendations::list))
        .route(
            "/v1/recommendations/:category",
            get(recommendations::get_one),
        )
        .nest_service("/assets", assets_service)
        .with_state(pool)
}

fn default_assets_dir() -> PathBuf {
    let repo_root_path = PathBuf::from("server/assets");
    if repo_root_path.exists() {
        return repo_root_path;
    }
    PathBuf::from("assets")
}

#[cfg(test)]
#[allow(non_snake_case)] // 테스트 함수명은 한글 + 언더바 (CLAUDE.md / code-style.md §1)
mod tests {
    use super::router_with_assets;
    use axum::body::{to_bytes, Body};
    use axum::http::{header, Request, StatusCode};
    use serde_json::Value;
    use std::path::PathBuf;
    use tower::ServiceExt;

    async fn fresh_pool() -> sqlx::SqlitePool {
        let pool = storage::connect("sqlite::memory:").await.expect("connect");
        storage::migrate(&pool).await.expect("migrate");
        pool
    }

    fn test_assets_dir() -> PathBuf {
        PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../assets")
    }

    #[tokio::test]
    async fn categories_endpoint는_16종_seed와_serverVersion을_반환한다() {
        let app = router_with_assets(fresh_pool().await, test_assets_dir());

        let response = app
            .oneshot(
                Request::builder()
                    .uri("/v1/categories")
                    .body(Body::empty())
                    .expect("request"),
            )
            .await
            .expect("response");

        assert_eq!(response.status(), StatusCode::OK);
        let body = to_bytes(response.into_body(), usize::MAX)
            .await
            .expect("body");
        let json: Value = serde_json::from_slice(&body).expect("json");

        assert_eq!(json["serverVersion"], 1);
        let categories = json["categories"].as_array().expect("categories array");
        assert_eq!(categories.len(), 16);
        assert_eq!(categories[0]["key"], "omega3");
        assert_eq!(categories[0]["displayName"], "오메가-3");
        assert_eq!(
            categories[0]["iconUrl"],
            "/assets/category-icons/omega3.png"
        );
    }

    #[tokio::test]
    async fn categories_endpoint는_since_현재_version이면_빈_목록을_반환한다() {
        let app = router_with_assets(fresh_pool().await, test_assets_dir());

        let response = app
            .oneshot(
                Request::builder()
                    .uri("/v1/categories?since=1")
                    .body(Body::empty())
                    .expect("request"),
            )
            .await
            .expect("response");

        assert_eq!(response.status(), StatusCode::OK);
        let body = to_bytes(response.into_body(), usize::MAX)
            .await
            .expect("body");
        let json: Value = serde_json::from_slice(&body).expect("json");

        assert_eq!(json["serverVersion"], 1);
        assert_eq!(json["categories"].as_array().expect("categories").len(), 0);
    }

    #[tokio::test]
    async fn category_icon_static_asset은_png와_cache_control을_반환한다() {
        let app = router_with_assets(fresh_pool().await, test_assets_dir());

        let response = app
            .oneshot(
                Request::builder()
                    .uri("/assets/category-icons/omega3.png")
                    .body(Body::empty())
                    .expect("request"),
            )
            .await
            .expect("response");

        assert_eq!(response.status(), StatusCode::OK);
        assert_eq!(
            response
                .headers()
                .get(header::CACHE_CONTROL)
                .expect("cache-control"),
            "public, max-age=86400"
        );
        let content_type = response
            .headers()
            .get(header::CONTENT_TYPE)
            .expect("content-type")
            .to_str()
            .expect("content-type str");
        assert!(content_type.starts_with("image/png"));
    }
}
