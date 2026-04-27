# `cargo clippy -- -D warnings`가 한국어 doc 주석 안 영문 키워드에서 실패

## 환경
- Rust stable (1.95.0 기준)
- workspace lints에 `clippy::pedantic = warn` + `-D warnings`
- 발생일: 2026-04-27 (PR #2, Issue #1 첫 CI)

## 재현 절차
1. `crates/storage/src/lib.rs`에 다음 doc 주석:
   ```rust
   //! SQLite 접근 (sqlx) + 마이그레이션. W3에서 채움.
   ```
2. `cargo clippy --workspace --all-targets -- -D warnings`
3. 결과:
   ```
   error: item in documentation is missing backticks
    --> crates/storage/src/lib.rs:1:5
     |
   1 | //! SQLite 접근 (sqlx) + 마이그레이션. W3에서 채움.
     |     ^^^^^^
     |
     = note: `-D clippy::doc-markdown` implied by `-D warnings`
   help: try
     |
   1 - //! SQLite 접근 (sqlx) + 마이그레이션. W3에서 채움.
   1 + //! `SQLite` 접근 (sqlx) + 마이그레이션. W3에서 채움.
   ```

## 원인
- `clippy::pedantic` 그룹에 포함된 `doc_markdown` lint가 **CamelCase/대문자 영문 단어**를 코드 식별자로 추정 → 백틱 안 감싸면 경고
- 한국어 doc 주석에 등장하는 `SQLite`, `Axum`, `APNs`, `HTTP/2`, `TDD` 등 영문 제품/약어가 모두 trip
- `-D warnings`라 경고가 에러로 승격 → CI 실패

## 해결책

### 옵션 평가
| | A. workspace에서 `doc_markdown = "allow"` | B. 모든 doc 주석에 백틱 |
|---|---|---|
| 장점 | 한국어 흐름 유지, 작업량 0 | clippy 엄격 유지 |
| 단점 | lint 1개 약화 | 매 doc string 신경, 한국어 가독성 저하 |
| 적합도 | 한국어 주석이 표준인 이 프로젝트 | 영어 주석 표준 프로젝트 |

### 채택: A
한국어 doc 주석에 영문 키워드(`Axum`, `SQLite`, `APNs HTTP/2`, `sqlx`, `TDD` 등)가 매번 등장하는 게 자연스러우므로, `doc_markdown` 한 개만 allow. 다른 pedantic lint는 그대로 warn 유지.

### 적용 (`server/Cargo.toml`)
```toml
[workspace.lints.clippy]
all = { level = "deny", priority = -1 }
pedantic = { level = "warn", priority = -1 }
module_name_repetitions = "allow"
# 한국어 doc 주석에 Axum/SQLite/APNs 등 영문 키워드가 자주 등장.
# 코드 식별자처럼 매번 백틱 감싸는 비용 > 얻는 가치.
# 의식적으로 백틱 쓰는 것은 자유.
doc_markdown = "allow"
```

## 향후 대응
- 영문 주석 작성 시(외부 공개용 등)엔 의식적으로 백틱 사용 권장
- API 문서가 본격적으로 필요한 시점(V2~)엔 `doc_markdown` 재활성화 + 일괄 정리 검토
- 다른 `clippy::pedantic` lint는 계속 활성: `cast_*`, `must_use_candidate`, `missing_errors_doc`, `missing_panics_doc` 등은 코드 품질에 직결

## 참고
- doc_markdown 룰: https://rust-lang.github.io/rust-clippy/master/index.html#doc_markdown
- workspace lints (Rust 1.74+): https://doc.rust-lang.org/cargo/reference/workspaces.html#the-lints-table
