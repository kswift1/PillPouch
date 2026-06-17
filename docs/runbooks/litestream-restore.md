# litestream-restore.md - SQLite 백업 확인 + 복구

> **Status**: Railway V1 기준 완료. Litestream + R2는 ADR-0013에 따라 보류.

## 현재 결정

V1 Railway 배포에서는 Litestream을 runtime에 붙이지 않는다.

- Hosting: Railway ([ADR-0012](../adr/0012-railway-hosting.md))
- DB: SQLite (`/data/pillpouch.db`)
- Volume: Railway `api-volume`
- Backup: Railway volume-native backup + CLI DB export
- Litestream/R2: PTS/user data가 production에 들어가거나 PITR 요구가 생기면 재검토 ([ADR-0013](../adr/0013-railway-volume-backups.md))

## 운영 정보

```text
Project: PillPouch
Project ID: cf1ad73a-f08e-4353-933c-bfb42da2b63a
Environment: production
Service: api
Service ID: 7a6df165-dc50-4a4b-89cc-dfc21481a4e5
Volume: api-volume
Volume ID: 158911b4-e5e0-48a1-9a66-c265140d6f1e
Mount path: /data
SQLite path in container: /data/pillpouch.db
SQLite path via volume file browser: /pillpouch.db
```

## 정상성 확인

### 1. 서비스 상태

```bash
railway status
```

기대:

```text
api
    status: ● Online
    volume: api-volume · /data
```

### 2. Volume 파일 목록

```bash
railway volume files --volume api-volume list / --json
```

기대:

```text
/pillpouch.db
```

### 3. DB 다운로드

민감 데이터가 생기면 다운로드 파일은 `.context/` 아래에만 둔다. `.context/`는 gitignored이다.

```bash
mkdir -p .context/task_W3_37_stage3
railway volume files --volume api-volume download \
  /pillpouch.db \
  .context/task_W3_37_stage3/pillpouch.db \
  --overwrite \
  --json
```

### 4. SQLite integrity check

```bash
sqlite3 .context/task_W3_37_stage3/pillpouch.db 'PRAGMA integrity_check;'
```

기대:

```text
ok
```

### 5. 핵심 row count

```bash
sqlite3 .context/task_W3_37_stage3/pillpouch.db \
  "SELECT 'category', COUNT(*) FROM category
   UNION ALL
   SELECT 'recommendations', COUNT(*) FROM recommendations;"
```

현재 기대:

```text
category|16
recommendations|5
```

## 백업 절차

### 위험 작업 전 ad-hoc export

```bash
ts=$(date -u +%Y%m%dT%H%M%SZ)
mkdir -p ".context/railway-backups/$ts"
railway volume files --volume api-volume download \
  /pillpouch.db \
  ".context/railway-backups/$ts/pillpouch.db" \
  --json
sqlite3 ".context/railway-backups/$ts/pillpouch.db" 'PRAGMA integrity_check;'
shasum -a 256 ".context/railway-backups/$ts/pillpouch.db"
```

### Railway native backup

Railway Dashboard에서 service `api` 또는 attached volume의 Backups 화면을 연다.

1. Manual backup 생성
2. backup 이름에 작업 이유와 UTC 시각 포함
3. 생성 완료 확인
4. 복구가 필요한 경우 해당 backup의 Restore 사용

Railway 문서 기준 volume backups는 volume에 저장된 모든 content를 복구 대상으로 포함하며, SQLite 파일도 포함된다.

## 복구 절차

### 우선 경로 - Railway native restore

1. Railway Dashboard에서 `PillPouch` project 열기
2. `api` service / `api-volume` backup 화면으로 이동
3. 복구할 backup 선택
4. Restore 실행
5. service 재시작/상태 확인
6. endpoint smoke:

```bash
curl -sS https://api-production-58ff5.up.railway.app/healthz
curl -sS https://api-production-58ff5.up.railway.app/v1/categories \
  | jq '(.categories | length), .serverVersion'
```

7. DB export 후 integrity check 재실행

### 긴급 경로 - 파일 단위 restore

운영 DB를 직접 덮어쓰는 절차다. 작업지시자 명시 승인과 downtime 공지 없이 실행하지 않는다.

1. service 중지 또는 maintenance window 확보
2. 기존 DB export
3. 복구할 DB 파일 integrity check
4. Railway volume file upload로 `/pillpouch.db` 교체
5. service restart
6. smoke test

파일 단위 restore는 CLI 절차가 단순하지만, running SQLite process와 충돌할 수 있다. 가능하면 native restore를 우선한다.

## Litestream 재도입 조건

아래 조건 중 하나가 생기면 Litestream + R2 또는 다른 cross-provider backup을 다시 검토한다.

- production PTS token 저장 시작
- backend에 사용자 schedule/log 저장 시작
- Railway native backup의 RPO/RTO가 부족함
- PITR이 V1 운영 요구가 됨
- Railway volume restore drill 실패

## Stage 3 검증 기록

2026-06-17:

```text
railway volume files --volume api-volume list / --json
=> /pillpouch.db, 57344 bytes

sqlite3 .context/task_W3_37_stage3/pillpouch.db 'PRAGMA integrity_check;'
=> ok

row count
=> category|16
=> recommendations|5

SHA-256
=> d31ff98fba1d0bc17646c4d93c0ed41034b056ec2710acf2edbf5485453b829b
```

## 참고

- [ADR-0002: SQLite + Litestream](../adr/0002-sqlite-litestream.md)
- [ADR-0012: Railway 호스팅](../adr/0012-railway-hosting.md)
- [ADR-0013: Railway Volume Backups for V1 SQLite](../adr/0013-railway-volume-backups.md)
- Railway Volume Backups: https://docs.railway.com/volumes/backups
- Railway Volumes: https://docs.railway.com/volumes
- Railway volume CLI: https://docs.railway.com/cli/volume
