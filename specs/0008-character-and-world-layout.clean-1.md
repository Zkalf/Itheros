# Spec 0008: Character and world layout (clean edition 1)

Status: accepted
Clean edition of: [spec 0008](0008-character-and-world-layout.md) with its amendments 1-8 and amendment 7 erratum 1,
and the parts of other specs that change spec 0008 (see [Changes from other specs](#changes-from-other-specs))
Up to: 2026-11-11 (main 51b7d8b)
Issue: #59
Product owner: Zkalf

## How to read this edition
- This edition changes no rule, number or criterion. It says in one file what spec 0008 and its changes say today.
- The accepted files stay the record. If this edition and an accepted file differ, the accepted file wins, and an
  erratum fixes this edition.
- The section numbers (§1-§6), the decision numbers (1-12) and the criterion numbers (1-14) are those of spec 0008.
  Amendment 3 went on with that series (criteria 15-16). Code and tests that cite them stay right.
- A tag such as **(am. 5 change 6)** marks a text that came from an amendment.
- §6 keeps the criteria of each amendment under its own heading, with their own numbers.
- Spec 0008 is the base of many later specs. Where a later spec owns a rule now, this edition says so in one line
  and points to it. It does not copy that spec.
- [Where each change went](#where-each-change-went) lists every amendment and erratum and its place here.
- A new change to spec 0008 is a new amendment of spec 0008, as before. A later clean edition folds it in.

Intent: [intent/0008-character-and-world-layout.md](../intent/0008-character-and-world-layout.md) (accepted, commit
2beba9f)

Spec 0008 overrides:
- spec 0002 §4 (gear slots), §6 "Opens" column, §8 (the level ladder's unlocks), §9.1 item 2, §9.3 (hide from level
  10), criterion 8;
- spec 0003 decisions 1 and 4, criterion 1;
- spec 0005 amendment 2 (where brackets show);
- spec 0006 decisions 1-3, §2.1 (resting card), §2.2-2.4, criteria 1, 5, 9, 10, and amendments 1-3.

## Summary
- Spec 0008 is the base for intents 0009-0012.
- Four buttons at the bottom: Now, World, Professions and Character.
- A Character screen with the gear slots, a bag grid and item cards.
- No level gates except talents. Professions have levels since spec 0010, and the Graveyard King closes one road
  **(am. 5)**.
- No change to steps, XP, chances, drops or rewards. All numbers live in `data/*.json`.

## Changes from other specs
These specs change parts of spec 0008. This edition folds in the changes that replace a text of spec 0008, with a
tag such as **(spec 0016)**. The other rows only point to the spec that owns the rule.

| Spec | What it changes in spec 0008 | Folded in |
|---|---|---|
| Spec 0009 (fights with depth) | Decision 3 (two-handers exist); §2.2 (what stacks); §3.2 (a tap on a monster); §3.5 (the item card); §4; criteria 6 and 8 | §1, §2.2, §3.2, §3.5 |
| Spec 0010 (professions) | Amendments 1 and 2 (spots and recipes need a profession level, not a character level); §3.4 (the Professions screen) | §1, §3.4, criterion 4 |
| Spec 0011 (lake and hunt) | Decision 5 (fog): hidden areas | §1, §2.3 |
| Spec 0012 (your character) | §3.5: the name and the origin in the Character header | §3.5 |
| Spec 0014 (Quiet Teal) | §3.5's icons and corner count, and criterion 8's icons: things show pictures | §3.5, criterion 8 |
| Spec 0015 (talent trees) | §3.5: a third tab, Talents | §3.5 |
| Spec 0016 (queue rework) | Decision 7 (3 slots) and criterion 3: the queue holds 5 actions | §1, criterion 3 |
| Spec 0016 amendment 1 | §3.3: the button "Travel here" reads "Walk here" | §3.3 |
| Spec 0020 (item bank) and its amendments 2 and 4 | §3.5 the bag: kind chips, pictures, search and sort | §2.2, §3.5 (pointers) |
| Spec 0021 (bag limit) and its amendment 4 | §2.2 "No size limit": the bag has 40 spaces, and stacks have a size | §2.2 (pointer) |

## 1. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | What still opens by level? | **Nothing but talents** (owner's choice). Every area can be walked to from level 1, and every monster, gathering spot and recipe shows from the start. Monster colours and skulls, the deadly-fight warning, materials and profession levels (spec 0010) hold players back. The `unlockLevel` fields leave the data. One road waits for a boss: the Graveyard King opens the river **(am. 5)**. |
| 2 | Bear-pelt cloak | It moves to the new **Cloak** slot, so the player wears it with chest armour. Its stats are cut to cloak size (owner's choice), so total power stays as it was. The pacing tests decided the exact numbers. |
| 3 | Two-handed weapons | Spec 0008 built the rule with no two-handed item (owner's choice). Spec 0009 made one two-hander per tier from bone on, and they hit harder. |
| 4 | The slots of old saves | weapon → Main hand, shield → Off hand, body → Chest, head → Head, feet → Boots, amulet → Neck. Shoulder, Bracer, Gloves, Belt, Legs, Rings and Trinkets start empty. |
| 5 | When does fog lift? | An area is **explored** once the player has stood in it. An area shows in full if it is explored or joined by a route to an explored area. Every other area is fogged. A new player sees Camp and its neighbours. A hidden area (spec 0011 §6.2) does not show at all until it is revealed. |
| 6 | Travel to fog | The player cannot pick a fogged area as a destination, so automatic travel never crosses fog. A walk to its neighbour lifts it. |
| 7 | Stop conditions and slots | "Until I have N" and "until a quality" are level gates too, so they are offered from level 1. The queue holds 5 actions from level 1, the current action included **(spec 0016)**. Talents can add slots (spec 0015). |
| 8 | Ranks | Recruit, Adventurer (10), Veteran (20) and Champion (30) stay as titles with their ceremony lines. The Adventurer line no longer mentions the crossing of the river (data wording). |
| 9 | Next goal | Its **Hide** switch is there from level 1 (it was level 10). Its rules do not change. |
| 10 | Quality in brackets | Dropped where the item is drawn as an object: the bag grid, the Gear page, the item card's title. Kept wherever items are written as text (reports, journal, tally, Next goal, level-up cards), as spec 0005 amendment 2 says. |
| 11 | Two Rings, two Trinkets | One item kind each (`ring`, `trinket`) that fits either slot. **Equip** fills an empty one first. With both full, the card offers "Swap with <left>" and "Swap with <right>". |
| 12 | Settings | A gear button in the top bar, next to Journal and Trophies, opens a Settings page (Next goal switch, test walk; name and gender from spec 0012). |

## 2. Rules

### 2.1 Equipment
- The slots live in data (`economy.json` `gearSlots`, display order): Head, Neck, Shoulder, Cloak, Chest, Bracer,
  Gloves, Belt, Legs, Boots, Ring 1, Ring 2, Trinket 1, Trinket 2, Main hand, Off hand. No slot has a level.
- Each gear item names one slot kind in `items.json`. A main-hand weapon may be `twoHanded: true`.
- To equip a two-hander puts it in Main hand and moves the off-hand item to the bag.
- To equip an off-hand item while a two-hander is worn moves the two-hander to the bag.
- Swapped-out items always go to the bag. Nothing is lost.
- The stats of all worn items add up.

### 2.2 The bag
- One bag holds everything that the player owns and does not wear. Since spec 0020, the bank at Camp holds the rest.
- Items stack with a count when the item, the quality **and the bonus stats** match **(spec 0009 §5.3)**. Common
  gear still stacks freely.
- Spec 0008 gave the bag no size limit. Spec 0021 gave it 40 spaces and a step cost for each space over. Spec 0021
  amendment 4 gave each kind of item a stack size. Those specs own the rules of spaces.

### 2.3 Fog, exploring and the closed road
**Fog**
- The save keeps the set of explored areas. Arrival in an area adds it.
- Fog follows decision 5. An area is never fogged again.
- A hidden area is not drawn, not "???", not listed and on no route until it is revealed. Then the fog rules apply to
  it (spec 0011 §6.2).

**The closed road (am. 5 changes 1-9)**
- A route in `data/world.json` can name a boss in the field `opensOn`. Only one route has it: `old_graveyard` to
  `grey_moor`, with `"opensOn": "graveyard_king"` **(change 1)**.
- A road with `opensOn` is open when either of these is true **(change 2)**:
  - the player has killed its boss at least once (the counter `kills.graveyard_king`);
  - the player has explored both ends of the road.
- Otherwise the road is **closed**, in both directions **(change 3)**.
- The second case keeps old saves whole: a save that has stood in Grey Moor keeps the road, with or without a kill.
  The save gets no new field **(change 4)**.
- The kill counter never goes down, so a later loss never closes the road **(change 5)**.
- Travel and the routes treat a closed road as a road that does not exist **(change 6)**:
  - auto-travel and the walk before a queued action never plan a path across it;
  - the game refuses a walk to Grey Moor, or to any area that only the closed road reaches;
  - the game refuses an action that only happens beyond the river when the player adds it;
  - the queue skips a waiting action whose place lies beyond the road, with the reason `noRoute`.
- A refusal or a skip because of the closed road says: "Beat the Graveyard King to cross." Fog keeps its own words
  ("The way there is in the fog") **(change 7)**.
- A walk that is on the road when the game updates finishes that leg. The player arrives in Grey Moor, which then
  counts as explored **(change 8)**.
- Fog does not change. Grey Moor shows in full once Old Graveyard is explored: its monsters, its spots and its sheet.
  The areas beyond Grey Moor stay fogged until the player explores Grey Moor **(change 9)**.

**What stays open (am. 5 changes 16-19)**
- The south of the river stays open from level 1: Camp, Goblin Woods, Copper Hills, Old Graveyard, Mirror Lake and
  Smugglers' Cove.
- Any player can fight the King from level 1. The road opens on a win, never at a level.
- The King's stats, drops, first-kill drop and the King's Bane achievement do not change.
- The Ogre Chieftain and the Young Dragon stay optional (spec 0002 decision 8 still holds for them).

**The first kill (am. 5 changes 13-14)**
- The first kill of the Graveyard King adds one line to the report of that walk (the away summary and the news):
  "The King falls. The road to Grey Moor is open."
- The line shows only when the kill opens the road. A save that already had the road through the second case gets no
  line.

### 2.4 Old saves
On load of a save from before spec 0008 (a new save version):
- equipment moves by decision 4;
- the Bear-pelt cloak, worn or in the bag, keeps its place (worn → Cloak);
- the inventory becomes the bag;
- every area that the player has visited (spec 0004 counters) and the current area count as explored;
- level, XP, items, qualities and counters do not change.

Every fixture in `app/test/fixtures/saves/` loads.

## 3. Screens

### 3.1 Bottom bar and top bar
- The bottom bar has four buttons at all times: **Now · World · Professions · Character**. The app opens on Now.
- The top bar on every tab screen: **Journal**, **Trophies** (with its dot, spec 0006 amendment 2) and **Settings**.

### 3.2 Now: what am I doing, and what can I do here?
**The order from the top (am. 6 change 2)**
1. the step-sync problem (if any);
2. the place, the level and the bars (XP bar, step bank, walked today);
3. the test walk (if on);
4. Next goal;
5. the current action with the waiting actions (bars, fight log, tally, Stop);
6. the story of the place;
7. **Here**.

**The story card (am. 6 changes 1, 3)**
- On the first visit to a place, the card with the story of the place and its monsters stands under the card of the
  current action and the waiting actions, and above "Here".
- The card, its words and its OK button do not change. It shows only until the player taps OK.

**Here**
- In an area: its monsters (level badge, stats, drops "2 of 3 found") and its gathering spots. A tap starts or queues
  one.
- A tap on a monster opens one sheet: its bestiary card on top, the fight choices below **(spec 0009 decision 11)**.
- Where there is a forge (Camp, Grey Moor, Mountain Pass): a **Forge** row. It opens Crafting's screen (spec 0010
  amendment 4).

**Resting**
- While the player rests, the card reads "Your steps go to the step bank. Pick something to do below, or on the World
  map." with an **Open the World map** button (this replaced spec 0006 amendment 3).

### 3.3 World: where can I go?
- The Map of spec 0006 (positions, routes, river, area sheet), named World.
- The area sheet's button reads **"Walk here"** **(spec 0016 amendment 1)**.
- Fogged areas follow decision 5: "???" on the map and, on a tap, "Thick fog. Walk to a neighbouring area to see
  what's there." Paths to them are dashed.
- **The lock (am. 5 changes 10-12):**
  - While the road is closed, a small lock sits on the middle of the road on the World map. It is a flat SVG that
    Claude draws, in the Quiet Teal style (spec 0014). The road keeps its look under it.
  - The lock is not a button. Grey Moor's area sheet says why: it shows "Beat the Graveyard King to cross." in place
    of the walk button. (Amendment 5 calls it "Travel here"; spec 0016 amendment 1 renamed it "Walk here".)
  - When the road opens, the lock leaves the map.

### 3.4 Professions: what am I good at?
- Spec 0008 moved the Craft screen here unchanged, shown from level 1.
- Spec 0010 owns the Professions tab and the profession screens now: levels, tiers, tools, recipes and filters.

### 3.5 Character: who am I?
**The header**
- The name stands above the rank. The origin follows the rank: "Adventurer · Fisher from the coast" (spec 0012
  §4.4). Seven taps on the rank turn on the test walk.
- The level stands at the right of the name, not in the stats. A tap on it opens nothing **(am. 7 change 1)**.
- When the name and the level do not fit one line, at any text size, the level stands under the name. Nothing is cut
  off **(am. 7 erratum 1 correction 2)**.
- HP, Attack, Defense, Crit, Hit, Dodge and Block stand in one row, in this order, with smaller numbers. Each has its
  label under it. A tap opens its sheet (spec 0009 amendment 4) **(am. 7 change 2)**.
- At a large text size the row wraps to two rows **(am. 7 erratum 1 correction 2)**.
- Each stat is at least 44 dp wide, so a thumb can hit it **(am. 7 change 6)**.
- The portrait is 48 dp **(am. 7 change 3)**.
- The meal line under a stat reads "+19 meal", without brackets, in the small type of the labels
  **(am. 7 change 4)**.
- The line "N talent points to spend" stays **(am. 7 change 7)**.

**The tabs**
- **Gear**, **Bag** and **Talents** (spec 0015) stand under the header.

**Gear (am. 8)**
- The Gear page shows no figure **(change 1)**.
- The 16 slots stand in a grid of four rows and four columns, centred **(change 2)**:

  | | | | |
  |---|---|---|---|
  | Shoulder | Head | Neck | Cloak |
  | Main hand | Chest | Gloves | Off hand |
  | Ring 1 | Belt | Bracer | Ring 2 |
  | Trinket 1 | Legs | Boots | Trinket 2 |

  - Head, Chest, Belt and Legs stand in the second column.
  - The pairs (Shoulder and Cloak, the two hands, the two rings, the two trinkets) stand in the outer columns.
- The squares are a quarter of the width, at most 72 dp and at least 48 dp **(change 3)**.
- A slot that the data adds later stands in a row under the grid **(change 4)**.
- An empty slot is a faint outline with its slot icon.
- A worn item shows its picture with a ring in its quality colour (spec 0014 §2.3).
- A two-hander shows in Main hand and greys out Off hand with a link icon.

**A tap on a slot (am. 3 changes 2-3, am. 4)**
- A tap on a **filled** slot opens the item card of the item worn there **(am. 4 change 1)**.
- A tap on an **empty** slot opens its **slot sheet**. This includes the greyed Off hand under a two-hander
  **(am. 4 change 3)**.
- The slot sheet holds **(am. 3 change 2)**:
  - its name and kind ("Head", "Ring 1 · rings fit here");
  - what is worn there, if anything, with its stats and **Unequip**;
  - **From your bag**: every bag item that fits this slot, best first, each with its stat change against what is worn
    there and **Equip** (empty slot) or **Swap**. A tap on an item's name opens its item card;
  - with nothing in the bag that fits: "Nothing in your bag fits here yet."
- To equip from the slot sheet puts the item in **that** slot, so a ring tapped from Ring 2 goes to Ring 2. The
  two-hand rules of §2.1 apply **(am. 3 change 3)**.
- A tap on the worn row in the slot sheet opens the item card of the worn item **(am. 4 change 4)**.

**Bag**
- A grid, 5 squares to a row on the phone. In the bag's own order, gear comes first (by slot order, then best first),
  then materials.
- Each square shows the item's picture (spec 0014 §3.1). Gear and tools have a ring in their quality colour.
  Materials and meals have no ring.
- Stacks show a count badge. Text under or over the squares is limited to the count.
- Spec 0020 amendment 2 adds the kind chips and the pictures in rows. Spec 0020 amendment 4 adds the search and the
  sort. Spec 0021 adds the spaces.

**Item card** (a tap on a square in the bag, or on a filled slot)
- The name in its quality colour.
- The quality and the kind in words: "Rare one-hand weapon · Main hand", "Material".
- Its stats. Spec 0009 §8.2 adds the damage type and the hands, or the armour type, and the bonus stats.
- For gear in the bag: the change against what is worn there ("+2 Attack", "−10 HP", or "Slot is empty").
- The buttons:
  - **Equip** (an empty slot) or **Swap** (a taken slot), for a bag item. A bag item shows no **Change**
    **(am. 4 change 4)**;
  - **Unequip** and **Change**, for a worn item **(am. 4 change 2)**. Change closes the item card and opens the slot
    sheet of that slot. Unequip moves the item to the bag.
- For a two-hander, the card says "Uses both hands: your shield goes to the bag."
- Materials show where they come from ("Drops from: Skeleton") and what uses them ("Used in: Bone sword").
- Later specs add buttons to the card, such as Salvage and Reroll (spec 0010), Eat (spec 0011), Store and Take (spec
  0020) and Destroy (spec 0021 amendment 2).

## 4. Out of scope
These were out of the scope of spec 0008, and later specs built them:
- professions, NPCs, tools and cooking (specs 0010, 0011);
- hit and miss, bonus stats, armour types, two-hander damage and the bestiary (spec 0009);
- character creation (spec 0012);
- talents (spec 0015);
- a bag cap (spec 0021) and salvage (spec 0010).

Still out of scope: loadouts, quests, the sale of gear, and new content in spec 0008 itself.

## 5. Concerns
1. **Open world for a new player (intended).** A level 1 player can walk into the Old Graveyard (zombies red, the
   King orange). Spec 0008 also let fog lift across the river. Since amendment 5, the King closes the road across the
   river. The owner wants this: "let people explore and fail". The colours, the deadly warning and spec 0003's cheap
   losses keep failure cheap. The pacing simulator already picks the best yellow monster, so its numbers should not
   move. If they do, the plan says so before tuning.
2. **Recipes from level 1 (low).** Materials are the gate now. A long Professions list at level 1 could feel busy.
   Spec 0010 amendment 12 later put the recipes that the player can make first.
3. **Level-up cards get shorter.** Levels 2-9 no longer name new areas or recipes. They show stats plus "now your
   level / now grey" news. Levels with nothing else say "Stronger: +10 HP, +1 Attack, +1 Defense."

## 6. Acceptance criteria
The base criteria keep their numbers. A criterion that checks several things has a letter for each check (rule 13
of `WRITING.md`). A note says where a later change moved a check.

**Screens and actions**
1. Bars:
   - 1a. The bottom bar has exactly Now, World, Professions and Character at every level.
   - 1b. The app opens on Now.
   - 1c. The top bar has Journal, Trophies (with its dot) and Settings on every screen.
2. Every action that the old screens offered (fight, gather, craft, travel, stop, remove from queue, equip, settings)
   can still be done from the new screens.
3. At level 1:
   - 3a. All 16 slots can be filled.
   - 3b. The queue takes its full count of actions. Spec 0008 said 3; spec 0016 made it 5.
   - 3c. "Until I have N" and "until a quality" are offered.
4. At level 1:
   - 4a. Every monster, gathering spot and recipe in data shows wherever its area is not fogged.
   - 4b. No `unlockLevel` is left in `data/*.json`.
   - 4c. No rule checks the character level before an action. Spots and recipes check their profession level (spec
     0010 criterion 1, which replaced amendment 2's criterion 4).
   - 4d. The only other gate is the closed road (am. 5).
5. Fog:
   - 5a. A new save shows Camp and the areas joined to it in full, and every other area as "???".
   - 5b. Arrival in an area shows its neighbours in full.
   - 5c. The player cannot pick a fogged area for travel.
   - 5d. Auto-travel never routes through a fogged area.
6. Two-handers:
   - 6a. To equip a two-hander moves the off-hand item to the bag.
   - 6b. To equip an off-hand item moves the two-hander to the bag.
   - 6c. No item is lost in any equip, swap or unequip.
7. Rings and trinkets:
   - 7a. A ring or trinket fills an empty slot first.
   - 7b. With both full, the card offers a swap with each.
8. The bag:
   - 8a. Items stack in the bag with a count, when item, quality and bonus stats match (spec 0009 criterion 9).
   - 8b. Gear and materials look different: gear has its picture and a quality-colour ring; materials have no ring
     (spec 0014 criterion 17).
9. The item card:
   - 9a. It shows the name in colour.
   - 9b. It shows the quality and the kind in words.
   - 9c. It shows the stats.
   - 9d. It shows the comparison with the worn item.
   - 9e. It shows the right buttons (Equip / Swap for a bag item; Unequip / Change for a worn item, am. 4).
10. Brackets:
    - 10a. No name in the bag, the Gear page or the card title carries a quality bracket.
    - 10b. Reports, the journal, the tally and Next goal still do.
11. The Bear-pelt cloak sits in the Cloak slot, alongside chest armour.
12. Each fixture save loads:
    - 12a. gear in its decision 4 slot;
    - 12b. the inventory in the bag;
    - 12c. visited areas explored;
    - 12d. level, XP and items unchanged.
13. Pacing:
    - 13a. The pacing tests stay green, with no change to steps, XP, chances or drops other than the cloak's stats.
    - 13b. The pacing simulator may walk anywhere that it can see, and its targets still hold (am. 2, which replaced
      amendment 1's criterion 13).
14. `.\scripts\check.ps1 -Release` is green, with no INTERNET permission.

**Amendment 1** and **amendment 2** criteria 4 and 13 are replaced: criterion 4 by spec 0010 criterion 1 (see 4c),
criterion 13 by amendment 2's own (see 13b).

**Amendment 3**
15. Replaced by amendment 8 criterion 2. The Gear page has no bottom row of hands.
16. A tap on a slot opens its sheet, with the worn item (if any) with Unequip, and every bag item that fits that slot
    with its stat change and Equip or Swap, which equips into that slot; "Nothing in your bag fits here yet." when
    none does. Since amendment 4, a tap on a filled slot opens the item card instead (amendment 4 criterion 1).

**Amendment 4**
- Gear page:
  1. A tap on a filled slot opens the item card of the item worn in that slot.
  2. A tap on an empty slot opens the slot sheet of that slot.
  3. With a two-hander worn, a tap on the greyed Off hand opens the Off hand slot sheet.
- Item card:
  4. The item card of a worn item shows a Change button and an Unequip button.
  5. Change closes the item card and opens the slot sheet of the slot that holds the item.
  6. Unequip on the item card of a worn item moves the item to the bag.
  7. The item card of a bag item shows no Change button.
- Check and release:
  8. Rules, numbers and the save do not change. The pacing test passes.
  9. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

**Amendment 5**
- The road:
  1. `data/world.json` has `"opensOn": "graveyard_king"` on the route from `old_graveyard` to `grey_moor`, and on no
     other route.
  2. A new save has the road closed.
  3. A save with one kill of the Graveyard King has the road open.
  4. A save that has explored both Old Graveyard and Grey Moor, with no King kill, has the road open.
  5. A save with the road open keeps it open after a loss to the King.
- Travel and the queue:
  6. With the road closed, the walking distances from Camp reach no area beyond the river.
  7. With the road closed, Travel to Grey Moor throws an error that says "Beat the Graveyard King to cross."
  8. With the road closed, adding a fight with a Wolf (Grey Moor) from Camp throws the same error.
  9. With the road closed, a waiting action whose place lies beyond the river is skipped with `noRoute`.
  10. With the road open, Travel from Camp to Grey Moor walks through Old Graveyard.
  11. A walk that is on the closed road's leg finishes it and arrives in Grey Moor.
- Fog:
  12. With Old Graveyard explored and the road closed, Grey Moor is not fogged.
  13. With the road closed, Iron Ridge and Troll Bridge are fogged for a player who has not explored Grey Moor.
- The World map:
  14. With the road closed, the World map shows the lock on the road between Old Graveyard and Grey Moor.
  15. With the road open, the World map shows no lock.
  16. With the road closed, Grey Moor's area sheet shows "Beat the Graveyard King to cross." and no walk button.
  17. With the road open, Grey Moor's area sheet shows the walk button ("Walk here", spec 0016 amendment 1).
  18. The lock and the sheet fit at 408 dp wide and at text size 2.0. The PR says so, with a render.
- The first kill:
  19. The walk with the first King kill reports "The King falls. The road to Grey Moor is open."
  20. A second King kill reports no such line.
  21. A save whose road is open through criterion 4 reports no such line on its first King kill.
- The camp tour:
  22. Card 2 of the camp tour shows the words of change 15 (spec 0022 owns the tour).
- Save:
  23. The save schema does not change.
  24. Each save fixture in `app/test/fixtures/saves/` loads. A fixture that has explored Grey Moor has the road open.
- The sim and the pace:
  25. The walker beats the King before it crosses the river, on every seed of the pacing test.
  26. Plan milestone 1 reports the median day of level 30 (16 seeds) before and after, and the owner sees it before
      milestone 2.
  27. The pacing test passes, or the owner has accepted new ranges for it.
- Check and release:
  28. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

Amendment 5 also changed spec 0002 decision 8 (bosses never a gate) for the King, and spec 0022 card 2:
"This is the map. Tap a place to travel there, or to see what lives there. Beat the Graveyard King to cross the
river." (change 15). Its walker habit and pace rules (changes 20-23) are in plan 0055 and the pacing test: from level
10, while the road is closed, the walker fights the King before it picks anything else. After a loss it waits for its
next level. Change 22 says why the numbers came in the plan, not in the amendment: the sim needed the new rule and
the walker's habit.

**Amendment 6**
1. On the first visit to a place with a story, the story card stands under the card of the current action.
2. The story card stands above "Here".
3. With no current action, the story card stands under "Resting".
4. A tap on OK still takes the story card away.
- Check and release:
  5. Rules, numbers and the save do not change. The pacing test passes.
  6. Now with a story card and a fight is rendered at 408 dp wide before the PR (`CLAUDE.md`).
  7. `releases/next/` has a line for players.
  8. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

**Amendment 7** (with erratum 1)
- The block:
  1. The level stands on the line of the character's name, and the stats row has no Level. This holds for a name
     that fits the line with the level (erratum 1 correction 3).
  2. At the usual text size on a 408 dp phone the seven stats stand in one row, in the order of change 2.
  3. A tap on each of the seven stats opens its sheet. A tap on the level opens nothing.
  4. With a meal that adds HP, the line under HP reads "+N meal".
  5. The portrait is 48 dp.
  6. At the usual text size on a 408 dp phone the block is shorter than before: the three tabs start in the top third
     of the screen (above 295 dp of 884). It is measured with a name that fits the line with the level (erratum 1
     correction 3).
  7. At text size 2.0 on a 408 dp phone the block does not overflow.
  8. Each stat is at least 44 dp wide.
- Check and release:
  9. Rules, numbers and the save do not change. The pacing test passes.
  10. Character is rendered at 408 dp wide, at the usual text size and at 2.0, before the PR (`CLAUDE.md`).
  11. `releases/next/` has a line for players.
  12. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

Erratum 1 also says that amendment 7 amends spec 0014 §2.3 and criterion 8, and spec 0011 §8.3 (the meal example
reads "+2 meal" under Attack). The clean edition of spec 0014 folds that in.

**Amendment 8**
1. The Gear page shows no figure.
2. The 16 slots stand in four rows of four, in the places of change 2.
3. On a 408 dp phone at the usual text size, all 16 slots are on the screen below the tabs without a scroll.
4. A tap on an empty slot opens its sheet; a tap on a filled slot opens the card of its item.
5. Under a two-hander the Off hand is greyed.
- Check and release:
  6. Rules, numbers and the save do not change. The pacing test passes.
  7. The Gear page is rendered at 408 dp wide before the PR (`CLAUDE.md`).
  8. `releases/next/` has a line for players.
  9. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

## Where each change went

| File | Its changes | Place in this edition |
|---|---|---|
| [Amendment 1](0008-character-and-world-layout.amendment-1.md) | 1 spots need a character level; 2 areas stay open; 3 `level` replaces `unlockLevel` | Replaced by spec 0010; decision 1; criterion 4 |
| [Amendment 2](0008-character-and-world-layout.amendment-2.md) | 1 recipes need a character level; 2 recipe news; 3 areas stay open; 4 XP table | Replaced by spec 0010; decision 1; criteria 4 and 13 |
| [Amendment 3](0008-character-and-world-layout.amendment-3.md) | 1 hands in the bottom row (replaced by amendment 8); 2 the slot sheet; 3 equip into that slot | §3.5 "A tap on a slot"; criteria 15-16 |
| [Amendment 4](0008-character-and-world-layout.amendment-4.md) | 1 a filled slot opens the card; 2 Change; 3 an empty slot opens the sheet; 4 what stays | §3.5; criterion 9e; §6 |
| [Amendment 5](0008-character-and-world-layout.amendment-5.md) | 1-8 the closed road; 9 fog; 10-12 the lock; 13-14 the first kill; 15 the camp tour; 16-19 what stays; 20-23 the walker and the pace | decision 1; §2.3; §3.3; criterion 4d; §6 |
| [Amendment 6](0008-character-and-world-layout.amendment-6.md) | 1-3 the story card under the current action | §3.2; §6 |
| [Amendment 7](0008-character-and-world-layout.amendment-7.md) | 1-6 a shorter stats block; 7-8 what stays | §3.5 "The header"; §6 |
| [Amendment 7, erratum 1](0008-character-and-world-layout.amendment-7.erratum.md) | 1 other texts it changes; 2 a long name; 3 criteria 1 and 6; 4 a test at 320 dp | §3.5 "The header"; §6 |
| [Amendment 8](0008-character-and-world-layout.amendment-8.md) | 1-4 the Gear grid; 5-6 what stays | §3.5 "Gear"; §6 |
