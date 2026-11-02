# Plan 0040: Build "The item bank" (spec 0020)

Status: accepted
Spec: `specs/0020-item-bank.md` · Product owner: Zkalf · Date: 2026-11-02

Names of files, widgets and tests refer to `main` at `ebb5ca8`.

## What changes in the code
**game_core**
- `packages/game_core/lib/src/state.dart`:
  - `GameState.bank`: a `Map<String, int>` saved as `bank`, empty in an old save.
  - `GameState.schemaVersion` becomes 16.
- `packages/game_core/lib/src/data/world.dart` (the location definition): a `bank` flag, read from `"bank": true`.
- `packages/game_core/data/world.json`: Camp gets `"bank": true`.
- `packages/game_core/lib/src/game/bank.dart` (new extension `GameBank`):
  - `hasBank(location)`.
  - `store(s, key, count)` and `take(s, key, count)`, with the refusals of rules 5 and 6 and decision 4 as
    `ActivityError`.
  - `materials(s)`: the items that a craft at the player's location can use. This is the bag, plus the bank at a
    place with a bank.
- `packages/game_core/lib/src/game/items.dart`:
  - `hasMaterials` and `missingFor` count `materials(s)` (rules 7-9). The queue checks a craft when it starts, at
    its place, so this also covers a craft queued for Camp (rule 9).
  - `owned` counts the bank (rule 10). "Until I have N", the next goal and the found lists all use `owned`.
- `packages/game_core/lib/src/game/run.dart`, the craft step: it takes each input from the bag first, then from the
  bank at a place with a bank (rule 7).
- The sim does not change. The sim walker never stores anything, so its bank stays empty.

**app**
- `app/lib/game_controller.dart`: `store(key, count)` and `take(key, count)`, through `_act` (sync first, one queue).
- `app/lib/ui/bank_screen.dart` (new): the screen of §3.2, with the tabs Bag and Bank, and the move sheet with Store or
  Take all and some. "Some" reuses the "How many?" dialog of `action_sheet.dart`, moved to a shared helper if it is
  private.
- `app/lib/ui/now_tab.dart`: the Bank card in "Here" at a place with a bank.
- `app/lib/ui/character_tab.dart`: the button Bank under the bag.
- `app/lib/ui/profession_screen.dart` and `app/lib/ui/action_sheet.dart`: the "have" counts, the "Have the materials"
  filter and `craftsAllowed` count `materials(s)` (§3.3).
- `releases/next.md`: a line for players.

**Tests that change:** the tests that assert schema 15 assert 16.

## Order of work
### M1: the bank (one PR)
- First, the failing tests, committed alone:
  - `packages/game_core/test/bank_test.dart` (new): criteria 1-15 and 26-27.
  - `app/test/bank_screens_test.dart` (new): criteria 16-25 and 31.
  - The version tests that change.
- Then the code.
- **Proof:** `.\scripts\check.ps1 -Release` green, the pacing sims included (criteria 28-30). The verifier checks the
  change against criteria 1-32. Screenshots of the bank screen at the Fairphone's 408 dp width go to the owner.
- Branch `feat/item-bank`. PR with the intent, the spec and this plan, review per `REVIEW.md`. The owner merges.
