# Spec 0021 amendment 1: the pacing test with the bag limit

Status: accepted
Amends: [spec 0021](0021-bag-limit.md) §5.3 target 5 (the pacing test stays green)
Issue: #173
Product owner: Zkalf (accepted on 2026-11-02, with day 91 for level 30)
Date: 2026-11-02

## Why
- With the bag limit, the mixed walker reaches level 30 on day 91.5 (median of 16 seeds), not day 84. The owner
  accepted day 91 (criterion 41).
- The pacing test pins seed 1 at level 30 within 5% of day 84 (spec 0017 criterion 31). Seed 1 now reaches it on
  day 91.
- The pacing test compares fighter seed 1 with the median of 8 mixed seeds (spec 0010 §9.3 target 3, at least 15%
  later). The fighter's days spread from 84 to 116, so one seed, or 8, says little:

| Fighter | Mixed | Gap |
|---|---|---|
| 16 seeds, median 105.5 | 16 seeds, median 91.5 | 15.3% |
| 8 seeds, median 97 | 8 seeds, median 92 | 5.4% |
| seed 1, day 96 | 8 seeds, median 92 | 4% |

## Change
1. **Criterion 31's day of level 30:** day 91, not day 84, within 5% as before. Levels 10 and 20 keep days 15
   and 50.
2. **The pacing test's fighter:** 8 seeds, the same as the mixed walker. Its median day of level 30 is later than
   the mixed walker's median. A fighter seed that does not reach level 30 in 120 days counts as day 121.
3. **The 15% target of spec 0010 §9.3 target 3:** a hand-run sim on 16 seeds, `dart run tool/bag.dart` and
   `dart run tool/bag.dart --fighter`. It runs with each change that moves the pace (CLAUDE.md, Rules).
4. Everything else in the pacing test stays as it is.

## Acceptance criteria
1. The pacing test checks seed 1 at level 30 within 5% of day 91.
2. The pacing test runs the fighter on seeds 1-8 and checks its median day of level 30 against the mixed walker's.
3. On 16 seeds the fighter's median day of level 30 is at least 15% later than the mixed walker's.
4. `.\scripts\check.ps1 -Release -Pacing` is green.
