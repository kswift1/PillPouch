# ADR-0004: Monorepo

## Status
Accepted — 2026-04-27

## Context
iOS 앱(Swift) + 백엔드(Rust) + 문서(Markdown) 3종을 어떻게 git 단위로 분리할지.

후보:
- **Monorepo**: `pillpouch/` 한 repo에 `ios/`, `server/`, `docs/`, `design/` 폴더 분리
- **분리 repo**: `pillpouch-ios`, `pillpouch-server` 별도
- **iOS만 git, 서버는 별도**: 점진적 분리

솔로 + AI 페어 컨텍스트:
- 한 PR에 클라+서버 변경(API 스키마 등) 묶기 가능
- AI 컨텍스트 단일화 (한 워크스페이스에서 모두 접근)
- Issue/Milestone 한 곳

V1엔 외부 사용자/협업자 없음. 권한 분리 필요 X.

## Decision
**Monorepo** — `kswift1/PillPouch` 한 repo:
```
pillpouch/
├── ios/          # SwiftUI 앱 + Widget Extension
├── server/       # Rust workspace (4 crate)
├── docs/         # 단일 소스 문서 (brief, ADR, runbooks, plans, ...)
├── design/       # 색 토큰, 봉지 SVG, Figma 익스포트
└── .github/      # workflows, ISSUE/PR 템플릿
```

CI: `paths` 필터로 `ios/**` / `server/**` 변경 시 각각 빌드(비용 절감).

## Consequences

### 긍정
- 단일 컨텍스트: PR/Issue/Milestone 한 곳, AI 세션이 모든 영역 접근
- 한 PR로 클라↔서버 협력 변경(API 스키마, ContentState 페이로드 등) 가능
- 공통 문서(`docs/brief.md`, ADR) 단일 소스
- 머지/리뷰 절차 통일

### 부정 / 트레이드오프
- repo size 증가 (V1 규모엔 무시 가능)
- iOS만 보는 외부 사용자에게 `server/` 노이즈 (V1엔 외부 사용자 X)
- 공개 후엔 서버 코드도 함께 노출 (이미 PUBLIC, 의도적)
- CI paths 필터로 docs-only PR이 모든 빌드 skip → Monitor 종료 조건에 별도 처리 필요 (이미 박제)

### 재검토 조건
- 협업자 합류 + 권한 분리 필요 (예: 외부 기여자에게 iOS만 공개) 시 분리 repo 검토
- 서버 부분이 다른 제품과 공유돼야 할 때

## 참고
- Plan §Repo 구조
- `docs/runbooks/github-repo-setup.md`
