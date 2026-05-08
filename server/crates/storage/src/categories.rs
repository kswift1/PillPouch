//! `category` 테이블 sqlx 액세스.
//!
//! ADR-0007 카테고리 서버 SoT. V1.0 16종 시드가 마이그레이션에 박혀 있고,
//! `server/seed/categories.json` upsert로 배포 시 갱신 가능.

use chrono::Utc;
use domain::{Category, CategoryError};
use sqlx::{FromRow, SqlitePool};

#[derive(Debug, FromRow)]
struct CategoryRow {
    key: String,
    display_name: String,
    icon_path: String,
    display_order: i64,
    version: i64,
    updated_at: i64,
}

impl From<CategoryRow> for Category {
    fn from(row: CategoryRow) -> Self {
        Self {
            key: row.key,
            display_name: row.display_name,
            icon_path: row.icon_path,
            display_order: row.display_order,
            version: row.version,
            updated_at: row.updated_at,
        }
    }
}

/// 카테고리 목록 fetch.
///
/// `since`가 있으면 해당 버전보다 큰 row만 반환한다. 정렬 기준은
/// `display_order ASC`, 동률이면 `key ASC`.
///
/// # Errors
/// SQL 실패 시 에러.
pub async fn list_since(
    pool: &SqlitePool,
    since: Option<i64>,
) -> Result<Vec<Category>, CategoryError> {
    let rows: Vec<CategoryRow> = if let Some(version) = since {
        sqlx::query_as(
            r"
            SELECT key, display_name, icon_path, display_order, version, updated_at
            FROM category
            WHERE version > ?
            ORDER BY display_order ASC, key ASC
            ",
        )
        .bind(version)
        .fetch_all(pool)
        .await
    } else {
        sqlx::query_as(
            r"
            SELECT key, display_name, icon_path, display_order, version, updated_at
            FROM category
            ORDER BY display_order ASC, key ASC
            ",
        )
        .fetch_all(pool)
        .await
    }
    .map_err(|e: sqlx::Error| CategoryError::Storage(e.to_string()))?;

    Ok(rows.into_iter().map(Category::from).collect())
}

/// 단일 카테고리 fetch.
///
/// # Errors
/// 카테고리 미존재 시 `NotFound`. SQL 실패 시 `Storage`.
pub async fn get(pool: &SqlitePool, key: &str) -> Result<Category, CategoryError> {
    let row: Option<CategoryRow> = sqlx::query_as(
        r"
        SELECT key, display_name, icon_path, display_order, version, updated_at
        FROM category
        WHERE key = ?
        ",
    )
    .bind(key)
    .fetch_optional(pool)
    .await
    .map_err(|e: sqlx::Error| CategoryError::Storage(e.to_string()))?;

    row.map(Category::from)
        .ok_or_else(|| CategoryError::NotFound(key.to_string()))
}

/// 서버 카탈로그 최신 버전 fetch.
///
/// # Errors
/// SQL 실패 시 에러.
pub async fn server_version(pool: &SqlitePool) -> Result<i64, CategoryError> {
    let row: (i64,) = sqlx::query_as("SELECT COALESCE(MAX(version), 0) FROM category")
        .fetch_one(pool)
        .await
        .map_err(|e: sqlx::Error| CategoryError::Storage(e.to_string()))?;
    Ok(row.0)
}

/// 여러 카테고리 한 번에 UPSERT (트랜잭션).
///
/// 빈 입력은 no-op. `updated_at`이 0이면 호출 시점 Unix epoch seconds로 채운다.
///
/// # Errors
/// SQL 실패 시 에러.
pub async fn upsert_many(pool: &SqlitePool, categories: &[Category]) -> Result<(), sqlx::Error> {
    if categories.is_empty() {
        return Ok(());
    }
    let mut tx = pool.begin().await?;
    let now = Utc::now().timestamp();
    for category in categories {
        let updated_at = if category.updated_at == 0 {
            now
        } else {
            category.updated_at
        };
        sqlx::query(
            r"
            INSERT INTO category (key, display_name, icon_path, display_order, version, updated_at)
            VALUES (?, ?, ?, ?, ?, ?)
            ON CONFLICT(key) DO UPDATE SET
                display_name = excluded.display_name,
                icon_path = excluded.icon_path,
                display_order = excluded.display_order,
                version = excluded.version,
                updated_at = excluded.updated_at
            ",
        )
        .bind(&category.key)
        .bind(&category.display_name)
        .bind(&category.icon_path)
        .bind(category.display_order)
        .bind(category.version)
        .bind(updated_at)
        .execute(&mut *tx)
        .await?;
    }
    tx.commit().await?;
    Ok(())
}

#[cfg(test)]
#[allow(non_snake_case)] // 테스트 함수명은 한글 + 언더바 (CLAUDE.md / code-style.md §1)
mod tests {
    use super::{get, list_since, server_version, upsert_many};
    use crate::{connect, migrate};
    use domain::{Category, CategoryError};

    async fn fresh_pool() -> sqlx::SqlitePool {
        let pool = connect("sqlite::memory:").await.expect("connect");
        migrate(&pool).await.expect("migrate");
        pool
    }

    fn 샘플_카테고리(key: &str, display_order: i64, version: i64) -> Category {
        Category {
            key: key.to_string(),
            display_name: format!("{key} 표시명"),
            icon_path: Category::icon_path_for_key(key),
            display_order,
            version,
            updated_at: 1,
        }
    }

    #[tokio::test]
    async fn 마이그레이션_후_16종_seed가_display_order로_정렬된다() {
        let pool = fresh_pool().await;
        let all = list_since(&pool, None).await.expect("list");

        assert_eq!(all.len(), 16);
        assert_eq!(all[0].key, "omega3");
        assert_eq!(all[0].display_name, "오메가-3");
        assert_eq!(all[15].key, "other");
    }

    #[tokio::test]
    async fn since가_현재_version이면_빈_목록과_기존_server_version을_얻는다() {
        let pool = fresh_pool().await;
        let changed = list_since(&pool, Some(1)).await.expect("list");
        let version = server_version(&pool).await.expect("version");

        assert!(changed.is_empty());
        assert_eq!(version, 1);
    }

    #[tokio::test]
    async fn version이_증가한_row만_since_응답에_포함된다() {
        let pool = fresh_pool().await;
        let mut calcium = get(&pool, "calcium").await.expect("get");
        calcium.display_name = "칼슘 업데이트".to_string();
        calcium.version = 2;
        upsert_many(&pool, &[calcium]).await.expect("upsert");

        let changed = list_since(&pool, Some(1)).await.expect("list");
        let version = server_version(&pool).await.expect("version");

        assert_eq!(changed.len(), 1);
        assert_eq!(changed[0].key, "calcium");
        assert_eq!(changed[0].display_name, "칼슘 업데이트");
        assert_eq!(version, 2);
    }

    #[tokio::test]
    async fn 미존재_key_get은_NotFound() {
        let pool = fresh_pool().await;
        let err = get(&pool, "missing").await.expect_err("not found");
        match err {
            CategoryError::NotFound(key) => assert_eq!(key, "missing"),
            other @ CategoryError::Storage(_) => panic!("expected NotFound, got {other:?}"),
        }
    }

    #[tokio::test]
    async fn 신규_category_upsert가_가능하다() {
        let pool = fresh_pool().await;
        let category = 샘플_카테고리("biotin", 100, 2);
        upsert_many(&pool, &[category]).await.expect("upsert");

        let got = get(&pool, "biotin").await.expect("get");
        assert_eq!(got.display_name, "biotin 표시명");
        assert_eq!(got.icon_path, "/assets/category-icons/biotin.png");
    }
}
