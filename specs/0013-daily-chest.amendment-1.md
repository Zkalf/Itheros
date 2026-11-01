# Spec 0013 amendment 1: rarer chest gear, Crafting materials, the pace with chests

Status: accepted
Amends: [spec 0013](0013-daily-chest.md) §2.4 (the gear chance, the common roll) and criteria 15, 18 and 19;
[spec 0017](0017-achievements-rework.md) criterion 31 (the day of level 10);
[spec 0010 amendment 1](0010-professions.amendment-1.md) point 4 (the day of Crafting 10)
Issue: #57
Product owner: Zkalf (chose on 2026-11-01, after the sim of plan 0037 M1: a faster pace with chests, gear in 1 chest
in 10, Crafting materials; intent 0013 amendment 3)
Date: 2026-11-01

## Why
- The sim of plan 0037 M1 showed two effects of the chest:
  - The character levels a little faster. The owner accepts this pace.
  - With gear in 1 chest in 5, a pure fighter reached level 30 as soon as the walker with professions (day 86 and
    day 85). Spec 0010 §9.3 target 3 wants the fighter at least 15% later.
- The owner chose rarer gear and Crafting materials (intent 0013 amendment 3).

## Change

### The chest (spec 0013 §2.4)
1. **Gear:** `supplyChest.gearChance` becomes **0.1**: about 1 chest in 10.
2. **The Crafting choice:** with Crafting learned, the common roll has one more choice. The list of point 19 becomes:
   - each gathering profession that the player has learned
   - Crafting, if the player has learned it
   - a meal
3. The Crafting choice gives the inputs of one craft. The game picks the recipe evenly among the gear recipes with a
   Crafting level from the player's Crafting level minus 4 (`supplyChest.gearWindow`) up to the Crafting level.
4. The recipes of the gear in `supplyChest.exclude` are never picked.
5. For example, Crafting 3 can give the inputs of a copper sword (5 Copper ore).
6. Point 24 becomes: Cooking is not a choice. A player without a gathering profession and without Crafting always
   gets a meal.

### The pace with chests
The sim of seeds 1-8 at 5,000 steps a day, with chests, gear in 1 chest in 10 and the Crafting choice:

| Target | Before | With chests | New target |
|---|---|---|---|
| Spec 0017 criterion 31, level 10 (seed 1, without feats) | within 5% of day 16 | day 15 | within 5% of day **15** |
| Spec 0017 criterion 31, level 20 | within 5% of day 50 | day 48 | no change |
| Spec 0017 criterion 31, level 30 | within 5% of day 84 | day 88 | no change |
| Spec 0010 amendment 1 point 4, Crafting 10 (median) | day 8-22 | day 7 | day **6-22** |
| Spec 0010 §9.3 target 3, the fighter to level 30 | at least 15% later | day 105 against day 88: 19% later | no change |
| Spec 0011 §9.3 target 5, meals | no later, at most 5 days sooner | 0.5 days sooner | no change |

7. Spec 0017 criterion 31 becomes: the sim walker without feats reaches levels 10, 20 and 30 within 5% of days
   **15**, 50 and 84.
8. Spec 0010 amendment 1 point 4 becomes: Mining and Crafting reach 10 by day **6-22** for Crafting and 5-22 for
   Mining, and 20 by day 45-65 (medians of seeds 1-8).

### The sim walker
9. The sim walker of plan 0037 makes two choices that a player makes. They change no rule of the game:
   - It practises a gathering profession one level short of its next tier, once its character level has reached
     that tier.
   - In the last 3 levels of a stage, it gathers for a milestone of that stage that counts a gathered item.
10. Without them, chest materials filled the walker's recipes, and it stopped gathering: Mining 10 came on day 50
    instead of day 6, and the Angler milestone weeks late.

## Acceptance criteria
**The chest**
1. About 1 chest in 10 holds a piece of gear (a seeded test of many chests). It replaces spec 0013 criterion 19.
2. The common roll picks evenly among the learned gathering professions, Crafting if learned, and a meal. It replaces
   spec 0013 criterion 15.
3. The Crafting choice gives the inputs of one gear recipe with a Crafting level from the player's Crafting level
   minus 4 up to the Crafting level.
4. The Crafting choice never gives the inputs of a recipe of the gear in `supplyChest.exclude`.
5. A player without a gathering profession and without Crafting always gets a meal. It replaces spec 0013
   criterion 18.

**The pace**
6. The pacing test checks level 10 of the walker without feats within 5% of day 15.
7. The pacing test checks the median of Crafting 10 on day 6-22.
8. The pacing test passes.

**Check and release**
9. `.\scripts\check.ps1 -Pacing` is green.
