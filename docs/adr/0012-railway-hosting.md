# ADR-0012: Railway 호스팅

## Status
Accepted — 2026-06-17

Supersedes: [ADR-0003: Fly.io 호스팅](0003-fly-io-hosting.md)

## Context

ADR-0003은 V1 백엔드 호스팅으로 Fly.io 도쿄 리전을 선택했다. 당시 기준은 한국 사용자 대상 푸시 발송 레이턴시, SQLite + Litestream 호환성, 비용이었다.

2026-06-17 현재 작업지시자는 Railway Hobby 계정에 이미 월 $5를 지불 중이다. Fly를 새로 추가하면 V1 운영 비용이 중복된다. V1 현재 서버 surface는 read-heavy endpoint 중심이다.

- `GET /healthz`
- `GET /v1/recommendations`
- `GET /v1/categories`
- `GET /assets/category-icons/{key}.png`

APNs Push to Start 및 `/v1/devices` 계열 endpoint는 아직 구현 전이다. 따라서 첫 운영 배포는 Railway로 시작하고, 푸시 발송 정확도/레이턴시가 실제 문제가 될 때 Asia region 또는 Fly 재검토가 가능하다.

Railway 공식 문서 확인 사항:

- `railway.toml` / `railway.json` config-as-code 지원
- Dockerfile이 있으면 Dockerfile build 사용
- public web service는 Railway가 주입하는 `PORT`에 `0.0.0.0:$PORT`로 listen해야 함
- volume mount path를 서비스에 설정하면 runtime container에서 read/write 가능
- Hobby plan은 월 $5 minimum usage와 $5 monthly usage credit 포함

## Decision

V1 백엔드 첫 운영 호스팅은 Railway로 변경한다.

- **플랫폼**: Railway
- **요금제**: 이미 결제 중인 Hobby plan 활용
- **배포 방식**: Railway GitHub 연결 배포 우선
- **빌드**: Dockerfile 기반 Rust release build
- **서비스 포트**: Railway `PORT` 환경변수 우선, local fallback `0.0.0.0:8080`
- **DB**: SQLite
- **영속 저장소**: Railway volume, mount path `/data`
- **DB path**: `sqlite:///data/pillpouch.db`
- **정적 자산**: Docker image에 `server/assets` 포함 후 Axum static route로 제공
- **Seed**: Docker image에 `server/seed` 포함 후 app boot 시 UPSERT
- **Secrets**: Railway service variables 사용

V1에서는 Railway volume backup을 우선 검토한다. 기존 ADR-0002의 Litestream + R2는 PITR 요구가 여전히 강할 때 Stage 3에서 유지한다.

## Consequences

### 긍정

- 이미 결제 중인 Railway Hobby plan을 사용해 월 비용 중복을 피한다.
- GitHub 연결 배포가 단순하다.
- Railway volume으로 SQLite 파일을 직접 보존할 수 있다.
- Dockerfile 기반 배포로 local/production 차이를 줄인다.
- 현재 read-heavy endpoint에는 Fly 도쿄 리전의 latency 장점이 필수 조건이 아니다.

### 부정 / 트레이드오프

- ADR-0003의 Fly 도쿄 리전 결정을 폐기한다.
- PTS 푸시 발송 시점에는 Railway region/latency가 문제가 될 수 있다.
- Fly + Litestream 공식 조합 대신 Railway volume/backup 또는 Litestream 별도 운영을 판단해야 한다.
- `PORT` 기반 listen 정합이 필요하다.
- 기존 문서의 Fly 표현을 Railway 기준으로 정리해야 한다.

### 재검토 조건

- PTS 발송 정확도나 사용자 체감 latency가 문제가 될 때
- Railway 비용이 기존 결제 범위를 유의미하게 초과할 때
- Railway volume backup만으로 복구 요구를 만족하지 못할 때
- multi-region 또는 Asia region 요구가 V1 운영 요구가 될 때

## 참조

- Issue [#37](https://github.com/kswift1/PillPouch/issues/37)
- 수행계획서 `docs/plans/task_W3_37.md`
- Railway docs: Config as Code — https://docs.railway.com/config-as-code/reference
- Railway docs: Volumes — https://docs.railway.com/volumes
- Railway docs: CLI Deploying — https://docs.railway.com/cli/deploying
- Railway docs: Public Networking — https://docs.railway.com/public-networking
- Railway Pricing — https://railway.com/pricing
