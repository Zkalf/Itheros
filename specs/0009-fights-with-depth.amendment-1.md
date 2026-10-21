# Spec 0009 amendment 1: luck may be faster

Status: accepted
Amends: [spec 0009](0009-fights-with-depth.md) criterion 16 (and so spec 0002 criterion 3's level 30 target)
Product owner: Zkalf (chose "let luck be faster" during plan 0011 M2, 2026-10-21)
Date: 2026-10-21

## Why
With bonus stats at the §5.1 sizes, the 8 simulated walkers reach level 30 on days 75–86, typically around day 82
(as before spec 0009). The spread comes from luck: a walker who finds strong gear early fights higher monsters
sooner. Smaller bonus stats don't narrow it (at half size: day 71–85). Holding every walker to day 80 would need
about 20% more XP for each level from 21 to 30. That would lengthen everyone's late game, and the luckiest walker
would sit right on day 80, where any later data change can tip it out. The owner prefers that luck pays off (spec
concern 2's Diablo chase).

## Change
Criterion 16 becomes: simulated 5,000 steps a day on seeds 1–8: level 5 on day 1–2, level 10 on day 12–16, level
30 on day **70–100 on every seed**, and the **median of the 8 seeds on day 80–100**. The typical walker keeps spec
0002's target; a lucky one may get there up to 10 days sooner.

XP, monsters and the bonus stat sizes of §5.1 stay as they are.
