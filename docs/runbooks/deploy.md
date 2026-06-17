# deploy.md - Railway 배포 절차

> **Status**: Railway V1 첫 배포 완료. GitHub autodeploy 연결은 PR merge 후 진행.

## 운영 정보

```text
Workspace: 김성원's Projects
Project: PillPouch
Project ID: cf1ad73a-f08e-4353-933c-bfb42da2b63a
Environment: production
Environment ID: cd22b416-9491-4e77-8aea-38bd1da54612
Service: api
Service ID: 7a6df165-dc50-4a4b-89cc-dfc21481a4e5
Volume: api-volume
Volume ID: 158911b4-e5e0-48a1-9a66-c265140d6f1e
Volume mount: /data
Public URL: https://api-production-58ff5.up.railway.app
Current deployment: caa49767-457b-41b5-92d2-d4ebc4a77c93
```

## 현재 배포 상태

Stage 2에서는 GitHub source를 아직 연결하지 않고 CLI upload로 배포했다.

이유:

- `server/Dockerfile`, `server/railway.toml`, Railway `PORT` fallback 변경이 아직 `main`에 없다.
- 지금 GitHub autodeploy를 연결하면 `main` 기준 재빌드가 실패할 수 있다.

PR merge 후 Stage 4/최종 단계에서 GitHub source를 연결한다.

## 로컬 CLI 배포

Railway CLI 로그인:

```bash
railway login
railway whoami
```

현재 repo를 Railway project/service에 연결:

```bash
railway link --project cf1ad73a-f08e-4353-933c-bfb42da2b63a --environment production --service api
railway status
```

수동 배포:

```bash
railway up ./server \
  --path-as-root \
  --service api \
  --environment production \
  --detach \
  --json \
  --message "manual deploy"
```

상태 확인:

```bash
railway deployment list --json | jq '.[0] | {id,status,createdAt}'
railway service status --json
railway logs --service api --deployment <deployment-id> --lines 120
```

## GitHub Autodeploy 연결

전제:

- 이 PR이 `main`에 merge되어야 한다.
- `main`에 `server/Dockerfile`, `server/railway.toml`, Railway `PORT` fallback 변경이 있어야 한다.

연결 전 Dashboard에서 먼저 설정/저장:

- Service root directory: `/server`
- Config file path: `/server/railway.toml`
- Dockerfile path: `Dockerfile`
- Healthcheck path: `/healthz`
- Volume: `api-volume` mounted at `/data`

주의: `railway service source connect`는 root/config path를 함께 설정하지 않는다. 위 설정 없이 연결하면 GitHub build가 repo root에서 시작되어 `server/Dockerfile`과 `server/railway.toml`을 찾지 못할 수 있다.

연결 명령:

```bash
railway service source connect \
  --service api \
  --repo kswift1/PillPouch \
  --branch main \
  --json
```

연결 확인:

```bash
railway service list --json | jq '.[] | select(.name=="api") | {source,url,status}'
```

GitHub 연결 후에는 `main` push/merge가 Railway deployment를 트리거한다.

## Variables

```text
DATABASE_URL=sqlite:///data/pillpouch.db
SEED_RECOMMENDATIONS_PATH=seed/recommendations.json
SEED_CATEGORIES_PATH=seed/categories.json
STATIC_ASSETS_DIR=assets
RUST_LOG=info
```

확인:

```bash
railway variable list --service api --kv
```

주의: `--kv`는 raw value를 출력한다. secret-bearing variable이 추가된 뒤에는 출력 공유 금지.

## Volume

```bash
railway volume list --json
railway volume files --volume api-volume list / --json
```

기대:

```text
/pillpouch.db
```

백업/복구는 [`litestream-restore.md`](litestream-restore.md)를 따른다.

## Smoke Test

```bash
BASE_URL=https://api-production-58ff5.up.railway.app

curl -sS "$BASE_URL/healthz"
curl -sS "$BASE_URL/v1/recommendations" | jq '.recommendations | length'
curl -sS "$BASE_URL/v1/categories" | jq '(.categories | length), .serverVersion'
curl -sSI "$BASE_URL/assets/category-icons/omega3.png" | sed -n '1,12p'
```

현재 기대:

```text
ok
5
16
1
HTTP/2 200
content-type: image/png
cache-control: public, max-age=86400
```

## Rollback / Redeploy

최근 deployment 확인:

```bash
railway deployment list --json | jq '.[0:5] | map({id,status,createdAt,meta:{cliMessage:.meta.cliMessage}})'
```

최신 successful deployment 재배포:

```bash
railway redeploy --service api
```

문제가 있으면 Railway Dashboard에서 이전 successful deployment를 선택해 redeploy한다.

## Logs / Metrics

```bash
railway logs --service api --lines 120
railway logs --service api --build <deployment-id> --lines 200
railway logs --service api --http --status ">=400" --lines 50
railway metrics --service api
railway open
```

## 위험 메모

- 현재 Railway replica region은 `sfo`로 표시된다. 한국 사용자 latency가 PTS 발송 정확도에 영향을 주면 ADR-0012 재검토 조건에 해당한다.
- GitHub autodeploy는 PR merge 전 연결 금지. `main`에 배포 파일이 없으면 실패 deployment를 만들 수 있다.
- SQLite 파일 단위 restore는 running process와 충돌할 수 있다. 가능하면 Railway native volume restore를 우선한다.
- APNs secrets는 아직 설정하지 않았다. PTS 구현 시 Railway variables/secrets로 별도 주입한다.

## 참고

- [ADR-0012: Railway 호스팅](../adr/0012-railway-hosting.md)
- [ADR-0013: Railway Volume Backups for V1 SQLite](../adr/0013-railway-volume-backups.md)
- [`litestream-restore.md`](litestream-restore.md)
- Railway Config as Code: https://docs.railway.com/config-as-code/reference
- Railway GitHub Autodeploys: https://docs.railway.com/deployments/github-autodeploys
- Railway CLI Deploying: https://docs.railway.com/cli/deploying
- Railway Volumes: https://docs.railway.com/volumes
