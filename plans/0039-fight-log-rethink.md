# Plan 0039: Build "A new fight log" (spec 0019)

Status: accepted
Spec: `specs/0019-fight-log-rethink.md` · Product owner: Zkalf · Date: 2026-11-01

Names of files, widgets and tests refer to `main` at `283744a`.

## What changes in the code
**game_core**
- `packages/game_core/lib/src/state.dart`:
  - A new class `FightSummary` (`number`, `outcome`, `rounds`, `taken`, `crits`) with `toJson` and `fromJson`.
  - `RunningActivity` gets `fights` (a `List<FightSummary>`). An old save loads it as an empty list.
  - `FightState` gets `taken` and `crits`: the damage taken and the crits of the fight so far. An old save loads
    them as 0.
  - `GameState.schemaVersion` becomes 15.
- `packages/game_core/lib/src/game/run.dart`, `_combatRound`:
  - In round 1 of a fight, the round log is emptied before the round is added (rule 3).
  - Each round adds its damage taken and its crit to `FightState`.
  - When the round ends the fight, a `FightSummary` is added. Its number is `won + lost + 1` of the action, before
    `_win` or `_lose` counts the fight. The list keeps the last `fightLogFights`.
  - No new roll. The order of the rolls does not change.
- `packages/game_core/lib/src/data.dart`: reads `fightLogFights` and checks that it is above 0.
- `packages/game_core/data/economy.json`: `fightLogFights` 10 (new) and `fightLogRounds` 4 → 50.

**app**
- `app/lib/ui/now_tab.dart`: the round lines go. The line "Last fight: …" and the text button Fight details
  (key `fight-details`) take their place.
- `app/lib/ui/fight_sheet.dart` (new): the fight sheet of spec 0019 §3.2 and §3.3. It reads the controller through
  `ControllerScope`, so a fight that ends while it is open shows in it. A `ListView` with `reverse: true` opens it at
  the bottom.
- `app/lib/ui/labels.dart`: the words of the Now line and the summaries. `fightLog` and `newFight` go. The swing
  words of `roundLines` stay, and a swing gets its kind, so the sheet can give it its look.
- `app/lib/ui/theme.dart`: no new colour.

**Tests that change**
- The tests that assert schema 14 (`supply_chest_test.dart`, `travel_slot_test.dart`, `world_route_test.dart`)
  assert 15.
- The test of the fight log on the Now screen in `ui_test.dart` (spec 0006 criterion 3) moves to the fight sheet.

**No change** to the fight rules, the rolls, the sim or the pacing.

## Choices this plan makes
- `FightState` saves the damage taken and the crits of the running fight. The round log keeps 50 rounds, so a sum
  over the log would be wrong for a longer fight. This adds two fields to the save beyond spec 0019 §4.
- A fight that runs when an old save loads starts its sums at 0. Its summary then counts only the rounds after the
  update.
- The owner chose this way on 2026-11-01, over a sum over the round log.

## Order of work
### M1: the fight log (one PR)
- First, the failing tests, committed alone:
  - `packages/game_core/test/fight_log_test.dart` (new): criteria 1-7 and 35-36.
  - `app/test/fight_log_screens_test.dart` (new): criteria 8-34.
  - The changed tests above.
- Then the code.
- `releases/next.md`: a line for players (criterion 40).
- **Proof:** `.\scripts\check.ps1 -Release` green, the pacing sims included (criteria 37-39). The verifier checks
  the change against criteria 1-40. Screenshots of the Now screen and the sheet, rendered on the PC at the
  Fairphone's 408 dp width, go in the PR.
- Branch `feat/fight-log`. PR with the intent, the spec and this plan, review per `REVIEW.md`. The owner merges.
