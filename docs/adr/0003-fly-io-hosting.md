# ADR-0003: Fly.io 호스팅 (도쿄 리전)

## Status
Accepted — 2026-04-27

## Context
백엔드 호스팅. PTS 푸시 스케줄러는 한국 사용자의 슬롯 시각(아침 8시 등)에 맞춰 정확히 발송해야 하므로 **레이턴시 중요**.

후보:
- **Fly.io**: 도쿄(NRT) 리전 존재, Litestream 공식 가이드, Rust micro VM 친화, $2~$5/mo
- **Railway**: GitHub 연결만으로 자동 배포, US 리전만 → 한국 200~250ms, $5~$10/mo
- **Shuttle.dev**: Rust 전용 PaaS, infra-from-code, 신생

선택 기준: 한국 레이턴시 + Litestream 호환 + 비용.

## Decision
- **플랫폼**: Fly.io
- **리전**: `nrt` (도쿄) — 한국 사용자 50~80ms
- **머신**: shared-cpu-1x 256MB (Rust 백엔드 충분)
- **볼륨**: 1GB (`/data`, SQLite + WAL 보관)
- **빌드**: Multi-stage Dockerfile (`rust:1.83-slim` → `gcr.io/distroless/cc-debian12`)
- **배포**: `flyctl deploy` (GitHub Actions로 main push 시 자동, FLY_API_TOKEN secret)
- **시크릿**: Fly secrets (APNs `.p8`, R2 자격증명)
- **사이드카**: Litestream replicate

## Consequences

### 긍정
- 도쿄 리전 = 한국 사용자 푸시 발송 레이턴시 50~80ms (Railway US 대비 ~150ms 절감)
- Litestream 공식 가이드 + 제작자가 Fly 합류 → 호환성 안정적
- 비용 $2~$5/mo (Railway 대비 절감)
- shared-cpu-1x로 Rust micro VM 적합
- TLS 자동, autoscaling 옵션

### 부정 / 트레이드오프
- Fly 종속 (다른 PaaS로 이전 시 fly.toml/Dockerfile 일부 재구성)
- 무료 사용량 정책 변동 이력 있음 (모니터링 필요)
- macos-15 GitHub Actions runner와 별개의 deploy CI 필요

### 재검토 조건
- 사용자 10만+ 또는 multi-region 필요 시 별도 ADR
- Fly 정책/비용이 크게 변경될 때

## 참고
- Plan §호스팅 비용 비교
- `docs/runbooks/deploy.md` (W3에서 채움)
