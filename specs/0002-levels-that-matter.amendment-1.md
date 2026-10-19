# Spec 0002 amendment 1: later bosses need both gear and levels

Status: accepted
Amends: [specs/0002-levels-that-matter.md](0002-levels-that-matter.md) §5.3 (gear check targets) and acceptance
criterion 6
Product owner: Zkalf
Date: 2026-10-19

Found while tuning (plan 0003 M3): from level 20, gear is worth far more than 5 levels. For a level 35 player with
no gear to beat the Young Dragon, the dragon had to hit so softly that a geared level 21 player killed and farmed
it, and the simulated walker reached level 30 around day 72. The product owner decided that later bosses get a
harder check: they need more items and more levels. A few levels late in the game is already many steps.

## Replaces the §5.3 gear check targets
Simulated over 200 fights against each boss:

| Player | Graveyard King (10) | Ogre Chieftain (20), Young Dragon (30) |
|---|---|---|
| Even level, no gear | wins ≤ 10% | wins ≤ 10% |
| Even level, best crafted gear of that stretch | wins ≥ 70% | wins ≥ 70% |
| 5 levels above, no gear | wins ≥ 50% | — |
| 3 levels below, best crafted gear of their own level | — | wins ≤ 10% |

"Best crafted gear" never includes gear made from the boss's own drops (only materials no other monster or spot
gives count as the boss's own).

## Corrections to the spec text (found by the verifier)
- §8 level 6: the Graveyard King shows **orange**, not red (level 10 against 6 is +4, orange in §3's table).
- Decision 3 and §11: the roster is **14** normal monsters, 3 bosses and 1 lurker (18), as in the §6 table.
- §8: levels 16 and 21 bring no new recipe. Their named unlock is "a monster is now your level" (giant spider at
  16, stone golem at 21), which §9.1 lists as level news.
- §2 / criterion 11: a version 1 save at level 10 with XP past the old cap (28,000) keeps that extra XP as progress
  into level 10, up to one XP short of level 11. The rest of §5.3 is unchanged: fights take
25–40 rounds, XP per step matches a normal monster of the boss's level, first kills drop a unique item, and bosses
stay optional.
