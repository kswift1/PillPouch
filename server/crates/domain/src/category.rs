//! 영양제 카테고리 카탈로그 도메인 타입.
//!
//! ADR-0007 결정:
//! - 서버가 카테고리 SoT
//! - 클라이언트 enum 없음
//! - V1.0 16종 시드 + V1.1 SKU 확장 대비

use serde::{Deserialize, Serialize};
use thiserror::Error;

/// 서버 카테고리 row.
///
/// `key` = lowerCamel 식별자 (예: `omega3`, `milkThistle`).
/// `display_name` = 한국어 표시명.
/// `icon_path` = Fly static 상대 경로 (`/assets/category-icons/{key}.png`).
/// `display_order` = 사용자 표시 순서.
/// `version` = 증분 동기화 기준 버전.
/// `updated_at` = Unix epoch seconds.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Category {
    pub key: String,
    pub display_name: String,
    pub icon_path: String,
    pub display_order: i64,
    pub version: i64,
    pub updated_at: i64,
}

/// 카테고리 카탈로그 도메인 에러.
#[derive(Debug, Error)]
pub enum CategoryError {
    #[error("category not found: {0}")]
    NotFound(String),
    #[error("storage error: {0}")]
    Storage(String),
}

impl Category {
    /// API/DB에 쓰는 정적 이미지 경로를 일관되게 생성.
    #[must_use]
    pub fn icon_path_for_key(key: &str) -> String {
        format!("/assets/category-icons/{key}.png")
    }
}

#[cfg(test)]
#[allow(non_snake_case)] // 테스트 함수명은 한글 + 언더바 (CLAUDE.md / code-style.md §1)
mod tests {
    use super::Category;

    #[test]
    fn icon_path_for_key는_static_asset_경로를_생성한다() {
        assert_eq!(
            Category::icon_path_for_key("omega3"),
            "/assets/category-icons/omega3.png"
        );
    }

    #[test]
    fn category_serde_왕복으로_의미가_보존된다() {
        let category = Category {
            key: "vitaminD".to_string(),
            display_name: "비타민 D".to_string(),
            icon_path: Category::icon_path_for_key("vitaminD"),
            display_order: 5,
            version: 1,
            updated_at: 1_777_388_476,
        };
        let json = serde_json::to_string(&category).expect("serialize");
        let back: Category = serde_json::from_str(&json).expect("deserialize");
        assert_eq!(category, back);
    }
}
