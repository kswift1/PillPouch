# task_W3_37_stage0.md - ADR/계획 정합 단계보고서

## 메타

| 항목 | 값 |
|---|---|
| Issue | [#37](https://github.com/kswift1/PillPouch/issues/37) |
| Stage | 0 - ADR/계획 정합 |
| 작성일 | 2026-06-17 |

## 한 일

- Railway 전환 결정을 신규 ADR로 박제했다.
  - `docs/adr/0012-railway-hosting.md`
- 기존 Fly 호스팅 ADR은 본문을 고치지 않고 status만 supersede로 변경했다.
  - `docs/adr/0003-fly-io-hosting.md`
- ADR index를 최신화했다.
  - `docs/adr/README.md`

## 결정 요약

- V1 백엔드 첫 운영 호스팅은 Railway로 변경한다.
- 이유는 작업지시자가 Railway Hobby plan에 이미 월 $5를 지불 중이기 때문이다.
- Fly 도쿄 리전의 latency 장점은 인정하지만, 현재 W3 서버 surface는 read-heavy endpoint 중심이다.
- PTS/device endpoint 구현 후 발송 정확도나 latency가 실제 문제가 되면 Fly 또는 Asia region을 재검토한다.

## 확인한 현재 상태

- Railway CLI 설치됨: `railway 4.59.0`
- Railway CLI auth 만료: `railway login` 필요
- 현재 workspace는 Railway project에 link되어 있지 않음: `railway link` 필요

## 계획/이슈 mismatch

Issue #37 제목과 본문은 Fly.io 첫 배포를 기준으로 되어 있다. 이번 Stage 0에서 ADR-0012로 Railway 전환을 박제했으므로, 이후 보고서와 PR 본문에는 "#37은 Railway 배포로 scope 보정"을 명시한다.

## 검증

- 문서 생성/수정만 수행했다.
- 서버 코드, Dockerfile, Railway config는 아직 수정하지 않았다.
- Stage 1 진입 전 작업지시자 승인이 필요하다.

## 다음 단계

Stage 1에서 다음을 구현한다.

- `server/crates/api/src/main.rs`가 Railway `PORT`를 fallback으로 읽게 수정
- `server/Dockerfile`
- `server/.dockerignore`
- local Docker smoke test

## 승인 요청

Stage 1 진행 승인 필요.
