# ADR-0008: 카테고리 이미지 hosting — V1.0 Fly static, V1.1 재평가

## Status
Accepted — 2026-04-28

## Context

[ADR-0007](0007-server-catalog-as-source-of-truth.md)에서 영양제 카테고리 카탈로그를 서버 SoT로 결정. 카테고리 row마다 대표 이미지가 필요하고, 이 이미지를 어디서 hosting할지 별도 결정이 필요.

서버 SoT로 가는 이상 이미지는 백엔드 인프라 안에서 서빙되어야 함 (App Store 배포 없이 update 가능 — ADR-0007의 핵심 가치).

후보:

- **Fly static** — Fly 앱이 정적 파일을 직접 서빙 (`/assets/...` 경로). 매 요청 = Fly 머신이 응답 (CPU/메모리 점유). 지리적 캐싱 X. 대역폭이 Fly 청구서에 합쳐짐.
- **S3 + CloudFront** — 정적 파일을 S3에 두고 CDN edge 캐싱. Fly 앱은 catalog 메타 endpoint만 책임. 지리적 캐싱 ✅. 대역폭 효율 ↑.
- **Cloudflare R2 + Cloudflare CDN** — egress 무료, 비용 효율 ↑. AWS 외 인프라 도입 비용.

V1.0/V1.1 규모 추정:
- **V1.0**: 12장 × 평균 100KB ≈ 1.2MB 총. DAU 100명 × 첫 실행 1회 = 월 4MB 대역폭.
- **V1.1**: SKU 1000개 × 평균 200KB ≈ 200MB 총. DAU 1000명 × 평균 5장 신규 다운로드 = 월 1GB.
- **V2 (가정)**: SKU 5000개 + DAU 10K = 월 50GB+.

월 대역폭 휴리스틱:
- < 5GB → Fly static 무난
- 5~50GB → 결정 미묘 (Fly로 견딜 수 있지만 S3 안전)
- \> 50GB → CDN 필수

V1.0 1.2MB 총 사이즈 + 월 4MB 대역폭은 CDN 도입 정당화 한참 미달. V1.1 시점도 월 1GB로 Fly가 견딜 수 있는 영역.

## Decision

**V1.0: Fly static 채택**.

### V1.0 인프라

- 카테고리 이미지 12장을 Fly 앱 docker image에 동봉 또는 Fly volume에 마운트
- 경로: `/assets/category-icons/{key}.png` (key = ADR-0007의 lowerCamel id)
- Axum의 `tower_http::services::ServeDir` 또는 `axum::Router::nest_service`로 정적 서빙
- `Cache-Control: public, max-age=31536000, immutable` (이미지 파일명에 version hash 포함 시) 또는 `max-age=86400` (단순 path)
- 모바일 클라이언트는 `iconRemoteURL: "https://api.pillpouch.app/assets/category-icons/omega3.png"` 형태로 mirror에 저장 후 다운로드 + 로컬 path 캐시

### 시드 동봉 (앱 번들)

V1.0 12장은 Fly + 앱 번들 **둘 다**에 동봉:
- 앱 번들: 첫 실행 즉시 사용 (네트워크 무관, UX 회귀 회피)
- Fly: 백그라운드 동기화 시 보강 또는 update 시 갱신
- 모바일은 다운로드 이미지가 있으면 그걸 우선 사용, 없으면 번들 시드 fallback

### V1.1 재평가 트리거

다음 중 하나라도 만족 시 S3 + CDN 마이그레이션 ADR 작성:
- **월 총 이미지 대역폭 > 50GB** 측정
- **Fly 머신 CPU/메모리가 정적 서빙으로 5%+ 점유** 측정
- **사용자 첫 이미지 다운로드 p95 > 2초** 측정 (지리적 거리 영향 시)
- **SKU 5000+ row 도입** (자산 총 사이즈 1GB+)

마이그레이션 비용 추정: 1~2일 (S3 업로드 스크립트 + Axum 정적 서빙 제거 + endpoint URL 갱신). 모바일은 mirror에 `iconRemoteURL` 갱신만 받으면 자동 적용 — 클라 변경 0.

### 대안으로 Cloudflare R2

V1.1 시점에 S3 vs R2 비교 ADR 작성. R2는 egress 무료라 사용자 다운로드 패턴이 큰 우리 use case에 매력적. AWS 외 인프라 도입 비용 vs 장기 운영비 절감 비교.

## Consequences

### 긍정
- V1.0 인프라 단순 — 추가 AWS 계정/CloudFront 셋업 불필요
- Fly 단일 cluster에 백엔드 + 정적 자산 통합 → 운영 표면 작음
- 12장 작은 사이즈 + 낮은 DAU → CDN 부재 영향 미미
- 시드 동봉으로 첫 실행 UX 즉시 동작
- V1.1 마이그레이션 비용 낮음 (모바일 변경 0)

### 부정 / 트레이드오프
- 지리적 캐싱 부재 — 한국 외 지역 사용자는 Fly region에서 직접 받음 (V1.0은 한국 시장 한정이라 영향 없음)
- Fly 앱 다운/배포 시 정적 자산 동시 일시 중단 — 시드 동봉으로 완전 차단 회피
- V1.1 SKU 1000+ 시점에 재평가 필요 — 측정 셋업 부담 (Fly 머신 metric, p95 다운로드 latency)
- Fly volume 사용 시 단일 region 종속 — 멀티 region 확장 시 자산 동기화 별도 결정

### 위험
- Fly static 한계 측정 누락 → 사용자 체감 latency 증가 인지 못함. **완화**: 모바일에 다운로드 시간 telemetry 추가 (V1.0 후반 또는 V1.1 초반).
- 시드 동봉으로 V1.0 앱 번들 사이즈 ~수 MB 증가 — 사용자 첫 다운로드 비용. 12장이면 1~2MB 수준이라 미미.
- Fly 정적 서빙에 `Cache-Control` 잘못 설정 → 사용자 캐시 누락 또는 stale. **완화**: 본 ADR 머지 후 운영 PR 시 `Cache-Control` 명시 검증 + 변경 이력 박제.

## 후속 결정

- V1.1에 위 트리거 조건 측정 + 도달 시 S3/R2 마이그레이션 ADR 작성
- 시드 12장 PNG는 ADR-0007 issue (c)에서 작업지시자 GPT Image 2 v4 톤 시리즈 생성 + Claude imageset 변환 흐름으로 박제

## 참조
- ADR-0001 Rust + Axum 백엔드
- ADR-0003 Fly.io hosting
- ADR-0007 영양제 카테고리 카탈로그 — 서버 SoT
- 기획서 §시각 언어 (`docs/brief.md`)
