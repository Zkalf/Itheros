# Plan 0013: Build "Lake and hunt"

Status: accepted
Spec: `specs/0011-lake-and-hunt.md` (accepted, 02278ff) · Intent: `intent/0011-lake-and-hunt.md` (accepted, 8d4837c)
Product owner: Zkalf · Date: 2026-10-22

## What changes in the code
- **Data:** `professions.json` gains Fishing, Hunting and Cooking (tool, tiers, Wen / Sigrun / Marta, lines, starter
  tools, Sigrun's three tips). `world.json`: Mirror Lake (routes to Camp 300, Copper Hills 300) and hidden
  Smugglers' Cove (`hidden: true`, route to Mirror Lake 700), placed so no road crosses another; fishing spots with a
  `catches` table (four rows, species, weight range), `scale`, trophy as `rareFind` with its base (cove 1.5%), and the
  cove's `chest`; hunting spots with animals (meat, trophy) and `hide`; camp gets `fire: true`. `items.json`: 16 fish,
  6 meats, 3 hides, 3 scales, 3 trophies, starter and crafted rods / bows / pots, the `meal` kind (22 meals with
  `buff` and tier), the 15 pieces of spec §7 (`reference: false`), the Drowned Captain's ring, and their recipes
  (meal recipes with `profession: cooking`). `economy.json`: `mealSteps`, `perfectDish` (base, nudges), meal buff
  sizes by tier, `bottleChance`, `chestChance`. Validation: every catch, meat, hide, scale and trophy is an item,
  every meal names a known buff, hidden areas are only reached by their routes.
- **`state.dart`:** save version 9 per spec §10 (`records`, `meal`, `autoEat`, `revealed`, `bottles`; three new
  professions unlearned on migrate).
- **`game.dart`:** `learn` and tips for the three new teachers (spec 0010 code, more data); a gather with a `catches`
  table rolls the row, the trophy, the weight, the bottle and the chest on the profession stream; hunting rolls the
  animal and rare trophy; records and their news; cooking as a craft that needs the fire and rolls perfect; meals:
  `eat`, `setAutoEat`, the buff in the stat totals and in step costs, the countdown inside `applySteps` with auto-eat
  at the exact step; hidden areas left out of map, lists and route finding until revealed. News for trophies,
  records, bottles, the chest, auto-eat and "out of meals".
- **Simulator and tools:** `SensiblePlayer` learns all six, counts the §7 pieces as upgrades, fishes and hunts for
  their inputs, crafts mantles from trophies, cooks a batch in camp and auto-eats (spec §9.2), with a switch to turn
  meals off for target 5. `GathererPlayer` fishes, hunts, crafts the pieces and eats its fewer-steps meal.
  `referencePlayer` skips `reference: false` items and never eats. `tool/seeds.dart` adds the meals-off column and
  Fishing / Hunting / Cooking on days 30, 60, 90.
- **App:** Professions shows six cards; Fishing's records ("???" for uncaught); Cooking's recipe list, active meal
  and auto-eat; Now: the active-meal line, new spots, teachers and the Camp fire row; item card: meal buff and length,
  Eat (with the replace confirm), Auto-eat (off / until out / only N); Character stats with the meal mark; World draws
  Mirror Lake and the cove once revealed; banner for the sea chart; labels for the new news lines.
- **Old tests:** none expected to break (no rule of today changes). Any that do are rewritten next to their
  replacement, pointing at the spec 0011 line.

## Order of work
### M1: Rules, data, save version 9, tuning
Failing tests first for criteria 1–14, then the data, the rules, `migrate` and the walkers. Then the first 8-seed
run with full sims (the first in this plan). Tune per spec §9.4: the §7 stats first, then the batch size and when the
walker cooks. If target 5 or the level 30 window can only be met by changing meal sizes or monsters, stop and ask
the owner. **Proof:** `.\scripts\check.ps1` green; every fixture save loads as version 9; the criterion 13 test
(same fights with and without the new rolls); the 8-seed table in the PR (meals on and off, fighter, gatherer, the
new professions on days 30/60/90). Branch `plan13-m1`, PR, review per `REVIEW.md`; the owner merges.

### M2: Screens (install)
Failing widget tests first for criterion 15 and the meal and auto-eat controls (with `MemorySaveStore`), then the
screens above. **Proof:** check green, `.\scripts\check.ps1 -Release`, `.\scripts\device-smoke.ps1 -Install` (owner
asked first), the owner's save loads on the phone with the three new professions to learn and Mirror Lake on the map;
the verifier checks the whole change against spec 0011. Branch `plan13-m2`, PR, review; the owner merges.

## Risks
| Risk | Mitigation |
|---|---|
| M1 is large (three professions, meals, bottle, gear) | Tests by criterion, committed in slices on the branch; if the PR passes ~1,500 lines of rules, split off the §7 gear as its own PR before tuning |
| The 15 pieces and meals push lucky seeds under day 70 | §7 stats are the first knob; the reference player ignores them so monster targets stay put |
| Camp trips for meals make the walker slower with meals than without (target 5 fails the other way) | Batch size and "cook only when passing camp" are walker rules, tuned in M1; meal sizes only with the owner |
| The meal countdown inside `applySteps` splits a sync's steps in odd places | Tests: auto-eat at the exact step, a meal ending mid-fight, a sync that spans two meals, banked steps not counted |
| Hidden areas leak through an old code path (route finding, Next goal, map labels) | One test per path with the cove hidden; the cove's id must not appear in any list or route before the chart |
| More rolls on the profession stream shift spec 0010's finds and rerolls | Expected and fine: only the shared generator must keep its draws (criterion 13) |
