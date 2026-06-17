# ADR-0014: Railway 카테고리 이미지 호스팅

## Status
Accepted — 2026-06-17

Railway V1에서는 [ADR-0008: 카테고리 이미지 hosting](0008-category-image-hosting.md)의 Fly static 플랫폼 한정 결정을 supersede한다.

## Context

ADR-0008은 V1.0 카테고리 이미지를 Fly app에서 직접 서빙하기로 결정했다. 이 결정은 ADR-0003의 Fly.io hosting을 전제로 했다.

ADR-0012에서 V1 첫 백엔드 hosting 플랫폼을 Railway로 변경했다. 카테고리 이미지의 경로와 서빙 모델은 그대로 유지할 수 있다.

- public path: `/assets/category-icons/{key}.png`
- API 응답은 같은 host 기준 상대 `iconUrl`을 사용
- Axum이 Docker image에 동봉된 assets directory를 서빙
- 모바일은 다운로드 실패 시 앱 번들 seed asset으로 fallback

ADR-0008의 플랫폼명은 낡았지만, V1 규모에서는 S3/R2/CDN을 도입하지 않는다는 비용/복잡도 판단은 여전히 유효하다.

## Decision

V1 Railway 배포에서는 카테고리 이미지를 API container의 app static asset으로 서빙한다.

- `server/assets`를 Docker image에 동봉한다.
- Axum `ServeDir`로 `/assets/...`를 서빙한다.
- 파일명에 version hash가 없으므로 `Cache-Control: public, max-age=86400`을 유지한다.
- ADR-0008의 scale trigger 또는 production latency/cost 문제가 생기기 전까지 S3/R2/CDN은 scope 밖으로 둔다.

## Consequences

### 긍정

- Railway hosting 결정과 ADR-0008의 Fly-specific wording 사이 SoT 충돌을 제거한다.
- 이미 구현된 API contract를 바꾸지 않는다.
- V1에 별도 object storage/CDN 운영 표면을 추가하지 않는다.

### 부정 / 트레이드오프

- 정적 자산 availability가 Railway API service에 묶인다.
- Fly 기준 latency/resource 가정은 Railway region/edge 동작으로 대체된다.
- SKU/image 수가 커지면 ADR-0008의 CDN 재검토 기준을 다시 측정해야 한다.

### 재검토 조건

다음 중 하나라도 발생하면 S3/R2/CDN 또는 별도 asset host를 재검토한다.

- 월 이미지 대역폭이 ADR-0008 기준을 넘음
- static serving이 API CPU/memory에 유의미한 영향을 줌
- 첫 이미지 다운로드 p95가 제품 목표를 넘음
- SKU/image catalog 규모 때문에 image-bundled deploy가 무거워짐

## 참조

- [ADR-0008: 카테고리 이미지 hosting](0008-category-image-hosting.md)
- [ADR-0012: Railway 호스팅](0012-railway-hosting.md)
- [docs/api.md](../api.md)
