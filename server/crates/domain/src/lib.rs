//! 순수 도메인 로직 — 슬롯 시각 계산, 타임존, 상태 전환, 권장 영양제.
//! TDD 강제 영역.

pub mod recommendation;

pub use recommendation::{Recommendation, RecommendationError, Supplement};
