# CONTRIBUTING — Pill Pouch 작업 사이클

이 프로젝트는 **Hyper-Waterfall 적응형(RHWP)** 방법론으로 개발한다.
참고: [edwardkim/rhwp](https://github.com/edwardkim/rhwp) — 솔로 V1 6주 일정에 맞게 경량화.

AI 페어 프로그래밍 가드레일은 [`CLAUDE.md`](CLAUDE.md). 사람도 같은 룰을 따른다.

---

## 1. 핵심 원칙

1. **모든 계획은 검토되고, 모든 결과물은 검증된다.**
2. **모든 결정의 뒤에는 사람이 있다.**
3. **승인 없이 다음 단계 진행 금지.**
4. **임시방편/우회 금지** — 막히면 troubleshooting 기록 후 에스컬레이션.

---

## 2. 태스크 분류 (S/M/L)

| 크기 | 시간 | 예시 | 문서 | 승인 게이트 |
|---|---|---|---|---|
| **S** | 반나절 미만 | 오타, 작은 버그, lint, 의존성 업데이트 | PR 본문만 | PR 리뷰 1회 |
| **M** | 반나절~3일 | 1개 화면, 1개 API, 1개 모델, CRUD | 구현계획서 + 최종보고서 | 2회 (계획·최종) |
| **L** | 3일~1주 | 큰 통합, 위험 작업 (백엔드 PTS E2E, Live Activity 통합) | 수행계획서 + 구현계획서 + 단계보고서 + 최종보고서 | 3+회 (계획·단계별·최종) |

**판단 기준: 불확실성.** 기능이 커도 패턴이 명확하면 M, 작아도 위험하면 L.
모르겠으면 작업지시자에게 분류 묻기.

---

## 3. 태스크 사이클

### 3.1 공통 (S/M/L)

```
GitHub Issue 등록 → 브랜치 생성 → (계획서) → 구현 → (보고서) → PR Squash merge → Issue close
```

**브랜치명**: `local/task{이슈번호}` (예: `local/task42`)
**커밋 컨벤션**: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`, `ci:`)
**머지 방식**: Squash merge **only** (repo 설정 강제)

### 3.2 S 사이클

```
1. Issue 등록 (size:S, area:*, type:*, milestone)
2. 브랜치 local/task{N}
3. 구현
4. PR 생성 (본문에 한두 줄 설명 + Closes #N)
5. CI 통과 → Squash merge
```

### 3.3 M 사이클

```
1. Issue 등록 (size:M, area:*, type:*, milestone)
2. 브랜치 local/task{N}
3. docs/plans/task_W{N}_{이슈}_impl.md 작성
4. ⛔ 작업지시자 승인 ⛔
5. 구현 (Conventional Commits 단위로 커밋)
6. CI 통과
7. docs/report/task_W{N}_{이슈}_report.md 작성
8. ⛔ 작업지시자 승인 ⛔
9. PR 생성 (본문에 계획서·보고서 링크 + 가설 체크 + Closes #N)
10. Squash merge
```

### 3.4 L 사이클

M에 추가:

```
1~2. (Issue, 브랜치)
3. docs/plans/task_W{N}_{이슈}.md (수행계획서) 작성
4. ⛔ 승인 ⛔
5. docs/plans/task_W{N}_{이슈}_impl.md (구현계획서, 3~6단계로 쪼갬) 작성
6. ⛔ 승인 ⛔
7. 단계1 구현 → 커밋
8. docs/working/task_W{N}_{이슈}_stage1.md 작성
9. ⛔ 단계1 승인 ⛔
10. 단계2 구현 → 커밋
11. docs/working/task_W{N}_{이슈}_stage2.md
12. ⛔ 단계2 승인 ⛔
... (단계마다 반복)
N. 모든 단계 완료 → docs/report/task_W{N}_{이슈}_report.md
N+1. ⛔ 최종 승인 ⛔
N+2. PR Squash merge
```

L 태스크는 PR 1개에 단계별 커밋이 쌓이고, squash merge로 main에 1커밋.

---

## 4. 문서 종류 (`docs/`)

자세한 건 [`docs/README.md`](docs/README.md).

| 폴더 | 작성 시점 | 작성자 | 승인 |
|---|---|---|---|
| `plans/` | 태스크 시작 전 | AI | 필수 |
| `working/` | L 단계 완료 후 | AI | 필수 |
| `report/` | 태스크 완료 시 | AI | 필수 |
| `feedback/` | 보고서 검토 후 | **사람만** | — |
| `orders/` | 매일 아침 | 사람/AI | — |
| `tech/` | 기술 조사 발견 시 | AI/사람 | — |
| `troubleshootings/` | 문제 해결 후 | AI/사람 | — |
| `adr/` | 결정 시점 | AI/사람 | 필수 (사람 review) |
| `runbooks/` | 운영 절차 정리 시 | AI/사람 | — |

---

## 5. 일일 운영

- **매일 시작**: `docs/orders/yyyymmdd.md` 작성 (오늘 할일 1~3줄)
- **매일 종료**: 같은 파일에 회고 추가 (막힌 것/배운 것)
- **주차 종료**: `docs/plan/week-NN.md` 통합 회고

---

## 6. PR 작성

- **PR 템플릿** ([`.github/pull_request_template.md`](.github/pull_request_template.md))은 자동 로드
- 필수 섹션: Why / What / Test plan / Linked docs / 가설 검증 체크
- UI 변경: Snapshot PNG 첨부 (`docs/screenshots/<feature>/`)
- PR 사이즈 **+500 LOC 넘으면 분할 고민** (강제는 아님)

---

## 7. CI / 머지 룰

- **PR 머지 전 CI 통과 필수** (테스트 실패 시 자동 차단)
- iOS: `xcodebuild test`
- Rust: `cargo fmt --check && cargo clippy -- -D warnings && cargo test`
- 시크릿 누출 검사 (gitleaks, 추후 추가)

---

## 8. 가설 보호 (Pill Pouch 정체성)

기획서 §핵심 가설 B를 약화하는 변경은 **거부**. 매력적인 시각/기능이라도.

PR 템플릿에 체크 박스로 강제:
- [ ] 이 변경은 가설 B(기록 신뢰성)를 강화한다
- [ ] Non-goals에 해당하지 않는다

체크 안 되면 ADR 작성 후 작업지시자 승인 필요.

---

## 9. 환경 셋업

### iOS
- Xcode 16+ (Swift Testing)
- iOS 17.2+ 시뮬레이터 (Push to Start)

### 서버
- Rust stable (1.83+)
- (W3부터) Fly CLI, sqlx-cli

### 시크릿
- `.env` (로컬), Fly secrets (프로덕션). 절대 git X.
- APNs `.p8` 원본은 1Password/Keychain. Fly secrets에 주입.

---

## 10. 참고

- 기획서: [`docs/brief.md`](docs/brief.md)
- 마일스톤: [`docs/plan/milestones.md`](docs/plan/milestones.md)
- AI 가드레일: [`CLAUDE.md`](CLAUDE.md)
- 방법론 원본: [edwardkim/rhwp](https://github.com/edwardkim/rhwp)
