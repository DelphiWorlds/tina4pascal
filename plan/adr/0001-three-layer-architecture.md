# ADR-0001: Three-layer architecture — core / contract / shells

- **Status:** Accepted
- **Date:** 2026-10-01 (retrofit; decision predates the ADR log)

## Context

Tina4Pascal renders HTML natively on macOS, Windows, Linux, Android and iOS from
one engine. Without a hard boundary, OS-specific code leaks into the renderer and
every platform fork drifts, which is exactly the rot this project exists to avoid.

## Decision

Three layers, strictly separated:

1. **Core** — `src/Tina4HTMLDom.pas`, `src/Tina4HTMLLayout.pas`: pure Pascal, zero
   OS dependencies. It may call ONLY the abstract contract.
2. **Contract** — `src/Tina4RenderBackend.pas`: a small, stable, documented set of
   virtuals (canvas, text measurement, images, events) with safe defaults.
3. **Shells** — one unit per OS (e.g. `src/Tina4ShellCocoa.pas`): window, blit,
   input, image fetch/decode. Keep each under ~500 lines.

## Consequences

- A new OS capability extends the **contract** (a new virtual + default), never an
  `{$IFDEF}` or OS `uses` in the core.
- If a shell grows logic, that logic belongs in the core.
- Reward: the headless/raster path and every shell share one tested renderer, and
  the `compare-all` harness can hold all of them to the same Chrome-matched output.
- Undo this and you get N diverging renderers and no single source of truth.
