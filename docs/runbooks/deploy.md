# deploy.md — Fly.io 배포 절차

> **Status**: stub. **W3에서 채움** (백엔드 첫 Fly 배포 시점).

## 채워야 할 항목

### 1. 첫 배포 (1회)
- [ ] `fly auth login`
- [ ] `cd server && fly launch` (`fly.toml` 자동 생성, 도쿄 리전 `nrt` 명시)
- [ ] 볼륨 생성: `fly volumes create pillpouch_data --region nrt --size 1`
- [ ] Postgres/Redis 등 추가 서비스 미사용 (SQLite + Litestream)

### 2. 환경 변수 / 시크릿 주입
- [ ] `fly secrets set APNS_KEY_ID=... APNS_TEAM_ID=... APNS_BUNDLE_ID=... APNS_ENV=production`
- [ ] `.p8` 키: `fly secrets set APNS_PRIVATE_KEY_PEM="$(cat AuthKey_XXX.p8)"` (또는 파일 마운트)
- [ ] `LITESTREAM_REPLICA_URL=s3://...` + R2 자격증명 (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `LITESTREAM_S3_ENDPOINT`)
- [ ] `RUST_LOG=info,api=debug,pusher=debug`

### 3. CI/CD
- [ ] GitHub Secret: `FLY_API_TOKEN` (`fly tokens create deploy`)
- [ ] `.github/workflows/server-deploy.yml` (push to main + paths server/**)
- [ ] `flyctl deploy` 명령

### 4. 일상 배포
```bash
# 로컬에서 직접 배포 (예외 케이스)
cd server && fly deploy

# 표준: main 머지 → GitHub Actions 자동 배포
```

### 5. 롤백
```bash
fly releases list
fly releases rollback <version>
```

### 6. 모니터링
- [ ] `fly logs` 실시간 로그
- [ ] `fly status` 머신 상태
- [ ] `fly dashboard` 메트릭 (CPU, 메모리, 네트워크)

## 위험 메모
- `fly deploy` 첫 실행 시 빌드 5~10분 (이후 캐시)
- 환경 변수 변경 시 자동 재시작 → 잠시 다운 (~30초)
- Litestream 사이드카가 `litestream restore` 후에 Axum 부팅 — 첫 시작은 더 느릴 수 있음
- 시크릿 key 회전 시 바로 재시작됨 (downtime 주의)

## 참고
- ADR-0003 (Fly.io 호스팅)
- `litestream-restore.md`
- `apns-cert-setup.md`
