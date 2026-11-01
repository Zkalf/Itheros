# Spec 0015 amendment 2: the numbers that the sim tuned

Status: accepted
Amends: [spec 0015](0015-talent-trees.md) §2.3, §2.4, §4 and criteria 14, 18, 26 and 38, and
[amendment 1](0015-talent-trees.amendment-1.md) change 1, change 3 and criterion 66
Issue: #55
Product owner: Zkalf
Date: 2026-10-31

## Why
- The sim of plan 0031 M1 tuned the talents to the targets of amendment 1. The record is
  [`plans/0031-talent-trees.results.md`](../plans/0031-talent-trees.results.md): all 7 targets met, Combat +13.2% over
  Utility in full builds.
- Amendment 1 lets the sim tune the Combat numbers. Four changes go further, and four criteria still state the old
  numbers:
  - Nimble hands and Practised hands are Utility talents.
  - The row of Practised hands is a placement, not a number.
  - Amendment 1 says 4 seeds. With 4 seeds, part A moved by up to 10 points with the order of two talents, so the sim
    used 12.

## Change
1. **The tuned numbers:**

| Talent | Accepted | Now | Full |
|---|---|---|---|
| Might | +2% Attack a rank (spec 0015); +1% (amendment 1) | **+0.8%** a rank | +4% Attack |
| Swift strikes | 3% fewer steps a rank; 1% (amendment 1) | **0.5%** a rank | 2.5% fewer |
| Nimble hands | 2% fewer steps a rank | **1%** a rank | 5% fewer |
| Practised hands | +4% profession XP a rank | **+2%** a rank | +6% |

2. **Practised hands moves to row 2**, next to Bountiful and Wary. In row 4 a Utility player gets it after level 25,
   too late for target 6 of amendment 1.
3. **The sim uses the mean of 12 seeds**, not 4.
4. **Utility row 1 keeps its order:** Deep pockets, then Nimble hands. The walker of the sim takes the talents of a row
   in data order. With Nimble hands first, part A's Utility build fell 4.2% under no talents on day 50.
5. **A reroll uses Lucky hammer only.** Spec 0015 §2.4 says both "Master crafter … rerolls do not use it" and "Lucky
   hammer … multiplies with Master crafter". The first rule holds: Master crafter does not boost a reroll. Criterion 38
   (Lucky hammer at rank 3 multiplies a reroll's chances by 1.45) holds with Master crafter too.
6. **The saved reset price of a new or old save is 0**, which means the base price of the data (`resetBase`, 2,000).
   Spec 0015 §4 says 2,000. The price that the player pays does not change, and the number lives only in
   `talents.json`.
7. Every other number of spec 0015 and amendment 1 stays.

## Acceptance criteria
These criteria replace criteria 14, 18 and 26 of spec 0015 and criterion 66 of amendment 1. Criterion 75 adds to
criterion 38. The numbers continue after criterion 69.

**Combat effects**
70. Might at rank 5 adds 4% of the level-and-gear Attack, rounded down.
71. With Swift strikes at rank 5, a won fight of 6 rounds gives 1 step back to the action (60 × 0.025, rounded down).

**Utility effects**
72. Nimble hands at rank 5 makes a 100-step gathering action with a starter tool cost 95 steps.
73. Practised hands at rank 3 gives 6% more profession XP from an action, rounded down.
74. Practised hands is a row 2 talent.
75. A quality reroll with Master crafter at rank 3 and Lucky hammer at rank 3 multiplies the Uncommon-or-better
    chances by 1.45, not by more.

**Check and release**
76. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
