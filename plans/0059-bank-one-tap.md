# Plan 0059: Build "the bank in one tap, and Store all materials"

Status: accepted
Spec: `specs/0020-item-bank.amendment-5.md` · Product owner: Zkalf · Date: 2026-11-10

Names of files, widgets and tests refer to `main` at `84cf733`.

## What changes in the code
- `packages/game_core/lib/src/game/items.dart` (beside `store`): `storeAllMaterials(state)` moves the whole stack of
  each item of `ItemKind.material` from the bag to the item bank. It refuses away from a place with a bank, as
  `store` does. It rolls nothing.
- `app/lib/game_controller.dart`: `storeAllMaterials()` through `_act`, as `storeInBank`.
- `app/lib/ui/home_shell.dart`: the `IconButton` `bank-button` at the left end of the `BarPlate`, with
  `Icons.account_balance` and the tooltip "Bank". It calls `openBank`.
- `app/lib/ui/bank_screen.dart`, `_ItemList`: the button `store-all-materials` under `BagSpacesLine`, at a place
  with a bank and with a material in the bag. After the move it shows the note in a `SnackBar`.
- Tests:
  - `packages/game_core/test/store_all_materials_test.dart`: criteria 7, 8, 15 and 16.
  - `app/test/bank_one_tap_test.dart`: criteria 1 to 6, 9 to 14 and 17.
- `releases/next/feat-bank-one-tap.md`: the line for players.
- No change to the data, the save or the sim. The sim walker does not use the bank.

## Order of work
### M1: the button and the move (one PR)
- The tests first, then the code.
- **Proof:** `.\scripts\check.ps1 -Release` green. A render at 408 dp wide of the top bar with five buttons and of
  the Bag tab with Store all materials.
- Branch `feat/bank-one-tap`. PR with the amendment and this plan, `Closes #249`, review per `REVIEW.md`. The owner
  merges.
