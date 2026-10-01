# ADR-0005: iOS is device-only — no Simulator build

- **Status:** Accepted
- **Date:** 2026-10-01 (retrofit)

## Context

FPC 3.2.2 ships exactly one iOS slice: `aarch64-ios` (a physical-iPhone ARM64
build). Simulator arm64 and simulator x86_64 are different platform triples FPC
3.2.2 cannot emit (`-Piphonesim` falls through to a `ppc386` that isn't installed).
This is the #1 thing agents get stuck on.

## Decision

Build and test iOS **only on a physical device** (`-Tios -Paarch64`). Do not use
the iOS Simulator or any iOS-Simulator MCP/host tool for Tina4Pascal: the engine
static lib is device-arm64 and the Simulator SDK rejects it with an
architecture/platform mismatch.

## Consequences

- iOS verification needs a paired iPhone (full Xcode selected via
  `xcode-select -s /Applications/Xcode.app`, `xcodegen`, `devicectl`/libimobiledevice).
- `tools/tina4pascal ios` builds `libtina4ios.a`, generates the xcodeproj, signs for
  device, installs and launches.
- Undo this (chase a Simulator build) and you burn hours on an impossible triple.
