#!/usr/bin/env bash
# 카테고리 PNG → Asset Catalog Image Set 자동 등록.
#
# 입력: design/categories/raw/{key}.png (GPT Image 2 산출물, ≥1024px)
# 출력: ios/PillPouch/Assets.xcassets/Categories/{key}.imageset/
#       (Contents.json + {key}@1x.png + @2x + @3x — base 128pt 기준)
#
# 의존: imagemagick (brew install imagemagick), python3
# 참조: docs/plans/task_W2_17_impl.md, docs/adr/0007-server-catalog-as-source-of-truth.md
#
# 17종 (시장조사 후 12 → 17 확장, 2026-04-28):
#   omega3 probiotics vitaminC multivitamin redGinseng vitaminD vitaminB
#   milkThistle glucosamine lutein collagen magnesium calcium iron zinc coq10 other

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RAW_DIR="$ROOT/design/categories/raw"
ASSET_DIR="$ROOT/ios/PillPouch/Assets.xcassets/Categories"
SCRIPT_DIR="$ROOT/scripts"
SPEC="$SCRIPT_DIR/category-spec.json"

command -v magick >/dev/null 2>&1 || {
  echo "missing dep: magick — run \`brew install imagemagick\`" >&2
  exit 1
}
command -v python3 >/dev/null 2>&1 || {
  echo "missing dep: python3" >&2
  exit 1
}

if [[ $# -eq 0 ]]; then
  set -- omega3 probiotics vitaminC multivitamin redGinseng vitaminD vitaminB \
         milkThistle glucosamine lutein collagen magnesium calcium iron zinc coq10 other
fi

base_size="$(python3 -c "import json; print(json.load(open('$SPEC'))['_base_size'])")"

mkdir -p "$ASSET_DIR"

for name in "$@"; do
  src="$RAW_DIR/$name.png"
  if [[ ! -f "$src" ]]; then
    echo "skip $name — not found at $src" >&2
    continue
  fi

  echo "→ $name" >&2

  ratio="$(python3 -c "import json; print(json.load(open('$SPEC'))['$name']['ratio'])")"
  rw="${ratio%%:*}"
  rh="${ratio##*:}"

  if [[ "$rw" == "$rh" ]]; then
    w1="$base_size"; h1="$base_size"
  else
    h1="$base_size"
    w1="$(python3 -c "print(int($base_size * $rw / $rh))")"
  fi
  w2=$((w1 * 2)); h2=$((h1 * 2))
  w3=$((w1 * 3)); h3=$((h1 * 3))

  set_dir="$ASSET_DIR/$name.imageset"
  mkdir -p "$set_dir"

  # 1. 배경 제거 — fuzz 5%로 거의 흰(≥#F2F2F2) 픽셀만 투명. 매트 컬러 highlight·회색 shadow는 안전.
  cut="$RAW_DIR/.tmp-${name}-cut.png"
  magick "$src" -fuzz 5% -transparent white "$cut"

  # 2. @1x/@2x/@3x 다운샘플 (Lanczos 고품질, alpha 보존)
  magick "$cut" -filter Lanczos -resize "${w1}x${h1}!" -strip "$set_dir/$name@1x.png"
  magick "$cut" -filter Lanczos -resize "${w2}x${h2}!" -strip "$set_dir/$name@2x.png"
  magick "$cut" -filter Lanczos -resize "${w3}x${h3}!" -strip "$set_dir/$name@3x.png"
  rm -f "$cut"

  cat > "$set_dir/Contents.json" <<JSON
{
  "images" : [
    { "idiom" : "universal", "filename" : "$name@1x.png", "scale" : "1x" },
    { "idiom" : "universal", "filename" : "$name@2x.png", "scale" : "2x" },
    { "idiom" : "universal", "filename" : "$name@3x.png", "scale" : "3x" }
  ],
  "info" : { "version" : 1, "author" : "xcode" }
}
JSON

  echo "  ✓ $set_dir (@1x ${w1}×${h1}, @2x ${w2}×${h2}, @3x ${w3}×${h3})" >&2
done

cat > "$ASSET_DIR/Contents.json" <<JSON
{
  "info" : { "version" : 1, "author" : "xcode" }
}
JSON

echo "done." >&2
