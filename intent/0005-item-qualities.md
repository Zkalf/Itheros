# Intent: Item qualities

Status: accepted
Product owner: Zkalf
Date: 2026-10-19

## Problem
Gear is fixed: a Bone sword is always +5 Attack. Once a player has crafted the best item for their stretch there is
nothing left to chase, and grey monsters' loot (spec 0002 decision 6) has little use. The owner enjoys Diablo 2-style
low-chance loot and a long grind, and wants that chase here.

## Proposed outcome
Every piece of gear has a quality, shown by its colour:

| Quality | Colour | Stats vs common | Chance |
|---|---|---|---|
| Common | white | — | 70% |
| Uncommon | green | +20% | 20% |
| Rare | blue | +40% | 7% |
| Epic | purple | +70% | 2.5% |
| Legendary | orange | +100% (double) | 0.5% (1 in 200) |

- **Crafting rolls a quality** for each item made. The same recipe can be crafted again in the hope of a better one.
- **Being above the recipe's level helps very slightly** (owner: "very minor"): each level above makes the better
  qualities about 2% more likely (so 0.5% becomes 0.51%), up to about 20% more at 10 levels above (0.6%).
- **Dropped gear rolls too** (owner's choice): the Old Bear's Bear-pelt cloak and the bosses' unique items. To make
  bosses worth farming, a boss's unique item can drop again after the first kill, with a small chance (starting
  value 5% per kill), rolling its quality each time.
- Stats round to whole numbers, and each quality above common adds at least +1 to every stat the item has, so every
  step up shows.
- The item's name and colour show the quality everywhere: inventory, equipment, the report, the journal.
  Identical items of the same quality stack; different qualities are separate rows.

**What this means for an average walker** (pacing simulator, 5,000 steps a day, crafting only what they wear,
about 22 crafts by day 90): about 9 in 10 players see at least one rare by day 90, about half see an epic, and about
1 in 10 sees a legendary from crafting alone. Players who grind (craft more, farm bosses) see more.

## Affected users and systems
All players. Game rules (crafting, drops, gear stats), item data, the save (items now carry a quality), the
Character tab, the report and journal lines.

## Constraints
- All numbers (stat bonuses, chances, the over-level nudge, the boss repeat chance) live in data.
- The dice stay in the save's seeded generator, so results stay deterministic and testable.
- Pacing tests stay green: the level targets of spec 0002 must hold with qualities on. Lucky gear may make bosses
  easier; that's accepted (owner's choice of strong qualities).
- Existing items in saves become common.
- Out of scope: salvaging or selling spare gear, quality on materials, sets or affixes.

## Open questions
None blocking. Starting values above are tuned with the simulator and on the phone.
