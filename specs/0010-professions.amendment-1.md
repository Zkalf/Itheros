# Spec 0010 amendment 1: profession pace, starter recipes, the walker

Status: accepted
Amends: [spec 0010](0010-professions.md) §9.2 (the simulated walker) and §9.3 targets 1, 2 and 4 (and so spec 0002
criterion 3's level 10 target)
Product owner: Zkalf (chose the targets during plan 0012 M1, 2026-10-21/22; the other two changes are found in M1 and
shown in its PR)
Date: 2026-10-21

## Why
Plan 0012 M1 found three things:
1. **No first recipe.** The cheapest recipes (copper sword, spear, mace, hide vest) had level 3, now their Crafting
   level, while a new player has Crafting 1: nothing could be crafted, so Crafting could never rise.
2. **The walker stalled.** A walker that only gathers and crafts what its next upgrade needs never reaches the level
   that upgrade wants (it needs a few oak logs, not Woodcutting 10). Spec §8.4 already tells a real player what to do
   then: "Reach Mining 10 to dig iron".
3. **Tier 2 falls where it is needed.** The walker digs iron only when its character reaches level 12 (day 16–19),
   so Mining 10 lands on day 19.5 (median) whatever the curve; Crafting 10 on day 11.
4. **Luck comes early too.** Practising Crafting means more crafts and so more quality rolls: one walker of eight
   (seed 4) reaches level 10 on day 11. The owner chose to let luck be a day faster, as for level 30 (spec 0009
   amendment 1).

## Change
1. The copper sword, spear and mace and the hide vest need **Crafting 1** (`crafting` 1 in `items.json`; their
   `level`, which sets the item level and the reference player's gear, stays 3).
2. §9.2, the mixed walker: it aims at upgrades up to its own character level. When the best one is held back only by
   a profession level, it **practises that profession**: its highest spot, or for Crafting the recipe with the most
   Crafting XP per step (getting the inputs included). It still never practises for its own sake. The
   gatherer-crafter explores the open areas it hasn't stood in before it practises, since the fog hides the higher
   spots.
3. §9.3 target 1: level 10 on day **11–16** (was 12–16); the rest of spec 0009 amendment 1 holds.
4. §9.3 target 2 becomes: Mining and Crafting reach 10 by day **8–22** and 20 by day 45–65 (medians of seeds 1–8).
5. §9.3 target 4: the gatherer-crafter is **level 6–10 on day 90** (seed 1 in the pacing test; level 7 on every seed
   at M1). The owner: fighting is the game's main way to grow, the professions add to it.

## Numbers at the end of M1 (5,000 steps a day, seeds 1–8)
Character level 10 on day 11–14 (median 13), level 30 on day 81–96 (median 91); Mining 10 median day 20, Mining 20
54.5; Crafting 10 median day 11, Crafting 20 48; the fighter doesn't reach level 30 by day 120 on any seed; the
gatherer-crafter is level 7 on day 90 on every seed.
