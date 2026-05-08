//! SQLite 접근 (sqlx) + 마이그레이션 + seed import.

pub mod categories;
pub mod recommendations;

use sqlx::sqlite::{SqliteConnectOptions, SqlitePoolOptions};
use sqlx::SqlitePool;
use std::path::Path;
use std::str::FromStr;

/// 마이그레이션 묶음 — `server/migrations/` 디렉토리.
/// `sqlx::migrate!` 매크로가 빌드 타임에 SQL 파일 검증.
pub static MIGRATOR: sqlx::migrate::Migrator = sqlx::migrate!("../../migrations");

/// SQLite 풀 셋업. URL 예: `sqlite::memory:` (테스트) 또는 `sqlite:///var/lib/pillpouch/db.sqlite`.
///
/// # Errors
/// 잘못된 URL / 파일 권한 / 연결 실패 시 sqlx 에러 반환.
pub async fn connect(url: &str) -> Result<SqlitePool, sqlx::Error> {
    let opts = SqliteConnectOptions::from_str(url)?
        .create_if_missing(true)
        .foreign_keys(true);
    SqlitePoolOptions::new()
        .max_connections(8)
        .connect_with(opts)
        .await
}

/// 마이그레이션 실행. `connect` 후 호출.
///
/// # Errors
/// 마이그레이션 SQL 실행 실패 시 sqlx 에러 반환.
pub async fn migrate(pool: &SqlitePool) -> Result<(), sqlx::migrate::MigrateError> {
    MIGRATOR.run(pool).await
}

/// repo `server/seed/recommendations.json` → DB import.
/// 이미 같은 카테고리가 있으면 갱신 (UPSERT).
///
/// # Errors
/// 파일 읽기 / JSON 파싱 / SQL 실패 시 에러 반환.
pub async fn seed_recommendations_from_path(
    pool: &SqlitePool,
    path: impl AsRef<Path>,
) -> Result<usize, SeedError> {
    let bytes = tokio::fs::read(path.as_ref())
        .await
        .map_err(|e| SeedError::Io(e.to_string()))?;
    let recs: Vec<domain::Recommendation> = serde_json::from_slice(&bytes)?;
    recommendations::upsert_many(pool, &recs).await?;
    Ok(recs.len())
}

/// repo `server/seed/categories.json` → DB import.
/// 이미 같은 key가 있으면 갱신 (UPSERT).
///
/// # Errors
/// 파일 읽기 / JSON 파싱 / SQL 실패 시 에러 반환.
pub async fn seed_categories_from_path(
    pool: &SqlitePool,
    path: impl AsRef<Path>,
) -> Result<usize, SeedError> {
    let bytes = tokio::fs::read(path.as_ref())
        .await
        .map_err(|e| SeedError::Io(e.to_string()))?;
    let categories: Vec<domain::Category> = serde_json::from_slice(&bytes)?;
    categories::upsert_many(pool, &categories).await?;
    Ok(categories.len())
}

#[derive(Debug, thiserror::Error)]
pub enum SeedError {
    #[error("io: {0}")]
    Io(String),
    #[error("json: {0}")]
    Json(#[from] serde_json::Error),
    #[error("sqlx: {0}")]
    Sqlx(#[from] sqlx::Error),
}

#[cfg(test)]
#[allow(non_snake_case)] // 테스트 함수명은 한글 + 언더바 (CLAUDE.md / code-style.md §1)
mod tests {
    use super::{connect, migrate};

    #[tokio::test]
    async fn 인메모리_DB로_마이그레이션이_성공하고_핵심_테이블이_존재한다() {
        let pool = connect("sqlite::memory:").await.expect("connect");
        migrate(&pool).await.expect("migrate");

        for table in ["recommendations", "category"] {
            let row: (i64,) =
                sqlx::query_as("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name=?")
                    .bind(table)
                    .fetch_one(&pool)
                    .await
                    .expect("query");
            assert_eq!(row.0, 1, "{table} table should exist");
        }

        let category_count: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM category")
            .fetch_one(&pool)
            .await
            .expect("category count");
        assert_eq!(category_count.0, 16);
    }
}
