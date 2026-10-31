# Plan 0031 results: the talent sim

The record of spec 0015 criterion 62, as [amendment 1](../specs/0015-talent-trees.amendment-1.md) change 4 has it
(criterion 68). Run: `dart run tool/talents.dart --seeds 12` in `packages/game_core`, at 5,000 steps a day, the mean
of 12 seeds. Date: 2026-10-31.

## Part A: a new character, 120 days

| Build | XP on day 50 | Against no talents | Profession levels on day 60 | Rare-or-better drops |
|---|---|---|---|---|
| None | 162,755 | — | 94.3 | 8.1 |
| Combat | 171,353 | +5.3% | 95.7 | 9.5 |
| Utility | 166,646 | +2.4% | 95.3 | 7.8 |
| Split | 171,353 | +5.3% | 95.7 | 8.9 |

## Part B: full builds, 60 days from the no-talent walker on day 120

| Build | XP gained | Against Utility | Rare-or-better drops |
|---|---|---|---|
| None | 225,994 | +0.0% | 6.4 |
| Combat | 255,918 | **+13.2%** | 9.8 |
| Utility | 225,994 | — | 6.4 |
| Split | 245,304 | +8.5% | 6.6 |

## The targets

| # | Target | Result |
|---|---|---|
| 1 | Part B: Combat gains 10-15% more XP than Utility | met: +13.2% |
| 2 | Part B: Combat finds at least as many Rare-or-better drops as Utility | met: 9.8 against 6.4 |
| 3 | Part B: no build more than 2% under no talents | met |
| 4 | Part A: Combat has more XP than Utility on day 50 | met: +5.3% against +2.4% |
| 5 | Part A: no build more than 2% under no talents on day 50 | met |
| 6 | Part A: Utility's profession levels on day 60 above no talents | met: 95.3 against 94.3 |
| 7 | The pacing test passes | met: `check.ps1` |

## What the sim moved

| Talent | Spec 0015 / amendment 1 | Now | Why |
|---|---|---|---|
| Might | +2% Attack a rank (amendment 1: +1%) | **+0.8%** a rank | Alone it gave +12.4% XP in part B at +2%. With Swift strikes and Impale, Combat was +43%. |
| Swift strikes | 3% fewer steps a rank (amendment 1: 1%) | **0.5%** a rank | Alone it gave +17.2% in part B at 3%. |
| Impale | 2.5× | 2.5× (kept) | The owner's choice. Alone it gives +10.6% in part B. |
| Nimble hands | 2% fewer steps a rank | **1%** a rank | Taken first, at 2% it pulled part A's Utility XP down to −4.2%: the walker gathers more and fights less when gathering is cheap. |
| Practised hands | row 4, +4% a rank | **row 2, +2%** a rank | In row 4 a Utility player gets it only after level 25, too late for target 6. At +4% alone it gave +17% XP on day 50, more than "a slight amount". |
| Utility row 1 | Deep pockets, Nimble hands | the same order | With Nimble hands first, part A's Utility was −4.2% (12 seeds); with Deep pockets first, +2.4%. |

## What the sim showed
- **At the soft cap the walker only fights.** Toughness, Guard, Precision and Evasion give 0% XP there: it never loses,
  and its Hit is at the cap. They help in the middle of the game, against monsters at or above the player's level.
- **Utility gives no XP at the soft cap**, as amendment 1 expects. Its gain there is comfort that the sim does not
  count: the bank, the queue slot, travel, crafting.
- **The walker's choices make part A noisy.** With 4 seeds, part A's Utility moved between −4.6% and +5.9% with the
  order of two talents in row 1. With 12 seeds the order still matters, and the numbers above are with 12 seeds.
