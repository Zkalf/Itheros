# Plan 0056: Build "a stack limit for each kind of item" (spec 0021 amendment 4)

Status: accepted
Spec: `specs/0021-bag-limit.amendment-4.md` · Issue: #228 · Product owner: Zkalf · Date: 2026-11-09

Names of files, widgets and tests refer to `main` at `44e3e0f`.

## Choices this plan makes
- **One PR.** The rule is one function (`spacesUsed`); the screens are the bag grid, one card line and the
  Overloaded sheet.
- **One rule in one place.** `Game.spacesOf(key, count)` gives the spaces of one bag item. `spacesUsed`, the sim
  walker and the bag grid all use it, so the count on screen and the count in the rules can't differ.
- **No new save field and no migration** (change 13).

## What changes in the code

### game_core
- `data/economy.json`: `"stacks": { "material": 100, "meal": 20, "gear": 1, "tool": 1 }` in `bag` (change 1).
- `lib/src/data.dart`: `GameData.bagStacks` (`Map<ItemKind, int>`), read from `bag.stacks`; validation: all four
  kinds, each 1 or more.
- `lib/src/game/items.dart`: `GameData.stackOf(key)`, the stack size of the kind of `key`.
- `lib/src/game/bank.dart`: `spacesOf(key, count)` (count ÷ stack, rounded up) and `spacesUsed` as its sum over the
  bag (change 2). `overloaded`, `overload` and the "Until the bag is full" stop (`queue.dart`) read `spacesUsed`, so
  they follow with no change (change 5).
- `lib/simulation.dart`: `_goBank` counts the spaces of what it keeps with `spacesOf`; `_takeInputs` checks the
  spaces after the take with `spacesOf` (change 14).
- New `test/stack_limit_test.dart`: criteria 1-8, 15.

### app
- `lib/ui/bag_grid.dart`: one `ItemSquare` for each stack (change 6), full stacks first. The first square keeps the
  key `bag-<item>`, the next ones `bag-<item>-2`, `bag-<item>-3`, so today's tests still find the item.
- `lib/ui/item_card.dart`: the line "Up to 100 in a bag space." for a material or a meal (change 9).
- `lib/ui/bag_spaces.dart`: the two new lines of the Overloaded sheet (change 10).
- The bank screen does not change (change 12): its test checks it.
- New `test/stack_limit_screens_test.dart`: criteria 9-14.
- `releases/next/feat-stack-limit.md`: one line for players.

## Order of work
1. The tests: criteria 1-15.
2. The code and the data.
3. The hand sims at 5,000 steps a day, seeds 1-16, mixed and fighter (`dart run tool/bag.dart`), with `main` and with
   the branch: the numbers of the Balance section again, now with the walker of change 14.
4. Renders at 408 dp wide: the bag grid with copper ore in three squares, and the copper ore card (criterion 17).
5. **Proof:**
   - `.\scripts\check.ps1 -Release -Pacing` green, or the pacing test trips and Claude reports its numbers once
     (criterion 16).
   - The sim numbers in the PR description.
   - The verifier runs alongside the local check, before the PR.
   - Review per `REVIEW.md`; the owner merges.

Branch `feat/stack-limit`.

## Risks
- **Friends' saves.** A save with big stacks of one material can load overloaded at once (change 13). Nothing is
  lost: a store in the bank or a destroy ends it. The release note says so.
- **The pace.** 3-4.5 days later to level 30 in the throwaway run. If the run with the new walker differs much, Claude
  reports it before the PR.
