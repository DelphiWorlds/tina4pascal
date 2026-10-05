# ADR-0012: `onmousemove` DOM event dispatched to app code

- **Status:** Accepted
- **Date:** 2026-10-05

## Context

Apps need the cursor position to drive mouse-linked effects (parallax, a cursor
particle/sparkle trail). The engine already delivered `OnMouseMove` from every
shell into the host, but it was consumed **only** to drive the `:hover`
pseudo-class — nothing reached app/page code. `onscroll` already had the pattern
we wanted: `FireOnScroll` reads the attribute, strips to the action name, and
calls `DispatchActionArgs(name, "<value>")` so a registered Pascal action runs
(ADR-0002, HTML-drives-everything). There was no `onmousemove` equivalent.

Surfaced building the `tina4studio` native hero, whose parallax + sparkle driver
had to live in the example viewer because the framework could not deliver moves
to an app.

## Decision

Add an `onmousemove` DOM event mirroring `onscroll`, in the core interaction unit
(`src/Tina4Interact.pas`):

- `FindOnMouseMoveTag(root)` — first node in document order with an
  `onmousemove` attribute (typically `<body>` or a hero container).
- `FireOnMouseMove(tag, x, y)` — dispatches the attribute's action via
  `DispatchActionArgs(name, "x,y")`, with the cursor in **CSS px, viewport
  coords**. A DOM mutation in the handler promotes `BuiltinsDirty`→`GLayoutDirty`
  (relayout next frame), and sets a one-shot `GMoveRepaint` flag.
- `TinaHover` fires it **before** the `HasInteractiveSelectors` early-out, so a
  page with no `:hover` CSS still receives moves; it resets `GMoveRepaint` each
  call so the flag reflects the current move.
- `TinaTakeMoveRepaint` lets the host repaint only when a handler fired — plain
  hover stays repaint-free. All three hosts consume it: macOS
  (`TAppDriver.Move`), Windows (`WM_MOUSEMOVE`), X11 (`MotionNotify`).

A handler is a normal registered action: `RegisterAction('hero.move', @Proc)`
bound by `<body onmousemove="hero.move()">`, receiving the one `Args` string
`"x,y"` to split — identical to `onscroll`/`oninput`, no new dispatch path.

## Consequences

- Mouse-linked effects can be **app-driven**: the `tina4studio` hero's parallax
  (mutate layer transforms) can move out of the example viewer into app code,
  via `onmousemove` + runtime DOM style mutation. Sparkles still want a runtime
  DOM node create/append/remove API in `Tina4Builtins` (and/or a per-frame app
  hook) — a follow-up; CSS `@keyframes` already animates a spawned node.
- Covered by `tests/test_mousemove.pas` (in the compliance unit gate): dispatch
  with `"x,y"`, fires without `:hover` CSS, one-shot repaint flag, and no fire /
  repaint-free on a page without the handler. Full suite stays green (224/224).
- `FindOnMouseMoveTag` walks the DOM per move (as `FindOnScrollTag` does per
  scroll); fine for app-sized DOMs. If a huge DOM makes this hot, cache the
  target and invalidate the cache on Rebuild — don't fold the flag back into a
  persistent set-only boolean (that staleness is what the reset in `TinaHover`
  and the `test_mousemove` repaint-free assertion exist to prevent).
