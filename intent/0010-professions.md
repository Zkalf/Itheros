# Intent: Professions

Status: accepted
Product owner: Zkalf
Date: 2026-10-21

## Problem
Mining and crafting are side activities with no growth of their own: they only feed the character's level and the
next recipe. A great RPG lets you become good at something (World of Warcraft's professions), with crafts that feed
each other in ways that make sense in the world. Owner: "the system should be called professions"; "they should
interact with each other when it makes sense RP-wise"; "I know this is changing the whole system but we have to, in
order to make it a great RPG game."

This intent builds the profession system with the three that fit today's world: **Mining**, **Woodcutting** (new)
and **Crafting**. Intent 0011 adds Fishing, Hunting and Cooking on the same system.

## Proposed outcome
1. **Each profession has its own level.** Steps spent in a profession earn profession XP. There is no level cap: a
   new material tier (copper, iron, mithril, ...) opens about every 10 levels, and new content adds tiers. Recipes
   and gathering spots need a profession level, not a character level. Rough feel at 5,000 steps a day, focusing on
   one profession: tier 2 in about two weeks, tier 3 in about two months.
2. **Professions also level the character, a little.** A profession step gives about a quarter of the character XP a
   fighting step gives. Focusing on one side (only fighting, or only professions) still takes a player far, but a
   **mix is the fastest way** to grow: crafted gear and tools let you beat harder monsters, and monsters drop
   materials the professions need.
3. **Professions feed each other.** Ore and logs go into Crafting; monster drops (bones, hides) too. Crafting makes
   gear and the tools for the other professions. Each gathering profession has a rare find of its own (a gem in the
   ore, heartwood in the logs) for special recipes: a small-chance chase in the Diablo 2 spirit.
4. **A tool for each profession.** Pickaxe, hatchet and smith's hammer, one slot each, shown with the profession on
   the Professions screen (not on the paper doll). Tools are crafted and roll quality like gear. A better tool makes
   each action cost fewer steps and nudges the rare-find chance up very slightly.
5. **Teachers in camp.** The miner, the woodcutter and the smith are in camp from level 1. Talking to one (from Now,
   when in camp) teaches the profession and gives a Common starter tool, with a line of RP ("Take my old pick. Bring
   me copper and we'll talk."). They also share tips about monsters, filling in bestiary cards (intent 0009).
6. **Salvage at the forge.** Spare gear can be broken down at the forge into **dust** of its quality (Uncommon dust,
   Rare dust, ...). Salvage gives dust only, no materials back. Dust **rerolls an item's quality**, and a reroll never
   lands below what the item has; when it lands higher, the item keeps its bonus stats and gains one for each new
   step. Salvaging has a tiny chance to give a **boss shard**; 10 shards of one boss make that boss's unique item.
7. **The Professions screen** (bottom button, intent 0008) lists each profession with an RP icon, its level and
   progress, tier, tool and recipes, and where to practise it, with a way to go there.

## Affected users and systems
All players. Game rules (profession XP and levels, character XP from professions, tools, rare finds, salvage, dust,
rerolls, shards), `data/*.json` (professions, tiers, tools, woodcutting spots and logs, recipes with profession
levels, dust costs, shard chances), the save (profession levels and XP, tool slots, dust, shards, learned
professions), camp NPCs on Now, and the Professions screen.

## Constraints
- **Balance for ~5,000 steps a day.** The sim shows, before the spec is accepted: a mix beats pure fighting and pure
  professions by a clear margin; pure professions still reaches a fair character level by day 90 (number set from the
  sim); the character pace from spec 0002 holds for a mixed player. Pacing tests stay green.
- **Diablo-style rarity:** rare finds and shards stay low-chance; tool and level bonuses to rare chances stay very
  minor (as for quality in spec 0005).
- **Existing saves keep their progress.** Every vein mined and item crafted so far counts as profession XP, so
  players start at the profession levels their past work earned. Mining and crafting count as already learned. Where
  the save doesn't record a count, a fair estimate from what it does record is used.
- Clean UI (intent 0008): one Professions screen; doing things stays where it happens (Now at the place, World to get
  there).
- Out of scope: Fishing, Hunting, Cooking and their NPCs (intent 0011); character origins (0012); quests from NPCs
  (later); splitting Crafting into Blacksmithing and Leatherworking (later, when content needs it).

## Open questions
None blocking. Exact numbers (profession XP curve, step costs, tool bonuses, dust costs, shard chance) are settled in
the spec with the sim.
