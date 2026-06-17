# task_W3_37_stage1.md - Docker image + Railway PORT 정합 단계보고서

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#37](https://github.com/kswift1/PillPouch/issues/37) |
| Stage | 1 - Docker image + Railway PORT 정합 |
| 작성일 | 2026-06-17 |

## 한 일

- Railway runtime이 주입하는 `PORT`를 서버가 읽도록 진입점을 수정했다.
  - `BIND_ADDR`가 있으면 기존처럼 우선 사용
  - `BIND_ADDR`가 없고 `PORT`가 있으면 `0.0.0.0:{PORT}`
  - 둘 다 없으면 local fallback `0.0.0.0:8080`
- bind 주소 결정 unit test 3개를 추가했다.
- Railway/Docker 배포용 파일을 추가했다.
  - `server/Dockerfile`
  - `server/.dockerignore`

## 변경 파일

- `server/crates/api/src/main.rs`
- `server/Dockerfile`
- `server/.dockerignore`

## Dockerfile 요약

- builder: `rust:1-bookworm`
- runtime: `debian:bookworm-slim`
- runtime 포함 파일:
  - `pillpouch-api`
  - `migrations/`
  - `seed/`
  - `assets/`
- runtime 기본 env:
  - `DATABASE_URL=sqlite:///data/pillpouch.db`
  - `SEED_RECOMMENDATIONS_PATH=seed/recommendations.json`
  - `SEED_CATEGORIES_PATH=seed/categories.json`
  - `STATIC_ASSETS_DIR=assets`
  - `RUST_LOG=info`

## 검증 결과

### Rust checks

```text
cargo fmt --all --check
=> passed

cargo test --workspace --all-targets
=> passed, 25 tests

cargo clippy --workspace --all-targets -- -D warnings
=> passed

cargo build --release -p api --bin pillpouch-api
=> passed
```

### PORT smoke

실행:

```bash
PORT=18080 DATABASE_URL=sqlite::memory: cargo run -p api --bin pillpouch-api
```

로그:

```text
seeded 5 recommendations from seed/recommendations.json
seeded 16 categories from seed/categories.json
listening on 0.0.0.0:18080
```

endpoint 확인:

```text
GET /healthz
=> ok

GET /v1/recommendations | jq '.recommendations | length'
=> 5

GET /v1/categories | jq '(.categories | length), .serverVersion'
=> 16
=> 1

HEAD /assets/category-icons/omega3.png
=> 200 OK
=> content-type: image/png
=> cache-control: public, max-age=86400
```

### Docker smoke

실행하지 못했다.

```text
docker --version
=> zsh:1: command not found: docker
```

대체 검증으로 Dockerfile이 빌드하는 release target은 로컬에서 성공했다. 실제 Docker build는 Docker가 있는 환경 또는 Railway Stage 2 build에서 확인해야 한다.

## 남은 위험

- Docker CLI가 없어 `docker build`와 컨테이너 내부 파일 배치를 아직 검증하지 못했다.
- `server/Dockerfile`은 `server/`를 Docker build context로 가정한다. Stage 2 Railway config에서 service root 또는 build context를 이 가정에 맞춰야 한다.
- Railway volume `/data`는 아직 생성/연결하지 않았다.

## 다음 단계

Stage 2에서 다음을 진행한다.

- Railway login/link
- Railway config-as-code 작성
- Railway service root/build context 확정
- Railway volume `/data` 생성/연결
- 첫 Railway deploy + public domain smoke test

## 승인 요청

Stage 2 진행 승인 필요.
