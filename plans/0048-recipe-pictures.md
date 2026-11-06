# Plan 0048: Build "Pictures on recipe rows and in the materials table" (spec 0014 amendment 9)

Status: accepted
Spec: `specs/0014-quiet-teal.amendment-9.md` · Issue: none (follow-up of #86) · Product owner: Zkalf · Date:
2026-11-06

## What changes in the code
**app**
- `lib/ui/profession_screen.dart` (`_RecipeTile`): `leading` becomes `PictureSocket.item` of the recipe's output at
  48 dp. The `LevelBadge` moves into the title row before the name, as `ActionTile` does (rules 1-5).
- `lib/ui/action_sheet.dart` (`_MaterialsTable`): the name cell starts with a 32 dp socket of the material. A tap on
  the line opens `showItemCard` for the material (rules 6-8).
- `lib/ui/now_tab.dart` (`_QueueCard`): no stop line for a reroll, current or waiting (rule 9).
- `releases/next/feat-recipe-pictures.md`: one line for players.

No change in `game_core`, `data/` or the save.

## Tests (`app/test/`)
- A new `recipe_pictures_test.dart`: criteria 1-13.
- `now_monsters_test.dart`, the test of spec 0014 criterion 11 that expects recipe rows without a socket: it now
  expects the socket of rule 1. Its other checks (tool line, meal row) stay.
- Tests that find a recipe's level badge as the row's `leading` follow it to the title line.

## Order of work (one PR)
1. The tests: criteria 1-13.
2. The code and the notes line.
3. **Proof:** the Crafting and Cooking screens and the sheet of a craft, rendered at 408 dp wide (`CLAUDE.md`).
   `.\scripts\check.ps1 -Release` green. Review per `REVIEW.md`; the owner merges.

Branch `feat/recipe-pictures`.
