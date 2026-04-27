# ADR-0001: Rust + Axum 백엔드

## Status
Accepted — 2026-04-27

## Context
기획서 v0.4 §기술 스택에서 V1.0에 백엔드(Push to Start) 포함 결정. APNs HTTP/2 발송 + 사용자 슬롯 스케줄러가 주된 책임. 후보 3개:

- **Vapor (Swift on Server)**: iOS와 모델/코드 공유, 컨텍스트 단일화
- **Bun + TypeScript**: 셋업 빠름, JS 생태계
- **Rust**: 성능, 메모리 안전, 작은 바이너리, 학습 가치

작업지시자 결정: **Rust** (성능 + 안정성 + Fly micro VM 친화 + 학습 가치 우선).

웹 프레임워크는 Axum 채택 (Tokio 팀, 사실상 표준, 학습 곡선 완만, tower 생태계).

## Decision
- **언어**: Rust stable (1.83+)
- **웹 프레임워크**: Axum
- **런타임**: Tokio
- **DB 액세스**: sqlx (compile-time checked queries)
- **미들웨어**: tower-http (trace, cors)
- **APNs 클라이언트**: `a2` 또는 `apns2` (W3에서 비교 후 별도 ADR로 박제)
- **로깅**: tracing + tracing-subscriber
- **타임존**: chrono + chrono-tz

Workspace 구조:
```
server/crates/
├── api       # Axum HTTP 라우터
├── pusher    # APNs HTTP/2 + 스케줄러
├── domain    # 순수 도메인 로직 (TDD 강제)
└── storage   # SQLite 액세스
```

Workspace lints: `unsafe_code = "forbid"`, `clippy::all = deny`, `clippy::pedantic = warn`.

## Consequences

### 긍정
- 메모리 안전 (`unsafe_code = "forbid"`)
- 작은 단일 바이너리 → Fly micro VM(256MB)에 적합
- 비동기 런타임 성숙 (Tokio)
- 강타입 + sqlx로 SQL 컴파일 타임 검증

### 부정 / 트레이드오프
- iOS(Swift)와 코드/모델 공유 X — Vapor 채택 시 가능했던 컨텍스트 단일화 손실
- Rust 학습/디버그 비용 (솔로 6주 일정에 영향 가능)
- crate 생태계가 Node/JS 대비 좁음 (특히 외부 SDK)

### 재검토 조건
- 솔로 일정 압박이 큰 경우 V1.1에서 Vapor/Bun으로 전환 검토
- 협업자 합류 후 Rust 인력 부재 시 재평가

## 참고
- 기획서 §기술 스택 — `docs/brief.md`
- Plan §결정사항 §기술 스택
