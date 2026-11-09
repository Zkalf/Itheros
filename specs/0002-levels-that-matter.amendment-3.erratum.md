# Spec 0002 amendment 3, erratum 1: four things the build found

Status: accepted
Corrects: [spec 0002 amendment 3](0002-levels-that-matter.amendment-3.md) change 4, the reference checks that stay,
and the checks it moves; also spec 0001 criterion 5 as the pacing test reads it, and drops spec 0010 §9.3 target 4
Issue: #234
Product owner: Zkalf (chose on 2026-11-09: the Goblin gives 20 XP; the gatherer's target is dropped; accepted on
2026-11-09)
Date: 2026-11-09

## What was wrong
- **The two-hander and shield checks** (spec 0009 criterion 6) were listed as checks that stay. They compare weapons
  only in fights that the common-crafted reference player wins 90% of the time. At even level it now loses too often,
  so no fight counted: the rounds cut fell to 0 and the shield cut to 4-14%.
- **The first level-up** (spec 0001 criterion 5: level 2 within 350 walked steps) took 380-400 steps. By change 4,
  the Goblin gave 18 XP, and level 2 needs 20, so it still took two kills, each now longer.
- **The gatherer** (spec 0010 amendment 1, target 4: level 6-10 on day 90) reached level 5. It used to beat the
  Graveyard King once and cross the river; the tougher King now stops it, and it never fights otherwise.
- **Out-levelling the first boss** (spec 0002 amendment 1: 5 levels above the Graveyard King without gear wins at
  least 50%) was neither kept nor moved by the amendment; the build dropped it without a word. It now gives 27.5%.
- Claude's mistake: the amendment did not check these four older tests before it was accepted.

## Correction
1. The two-hander and shield checks compare the weapons with the reference player 5 levels above each monster of the
   stretch, where the one-hander wins. Their targets stay: about 25% fewer rounds (at least 15%), and the shield
   takes at least 20% off the damage.
2. The Goblin gives **20 XP**, not 18: one kill gives level 2, as today. It is the one exception to change 4.
3. The gatherer's target 4 (spec 0010 §9.3, amendment 1) is **dropped**, with its sim run in the pacing test. The
   game is not tuned for a player who never fights; the mixed walker's targets cover the professions. The gatherer
   walker stays in the tools for a hand look (`tool/bag.dart --gatherer`).
4. Out-levelling the Graveyard King takes **8 levels**: 8 levels above without gear wins at least 50% (Claude's
   proposal: you can still beat the first boss by levelling, just later).

## Numbers (5,000 steps a day)
- Level 2: after 310 steps on `main` (seed 1); 380-400 with 18 XP (seeds 1-3); 270-320 with 20 XP (seeds 1-8).
- The two-hander and shield checks 5 levels above: rounds cut 17-21%, shield cut 24-36%.
- The gatherer: level 7 on day 90 on `main`, level 5 with the amendment (seed 1).
- The Graveyard King without gear: 27.5% wins 5 levels above, 100% 8 levels above (200 fights each).
