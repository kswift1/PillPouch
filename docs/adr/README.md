# ADR — Architecture Decision Records

5분 안에 읽히는 의사결정 기록. 한 ADR = 한 결정.

## 형식
```markdown
# ADR-NNNN: 제목

## Status
Accepted | Superseded by ADR-XXXX | Deprecated

## Context
왜 이 결정이 필요한가?

## Decision
무엇을 결정했나?

## Consequences
긍정/부정 결과, 트레이드오프.
```

## 목록

- [x] [ADR-0001: Rust + Axum 백엔드](0001-rust-axum-backend.md)
- [x] [ADR-0002: SQLite + Litestream](0002-sqlite-litestream.md)
- [x] [ADR-0003: Fly.io 호스팅](0003-fly-io-hosting.md)
- [x] [ADR-0004: Monorepo](0004-monorepo.md)
- [x] [ADR-0005: SwiftUI 네이티브 (TCA 미사용)](0005-no-tca-swiftui-native.md)
- [x] [ADR-0006: Hyper-Waterfall 적응형 (S/M/L)](0006-hyper-waterfall-adaptive.md)
- [x] [ADR-0007: 영양제 카테고리 카탈로그 — 서버 SoT](0007-server-catalog-as-source-of-truth.md)
- [x] [ADR-0008: 카테고리 이미지 hosting — V1.0 Fly static](0008-category-image-hosting.md)
- [x] [ADR-0009: 봉지 찢기 제스처 — top → middle perforation](0009-tear-gesture-middle-perforation.md)

## 변경 룰
ADR은 한번 Accepted되면 수정 X. 결정이 바뀌면 새 ADR로 Supersede.
