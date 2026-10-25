# Sim table: achievements rework (spec 0017)

The table of spec 0017 §8, from plan 0021 M2 (plan choice 3 puts it here). The sim ran on 2026-10-24 with
`dart run tool/feat_cost.dart` in `packages/game_core`, at 5,000 steps a day, seed 1.

## The walker without feats
| Level | Day | Spec 0017 criterion 31 |
|---|---|---|
| 10 | 16 | 16, ±5% |
| 20 | 50 | 50, ±5% |
| 30 | 84 | 84, ±5% |

The walker earns no feat without a grind. The pacing test of `check.ps1` checks criteria 31 and 32 on each run.

## The feats
A feat costs its days of grind: from the start of the grind to the feat (spec 0017 amendment 3). The grind starts at
the last level of the stage of the feat: level 10, 20 or 30.

| Feat | Stage | Count | Grind from day | Earned on day | Grind days | Target |
|---|---|---|---|---|---|---|
| Goblin Slayer I | early | 1,200 Goblins | 16 | 19 | 3 | about 3 |
| Brute Force | early | 1,000 Goblin Brutes | 16 | 19 | 3 | about 3 |
| Bone Collector | early | 700 Skeletons | 16 | 19 | 3 | about 3 |
| Chieftain's Bane | mid | 275 Ogre Chieftains | 50 | 57 | 7 | about 7 |
| Bear Hunter | mid | 1,050 Old Bears | 50 | 58 | 8 | about 7 |
| Wolf Pack | mid | 1,350 Wolves | 50 | 57 | 7 | about 7 |
| Ghost Hunter | mid | 1,700 Ghosts | 50 | 57 | 7 | about 7 |
| Dragonslayer | late | 1,150 Young Dragons | 84 | 98 | 14 | about 14 |
| Golem Breaker | late | 2,150 Stone Golems | 84 | 98 | 14 | about 14 |
| Troll Slayer | late | 3,100 Trolls | 84 | 98 | 14 | about 14 |
| Wyvern Hunter | late | 2,200 Wyverns | 84 | 98 | 14 | about 14 |
| Master of a Trade | late | level 30 in Mining, Woodcutting, Fishing and Hunting | 84 | 103 | 19 | about 14 |
| Deep Waters | late | 500 catches at Cold tarn | 84 | 99 | 15 | about 14 |
| Legendary Find | late | luck | — | — | — | the chance of a Legendary item |

- Master of a Trade has no count to tune. Its levels come from spec 0017 amendment 1.
- Legendary Find is luck (spec 0017 §3.3). Earlier runs of this sim found a Legendary item on day 46 or day 65. The
  last run found none in 200 days.

## How the counts came
The first counts were those of spec 0017 §2. Four runs of the tool tuned them. Each run scaled a count by the grind
days that it cost. On the way, the sim also found the problems that spec 0017 amendments 1, 2 and 3 solve:
- Master of a Trade came on the way.
- Deep Waters came on the way.
- Smith's free shield slowed the walker.
- Five milestones did not come on the way.
