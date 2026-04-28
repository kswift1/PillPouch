#!/usr/bin/env bash
# 카테고리 raw PNG들을 다양한 사이즈 그리드로 합성 (시리즈 일관성 + 32pt 식별성 검증용).
#
# 입력: design/categories/raw/{key}.png (작업지시자 GPT Image 2 산출물)
# 출력: docs/screenshots/categories/grid-{size}px.png (32, 64, 96, 128 size 그리드)
#       docs/screenshots/categories/grid-by-color.png (색 그룹별 분리)
#
# 의존: imagemagick (brew install imagemagick)
# 참조: docs/plans/task_W2_17_impl.md, docs/working/task-17-review.md
#
# 라벨은 montage가 macOS imagemagick 폰트 문제로 어려움 → 라벨 없이 순서대로 표시.
# 순서는 카테고리별 displayOrder (시장 점유율 기반).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RAW_DIR="$ROOT/design/categories/raw"
OUT_DIR="$ROOT/docs/screenshots/categories"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

command -v magick >/dev/null 2>&1 || {
  echo "missing dep: magick — run \`brew install imagemagick\`" >&2
  exit 1
}

mkdir -p "$OUT_DIR"

# 16종 (홍삼 제거 후, displayOrder 기반 순서)
# Row 1: omega3 probiotics vitaminC multivitamin vitaminD
# Row 2: vitaminB milkThistle glucosamine lutein collagen
# Row 3: magnesium calcium iron zinc coq10
# Row 4: other (4 빈자리)
ALL=(omega3 probiotics vitaminC multivitamin vitaminD \
     vitaminB milkThistle glucosamine lutein collagen \
     magnesium calcium iron zinc coq10 \
     other)

# ── 사이즈별 그리드 (32, 64, 96, 128 pt — @2x 가정해 64/128/192/256 px)
for SIZE in 32 64 96 128; do
  px=$((SIZE * 2))   # @2x 표시 가정
  echo "→ size $SIZE pt (${px}px @2x), 5 columns × 4 rows" >&2

  list=()
  for name in "${ALL[@]}"; do
    src="$RAW_DIR/$name.png"
    if [[ ! -f "$src" ]]; then
      magick -size "${px}x${px}" xc:"#FAF7F2" "$TMP/${name}-${SIZE}.png"
    else
      magick "$src" -fuzz 5% -transparent white \
        -filter Lanczos -resize "${px}x${px}!" \
        -background "#FAF7F2" -alpha remove -alpha off \
        +set label \
        "$TMP/${name}-${SIZE}.png"
    fi
    list+=("$TMP/${name}-${SIZE}.png")
  done

  # 빈 슬롯 4개 padding (4행 × 5열 = 20 - 16 = 4)
  for i in 1 2 3 4; do
    magick -size "${px}x${px}" xc:"#FAF7F2" +set label "$TMP/blank-${SIZE}-${i}.png"
    list+=("$TMP/blank-${SIZE}-${i}.png")
  done

  magick montage "${list[@]}" \
    -font "/System/Library/Fonts/Geneva.ttf" \
    -tile 5x4 -geometry "+12+12" \
    -background "#FAF7F2" \
    -bordercolor "#FAF7F2" -border 24 \
    "$OUT_DIR/grid-${SIZE}pt.png"

  echo "  ✓ $OUT_DIR/grid-${SIZE}pt.png" >&2
done

# ── 색 그룹별 분리 그리드
echo "→ color-group grid" >&2

# 5 그룹 × 4 칸 (group당 최대 4) = 20 슬롯
COLOR_ORDER=(
  omega3 vitaminC vitaminD lutein               # yellow_orange (4)
  vitaminB probiotics collagen coq10            # red_pink (4)
  multivitamin calcium glucosamine other        # beige_tan (4)
  milkThistle "" "" ""                          # olive (1 단독 + 3 빈) — redGinseng 제거로 dark 그룹 단독
  magnesium iron zinc ""                        # grey_metal (3 + 1 빈)
)

GROUPED_LIST=()
for name in "${COLOR_ORDER[@]}"; do
  px=192
  if [[ -z "$name" ]]; then
    blank="$TMP/group-blank-$RANDOM.png"
    magick -size "${px}x${px}" xc:"#FAF7F2" +set label "$blank"
    GROUPED_LIST+=("$blank")
    continue
  fi
  src="$RAW_DIR/$name.png"
  if [[ -f "$src" ]]; then
    magick "$src" -fuzz 5% -transparent white \
      -filter Lanczos -resize "${px}x${px}!" \
      -background "#FAF7F2" -alpha remove -alpha off \
      +set label \
      "$TMP/group-${name}.png"
  else
    magick -size "${px}x${px}" xc:"#FAF7F2" +set label "$TMP/group-${name}.png"
  fi
  GROUPED_LIST+=("$TMP/group-${name}.png")
done

magick montage "${GROUPED_LIST[@]}" \
  -font "/System/Library/Fonts/Geneva.ttf" \
  -tile 4x5 -geometry "+12+12" \
  -background "#FAF7F2" \
  -bordercolor "#FAF7F2" -border 24 \
  "$OUT_DIR/grid-by-color.png"

echo "  ✓ $OUT_DIR/grid-by-color.png" >&2

echo "" >&2
echo "done." >&2
echo "" >&2
echo "검증 흐름:" >&2
echo "  1. grid-32pt.png — 32pt에서 헷갈리는 페어 시각 점검 (5×4 grid, displayOrder 순서)" >&2
echo "  2. grid-by-color.png — 색 그룹 내 카테고리들 변별 점검 (4×5 grid)" >&2
echo "     Row 1: yellow/orange (omega3, vitaminC, vitaminD, lutein)" >&2
echo "     Row 2: red/pink (vitaminB, probiotics, collagen, coq10)" >&2
echo "     Row 3: beige/tan (multivitamin, calcium, glucosamine, other)" >&2
echo "     Row 4: olive (milkThistle, blank, blank, blank)" >&2
echo "     Row 5: grey/metal (magnesium, iron, zinc, blank)" >&2
echo "  3. grid-128pt.png — 큰 사이즈에서 시리즈 일관성 점검 (카메라/shadow)" >&2
