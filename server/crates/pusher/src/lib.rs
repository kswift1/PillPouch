//! APNs HTTP/2 클라이언트 + 슬롯 스케줄러. W3에서 채움.

#[must_use]
pub fn placeholder() -> &'static str {
    "pusher"
}

#[cfg(test)]
mod tests {
    use super::placeholder;

    #[test]
    fn placeholder_returns_crate_name() {
        assert_eq!(placeholder(), "pusher");
    }
}
