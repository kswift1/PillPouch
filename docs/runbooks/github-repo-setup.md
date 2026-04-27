# github-repo-setup.md — GitHub repo 메타 셋업

> GitHub repo의 메타 설정(가시성, 라벨, 마일스톤, 머지 옵션, branch protection)은
> git history에 남지 않는다. 이 runbook이 **단일 소스(SoT)** — 변경 시 반드시 갱신.

repo: [kswift1/PillPouch](https://github.com/kswift1/PillPouch)

---

## 1. 가시성

**현재**: `PUBLIC`
- 2026-04-27: PRIVATE → PUBLIC 전환 (사유: branch protection 사용을 위해 — GitHub Free + private은 protection 차단)
- 영향: 코드/기획서 모두 공개. App Store 출시 후 큰 변화 없음.

복구/변경:
```bash
gh repo edit kswift1/PillPouch --visibility private --accept-visibility-change-consequences
```

---

## 2. 머지 옵션 (Settings → General → Pull Requests)

**현재** (2026-04-27 적용):
| 옵션 | 값 |
|---|---|
| `squashMergeAllowed` | **true** |
| `mergeCommitAllowed` | false |
| `rebaseMergeAllowed` | false |
| `deleteBranchOnMerge` | true |

→ Squash merge **only**. 머지 후 브랜치 자동 삭제.

복구/변경:
```bash
gh repo edit kswift1/PillPouch \
  --enable-squash-merge \
  --enable-merge-commit=false \
  --enable-rebase-merge=false \
  --delete-branch-on-merge
```

---

## 3. 마일스톤 (Issues → Milestones)

**현재** (2026-04-27 생성):
| 번호 | 제목 |
|---|---|
| 1 | W1 |
| 2 | W2 |
| 3 | W3 |
| 4 | W4 |
| 5 | W5 |
| 6 | W6 |
| 7 | V1.0 |
| 8 | V1.1 |

생성/복구:
```bash
for ms in W1 W2 W3 W4 W5 W6 V1.0 V1.1; do
  gh api -X POST repos/kswift1/PillPouch/milestones -f title="$ms"
done
```

---

## 4. 라벨 (Issues → Labels)

GitHub 기본 9개 라벨 + 추가 14개:

**size (3종)**:
| 라벨 | 색 | 의미 |
|---|---|---|
| `size:S` | `#c2e0c6` | 반나절 미만, PR 본문만 |
| `size:M` | `#fbca04` | 반나절~3일, 구현계획서+최종보고서 |
| `size:L` | `#d93f0b` | 3일~1주, 풀 RHWP 사이클 |

**area (5종)**:
| 라벨 | 색 | 의미 |
|---|---|---|
| `area:ios` | `#1d76db` | iOS 클라이언트 |
| `area:server` | `#5319e7` | Rust 백엔드 |
| `area:docs` | `#0075ca` | 문서 |
| `area:infra` | `#006b75` | Fly.io / CI / 인프라 |
| `area:design` | `#f9d0c4` | 디자인 시스템 / 자산 |

**type (6종, Conventional Commits 매칭)**:
| 라벨 | 색 | 의미 |
|---|---|---|
| `type:feat` | `#0e8a16` | 신규 기능 |
| `type:fix` | `#b60205` | 버그 수정 |
| `type:chore` | `#ededed` | 유지보수, 의존성, 빌드 |
| `type:refactor` | `#bfd4f2` | 리팩토링 |
| `type:test` | `#fef2c0` | 테스트 추가/수정 |
| `type:docs` | `#c5def5` | 문서 변경 |

생성/복구:
```bash
gh label create "size:S" --color "c2e0c6" --description "반나절 미만, PR 본문만" --repo kswift1/PillPouch
gh label create "size:M" --color "fbca04" --description "반나절~3일, 구현계획서+최종보고서" --repo kswift1/PillPouch
gh label create "size:L" --color "d93f0b" --description "3일~1주, 풀 RHWP 사이클" --repo kswift1/PillPouch
gh label create "area:ios" --color "1d76db" --description "iOS 클라이언트" --repo kswift1/PillPouch
gh label create "area:server" --color "5319e7" --description "Rust 백엔드" --repo kswift1/PillPouch
gh label create "area:docs" --color "0075ca" --description "문서" --repo kswift1/PillPouch
gh label create "area:infra" --color "006b75" --description "Fly.io / CI / 인프라" --repo kswift1/PillPouch
gh label create "area:design" --color "f9d0c4" --description "디자인 시스템 / 자산" --repo kswift1/PillPouch
gh label create "type:feat" --color "0e8a16" --description "신규 기능" --repo kswift1/PillPouch
gh label create "type:fix" --color "b60205" --description "버그 수정" --repo kswift1/PillPouch
gh label create "type:chore" --color "ededed" --description "유지보수, 의존성, 빌드" --repo kswift1/PillPouch
gh label create "type:refactor" --color "bfd4f2" --description "리팩토링" --repo kswift1/PillPouch
gh label create "type:test" --color "fef2c0" --description "테스트 추가/수정" --repo kswift1/PillPouch
gh label create "type:docs" --color "c5def5" --description "문서 변경" --repo kswift1/PillPouch
```

---

## 5. Branch protection — `main`

**현재** (2026-04-27 적용, public 전환 후):

| 룰 | 값 | 효과 |
|---|---|---|
| `required_pull_request_reviews` | `{required_approving_review_count: 0}` | **PR 머지 강제** (직접 push 금지). 솔로라 review 0명만 필요 |
| `allow_force_pushes` | **false** | force push 차단 (history rewrite 방지) |
| `allow_deletions` | **false** | branch 삭제 차단 |
| `required_linear_history` | **true** | linear history 강제 (squash merge라 자연 충족) |
| `enforce_admins` | false | admin(=본인)은 우회 가능 — 자기 실수 방지 정도 |
| `required_status_checks` | **null** | CI 통과 강제 X (paths 필터와 충돌 회피, W3에서 재검토) |

이유:
- **솔로 + AI 페어**: PR 강제만으로 self-discipline + AI 가드레일 (CLAUDE.md) 충분
- **paths 필터 충돌**: docs-only PR이면 ios-build/server-build skip → required check이 missing이라 머지 차단되는 함정. 회피.
- W3에 paths 필터 제거 + required checks 활성화 검토 (별도 ADR)

복구/재설정:
```bash
cat <<'EOF' | gh api -X PUT --input - repos/kswift1/PillPouch/branches/main/protection
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": false,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 0
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_linear_history": true
}
EOF
```

검증:
```bash
gh api repos/kswift1/PillPouch/branches/main/protection
```

---

## 6. 변경 이력

| 날짜 | 변경 | 사유 / PR |
|---|---|---|
| 2026-04-27 | 가시성 PRIVATE → PUBLIC | branch protection 사용 (GitHub Free 제약) — PR #4 |
| 2026-04-27 | Squash merge only 설정 | task #1 사전 셋업 |
| 2026-04-27 | 마일스톤 8개 (W1~W6, V1.0/V1.1) 생성 | task #1 사전 셋업 |
| 2026-04-27 | 라벨 14개 (size×3, area×5, type×6) 추가 | task #1 사전 셋업 |
| 2026-04-27 | main branch protection 활성화 | PR #4 |

---

## 변경 시 룰

1. GitHub UI 또는 `gh` 명령으로 메타 변경
2. **즉시 이 runbook 갱신** (변경 이력 표 + 해당 섹션)
3. PR로 commit (변경의 사유 명시)
