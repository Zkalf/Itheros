# Spec 0011 amendment 2: meals speed up the pace again

Status: accepted
Amends: [spec 0011](0011-lake-and-hunt.md) decision 2 and §5.3 (the buffs and how long a meal lasts), §9.3 target 5 as
[spec 0013 amendment 3](0013-daily-chest.amendment-3.md) left it
Issue: #165
Product owner: Zkalf (chose on 2026-11-06: meals help a little with the pace and a little in hard fights; after the
sims below: meals last longer and Attack and HP meals make fights cost fewer steps; accepted on 2026-11-06)
Date: 2026-11-06

## Why
- With supply chests, chest gear makes fights short. An Attack or HP buff saves few rounds.
- The steps of fishing, hunting and cooking cost about as much as the buff saves, or more.
- Claude's hand-run sims, the mixed walker at 5,000 steps a day, seeds 1-16. "Gain" is the day of level 30 without
  meals minus the day with meals:

  | Variant | Gain (mean) | Gain (median) | Gain (lowest to highest) |
  |---|---|---|---|
  | Today: meals last 3,000 steps | -2.6 days | -3.5 days | -14 to +10 |
  | A: meals last 6,000 steps | -0.4 days | -1.5 days | -15 to +16 |
  | B: Attack and HP meals give back 6 / 10 / 14% of each fight round's steps | -0.4 days | +0.5 days | -11 to +7 |
  | A and B | -0.2 days | +0.5 days | -14 to +11 |
  | **A and B at 12 / 20 / 28%** | **+3.2 days** | **+4.5 days** | -8 to +10 |

- Before supply chests, meals gained about 5 days (spec 0013 amendment 3). The last variant brings back most of that.

## Change
**How long a meal lasts**
1. A meal lasts 6,000 steps (`mealSteps` in `economy.json`, was 3,000).
2. A perfect dish still lasts twice as long: 12,000 steps.

**Faster fights**
3. An Attack meal, an HP meal and a feast (HP and Attack) also make fights cost fewer steps.
4. While such a meal runs, each fight gives back a share of its round steps to its action, as the talent Swift strikes
   does (spec 0015 §2.3).
5. The share by meal tier is 12% / 20% / 28%. The numbers live in `economy.json` (`meals.fightSteps`).
6. The meal's share and the talent's share add up. The steps given back are rounded down, as today.
7. Defense, Crit and fewer-steps meals do not change.

**The words on screen**
8. The buff line of an Attack or HP meal names both effects, for example "+6% Attack, −12% fight steps for 6,000
   steps". A feast reads "+6% HP, +6% Attack, −12% fight steps".
9. The words show where a meal's buff shows today: its item card, the meal line on Now and on the Cooking screen.

**The pace**
10. Spec 0011 §9.3 target 5 becomes: **meals help a little.**
    - In a hand-run sim on seeds 1-16, the mean gain of meals is 2 to 6 days.
    - In the pacing test on seeds 1-8, the median day of level 30 with meals is 0 to 10 days sooner than without meals.
11. The other targets of §9.3 do not change. The mixed walker's median level 30 day stays 80-100.

**What stays**
12. The stat buffs stay +6% / +10% / +14%, and Crit stays +2 / +3 / +4 points.
13. The fewer-steps buff for gathering, crafting, cooking and rerolls stays 6% / 10% / 14%.
14. The sim walker does not change.
15. The save does not change. A meal that runs when the player updates keeps the steps it has left.

## Acceptance criteria
**Rules**
1. A plain meal lasts 6,000 steps, and a perfect dish 12,000.
2. A fight under an Attack meal gives back its tier's share of the fight's round steps: 12% at tier 1.
3. A fight under an HP meal gives back the same share.
4. A fight under a feast gives back the same share.
5. A fight under a Defense, Crit or fewer-steps meal gives back no steps from the meal.
6. With the talent Swift strikes, the talent's share and the meal's share add up.
7. The shares 12 / 20 / 28 and the 6,000 steps come from `economy.json`.

**Screens**
8. The card of an Attack meal reads "+6% Attack, −12% fight steps for 6,000 steps" at tier 1.
9. The card of a feast names HP, Attack and the fight steps.
10. The card of a Defense meal names no fight steps.

**Pace**
11. The pacing test: on seeds 1-8, the median level 30 day with meals is 0 to 10 days sooner than without.
12. The pacing test: the mixed walker's median level 30 day stays 80-100, and its other targets pass.
13. The plan reports the hand-run sim on seeds 1-16 with the final numbers: mean gain 2 to 6 days.

**Check and release**
14. The save does not change. Each fixture in `app/test/fixtures/saves/` loads.
15. `releases/next/` has a line for players.
16. `.\scripts\check.ps1 -Release` is green with the pacing sims, and the release build declares no INTERNET
    permission.
