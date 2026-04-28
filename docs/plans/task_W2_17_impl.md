# task_W2_17_impl — 카테고리 12종 시드 자산 + JSON 동봉

- **Issue**: [#17](https://github.com/kswift1/PillPouch/issues/17)
- **Size**: M
- **Branch**: `kswift1/issue-17-seed-assets`
- **Milestone**: W2
- **의존**: #15 머지(✅), #11 머지(✅), #16 OPEN — 자산 자체는 #16 무관 병렬

## 목표
ADR-0007 12종 카테고리 대표 이미지 + 시드 JSON을 앱 번들에 동봉. `CategoryMirror` import 코드는 #16 의존이라 본 task 비포함.

## Scope

### 1. 스크립트 재활용 rename (ADR-0007 §Migration)
- `scripts/imageset-capsules.sh` → `scripts/imageset-categories.sh` (RAW_DIR/ASSET_DIR/SPEC 경로만 categories로 교체, 로직 동일)
- `scripts/capsule-spec.json` → `scripts/category-spec.json` (12종 entry, 전부 `ratio: "1:1"`, base_size 128 유지)
- `design/capsules/` → `design/categories/`
- `design/capsules/raw/tablet.png` → `design/categories/raw/other.png` (generic pill = 기타 폴백 재활용)

### 2. 자산 12장 등록
- 작업지시자: GPT Image 2 v4 톤(매트 베이지 3D, photoreal 회피, 공통 잠금 블록)으로 11장 생성 → `design/categories/raw/{key}.png` (≥1024px)
  - 카테고리별 subject 후보:
    - `omega3`: 어유 캡슐
    - `vitaminC`: 시트러스
    - `vitaminD`: 햇살/방울
    - `vitaminB`: 곡물 알갱이
    - `multivitamin`: 다색 정제 묶음
    - `calciumMagnesium`: 흰 정제 + 미네랄 결정
    - `probiotics`: 요거트 컵 / 캡슐 안 미생물 추상
    - `iron`: 짙은 적갈색 정제
    - `zinc`: 메탈릭 회색 정제
    - `lutein`: 옐로우 소프트젤 + 잎
    - `collagen`: 하늘색 소프트젤 + 탄력 모티프
- `other.png` = #11 tablet.png 재활용 (시리즈 일관성 깨지면 v4 톤으로 재생성)
- Claude: `./scripts/imageset-categories.sh` 일괄 실행 → `ios/PillPouch/Assets.xcassets/Categories/{key}.imageset/` × 12 생성·커밋

### 3. 시드 JSON 동봉
- `ios/PillPouch/Resources/category-seed.json` 신규 (12 row, key/displayName/iconAssetName/displayOrder/version)
- `displayOrder`는 ADR-0007 §카테고리 표 순서(omega3=1 … other=12)
- `version=1` 통일 (V1.0 시드 베이스라인)
- `PBXFileSystemSynchronizedRootGroup` 사용 → 폴더 추가만으로 Xcode 자동 인식, pbxproj 편집 불필요

### 4. 빌드 검증
- `xcodebuild build` + `xcodebuild test` 통과
- 임시 SwiftUI Preview로 12종 그리드 스크린샷 → `docs/screenshots/category-seed/grid.png` + 32pt 식별성 단독 스크린샷 → 작업지시자 검증
- Preview 코드는 검증 후 제거 (merge에 남기지 않음)

## 비포함 (별도 task)
- ❌ `CategoryMirror @Model` 정의 → #16
- ❌ 시드 JSON → SwiftData import 코드 → #16 머지 후 별도 PR
- ❌ 서버 endpoint, mirror 동기화 → #(d), #(e)

## 가설 B 정합성
가설 B 강화 무관 — 시각/UX 인프라. Non-goals 위반 없음.

## Done 게이트
- [ ] 12 `Assets.xcassets/Categories/{key}.imageset/` 등록 + `Contents.json` 12개
- [ ] `category-seed.json` 12 row
- [ ] `imageset-categories.sh` + `category-spec.json` rename 완료, 기존 capsules 스크립트/spec/raw 삭제
- [ ] `xcodebuild build` + `xcodebuild test` 통과
- [ ] 12종 그리드 + 32pt 식별성 스크린샷 PR 본문 첨부 → 작업지시자 시리즈 일관성 검증 ⛔

## 작업 흐름
1. AI: 스크립트/spec rename + 폴더 rename + `category-seed.json` 셸 생성 → 1차 커밋 (raw 12장 미존재 상태)
2. 작업지시자: GPT Image 2로 11장(omega3~collagen) 생성 → `design/categories/raw/`에 추가
3. AI: `./scripts/imageset-categories.sh` 일괄 실행 → 12 imageset 커밋 + 빌드/테스트 검증 + 그리드 Preview 스크린샷
4. PR 단일 제출 → Done 게이트 ⛔
