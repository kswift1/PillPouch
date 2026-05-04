# api.md — 클라↔서버 엔드포인트 명세

> **Status**: 진행 중. W3에서 채움. 본 PR (#31)에서 recommendations + healthz 박제.

## 박제 완료 엔드포인트 (v1)

| Method | Path | 용도 | 박제 PR |
|---|---|---|---|
| `GET` | `/healthz` | Fly health check (응답: `"ok"`) | #31 |
| `GET` | `/v1/recommendations` | 인구통계 권장 영양제 전체 (Identity Anti-Promise §4 정합) | #31 |
| `GET` | `/v1/recommendations/:category` | 단일 카테고리 (404 if missing) | #31 |

### `/v1/recommendations` 응답 스키마

```json
{
  "recommendations": [
    {
      "category": "male_20s_30s",
      "display_name": "20~30대 남성",
      "supplements": [
        { "name": "비타민 D", "reason": "한국인 평균 부족", "priority": 1 }
      ],
      "source": "식약처 KDRIs / ...",
      "disclaimer": "인구통계 기반 일반 정보. 개인 진단·처방 X.",
      "updated_at": 1762300000
    }
  ]
}
```

`/v1/recommendations/:category` 는 위 객체 하나 그대로 반환 (wrapper 없음).

## 예정 엔드포인트 (PTS / 기능 구현 트랙)

| Method | Path | 용도 | 예정 Issue |
|---|---|---|---|
| `POST` | `/v1/devices` | PTS 토큰 등록/갱신 | W3 별도 |
| `PATCH` | `/v1/devices/:id/timezone` | 타임존 변경 | W3 별도 |
| `POST` | `/v1/activities/:id/update-token` | Activity 시작 후 PU 토큰 등록 | W3 별도 |
| `GET` | `/v1/categories` | 영양제 카테고리 카탈로그 | #18 |

## 인증 정책

본 PR (#31) endpoint는 **public read-only** — 카테고리별 권장 영양제는 일반 정보로 외부 송신 무관. 추후 admin endpoint(seed write 등) 추가 시 별도 ADR.

## 에러 응답

```json
{ "error": "category not found: missing" }
```

| Status | 의미 |
|---|---|
| 200 | OK |
| 404 | 카테고리 미존재 |
| 500 | Storage / JSON 실패 (서버 로그에 상세 박제) |

## TODO
- [ ] OpenAPI / JSON Schema 자동 생성
- [ ] 인증 정책 정식 박제 (PTS endpoint 시점)
- [ ] APNs 페이로드 ContentState 스키마
