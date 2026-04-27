# api.md — 클라↔서버 엔드포인트 명세

> **Status**: stub. W3에서 채움.

## 초기 엔드포인트 (예정)

| Method | Path | 용도 |
|---|---|---|
| `POST` | `/v1/devices` | PTS 토큰 등록/갱신 |
| `PATCH` | `/v1/devices/:id/timezone` | 타임존 변경 |
| `POST` | `/v1/activities/:id/update-token` | Activity 시작 후 PU 토큰 등록 |
| `GET` | `/healthz` | Fly health check |

## TODO
- [ ] 각 엔드포인트 Request/Response 스키마 (JSON Schema 또는 OpenAPI)
- [ ] 인증 정책 (API key? device-id 기반?)
- [ ] 에러 코드 표
- [ ] APNs 페이로드 ContentState 스키마
