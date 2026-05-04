//! `/v1/recommendations` HTTP 핸들러.

use axum::extract::{Path, State};
use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};
use axum::Json;
use domain::{Recommendation, RecommendationError};
use serde::Serialize;
use sqlx::SqlitePool;

/// 응답 wrapper — `{ "recommendations": [...] }` 형태.
/// iOS 앱 디코딩 안정성 + 향후 메타데이터(예: cursor) 추가 여지.
#[derive(Debug, Serialize)]
pub struct ListResponse {
    pub recommendations: Vec<Recommendation>,
}

/// `GET /v1/recommendations` — 모든 카테고리.
///
/// # Errors
/// Storage layer 실패 시 500. 카테고리 미존재 케이스는 빈 배열로 응답 (에러 X).
pub async fn list(State(pool): State<SqlitePool>) -> Result<Json<ListResponse>, ApiError> {
    let recommendations = storage::recommendations::list_all(&pool).await?;
    Ok(Json(ListResponse { recommendations }))
}

/// `GET /v1/recommendations/:category` — 단일 카테고리.
///
/// # Errors
/// 미존재 시 404. Storage/JSON 실패 시 500.
pub async fn get_one(
    State(pool): State<SqlitePool>,
    Path(category): Path<String>,
) -> Result<Json<Recommendation>, ApiError> {
    let r = storage::recommendations::get(&pool, &category).await?;
    Ok(Json(r))
}

/// 도메인 에러 → HTTP 응답 매핑.
#[derive(Debug)]
pub struct ApiError(pub RecommendationError);

impl From<RecommendationError> for ApiError {
    fn from(e: RecommendationError) -> Self {
        Self(e)
    }
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let (status, message) = match &self.0 {
            RecommendationError::NotFound(c) => {
                (StatusCode::NOT_FOUND, format!("category not found: {c}"))
            }
            RecommendationError::InvalidJson(_) | RecommendationError::Storage(_) => (
                StatusCode::INTERNAL_SERVER_ERROR,
                "internal error".to_string(),
            ),
        };
        if matches!(
            self.0,
            RecommendationError::Storage(_) | RecommendationError::InvalidJson(_)
        ) {
            tracing::error!("api error: {:?}", self.0);
        }
        (status, Json(serde_json::json!({ "error": message }))).into_response()
    }
}
