//! 순수 도메인 로직 — 슬롯 시각 계산, 타임존, 상태 전환, 권장 영양제, 카테고리.
//! TDD 강제 영역.

pub mod category;
pub mod recommendation;

pub use category::{Category, CategoryError};
pub use recommendation::{Recommendation, RecommendationError, Supplement};
