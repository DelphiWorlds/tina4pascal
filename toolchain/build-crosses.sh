#!/bin/sh
# Build FPC 3.2.2 cross-compilers on macOS arm64 → win64, linux x64/a64, android a64, darwin x64, ios a64
# Key insight: OPT applies to the NATIVE compiler rebuild too (needs mac SDK via -XR),
# while CROSSOPT applies only to target RTL/packages.
set -u
SRC=$HOME/fpc-dev/fpc-3.2.2
PREFIX=$HOME/fpc
PP=$PREFIX/lib/fpc/3.2.2/ppca64
MACSDK=$(xcrun --show-sdk-path)
IOSSDK=$(xcrun --sdk iphoneos --show-sdk-path)
CROSS=$PREFIX/cross

# CPU → FPC compiler-binary suffix (ppc<suffix> / ppcross<suffix>)
cpusuffix() {
  case "$1" in
    x86_64) echo x64 ;; aarch64) echo a64 ;; arm) echo arm ;;
    i386) echo 386 ;; *) echo "$1" ;;
  esac
}

# crossinstall installs the cross compiler as ppcross<suffix>, but the `fpc`
# driver invokes ppc<suffix> and searches its own bin dir (where native compilers
# are symlinked). Without this link a cross build fails with "ppc<suffix> can't be
# executed, error code: 127". One cross compiler serves every OS of its CPU, so a
# link per CPU is enough — and never clobber the host's native ppc<suffix>.
link_cross() {
  sfx=$(cpusuffix "$1")
  libdir=$(dirname "$PP")                 # …/lib/fpc/<ver>
  xbin="$libdir/ppcross$sfx"
  lnk="$PREFIX/bin/ppc$sfx"
  if [ -f "$xbin" ] && [ ! -e "$lnk" ]; then
    ln -sf "../lib/fpc/$(basename "$libdir")/ppcross$sfx" "$lnk"
    echo "     linked $(basename "$lnk") -> ppcross$sfx"
  fi
}

build() {
  name=$1; os=$2; cpu=$3; bindir=$4; binprefix=$5; crossopt=$6
  log=/private/tmp/fpc-cross-$name.log
  cd "$SRC" || exit 1
  make clean OS_TARGET=$os CPU_TARGET=$cpu > /dev/null 2>&1
  if make crossall crossinstall OS_TARGET=$os CPU_TARGET=$cpu PP=$PP \
      INSTALL_PREFIX=$PREFIX OVERRIDEVERSIONCHECK=1 OPT="-XR$MACSDK" \
      ${bindir:+CROSSBINDIR=$bindir} ${binprefix:+BINUTILSPREFIX=$binprefix} \
      ${crossopt:+CROSSOPT="$crossopt"} > "$log" 2>&1; then
    echo "OK   $name"
    link_cross "$cpu"
  else
    echo "FAIL $name (see $log)"
  fi
}

echo "== FPC cross builds started $(date) =="
build win64          win64   x86_64  ""                           ""                           ""
build linux-x64      linux   x86_64  "$CROSS/bin/x86_64-linux"    "x86_64-linux-"              ""
build linux-a64      linux   aarch64 "$CROSS/bin/aarch64-linux"   "aarch64-unknown-linux-gnu-" ""
build android-a64    android aarch64 "$CROSS/bin/aarch64-android" "aarch64-linux-android-"     ""
# 32-bit ARM (armeabi-v7a) — needs GNU as+ld wrappers and armv7/VFP flags.
# Prereq: brew install arm-linux-gnueabihf-binutils; wrappers in
# $CROSS/bin/arm-android/ (as→GNU as, ld→GNU ld). See docs/ANDROID.md.
build android-arm    android arm     "$CROSS/bin/arm-android"     "arm-linux-androideabi-"    "-CpARMV7A -CfVFPV3"
build darwin-x64     darwin  x86_64  ""                           ""                           ""
build ios-a64        ios     aarch64 ""                           ""                           "-XR$IOSSDK"
echo "== done $(date) =="
