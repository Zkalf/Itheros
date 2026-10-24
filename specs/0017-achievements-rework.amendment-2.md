# Spec 0017 amendment 2: Deep Waters counts catches at Cold tarn

Status: accepted
Amends: [spec 0017](0017-achievements-rework.md) §2.3 (row 30)
Product owner: Zkalf (chose "catch fish: a count" on 2026-10-24)
Date: 2026-10-24

## Why
The sim of plan 0021 M2 shows that the average walker (5,000 steps a day) reaches Fishing 25 about one day after
level 30, without a grind. Fishing 30 costs only about 5 days of grind. A late feat costs about 14 days (§3.3).

## Change
1. Deep Waters asks for **a number of catches at Cold tarn**, the fishing spot of level 20. Its reward stays +6 Block.
2. The criterion is the counter `gathered.tarn_scale`. Each catch at Cold tarn gives one tarn scale, and no other spot
   gives one.
3. The sim sets the number, as for the other feats (§3.3).
4. The Achievements screen names the goal as catches at Cold tarn, for example "Catch 500 fish at Cold tarn".
5. Each other part of spec 0017 stays.
