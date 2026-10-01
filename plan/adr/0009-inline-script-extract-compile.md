# ADR-0009: Inline `<script type="text/pascal">` is extracted and compiled, not interpreted

- **Status:** Accepted
- **Date:** 2026-10-01

## Context

Authors want an app's UI and its behaviour in one file — HTML plus the action code
that `onclick="app.foo()"` dispatches to — instead of a separate `src/AppLogic.pas`.
The obvious web shape is a `<script>` block in the page.

But Tina4Pascal runs **ahead-of-time compiled native Pascal** (FPC). There is no
Pascal VM, interpreter, or JIT in the engine, and ADR-0002 (HTML drives everything)
is explicit that the engine consumes APIs built elsewhere rather than hosting a
scripting runtime. So a `<script>` cannot be *executed* at runtime — only compiled.

## Decision

The build **lifts** `<script type="text/pascal">` out of `app.html` and compiles it
in, so the single-file authoring experience is real while the code stays native:

- `prepare_inline` (in `tools/tina4pascal`) extracts every such block into a
  generated unit, `<app>/.tina4/AppInline.pas`, wrapping the bodies in a unit shell
  with the standard action `uses` (extendable via `<script … uses="Tina4Http,…">`).
  The body is ordinary Pascal — procedures plus an `initialization` section that
  `RegisterAction(...)`s them.
- If the project has no `main.pas`, a host is generated too, so an app can be **just
  an `app.html`**. `tina4pascal dev` wires the generated unit onto the FPC unit path
  (`-Fu <app>/.tina4`) and runs it.
- The engine already ignores `<script>` at render time (it reads the body as raw text
  and does not display it), so no page change is needed.
- `.tina4/` is generated output — git-ignored, never edited by hand.

## Consequences

- One-file apps work: `examples/inline` is a single `app.html` whose counter logic
  lives in its `<script type="text/pascal">` and is compiled on `dev`.
- It is still **native and type-checked** — a syntax error in the block is a compile
  error, not a runtime surprise. No sandbox, no interpreter attack surface, no perf
  cost. This is the whole reason to extract-and-compile rather than embed a VM.
- The contract for a block: valid Pascal implementation-section code + an
  `initialization` that registers actions; extra units via the `uses` attribute.
- Scope today is the **desktop `dev`** path (the edit-run loop). Wiring the same
  extraction into `build`/`run_project` and the mobile `--dump-html` + `appUnits`
  packaging is the follow-up in
  [`plan/code-editing-highlighting.md`](../code-editing-highlighting.md).
- If you are tempted to make `<script>` run at runtime instead, you are reintroducing
  a scripting engine the project deliberately omits (ADR-0002) — don't; extend the
  extractor or the native API instead.
