#!/usr/bin/env bash
# Build the Tina4Pascal app icon for every platform from the master logo
# branding/icon-source.webp (the flamingo + cheetah neon mark).
#   master  → branding/icon.png (1024² RGB)
#   macOS   → branding/AppIcon.icns
#   Windows → branding/icon.ico (16–256 multi-size)
#   iOS     → ios/app/Assets.xcassets/AppIcon.appiconset/icon_1024.png (square fill)
#   Android → res/mipmap-*/ic_launcher.png (square) + ic_launcher_round.png (circle)
#   docs    → examples/{showcase,parallax}/assets/tina4pascal-logo.png
#
# Needs ImageMagick (`magick`) + macOS `sips`/`iconutil`. Re-run after replacing
# branding/icon-source.webp to refresh every derived asset from one source.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$(pwd)"; OUT="$ROOT/branding"
SRC="$OUT/icon-source.webp"
[ -f "$SRC" ] || { echo "missing $SRC"; exit 1; }
command -v magick >/dev/null || { echo "need ImageMagick (brew install imagemagick)"; exit 1; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# 1) master 1024² (opaque — flatten any alpha onto white)
magick "$SRC" -resize 1024x1024 -background white -alpha remove -alpha off "$TMP/icon.png"
cp "$TMP/icon.png" "$OUT/icon.png"

# 2) circle-masked variant (Android round)
magick "$TMP/icon.png" \
  \( -size 1024x1024 xc:none -fill white -draw "circle 511.5,511.5 511.5,0" \) \
  -alpha set -compose DstIn -composite "$TMP/round.png"

# 3) macOS .icns
if command -v iconutil >/dev/null; then
  IS="$TMP/icon.iconset"; mkdir -p "$IS"
  for s in 16 32 64 128 256 512; do
    sips -z "$s" "$s" "$TMP/icon.png" --out "$IS/icon_${s}x${s}.png" >/dev/null
    d=$(( s*2 )); sips -z "$d" "$d" "$TMP/icon.png" --out "$IS/icon_${s}x${s}@2x.png" >/dev/null
  done
  cp "$TMP/icon.png" "$IS/icon_512x512@2x.png"
  iconutil -c icns "$IS" -o "$OUT/AppIcon.icns"
  echo "✓ macOS  branding/AppIcon.icns"
fi

# 4) Windows .ico
magick "$TMP/icon.png" -define icon:auto-resize=256,128,64,48,32,16 "$OUT/icon.ico"
echo "✓ Windows branding/icon.ico"

# 5) iOS (square fill; iOS applies its own superellipse mask)
cp "$TMP/icon.png" "$ROOT/ios/app/Assets.xcassets/AppIcon.appiconset/icon_1024.png"
echo "✓ iOS    icon_1024.png"

# 6) Android mipmaps (square + round)
for e in mdpi:48 hdpi:72 xhdpi:96 xxhdpi:144 xxxhdpi:192; do
  dir="${e%%:*}"; px="${e##*:}"; base="$ROOT/android/app/src/main/res/mipmap-$dir"
  [ -d "$base" ] || continue
  sips -z "$px" "$px" "$TMP/icon.png"  --out "$base/ic_launcher.png"       >/dev/null
  sips -z "$px" "$px" "$TMP/round.png" --out "$base/ic_launcher_round.png" >/dev/null
done
echo "✓ Android mipmap-*/ic_launcher(.png/_round.png)"

# 7) docs / example logos
cp "$TMP/icon.png" "$ROOT/examples/showcase/assets/tina4pascal-logo.png"
cp "$TMP/icon.png" "$ROOT/examples/parallax/assets/tina4pascal-logo.png"
echo "✓ docs   examples/{showcase,parallax}/assets/tina4pascal-logo.png"
echo "done."
