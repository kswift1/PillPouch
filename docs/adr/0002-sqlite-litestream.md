# ADR-0002: SQLite + Litestream

## Status
Accepted — 2026-04-27

## Context
백엔드(`server/`)가 저장하는 데이터는:
- 사용자/디바이스 PTS 토큰 (1~2개/사용자)
- 영양제 스케줄 (5개 내외/사용자)
- 푸시 발송 로그

→ 사용자 1만 명 가도 데이터 총량 수십~수백 MB. write 빈도 매우 낮음(토큰 갱신·영양제 수정 정도).

후보:
- **SQLite + Litestream**: 단일 파일 DB, 1초 단위 R2/S3 백업으로 단일 노드 약점 보완
- **Fly Postgres**: 관리형, ~$5/mo + 볼륨, 오버스펙
- **Neon Postgres**: 서버리스, 한국 리전 없음(레이턴시 200ms+), 익숙함

Pill Pouch는 솔로 V1, write 가벼움, 단일 노드로 충분 → SQLite가 자연스러움. 단일 파일 손실 위험은 Litestream 사이드카로 해결(WAL을 1초 단위로 오브젝트 스토리지에 백업, PITR 가능).

## Decision
- **DB 엔진**: SQLite (WAL 모드)
- **Rust 액세스**: `sqlx` (compile-time checked queries)
- **백업**: [Litestream](https://litestream.io/) 사이드카 컨테이너
- **백업 대상**: Cloudflare R2 (S3 호환, 송신 무료)
- **마이그레이션**: `sqlx-cli` (`server/migrations/`)
- **시작 흐름**: `litestream restore` → Axum 부팅

## Consequences

### 긍정
- 비용 ~$0.10/년 (R2 스토리지만)
- 쿼리 마이크로초 (네트워크 0)
- 운영 부담 최소 (백업/업그레이드/vacuum 자동 또는 minimal)
- PITR로 임의 시점 복구 (`litestream restore`)
- Fly.io 공식 가이드 + Litestream 제작자가 Fly 합류 → 호환성 안정적

### 부정 / 트레이드오프
- **단일 노드**: 동시 쓰기 1개, 수평 확장 어려움 (V1엔 무관)
- 서버 VM 폭파 시 재시작 필요 (downtime ~1분, Litestream restore 후 시작)
- Postgres의 풍부한 기능(JSONB, full-text 등) 미사용 (필요할 때 마이그레이션)

### 재검토 조건
- 사용자 10만 명+ 또는 동시 write 폭증 시 Postgres 검토 (V2)
- HA(고가용성)가 비즈니스 요구가 될 때

## 참고
- Plan §DB 비교 + 설명 대화
- `docs/runbooks/litestream-restore.md` (W3에서 채움)
