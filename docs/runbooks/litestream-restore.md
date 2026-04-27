# litestream-restore.md — Litestream 백업 확인 + 복구

> **Status**: stub. **W3에서 채움** (Litestream 사이드카 셋업 시점).

## 채워야 할 항목

### 1. 백업 흐름
- [ ] Axum 컨테이너 내 SQLite 파일: `/data/pillpouch.db`
- [ ] Litestream 사이드카가 WAL을 1초 단위로 R2 업로드
- [ ] R2 버킷 구조: `s3://pillpouch-litestream/pillpouch.db/`

### 2. 백업 정상성 확인
- [ ] `litestream snapshots -config litestream.yml /data/pillpouch.db`
- [ ] R2 버킷에 `*.wal` 파일이 1~2초 단위로 쌓이는지
- [ ] `litestream wal -config litestream.yml /data/pillpouch.db | head` (최근 WAL 프레임 확인)

### 3. 복구 시나리오 — 서버 머신 새로 띄울 때
```bash
# 0. 빈 머신/볼륨 준비
# 1. Litestream으로 R2에서 SQLite 파일 복원
litestream restore -config litestream.yml /data/pillpouch.db
# 2. 복원 확인
ls -lh /data/pillpouch.db
# 3. Axum 부팅
./api
```

### 4. 복구 시나리오 — 임의 시점 (PITR)
```bash
# 어제 10:30 UTC 시점으로
litestream restore -config litestream.yml \
  -timestamp 2026-04-26T10:30:00Z \
  -o /tmp/pillpouch-restored.db /data/pillpouch.db
# 검증 후 교체
```

### 5. 정합성 검증
- [ ] `sqlite3 /data/pillpouch.db "PRAGMA integrity_check;"` → `ok`
- [ ] 주요 테이블 row count 비교 (복원 전 백업과)
- [ ] 최근 PTS 토큰 sample 5개 조회로 활성 확인

### 6. R2 버킷 운영
- [ ] R2 lifecycle policy: 30일 이전 WAL 자동 삭제 (스토리지 비용 절감)
- [ ] R2 자격증명은 Fly secrets에만 (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `LITESTREAM_S3_ENDPOINT`)
- [ ] 정기 백업 검증 (월 1회 PITR 테스트)

## 위험 메모
- 서버 머신이 죽으면 새 머신 복구까지 ~1분 다운 (Axum 시작 + Litestream restore)
- R2 자격증명 누출 시 백업 데이터 노출 — secrets 관리 엄격
- Litestream 버전과 SQLite 버전 호환성 확인 (큰 메이저 업그레이드 시)

## 참고
- ADR-0002 (SQLite + Litestream)
- ADR-0003 (Fly.io 호스팅)
- `deploy.md`
- 공식 문서: [litestream.io](https://litestream.io/)
