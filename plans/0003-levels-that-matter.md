# Plan 0003: Build "Levels that matter"

Status: accepted
Spec: `specs/0002-levels-that-matter.md` (accepted, 7218d5f) · Intent: `intent/0002-levels-that-matter.md` (accepted, 041ecbd)
Product owner: Zkalf · Date: 2026-10-19

## Context
Builds spec 0002 on top of the Goblin slice. Rules first (pure Dart, tests first), then content, then tuning with
the simulator, then screens, then the phone. Each milestone ends with its proof and a commit. The queue, stop
conditions and losing rules stay out (spec 0003, next).

## What changes in the code
- **`packages/game_core/lib/src/data.dart`:** drop `maxLevel`; levels past the XP list grow by `xpGrowthAfterList`.
  Enemies get `level`, `traits`, `regen`, `firstKillDrops`, `lossHint`, `flavour`. Nodes and recipes get a level
  (their unlock level). New data: colour bands (difference → colour, XP multiplier, skull threshold), gear slots
  with unlock levels, ranks (level, name, ceremony line), feature unlocks (queue sizes, map opening), area flavour.
  `_validate()` grows: every drop, input and output item exists, every item slot exists, every location in a
  route exists, colour bands cover every difference.
- **`game.dart`:** `stats()` counts only gear in open slots; `equip()` refuses closed slots; colour and XP
  multiplier queries; XP fade applied in `_gainXp` callers (fights, gathering, crafting, minimum 1 XP for a win);
  combat traits (quick, slow, ghostly, regenerates); first-kill drops (a kill counter at 0 before the kill);
  `talentPoints(level)`; `levelNews(level, before, after)` for the cards (spec §9.1); `nextGoal(state)` (§9.3).
- **`state.dart`:** save schema 1 → 2. Migration keeps the level and moves XP to the same fraction through that
  level in the new table (the old table is kept as a constant for this). No new fields: first kills come from
  kill counters, talent points from the level.
- **`app/lib/persistence/save_data.dart`:** version 2, adds the "Next goal hidden" switch and the set of flavour
  lines already shown (UI state, not game rules).
- **`lib/simulation.dart`:** a smarter scripted player (below).

## Order of work

### M1: Rules, tests first
1. Failing tests first, committed: the colour/XP table from −10 to +12 and identical loot at every colour
   (criterion 1); levels past the list (2); one deterministic test per trait (5); first-kill drop exactly once (7);
   closed gear slots and hidden content (8); v1 → v2 save migration with a level 10 save (11).
2. Implement in that order. Existing content keeps working: goblin level 1, brute level 4.

**Proof:** `.\scripts\check.ps1` green; criteria 1, 2, 5, 7, 8, 11 pass.

### M2: Content
All of spec §6–§8 in `data/*.json`: 9 locations and the routes, 19 monsters with drops, traits, loss hints and
flavour lines, 2 new gathering spots, about 30 items and recipes, 6 gear slots, ranks, boss achievements
(King's Bane, Chieftain's Bane, Dragonslayer). Starting stats come from the spec's targets:
player at level L has `30 + 10(L−1)` HP, `5 + (L−1)` Attack, `2 + (L−1)` Defense, and gear adds about half of
that again by tier.

**Proof:** check green; data validation passes; a test walks the ladder and finds at least one named unlock at
every level from 2 to 30.

### M3: Simulator and tuning (the main work)
1. The scripted player: equips the best gear, crafts each tier's recipes when it has the materials (farming grey
   monsters for missing materials), fights the yellow monster with the most XP per step that it beats, travels
   between areas and uses the outposts, tries each boss once geared.
2. Pacing test at 5,000 steps a day, 3 seeds, 100 days: level 5 on day 1, 10 on day 12–16, 30 on day 80–100
   (criterion 3). This replaces spec 0001's "level 10 on day 7–11" test, which spec 0002 supersedes.
3. Roster test: XP per step rises with each monster, by at most a third (criterion 4).
4. Boss harness: 200 fights per case for the §5.3 win rates and XP per step (criterion 6).
5. Tune `data/*.json` until all pass. Numbers only, no rule changes.

**Proof:** check green with criteria 3, 4, 6. The simulator prints day-by-day levels for the owner.

### M4: Screens
- Level-up cards on open before the report, and live when levelling in the foreground; swipe, "Skip all",
  collapse past 3 (§9.1). Rank ceremony cards at 10, 20 and 30.
- Monster level in colour or a skull in the fight list; confirmation before red or skull fights (§9.2).
- "Next goal" line with Hide from level 10 and a switch to turn it back on (§9.3).
- Loss hints in the report (§9.4). Flavour lines the first time an area or monster shows (§9.5).
- Character tab: open gear slots, rank title, talent points waiting.
- Travel lists all routes from the current location (the map is bigger now).

**Proof:** widget tests for criteria 9 and 10 (with `MemorySaveStore`); check green.

### M5: On the phone
Install the release build over the existing save. Check the level survives the migration (criterion 11 on the
real save), the level-up card and colours look right, and nothing crashes. `.\scripts\device-smoke.ps1 -Install`,
then `.\scripts\check.ps1 -Release` (criterion 12). The verifier checks the change against spec 0002 before the
final commit. The owner playtests.

## Risks
| Risk | Mitigation |
|---|---|
| Tuning 19 monsters and 30 items takes many rounds | Targets are written as tests; the simulator prints per-monster XP per step and win rates to tune against |
| The 100-day simulation makes `check.ps1` slow (about 450,000 steps × 3 seeds) | Measure in M3; if it's over a minute, run 1 seed in `check.ps1` and 3 seeds in a tagged slow test |
| The scripted player plays better or worse than a real one | Pacing ranges are wide; the owner's playtest in M5 is the real check |
| The owner's save breaks on migration | The migration test uses a real v1 save shape; the old save loads read-only first and the app keeps the v1 file until the v2 save is written |
| A skull-filled world at level 10, before spec 0003's softer losing rules | Expected; spec 0003 follows directly |

## Owner's part
Accept this plan. Playtest after M5 and say what feels off. Numbers are tuned in data afterwards.
