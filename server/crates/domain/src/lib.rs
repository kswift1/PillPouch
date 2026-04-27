//! 순수 도메인 로직 — 슬롯 시각 계산, 타임존, 상태 전환.
//! TDD 강제 영역. W3에서 채움.

#[must_use]
pub fn placeholder() -> &'static str {
    "domain"
}

#[cfg(test)]
mod tests {
    use super::placeholder;

    #[test]
    fn placeholder_returns_crate_name() {
        assert_eq!(placeholder(), "domain");
    }
}
