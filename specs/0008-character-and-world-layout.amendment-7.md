# Spec 0008 amendment 7: a shorter stats block on Character

Status: accepted
Amends: [spec 0008](0008-character-and-world-layout.md) §3.5 ("The level, stats … and rank sit above the tabs") and
[spec 0009 amendment 4](0009-fights-with-depth.amendment-4.md) rule 10 (the "(+N meal)" line under a stat)
Issue: #254
Product owner: Zkalf (chose on 2026-11-10: the level beside the name, and the seven stats in one row; accepted on 2026-11-10)
Date: 2026-11-10

## Why
- The block with the portrait and the stats takes the top half of Character on a 408 dp phone. Each visit to Gear,
  Bag or Talents begins with a scroll.

## Change
1. **The level beside the name.** "Level 12" stands at the right of the character's name, not in the stats. A tap on
   it opens nothing, as before.
2. **One row of seven.** HP, Attack, Defense, Crit, Hit, Dodge and Block stand in one row, in this order, with
   smaller numbers. Each has its label under it, and a tap still opens its sheet (spec 0009 amendment 4).
3. **A smaller portrait.** The portrait is 48 dp, not 72 dp.
4. **The meal line** under a stat reads "+19 meal", without the brackets, in the small type of the labels.
5. At a large text size the row wraps to two rows, and the level wraps under the name. Nothing is cut off.
6. Each stat is at least 44 dp wide, so a thumb can hit it.

**What stays**
7. The name, the rank and the origin, the numbers of the stats, their sheets, the line "N talent points to spend" and
   the three tabs under the block.
8. No rule, number or save field changes. This does not move the pace, so it has no sim targets.

## Acceptance criteria
**The block**
1. The level stands on the line of the character's name, and the stats row has no Level.
2. At the usual text size on a 408 dp phone the seven stats stand in one row, in the order of change 2.
3. A tap on each of the seven stats opens its sheet. A tap on the level opens nothing.
4. With a meal that adds HP, the line under HP reads "+N meal".
5. The portrait is 48 dp.
6. At the usual text size on a 408 dp phone the block is shorter than before: the three tabs start in the top third
   of the screen (above 295 dp of 884).
7. At text size 2.0 on a 408 dp phone the block does not overflow.
8. Each stat is at least 44 dp wide.

**Check and release**
9. Rules, numbers and the save do not change. The pacing test passes.
10. Character is rendered at 408 dp wide, at the usual text size and at 2.0, before the PR (`CLAUDE.md`).
11. `releases/next/` has a line for players.
12. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
