//! `/v1/categories` HTTP 핸들러.

use axum::extract::{Query, State};
use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};
use axum::Json;
use domain::{Category, CategoryError};
use serde::{Deserialize, Serialize};
use sqlx::SqlitePool;

/// 카테고리 증분 동기화 query.
#[derive(Debug, Deserialize)]
pub struct ListQuery {
    pub since: Option<i64>,
}

/// 카테고리 목록 응답 wrapper.
#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ListResponse {
    pub categories: Vec<CategoryResponse>,
    pub server_version: i64,
}

/// 모바일 mirror가 소비하는 카테고리 row.
#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct CategoryResponse {
    pub key: String,
    pub display_name: String,
    pub icon_url: String,
    pub display_order: i64,
    pub version: i64,
    pub updated_at: i64,
}

impl From<Category> for CategoryResponse {
    fn from(category: Category) -> Self {
        Self {
            key: category.key,
            display_name: category.display_name,
            icon_url: category.icon_path,
            display_order: category.display_order,
            version: category.version,
            updated_at: category.updated_at,
        }
    }
}

/// `GET /v1/categories?since={version}` — 카테고리 카탈로그.
///
/// # Errors
/// Storage layer 실패 시 500.
pub async fn list(
    State(pool): State<SqlitePool>,
    Query(query): Query<ListQuery>,
) -> Result<Json<ListResponse>, ApiError> {
    let categories = storage::categories::list_since(&pool, query.since)
        .await?
        .into_iter()
        .map(CategoryResponse::from)
        .collect();
    let server_version = storage::categories::server_version(&pool).await?;
    Ok(Json(ListResponse {
        categories,
        server_version,
    }))
}

/// 도메인 에러 → HTTP 응답 매핑.
#[derive(Debug)]
pub struct ApiError(pub CategoryError);

impl From<CategoryError> for ApiError {
    fn from(e: CategoryError) -> Self {
        Self(e)
    }
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let (status, message) = match &self.0 {
            CategoryError::NotFound(key) => {
                (StatusCode::NOT_FOUND, format!("category not found: {key}"))
            }
            CategoryError::Storage(_) => (
                StatusCode::INTERNAL_SERVER_ERROR,
                "internal error".to_string(),
            ),
        };
        if matches!(self.0, CategoryError::Storage(_)) {
            tracing::error!("api error: {:?}", self.0);
        }
        (status, Json(serde_json::json!({ "error": message }))).into_response()
    }
}
