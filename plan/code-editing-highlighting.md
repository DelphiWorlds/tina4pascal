# Task: code editing & syntax highlighting (`<codearea>`)

**Outcome:** a first-class, editable, multi-language syntax-highlighting code control
in the engine, plus the pure highlighter it rests on — usable from HTML with no app
code. See [ADR-0008](adr/0008-text-editing-and-highlighting.md).

## Scope
- [x] `src/Tina4Highlight.pas` — generic lexer + `THLLanguage` + registry
- [x] Built-in languages: pascal, php
- [x] Load a language from memory (`LoadLanguageFromString`) and disk (`LoadLanguageFromFile`)
- [x] `<codearea>` element: raw-literal body, `value` seeding, explicit `value` wins
- [x] `<codearea>` edits like a textarea (focus, caret, IME, tab order, `oninput`, result-fill)
- [x] `lang="…"` selects the highlighter; unknown falls back to pascal
- [x] `line-numbers` gutter
- [x] Engine: `TinaKey` dispatches `oninput`; controls honour an explicit `background`
- [x] Examples: `examples/codearea` (php + pascal + disk-loaded sql), `examples/codeeditor`, `examples/codeviewer`
- [x] Tests: `tests/test_highlight.pas`, `tests/test_codearea.pas` (both in the suite)
- [ ] **Full caret model** (next, ADR-worthy): caret index, insert/delete-at-caret,
      selection, arrow/Home/End, click-to-place → unlocks mid-buffer editing and the
      single-pane overlay for plain textareas.
- [ ] **DOM load/ready action** so a control can seed its first paint without a keystroke.
- [ ] **`<script type="text/pascal">` extract-and-compile** (requested): lift inline
      Pascal from app.html at build time into a generated AppLogic unit and compile it
      in, so UI + behaviour live in one file. AOT, not interpreted (the engine has no
      Pascal VM). Needs CLI work in `tools/tina4pascal` (run / build / --dump-html).
- [ ] Multi-line block comments/strings coloured across line breaks (currently per-line).

## Parity
| Surface | macOS | Windows/Linux | Android/iOS |
|---|---|---|---|
| Tina4Highlight (pure) | ✅ | ✅ (pure Pascal) | ✅ (pure Pascal) |
| `<codearea>` render + edit | ✅ verified | ✅ (shared layout/shell) | ✅ (shared layout; IME kind 2) |
| Language from disk | ✅ | ✅ | bundle `languages/` or use in-memory def |

## Tests (real)
- [x] `tools/tina4pascal test` — all suites pass (incl. `test_highlight` 24 asserts, `test_codearea` 9 asserts)
- [x] `sh tools/run-compliance.sh` — 222 pass, 0 fail
- [x] `sh tools/run-raster-tests.sh` — 11 pass, 0 fail
- [x] Visual: `examples/codearea` snapshot (php/pascal/disk-sql) and `examples/codeeditor`
      scripted typing (type → re-highlight, focus ring, line numbers) both verified.

## Bugs (found + fixed)
- [x] Control `background:transparent` / any author background was overwritten by the
      light UA surface → added `BackgroundExplicit` so the author wins.
- [x] `.lang` loader dropped wrapped list lines → repeat the key to append (documented).
- [x] Unit doc comment contained literal `{ } {$` which broke FPC's non-nesting brace
      comment → reworded.

## Commits
- (this change) feat(highlight) + feat(codearea) + engine oninput/background + examples/tests

## Status: Core complete; caret model, load/ready, and `<script>` extraction are follow-ups.
