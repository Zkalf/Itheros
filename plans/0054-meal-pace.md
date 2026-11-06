# Plan 0054: Build meals that speed up the pace (spec 0011 amendment 2)

Status: accepted
Spec: `specs/0011-lake-and-hunt.amendment-2.md` · Issue: #165 · Product owner: Zkalf · Date: 2026-11-06

## What changes in the code
**game_core**
- `data/economy.json`: `meals.steps` 3000 -> 6000; new `meals.fightSteps` [12, 20, 28] (rules 1, 5).
- `lib/src/data.dart`: `GameData.mealFightSteps`, read from `meals.fightSteps`.
- `lib/src/game/talents.dart` (`fightStepsBack`): the talent's share plus the running meal's share, for a meal with
  the Attack or HP buff (rules 3-6).
- `lib/src/game/odds.dart`: `mealFightShare(state)` next to `mealStepShare`.
- `test/pacing_test.dart`: target 5 checks 0 to 10 days sooner (criterion 11).
- New `test/meal_fight_steps_test.dart`: criteria 1-7.

**app**
- `lib/ui/labels.dart` (`mealBuff`): Attack and HP meals add "−N% fight steps" (rules 8-9).
- Tests in `test/meal_fight_steps_screens_test.dart`: criteria 8-10.
- `releases/next/feat-meal-pace.md`: one line for players.

No save change.

## Order of work (one PR)
1. The tests: criteria 1-12.
2. The code and the data.
3. **Proof:**
   - The hand-run sim on seeds 1-16 with the final code (`tool/seeds.dart` or a throwaway like it), reported in the PR
     (criterion 13).
   - `.\scripts\check.ps1 -Release -Pacing` green (`packages/` changes, so the pacing sims run anyway).
   - The item card of a meal rendered at 408 dp (`CLAUDE.md`).
   - The verifier runs alongside the local check, before the PR.
   - Review per `REVIEW.md`; the owner merges.

Branch `feat/meal-pace`.
