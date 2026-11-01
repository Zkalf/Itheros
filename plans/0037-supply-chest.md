# Plan 0037: Build "The supply chest" (spec 0013)

Status: accepted
Spec: `specs/0013-daily-chest.md` · Product owner: Zkalf · Date: 2026-11-01

Names of files, widgets and tests refer to `main` at `9eb9f53`.

## What changes in the code

### `packages/game_core`
- `data/economy.json`: a new `supplyChest` block with every number of the spec (criterion 59):
  - `goal` 5000
  - `materials` 5
  - `meals` 2
  - `gearChance` 0.2
  - `shardChance` 0.02
  - `qualityBoost` 2
  - `gearWindow` 4 (the player's level minus 4)
  - `exclude`: `kings_blade`, `chieftains_amulet`, `dragons_heart`, `golden_antler_mantle`, `drowned_captains_ring`
- `lib/src/data.dart`: reads `supplyChest`. The data check refuses:
  - an `exclude` id that is not gear
  - a chance outside 0 to 1
  - a `goal` below 1
  - a `qualityBoost` below 1
- `lib/src/state.dart`: the four save fields of spec §4 (`supplySteps`, `supplyPaid`, `supplyChests`, `supplyRng`),
  in `copy`, `toJson` and `fromJson`. `schemaVersion` becomes 14.
- `lib/src/game/migrate.dart`: a version 13 save gets empty fields and a `supplyRng` derived from its `rngState`.
- `lib/src/game/items.dart`: `applySteps(state, walked, {String? day})`. Without `day`, nothing counts (spec §2.1
  point 7).
- `lib/src/game/run.dart`: `step()` adds `1 + boost` to the day's count when an action runs. The step that reaches
  the goal earns the chest and rolls it at once (spec §2.2, §2.3).
- `lib/src/game/supply.dart` (new, `part of game.dart`):
  - `rollSupplyChest`: the common roll, the gear and the shard of spec §2.4, all from `supplyRng`
  - `supplyWindow(level)`: the gear of the window, without `exclude`
  - `openSupplyChest(s)` and `openAllSupplyChests(s)`: move the contents into the bag
  - `supplyToday(s, day)`: the day's count and whether it paid
  - the pruning of `supplySteps` and `supplyPaid` to the 14 most recent days
- `lib/src/game/odds.dart`: `rollQuality` gets a multiplier for rare, epic and legendary (default 1). Monster drops,
  crafts and salvage keep their rolls.
- `lib/src/events.dart`: `SupplyChestEarned(day)`.
- `lib/simulation.dart`: each sim day passes a day key to `applySteps`. The walker opens each chest at once. Its
  normal gear choice then equips what is better.
- `tool/simulate.dart`: prints the share of days that pay a chest. `--no-chests` runs the same walk without days,
  for the comparison of spec §5.

### `app`
- `lib/sync/sync_service.dart`: passes `dayKey(d)` to `applySteps` for each day. Test walks (`GameController.testWalk`)
  pass no day.
- `lib/game_controller.dart`: `openSupplyChest()` and `openAllSupplyChests()`, through the one queue, sync first
  (`CLAUDE.md`). A getter for today's count, from `dayKey(now)`.
- `lib/ui/home_shell.dart`: the supply chest button (`supply-chest-button`) left of `achievements-button` on the
  `BarPlate`, with a dot (`supply-chest-dot`) while a chest waits.
- `lib/ui/supply_chest_screen.dart` (new): the screen of spec §3.2 and the chest sheet of §3.3.
- `lib/sync/away_summary.dart`: counts `SupplyChestEarned`. A journal entry from before this change reads as 0
  chests.
- `lib/ui/away_summary_card.dart`: the line "Supply chest earned" or "N supply chests earned".
- `releases/next.md`: a line for players (criterion 61).

### What does not change
- Monster drops, crafts, salvage, catches and their chances.
- The queue, the bank, the step count of the sync, and test walks.
- No new permission. No network code.

## Choices this plan makes
- **The day is an opaque key.** `game_core` gets the app's `yyyy-mm-dd` key and never reads a clock. Keys sort as
  text, so "the 14 most recent days" is the last 14 keys in text order. The sim uses keys of the same shape.
- **`supplyRng` for an old save** is `rngState` mixed with a fixed constant, as the lore roll does in `run.dart`. A
  load gives the same stream each time.
- **One generator per chest:** each chest seeds its own generator from one draw of `supplyRng`. So the number of
  rolls in one chest never shifts the next chest.
- **The walker opens chests at once.** A real player can wait, but the contents do not change (spec §2.3), so the
  pace is the same.

## Order of work

### M1: the rules, the data, the save and the sim (one PR)
- First, the failing tests, committed alone (`packages/game_core/test/supply_chest_test.dart`):
  - the goal: criteria 1-8
  - earning: criteria 9-13
  - contents: criteria 14-29 (seeded runs of many chests for 19 and 20)
  - rolled at once: criteria 30-32
  - opening: criteria 33-35
  - the save: criteria 52, 53 and 55, in `game_core`
- Then the code.
- Then the hand-run sim (`CLAUDE.md`: drop and quality chances move the pace):
  - `dart run tool/simulate.dart --steps-per-day 5000`, with and without `--no-chests`
  - the PR reports the share of days that pay a chest and the levels at day 7, 30 and 90, with and without chests
    (criterion 58)
  - if the average walker leaves a level target of the pacing test, I stop and ask the owner before any tuning
- **Proof:** `.\scripts\check.ps1 -Pacing` green (criteria 56 and 57), and the sim table in the PR. The verifier checks
  criteria 1-35, 52-53, 55-59.
- Branch `daily-chest`. The PR also holds intent 0013 amendments 1 and 2, spec 0013 and this plan. Review per
  `REVIEW.md`. The owner merges.

### M2: the screens and the sync (one PR)
- First, the failing tests, committed alone:
  - `app/test/supply_chest_screens_test.dart`: the button, the dot, the screen, the sheet (criteria 36-48)
  - `app/test/away_summary_test.dart`: the chest lines and the journal (criteria 49-51)
  - `app/test/sync_service_test.dart`: the sync passes each day's key; a test walk earns nothing (criteria 7, 11)
  - `app/test/save_fixtures_test.dart` stays green with every fixture (criterion 54)
- Then the code and the line in `releases/next.md`.
- **Proof:** `.\scripts\check.ps1 -Release` green (criterion 60). The verifier checks criteria 36-51, 54, 60-61. A
  playtest on the owner's phone at the end, if the owner wants it.
- Branch `supply-chest-screens`, from `main` after M1. PR, review per `REVIEW.md`. The owner merges. The PR closes
  #57.
