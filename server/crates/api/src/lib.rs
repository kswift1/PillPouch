//! Pill Pouch HTTP API (Axum). W3에서 채움.

#[must_use]
pub fn placeholder() -> &'static str {
    "api"
}

#[cfg(test)]
mod tests {
    use super::placeholder;

    #[test]
    fn placeholder_returns_crate_name() {
        assert_eq!(placeholder(), "api");
    }
}
