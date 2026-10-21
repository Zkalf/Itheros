# Spec 0008 amendment 2: recipes keep a level until spec 0010

Status: accepted
Amends: [spec 0008](0008-character-and-world-layout.md) decision 1, criteria 4 and 13, and
[amendment 1](0008-character-and-world-layout.amendment-1.md) §3 and its criteria
Product owner: Zkalf (chose it, 2026-10-21)
Date: 2026-10-21

Found in plan 0010 M1: with every recipe open, the pacing simulator's lucky runs crafted level 28 gear at level 22,
beat the level 30 Young Dragon, made Dragon-scale armour from its drops and farmed it for full XP. Level 30 came on
day 59–79 depending on luck (target 80–100). Slowing levels 20–30 didn't help. The owner chose the same fix as
amendment 1.

## Change
1. **Recipes need a player level** to craft: their `level` in `items.json` (today's numbers). Every recipe is
   **shown** from level 1, with "Needs level 28" in place of the craft button. Picking or queueing one below its
   level is refused. Spec 0010 replaces this with the Crafting level.
2. A recipe reaching its level is level-up news again ("New recipe: Bone sword").
3. Areas and monsters stay fully open: a player can still walk to Dragon's Peak and lose to the dragon.
4. The XP table is unchanged.

## Acceptance criteria
4 (replaces amendment 1's). At level 1, every monster, gathering spot and recipe in data is shown wherever its area
is not fogged; no `unlockLevel` is left in `data/*.json`; the only levels a rule checks before an action are a
gathering spot's and a recipe's (one above the player's level can't be started or queued, and shows
"Needs level N").
13 (replaces amendment 1's). The pacing simulator may walk anywhere it can see, and its targets still hold.
