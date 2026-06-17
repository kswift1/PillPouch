# task_W3_37_stage4.md - GitHub 연결 배포와 runbook 단계보고서

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#37](https://github.com/kswift1/PillPouch/issues/37) |
| Stage | 4 - GitHub 연결 배포와 runbook |
| 작성일 | 2026-06-17 |

## 한 일

- Railway deploy runbook을 Fly stub에서 Railway 운영 절차로 교체했다.
  - `docs/runbooks/deploy.md`
- runbook index 상태를 갱신했다.
  - `docs/runbooks/README.md`
- 운영 표면 문서를 Railway 기준으로 정합했다.
  - `README.md`
  - `server/README.md`
  - `docs/api.md`
  - `docs/architecture.md`
  - `server/crates/api/src/lib.rs`
- GitHub autodeploy 연결 명령과 전제 조건을 runbook에 박제했다.

## GitHub autodeploy 연결 상태

아직 연결하지 않았다.

현재 Railway service 상태:

```json
{
  "source": null,
  "url": "https://api-production-58ff5.up.railway.app",
  "status": "SUCCESS",
  "deploymentId": "caa49767-457b-41b5-92d2-d4ebc4a77c93"
}
```

보류 이유:

- 현재 production deployment는 local CLI upload 기반이다.
- `server/Dockerfile`, `server/railway.toml`, Railway `PORT` fallback 변경이 아직 `main`에 없다.
- 지금 `railway service source connect --repo kswift1/PillPouch --branch main`을 실행하면 Railway가 `main` 기준 build를 트리거할 수 있고, 이 경우 배포 파일이 없어 실패할 수 있다.

따라서 GitHub source 연결은 PR merge 후 또는 최종 승인 시점으로 넘긴다.

Runbook에는 root/config 선확인 후 다음 명령을 실행하도록 박제했다.

```bash
railway service source connect \
  --service api \
  --repo kswift1/PillPouch \
  --branch main \
  --json
```

## Runbook 핵심 내용

`docs/runbooks/deploy.md`에 다음을 포함했다.

- Railway 운영 정보
  - Project ID
  - Environment ID
  - Service ID
  - Volume ID
  - public URL
  - current deployment ID
- local CLI deploy 절차
- GitHub autodeploy 연결 절차
- service root/config/Dockerfile/healthcheck 확인 항목
- variables
- volume 확인
- smoke test
- rollback/redeploy
- logs/metrics
- 위험 메모

## 검증

### Rust checks

```text
cargo fmt --all --check
=> passed

cargo test --workspace --all-targets
=> passed, 25 tests

cargo clippy --workspace --all-targets -- -D warnings
=> passed
```

### Railway smoke

```text
GET /healthz
=> ok

GET /v1/recommendations | jq '.recommendations | length'
=> 5

GET /v1/categories | jq '(.categories | length), .serverVersion'
=> 16
=> 1
```

## 남은 위험

- GitHub autodeploy가 아직 연결되지 않았다.
- PR merge 전 source 연결을 하면 `main` 기준 실패 deployment를 만들 수 있다.
- custom domain `api.pillpouch.app`는 아직 연결하지 않았다.
- APNs secrets는 아직 Railway variables에 없다.

## 다음 단계

Stage 5에서 다음을 진행한다.

- 최종 보고서 작성
- 전체 검증 재실행
- PR 준비 문안 작성
- 최종 승인 후 PR 생성/머지 절차

GitHub autodeploy 연결은 PR merge 이후 Railway service root `/server`와 config file path `/server/railway.toml`을 먼저 확인한 뒤 다음 명령으로 수행한다.

```bash
railway service source connect \
  --service api \
  --repo kswift1/PillPouch \
  --branch main \
  --json
```
