# Spec 0005 amendment 1: boss uniques repeat at 1%

Status: accepted
Amends: [spec 0005](0005-item-qualities.md) decision 6 and criterion 6; intent 0005's starting value of 5%
Product owner: Zkalf (chose option a, 2026-10-19)
Date: 2026-10-19

## Change
A boss's unique item drops again on later kills with `repeatChance` **0.01** (was 0.05).

## Why
The pacing simulator's average walker kills bosses about 200 times by day 90. At 5% it collected several boss
uniques with epic or legendary quality and reached level 30 on day 70-80, outside spec 0002's target (80-100). At 1%
it reaches level 30 on day 80-89, and a boss farmer still finds a repeat about once per 100 kills.
