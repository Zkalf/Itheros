# Spec 0013 amendment 2: Crafting 20 with chests

Status: accepted
Amends: [spec 0010 amendment 1](0010-professions.amendment-1.md) point 4 (the day of Crafting 20), as
[spec 0013 amendment 1](0013-daily-chest.amendment-1.md) point 8 restates it
Issue: #57
Product owner: Zkalf (chose on 2026-11-01 a faster pace with chests; spec 0013 amendment 1)
Date: 2026-11-01

## Why
- Spec 0013 amendment 1 moved Crafting 10 for the chest's Crafting materials. It missed Crafting 20.
- With chests, the median of seeds 1-8 reaches Crafting 20 on day 44.5:

  | Seed | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
  |---|---|---|---|---|---|---|---|---|
  | Crafting 20 on day | 48 | 46 | 41 | 47 | 43 | 46 | 42 | 43 |

- The target is day 45-65.

## Change
1. Crafting reaches 20 by day **40-65** (median of seeds 1-8). It was 45-65.
2. Mining 20 stays at day 45-65. With chests, its median is day 54.5.
3. Everything else of spec 0013 amendment 1 stays as it is.

## Acceptance criteria
1. The pacing test checks the median of Crafting 20 on day 40-65.
2. The pacing test checks the median of Mining 20 on day 45-65.
3. `.\scripts\check.ps1 -Pacing` is green.
