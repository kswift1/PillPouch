# api.md — 클라↔서버 엔드포인트 명세

> **Status**: 진행 중. W3에서 채움. #31에서 recommendations + healthz, #18에서 categories + category icon static hosting 박제.

## 박제 완료 엔드포인트 (v1)

| Method | Path | 용도 | 박제 PR |
|---|---|---|---|
| `GET` | `/healthz` | Service health check (응답: `"ok"`) | #31 |
| `GET` | `/v1/recommendations` | 인구통계 권장 영양제 전체 (Identity Anti-Promise §4 정합) | #31 |
| `GET` | `/v1/recommendations/:category` | 단일 카테고리 (404 if missing) | #31 |
| `GET` | `/v1/categories?since={version}` | 영양제 카테고리 카탈로그 증분 동기화 | #18 |
| `GET` | `/assets/category-icons/{key}.png` | 카테고리 아이콘 PNG 정적 서빙 | #18 |

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

### `/v1/categories` 응답 스키마

`since` query가 없으면 전체 카테고리, 있으면 `version > since` row만 반환한다. `serverVersion`은 항상 서버 전체 최신 버전이다.

```json
{
  "categories": [
    {
      "key": "omega3",
      "displayName": "오메가-3",
      "iconUrl": "/assets/category-icons/omega3.png",
      "displayOrder": 1,
      "version": 1,
      "updatedAt": 1777388476
    }
  ],
  "serverVersion": 1
}
```

V1.0 seed는 ADR-0007/#17 기준 16종이다. `iconUrl`은 같은 API host 기준 상대 URL이다. 모바일은 base URL과 결합해 다운로드하고, 실패 시 앱 번들 seed asset을 fallback으로 쓴다.

### `/assets/category-icons/{key}.png`

App static 자산. V1.0은 파일명이 version hash를 포함하지 않으므로 `Cache-Control: public, max-age=86400`을 사용한다.

## 예정 엔드포인트 (PTS / 기능 구현 트랙)

| Method | Path | 용도 | 예정 Issue |
|---|---|---|---|
| `POST` | `/v1/devices` | PTS 토큰 등록/갱신 | W3 별도 |
| `PATCH` | `/v1/devices/:id/timezone` | 타임존 변경 | W3 별도 |
| `POST` | `/v1/activities/:id/update-token` | Activity 시작 후 PU 토큰 등록 | W3 별도 |

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
