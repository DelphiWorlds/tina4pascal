# ADR-0002: HTML drives everything — no widget components

- **Status:** Accepted
- **Date:** 2026-10-01 (retrofit)

## Context

Tina4Pascal is the Free Pascal sibling of Tina4Delphi's `TTina4HTMLRender`. Apps
are written as HTML + CSS, not as trees of native widgets. Diverging from that
model would fork the mental model and break parity with the Delphi renderer.

## Decision

The application model is HTML-drives-everything: there are **no widget objects**.
Form controls are drawn by the renderer; state lives in the DOM; interaction
surfaces as **semantic events** — `onclick → object:method(params)`, form submits
as name/value pairs, link clicks. Preserve exact event-contract parity with
Tina4Delphi's `TTina4HTMLRender.pas`.

## Consequences

- App logic is a unit that registers named actions in its `initialization` (see
  `examples/calculator/Tina4CalcApp.pas`); ANY shell that links the unit gets them.
- A decoded value / result reaches the DOM through the engine (e.g. a
  `<barcode-scanner result="#id">` fills that element — and because a form control
  renders its `value` attribute, the fill sets `value`, not text content).
- Apps that re-render from a template on every action must bind dynamic values in
  the template; the DOM mutation alone won't survive their re-parse.
- Undo this and you lose Delphi parity and the single HTML UI across all targets.
