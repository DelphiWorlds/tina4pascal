#!/bin/sh
set -eu

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PROJECT="$(cd "$(dirname "$0")" && pwd)"
STAGE="$PROJECT/build/simulator/native"
DD="${TINA4_SIM_DERIVED_DATA:-/tmp/tina4-shareitems-sim-dd}"

rm -rf "$STAGE"
mkdir -p "$STAGE"
rm -rf "$PROJECT/sim/app"
cp -R "$ROOT/ios/sim/App" "$PROJECT/sim/app"
cp "$PROJECT/app.html" "$PROJECT/sim/app/shareitems.html"
cp "$ROOT/ios/sim/native/tina4iossimnative.pas" "$STAGE/"
printf ', ShareItemsDemo' > "$STAGE/app_units.inc"

TINA4_IOSSIM_ENG_DIR="$STAGE" \
TINA4_APP_UNIT_DIRS="-Fu$PROJECT/src" \
  sh "$ROOT/ios/build-sim.sh" --native

cd "$PROJECT/sim"
xcodegen generate
xcodebuild -project ShareItemsSim.xcodeproj -scheme ShareItemsSim \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$DD" CODE_SIGNING_ALLOWED=NO build

echo "ShareItems simulator app: $DD/Build/Products/Debug-iphonesimulator/ShareItemsSim.app"
