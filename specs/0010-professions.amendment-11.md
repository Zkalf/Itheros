# Spec 0010 amendment 11: the fighter focuses on fighting

Status: accepted
Amends: [spec 0010](0010-professions.md) §9.3 target 3 (the fighter is clearly slower); also
[spec 0021 amendment 1](0021-bag-limit.amendment-1.md) changes 2-3 and criteria 2-3 (the fighter in the pacing test)
Issue: #237
Product owner: Zkalf (on 2026-11-07: "the fighting should not only fight but just focus on it"; chose "like mixed,
fights first" and "accept: fighting is fastest")
Date: 2026-11-07

## Why
- The fighter sim walker only fights. It never learns a profession, never cooks and never crafts.
- The owner wants it to play like a player who likes fights: fights first, but also crafts and eats.
- With that habit it reaches level 30 sooner than the mixed walker. Target 3 says it must be at least 15% later.

## Change
1. **The fighter's habit.** The fighter sim walker (`Walker.fighter`):
   - learns every profession at Camp, as the mixed walker does;
   - salvages its spare gear at a forge, and cooks and eats meals, as the mixed walker does;
   - beats the Graveyard King first (spec 0008 amendment 5), then follows its feat, reroll and meal goals;
   - crafts the best gear upgrade up to its level when it holds all the materials;
   - else fights the monster that pays best. It never gathers or practises a profession for gear.
2. **Target 3 becomes:** the fighter's median day of level 30 is in 70-100, the same range as the mixed walker's
   (spec 0009 amendment 1). It does not need to be later than the mixed walker. Fighting first is a fine way to play.
3. The pacing test checks target 3 on seeds 1-8. A fighter seed that does not reach level 30 in 120 days counts as
   day 121 (spec 0021 amendment 1 change 2, kept).
4. The 15% comparison on 16 seeds (spec 0021 amendment 1 change 3) ends.
5. **What stays.** No game rule, number or data changes. The mixed walker and the gatherer do not change.

## The pace (hand sims, 16 seeds, 5,000 steps a day)
| Median day of level 30 | Before | After |
|---|---|---|
| Fighter | 95.5 (78-118) | 81 (72-99) |
| Mixed walker | 86 | 86 |

## Acceptance criteria
**The walker**
1. The fighter learns every profession on day 1.
2. The fighter crafts a gear upgrade when it holds the materials, and gathers for none.

**Pace**
3. The pacing test checks that the fighter's median day of level 30 (seeds 1-8) is in 70-100.
4. The pacing test no longer checks that the fighter is later than the mixed walker.

**Check and release**
5. `.\scripts\check.ps1 -Release -Pacing` is green.
