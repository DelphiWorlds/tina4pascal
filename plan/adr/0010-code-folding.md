# ADR-0010: `<codearea>` code folding by indentation

- **Status:** Accepted
- **Date:** 2026-10-05

## Context

`<codearea>` (ADR-0008) highlights code and edits append/backspace-at-end — there
is no caret index, arrow navigation, selection, or click-to-place. Clients asked to
**fold** blocks in the editor. Two design questions outlive the commit:

1. **What defines a foldable block?** Language-aware brackets (Pascal `begin/end`,
   C/PHP `{ }`) are precise but need per-language rules in the highlighter and would
   couple folding to the lexer. Indentation — "a line whose following lines are
   deeper is a header" — is language-agnostic, works for Pascal, PHP, SQL, Python and
   JSON with zero per-language rules, and is the universal fallback every editor
   ships. The editor's existing audience spans several languages via the highlighter
   registry, so a universal rule covers them all on day one.

2. **Where does fold state live, and how does it survive a re-layout?** The editor
   re-lays-out from the control `value` on every keystroke; there is no persistent
   document model to hang live fold ranges on. State must round-trip through the DOM
   like `_caret` does.

The append-at-end caret (ADR-0008) means folding needs no caret↔screen remapping —
it is a **rendering + gutter-click** feature, not an editing-model change.

## Decision

1. **`src/Tina4CodeFold.pas`** is a pure, OS-free, canvas-free unit (three-layer
   law, ADR-0001) that computes the fold model from source lines + a collapsed set:
   `IsFoldHeader`, `FoldRangeEnd` (trailing blanks trimmed), and `ComputeFoldView`
   (the visible lines, nesting-aware, self-healing when a stored index is no longer a
   header). Both the renderer (`Tina4HTMLLayout`) and the click handler
   (`Tina4Interact`) fold through this one definition, so they never disagree.
2. Foldability is chosen per language by **`TFoldRules`** (`FoldRulesForLang`):
   - **Indentation** is the universal default (PHP, SQL, JSON, Python, a DSL): a
     line whose following lines are deeper is a header.
   - **Routine folding** for Pascal: a `procedure`/`function`/`constructor`/
     `destructor`/`operator` declaration is the header, and its WHOLE body folds
     into the signature — the range runs through the routine's closing `end;`, so
     `begin`/`end` are hidden rather than folding on their own (`begin` is a
     *suppressed* keyword and gets no arrow). Inner indented blocks (an `if` with a
     deeper body) still fold by indentation. Both shapes produce the same
     `TFoldView`, so the renderer and click handler are unchanged.
   More language rule-sets (C/JS `{ }`, etc.) layer on by extending `FoldRulesForLang`.
3. Collapsed headers are stored on the tag in a **`_folds` attribute** (comma-
   separated source-line indices), parsed/toggled via `ParseFolds`/`ToggleFold` —
   the same DOM-round-trip pattern as `_caret`, so fold state survives every
   re-layout and carries no new engine state.
4. The gutter paints a `▾`/`▸` arrow beside each foldable line; a collapsed header
   trails a dim `⋯`. A tap on the arrow column toggles `_folds` and re-lays-out.

## Consequences

- Folding is universal across every highlighted language for free, and the lexer
  stays decoupled from folding. Bracket-aware folding is an additive follow-up.
- One source of truth (`Tina4CodeFold`) is unit-tested on its own
  (`tests/test_codefold.pas`), so the renderer and the hit-tester can never drift —
  the exact bug class that made the status-badge fix slow (duplicated logic).
- Fold state is per-element DOM data: it survives re-layout, serialises with the
  document, and needs no new globals. It can drift if the user inserts/deletes lines
  *above* a collapsed header (indices shift); `ComputeFoldView` re-validates and
  drops stale indices, so the worst case is a fold quietly re-opening, never a crash
  or a wrong hide.
- If you're tempted to move fold detection into `Tina4Highlight` per-language:
  don't do it as a *replacement*. The indentation view is the cross-language
  guarantee; brackets must refine it, not supplant it, or SQL/JSON/DSL authors lose
  folding.
