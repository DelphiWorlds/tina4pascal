# ADR-0003: Vendored FPC 3.2.2 cross-toolchain at ~/fpc

- **Status:** Accepted
- **Date:** 2026-10-01 (retrofit)

## Context

Builds must cross-compile from one Mac to Windows, Linux (x64/arm64), Android and
iOS. Homebrew's `fpc` is native-only — no cross RTLs, no source tree — so it cannot
do this. Building the cross compilers has ~20 pitfalls that were solved once.

## Decision

Use a self-contained FPC 3.2.2 install at `~/fpc` (native aarch64-darwin plus the
cross targets), built by `toolchain/build-crosses.sh`. Every FPC invocation needs
`PPC_CONFIG_PATH=$HOME/fpc/etc` and `~/fpc/bin` on PATH. Do not substitute Homebrew
fpc. The CLI (`tools/tina4pascal`) resolves this toolchain for every target.

## Consequences

- `build-crosses.sh` links `ppc<suffix> → ppcross<suffix>` in `~/fpc/bin` after
  `crossinstall`, so a fresh build doesn't fail with "ppc<suffix> … error 127".
- A target that fails with "Can't find unit system" means that cross RTL was never
  built — run the formula, don't guess.
- See `references/build-formula.md` in the developer skill for the full formula.
- Undo this (e.g. use Homebrew fpc) and cross builds silently lose the RTLs.
