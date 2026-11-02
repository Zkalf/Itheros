# Plan 0041: Build "The bag limit" (spec 0021)

Status: accepted
Spec: `specs/0021-bag-limit.md` (with intent 0020 amendment 1) · Issue: #173 · Product owner: Zkalf · Date: 2026-11-02

Names of files, widgets and tests refer to `main` at `9f2cc34`.

## What changes in the code
**game_core**
- `packages/game_core/data/economy.json`: a new `bag` block: `spaces` 40, `overloadStep` 0.05, `overloadMax` 0.5.
- `packages/game_core/lib/src/data.dart`: `GameData.bagSpaces`, `bagOverloadStep`, `bagOverloadMax`, read from the
  `bag` block.
- `packages/game_core/data/talents.json`: the new talent `bigger_bag` (spec 0021 rule 11).
- `packages/game_core/lib/src/data/talents.dart`: a new `TalentEffect.bagSpaces`.
- `packages/game_core/lib/src/game/bank.dart` (the `GameBank` extension):
  - `bagSpaces(s)`: `bagSpaces` plus `talentSum(s, TalentEffect.bagSpaces)`.
  - `spacesUsed(s)`: the keys in `s.inventory` with a count of 1 or more.
  - `overloaded(s)` and `overload(s)`: the share of rule 5, from 0 to `bagOverloadMax`.
- `packages/game_core/lib/src/game/world.dart`, `_costOf`: each unit cost takes the factor (1 + overload) before
  its one rounding up (rule 6). A craft or a reroll at a place with a bank (`hasBank(s.location)`) takes no factor
  (rule 7).
  - `professionSteps` and `travelCost` get the factor as an argument, so the rounding stays in one place.
  - `fightStepsBack` does not change (rule 8).
- `unitCost` uses `_costOf`, so the queue, the action sheet and the estimates follow (rule 10). No change there.
- No change to the save (version 16), to how items go into the bag, or to the bank moves.

**The sim**
- `packages/game_core/tool/bag.dart` (new): the bag-fill sim of spec 0021 §5, with `--bank`, `--fighter`,
  `--gatherer`, `--seeds`, `--days`, `--limit`. It prints the medians of §5 and the four targets of §5.3.
- `packages/game_core/lib/simulation.dart`, `SensiblePlayer` (spec 0021 point 22):
  - `decide`: when the walker is overloaded, and storing its materials and spare gear would end it, it walks to
    Camp.
  - At Camp, when overloaded or over `bagSpaces - 10`, it stores every material, and the gear that it neither
    wears nor keeps (the keep set of `_salvageSpares`, moved to a helper that both use).
  - `_locationFor` for a craft: Camp when the bag alone does not hold the inputs, but the bag and the bank do.
  - It takes no Bigger bag ranks.
- `packages/game_core/test/pacing_test.dart`: no new test. Its ranges stay as they are; the overloaded rule now
  runs in it (point 23).

**app**
- `app/lib/ui/character_tab.dart`: the spaces line above `BagGrid` (points 13, 14).
- `app/lib/ui/bank_screen.dart`: the same line above the Bag tab's list (point 18). The line is one widget,
  `BagSpacesLine`, in a new `app/lib/ui/bag_spaces.dart`.
- `app/lib/ui/now_tab.dart`, `_StatusCard`: the Overloaded line under "Walked today", and its sheet (points 15-17).
- `app/lib/ui/talents_tab.dart`, `talentIcon`: `bag` gives `Icons.backpack` (point 19).
- The talent card shows "+2 bag spaces" for each rank, by the way it shows the other effects today (point 20).
- `releases/next.md`: one line for players about the bag limit and Bigger bag.

## Choices this plan makes
- The sim walker's banking is a habit of the walker, not a rule. The game does not walk the player to Camp.
- The pacing test keeps its ranges. If the overloaded rule moves a range out, Claude stops and reports to the owner
  (spec 0021 §5.3).

## Order of work
### M1: The rules and the sim (one PR)
- First, the failing tests in a new `packages/game_core/test/bag_limit_test.dart`, committed alone:
  - Spaces: criteria 1-8.
  - Nothing is lost: criteria 9-12.
  - The step cost: criteria 13-26, with Camp for the free crafts, cooks and rerolls and Grey Moor for the ones
    that cost more.
  - The talent: criteria 27-29.
  - Save: criteria 37-39 (a save with 45 kinds loads overloaded, with every item).
- Then the code, the data and the walker.
- Then the sim: `dart run tool/bag.dart` for the mixed walker, the fighter and the gatherer, with `--bank`, on 16
  seeds. The PR description gives the tables of spec 0021 §5 and the four targets of §5.3.
- **Proof:** `.\scripts\check.ps1 -Release -Pacing` green. The four targets hold, or the owner accepts the numbers
  (criterion 41). The verifier checks criteria 1-29, 37-43.
- Branch `feat/bag-limit`. PR with the spec, the intent amendment and this plan; review per `REVIEW.md`. The owner
  merges.

### M2: The screens (one PR)
- First, the failing widget tests, committed alone (with `MemorySaveStore`):
  - The Bag pane shows "Spaces N / M" (criterion 30).
  - An overloaded Bag pane shows the overload in `Quiet.risky` (criterion 31).
  - Now shows the Overloaded line only when overloaded (criteria 32, 33).
  - A tap on the line opens the sheet with its title and four lines (criterion 34).
  - The bank screen's Bag tab shows the spaces line (criterion 35).
  - Bigger bag shows at Utility row 1, column 2, with the bag icon (criterion 36).
- Then the code and the `releases/next.md` line (criterion 44).
- **Proof:** `.\scripts\check.ps1 -Release` green. The verifier checks criteria 30-36, 42-44. A screenshot of the
  Bag pane and of Now, overloaded, in the PR.
- Branch `feat/bag-limit-screens` from `main` after M1 merges. PR, review per `REVIEW.md`. The owner merges.
