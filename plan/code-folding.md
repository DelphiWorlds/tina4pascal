# Task: `<codearea>` code folding

**Outcome:** the native code editor folds indentation blocks — a ▾/▸ gutter arrow
on every foldable line, a tap collapses the block (hidden lines, a dim ⋯ on the
header), and fold state round-trips through the DOM so it survives re-layout.

## Scope
- [x] `src/Tina4CodeFold.pas` — pure fold model (header detection, range end,
      visible view, `_folds` parse/format/toggle). No OS, no canvas (ADR-0001).
- [x] `tests/test_codefold.pas` — 20 assertions over the model, wired into `test`.
- [x] Renderer (`Tina4HTMLLayout.MakeControl`): fold-aware codearea paint — arrows,
      ⋯ marker, hidden lines, source-true line numbers, scroll on visible rows.
- [x] Fold-arrow hit targets recorded on the box (`TLayoutBox.FoldSpots`).
- [x] Click handler (`Tina4Interact.TryToggleFold`): a tap on the arrow toggles
      `_folds` and re-lays-out, instead of focusing the editor.
- [x] `ADR-0010` records the decision; MASTER index updated; developer skill noted.

## Parity
| Surface | macOS/iOS | Android | Windows/Linux |
|---|---|---|---|
| Fold model (`Tina4CodeFold`) | ✅ pure Pascal — identical on every target |
| Codearea render + click | ✅ core renderer/interact — identical on every shell |

Folding is engine-core (pure logic + the shared renderer/interact), so it is the
same on every platform; nothing shell-specific was touched.

## Tests (real)
- [x] `tina4pascal test` → **all suites pass** (incl. new `test_codefold`, 20/20,
      and `test_codearea`).
- [x] `sh tools/run-raster-tests.sh` → **11/11**.
- [x] `sh tools/run-compliance.sh` → **222/222**.
- [x] Visual: `<codearea lang="pascal" line-numbers>` rendered expanded (both
      `begin` lines show ▾) and with `_folds="3"` (inner `begin` → ▸ ⋯, DoFirst/
      DoSecond hidden, numbers jump 4→7). Confirmed via htmlviewer --snapshot.

## Bugs
- [x] `ParseFolds` pre-sized the result with zeros, so the dedupe saw a phantom 0
      and dropped a real `0` index — fixed to dedupe over the filled prefix only
      (caught by `test_codefold`).

## Commits
- <pending>  feat(codearea): indentation code folding

## Status: Complete
