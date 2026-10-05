#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
PROJECT="$ROOT/examples/location"
BUILD="$PROJECT/build/macos-location"
APP="$BUILD/LocationDemo.app"
FPC="${FPC:-$HOME/fpc/bin/fpc}"

rm -rf "$BUILD"
mkdir -p "$BUILD/bin" "$APP/Contents/MacOS" "$APP/Contents/Resources"

"$FPC" -Mdelphi -O2 \
  -Fu"$ROOT/src" -Fu"$PROJECT/src" \
  -FE"$BUILD/bin" -FU"$BUILD/bin" \
  -o"$BUILD/bin/LocationDemo" "$PROJECT/main.pas"

cp "$BUILD/bin/LocationDemo" "$APP/Contents/MacOS/LocationDemo"
cp "$PROJECT/app.html" "$APP/Contents/Resources/app.html"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>LocationDemo</string>
  <key>CFBundleIdentifier</key><string>com.delphiworlds.locationdemo.macos</string>
  <key>CFBundleName</key><string>Tina4 Location Demo</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>LSMinimumSystemVersion</key><string>10.15</string>
  <key>NSLocationUsageDescription</key><string>Use your location while the app is running.</string>
  <key>NSLocationWhenInUseUsageDescription</key><string>Use your location while the app is running.</string>
</dict></plist>
PLIST

echo "Location macOS app: $APP"
