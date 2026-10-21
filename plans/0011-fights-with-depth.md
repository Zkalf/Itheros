# Plan 0011: Build "Fights with depth"

Status: accepted
Spec: `specs/0009-fights-with-depth.md` (accepted, d7b6e89) · Intent: `intent/0009-fights-with-depth.md` (accepted, 44ad50c)
Product owner: Zkalf · Date: 2026-10-21

## What changes in the code
- **`data.dart` / JSON:** `Stats` gains `crit`, `hit`, `dodge`, `block` (percent points). `enemies.json`: `armour`
  (light/medium/heavy) on every monster, `dodge` on five, a `lore` entry (note id, subject, text) on the sixteen
  that drop one. `items.json`: `damageType` on every weapon, `armourType` on armour, base `block` on shields, base
  `dodge` on light armour; 14 new weapons and recipes (spec §4.1); the maul gets `twoHanded`. `economy.json`: the
  combat numbers of spec §2.1 (hit base, per level, bounds, base Crit, crit size, block share, caps, Slayer bonus,
  lore chance), the type table (§3) and the bonus stat pools and ranges by tier (§5.1). Validation: every monster
  has an armour, every weapon a type, `block` only on off-hand items, each lore subject exists.
- **Item keys carry bonus stats:** `bone_sword@rare+crit3+hp12` (stats in a fixed order). Stacking stays "same key,
  same stack", so the bag, equip and save code keep their map. `bonusOf(key)` adds the bonus stats to the quality
  stats; `scoreOf` weighs every stat.
- **`game.dart`:** combat round per spec §2 (hit roll, dodge roll, crit, block, type factor, Slayer); `RoundLog`
  records the outcome of each swing (hit, crit, miss, dodge, block) so the log can name it. Rolling bonus stats
  after the quality roll, for crafts, drops and boss uniques. Bestiary queries (`knowledge(s, monster)`: fought,
  weakness known, stats known, slayer) and lore drops (1%, once, named in the report). Next goal compares weapons
  within type and hands.
- **`state.dart`:** save version 7: `fought` set and `lore` set. `migrate` rolls bonus stats for owned gear above
  Common with the save's generator (spec §5.4) and marks every monster with a kill as fought.
- **Simulator and tools:** `estimateFight` with hit, dodge, crit, block and types; `armFor` picks the weapon (and
  shield) per fight; weapons compared within type and hands for crafting; `referencePlayer` holds the stretch's
  weapons and arms the strong type (spec §9.1). `tool/seeds.dart` (8 seeds, day of level 5/10/20/30) and a
  `tool/fit.dart` that fits monster HP to a target XP per step, both from the scratchpad prototype. `tune.dart`
  adds the §4.2 two-hander / shield report.
- **App:** `labels.dart` fight log lines (§8.1); `item_card.dart` / `slot_sheet.dart` type, hands, armour and bonus
  stat lines; new `bestiary_card.dart` (on the monster sheet in Now and World, above today's fight choices);
  `journal_screen.dart` with Log / Bestiary / Lore tabs; the Character stats block with the four new stats.
- **Old tests:** tests that assume every hit lands (`combat_test.dart`, `traits_test.dart`) are rewritten to the
  new rules with fixed seeds in the same commit as their failing replacements, each pointing to the spec 0009 line
  that overrides it. The pacing test runs seeds 1–8 with spec §13 criterion 16's targets.

## Order of work
### M1: Combat rules, weapons and tuning, tests first
Failing tests first for criteria 1–6 and 15–16, then the combat rules, the data (types, armour, new weapons,
shields), the simulator and tools. Bonus stats are off in this milestone. Monster HP fitted with `fit.dart`, then
the boss checks and the §4.2 two-hander targets. **Proof:** `.\scripts\check.ps1` green; the tuning report and
the 8-seed table in the PR description.

### M2: Bonus stats, save version 7, final tuning
Failing tests first for criteria 7–10, then rolling, keys, `migrate`, fixture loads. Bonus stat sizes tuned until
all 8 seeds meet criterion 16. If no tuning holds every seed in range, stop and ask the owner (spec concern 2).
**Proof:** check green, every fixture save loads with its gear rolled once, 8-seed table in the PR.

### M3: Bestiary, lore, screens (install)
Failing tests first for criteria 11–14, then knowledge, Slayer and lore drops, the lore texts in data, the fight
log lines, item card, bestiary card, Journal tabs and stats block. Widget tests with `MemorySaveStore`. **Proof:**
check green, `.\scripts\check.ps1 -Release`, `.\scripts\device-smoke.ps1 -Install` (owner asked first), the
owner's save loads on the phone with its gear rolled and its old kills in the bestiary; the verifier checks the
whole change against spec 0009.

Each milestone is its own branch and PR, reviewed per `REVIEW.md`; the owner merges.

## Risks
| Risk | Mitigation |
|---|---|
| Real bonus stat rolls spread the pacing wider than the prototype's averages | M2 tunes on 8 seeds with real rolls; the owner decides if it can't fit |
| Two extra rolls per swing change every seeded test's numbers | Old combat tests are rewritten in one commit with their reasons; pacing is judged by targets, not exact days |
| The simulated player arms the perfect weapon every fight, kinder than a real player | Pacing keeps margin below the day-100 ceiling; the owner's playtest after M3 is the check |
| Long item keys in old code paths (labels, counters) | Counters keep the plain item id (as for qualities); a test equips, swaps and saves an item with four bonus stats |
| Lore texts are content work | Short texts in data, written in M3; the owner may rewrite them without a code change |
