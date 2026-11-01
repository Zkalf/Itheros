# Spec 0015 amendment 1: the sim measures full builds, and Utility gets Practised hands

Status: accepted
Amends: [spec 0015](0015-talent-trees.md) §5 (balance), §2.4 (the Utility tree), §2.8 (the effects) and criteria 8
and 62
Issue: #55
Product owner: Zkalf (2026-10-31: "I think you should add both. Yeah. Agreed. Accepted."; trim Might and Swift
strikes, keep Impale)
Date: 2026-10-31

## Why
- §5 measures the balance by the days to level 25. The first sim (plan 0031 M1) showed that this does not work:
  - A player has 16 of 30 points at level 25. The talents that make fights faster sit deep in the tree.
  - Every build reached level 25 on about day 70 (the mean of 4 seeds: none 69.8, Combat 70.0, Utility 70.0, Split
    70.3). Crafting, travel and the safe monsters decide that race, not the talents.
- Intent 0015 outcome 5 compares **full** builds. Measured that way (60 days from the level 37 walker), Combat gave
  +43% XP and Utility +0%. Combat is far over the 10-15% that the owner chose.
- Utility gives no XP at the soft cap: the walker only fights there, and its talents give comfort. The owner wants
  one Utility talent with a small amount of power that is not about fights.

## Change
1. **Practised hands**, a new Utility talent:
   - Row 4, next to Light pack. 3 ranks.
   - Each rank: +4% profession XP. Full: +12%.
   - It multiplies the profession XP of each gathering and crafting action, after the fade, rounded down.
   - It does not change character XP. Effect: `professionXp`.
   - The Utility tree holds 33 points. The player still cannot fill both trees (the soft cap gives 28).
2. **The Combat trim** (owner's choice): Impale keeps 2.5×. Might and Swift strikes get smaller: the starting values
   become +1% Attack and 1% fewer steps a rank. The sim may tune them further, and the other Combat numbers, to meet
   the targets below. Impale stays at 2.5×.
3. **§5 is replaced.** The sim runs two parts, each the mean of 4 seeds, at 5,000 steps a day:
   - **Part A, the whole game:** a new character, 120 days, for each of the four builds of §5 (none, Combat,
     Utility, Split).
   - **Part B, full builds:** the no-talent walker of part A on day 120 (about level 37, 28 points). Each build takes
     its points in its order, then plays 60 more days.
4. **The targets:**
   1. Part B: Combat gains 10-15% more XP than Utility.
   2. Part B: Combat finds at least as many Rare-or-better monster drops as Utility.
   3. Part B: no build gains more than 2% less XP than no talents.
   4. Part A: on day 50, Combat has more XP than Utility.
   5. Part A: on day 50, no build has more than 2% less XP than no talents.
   6. Part A: on day 60, the profession levels of the Utility build add up to more than with no talents.
   7. No-talent pace stays as today: the pacing test passes.
5. The results file of plan 0031 records parts A and B, and each number that the sim moved.

## Acceptance criteria
These criteria replace criteria 8 and 62 of spec 0015. The numbers continue after criterion 64.

**Points and rows**
65. The Combat tree holds 30 points, and the Utility tree holds 33.

**Utility effects**
66. Practised hands at rank 3 gives 12% more profession XP from an action, rounded down.
67. Practised hands does not change the character XP of an action.

**Balance**
68. The sim results meet the targets of change 4, and the results file of plan 0031 records them.

**Check and release**
69. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
