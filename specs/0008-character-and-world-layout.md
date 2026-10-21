# Spec 0008: Character and world layout

Status: accepted
Intent: [intent/0008-character-and-world-layout.md](../intent/0008-character-and-world-layout.md) (accepted, commit 2beba9f)
Overrides: spec 0002 §4 (gear slots), §6 "Opens" column, §8 (the level ladder's unlocks), §9.1 item 2, §9.3 (hide
from level 10), criterion 8; spec 0003 decisions 1 and 4, criterion 1; spec 0005 amendment 2 (where brackets show);
spec 0006 decisions 1–3, §2.1 (resting card), §2.2–2.4, criteria 1, 5, 9, 10, and amendments 1–3
Product owner: Zkalf
Date: 2026-10-21

The base for intents 0009–0012: four bottom buttons, a paper-doll Character screen with a bag grid and item cards,
and no level gates except talents. No change to steps, XP, chances, drops or rewards. All numbers live in
`data/*.json`.

## 1. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | What still opens by level? | **Nothing but talents** (owner's choice). Every area can be walked to from level 1, and every monster, gathering spot and recipe shows from the start. Monster colours and skulls, the deadly-fight warning, materials and (from 0010) profession levels hold players back. The `unlockLevel` fields leave the data. |
| 2 | Bear-pelt cloak | Moves to the new **Cloak** slot, so it is worn with chest armour. Its stats are cut to cloak size (owner's choice) so total power stays as today; the pacing tests decide the exact numbers. |
| 3 | Two-handed weapons | The rule is built now; **no item is two-handed yet** (owner's choice). Spec 0009 makes two-handers hit harder and turns the Troll-bone maul into one. |
| 4 | Today's slots on the doll | weapon → Main hand, shield → Off hand, body → Chest, head → Head, feet → Boots, amulet → Neck. Shoulder, Bracer, Gloves, Belt, Legs, Rings and Trinkets start empty. |
| 5 | When does fog lift? | An area is **explored** once the player has stood in it. An area shows in full if it is explored or joined by a route to an explored area; every other area is fogged. A new player sees Camp and its neighbours. |
| 6 | Travel to fog | A fogged area can't be picked as a destination, so automatic travel never crosses fog. Walking to its neighbour lifts it. |
| 7 | Stop conditions | "Until I have N" and "until a quality" are level gates too: they are offered from level 1. Three queue slots from level 1. |
| 8 | Ranks | Recruit, Adventurer (10), Veteran (20), Champion (30) stay as titles with their ceremony lines. The Adventurer line no longer mentions crossing the river (data wording). |
| 9 | Next goal | Its **Hide** switch is there from level 1 (was level 10). Rules unchanged. |
| 10 | Quality in brackets | Dropped where the item is drawn as an object: the bag grid, the doll, the item card's title. Kept wherever items are written as text (reports, journal, tally, Next goal, level-up cards), as spec 0005 amendment 2 says. |
| 11 | Two Rings, two Trinkets | One item kind each (`ring`, `trinket`) that fits either slot. **Equip** fills an empty one first; with both full, the card offers "Swap with <left>" and "Swap with <right>". |
| 12 | Settings | A gear button in the top bar, next to Journal and Trophies, opens a Settings page (Next goal switch, test walk; name and gender from 0012). |

## 2. Rules

### 2.1 Equipment
- Slots, in data (`economy.json` `gearSlots`, display order): Head, Neck, Shoulder, Cloak, Chest, Bracer, Gloves,
  Belt, Legs, Boots, Ring 1, Ring 2, Trinket 1, Trinket 2, Main hand, Off hand. None has a level.
- Each gear item names one slot kind in `items.json`. A main-hand weapon may be `twoHanded: true`.
- Equipping a two-hander puts it in Main hand and moves the off-hand item to the bag. Equipping an off-hand item
  while a two-hander is worn moves the two-hander to the bag. Swapped-out items always go to the bag; nothing is
  lost.
- Stats from all worn items add up as today.

### 2.2 The bag
- One bag holds everything the player owns and doesn't wear. No size limit.
- Identical items (same item, same quality) stack with a count.

### 2.3 Fog and exploring
- The save keeps the set of explored areas. Arriving in an area adds it.
- Fog is decision 5; an area is never fogged again.

### 2.4 Old saves
On load (new save version): equipment moves by decision 4; the Bear-pelt cloak, worn or in the bag, keeps its
place (worn → Cloak); the inventory becomes the bag; every area the player has visited (spec 0004 counters) and the
current area count as explored. Level, XP, items, qualities and counters are unchanged. Every fixture in
`app/test/fixtures/saves/` loads.

## 3. Screens

### 3.1 Bottom bar and top bar
- Bottom bar, always four buttons: **Now · World · Professions · Character**. The app opens on Now.
- Top bar on every screen: **Journal**, **Trophies** (with its dot, spec 0006 amendment 2) and **Settings**.

### 3.2 Now: what am I doing, and what can I do here?
Top to bottom: step-sync problem (if any); location, level, XP bar, step bank, walked today; test walk (if on);
Next goal; discoveries; the running action (bars, fight log, tally, Stop, as today); the queue; then **Here**:
- in an area: its monsters (level badge, stats, drops "2 of 3 found") and gathering spots, tappable to start or
  queue, as on today's map sheet;
- where there is a forge (Camp, Grey Moor, Mountain Pass): a **Forge** row that opens Professions.

While resting, the card reads "Your steps go to the step bank. Pick something to do below, or on the World map."
with an **Open the World map** button (replaces spec 0006 amendment 3).

### 3.3 World: where can I go?
Today's Map (positions, routes, river, area sheet, Travel here), renamed World. Fogged areas follow decision 5:
"???" on the map and, on tap, "Thick fog. Walk to a neighbouring area to see what's there." Paths to them are dashed.

### 3.4 Professions: what am I good at?
Today's Craft screen moved here unchanged (where the forge is, every recipe, owned/needed inputs, stop choices).
Shown from level 1. Professions with levels, tiers and tools arrive with spec 0010.

### 3.5 Character: who am I?
Tabs **Gear** and **Bag** (Talents comes with its spec). The level, stats (HP, Attack, Defense) and rank sit above
the tabs.
- **Gear:** the paper doll. A simple figure outline (no drawn art) with slots around it, as icons in squares:
  left column Head, Neck, Shoulder, Cloak, Chest, Bracer; right column Gloves, Belt, Legs, Boots, Ring 1, Ring 2;
  bottom row Trinket 1, Trinket 2, Main hand, Off hand. An empty slot is a faint outline with its slot icon. A worn
  item shows its icon with a border in its quality colour. A two-hander shows in Main hand and greys out Off hand
  with a link icon.
- **Bag:** a grid, 5 squares to a row on the phone, gear first (by slot order, then best first), then materials.
  Gear uses its slot's icon with a quality-colour border; materials use one material icon with no border. Stacks
  show a count in the corner. Text under or over the squares is limited to the count.
- **Item card** (tap any square, in the bag or on the doll): the name in its quality colour; the quality and kind in
  words ("Rare one-hand weapon · Main hand", "Material"); its stats; for gear in the bag, the change against what is
  worn there ("+2 Attack", "−10 HP", or "Slot is empty"); buttons **Equip** (empty slot), **Swap** (slot taken),
  **Unequip** (on the doll). For a two-hander the card says "Uses both hands: your shield goes to the bag."
  Materials show where they come from ("Drops from: Skeleton") and what uses them ("Used in: Bone sword").

## 4. Out of scope
Professions, NPCs, tools, cooking (0010, 0011); hit/miss, affixes, armour types, two-hander damage, bestiary (0009);
character creation (0012); talents; bag cap, loadouts, quests, selling or salvage; new content.

## 5. Concerns
1. **Open world for a new player (intended).** A level 1 player can walk into the Old Graveyard (zombies red, the King
   orange) and, as fog lifts, across the river. The owner wants this: "let people explore and fail". The colours,
   the deadly warning and spec 0003's cheap losses keep failing cheap. The pacing simulator already picks the best yellow monster, so its numbers shouldn't move; if they do, the
   plan says so before tuning.
2. **Recipes from level 1 (low).** Materials are the gate now. A long Professions list at level 1 could feel busy;
   the list keeps today's order (lowest tier first) so the first rows are the ones the player can make.
3. **Level-up cards get shorter.** Levels 2–9 no longer name new areas or recipes; they show stats plus "now your
   level / now grey" news. Levels with nothing else say "Stronger: +10 HP, +1 Attack, +1 Defense."

## 6. Acceptance criteria
1. The bottom bar has exactly Now, World, Professions and Character at every level; the app opens on Now; the top
   bar has Journal, Trophies (with its dot) and Settings on every screen.
2. Every action the old screens offered (fight, gather, craft, travel, stop, remove from queue, equip, settings) can
   still be done from the new screens.
3. At level 1, all 16 slots can be filled, the queue takes 3 actions, and "until I have N" and "until a quality" are
   offered.
4. At level 1, every monster, gathering spot and recipe in data is shown wherever its area is not fogged; no
   `unlockLevel` is left in `data/*.json` and no rule reads one.
5. A new save shows Camp and the areas joined to it in full and every other area as "???"; arriving in an area
   shows its neighbours in full; a fogged area can't be picked for travel and auto-travel never routes through one.
6. Equipping a two-hander (test data) moves the off-hand item to the bag, and equipping an off-hand item moves the
   two-hander to the bag; no item is lost in any equip, swap or unequip.
7. A ring or trinket fills an empty slot first; with both full the card offers a swap with each.
8. Identical items stack in the bag with a count; gear and materials use different icons; gear has a quality-colour
   border.
9. The item card shows the name in colour, quality and kind in words, stats, the comparison with the worn item and
   the right button (Equip / Swap / Unequip).
10. No name in the bag, doll or card title carries a quality bracket; reports, the journal, the tally and Next goal
    still do.
11. The Bear-pelt cloak sits in the Cloak slot, alongside chest armour.
12. Each fixture save loads: gear in its decision 4 slot, the inventory in the bag, visited areas explored, level, XP
    and items unchanged.
13. Pacing tests stay green with no change to steps, XP, chances or drops other than the cloak's stats.
14. `.\scripts\check.ps1 -Release` is green, with no INTERNET permission.
