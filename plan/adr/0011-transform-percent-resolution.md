# ADR-0011: `translate()` percentages resolve against the element's own box

- **Status:** Accepted
- **Date:** 2026-10-05

## Context

CSS `transform: translate(<x>, <y>)` resolves a `%` argument against the
**element's own** border-box size (X→width, Y→height) — that is how
`translate(-50%, -50%)` centres a box, and how compositions like
`translate(50vw, 50vh) translate(-50%, -50%) scale(1.15) translate(12px, 8px)`
work in a browser.

Two bugs stopped the engine replicating this:

1. The transform argument parser scanned to the **first** `)`, so a `calc()`
   argument (`translate(calc(-50% + 12px))`) was truncated at `calc(`'s own
   inner `)` — mangling the whole transform (blank render).
2. `translate()` arguments went through `ParseLength`, which **sign-encodes** a
   `%` into the single `TransformTranslateX/Y` field. That value was then used
   as raw px at paint and never resolved against the box. The encoding is also
   ambiguous (`-50%` and `+50px` collide). It only "worked" by accident — a
   centred layer's `left:50%`→−50 and `translate(-50%)`→+50 cancelled to ~0 —
   which fell apart the moment a parallax offset was composed in.

Surfaced while building the `tina4studio` native hero (mouse parallax + sparkle)
against this engine.

## Decision

- Balance nested parens when extracting a transform function's arguments, so
  `calc()`/`min()`/`max()`/`clamp()` inside `translate()` survive intact.
- Store a translate's **px part and % part separately**
  (`TransformTranslate{X,Y}` + new `TransformTranslate{X,Y}Pct`). The parser
  routes a `%` arg to the Pct accumulator and everything else (px/em/vw/calc…)
  to the px accumulator. At paint, the final shift is
  `px + Pct/100 * Box.{W,H}` (plus `ResolveCalc` for any deferred `calc()`
  marker in the px part) — resolving `%` against the element's own size.

## Consequences

- `translate(-50%, -50%)` centres exactly, and px/%/vw/`calc()` compose the way a
  browser composes them. `scale()` is unaffected and still the right tool for
  overscan (viewport-unit *widths* are clamped to the viewport, so `width:140vw`
  cannot over-size an element — `scale()` can).
- New state on `TComputedStyle` must be reset in both `Default` and the `ForTag`
  inherit path (it is), and included in the paint-cull "has transform" check (it
  is) so a `%`-only translated box off its natural spot is never wrongly culled.
- Covered by reftests `examples/compliance/transform-translate-pct` and
  `transform-translate-calc` (both delta 0.00%). If you're tempted to fold the
  Pct fields back into the single px field, these reftests break — that
  ambiguity is exactly what this ADR removes.
- Transitions/animations still interpolate the px part only; animating a
  `%`-translate is not yet interpolated (acceptable; no current caller needs it).
