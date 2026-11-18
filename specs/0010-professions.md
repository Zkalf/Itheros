# Spec 0010: Professions

Status: accepted
Intent: [intent/0010-professions.md](../intent/0010-professions.md) (accepted, commit 9e8208a)
Builds on:
- spec 0002 and its amendment 1 (XP, fade, pacing);
- spec 0005 and its amendments (qualities, uniques);
- spec 0008 and its amendments 1-3 (the Professions screen, the Here list, the item card);
- spec 0009 and its amendment 1 (bonus stats, tiers, lore, the 8-seed pacing).
Overrides:
- spec 0008 amendment 1 (gathering spots need a character level) and its criterion 4;
- spec 0008 amendment 2 (recipes need a character level) and its criterion 13;
- spec 0008 §3.4 (Professions = the Craft screen of that time);
- spec 0002 §3 for gathering and crafting (their character XP);
- spec 0005 §3's overlevel bonus for crafts: the bonus counts against the Crafting level, not the character level.
Product owner: Zkalf
Date: 2026-10-21

## Summary
- Mining, Woodcutting and Crafting each have a level of their own. Spec 0011 adds Fishing, Hunting and Cooking with
  the same rules.
- Gathering spots and recipes need a profession level, not a character level.
- Profession steps still level the character, at a quarter of the pace of a fight.
- Each profession has one tool.
- Each gathering spot has a rare find. Rare finds make rings and trinkets.
- Teachers at Camp teach the professions and give starter tools.
- At a forge:
  - spare gear salvages into dust;
  - dust rerolls the quality of gear;
  - a salvage can give a boss shard.
- All numbers are starting values in `data/*.json`. The pacing simulator tunes them.

## 1. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | Character XP from a profession step | **A quarter of a fair fight, with fade** (owner's choice). Each step that the player spends on gathering or crafting gives 25% of the XP per step that an even-level fight pays at the character's level. The profession fade (§2.3) multiplies it. Recipes and spots pay no character XP of their own. |
| 2 | Rare finds | **Gems make rings, heartwood makes trinkets** (owner's choice). Each vein has a gem, and each tree has a heartwood. They are the only inputs that make rings and trinkets (§5). |
| 3 | What logs go into | **Hafts, shields and tools** (owner's choice). Spears, maces, two-handers and the wooden-backed shields need logs of their tier. Every tool needs logs. Swords, armour and jewellery do not. |
| 4 | Tool strength | **Tier matters, quality adds a little** (owner's choice). The steps of an action cost: old tool 100%, copper 90%, iron 80%, mithril 70%. Each quality step above Common takes 2 more points off. The rare-find chance grows by 5% of itself per quality step. |
| 5 | Reroll cost | **3 dust of the item's quality** (owner's choice), plus a short forge action. Common gear salvages into Common dust. |
| 6 | Boss shards | **The boss of the item's tier, 2%** (owner's choice), plus 0.5 points per quality step above Common. |
| 7 | Who sets the profession pace | **The fighter who crafts their own gear** (owner's choice). A player who gathers and crafts what their gear needs reaches tier 2 around day 14 and tier 3 around day 55, in step with the character. A player who only grinds a profession gets there much sooner, at a low character level ("explore and fail"). |
| 8 | Do profession levels have a cap? | No cap, and no link to the character level (intent). Tiers above mithril come with new content. |
| 9 | Learning | The player learns a profession from its teacher at Camp. Until then, its spots and recipes show "Learn from <teacher> in camp" instead of a start button. Old saves have Mining and Crafting learned. |
| 10 | Salvage and reroll place | At a forge (Camp, Grey Moor, Mountain Pass), from the item card, once the player has learned Crafting. |
| 11 | Rerolling a Legendary | **One chosen bonus stat, keep the better** (owner's choice). 3 Legendary dust reroll one bonus stat. The player keeps the old one or the new one (§7.3). A Legendary salvages into Legendary dust like any quality. |
| 12 | Reroll odds | The craft odds with the floor, as written (the owner reviewed the numbers). A Common takes about 3 tries to rise, an Uncommon 10, a Rare 33 and an Epic 200. Rising from Epic is a very long chase. |

## 2. Profession levels

### 2.1 Professions and tiers
`professions.json` lists the professions. Each has an id, a name, an icon, a teacher, a tool slot and its tiers:

| Profession | Tier 1 (level 1) | Tier 2 (level 10) | Tier 3 (level 20) |
|---|---|---|---|
| Mining | Copper vein | Iron vein | Mithril vein |
| Woodcutting | Oak tree | Ash tree | Pine tree |
| Crafting | recipes of level 1-9 | 10-19 | 20 and up |

- A tier's name is its material (Copper, Iron, Mithril; Oak, Ash, Pine).
- Crafting names its tiers by the ore.
- Later content adds tiers about every 10 levels.
- Spec 0011 adds Fishing, Hunting and Cooking in the same shape.

### 2.2 Profession XP and levels
- Every gathering spot and recipe keeps its `xp` and `level` in data.
  - `xp` is **profession XP** per action. The numbers of 2026-10-21: veins 20, 55 and 175; recipes 30-1270.
  - `level` is the profession level that the action needs.
- The copper sword, the copper spear, the copper mace and the hide vest need **Crafting 1** (`crafting` 1 in
  `items.json`). Their `level` stays 3: it sets the item level and the reference player's gear. So a new player has
  a first recipe.
- All professions share one XP table, `professionXpToReachLevel` in `economy.json`. A growth factor follows the list,
  as for the character. The table is tuned so that the simulated walker (§9.2) meets §9.3. Spec 0011 amendment 1
  changed its numbers.
- A profession level-up is news in the report and in the Journal: "Mining 10: the Iron vein is yours to work",
  "Crafting 14: new recipes".
- A spot or a recipe above the player's profession level shows why. §8.1 and §8.2 give the words.

### 2.3 Fade
Work below the player's profession level fades two things:
- the profession XP;
- the character XP of §2.4.

The fade compares the action's level with the profession level, by `professionBands` in `economy.json`:

| Action level vs profession level | XP |
|---|---|
| up to 5 below | 100% |
| 6-9 below | 50% |
| 10 or more below | 10% (grey) |

- So the Copper vein (level 1) pays in full up to Mining 6. It goes grey at Mining 11, after the Iron vein opens.
- Recipes and spots show the same colours as monsters (yellow, green, grey) on the profession screens and in Here.

### 2.4 Character XP from professions
- `characterXp = steps walked × professionShare × fightXpPerStep[character level] × fade`.
- The game rounds it down per action. A non-grey action gives at least 1.
- `professionShare` is 0.25.
- `fightXpPerStep` is a list per character level in `economy.json`. It is what the spec 0002 reference player earns
  per step against even-level monsters (spec 0009 §9.1).
- The tuning tool writes `fightXpPerStep`. Levels past the list grow by `xpGrowthAfterList`.
- "Steps walked" counts after the tool's discount (§3). So a better tool gives more items per step, not more
  character XP per step.

## 3. Tools

### 3.1 Slots and starter tools
- Each profession has one tool slot:
  - **Pickaxe** (Mining);
  - **Hatchet** (Woodcutting);
  - **Smith's hammer** (Crafting).
- The tool slots show on the profession screens, not on the paper doll.
- Each teacher gives a Common starter tool when they teach: Hilde's old pick, Bram's old hatchet, Garrow's old
  hammer.
- The player cannot salvage a starter tool, so a player always has one.
- The player can work a profession only with its tool worn. The starter tool goes straight into the slot.

### 3.2 Crafted tools
- The player crafts tools. A tool rolls quality (the craft odds, spec 0005). It has no bonus stats.
- A better tool swaps in from the item card, as gear does. The old tool goes to the bag.

| Tool tier | Crafting level | Steps | Inputs (pickaxe; hatchet and hammer the same) | Step cost |
|---|---|---|---|---|
| Old (starter) | - | - | - | 100% |
| Copper | 3 | 150 | 4 copper ore, 2 oak logs | 90% |
| Iron | 12 | 300 | 6 iron ore, 2 ash logs | 80% |
| Mithril | 22 | 400 | 6 mithril ore, 2 pine logs | 70% |

- Each quality step above Common takes `toolQualityStep` (2 points) more off. A Legendary mithril pick costs 62% of
  the action's steps.
- The game rounds the steps up to whole steps.
- The tool does not change the profession XP per action. So a better tool levels a profession faster per step walked.
- A talent on steps multiplies with the tool, then the game rounds up (spec 0015).
- The words of a tool line are in §8.1.

## 4. Woodcutting

| Spot | Area | Woodcutting level | Steps | Gives | XP |
|---|---|---|---|---|---|
| Oak tree | Goblin Woods | 1 | 100 | Oak log | 20 |
| Ash tree | Grey Moor | 10 | 120 | Ash log | 55 |
| Pine tree | Mountain Pass | 20 | 150 | Pine log | 175 |

The spots live in `world.json` next to the veins, each with its `profession`. Logs join these recipes
(`items.json`):

| Tier | Recipe | Logs added |
|---|---|---|
| Copper / bone | Copper spear, Copper mace, Bone spear, Bone club | 1 oak |
| | Bone greataxe | 2 oak |
| | Bone shield | 2 oak |
| Iron | Iron spear, Iron mace | 1 ash |
| | Iron pike, Troll-bone maul | 3 ash |
| | Iron shield | 2 ash |
| Mithril / drake | Mithril spear, Mithril mace, Drake-fang spear, Drake-fang hammer | 1 pine |
| | Mithril greatsword, Drake-fang halberd | 2 and 3 pine |
| | Golem-core shield | 2 pine |
| All | Every tool (§3.2) | 2 of its tier |

Swords keep their recipes, so the copper sword of day 1 needs no woodcutting.

## 5. Rare finds, rings and trinkets

### 5.1 The roll
Each gathering action rolls once for its spot's rare find:

`chance = rareBase × (1 + 5% × tool quality steps) × (1 + 1% × levels above the spot, at most +10%)`

- `rareBase` is 0.5% (about 1 in 200).
- A find adds one item to the bag.
- A find is news: "Found a Garnet!".

| Spot | Rare find |
|---|---|
| Copper vein | Garnet |
| Iron vein | Sapphire |
| Mithril vein | Star diamond |
| Oak tree | Oak heartwood |
| Ash tree | Ash heartwood |
| Pine tree | Pine heartwood |

### 5.2 Ring and trinket recipes
- Rings fit Ring 1 and Ring 2. Trinkets fit Trinket 1 and Trinket 2.
- They roll quality and bonus stats like any gear. Their item level is the recipe level (spec 0009 §5.1).

| Item | Crafting | Steps | Inputs | Stats |
|---|---|---|---|---|
| Garnet ring | 5 | 200 | 1 garnet, 3 copper ore | +1 Attack, +7 HP |
| Oak charm (trinket) | 5 | 200 | 1 oak heartwood, 2 goblin hide | +1 Defense, +10 HP |
| Sapphire ring | 15 | 300 | 1 sapphire, 4 iron ore | +2 Attack, +17 HP |
| Ash totem (trinket) | 15 | 300 | 1 ash heartwood, 2 ectoplasm | +2 Defense, +20 HP |
| Star-diamond ring | 25 | 400 | 1 star diamond, 4 mithril ore | +3 Attack, +30 HP |
| Pine idol (trinket) | 25 | 400 | 1 pine heartwood, 2 feathers | +3 Defense, +33 HP |

The HP is that of `items.json` on 2026-11-15. Spec 0010 started them at 10, 15, 25, 30, 45 and 50 HP. Spec 0002
amendment 3 change 7 cut the HP of every ring and trinket to 2/3.

## 6. Teachers at Camp

### 6.1 Teaching
- Camp's Here list (spec 0008 §3.2) shows three teachers:
  - **Hilde, the miner**;
  - **Bram, the woodcutter**;
  - **Garrow, the smith**.
- Spec 0011 adds Wen, the fisherman, Sigrun, the hunter, and Marta, the cook. They work in the same way.
- A tap on a teacher opens a sheet.
- The sheet opens with the teacher's greeting or kin line (spec 0012 §3.1 and §4.3).
- Before the player learns the profession, the sheet shows the teacher's line and **Learn Mining** (or the other
  profession).
  - **Learn** learns the profession and puts the starter tool in its slot: "Take my old pick. Bring me copper and
    we'll talk."
  - Learning is instant and free.
  - For the player's origin profession, the kin line replaces the learn line (spec 0012 §3.1).
- After the player learns the profession, the sheet shows a line that follows the profession level, and the tips
  that the teacher has told.

### 6.2 Tips
**Monster tips**
- Each teacher tells a tip about a monster at profession levels 1, 10 and 20.
- A monster tip reveals that monster's armour and weakness, like a lore note (spec 0009 §7.2).

| Teacher | Level 1 | Level 10 | Level 20 |
|---|---|---|---|
| Hilde (Mining) | Skeleton | Troll | Stone golem |
| Bram (Woodcutting) | Old Bear | Giant spider | Harpy |
| Garrow (Crafting) | Zombie | Bandit | Wraith |

Sigrun's three monster tips are in spec 0011 §2.2. Marta, the cook, tells no tips.

**Spot tips**
- A teacher tip can be about a spot instead of a monster.
  - Sigrun tells one tip about each hunting spot.
  - Wen tells one tip about each water.
- A spot tip says:
  - the common catch and the uncommon catch of the spot, with the share of the uncommon one in words, for example
    "one in four";
  - for a fishing spot, also the rare fish, without a share ("now and then a golden carp");
  - a rumour of the spot's rare find, which names the animal or the fish, so the player knows that it exists.
- A spot tip never states a chance as a number. It never tells a rule that the game does not have.
- A spot tip reveals nothing about monsters. It changes no chance, no number and no knowledge. Only
  monster tips reveal an armour and a weakness.
- Wen's tip about Cove rocks also waits until Smugglers' Cove is revealed (spec 0011 §6.1). Before
  that, the teacher sheet does not count it as the next tip.

| Teacher | Level | Spot | Title | Text |
|---|---|---|---|---|
| Sigrun | Hunting 1 | Deer trail | The deer trail | "Red deer feed along the deer trail. One track in four is a wild boar's. And they say a golden stag walks there at dusk. Few hunters ever see it, fewer bring home its antler." |
| Sigrun | Hunting 10 | Moor tracks | Tracks on the moor | "Moor elk graze the Grey Moor, with black boar among them, one in four. The herders talk of Old Tusk, a boar as big as a cart. Nobody I know has brought back his tusk." |
| Sigrun | Hunting 20 | High crags | Up in the crags | "Ibex climb the crags above the pass, and snow grouse nest there, one in four. Watch the snow for a lynx's print. I've seen one, once. Its pelt is worth a season." |
| Wen | Fishing 1 | Lake shore | Still water | "Perch bite all day at Mirror Lake. One in five is a pike, and now and then a golden carp. Something old and green rolls out there at dawn. We call him Old Mossback." |
| Wen | Fishing 10 | Under the bridge | Under the bridge | "Brown trout hold under Troll Bridge, and eels, one in five. A silver salmon, if you're lucky. The trolls say a river king lives under the middle arch. Trolls lie, mostly." |
| Wen | Fishing 15 | Cove rocks | Off the rocks | "So the chart was true. Sea bass off the rocks, mackerel one in five, a moonfish now and then. The old smugglers swore by a fish with one eye, big as a man. And by a chest they lost off the jetty." |
| Wen | Fishing 20 | Cold tarn | The cold tarn | "Arctic char in the cold tarn, and frostfin, one in five. Glacier pike, if you're patient. Something pale moves deep under the ice. I don't fish there alone." |

**When a tip is told**
- A tip waits until the player next talks to the teacher after the player reaches its level. A spot tip uses its
  spot's profession level.
- The teacher's row shows a dot while a tip waits.

**Where tips show**
- Tips show in the teacher sheet and in the Lore tab under the teacher's name.
- Above the text, a monster tip says "About the Wolf", and a spot tip says "About Deer trail".
- Tips do not count in the Lore tab's "6 of 16 found". This applies to monster tips and spot tips.

**Data**
- The tip texts live in `professions.json`.
- A tip has either `enemy` (a monster tip) or `node` (a spot tip), never both.
- The data check fails when a tip has both fields or neither field.
- The data check fails when a spot tip names a spot of another profession.
- The data check fails when the level of a spot tip differs from its spot's level.

**What spot tips leave as it is**
- Sigrun keeps her three monster tips.
- The spot card does not change.
- The catches, their chances and the rare finds do not change.
- The save does not change. Spot tips join the told tips (`tips`) by their ids. An old save loads as before, and a
  player above a spot's level finds the tip waiting at the next talk with the teacher.

## 7. Salvage, dust, rerolls and shards

### 7.1 Salvage
**One item**
- At a forge, the item card of a bag item has **Salvage**. The item is gear or a tool, not worn and not a starter
  tool.
- Rare and better items ask to confirm. Common and Uncommon items do not.
- Salvage is instant and gives no XP.
- It gives **1 dust of the item's quality** (Common dust … Legendary dust). Dust is a material in the bag.
- It rolls once for a **boss shard**: `shardBase` 2%, plus 0.5 points per quality step above Common.
- The shard is the boss of the item's tier (spec 0009 §5.1 bounds):
  - tier 1: Graveyard King;
  - tier 2: Ogre Chieftain;
  - tier 3: Young Dragon.
- Tools count as gear of their tier.
- News: "Found a shard of the Graveyard King (3 of 10)".

**Salvage all**
- A batch takes the same items as a single salvage:
  - gear and tools in the bag;
  - not worn;
  - not a starter tool (a teacher's gift).
  - Items in the bank stay where they are.
- **Salvage all of one quality:** at a forge, the Bag shows one button for each quality that has items for
  a batch.
  - The button says "Salvage all Common (14)": the quality and the number of items.
  - One tap salvages every item of that quality that change 1 allows.
  - A quality with no such item shows no button.
  - Away from a forge, the Bag shows no button and no hint. The item card keeps its hint "Salvage and reroll at a
    forge".
- **Salvage all of one item:** at a forge, the item card shows "Salvage all (5)" next to Salvage when the
  bag holds 2 or more of that item.
  - "The same item" is the same square in the Bag: the same item, quality and bonus stats.
  - One tap salvages all of them.
- **Every batch asks first:** a dialog asks before a batch of any quality, Common too.
  - Title: "Salvage 14 Common items?" or "Salvage 5 Bone swords?".
  - Text: "They break down into dust for good."
  - Buttons: "Keep them" and "Salvage".
- **A batch is single salvages in a row:** each item gives 1 dust of its quality and rolls once for a boss
  shard.
  - The rolls take the bag's order (spec 0008 §3.5).
  - So 14 single salvages in that order and one batch give the same dust, the same shards and the same save.
- **One message for the batch:** the message replaces the one on screen (#176).
  - It says the number of items and the dust: "Salvaged 14 items: 14 Common dust."
  - It names each shard found with the count that its recipe needs: "Found a shard of the Graveyard King (4 of
    10)!".
  - Two shards of one boss: "Found 2 shards of the Graveyard King (5 of 10)!".
- **What stays:**
  - the single Salvage button and its rule (Rare and better ask first; Common and Uncommon do not);
  - the dust, the shard chance and the shard of each tier;
  - a waiting reroll in the queue whose item a batch salvages: the queue skips it, as after a single salvage;
  - the save shape.
- Spec 0020 amendment 8 adds one more batch: Salvage on the items that the player selects in the bag on Character.
  It follows the rules above: it asks first, takes the bag's order and shows one message.

### 7.2 Reroll
- At a forge, the item card of any gear below Legendary has **Reroll (3 Rare dust)**. The gear can be in the bag or
  worn. A tool has no Reroll.
- The button names the item's own quality.
- It starts a forge action of `rerollSteps` (50) steps.
  - The player can queue it like a craft of one.
  - It gives no XP.
- The new quality rolls with the craft odds, with spec 0005's overlevel bonus against the Crafting level.
- The quality **never lands lower**. A lower roll keeps the quality.
- A higher roll keeps the item's bonus stats. It adds one bonus stat per new quality step, from the spec 0009 §5.1
  pool of the item's tier.
- News: "Bone sword reroll: Rare → Epic" or "Bone sword reroll: stays Rare".
- At a place with a bank, a reroll counts its dust in the bag and the bank together. It takes the dust from the bag
  first, then the rest from the bank. Away from a bank, it uses the bag only (spec 0020 amendment 1).
- The Lucky hammer talent works on a quality reroll (spec 0015).

### 7.3 Legendary stat reroll
- At a forge, the item card of a Legendary lists its bonus stats, each with **Reroll (3 Legendary dust)**.
- The button starts the same `rerollSteps` forge action.
- When the action ends, that one stat rolls anew: a stat from the item's tier pool and a value in its range (spec
  0009 §5.1). Repeats are allowed. The other stats stay.
- The result waits on the item card: the old stat and the new one side by side, with **Keep new** and **Keep old**.
- Until the player chooses:
  - the item keeps its old stat;
  - no other reroll of the item can start.
- News: "Bone sword: new roll ready at the forge".
- The player can choose anywhere, because the choice is on the item card. So a queued reroll never blocks the queue.

### 7.4 Shard recipes
- Ten shards of a boss make its unique at a forge.
- The unique rolls quality and bonus stats like a boss drop.

| Unique | Crafting | Steps | Inputs |
|---|---|---|---|
| King's blade | 10 | 300 | 10 King's shards |
| Chieftain's amulet | 20 | 400 | 10 Chieftain's shards |
| Dragon's heart | 30 | 500 | 10 Dragon's shards |

## 8. Screens

### 8.1 Professions
**The Professions tab**
- The Professions tab is a list of profession buttons, in the order Mining, Woodcutting, Fishing, Hunting, Crafting,
  Cooking (spec 0011 §8.1).
- Each button shows the profession's icon, its name, its level, a progress bar to the next level, and the tier name
  ("Iron").
- The button of a profession that the player has not learned shows "Learn from <teacher> in camp" instead of the
  level and the bar.
- The tab shows no profession card.

**A profession's own screen**
- A tap on a button opens that profession's own screen: a page over the tab, with a back arrow.
- The top bar has the name of the profession as its title.
- The screen holds only that profession's card.
- The first line of the card shows the icon of the profession and, when learned, "Level N". It does not show the
  name.
- The card of a learned profession holds:
  - the level, a progress bar to the next level and the tier name ("Iron");
  - the tool line (below);
  - **Where to practise** (below);
  - for Crafting and Cooking, the recipe list (below);
  - what spec 0011 §8.1 adds: Records for Fishing, and the active meal and auto-eat for Cooking.
- The card of a profession that the player has not learned says "Learn from Hilde in camp" (or the other teacher)
  and nothing else.

**The XP numbers**
- The XP numbers of a profession count in the level, as its bar does:
  - the XP earned since the level began;
  - the XP that the level takes.
- Example: Fishing at 100 XP, where level 2 began at 100 and level 3 begins at 148, shows "0 / 48 XP".
- This goes for the profession's own screen and for the Professions tab.
- The character's bar on Now reads the same way: "XP 0 / 48".
- The bars do not change.

**The tool line**
- The tool line shows the tool's name in its quality colour and the saving of the tool: "Iron pickaxe · −20% steps".
- A tap on the tool line opens the tool's item card.
- A tool with no saving (share 100%, the starter tools) says **"Full step cost"**.
- Any other tool says **"−N% steps"**, where N is 100 minus its share.
  - A Common copper tool says "−10% steps".
  - An Uncommon copper tool says "−12% steps".
- The same words show on each tool line: the profession screen, the item card ("Mining tool · −20% steps") and the
  row of a tool recipe.

**Where to practise**
- The card shows the best spot for the level, with its colour and its area, and **Go there**.
- **Go there** travels, then starts the spot. On arrival, it is a normal gathering action.
- For Crafting, it shows the nearest forge.

**The recipe list**
- Crafting's card holds the recipe list (spec 0008 §3.4), with tools, rings, trinkets and shard recipes among the
  recipes. Cooking's card holds the meal recipes (spec 0011 §8.1).
- **The order**:
  - Open recipes come first: the recipes whose profession level the player has. They stand by level, the highest
    first.
  - Locked recipes follow: the recipes that need a higher profession level. They stand by level, the lowest first,
    so the next one to open leads them.
  - Recipes of the same level keep the order that they had among each other before amendment 12.
  - The order follows the profession level as it is when the screen draws. A recipe that opens with a new level
    moves to the top.
  - The lists of gathering spots keep their order.
- **A recipe row**:
  - Each material shows "have/needed" for one craft: "Copper ore 3/5". A short material shows in the short colour
    (`Quiet.short`).
  - The row adds "Enough for N" after the materials. N is the number of crafts that the bag of now allows.
  - "Enough for 0" shows in the short colour.
  - A recipe with no materials shows no "Enough for N".
- **A weapon recipe row** shows the damage type and the hands of the weapon in place of its slot,
  before its stats: "Slash · One hand · +3 Attack". These are the words of the item card.
  - Armour rows keep their slot. The armour type of the player's gear plays no part in a fight.
  - Rings, trinkets, tools, meals and materials keep their words.
- **A locked recipe row** reads "Needs Crafting 16 (you have 11)". It does not repeat the recipe's
  name: the row has the name as its title.
- The recipe rows and the materials table show pictures (spec 0014 §4.2).

**The recipe filters**
- Three chips filter the recipe list:
  - **Have mats:** recipes that the player can make at least once with what is in the bag now.
  - **Have level:** recipes whose profession level the player has.
  - **Up to 5 levels ahead:** recipes that the player has the level for, plus those that need up to 5 more
    profession levels.
- When the player turns on "Have level" or "Up to 5 levels ahead", the other one turns off. "Have mats" combines
  with either.
- With no chip on, the list shows every recipe.
- A list that a filter empties says "Nothing matches the filter".
- A filter takes rows out. It does not change the order of the rest.
- The current craft shows with every filter, at its place in the order.
- The chips show on the screens of Crafting and Cooking, and only when the player has learned that profession.
- The other four screens show no chips.
- The filter choice is one view setting, shared by both screens. The game does not save it. It is off each time the
  app starts.

**Links and actions**
- The Forge row in Now opens Crafting's screen.
- The Camp fire row in Now opens Cooking's screen.
- When the player starts an action from a profession screen (Go there, a recipe), the profession screen closes and
  Now shows.

### 8.2 Now
- Here (Camp): the rows of the teachers (§6.1), with a dot when a tip waits.
- Here (spots): each spot shows its profession level and colour.
- A spot row above the player's level reads "Needs Mining 10 (you have 7)".
- The running gather shows rare finds in its tally ("Garnets: 1").
- The character's bar shows "XP <in the level> / <the level takes>".

### 8.3 Item card and bag
- Tools show their profession and their saving ("Mining tool · −20% steps"), with **Use** / **Swap** like gear.
- At a forge, the item card shows **Salvage**, **Salvage all** and **Reroll** (§7.1-7.3). The Bag shows the Salvage
  all buttons of each quality (§7.1).
- A waiting Legendary stat roll shows **Keep new** / **Keep old** anywhere.
- Away from a forge, the item card says "Salvage and reroll at a forge".
- Dust, logs, gems, heartwood and shards are materials ("Used in: Garnet ring").

### 8.4 Next goal
- The queue checks use profession levels.
- Next goal went away with spec 0024, and its profession line ("Reach Mining 10 to dig iron") with it.

### 8.5 Why a locked action does not start
- The line of a locked spot or recipe names the player's level in that profession.
- On a row, the line has no name: "Needs Woodcutting 8 (you have 5)" (§8.1, §8.2).
- Where the queue says why it skipped a locked action, the line keeps the name: "Iron pike needs Crafting 16 (you
  have 11)". This goes for the Journal and the away report.
- These lines do not change:
  - the red badge;
  - "Learn Woodcutting from …" for a profession that the player has not learned;
  - "You need a hatchet" for a missing tool.

### 8.6 The action sheet of a craft or a cook
The materials of a recipe show on the recipe row (§8.1) and in the action sheet. A short material shows in the
short colour with "Enough for N". A queued craft counts what the earlier actions in the queue gather or use.

| # | Question | Decision |
|---|---|---|
| 1 | Where the materials show | **On the recipe row and in the action sheet** (owner's choice). |
| 2 | How a short material shows | **The short colour (`Quiet.short`) and "Enough for N"** (owner's choice). |
| 3 | Does a queued craft count earlier actions in the queue? | **Yes** (owner's choice). §8.7 gives the rules. |
| 4 | Which bag the recipe row counts | **The bag of now.** The row is a quick look. The action sheet counts the queue. |
| 5 | An earlier action with an unknown amount | **The game counts only what it knows.** §8.7 lists the cases. |
| 6 | The "Have mats" filter | **No change.** It counts the bag of now (§8.1). |
| 7 | Rerolls | **They count in the queue** (§8.7). The sheet of a reroll does not get the materials table. |

**The materials table**
The sheet shows a materials table below the stop choices. Each material of the recipe has one line:

| Material | Have | Uses | Left |
|---|---|---|---|
| Copper ore | 12 | 10 | 2 |
| Oak log | 3 | 4 | 0 |

- **Have** is the count at the place of the new action in the queue (§8.7). With an empty queue, it is the bag of now.
- **Uses** is the need of one craft times the number of crafts that the stop choice asks for.
- **Left** is Have minus Uses, never below 0.
- A material with Have below Uses shows its line in the short colour.
- Below the table, the sheet says "Enough for N" when N is below the number of crafts. N counts the Have column.
- The table updates when the player changes the stop choice or the count.

The number of crafts for each stop choice:

| Stop choice | Crafts |
|---|---|
| Until N crafted | N |
| Until I have N (meals) | N minus the meals at the place in the queue, at least 0 |
| Until a quality | Unknown. Uses and Left show "–". The line "Enough for N" shows. |
| Never stop | Unknown. Uses and Left show "–". The line "Enough for N" shows. |

**Start now and Add to queue**
- With actions in the queue, the table counts the bag after the queue, where "Add to queue" places the action.
- A line above the table then reads "After your queue". With an empty queue, the line does not show.
- Start now clears the queue (spec 0016 §5). The table does not show a second set of numbers for Start now.

### 8.7 The bag after the queue
**What the game counts**
The game reads the queue from the front to the back, from the bag of now, as spec 0016 §3.1 reads the place:
1. **The current action** counts only what is still to come. A craft "Until 5 crafted" with 2 crafts done counts 3.
2. **A craft or a cook with a known number of crafts** uses its materials for that number and adds its outputs. If
   the materials run short, it counts only the crafts that the materials allow.
3. **A gather or a fight "Until I have N"** raises its item to at least N. It adds no other item.
4. **A reroll** uses its dust (3 Rare dust, or 3 Legendary dust for a stat reroll).
5. **A travel action** changes nothing in the bag.

**What the game does not count**
- A gather or a fight "Until grey" or "Never stop" adds nothing: its amount is unknown.
- The other drops of a fight or a gather "Until I have N" add nothing.
- A craft "Until a quality" uses all the materials that it can use: the game cannot know when it stops.
- Salvage is instant, so it is never in the queue.

So the table never promises more materials than the player will have. It can show fewer.

**Rules**
- The count is for the screens only. It never changes the bag, the save or what an action does when it starts.
- The count lives in `game_core` as one function, so the screens and the tests use the same rules.

**Out of scope of the materials table**
- A warning when the player adds a craft that the queue cannot feed. The table shows it; the game does not refuse.
- Materials in the action sheet of a gather or a fight.
- Queue-aware counts on the recipe row and in the "Have mats" filter.

## 9. Balance

### 9.1 Random rolls stay off the shared generator
- Every roll of this spec uses a second generator in the save, the **profession stream**:
  - rare finds;
  - tool quality;
  - ring and trinket quality and bonus stats;
  - salvage shards;
  - reroll quality and new bonus stats;
  - Legendary stat rerolls;
  - shard uniques.
- A new game seeds the profession stream from the game seed through a fixed hash.
- An old save seeds it from a hash of its current generator state.
- Neither takes a draw from the shared generator, so fights and gear drops keep their rolls.
- The crafts that existed before spec 0010 keep their spec 0009 rule: one draw per item.
- The walker's own choices still change (logs to gather, tools to craft, the quarter-XP rule). So its fights move in
  time and the 8 seeds shift. Plan 0012 retuned against them.

### 9.2 The simulated walkers
**Mixed walker** (the `SensiblePlayer` of the 8-seed pacing test)
- It learns every profession on day 1 at Camp. Spec 0011 §9.2 makes it six.
- It counts tools as upgrades, weighed by the steps saved on what it gathers and crafts.
- It crafts a tier's tools once its character is **2 levels past the tool recipe's level**: copper from level 5, iron
  from 14, mithril from 24. It does so only when no gear upgrade waits.
- It aims at upgrades up to its own character level.
- It gathers what its upgrades need (ore, logs), when its profession level allows.
- When the best upgrade waits only for a profession level, it **practises that profession**:
  - its highest spot;
  - for Crafting, the recipe with the most Crafting XP per step, with the inputs.
- It never practises a profession for its own sake.
- It crafts rings and trinkets when it has a gem or a heartwood.
- At a forge:
  - it salvages spare gear: everything but its best in each weapon group, off hand and armour slot;
  - it rerolls worn gear **above Common**, best first, while it has 3 dust of the right quality. It does not reroll
    Common gear;
  - for a Legendary, it rerolls the weakest bonus stat and keeps the better roll;
  - it crafts a unique from 10 shards.
- Real players have neither of these two rules: they can craft a pickaxe on day 1 and reroll anything.
- Other specs add habits to the mixed walker:
  - spec 0011 §9.2 and its amendment 1: fishing, hunting, mantles, meals;
  - spec 0013 §5: it practises a gathering profession one level short of its next tier, once its
    character level reaches that tier; in the last 3 levels of a stage, it gathers for a milestone of that stage;
  - spec 0002 amendment 3 changes 8-9: when no fight is safe, it takes the best paying fight that it wins on average
    swings; it takes fights that it wins with at least 25% of its HP left;
  - spec 0008 §2.3: the King's road.

**Fighter** (`Walker.fighter`)
- It learns every profession at Camp, as the mixed walker does.
- It salvages its spare gear at a forge, and cooks and eats meals, as the mixed walker does.
- It beats the Graveyard King first (spec 0008 §2.3). Then it follows its feat, reroll and meal goals.
- It crafts the best gear upgrade up to its level when it holds all the materials.
- Else it fights the monster that pays best.
- It never gathers or practises a profession for gear.
- It takes fights that it wins with at least 10% of its HP left (spec 0002 amendment 3 change 9).

**Gatherer-crafter**
- It never fights.
- It mines, chops and crafts what it can make from ore, logs and finds, plus tool upgrades.
- It explores the open areas where it has not stood before it practises, because the fog hides the higher spots.
- Spec 0011 §9.2 adds fishing, hunting and meals.
- It has no target since spec 0002 amendment 3 erratum 1. It stays in the tools for a hand look
  (`tool/bag.dart --gatherer`).

### 9.3 Targets (5,000 steps a day, seeds 1-8)
1. **The mixed walker's level:**
   - each seed reaches level 5 on day 1-2;
   - each seed reaches level 10 on day 11-16;
   - each seed reaches level 30 on day 70-105;
   - the median seed reaches level 30 on day 80-100.
2. **The mixed walker's professions** (medians of seeds 1-8):

   | Level | Mining | Crafting |
   |---|---|---|
   | 10 | day 5-22 | day 6-22 |
   | 20 | day 45-65 | day 40-65 |

   The walkers start Mining at level 5 as Miner's children (spec 0012).
3. **The fighter:** its median day of level 30 (seeds 1-8) is in **80-120**. A fighter
   seed that does not reach level 30 in 120 days counts as day 121. The fighter does not need
   to be later than the mixed walker.
4. **Dropped** (spec 0002 amendment 3 erratum 1). It was the gatherer-crafter's level on day 90. The game
   is not tuned for a player who never fights. The mixed walker's targets cover the professions.
5. Spec 0010 changes no monster, so spec 0002's reference targets and spec 0009 criterion 15 hold. Spec 0002
   amendment 3 later changed the monsters and moved most of those reference checks to the walker.

Spec 0011 §9.3 adds targets 5-7 of its own (meals; Fishing, Hunting and Cooking reported).

### 9.4 Expected pressure
- Before spec 0010, the walker earned a good share of its XP from crafting (recipe XP up to 1,270 a craft). Under
  decision 1 that share drops, which slows the walker.
- The tuning order:
  1. the profession XP table first (§9.3 target 2);
  2. then `professionShare` (from 0.25 to at most 0.35);
  3. then the logs of §4.
- If the walker still misses §9.3 target 1, the plan asks the owner before it changes the character XP table or the
  monsters.

## 10. Save
- New save version (8):
  - `professions`: the XP per profession;
  - `learned`: the learned professions;
  - `tools`: the worn tool per profession;
  - `professionRng`: the profession stream;
  - `tips`: the tips told;
  - on a Legendary item, its waiting stat roll (§7.3), which keeps it from a stack with another item.
- On load of an older save:
  - Mining and Crafting are learned, with the starter pickaxe and hammer worn;
  - Woodcutting is not learned;
  - profession XP = for every spot, `gathered.<item>` × its `xp`, plus, for every recipe, `crafted.<output>` × its
    `xp`, with no fade. Saves of the spec 0001 era without these counters start at 0;
  - the game shows no level-up news for this catch-up. The Professions screen opens on the earned levels;
  - character XP stays as it is.
- The queue skips a queued gather or craft whose profession level the player does not have, with the skip line of
  §8.5 that names the level.
- Every fixture in `app/test/fixtures/saves/` loads.

## 11. Out of scope
These were out of the scope of spec 0010:
- Fishing, Hunting, Cooking and their teachers (intent 0011; later spec 0011);
- character origins (intent 0012; later spec 0012);
- quests;
- a split of Crafting;
- profession talents or specialisations;
- the sale of gear;
- a bag cap (later spec 0021);
- tools with bonus stats;
- a display of drop or find chances.

## 12. Concerns
1. **Grinding ahead (medium, accepted in decision 7).** A player who mines and crafts all day can make mithril gear
   in a week or two at a low character level and walk into strong monsters. The sim walker does not do this, so the
   pacing test does not catch it. It is the intent's "single focus goes far". The quarter XP and the monsters'
   levels are the brake.
2. **Losing crafting's XP (medium).** Old players saw big character XP from crafts. Now crafts mostly raise
   Crafting. §9.4 says how the pace is won back.
3. **Seeds shift (medium).** Even with the profession stream, the walker's new choices move its fights. Expect a
   tuning pass in the plan, as in plan 0011.
4. **Starter tool rule (low).** "No tool, no work" plus "starter tools cannot be salvaged" means that nobody is stuck.
   The only risk is a confusing row if a tool is missing. The save load fixes it: it gives the starter tool again.
5. **Old saves jump in level (low).** An old save that crafted a lot may open at Crafting 15 and see many recipes at
   once. That is earned. There is no flood of news (§10).
6. **Long climbs at the top (low, accepted in decision 12).** A reroll up from Rare or Epic takes dozens to hundreds
   of tries, so dust of those qualities piles up slowly. If playtests show that nobody rerolls past Uncommon, the
   later fix is a fixed upgrade chance per quality in data.

## 13. Acceptance criteria
A criterion that checks several things has a letter for each check (rule 13 of `WRITING.md`).

**Levels and XP**
1. Profession levels and what they open:
   - 1a. Mining, Woodcutting and Crafting each have a level from `professionXpToReachLevel`.
   - 1b. Spots and recipes need their profession level, not the character level.
   - 1c. Spots and recipes need their profession learned.
   - 1d. No rule checks the character level for them (this replaces spec 0008 amendment 2 criterion 4).
2. Profession XP per action is the action's `xp` × the profession fade (a table test of §2.3).
3. Character XP from professions:
   - 3a. A gather or a craft gives 25% of `fightXpPerStep` at the character's level per step walked, times the fade
     (§2.4).
   - 3b. Recipes and spots give no other character XP.
4. Teachers:
   - 4a. A teacher at Camp teaches their profession once.
   - 4b. The teacher gives a Common starter tool into its slot.
   - 4c. The teacher tells tips at profession levels 1, 10 and 20.
   - 4d. A monster tip reveals the monster's armour and weakness.

**Tools and woodcutting**
5. Tools:
   - 5a. Each profession has one tool slot.
   - 5b. The step cost follows tier and quality (§3.2), rounded up.
   - 5c. Tools roll quality.
   - 5d. Tools have no bonus stats.
   - 5e. The player cannot salvage a starter tool.
   - 5f. The player cannot work a profession with no tool.
6. Woodcutting:
   - 6a. The Woodcutting spots and the log inputs match §4.
   - 6b. Swords keep their recipes.

**Finds, salvage and rerolls**
7. Rare finds and their recipes:
   - 7a. A rare find rolls once per gathering action, at §5.1's chance.
   - 7b. Over many seeded actions, the rate is 0.5% ± 0.1 with a Common tool at the spot's level.
   - 7c. The ring and trinket recipes match §5.2.
   - 7d. Rings and trinkets fit their slots.
8. Salvage (seeded tests):
   - 8a. Salvage gives 1 dust of the item's quality.
   - 8b. Salvage works only at a forge.
   - 8c. Salvage works only on unworn bag items.
   - 8d. Salvage rolls a shard of the item's tier boss at 2% + 0.5 points per quality step.
9. Quality reroll:
   - 9a. A quality reroll costs 3 dust of the item's quality.
   - 9b. It never lowers quality.
   - 9c. It keeps the bonus stats and adds one per new quality step.
   - 9d. The player cannot reroll a tool.
10. Legendary stat reroll:
    - 10a. It costs 3 Legendary dust.
    - 10b. It rerolls exactly the chosen stat, from the item's tier pool.
    - 10c. The item keeps the old stat or the new one, as the player picks.
    - 10d. Until the player picks, the old stat counts.
    - 10e. Until the player picks, no second reroll of that item starts.
11. Ten shards make the boss's unique at the §7.4 Crafting level.
12. Every roll in criteria 5-11 uses the profession stream. A game with the same seed and steps gives the same fights
    and drops whether or not those rolls happened. The test compares a walker that never salvages with one that
    does: the same fight sequence up to the first craft.

**Save**
13. An old save:
    - 13a. loads with Mining and Crafting learned, at the levels that its counters earn;
    - 13b. has the starter pickaxe and hammer worn;
    - 13c. has Woodcutting not learned;
    - 13d. keeps its character XP;
    - 13e. Every fixture loads.

**Screens**
14. Profession screens (§8.1):
    - 14a. Each profession shows its level, its progress, its tier and its tool.
    - 14b. Each profession shows where to practise, with Go there.
    - 14c. Crafting holds the recipe list.
    - 14d. A profession that the player has not learned points to its teacher.

**Balance and release**
15. Simulated 5,000 steps a day on seeds 1-8:
    - 15a. The walkers meet §9.3 targets 1-3, with the ranges of §9.3.
    - 15b. Target 4 is dropped (spec 0002 amendment 3 erratum 1). The sim no longer reports it.
    - 15c. Spec 0009 criterion 15 holds.
16. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

**The recipe filters**
17. Each filter shows exactly the recipes that its rule describes, on Crafting's and Cooking's lists.
18. "Have level" and "Up to 5 levels ahead" are never on together. "Have mats" combines with either.
19. With no filter on, the list shows every recipe.

**One screen per profession**
20. The Professions tab shows six profession buttons and no profession card.
21. A tap on a button opens a screen with only that profession's card. Back returns to the tab.
22. Crafting's and Cooking's screens show the three filter chips, which work as criteria 17-19 say, when the player
    has learned the profession (criteria 50-51). The other four screens show none.
23. The button and the screen of a profession that the player has not learned name its teacher.
24. The Forge row and the Camp fire row open the matching profession's screen. Back returns to Now.
25. When the player starts an action from a profession screen, the screen closes and Now shows.

**Materials on the recipe row and in the action sheet**
26. A recipe row shows "have/needed" for each material.
27. A recipe row shows "Enough for N", with N from the bag of now.
28. "Enough for 0" shows in the short colour.
29. A recipe with no materials shows no "Enough for N".
30. The action sheet of a craft or a cook shows a materials table with Have, Uses and Left for each material.
31. With "Until 5 crafted" and a need of 2, Uses reads 10.
32. Left reads Have minus Uses, and never below 0.
33. A line with Have below Uses shows in the short colour.
34. "Enough for N" shows when N is below the number of crafts.
35. With "Until I have N" for a meal, the crafts are N minus the meals at the place in the queue.
36. With "Until a quality" or "Never stop", Uses and Left read "–", and "Enough for N" shows.
37. The table updates when the stop choice or the count changes.
38. With an empty queue, Have reads the bag of now, and the "After your queue" line does not show.
39. With actions in the queue, the sheet shows "After your queue", and Have counts the bag after the queue.
40. A queued craft "Until 3 crafted" lowers Have by its use for 3 crafts, and adds its outputs.
41. A queued gather "Until I have 20 Copper ore" raises Have of Copper ore to at least 20.
42. A queued gather "Until grey" or "Never stop" leaves Have as it is.
43. A queued craft "Until a quality" lowers Have to what is left after all the crafts that its materials allow.
44. The current action counts only its crafts still to come.
45. A queued reroll lowers Have of its dust by 3.
46. The count never changes the bag or the save.

**The name once, filters only when learned**
47. A profession screen shows the name of the profession as the title of the top bar.
48. The card on a profession screen does not show the name of the profession.
49. The first line of the card shows the icon of the profession, and "Level N" when learned.
50. The screens of Crafting and Cooking show the three filter chips when the player has learned the profession.
51. The screens of Crafting and Cooking show no filter chip when the player has not learned the profession.
52. The other four screens show no filter chip.
53. The pacing test passes.

**Tool lines and weapon recipe rows**
54. A starter tool's line says "Full step cost", on its profession screen and on its item card.
55. A Common copper tool's line says "−10% steps", on its profession screen and on its item card.
56. A tool of higher quality takes 2 more points off per quality step: an Uncommon copper tool says "−12% steps".
57. The row of a tool recipe says the saving of a Common tool of its tier, for example "−10% steps" for the copper
    pickaxe.
58. No tool line shows "% steps" without the minus sign.
59. The row of a one-handed weapon recipe shows its damage type and "One hand" before its stats, for example
    "Slash · One hand · +3 Attack" for the copper sword.
60. The row of a two-handed weapon recipe shows "Two hands".
61. An armour recipe row keeps its slot and shows no armour type.

**Spot tips**
62. A player who learns Hunting finds Sigrun's Deer trail tip told at once, with her level 1 monster tip.
63. A player at Hunting 9 has no Moor tracks tip waiting.
64. A player at Hunting 10 has the Moor tracks tip waiting, and Sigrun's row shows a dot.
65. A player who learns Fishing finds Wen's Mirror Lake tip told at once.
66. A player at Fishing 15 without Smugglers' Cove revealed has no Cove rocks tip waiting.
67. A player at Fishing 15 with Smugglers' Cove revealed has the Cove rocks tip waiting.
68. At Fishing 10 without the cove revealed, Wen's sheet names Fishing 20 as the next tip, not Fishing 15.
69. An old save of a player at Hunting 12 loads with the Moor tracks tip waiting.
70. A spot tip reveals no monster's armour or weakness.
71. Each spot tip text names the common catch and the uncommon catch of its spot.
72. Each spot tip text names the rare animal or the rare fish of its spot.
73. A spot tip shows "About Deer trail" (its spot's name) above its text, in the teacher sheet.
74. A spot tip shows under its teacher's name in the Lore tab.
75. The Lore tab's "N of M found" does not count spot tips.
76. The data check fails on a tip with both `enemy` and `node`.
77. The data check fails on a tip with neither `enemy` nor `node`.
78. The data check fails on a spot tip whose spot belongs to another profession.
79. The data check fails on a spot tip whose level differs from its spot's level.

**Salvage all**
80. A batch of one quality salvages every bag item of that quality, and nothing else.
81. A batch leaves worn items as they are.
82. A batch leaves starter tools in the bag.
83. A batch leaves the bank as it is.
84. A batch of 3 Common items gives 3 Common dust.
85. A batch gives the same state as single salvages of the same items in the bag's order, from the same seed.
86. A batch away from a forge throws an error and changes nothing.
87. At a forge, the Bag shows "Salvage all Common (N)" when the bag holds N Common items for a batch.
88. At a forge, the Bag shows no button for a quality without items for a batch.
89. Away from a forge, the Bag shows no Salvage all button.
90. At a forge, the item card of a stack of 2 or more shows "Salvage all (N)".
91. At a forge, the item card of a single item shows no "Salvage all" button.
92. A Common batch asks first, and "Keep them" salvages nothing.
93. After "Salvage", the message says the number of items and the dust.
94. A batch that finds a shard names it in the message with its count.

**A locked row names the player's level**
95. A spot row above the player's level reads "Needs <profession> <level> (you have <N>)".
96. A recipe row above the player's Crafting level reads "Needs Crafting <level> (you have <N>)" and does not repeat
    the recipe's name in that line.
97. A profession that the player has not learned still reads "Learn …", with no "(you have …)".

**The fighter**
98. The fighter learns every profession on day 1.
99. Gear:
    - 99a. The fighter crafts a gear upgrade when it holds the materials.
    - 99b. The fighter never gathers or practises a profession for gear.
100. The pacing test checks that the fighter's median day of level 30 (seeds 1-8) is in 80-120.
101. The pacing test no longer checks that the fighter is later than the mixed walker.
102. `.\scripts\check.ps1 -Release -Pacing` is green.

**The order of the recipe list**
103. With Crafting 13, the first row of Crafting's list is a recipe of the highest level up to 13 that the data has.
104. The open recipes stand by level from the highest to the lowest.
105. Each locked recipe stands under every open recipe.
106. The locked recipes stand by level from the lowest to the highest.
107. Recipes of the same level stand in the order of the list before amendment 12.
108. Cooking's list follows criteria 103 to 107 with the Cooking level.
109. With profession level 1, the list is in the order of the list before amendment 12: nothing is open above
     level 1.
110. With "Have level" on, the rows are the open recipes in the order of criterion 104. With "Up to 5 levels ahead"
     on, the locked rows shown follow them.
111. The list has the same recipes as before, each once.
112. Crafting's list is rendered at 408 dp wide before the PR (`CLAUDE.md`).
113. `releases/next/` has a line for players.

**XP numbers in the level**
114. A profession with XP at the start of a level shows "0 / N XP", where N is the XP that the level takes, on its
     screen and on the Professions tab.
115. A profession part way through a level shows the XP earned in the level, and the bar's share equals the first
     number over the second.
116. The character's bar on Now shows "XP <in the level> / <the level takes>".
117. The reason of a skipped locked action still names the recipe or spot.

## History
- 2026-10-21: first version (intent 0010, plan 0012). Criteria 1-16.
- 2026-10-21, amendment 1: first recipes at Crafting 1; the walker practises, the gatherer explores; level 10 on day
  11-16; profession days. §2.2; §9.2; §9.3 targets 1, 2 and 4.
- 2026-10-22, amendment 2: when the walker crafts tools and rerolls. §9.2.
- 2026-10-22, amendment 3 (plan 0015): recipe filters; the profession buttons that scrolled (replaced by amendment
  4). §8.1 "The recipe filters"; criteria 17-19.
- 2026-10-22, spec 0011 and its amendment 1: six professions and teachers; the walkers; the XP table. §2.2; §6.1;
  §8.1; §9.2.
- 2026-10-22, spec 0012 and its amendment 1: the teacher's greeting or kin line; Mining 10. §6.1; §9.3 target 2.
- 2026-10-23, amendment 4 (plan 0016): one screen per profession. §8.1; criteria 20-25.
- 2026-10-23, amendment 4 erratum 1: no link from a tool line to a screen; the tool line opens the tool's card. §8.1
  "The tool line", "Links and actions"; criterion 24.
- 2026-10-25, amendment 5 (#89, plan 0022): materials that the player has, needs, uses and keeps; the bag after the
  queue. §8.1 "The recipe list"; §8.6; §8.7; criteria 26-46.
- 2026-10-25, amendment 6 (#62, plan 0024): the profession screen says its name once and hides filters until learned.
  §8.1; criteria 16, 22 and 47-53.
- 2026-10-25, amendment 7 (#99, #100, plan 0025): tool lines say the saving; weapon recipe rows say their damage
  type. §3.2; §8.1; §8.3; criteria 16, 53 and 54-61.
- 2026-10-31, amendment 8 (#117, plan 0030): the hunter and the fisherman tell what lives at each spot. §6.2;
  criteria 16, 53 and 62-79.
- 2026-10-31, spec 0015: a talent on steps multiplies with the tool; Lucky hammer. §3.2; §7.2.
- 2026-11-01, spec 0013 amendments 1 and 2 (#57): Crafting 10 and 20, Mining 10; two walker habits. §9.2; §9.3
  target 2.
- 2026-11-02, spec 0009 amendment 3 (#181): each seed's day of level 30. §9.3 target 1.
- 2026-11-03, amendment 9 (#175, plan 0043): salvage all. §7.1; §8.3; criteria 16, 53 and 80-94.
- 2026-11-06, amendment 10 (#223): a locked spot or recipe names the player's level. §2.2; §8.2; §8.5; criteria
  95-97.
- 2026-11-06, spec 0020 amendment 1 (#181): a reroll counts the dust in the bank. §7.2.
- 2026-11-06, spec 0014 amendment 9 (PR #216): pictures on the recipe rows and in the materials table. §8.1.
- 2026-11-07, amendment 11 (#237): the fighter focuses on fighting. §9.2; §9.3 target 3; criteria 98-102.
- 2026-11-07, amendment 11 erratum 1 (#237): what target 3 copies; criterion 2 split. §9.2; §9.3 target 3;
  criterion 99.
- 2026-11-09, spec 0002 amendment 3 and its erratum 1 (#234): the fighter's range 80-120; target 4 dropped; the
  walkers' fight choice; the rings' HP. §5.2; §9.2; §9.3; criteria 15 and 100.
- 2026-11-10, amendment 12 (#253, plan 0061): recipe lists start with the highest level that the player can make.
  §8.1 "The order", "The recipe filters"; criteria 16, 53 and 103-113.
- 2026-11-10, amendment 13 (#255): XP numbers count in the level; a locked row does not repeat its name. §8.1; §8.2;
  §8.5; criteria 16, 53, 95-97, 113 and 114-117.
- 2026-11-13, spec 0020 amendment 8 (#267): a batch salvage of the items selected in the bag. §7.1.
- 2026-11-15 (plan 0068): the amendments, the errata and clean edition 1 folded into this file. §5.2 now gives the
  ring and trinket HP of the data (7, 10, 17, 20, 30, 33), with the first numbers beside them. No rule or criterion
  changed.
- 2026-11-17, spec 0024: quests replace Next goal. §8.4. Accepted.
- 2026-11-18 (#278): back from a profession's screen that the Forge row or the Camp fire row opened returns to
  Now, where the player came from. Criterion 24. Accepted.
- 2026-11-18 (#291): two of Wen's tip titles named a place, and the line under them named the spot. "Mirror
  Lake" became "Still water", and "Smugglers' Cove" became "Off the rocks". §6.2 table. Accepted (owner's choice).
