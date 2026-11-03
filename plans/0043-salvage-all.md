# Plan 0043: Build "Salvage all" (spec 0010 amendment 9)

Status: accepted
Spec: `specs/0010-professions.amendment-9.md` · Issue: #175 · Product owner: Zkalf · Date: 2026-11-03

## What changes in the code
**game_core** (`packages/game_core/lib/src/game/`)
- `items.dart`:
  - `salvageable(s, key)`: whether a single salvage takes the bag item `key` (rule 1). `salvage` uses it for its
    checks.
  - `salvageAll(s, keys)`: salvages each key of `keys` (each one as many times as the bag holds it), in the bag's
    order. It returns a `SalvageAllResult`.
  - `salvageAllOf(s, quality)`: the keys of a quality batch, for the Bag button and its count.
- `game.dart`: `SalvageAllResult(state, count, dust, shards)`. `dust` and `shards` are maps from item to count.
- `bagOrder` moves from `app/lib/ui/bag_grid.dart` to game_core, so the rule and the Bag share one order. The app
  imports it from game_core.

**app**
- `game_controller.dart`: `salvageAll(keys)` through the queue, like `salvage`.
- `bag_grid.dart` or `character_tab.dart`: the quality buttons under the Bag, at a forge only.
- `item_card.dart`: "Salvage all (N)" next to Salvage for a stack of 2 or more. The dialog of rule 4 is shared by
  both buttons.
- `labels.dart`: the batch message of rule 6.
- `releases/next.md`: one line for players.

## Order of work (one PR)
1. The tests:
   - `packages/game_core/test/`: criteria 1-7.
   - `app/test/`: criteria 8-15, with `MemorySaveStore`.
2. The code and the `releases/next.md` line.
3. **Proof:** `.\scripts\check.ps1 -Release` green. Review per `REVIEW.md`; the owner merges. The PR body says
   "Closes #175".

Branch `feat/salvage-all`.
