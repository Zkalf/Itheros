# Spec 0013 amendment 3: meals and the pace with chests

Status: accepted
Amends: [spec 0011](0011-lake-and-hunt.md) §9.3 target 5 (meals and the day of level 30)
Issue: #57
Product owner: Zkalf (agreed on 2026-11-01, after the sims of PR #164: change the target, not the meals)
Date: 2026-11-01

## Why
- Spec 0011 §9.3 target 5: with meals, the median level 30 day of seeds 1-8 is no later than without, and at most 5
  days sooner.
- With supply chests, the 8-seed pacing test found meals 2.5 days later. 32 seeds show that meals neither help nor
  hurt the pace:

  | Meal buffs | Gain of meals (median of 32 seeds) | Gain (mean) | Seeds where meals were sooner |
  |---|---|---|---|
  | 6 / 10 / 14% (today) | -0.5 days | -0.5 days | 14 of 32 |
  | 10 / 15 / 20% (tried) | +0.5 days | +0.1 days | 15 of 32 |
  | 12 / 18 / 24% (tried, before point 4) | +1.5 days | +0.1 days | not counted |

- Chest gear makes fights short, so a buff saves few rounds. The steps of fishing, hunting and cooking cost about as
  much as the buff saves.
- Stronger buffs do not change this, so the meals keep their numbers. Spec 0011 says meals help, but are not a must.
- One seed alone moves the day of level 30 by up to 10 days, so 8 seeds against 8 cannot measure a difference of 2 or
  3 days.

## Change
1. Spec 0011 §9.3 target 5 becomes: with meals, the median level 30 day of seeds 1-8 is **at most 5 days later and at
   most 5 days sooner** than without meals.
2. The meal buffs of spec 0011 decision 2 do not change: +6% / +10% / +14%.
3. Meals keep their use: buffs for hard fights, and fewer steps for profession actions.
4. **The sim walker:** it counts only the meals it would eat when it decides to cook. A supply chest's meals with
   another buff (Crit, Defense, fewer steps) piled up in its bag, and it never cooked again: 0 meals cooked in 7 of 8
   seeds. It changes no rule of the game.
5. Whether meals should speed up the pace again with chests is a design question for a later change. An issue tracks
   it.

## Acceptance criteria
1. The pacing test checks the meals target from -5 to 5 days.
2. The meal buffs in `economy.json` stay 6 / 10 / 14.
3. `.\scripts\check.ps1 -Pacing` is green.
