# ADR-0008: `<codearea>`, the syntax-highlighter registry, and the text-edit model

- **Status:** Accepted
- **Date:** 2026-10-01

## Context

Clients asked for a code-editing control with syntax highlighting. Three questions
had to be settled, because each outlives the commit:

1. **Where does a highlighter live, and how is a language chosen?** The three-layer
   law (ADR-0001) keeps OS code out of the core; the maintainer convention keeps
   *app-specific* units (ones that register actions) out of `src/`. A lexer that
   turns source into coloured runs is neither — it is pure, portable, reusable
   renderer-support. And one hard-coded language is not enough: callers need PHP,
   SQL, their own DSL.
2. **How is a code editor expressed in the HTML-drives-everything model (ADR-0002)?**
   An overlay of a transparent `<textarea>` over a highlighted `<pre>` was tried and
   rejected — it needs pixel-perfect alignment and is defeated by the UA control
   background. The engine should give authors a *first-class element*, not a recipe.
3. **How does app logic see a text edit?** Before this, `TinaKey`
   (`src/Tina4Interact.pas`) mutated a field's `value` but dispatched nothing — only
   the range slider fired `oninput`. Live-reacting fields were impossible without
   polling.

A constraint bounds the editing: the caret is **append/backspace-at-end only** — no
caret index, arrow-key navigation, selection, or click-to-place, and there is no DOM
"load" event. So the editor can highlight-as-you-type but not yet edit mid-buffer.

## Decision

1. **`src/Tina4Highlight.pas`** is a multi-language highlighter: one generic lexer
   driven by a `THLLanguage` definition (keywords, types, comment/string syntax, a
   variable sigil, a directive prefix). Languages live in a **registry** —
   `pascal` and `php` are built in; more are added at runtime from memory
   (`RegisterLanguage` / `LoadLanguageFromString`) or disk (`LoadLanguageFromFile`,
   a simple `key = value` format). It exposes `HighlightTokens` (for the canvas),
   `HighlightToHTML`, and `HighlightInto`. It lives in `src/` because it is pure and
   registers no actions.
2. **`<codearea lang="…" line-numbers>`** is a native control. The parser reads its
   body as **literal raw text** (so PHP's `<?php` and a bare `<` are not mis-parsed),
   seeds the control `value` from it, and honours an explicit `value` attribute. It
   behaves as a `<textarea>` for editing/caret/focus/IME/tab-order/`oninput`/result-
   fill, but the layout paints each line as coloured token runs (via the registry,
   keyed by `lang`), optionally behind a line-number gutter. It defaults to a dark
   monospace theme that the author can override.
3. **`TinaKey` now dispatches `oninput`** on the focused element after every value
   change — the one engine hook for any live-reacting field.
4. **Controls honour an explicitly-declared `background`** (new `BackgroundExplicit`
   on the computed style). Before, a control with `background:transparent` — or any
   author background — was overwritten by the light UA surface; now the author's
   choice wins, which is what lets `<codearea>` (and any dark-themed form) keep its
   background.

## Consequences

- A code **viewer** (HTML/`--dump-html`) and an editable, multi-language, line-
  numbered **`<codearea>`** both work today, cross-platform, with the highlighter in
  one tested pure unit. New languages need no engine change — a `.lang` file or an
  in-memory def.
- `oninput` on text fields is now public contract; it fires per keystroke, so
  handlers stay cheap. `<codearea>` re-tokenises the whole buffer each frame (fine
  for editor-sized text; it is not a diff).
- Per-line tokenisation means a block comment or string spanning multiple lines is
  re-coloured per line — acceptable for v1, noted in the plan.
- What this still forbids (the "if you're tempted" note): mid-buffer editing,
  click-to-place caret, and selection — all blocked on the **caret model**, not on
  highlighting. Delivering them means giving `TinaKey` a caret index +
  insert/delete-at-caret + selection, arrow/Home/End in the shells' key path, and a
  DOM load/ready action to seed first paint. That is a *new* ADR when decided; see
  [`plan/code-editing-highlighting.md`](../code-editing-highlighting.md).
- If you revert `BackgroundExplicit`, dark-themed controls break again; if you revert
  the `oninput` dispatch, live fields go silent. Both are contract, not one-offs.
