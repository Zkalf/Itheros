# Plan 0067: Build "hold an item to select several"

Status: accepted
Spec: `specs/0020-item-bank.amendment-8.md` · Product owner: Zkalf · Date: 2026-11-13

Names of files, widgets and tests refer to `main` at `bd2ea16`.

## What changes in the code
- `packages/game_core/lib/src/game/bank.dart` (beside `storeAllMaterials`): `storeItems(state, keys)` and
  `takeItems(state, keys)`. Each moves the whole count of each key that its list holds and skips the others. Each
  refuses away from a place with a bank, as `store` does. They roll nothing.
- `app/lib/game_controller.dart`: `storeItems(keys)` and `takeItems(keys)` through `_act`. Each gives the number of
  items that moved, counted after the sync. Salvage uses `salvageAll(keys)`, which exists.
- `app/lib/ui/item_selection.dart` (new):
  - `ItemSelection`: the selected keys of one list, with start, toggle and clear. It drops a key that left the list.
  - `SelectionBar`: the button × (`select-cancel`), the text "N selected" (`select-count`) and the action buttons
    (`select-store`, `select-take`, `select-salvage`).
  - `SelectedMark`: the fill `Quiet.selected` and the teal check mark of rule 6.
  - The functions that run Store, Take and Salvage and show the note. Salvage calls `salvageAll` of
    `salvage_all.dart` with the keys that `game.salvageable` allows.
- `app/lib/ui/item_square.dart`: `ItemSquare` gets `onLongPress` and `selected`.
- `app/lib/ui/bag_grid.dart`: `BagGrid` gets the selection. A hold starts it, and a tap toggles while it runs.
- `app/lib/ui/character_tab.dart`: holds the selection of the bag. The bar stands under the scroll view. A
  `PopScope` ends the selection on back. The selection ends on a change of pane and when no action is left.
- `app/lib/ui/home_shell.dart`: only if needed, so that a change of tab ends the selection (the Character tab
  leaves the tree, or the shell tells it).
- `app/lib/ui/bank_screen.dart`: `BankScreen` becomes stateful and holds the selection of the open tab. The bar is
  the `bottomNavigationBar` of its `Scaffold`. A `PopScope` ends the selection on back; a listener on the tab
  controller ends it on a change of tab. The rows get `onLongPress`, the mark and the toggle.
- `app/lib/ui/labels.dart`: `moved(verb, n)` for "Stored 12 items." and "Took 1 item."
- Tests:
  - `packages/game_core/test/move_items_test.dart`: criteria 1 to 6.
  - `app/test/select_items_test.dart`: criteria 7 to 34.
- `GLOSSARY.md`: **selection** and **selection bar**.
- `releases/next/feat-select-items.md`: the line for players.
- No change to the data, the save or the sim. The sim walker keeps its own store and salvage habits.

## Order of work
### M1: the selection, the bar and the three actions (one PR)
- The tests first, then the code.
- **Proof:** `.\scripts\check.ps1 -Release` green. The verifier checks the change against the criteria. A render at
  408 dp wide of the bank screen's Bag tab and of the bag on Character, each with a selection.
- Branch `feat/select-items`, in the main folder. PR with the amendment and this plan, `Closes #267`, review per
  `REVIEW.md`. The owner merges.
