# scripts/

repo 자동화 스크립트.

## imageset-categories.sh

영양제 카테고리 PNG → Asset Catalog Image Set 자동 등록.

```bash
brew install imagemagick                            # macOS
./scripts/imageset-categories.sh                    # 12종 일괄
./scripts/imageset-categories.sh omega3 vitaminC    # 일부만
```

입력: `design/categories/raw/{key}.png` (GPT Image 2 산출물, ≥1024px)
출력: `ios/PillPouch/Assets.xcassets/Categories/{key}.imageset/`
- `Contents.json` (Universal, 1x/2x/3x)
- `{key}@1x.png` / `{key}@2x.png` / `{key}@3x.png`

내부 흐름:
1. `magick -fuzz 5% -transparent white` — white BG 자동 제거 (GPT Image 2가 transparent BG 미지원)
2. `magick -filter Lanczos -resize` — base 128pt 기준 1x/2x/3x 다운샘플 (alpha 보존)
3. Contents.json 표준 형식 작성

base 사이즈와 비율 SoT: `scripts/category-spec.json` (12종 row, [ADR-0007](../docs/adr/0007-server-catalog-as-source-of-truth.md) §데이터 모델 박제)

12종 키 (lowerCamel):
- `omega3`, `vitaminC`, `vitaminD`, `vitaminB`, `multivitamin`, `calciumMagnesium`
- `probiotics`, `iron`, `zinc`, `lutein`, `collagen`, `other`

## 결정 기록

- **V1.0 결정 (2026-04-28)**: 영양제는 GPT Image 2 v4 결(매트 베이지 3D)의 PNG 그대로 사용. SVG/`currentColor` 변환 없음. 시간대 색조 주입 포기 → `Image("vitaminD")`는 베이크된 색 그대로 표시. 시간대 시각 단서는 봉지/헤더에서 표현.
- **카테고리 단위 결정 (2026-04-28, ADR-0007)**: 형태(정제/소프트젤) 분류 폐기 → 성분(오메가/비타민D) 카테고리 12종으로 갈아끼움. 사용자 인지 단위 정합.
- **이미지 hosting (2026-04-28, ADR-0008)**: V1.0은 Fly static + 앱 번들 시드 동봉. V1.1에 측정 후 S3/R2 재평가.
