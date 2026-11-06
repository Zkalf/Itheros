# Plan 0049: Build "Destroy an item" (spec 0021 amendment 2)

Status: accepted
Spec: `specs/0021-bag-limit.amendment-2.md` · Issue: #180 · Product owner: Zkalf · Date: 2026-11-06

## What changes in the code
**game_core**
- `lib/src/game/items.dart`: `Game.destroy(GameState s, String key, int count, {bool fromBank = false})`. It
  returns a new state without the items. It throws `ActivityError` when the bag or the bank holds fewer than
  `count` (rules 1-5).
- Unit tests in a new `test/destroy_test.dart`: criteria 1-6.

**app**
- `lib/game_controller.dart`: `destroy(key, count, {fromBank})` through the one queue, with a sync first (rule 6).
- `lib/ui/item_card.dart`: a Destroy button on the bag card and on both bank cards, not on a worn item or the tool
  in use. It asks "How many?" for a stack, then the confirm dialog, then shows the message (rules 8-12).
- `lib/ui/labels.dart`: the words of the dialog and the message ("Destroy 12 Goblin bones?", "Destroyed 12 Goblin
  bones.").
- `releases/next/feat-destroy-items.md`: one line for players.

No change in `data/` or the save.

## Tests
- `packages/game_core/test/destroy_test.dart`: criteria 1-6.
- `app/test/destroy_items_test.dart`: criteria 7-15.

## Order of work (one PR)
1. The tests: criteria 1-15.
2. The code and the notes line.
3. **Proof:** the item card with Destroy, the "How many?" dialog and the confirm dialog, rendered at 408 dp wide
   (`CLAUDE.md`). `.\scripts\check.ps1 -Release` green (with the pacing sims, as `game_core` changes). Review per
   `REVIEW.md`; the owner merges.

Branch `feat/destroy-items`.
