# scripts/

repo 자동화 스크립트.

## imageset-capsules.sh

캡슐 PNG → Asset Catalog Image Set 자동 등록.

```bash
brew install imagemagick                  # macOS
./scripts/imageset-capsules.sh            # 6종 일괄
./scripts/imageset-capsules.sh tablet     # 1종만
```

입력: `design/capsules/raw/{name}.png` (GPT Image 2 산출물, ≥1024px)
출력: `ios/PillPouch/Assets.xcassets/Capsules/{name}.imageset/`
- `Contents.json` (Universal, 1x/2x/3x)
- `{name}@1x.png` / `{name}@2x.png` / `{name}@3x.png`

내부 흐름:
1. `magick -filter Lanczos -resize` — base 128pt 기준 1x/2x/3x 다운샘플
2. ratio 적용 (정사각 vs 20:28 powder/liquid)
3. Contents.json 표준 형식 작성

base 사이즈와 비율 SoT: `scripts/capsule-spec.json` (`docs/design-system.md` §7.2 박제)

V1 결정 (2026-04-28): 캡슐은 v4 결의 PNG 그대로 사용. SVG/`currentColor` 변환 없음. 시간대 색조 주입 포기 → `Image(.tablet)`은 베이지 등 베이크된 색 그대로 표시.
