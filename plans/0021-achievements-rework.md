# Plan 0021: Build "Achievements rework"

Status: accepted
Spec: `specs/0017-achievements-rework.md` · Intent: `intent/0017-achievements-rework.md` and amendment 1 ·
Product owner: Zkalf · Date: 2026-10-24

Names of files, widgets and tests refer to `main` at `4b7f11d`.

## Overview
This plan builds spec 0017 in three milestones. Each milestone is one pull request.

| Milestone | What | Criteria | Size |
|---|---|---|---|
| M1: Rules, data and save | the criteria, the rewards, the quality counter, the check on load, lost achievements, save version 12, the 30 achievements with the start counts | 1, 2, 4–25 | about 900 lines |
| M2: Sim and feat counts | a sim walker that grinds a feat, a tool that measures the extra days, the final counts in the data | 3, 31, 32 | about 400 lines |
| M3: Screens | the Achievements screen, the reward line, the word "Feat", the banner, the report of lost achievements | 26–30 | about 500 lines |

Criterion 33 (the build) is the proof of each milestone.

## Choices this plan makes
The owner may want to change one of these choices before the owner accepts the plan.
1. **Rules first, screens last.** M1 and M2 change only `packages/game_core`, the data and the save. M3 changes the
   screens. Between M1 and M3, the Achievements screen shows the new achievements without the reward line.
2. **No friend release between M1 and M3.** Old saves lose achievements in M1, and only M3 tells the player why.
3. **The sim table lives in `docs/sim/0017-achievements.md`.** Spec 0017 §8 says "the plan records the table".
   This plan is accepted before the sim runs, and an accepted plan does not change. So the M2 pull request writes
   the table into that file, and the plan links it.
4. **The pacing test.** If the pacing test of `check.ps1` trips because of the rewards, Claude stops and asks the
   owner (`CLAUDE.md`).

## M1: Rules, data and save
- `packages/game_core/lib/src/data.dart`:
  - `AchievementDef` gets a kind (milestone or feat), a criterion (§3.1) and a reward (§3.4).
  - Five kinds of criterion: a counter, the level, a profession level, any profession level, a quality found.
  - Four kinds of reward: bank cap, an item at a fixed quality, a stat bonus, the queue slot.
  - A data check refuses a bonus or the queue slot on a milestone (criterion 14).
- `packages/game_core/lib/src/game.dart`:
  - The bank cap, the stats and `queueSlots(state)` add the rewards of the earned achievements.
  - A new counter keeps the best quality found (§3.2). Each source of §3.2 updates it.
  - `checkAchievements(state)` earns and loses achievements (§4, §5). It runs after each change, as today, and on load.
  - A lost achievement takes its reward (§5). An event names each lost achievement and what the player lost.
- `packages/game_core/lib/src/state.dart`: save version 12. An old save starts the quality counter from its bag and
  its doll (criterion 24).
- `packages/game_core/data/achievements.json`: the 30 achievements of §2, with the start counts.
- Tests first, committed alone:
  - one test for each criterion of 4–25;
  - a data test for criterion 15 (no reward item from the monster or spot of its criterion);
  - each fixture of `app/test/fixtures/saves/` loads (criterion 25).
- **Proof:** `.\scripts\check.ps1 -Release` green. The verifier checks criteria 1, 2 and 4–25.

## M2: Sim and feat counts
- `packages/game_core/lib/simulation.dart`: a walker option that grinds one feat after it reaches the stage of the
  feat, and then plays on as the pacing walker.
- `packages/game_core/tool/feat_cost.dart`: for each feat, the extra days to level 30 against the walker without
  feats, at 5,000 steps a day.
- The counts in `achievements.json` change until each feat costs the days of spec §3.3.
- `docs/sim/0017-achievements.md`: the table of the sim, with each feat, its count and its extra days, and the days
  to levels 10, 20 and 30 without feats.
- Tests: criteria 31 and 32 run in the pacing test of `check.ps1`.
- **Proof:** `.\scripts\check.ps1 -Release` green. The verifier checks criteria 3, 31 and 32.

## M3: Screens
- `app/lib/ui/achievements_screen.dart`: the headings Early, Mid and Late; the line "Reward: …"; the word "Feat".
- The banner of an earned achievement names its reward.
- The away report names each lost achievement and what the player lost (spec §5).
- Failing widget tests first, committed alone, for criteria 26–30 and the report line.
- **Proof:** `.\scripts\check.ps1 -Release` green. The verifier checks criteria 26–30. After the merge, an install on
  the Fairphone, with a screenshot of the Achievements screen.

## Branches
- `plan21-m1`, `plan21-m2`, `plan21-m3`: one pull request each, with a review per `REVIEW.md`. The owner merges.
