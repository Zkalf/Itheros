# Plan 0033: Build "Low XP on grey monsters" (spec 0002 amendment 2)

Status: accepted
Spec: `specs/0002-levels-that-matter.amendment-2.md` · Product owner: Zkalf · Date: 2026-11-01

Names of files, widgets and tests refer to `main` at `5718f29`.

## What changes in the code
- `app/lib/ui/actions.dart`, `enemyTile`: a grey band starts the stats with the words "Low XP" in `#9E9E9E`, then
  " · ", as the orange band does with "Risky".
- `app/lib/ui/theme.dart`: no new colour; `#9E9E9E` is the grey of `LevelBadge` (a band colour of spec 0014 §2.1).
- No change to game_core, the data, the save or the sim.
- `releases/next.md`: a line for players.

## Order of work
### M1: the label (one PR)
- First, the failing tests, committed alone, in `app/test/quiet_teal_test.dart` next to the "Risky" test: a grey
  Goblin row for a level 11 player says "Low XP" in `#9E9E9E` and nothing else in it (criteria 13-14); the orange
  Goblin brute and a yellow row do not (15); a tap on the grey row opens the stop condition sheet, not a question
  (16).
- Then the code.
- **Proof:** `.\scripts\check.ps1 -Release` green (criteria 17-18). A screenshot on the Fairphone at the owner's
  request.
- Branch `feat/low-xp-label`. PR with the amendment and this plan, review per `REVIEW.md`. The owner merges.
