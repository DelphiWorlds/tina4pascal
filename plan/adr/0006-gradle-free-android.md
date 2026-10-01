# ADR-0006: Gradle-free Android packaging

- **Status:** Accepted
- **Date:** 2026-10-01 (retrofit)

## Context

A Gradle/Android-Studio toolchain is heavy, slow, and another moving part to pin.
The engine ships as a pure `libtina4.so` (FPC `-Tandroid`), and the Java bridge is
small, so a full Gradle build earns nothing.

## Decision

Build the APK gradle-free in `tools/tina4pascal` (`cmd_apk`): `fpc` → `libtina4.so`,
then raw `javac` + `d8` + `aapt2` + `apksigner`. Third-party Java (ZXing for
`<barcode-scanner>`) is fetched once to `~/.tina4/bin` and **dexed directly** into
the app — not pulled via Gradle/Maven. The manifest `applicationId` is rewritten to
the project's `bundleId`.

## Consequences

- The `android/app/build.gradle` + `libs/` path is only for an optional
  Android-Studio build; the CLI path is the source of truth and bundles ZXing itself.
- `setup android` still needs the SDK cmdline-tools, build-tools, platform, NDK and a
  JDK — but no Gradle.
- Undo this and you reintroduce a Gradle version-matrix to maintain.
