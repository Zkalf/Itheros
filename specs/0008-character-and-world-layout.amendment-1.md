# Spec 0008 amendment 1: gathering spots keep a level until spec 0010

Status: accepted
Amends: [spec 0008](0008-character-and-world-layout.md) decision 1, criteria 4 and 13
Product owner: Zkalf
Date: 2026-10-21

Found while starting plan 0010 M1: with no gates, a level 2 player can walk to Mithril Deep and mine. Mining has no
danger, and XP only fades for things below the player, so mithril ore pays its full XP and makes a Mithril sword on
day 1. That breaks the pacing targets. Profession levels (spec 0010) are meant to hold mining back but don't exist
yet. The owner chose a level requirement on gathering spots until then.

## Change
1. **Gathering spots need a player level** to work: Copper vein 2, Iron vein 12, Mithril vein 22 (`level` in
   `world.json`). They are **shown** from level 1 wherever their area isn't fogged, with "Needs level 12" instead of
   a start button. Picking or queueing one below its level is refused. Spec 0010 replaces this with the Mining
   level.
2. Areas, monsters and recipes stay fully open (decision 1 otherwise unchanged).
3. Spots and recipes keep a **level** of their own (today's numbers, renamed from `unlockLevel`), used only for the
   XP fade (spec 0002 §3) and the item level of quality rolls (spec 0005 §3), not as a gate on recipes.

## Acceptance criteria
4 (replaces). At level 1, every monster, gathering spot and recipe in data is shown wherever its area is not
fogged; no `unlockLevel` is left in `data/*.json`; the only level a rule checks before an action is a gathering
spot's (a spot above the player's level can't be started or queued, and shows "Needs level N").
13 (adds). The pacing simulator may walk anywhere and craft any recipe, and its targets still hold.
