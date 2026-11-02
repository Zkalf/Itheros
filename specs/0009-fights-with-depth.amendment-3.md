# Spec 0009 amendment 3: each seed reaches level 30 by day 105

Status: accepted
Amends: [spec 0009 amendment 1](0009-fights-with-depth.amendment-1.md) (each seed reaches level 30 on day 70-100)
Issue: #181
Product owner: Zkalf (accepted on 2026-11-02)
Date: 2026-11-02

## Why
- Since the bag limit (spec 0021), the mixed walker's median day of level 30 is about day 92. The slowest seeds sit
  just under day 100.
- Plan 0042 (rerolls at Camp take the bank's dust) moved the median by half a day (91.5 to 92, 16 seeds), but seed
  3 from day 97 to day 102. The pacing test then failed on one seed, not on the pace.
- CLAUDE.md: a system that is not meant to move the pace gets no sim work; the owner chose to widen the range.

## Change
1. Each seed of the pacing test reaches level 30 on day 70-105, not 70-100.
2. The pacing test's walker runs 105 days, so a seed can show day 101-105.
3. The median seed still reaches level 30 on day 80-100 (spec 0009 amendment 1). It catches a real slowdown.

## Acceptance criteria
1. The pacing test checks each seed's level 30 on day 70-105, and the median on day 80-100.
2. `.\scripts\check.ps1 -Pacing` is green.
