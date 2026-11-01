# Plan 0038: Build "Test walks fill the chest, fresh steps on the chest screen, grey gear in the chest sheet" (spec 0013 amendment 4)

Status: accepted
Spec: `specs/0013-daily-chest.amendment-4.md` · Product owner: Zkalf · Date: 2026-11-01

Names of files, widgets and tests refer to `main` at `639213c`.

## What changes in the code
- `app/lib/game_controller.dart`, `testWalk`: passes `day: dayKey(now)` to `applySteps`, as the sync does, so the
  steps count toward the supply chest of that day.
- `app/lib/ui/supply_chest_screen.dart`:
  - `SupplyChestScreen` becomes a `StatefulWidget`. Its `initState` starts `GameController.syncNow()` (#167).
  - `_ChestSheet` reads the controller through `ControllerScope`, so it rebuilds when the bag changes. A gear row
    whose item is no longer in the bag is a disabled `ListTile`: grey, with no tap (#168).
- `packages/game_core/lib/src/game/supply.dart` (#169, no rule change): `openSupplyChest` and `openAllSupplyChests`
  return a `SupplyOpenResult` with the new state, the number of chests opened and what they held, as `salvage`
  returns a `SalvageResult`.
- `packages/game_core/lib/src/game.dart`: the class `SupplyOpenResult`.
- `app/lib/game_controller.dart`: `openSupplyChest` and `openAllSupplyChests` take the count and the items from the
  result. They no longer work them out from the state.
- `packages/game_core/lib/simulation.dart` and `packages/game_core/test/supply_chest_test.dart`: use `.state` of the
  result.
- `app/test/supply_chest_screens_test.dart`: the test of criterion 11 syncs 3 days, as the wording of spec 0013
  criterion 11 says (#169).
- No change to the data, the save or the pacing.
- `releases/next.md`: no line. The supply chest is not released yet, and its line already covers the screen. Test
  walks are for the owner only.

## Order of work
### M1: the nits (one PR)
- First, the failing tests, committed alone, in `app/test/supply_chest_screens_test.dart`:
  - The test "criterion 7: a test walk earns no chest" becomes: a test walk counts its steps toward today's chest
    (amendment criterion 1) and a test walk of the goal earns the chest (2).
  - Steps walked after the last sync show on the screen after it opens (3).
  - A worn piece of gear turns grey and stays in the sheet (4).
  - A salvaged piece of gear turns grey and stays in the sheet (5).
  - A tap on a grey row opens no item card (6).
  - A row of gear still in the bag keeps its colour and opens its card (7).
  - In `packages/game_core/test/supply_chest_test.dart`: the open returns the count and the items.
- Then the code.
- **Proof:** `.\scripts\check.ps1 -Release` green (criteria 8-9). The verifier checks the change against criteria
  1-7.
- Branch `fix/supply-chest-nits`. PR with the amendment and this plan, review per `REVIEW.md`. The owner merges.
