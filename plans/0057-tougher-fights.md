# Plan 0057: Build "tougher, longer fights" (spec 0002 amendment 3)

Status: accepted
Spec: `specs/0002-levels-that-matter.amendment-3.md` · Issue: #234 · Product owner: Zkalf · Date: 2026-11-09

Names of files, widgets and tests refer to `main` at `2d244e7`.

## Choices this plan makes
- **One PR.** It changes only data, the sim walker and tests. No screen and no rule of the game changes.
- **A one-time script for the numbers.** `tool/retune_fights.dart` reads today's `enemies.json` and `items.json`,
  applies changes 1-7, and writes them back. It runs once on the branch and is deleted before the PR: the new data
  is the record. Its output is the before/after table in the PR (criteria 1-7).
- **The walker measures fights.** `SimulationResult` gets the rounds and the HP taken of each finished fight, read
  from the fight log of the running action (spec 0019), so the pacing test can check targets 3-6.

## What changes in the code

### Data
- `data/enemies.json`: HP, Attack, XP and drops of every monster (changes 1-5), from the script.
- `data/economy.json`: `combat.hitBase` 75, `combat.hitMax` 90 (change 6).
- `data/items.json`: HP of the hide, scale and trophy pieces and of rings, necks and trinkets (change 7).

### game_core
- `lib/simulation.dart`:
  - `_bestFight`: with no safe fight, the best one it still wins (change 8);
  - `_canFight`: the fighter's bar is a win with 10% HP left (change 9);
  - `SimulationResult.fights`: per finished fight, the monster, rounds and share of HP taken; `simulate` fills it.
- `test/pacing_test.dart`:
  - target 2: the fighter's median day of level 30 in 80-120;
  - targets 3-6 on the mixed walker, seeds 1-8 (criterion 11).
- `test/roster_test.dart`: drops the checks that moved to the walker; keeps the boss checks without gear and 3 levels
  below, the strong weapon type and the two-hander check (criterion 12).
- `test/fights_test.dart`: the hit tests follow 75% and the 90% top (criteria 8-9).
- Other tests that pin monster numbers, XP or drop chances follow the new data.

### app
- No code. Tests that pin a monster's numbers or the hit chance follow the data.
- `releases/next/feat-tougher-fights.md`: one line for players (criterion 14).

## Order of work
1. The script, run once; the before/after table saved for the PR.
2. The walker changes and `SimulationResult.fights`.
3. The tests: criteria 8-9, 11-12.
4. The hand sims at 5,000 steps a day, seeds 1-16, mixed and fighter, with `main` and with the branch: targets 1-7
   (criterion 10). If a target fails, Claude reports the numbers to the owner before any tuning.
5. **Proof:**
   - `.\scripts\check.ps1 -Release -Pacing` green.
   - The before/after table and the sim numbers in the PR description.
   - The verifier runs alongside the local check, before the PR.
   - Review per `REVIEW.md`; the owner merges.

Branch `feat/tougher-fights`.

## Risks
- **The pace.** The study ran 8 seeds without the gentle start. If 16 seeds move level 30 out of 80-100, or the fighter
  out of 80-120, Claude reports before tuning.
- **Friends' saves.** Nothing in a save changes, but a player who fought one monster comfortably may now lose to it.
  The release note says fights are tougher.
- **Other tests.** Many tests use real monster numbers. They follow the data in this PR, with no change to what they
  check.
