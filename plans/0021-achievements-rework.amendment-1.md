# Plan 0021 amendment 1: M1 and M2 in one pull request

Status: accepted
Amends: [plan 0021](0021-achievements-rework.md) (the milestones M1 and M2)
Product owner: Zkalf
Date: 2026-10-24

## Why
The rewards of M1 trip two pacing targets of `check.ps1`:

| Pacing target | Allowed | With the rewards |
|---|---|---|
| Crafting 20 (spec 0010 amendment 1) | day 45–65 | day 43 |
| Meals bring level 30 sooner (spec 0011 §9.3) | 0–5 days sooner | 1 day later |

With all rewards set to nothing, each pacing test passes. The sim walker earns three feats on the way: Bear Hunter,
Master of a Trade and Legendary Find. The counts of M2 and spec 0017 amendment 1 change this. A pull request needs a
green `check.ps1`, so M1 cannot ship before the counts of M2.

## Change
1. M1 and M2 are one pull request, on the branch `plan21-m1`.
2. The pull request also builds spec 0017 amendment 1 (Master of a Trade).
3. The order of work stays: the tests of M1, the code of M1, then the sim and the counts of M2.
4. If a pacing target still trips after the counts of M2, Claude stops and asks the owner.
5. M3 (the screens) stays a pull request of its own.
