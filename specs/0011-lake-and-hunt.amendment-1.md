# Spec 0011 amendment 1: when the walker cooks and crafts tools, the profession curve, Travelling Salesman

Status: accepted
Amends: [spec 0011](0011-lake-and-hunt.md) §9.2 (the mixed walker), and so spec 0010 §9.2 as amendments 1–2 left
it; the `professionXpToReachLevel` numbers of spec 0010 §2.2; spec 0004's Travelling Salesman (every area)
Product owner: Zkalf (chose the Travelling Salesman count and accepted the rest during plan 0013 M1, 2026-10-22; found in M1
and shown in its PR)
Date: 2026-10-22

## Why
Plan 0013 M1's first runs (5,000 steps a day, seeds 1–8):
1. **Cooking on day 2 stalls the walker.** Cooking from level 5, the walker spends about 3,000 steps fishing perch
   for its first batch, at a quarter of a fight's XP: level 10 on day 17 on three seeds (target 11–16).
2. **Tools it barely uses.** At level 5 it also crafted a copper rod and pot (24 more ore and logs) for professions it
   had hardly worked. Spec 0010 §9.2 already says tools are "weighed by steps saved on what it gathers and crafts".
3. **Professions run ahead.** The 15 new pieces (§7) mean more crafting, and the walker practises Crafting 6 for the
   first hide pieces on day 3: Mining and Crafting 10 on day 4–7 (target 8–22), Crafting 20 on day 39 (45–65). Spec
   0010 §9.4 names the profession XP table as the first knob for this target.
4. **Travelling Salesman** asked for every area. The hidden cove is one most players never find, so the owner chose
   to count only the areas that aren't hidden.

## Change
1. §9.2, the mixed walker and the gatherer: they start a meal batch (in camp, with fewer than two meals) only from
   **character level 10**. The batch stays 10.
2. §9.2: it crafts a profession's tool only once that **profession's level reaches the tool recipe's level** (copper
   3, iron 12, mithril 22), on top of amendment 2's rule (2 character levels past the recipe).
3. `professionXpToReachLevel` is **25% steeper** (each entry × 1.25, rounded): Mining 10 needs 572 XP (was 458),
   level 20 needs 4,255 (was 3,404).
4. Travelling Salesman: **arrive at all 11 areas that aren't hidden** (Smugglers' Cove is a bonus).

Real players have none of the walker rules: they can cook and craft any tool whenever they like.

## Numbers at the end of M1 (5,000 steps a day, seeds 1–8)
Level 5 on day 2, level 10 on day 14–15, level 30 on day 86–99 (median 89.5); without meals level 30 median 90.0
(target 5: meals no later, at most 5 days sooner); Mining 10 median day 21.5, Mining 20 56.5; Crafting 10 median
day 8, Crafting 20 51.5; the fighter doesn't reach level 30 by day 120; the gatherer is level 7 on day 90. Fishing /
Hunting / Cooking medians: day 30 8 / 6 / 5, day 60 13 / 13.5 / 7, day 90 21 / 22 / 7.

The walker's meals change little: it cooks only when it passes camp (decision 5), which after the early levels is
rare, so most seeds eat one or two batches. Meals on and off differ by up to 10 days on a single seed from the
fights they reshuffle; the medians differ by half a day.
