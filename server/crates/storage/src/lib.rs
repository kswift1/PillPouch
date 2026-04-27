//! SQLite 접근 (sqlx) + 마이그레이션. W3에서 채움.

#[must_use]
pub fn placeholder() -> &'static str {
    "storage"
}

#[cfg(test)]
mod tests {
    use super::placeholder;

    #[test]
    fn placeholder_returns_crate_name() {
        assert_eq!(placeholder(), "storage");
    }
}
