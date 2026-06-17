# task_W3_37_stage3.md - SQLite backup/restore 결정 단계보고서

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#37](https://github.com/kswift1/PillPouch/issues/37) |
| Stage | 3 - SQLite backup/restore |
| 작성일 | 2026-06-17 |

## 한 일

- Railway volume 파일 접근을 위해 Railway SSH key를 등록했다.
  - Key name: `railway-pillpouch-codex-20260617`
  - Fingerprint: `SHA256:ese2eS5x/SSriIwlKIb3hCrR7FPxPlIEwjSEs87QmW8`
- Railway volume `api-volume`에서 `/pillpouch.db`를 확인했다.
- DB 파일을 `.context/task_W3_37_stage3/pillpouch.db`로 다운로드했다.
- SQLite integrity check와 핵심 row count를 검증했다.
- V1 backup 정책을 ADR로 박제했다.
  - `docs/adr/0013-railway-volume-backups.md`
- ADR-0002에 backup mechanism partial supersede를 표시했다.
- `docs/runbooks/litestream-restore.md`를 Railway SQLite backup/restore 기준으로 갱신했다.
- `docs/runbooks/README.md` 상태를 갱신했다.

## 검증 결과

### Volume file list

```text
railway volume files --volume api-volume list / --json
```

결과:

```text
/lost+found
/pillpouch.db (57344 bytes)
```

### DB download

```text
railway volume files --volume api-volume download \
  /pillpouch.db \
  .context/task_W3_37_stage3/pillpouch.db \
  --overwrite \
  --json
```

결과:

```text
localPath: .context/task_W3_37_stage3/pillpouch.db
remotePath: /pillpouch.db
volume: api-volume
```

### SQLite integrity

```text
sqlite3 .context/task_W3_37_stage3/pillpouch.db 'PRAGMA integrity_check;'
=> ok
```

### Tables

```text
_sqlx_migrations
category
recommendations
```

### Row counts

```text
category|16
recommendations|5
```

### Backup copy dry-run

Downloaded DB를 local restore-check copy로 복사한 뒤 다시 검증했다.

```text
PRAGMA integrity_check
=> ok

category count
=> 16
```

### SHA-256

```text
d31ff98fba1d0bc17646c4d93c0ed41034b056ec2710acf2edbf5485453b829b
```

## 결정

V1 Railway 배포에서는 Litestream + R2를 당장 붙이지 않는다.

대신:

- Railway native volume backup을 primary backup으로 사용
- 위험 작업 전 `railway volume files download`로 ad-hoc DB export
- export 파일은 `sqlite3 ... 'PRAGMA integrity_check;'`로 검증
- production PTS token/user data가 들어가거나 PITR 요구가 생기면 Litestream/R2 재검토

## 근거

- 현재 production DB는 seed 데이터만 가진다.
- Railway volume native backup은 volume content 전체를 대상으로 한다.
- Litestream을 지금 붙이면 R2 bucket/secrets/runtime entrypoint가 추가되어 첫 배포 복잡도가 커진다.
- V1 현 단계에서는 backup 검증 가능성과 운영 단순성이 더 중요하다.

## 변경 파일

- `docs/adr/0002-sqlite-litestream.md`
- `docs/adr/0013-railway-volume-backups.md`
- `docs/adr/README.md`
- `docs/runbooks/litestream-restore.md`
- `docs/runbooks/README.md`

## 남은 위험

- Railway native backup 생성/restore 자체는 Dashboard/API 작업이라 CLI에서 실제 restore까지 자동화하지 않았다.
- 파일 단위 restore는 running SQLite process와 충돌할 수 있어 native restore를 우선해야 한다.
- device token/user data가 production에 들어가면 RPO/RTO 요구를 다시 평가해야 한다.
- 등록한 Railway SSH key는 이후 volume inspection에 사용된다. 불필요해지면 Railway account SSH key settings에서 제거한다.

## 참고한 Railway 공식 문서

- Volume Backups: https://docs.railway.com/volumes/backups
- Volumes: https://docs.railway.com/volumes
- CLI volume commands: https://docs.railway.com/cli/volume
- Volume API backup operations: https://docs.railway.com/integrations/api/manage-volumes

## 다음 단계

Stage 4에서 GitHub 연결 배포와 deploy runbook 정합을 진행한다.

주의: 현재 Railway deployment는 local CLI upload 기반이다. GitHub autodeploy는 아직 연결하지 않았다.
