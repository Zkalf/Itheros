# Plan 0022: Build "Materials you have, need, use and keep"

Status: draft
Spec: `specs/0010-professions.amendment-5.md` · Issue: #89 · Product owner: Zkalf · Date: 2026-10-25

Names of files, widgets and tests refer to `main` at `2e770b7`.

## What changes in the code

### `game_core`
- `packages/game_core/lib/src/game.dart`:
  - A new `bagAfterQueue(GameState s)`. It returns the material counts after the current action and the waiting
    actions, by the rules of §3.1 and §3.2. It reads the state and never changes it (criterion 21).
  - A new `craftsAllowed(Map<String, int> bag, String recipe)`. It returns the number of crafts that [bag] allows.
    The recipe row and the action sheet both use it for "Enough for N".
  - A new `craftsFor(GameState s, Activity a, StopCondition stop, Map<String, int> bag)`. It returns the number of
    crafts for a stop choice (§2.2 table), or null when the number is unknown.
- The bag is a map from the base item id to its count, so a perfect meal counts as a meal (as `owned` does).
- No change to the rules of an action, the save, the data or the sim.

### `app`
- `app/lib/ui/professions_tab.dart`, `_RecipeTile`: the subtitle adds "Enough for N" after the materials, from the
  bag of now. "Enough for 0" takes `Quiet.short`. A recipe with no inputs shows none.
- `app/lib/ui/action_sheet.dart`: for a craft (not a reroll), a new `_MaterialsTable` below the stop choices:
  - the "After your queue" line when the queue has actions,
  - one row for each input: Have, Uses, Left, in `Quiet.short` when Have is below Uses,
  - "Enough for N" below the table when N is below the number of crafts, or when the number is unknown.
  - It rebuilds with the sheet's `setState`, so a change of the stop choice or the count updates it.
- The table uses the number font (`Fonts.number`) for the numbers, as the count does today.

## Order of work

### M1: The count in `game_core` (one PR)
- First, failing unit tests in a new `packages/game_core/test/materials_test.dart`, committed alone:
  - `craftsAllowed` with enough, short and no materials.
  - `craftsFor`: "Until 5 crafted" gives 5. A meal "Until I have N" gives N minus the meals in the bag, at least 0.
    "Until a quality" and "Never stop" give null (criteria 6, 10, 11).
  - `bagAfterQueue` with an empty queue equals the bag of now.
  - A queued craft "Until 3 crafted" lowers its inputs by 3 crafts and adds 3 outputs (criterion 15).
  - A queued craft with too few materials counts only the crafts they allow.
  - A queued gather "Until I have 20 Copper ore" raises it to at least 20 (criterion 16).
  - A queued gather "Until grey" or "Never stop" leaves the bag as it is (criterion 17).
  - A queued craft "Until a quality" uses all the crafts its materials allow (criterion 18).
  - The current action counts only its crafts still to come (criterion 19).
  - A queued reroll lowers its dust by 3 (criterion 20).
  - The state and its JSON are the same before and after `bagAfterQueue` (criterion 21).
- Then the code.
- **Proof:** `.\scripts\check.ps1 -Release` green.
- Branch `plan-0022-m1`, PR, review per `REVIEW.md`. The owner merges.

### M2: The screens (one PR)
- First, failing widget tests in a new `app/test/materials_screens_test.dart`, committed alone:
  - A recipe row shows "have/needed" and "Enough for N"; "Enough for 0" is in the short colour; a recipe without
    inputs shows none (criteria 1–4).
  - The action sheet of a craft shows Have, Uses and Left for each input (criterion 5).
  - "Until 5 crafted" with a need of 2 shows Uses 10; Left never goes below 0 (criteria 6, 7).
  - A short line takes the short colour, and "Enough for N" shows (criteria 8, 9).
  - A meal "Until I have N" counts the crafts from the meals in the bag (criterion 10).
  - "Until a quality" and "Never stop" show "–" and "Enough for N" (criterion 11).
  - A tap on the count's plus button and on another stop choice updates the table (criterion 12).
  - An empty queue: no "After your queue" line (criterion 13).
  - With a craft in the queue: "After your queue", and Have counts after that craft (criterion 14).
  - A reroll's sheet shows no table.
- Then the code.
- **Proof:** `.\scripts\check.ps1 -Release` green. The verifier checks the change against criteria 1–21.
- Branch `plan-0022-m2`, PR, review per `REVIEW.md`. The owner merges.
- After the merge, an install on the Fairphone for a playtest, if the owner wants one.

## Risks
- **Big text sizes.** Four columns can overflow at large system text. The table uses `Expanded` names and wraps;
  a widget test runs it at text scale 2.0.
- **Item keys with quality.** Gear outputs carry a quality key. The bag uses base ids, so a crafted ring counts
  as one ring whatever its quality.
