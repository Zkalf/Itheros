# Plan 0061: Build "recipe lists start with the highest level the player can make"

Status: accepted
Spec: `specs/0010-professions.amendment-12.md` · Product owner: Zkalf · Date: 2026-11-10

One small change from the playtest of 2026-11-10 in one PR (#253). Names of files, widgets and tests refer to `main`
at `06dce9c`.

## What changes in the code
- `app/lib/ui/profession_screen.dart`, `_practise`: the sort of the recipes. Open recipes come first, by level from
  the highest. Locked recipes follow, by level from the lowest. Recipes of the same level keep their place in the
  list of today (the order of the data), with their index as the last key of the sort.
- `app/test/recipe_order_test.dart` (new): criteria 1 to 9. It reads the rows of the screen top to bottom and
  compares them with the levels of the data.
- Tests that count on the old order follow the new one.
- `releases/next/feat-recipes-highest-first.md`: the line for players.
- No change to `game_core`, the data, the save or the sim.

## Order of work
### M1: the order (one PR)
- The tests first, then the code.
- **Proof:** `.\scripts\check.ps1 -Release` green. A render of Crafting's list at 408 dp wide with Crafting 13.
- Branch `feat/recipes-highest-first`. PR with the amendment and this plan, `Closes #253`, review per `REVIEW.md`.
  The owner merges.
