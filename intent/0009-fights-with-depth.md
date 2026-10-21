# Intent: Fights with depth

Status: accepted
Product owner: Zkalf
Date: 2026-10-21

## Problem
Fights are flat: attack, defence and health, and every hit lands. Gear differs only in its numbers, and nothing
rewards knowing the monster you face. Owner: "fighting and weapons should have way more stats and mechanics", "we
need hit and miss at least", and players should be "rewarded learning about a foe and changing gear to optimise
against it". The loot chase (Diablo 2) gets better when a lucky roll gives a stat you can't get any other way.

## Proposed outcome
1. **Hit and miss.** Every swing can miss, both the player's and the monster's. Against a foe of the same level
   about 85% of swings hit; the chance moves with the level difference. **Dodge** lowers the chance of being hit.
   The fight log on Now shows misses, dodges, crits and blocks ("You miss", "Skeleton dodges", "Critical hit for 14").
2. **Bonus stats from quality (affixes).** Common gear has its base stats only. Each quality step above Common adds
   one random bonus stat: Uncommon 1, Rare 2, Epic 3, Legendary 4. Bonus stats: **Crit** (chance of a double-damage
   hit), **Hit**, **Dodge**, **Block** (shields only: a blocked hit does much less damage) and **Health**. They are
   rolled once, when an item is crafted or dropped, and shown on the item's detail card. They open by material tier
   (for example Crit and Health from the first tier, Dodge and Block from the second), so early fights stay easy to
   read. Quality keeps raising base stats as today.
3. **Armour and damage types.** Every monster wears **light**, **medium** or **heavy** armour, and every weapon deals
   **slash**, **pierce** or **crush** damage. Slash beats light, pierce beats medium, crush beats heavy. The right
   type deals about 30% more damage, the wrong one about 20% less. The wrong weapon still works; the right one is a
   clear reward for paying attention. The player's own armour types shape their stats (light leans to Dodge, heavy
   to defence) but don't change how monster attacks land. This one-way rule is a starting point the owner may revisit
   after playtests.
4. **One hand and shield, or two hands.** A shield brings Block; a two-handed weapon instead hits clearly harder than
   a one-handed weapon of the same tier and quality, so both builds are worth choosing.
5. **Learning foes (bestiary).** The Journal gets tabs: **Log** (today's journal), **Bestiary** and **Lore**. Each
   monster's bestiary card fills in as the player learns about it, in either of two ways:
   - **By fighting it:** the first fight shows its armour type, 10 kills show its weakness and its stats, and 50 kills
     earn a **Slayer** mark (a small bonus against it, about +5% hit).
   - **By lore:** rare lore notes dropped by monsters (kept in the Lore tab), and from intent 0010 tips from the camp
     NPCs, can reveal a monster's armour type and weakness early.
   - Drop chances stay hidden, as on the map.
   Tapping a monster in Now or World opens its bestiary card.

## Affected users and systems
All players. Game rules for combat (hit, miss, dodge, crit, block, damage types), item generation (bonus stats),
monsters and weapons (`data/*.json`: armour type, damage type, bonus stat tiers), the bestiary and lore notes, the
save (bonus stats on items, kills per monster, lore found), and the Now, World and Journal screens.

## Constraints
- **Balance for ~5,000 steps a day.** Misses slow fights and bonus stats speed them up. Monsters are retuned so the
  level pace from spec 0002 holds (about L10 in 2 weeks, L30 in 3 months); the pacing tests stay green and the sim
  shows the numbers before acceptance of the spec.
- Losing fights works as today (spec 0003). A fight still resolves from steps alone; no taps during a fight.
- Existing saves load. Gear the player already owns gets its bonus stats rolled once when the update loads, so
  earlier lucky drops gain them too. Past kills count towards the bestiary.
- Clean UI (intent 0008): bonus stats and types appear on the detail card and the bestiary card, not as clutter on
  every list row.
- Out of scope: weapon loadouts / automatic swaps between queued fights (later), dust and rerolls (intent 0010),
  NPC tips themselves (0010), new monsters or areas beyond giving the existing ones types.

## Open questions
None blocking. Exact numbers (hit chance per level, crit size, which tier opens which bonus stat) are settled in the
spec with the sim.
