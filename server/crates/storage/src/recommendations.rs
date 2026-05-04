//! `recommendations` 테이블 sqlx 액세스.
//!
//! Identity Anti-Promise §4 정합 데이터 (인구통계 일반 권장만).
//! seed → DB import는 `super::seed_recommendations_from_path`.
//!
//! 본 모듈은 sqlx `query_as` / `query` (런타임 SQL 검증)을 사용한다.
//! ADR-0001 §"compile-time checked queries" 정합을 위한 `sqlx prepare`
//! 셋업은 후속 PR에서 박제 (별도 ADR).

use chrono::Utc;
use domain::{Recommendation, RecommendationError, Supplement};
use sqlx::{FromRow, SqlitePool};

#[derive(Debug, FromRow)]
struct RecommendationRow {
    category: String,
    display_name: String,
    supplements_json: String,
    source: String,
    disclaimer: String,
    updated_at: i64,
}

impl RecommendationRow {
    fn into_domain(self) -> Result<Recommendation, RecommendationError> {
        let supplements: Vec<Supplement> = serde_json::from_str(&self.supplements_json)?;
        Ok(Recommendation {
            category: self.category,
            display_name: self.display_name,
            supplements,
            source: self.source,
            disclaimer: self.disclaimer,
            updated_at: self.updated_at,
        })
    }
}

/// 모든 카테고리 권장 영양제 fetch.
///
/// 정렬 기준: `category` 알파벳순.
///
/// # Errors
/// SQL 실패 또는 supplements_json 파싱 실패 시 에러.
pub async fn list_all(pool: &SqlitePool) -> Result<Vec<Recommendation>, RecommendationError> {
    let rows: Vec<RecommendationRow> = sqlx::query_as(
        r"
        SELECT category, display_name, supplements_json, source, disclaimer, updated_at
        FROM recommendations
        ORDER BY category ASC
        ",
    )
    .fetch_all(pool)
    .await
    .map_err(|e: sqlx::Error| RecommendationError::Storage(e.to_string()))?;

    rows.into_iter()
        .map(RecommendationRow::into_domain)
        .collect()
}

/// 단일 카테고리 fetch.
///
/// # Errors
/// 카테고리 미존재 시 `NotFound`. SQL/JSON 실패 시 그에 맞는 에러.
pub async fn get(pool: &SqlitePool, category: &str) -> Result<Recommendation, RecommendationError> {
    let row: Option<RecommendationRow> = sqlx::query_as(
        r"
        SELECT category, display_name, supplements_json, source, disclaimer, updated_at
        FROM recommendations
        WHERE category = ?
        ",
    )
    .bind(category)
    .fetch_optional(pool)
    .await
    .map_err(|e: sqlx::Error| RecommendationError::Storage(e.to_string()))?;

    row.ok_or_else(|| RecommendationError::NotFound(category.to_string()))?
        .into_domain()
}

/// 여러 카테고리 한 번에 UPSERT (트랜잭션).
/// `updated_at`은 호출 시점 Unix epoch seconds로 자동 설정.
///
/// 빈 입력은 no-op.
///
/// # Errors
/// SQL 실패 또는 JSON 직렬화 실패 시 에러.
pub async fn upsert_many(pool: &SqlitePool, recs: &[Recommendation]) -> Result<(), sqlx::Error> {
    if recs.is_empty() {
        return Ok(());
    }
    let mut tx = pool.begin().await?;
    let now = Utc::now().timestamp();
    for rec in recs {
        let supplements_json = serde_json::to_string(&rec.supplements)
            .map_err(|e| sqlx::Error::Protocol(format!("supplements_json serialize: {e}")))?;
        sqlx::query(
            r"
            INSERT INTO recommendations (category, display_name, supplements_json, source, disclaimer, updated_at)
            VALUES (?, ?, ?, ?, ?, ?)
            ON CONFLICT(category) DO UPDATE SET
                display_name = excluded.display_name,
                supplements_json = excluded.supplements_json,
                source = excluded.source,
                disclaimer = excluded.disclaimer,
                updated_at = excluded.updated_at
            ",
        )
        .bind(&rec.category)
        .bind(&rec.display_name)
        .bind(&supplements_json)
        .bind(&rec.source)
        .bind(&rec.disclaimer)
        .bind(now)
        .execute(&mut *tx)
        .await?;
    }
    tx.commit().await?;
    Ok(())
}

#[cfg(test)]
#[allow(non_snake_case)] // 테스트 함수명은 한글 + 언더바 (CLAUDE.md / code-style.md §1)
mod tests {
    use super::{get, list_all, upsert_many};
    use crate::{connect, migrate};
    use domain::{Recommendation, RecommendationError, Supplement};

    fn 샘플_권장(category: &str, display: &str) -> Recommendation {
        Recommendation {
            category: category.to_string(),
            display_name: display.to_string(),
            supplements: vec![Supplement {
                name: "비타민D".to_string(),
                reason: "한국인 평균 부족".to_string(),
                priority: 1,
                description: None,
                dosage: None,
                timing: None,
                side_effects: None,
            }],
            source: "식약처 KDRIs".to_string(),
            disclaimer: "인구통계 기반 일반 정보. 개인 진단·처방 X.".to_string(),
            updated_at: 0,
        }
    }

    async fn fresh_pool() -> sqlx::SqlitePool {
        let pool = connect("sqlite::memory:").await.expect("connect");
        migrate(&pool).await.expect("migrate");
        pool
    }

    #[tokio::test]
    async fn upsert_후_list_all로_삽입한_레코드를_읽을_수_있다() {
        let pool = fresh_pool().await;
        let recs = vec![
            샘플_권장("male_20s_30s", "20~30대 남성"),
            샘플_권장("female_20s_30s", "20~30대 여성"),
        ];
        upsert_many(&pool, &recs).await.expect("upsert");

        let all = list_all(&pool).await.expect("list");
        assert_eq!(all.len(), 2);
        // category 알파벳순
        assert_eq!(all[0].category, "female_20s_30s");
        assert_eq!(all[1].category, "male_20s_30s");
    }

    #[tokio::test]
    async fn 같은_category로_재upsert하면_갱신된다() {
        let pool = fresh_pool().await;
        let v1 = 샘플_권장("male_20s_30s", "20~30대 남성");
        upsert_many(&pool, &[v1]).await.expect("v1");

        let mut v2 = 샘플_권장("male_20s_30s", "20~30대 남성 (수정)");
        v2.supplements.push(Supplement {
            name: "오메가3".to_string(),
            reason: "혈관".to_string(),
            priority: 2,
            description: None,
            dosage: None,
            timing: None,
            side_effects: None,
        });
        upsert_many(&pool, &[v2]).await.expect("v2");

        let got = get(&pool, "male_20s_30s").await.expect("get");
        assert_eq!(got.display_name, "20~30대 남성 (수정)");
        assert_eq!(got.supplements.len(), 2);
    }

    #[tokio::test]
    async fn 미존재_category_get은_NotFound() {
        let pool = fresh_pool().await;
        let err = get(&pool, "missing").await.expect_err("not found");
        match err {
            RecommendationError::NotFound(c) => assert_eq!(c, "missing"),
            other => panic!("expected NotFound, got {other:?}"),
        }
    }

    #[tokio::test]
    async fn upsert_빈_입력은_no_op() {
        let pool = fresh_pool().await;
        upsert_many(&pool, &[]).await.expect("noop");
        let all = list_all(&pool).await.expect("list");
        assert!(all.is_empty());
    }
}
