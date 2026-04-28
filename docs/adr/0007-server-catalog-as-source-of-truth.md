# ADR-0007: 영양제 카테고리 카탈로그 — 서버 SoT (클라 enum 폐기)

## Status
Accepted — 2026-04-28 (Amended same day: 12 → 17 → 16 카테고리, 시장조사 반영 + 홍삼 제거 (작업지시자 결정), [#17](https://github.com/kswift1/PillPouch/issues/17) 진행 중)

## Context

[#11](https://github.com/kswift1/PillPouch/issues/11) 진행 중 발견된 시각/데이터 결정 문제. W1-9 design-system §7에 박힌 **캡슐 형태 6종**(`tablet`/`softgel`/`capsule`/`powder`/`liquid`/`gummy`) 픽토그램이 사용자 인지 단위로 부적합함:

- 같은 "비타민 D"라도 정제·소프트젤·구미 형태로 갈라짐 → 사용자가 "내 비타민 D" 한 개념으로 묶어 인지하는데 시각적으로는 형태별로 흩어짐
- 6종 형태 분류는 **"무엇을 먹는가"**가 아니라 **"어떤 형태인가"**라는 직교 메타 — 사용자에겐 본질이 아님

작업지시자 명시 로드맵:
- **V1.0**: 보편적 영양제군(오메가/비타민 C·D/종합비타민/칼슘마그네슘 등) 12종 카테고리로 분류 + 각각 대표 이미지
- **V1.1**: 제약사 SKU 단위 카탈로그(센트룸·솔가 등) 수천~수만 row로 확장

V1.1 SKU 카탈로그는 enum 불가능(수가 너무 많음, 제약사 제품 변경 빈도) → 반드시 서버 SoT + 모바일 mirror 구조. V1.0 카테고리 12종을 클라 enum으로 두고 V1.1에 서버 SoT로 갈아끼우면 V1.0→V1.1 cutover에서 큰 학습비용 발생.

본 결정은 **V1.0부터 서버 SoT 패턴을 박제**해 V1.1 SKU 도입 시 인프라 변경 없이 데이터만 추가하도록 설계.

후보:

- **(α) 클라 enum + Asset Catalog만** (V1.0 단순화, V1.1에 서버 도입)
  - 5~7일 W3 슬립 회피
  - V1.1 도입 시 SwiftData mirror·동기화·페이지네이션·검색·이미지 다운로드 모두 한 번에 결정 → 1.5~2주 추가 비용 + UX 회귀 위험 (V1.0 사용자가 V1.1에 다운로드 지연 겪음)
- **(β-lite) 서버 카탈로그 메타만, 이미지 hosting은 V1.1로 미룸**
  - V1.0 절약 ≈ V1.1 추가 비용 + UX 회귀
- **(β-full + i) 서버 SoT + 이미지 hosting + 클라 enum 12종 유지** (하이브리드)
  - 컴파일 타임 안전성 확보, 카테고리별 UI 분기 자연스러움
  - V1.1 SKU와 카테고리가 다른 메커니즘 — 일관성 ↓
- **(β-full + ii) 서버 SoT + 이미지 hosting + 클라 enum 없음** (순수 서버) ✅
  - V1.1 SKU와 카테고리가 같은 mirror 메커니즘 → 통일성 최고
  - 신규 카테고리 추가 시 App Store 배포 없이 즉시 사용 가능
  - 컴파일 타임 안전성 손실은 V1.0 시점 카테고리별 시각 매직(특수 배지·다크모드 색조 변형 등)이 거의 없으므로 수용 가능
  - V1.0 → V1.1 사용자 학습비용 0 (UI 패턴 동일)

## Decision

**(β-full + ii) 채택**. 서버 SoT, 클라이언트 enum 없음, 이미지 hosting V1.0부터 도입.

### 카테고리 16종 (V1.0 시드, 2026-04-28 시장조사 후 12 → 17 → 16)

본 ADR 머지 직후 #17 진행 중 한국 시장 조사 결과로 12 → 17종 확장 → 작업지시자 결정으로 redGinseng(홍삼) 제거 → 16종 최종.

추가/변경:
- **calciumMagnesium 분리** → `calcium` + `magnesium` (한국 시장 단독 제품 매우 흔함)
- ~~**redGinseng**~~ 제거 (작업지시자 2026-04-28 결정 — 홍삼은 본 카탈로그 범위 밖. V1.1 검토)
- **milkThistle 신규** (간 건강 핵심 카테고리)
- **glucosamine 신규** (관절 5060 시장 핵심)
- **coq10 신규** (항산화/에너지)

| key (lowerCamel) | display (한글) | displayOrder |
|---|---|---|
| `omega3` | 오메가-3 | 1 |
| `probiotics` | 유산균 (프로바이오틱스) | 2 |
| `vitaminC` | 비타민 C | 3 |
| `multivitamin` | 종합 비타민 | 4 |
| `vitaminD` | 비타민 D | 5 |
| `vitaminB` | 비타민 B (B 컴플렉스 통합) | 6 |
| `milkThistle` | 밀크씨슬 | 7 |
| `glucosamine` | 글루코사민 | 8 |
| `lutein` | 루테인 | 9 |
| `collagen` | 콜라겐 | 10 |
| `magnesium` | 마그네슘 (단독) | 11 |
| `calcium` | 칼슘 (단독) | 12 |
| `iron` | 철분 | 13 |
| `zinc` | 아연 | 14 |
| `coq10` | 코엔자임 Q10 | 15 |
| `other` | 기타 (시드 외 폴백) | 99 |

key는 **lowerCamelCase 통일** (백엔드/모바일 일관성, REST URL에서도 그대로 사용). snake_case 변환 안 함.

displayOrder는 시장 점유율 + 구매율 1위 성분 (프로바이오틱스 25.2% > 비타민C 23.7% > 복합비타민 23.2% > 홍삼 21.4%) 기반.

V1.1 후순위 (시장조사 후 제외): biotin·BCAA·단백질·후코이단·녹용 — 도그푸딩 결과로 추가 검토.

### 데이터 모델

**서버 SQLite (`crates/storage/`)**:
```sql
CREATE TABLE category (
    key           TEXT PRIMARY KEY,          -- "omega3", "vitaminD", ...
    display_name  TEXT NOT NULL,             -- "오메가-3"
    icon_path     TEXT NOT NULL,             -- "/assets/category-icons/omega3.png"
    display_order INTEGER NOT NULL,
    version       INTEGER NOT NULL,
    updated_at    TIMESTAMP NOT NULL
);
```

V1.1 SKU 도입 시 `sku` table을 같은 catalog endpoint family에 추가. category는 SKU의 부모 facet으로 살아남음.

**모바일 SwiftData**:
```swift
@Model final class CategoryMirror {
    @Attribute(.unique) var key: String
    var displayName: String
    var iconLocalPath: String?    // 다운로드 후 로컬 path
    var iconRemoteURL: URL
    var displayOrder: Int
    var version: Int
    var updatedAt: Date
}

@Model final class Supplement {
    @Attribute(.unique) var id: UUID
    var name: String
    var categoryKey: String       // CategoryMirror.key 참조 (clientside FK)
    // CapsuleType 필드 폐기
    // ...
}
```

**W1-10 `CapsuleType` enum 폐기**. 형태 분류 자체를 V1에서 제거 (사용자 인지 본질 X).

### 동기화 흐름

1. **앱 첫 실행**: 번들 동봉 시드(JSON 12종 row + 12 PNG)를 SwiftData mirror에 import. 네트워크 무관 즉시 동작.
2. **백그라운드 동기화**: `GET /api/v1/categories?since={version}` 호출 → 변경된 row만 upsert + 신규 이미지 다운로드 → mirror 갱신.
3. **빈도**: 앱 launch 1회 + 24시간 stale-while-revalidate.
4. **오프라인**: mirror 캐시 사용 (마지막 성공 응답 + 다운로드된 이미지).
5. **신규 카테고리 추가** (서버에 13번째 등장): mirror에 row 추가됨 → 검색 UI에 표시 → 사용자 등록 가능. 클라 enum이 없으므로 폴백 로직 불필요.

### UI 사용 패턴

```swift
// Supplement 등록 화면
@Query(sort: \CategoryMirror.displayOrder) var categories: [CategoryMirror]
ForEach(categories) { mirror in
    Button {
        supplement.categoryKey = mirror.key
    } label: {
        Label(mirror.displayName, image: mirror.iconLocalPath ?? mirror.iconRemoteURL)
    }
}

// Today 봉지 안 표현
let mirror = mirrorRepo.fetch(key: supplement.categoryKey)
Image(uiImage: mirror?.icon ?? fallbackIcon)
Text(mirror?.displayName ?? "기타")
```

카테고리별 시각 매직(특수 배지 등)이 V1.0에는 없음 — V1.1에 등장 시 mirror에 메타 필드 추가 (예: `theme_color_hex`, `badge_type`) 또는 그때 enum 부분 도입.

### V1.1 SKU 확장 가이드라인

같은 mirror 패턴을 SKU에 적용:

```swift
@Model final class SKUMirror {
    @Attribute(.unique) var id: UUID
    var categoryKey: String       // 부모 카테고리 facet
    var brandName: String         // 제약사명
    var productName: String
    // ...
}

// Supplement 모델 확장
@Model final class Supplement {
    var categoryKey: String       // V1.0부터 유지
    var skuId: UUID?              // V1.1 추가, 옵셔널 (사용자가 SKU 안 고르면 nil)
    // ...
}
```

V1.0에서 박은 인프라 (catalog endpoint pattern, SwiftData mirror, 이미지 hosting, 시드 동봉, 동기화 흐름)가 SKU에도 그대로 적용됨.

### Migration

- W1-10 SwiftData 모델 변경: `Supplement.capsuleType: CapsuleType` 필드 제거 + `categoryKey: String` 추가
- V1 출시 전이라 사용자 데이터 0 → 마이그레이션 SQL 불필요, 단순 schema 갱신
- 현재 #11 PR-1 작업물(`CapsuleAsset` enum + `tablet.imageset` + `scripts/imageset-capsules.sh` + `design/capsules/raw/tablet.png`)은 새 구조로 재활용:
  - `CapsuleAsset` enum 폐기
  - `Capsules/` → `Categories/` 폴더 rename
  - `tablet.png` → `other.png` 재활용 (generic pill = 기타 폴백)
  - 변환 스크립트 그대로 (이름만 `imageset-categories.sh`)

## Consequences

### 긍정
- V1.1 SKU 카탈로그 도입 시 인프라 변경 없이 데이터만 추가 — 학습비용 0
- 신규 카테고리/SKU 추가 시 App Store 배포 없이 즉시 사용 가능 (서버 데이터만 update)
- V1.0 ↔ V1.1 사용자 UI 패턴 동일 (학습 회귀 없음)
- 봉지 안 표현이 사용자 인지 단위(성분)에 정합 — Pokemon Sleep 결의 "나의 비타민 D" 일관성
- enum sync 비용 0 (양쪽 SoT 어긋날 일 없음)
- 카테고리별 시각 변경이 서버 hot update — A/B 테스트 / 다크모드 색조 조정 등 빠른 iteration 가능

### 부정 / 트레이드오프
- W3 백엔드 마일스톤 5~7일 슬립 (catalog endpoint + 이미지 hosting + 모바일 동기화)
- 컴파일 타임 안전성 손실 — `categoryKey: String` 오타("vitamiD")는 런타임에 발견. **완화**: 시드 12종 key는 단일 SoT JSON에서 빌드 시 import (Swift constants generation script) 검토. V1.1 SKU 도입 시 어차피 string 기반이므로 통일.
- 카테고리별 UI 분기는 string match (`if mirror.key == "vitaminD"`) → 컴파일러 검증 X. **완화**: 분기 자체를 최소화 (시각 매직은 mirror 메타 필드로 데이터화).
- 첫 실행 시 시드 동봉 사이즈 ~수 MB (12 PNG × 평균 100KB) — 앱 번들 사이즈에 합산. 미미한 수준.
- 카테고리 데이터 모델 변경(예: 새 필드 추가) 시 mirror schema 마이그레이션 + 클라 빌드 필요. 다만 enum case 추가는 자유 (mirror row만 추가).
- 서버 다운/네트워크 단절 시 신규 가입 사용자 첫 동기화 실패 — **완화**: 시드 동봉으로 완전 차단 회피. 이후 재시도 백그라운드.

### 위험
- V1.0 12종이 사용자 첫 등록의 80%+를 커버 못 하면 `other` 폴백 비율 ↑ → 카탈로그 가치 약화 → V1.1 SKU 우선순위 ↑. **완화**: V1.0 도그푸딩에서 `other` 비율 측정해 V1.1 SKU 시드 우선순위 판단.
- SKU 도입 시 검색 UX (수천 row)가 V1.0 검색 UI 패턴(12 row 정렬 표시) 그대로면 부족. V1.1엔 검색·필터·페이지네이션 추가 필요. **완화**: V1.0 검색 컴포넌트가 SwiftUI `List` + `searchable` 표준이면 자연스럽게 확장.
- 이미지 hosting V1.0 Fly static의 V1.1 한계 — 별도 ADR `0008` 참조.

## 후속 결정/Issue

본 결정으로 다음 새 issue 시리즈 예정 (#11 close, 본 브랜치 `local/task11`은 (a)로 재활용):

- **(a)** [M] ADR `0007`/`0008` 작성 + 본 task #11 인프라 재활용 (현 브랜치)
- **(b)** [M] `Supplement` 모델 마이그레이션 (`CapsuleType` 폐기, `categoryKey` 신설, `CategoryMirror` 추가)
- **(c)** [M] 시드 12종 카테고리 이미지 + JSON 동봉 (#11 imageset 흐름 그대로 재활용)
- **(d)** [L] 백엔드 catalog endpoint + SQLite 시드 마이그레이션 + 이미지 hosting
- **(e)** [M] 모바일 mirror 동기화 + 검색 UI

## 참조
- 기획서 §데이터 모델 스케치, §시각 언어 (`docs/brief.md`)
- W1-9 design-system §7 (`docs/design-system.md`) — 카테고리 12종 시각 명세는 본 ADR 머지 후 §7 섹션 갱신 예정
- W1-10 데이터 모델 (`docs/adr/0001-rust-axum-backend.md` 영향 없음)
- ADR-0001 백엔드 storage SQLite (그대로 유지, 카탈로그 도메인도 동일 SQLite에 박음)
- ADR-0008 카테고리 이미지 hosting (V1.0 Fly static, V1.1 S3 재평가)
