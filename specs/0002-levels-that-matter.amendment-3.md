# Spec 0002 amendment 3: tougher, longer fights

Status: accepted
Amends: [spec 0002](0002-levels-that-matter.md) §5.2 (fight length targets), §5.3 (boss gear checks, as amendment 1
set them), §6 (the monsters' numbers), criteria 4 and 6; [spec 0009](0009-fights-with-depth.md) §2.1 (the hit chance);
[spec 0010 amendment 11](0010-professions.amendment-11.md) change 2 (the fighter's day of level 30)
Issue: #234
Product owner: Zkalf (chose on 2026-11-09: monsters tougher and the player's power trimmed a little; longer fights
with more monster HP; base hit 75%; level 30 stays on day 80-100; a gentle start; a pure fighter may take 80-120 days;
HP that carries over between fights waits for #244; accepted on 2026-11-09)
Date: 2026-11-09

## Why
- A study of 164,000 sim fights (#234): the walker won all but 30, a fight took 5 rounds, and the walker lost a median
  4% of its HP. Fights are the same from level 1 to 30, and meals change almost nothing.
- The monsters were tuned against a player in common crafted gear. A real player also has quality rolls, hide,
  scale and trophy pieces, rings and trinkets: about 1.6 times the HP and 1.4 times the Attack from level 20.
- From level 20 the player's hit chance is at its 95% cap in most fights, so luck plays almost no part.

## Change
**Monsters** (`enemies.json`)
1. **Normal monsters and lurkers from level 8:** HP × 2 and Attack × 1.35.
2. **The gentle start:** Goblin, Goblin brute and Skeleton (levels 1-6): HP × 1.5, Attack as today.
3. **Bosses:** HP × 1.5 and Attack × 1.2.
4. **XP follows the fight:** each monster's XP grows by the same factor as its fight length. The factor is the
   rounds of its fight against the spec 0002 reference player at its level, after the change ÷ before, with average
   swings (`estimateFight`). So XP per step stays about as today.
5. **Loot follows the fight too:** each normal monster's drop chances grow by the same factor. Gear drops grow by
   1.5 times more. A chance above 100% becomes 100% with a bigger count. Boss drops stay as today.

**Hit** (`economy.json`, `combat`)
6. The base hit chance is **75%**, not 85%, and its top is **90%**, not 95%. It counts for both sides, as today.
   The other numbers of spec 0009 §2.1 stay.

**The player's power** (`items.json`)
7. Hide, scale and trophy pieces (`reference: false`) and every ring, neck and trinket give a third less HP: their
   base HP × 2/3, rounded. Their other stats, quality bonuses and bonus stats stay.

**The sim walker** (`simulation.dart`)
8. When no fight is safe, a walker takes the fight that pays the most XP per step among those it wins on average
   swings, not the first monster in the data.
9. The fighter takes fights that it wins with at least 10% of its HP left; the mixed walker keeps the 25% of today.

**What stays**
10. The rules of a fight, the traits, losses (spec 0003 §5), the XP fade and the step cost of a round.
11. Every fight starts at full HP (#244 may change that later).
12. No save change.

## Targets
The yardstick is the sim walker, not the reference player: the walker wears what a player really wears. These are
the round 3 numbers of the study (8 seeds, 120 days, 5,000 steps a day); the build checks them again on 16 seeds with
the gentle start.

| # | Target | Today | Round 3 |
|---|---|---|---|
| 1 | Mixed walker: median day of level 30 in 80-100 (spec 0009 amendment 1) | 90.5 | 91.5 |
| 2 | Pure fighter: median day of level 30 in **80-120** (was 70-100) | 83.5 | 114 |
| 3 | Mixed walker: median rounds of a fight in 6-12 | 5 | 8 |
| 4 | Mixed walker: median HP taken in a fight in 10-25% | 4% | 15% |
| 5 | Mixed walker: 3-12% of fights take more than half its HP | 0.3% | 6.4% |
| 6 | Mixed walker: the Graveyard King takes a median 25-40 rounds | 18 | 30 |
| 7 | The player's hit chance in a fight never goes above 90% | at 95% in 68% of fights | at 90% in about half |

If a target fails in the build, Claude reports the numbers to the owner before any tuning.

**The reference player's checks change.** In common crafted gear alone, a player now loses often from level 8:
round 3 gave 14% wins against the Zombie, 3% against the Graveyard King. So:
- Spec 0002 §5.2 (normal fights 4-8 rounds, slow tanks 12-20; at least 90% wins at even level), §5.3's "even level
  with the stretch's crafted gear wins at least 70%" and "a fight takes 25-40 rounds", criterion 4 (each monster pays
  more per step, by at most a third) and the §3 check (XP per step within 15% of the rate for its level) are
  measured against the walker as targets 3-6, not against the reference player.
- These reference checks stay: an even-level player without gear wins at most 10% against a boss; 3 levels below
  with their own gear, at most 10% (the Chieftain and the Dragon); the strong weapon type (spec 0009 §9.1); a
  two-hander wins in about 25% fewer rounds (spec 0009 criterion 6).

## Acceptance criteria
**Data** (a one-time script makes the new numbers from today's; the PR lists each monster's and item's old and new
numbers, and the review checks them against changes 1-7)
1. Each monster of level 8 and up but the bosses has HP × 2 and Attack × 1.35 of today's, rounded.
2. Goblin, Goblin brute and Skeleton have HP × 1.5 of today's, rounded, and today's Attack.
3. Each boss has HP × 1.5 and Attack × 1.2 of today's, rounded.
4. Each monster's XP is today's × its rounds factor (change 4), rounded.
5. Each normal monster's drops follow change 5; boss drops are today's.
6. `economy.json` has `hitBase` 75 and `hitMax` 90.
7. The pieces of change 7 have two thirds of today's HP, rounded; other items are unchanged.

**Hit**
8. At even level with no Hit, about 75% of swings hit (± 1 point over many seeded swings).
9. No hit chance goes above 90%, with any Hit, Slayer or level gap.

**The walker and the pace**
10. Targets 1-7 hold on 16 seeds (a hand-run sim), or the owner accepts the numbers.
11. The pacing test checks targets 1, 2 and 3-6 on seeds 1-8.
12. The reference checks that stay (above) pass; the ones that moved to the walker are gone from `roster_test.dart`.

**Check and release**
13. No save change; every save fixture loads.
14. `releases/next/` has a line for players: monsters are tougher, fights are longer and pay more, and hits miss more
    often.
15. `.\scripts\check.ps1 -Release -Pacing` is green, and the release build declares no INTERNET permission.
