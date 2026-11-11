# Spec 0009, erratum 1: the hit chance moves 5% per level

Status: accepted
Corrects: [spec 0009](0009-fights-with-depth.md) §2.1 (the formula of the hit chance: "3% × (attacker level −
defender level)")
Issue: #59
Product owner: Zkalf (chose on 2026-11-11: the spec says 5%, as the game does)
Date: 2026-11-11

## What was wrong
- §2.1 says that the hit chance moves 3% for each level between the attacker and the defender.
- The data has said 5% since the first build of the fights: `hitPerLevel` 5 in `economy.json` (`combat`), from plan
  0011 milestone 1 (#15).
- The game and the pacing sims have always used 5%. The Hit sheet of amendment 4 tells players "Each level a monster
  is above you takes 5% off."
- No accepted text moved 3% to 5%. Claude found the gap while writing the clean edition of spec 0009.

## Correction
1. The formula of §2.1 reads:
   `hit chance = 85% + 5% × (attacker level − defender level) + attacker Hit`, kept between 50% and 95%.
2. Spec 0002 amendment 3 change 6 still sets the base to 75% and the top to 90%.
3. Nothing else changes: no data, no code, no test and no pace. The number lives in `economy.json`, as §2.1 says.
