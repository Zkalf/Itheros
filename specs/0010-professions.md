# Spec 0010: Professions

Status: accepted
Intent: [intent/0010-professions.md](../intent/0010-professions.md) (accepted, commit 9e8208a)
Builds on: spec 0002 + amendment 1 (XP, fade, pacing), spec 0005 + amendments (qualities, uniques), spec 0008 +
amendments 1–3 (Professions screen, Here list, item card), spec 0009 + amendment 1 (bonus stats, tiers, lore, 8-seed
pacing)
Overrides: spec 0008 amendment 1 (gathering spots need a character level) and amendment 2 (recipes need a character
level), and their criteria 4 and 13; spec 0008 §3.4 (Professions = today's Craft screen); spec 0002 §3 for gathering
and crafting (their character XP); spec 0005 §3's overlevel bonus for crafts (measured against Crafting, not the
character level)
Product owner: Zkalf
Date: 2026-10-21

Mining, Woodcutting (new) and Crafting each get a level of their own. Gathering spots and recipes need a profession
level instead of a character level. Profession steps still level the character, at a quarter of a fight's pace.
Each profession has one tool; gathering has a rare find that makes rings and trinkets. Teachers in camp teach the
professions and give starter tools. At a forge, spare gear salvages into dust, dust rerolls quality, and salvage
can yield boss shards. All numbers are starting values in `data/*.json`, tuned with the pacing simulator.

## 1. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | Character XP from a profession step | **A quarter of a fair fight, with fade** (owner's choice): each step spent gathering or crafting gives 25% of the XP per step an even-level fight pays at the character's level, times the profession fade (§2.3). Recipes and spots no longer pay character XP of their own. |
| 2 | Rare finds | **Gems make rings, heartwood makes trinkets** (owner's choice). Each vein has a gem, each tree a heartwood; they are the only inputs that make rings and trinkets (§5). |
| 3 | What logs go into | **Hafts, shields and tools** (owner's choice): spears, maces, two-handers and the wooden-backed shields gain logs of their tier; every tool needs logs. Swords, armour and jewellery don't. |
| 4 | Tool strength | **Tier matters, quality adds a little** (owner's choice): steps per action old tool 100%, copper 90%, iron 80%, mithril 70%; each quality step above Common takes 2 more points off. Rare-find chance +5% of itself per quality step. |
| 5 | Reroll cost | **3 dust of the item's quality** (owner's choice), plus a short forge action. Common gear salvages into Common dust. |
| 6 | Boss shards | **The boss of the item's tier, 2%** (owner's choice): +0.5 points per quality step above Common. |
| 7 | Who sets the profession pace | **The fighter who crafts their own gear** (owner's choice). A player who gathers and crafts what their gear needs reaches tier 2 around day 14 and tier 3 around day 55, in step with the character. A player who only grinds a profession gets there much sooner, at a low character level ("explore and fail"). |
| 8 | Do profession levels have a cap? | No cap, and no link to the character level (intent). Tiers above mithril come with new content. |
| 9 | Learning | A profession is learned by talking to its teacher in camp. Until then its spots and recipes show "Learn from <teacher> in camp" instead of a start button. Old saves have Mining and Crafting learned. |
| 10 | Salvage and reroll place | At a forge (Camp, Grey Moor, Mountain Pass), from the item card, once Crafting is learned. |
| 11 | Rerolling a Legendary | **One chosen bonus stat, keep the better** (owner's choice): 3 Legendary dust rerolls one bonus stat; the player keeps the old or the new one (§7.3). A Legendary salvages into Legendary dust like any quality. |
| 12 | Reroll odds | The craft odds with the floor, as written (owner reviewed the numbers): about 3 tries for a Common to rise, 10 for an Uncommon, 33 for a Rare, 200 for an Epic. Rising from Epic is a very long chase. |

## 2. Profession levels

### 2.1 Professions and tiers
`professions.json` lists the professions, each with an id, name, icon, teacher, tool slot and its tiers:

| Profession | Tier 1 (level 1) | Tier 2 (level 10) | Tier 3 (level 20) |
|---|---|---|---|
| Mining | Copper vein | Iron vein | Mithril vein |
| Woodcutting | Oak tree | Ash tree | Pine tree |
| Crafting | recipes of level 1–9 | 10–19 | 20 and up |

A tier's name is its material (Copper, Iron, Mithril; Oak, Ash, Pine); Crafting names its tiers by the ore. Later
content adds tiers about every 10 levels.

### 2.2 Profession XP and levels
- Every gathering spot and recipe keeps its `xp` and `level` in data. `xp` is now **profession XP** per action (the
  numbers of today: veins 20, 55, 175; recipes 30–1270). `level` is the profession level the action needs.
- One XP table for all professions, `professionXpToReachLevel` in `economy.json`, with a growth factor after the
  list (as the character's). Tuned so the simulated walker (§9.2) meets §9.3.
- A profession level-up is news in the report and journal: "Mining 10: the Iron vein is yours to work", "Crafting
  14: new recipes".

### 2.3 Fade
Working below your profession level fades both the profession XP and the character XP of §2.4, by the action's level
against the profession level, from `professionBands` in `economy.json`:

| Action level vs profession level | XP |
|---|---|
| up to 5 below | 100% |
| 6–9 below | 50% |
| 10 or more below | 10% (grey) |

So the Copper vein (level 1) pays in full up to Mining 6 and goes grey at Mining 11, after the Iron vein opens.
Recipes and spots show the same colours as monsters (yellow, green, grey) on the Professions screen and in Here.

### 2.4 Character XP from professions
- `characterXp = steps walked × professionShare × fightXpPerStep[character level] × fade`, rounded down per action,
  at least 1 for a non-grey action.
- `professionShare` is 0.25. `fightXpPerStep` is a list per character level in `economy.json`: what the spec 0002
  reference player earns per step against even-level monsters (spec 0009 §9.1). The tuning tool writes it; levels
  past the list grow by `xpGrowthAfterList`.
- Steps walked are after the tool's discount (§3), so a better tool gives more items, not more character XP per step.

## 3. Tools

### 3.1 Slots and starter tools
- Three tool slots, one per profession: **Pickaxe** (Mining), **Hatchet** (Woodcutting), **Smith's hammer**
  (Crafting). They show on the Professions screen, not on the paper doll.
- Each teacher gives a Common starter tool when they teach: Hilde's old pick, Bram's old hatchet, Garrow's old
  hammer. A starter tool can't be salvaged, so a player always has one.
- A profession can be worked only with its tool worn; the starter tool goes straight into the slot.

### 3.2 Crafted tools
Tools are crafted, roll quality (craft odds, spec 0005), and have no bonus stats. Better tools swap in from the
item card like gear; the old one goes to the bag.

| Tool tier | Crafting level | Steps | Inputs (pickaxe; hatchet and hammer the same) | Step cost |
|---|---|---|---|---|
| Old (starter) | — | — | — | 100% |
| Copper | 3 | 150 | 4 copper ore, 2 oak logs | 90% |
| Iron | 12 | 300 | 6 iron ore, 2 ash logs | 80% |
| Mithril | 22 | 400 | 6 mithril ore, 2 pine logs | 70% |

- Quality takes `toolQualityStep` (2 points) more off per step above Common: a Legendary mithril pick costs 62% of
  the action's steps. Rounded up to whole steps.
- Profession XP per action is unchanged by the tool, so a better tool levels a profession faster per step walked.

## 4. Woodcutting

| Spot | Area | Woodcutting level | Steps | Gives | XP |
|---|---|---|---|---|---|
| Oak tree | Goblin Woods | 1 | 100 | Oak log | 20 |
| Ash tree | Grey Moor | 10 | 120 | Ash log | 55 |
| Pine tree | Mountain Pass | 20 | 150 | Pine log | 175 |

Spots live in `world.json` next to the veins, each with its `profession`. Logs join these recipes (`items.json`):

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

Swords keep their recipes, so the day-1 copper sword needs no woodcutting.

## 5. Rare finds, rings and trinkets

### 5.1 The roll
Each gathering action rolls once for its spot's rare find:
`chance = rareBase × (1 + 5% × tool quality steps) × (1 + 1% × levels above the spot, at most +10%)`, with `rareBase`
0.5% (about 1 in 200). A find adds one item to the bag and is news: "Found a Garnet!".

| Spot | Rare find |
|---|---|
| Copper vein | Garnet |
| Iron vein | Sapphire |
| Mithril vein | Star diamond |
| Oak tree | Oak heartwood |
| Ash tree | Ash heartwood |
| Pine tree | Pine heartwood |

### 5.2 Ring and trinket recipes
Rings fit Ring 1 and Ring 2; trinkets fit Trinket 1 and Trinket 2. They roll quality and bonus stats like any gear
(item level = recipe level, spec 0009 §5.1).

| Item | Crafting | Steps | Inputs | Stats |
|---|---|---|---|---|
| Garnet ring | 5 | 200 | 1 garnet, 3 copper ore | +1 Attack, +10 HP |
| Oak charm (trinket) | 5 | 200 | 1 oak heartwood, 2 goblin hide | +1 Defense, +15 HP |
| Sapphire ring | 15 | 300 | 1 sapphire, 4 iron ore | +2 Attack, +25 HP |
| Ash totem (trinket) | 15 | 300 | 1 ash heartwood, 2 ectoplasm | +2 Defense, +30 HP |
| Star-diamond ring | 25 | 400 | 1 star diamond, 4 mithril ore | +3 Attack, +45 HP |
| Pine idol (trinket) | 25 | 400 | 1 pine heartwood, 2 feathers | +3 Defense, +50 HP |

## 6. Teachers in camp

### 6.1 Teaching
Camp's Here list (spec 0008 §3.2) shows three teachers: **Hilde, the miner**, **Bram, the woodcutter** and
**Garrow, the smith**. Tapping one opens a sheet with their line and:
- if not learned: **Learn Mining** (or the others), which learns the profession and puts the starter tool in its
  slot: "Take my old pick. Bring me copper and we'll talk." Learning is instant and free.
- once learned: a line that follows the profession level, and the tips told so far.

### 6.2 Tips
Each teacher tells a tip about a monster at profession levels 1, 10 and 20. A tip reveals that monster's armour and
weakness, like a lore note (spec 0009 §7.2). Tips show in the Lore tab under the teacher's name; they don't count in
"6 of 16 found".

| Teacher | Level 1 | Level 10 | Level 20 |
|---|---|---|---|
| Hilde (Mining) | Skeleton | Troll | Stone golem |
| Bram (Woodcutting) | Old Bear | Giant spider | Harpy |
| Garrow (Crafting) | Zombie | Bandit | Wraith |

A tip is told when the player next talks to the teacher after reaching the level; the sheet shows a dot on the
teacher's row when one is waiting. Texts live in `professions.json`.

## 7. Salvage, dust, rerolls and shards

### 7.1 Salvage
- At a forge, the item card of a bag item (gear or tool, not worn, not a starter tool) has **Salvage**. Rare and
  above ask to confirm. Salvage is instant and gives no XP.
- It gives **1 dust of the item's quality** (Common dust … Legendary dust). Dust is a material in the bag.
- It rolls once for a **boss shard**: `shardBase` 2% + 0.5 points per quality step above Common. The shard is the
  boss of the item's tier (spec 0009 §5.1 bounds): tier 1 Graveyard King, tier 2 Ogre Chieftain, tier 3 Young
  Dragon. Tools count as gear of their tier. News: "Found a shard of the Graveyard King (3 of 10)".

### 7.2 Reroll
- At a forge, the item card of any gear below Legendary (bag or worn; not a tool) has **Reroll (3 Rare dust)**,
  naming the item's own quality. It starts a forge action of `rerollSteps` (50) steps, which can be queued like a craft of
  one and gives no XP.
- The new quality rolls with the craft odds, including spec 0005's overlevel bonus against the Crafting level, and
  **never lands lower**: a lower roll keeps the quality. A higher one keeps the item's bonus stats and adds one bonus
  stat per new quality step (spec 0009 §5.1 pool of the item's tier).
- News: "Bone sword reroll: Rare → Epic" or "Bone sword reroll: stays Rare".

### 7.3 Legendary stat reroll
- At a forge, a Legendary's item card lists its bonus stats, each with **Reroll (3 Legendary dust)**. It starts the
  same `rerollSteps` forge action.
- When it ends, that one stat rolls anew: a stat from the item's tier pool and a value in its range (spec 0009
  §5.1; repeats allowed). The other stats stay.
- The result waits on the item card: old and new side by side, **Keep new** or **Keep old**. Until the player
  chooses, the item keeps its old stat and no other reroll of it can start. News: "Bone sword: new roll ready at the
  forge".
- The choice can be made anywhere (it's on the item card), so a queued reroll never blocks the queue.

### 7.4 Shard recipes
Ten shards of a boss make its unique at a forge. The unique rolls quality and bonus stats like a boss drop.

| Unique | Crafting | Steps | Inputs |
|---|---|---|---|
| King's blade | 10 | 300 | 10 King's shards |
| Chieftain's amulet | 20 | 400 | 10 Chieftain's shards |
| Dragon's heart | 30 | 500 | 10 Dragon's shards |

## 8. Screens

### 8.1 Professions (bottom bar)
One card per profession, in the order Mining, Woodcutting, Crafting:
- RP icon, name, level, a progress bar to the next level, and the tier name ("Iron").
- The tool: its name in its quality colour and the step cost ("Iron pickaxe · 78% steps"); tap opens the item card.
- **Where to practise**: the best spot for the level (its colour, area) with **Go there** (travels, then starts it;
  on arrival it's a normal gathering action). For Crafting: the nearest forge.
- Crafting's card holds today's recipe list (spec 0008 §3.4) with the profession level in place of the character
  level ("Needs Crafting 14"), tools, rings, trinkets and shard recipes among them, in tier order.
- Not learned: "Learn from Hilde in camp" and nothing else.

### 8.2 Now
- Here (camp): the teachers' rows (§6.1), with a dot when a tip is waiting.
- Here (spots): each spot shows its profession level and colour; one above the level reads "Needs Mining 10".
- The running gather shows rare finds in its tally ("Garnets: 1").

### 8.3 Item card and bag
- Tools show their profession and step cost, and **Use** / **Swap** like gear.
- At a forge: **Salvage** and **Reroll** (§7.1–7.3), and a waiting Legendary stat roll's **Keep new / Keep old**
  anywhere. Away from a forge, the card says "Salvage and reroll at a forge".
- Dust, logs, gems, heartwood and shards are materials ("Used in: Garnet ring").

### 8.4 Next goal
Next goal and the queue checks use profession levels. When the best upgrade is out of reach only because of a
profession level, Next goal says so: "Reach Mining 10 to dig iron (7 to go)".

## 9. Balance

### 9.1 Random rolls stay off the shared generator
Every roll this spec adds (rare finds, tool quality, ring and trinket quality and bonus stats, salvage shards,
reroll quality and new bonus stats, Legendary stat rerolls, shard uniques) uses a second generator in the save, the **profession stream**. A
new game seeds it from the game seed through a fixed hash; an old save seeds it from a hash of its current generator
state. Neither takes a draw from the shared generator, so fights and gear drops keep their rolls. Crafts that exist
today keep their spec 0009 rule (one draw per item).

The walker's own choices still change (logs to gather, tools to craft, the quarter-XP rule), so its fights move in
time and the 8 seeds will shift; the plan retunes against them.

### 9.2 The simulated walker
- **Mixed walker** (the `SensiblePlayer`, the 8-seed pacing test): learns all three professions on day 1 in camp.
  Counts tools as upgrades, weighed by steps saved on what it gathers and crafts. Gathers what its upgrades need
  (ore, logs), when its profession level allows; otherwise picks the next upgrade. Crafts rings and trinkets when it
  has a gem or heartwood. At a forge, salvages spare gear (everything but its best in each weapon group, off hand and
  armour slot), rerolls its worn gear best-first while it has 3 dust of the right quality (for a Legendary, its weakest
  bonus stat, keeping the better roll), and crafts a unique from 10 shards. It doesn't grind a profession for its own sake.
- **Fighter**: never learns a profession; wears only drops.
- **Gatherer-crafter**: never fights; mines, chops and crafts what it can make from ore, logs and finds, plus tool
  upgrades.

### 9.3 Targets (5,000 steps a day, seeds 1–8)
1. Mixed walker: spec 0009 amendment 1 holds (level 5 on day 1–2, level 10 on day 12–16, level 30 on day 70–100,
   median day 80–100).
2. Mixed walker's professions: Mining and Crafting 10 by day 12–18, 20 by day 45–65 (median of the seeds).
3. The mix is clearly fastest: the fighter's median level 30 day is at least 15% later than the mixed walker's (or
   it isn't level 30 by day 120).
4. The gatherer-crafter's median character level on day 90 is fair: the plan reports it after tuning and the owner
   sets the number.
5. Spec 0002's reference targets (XP per step, fight lengths, gear checks, spec 0009 criterion 15) are unchanged:
   no monster changes.

### 9.4 Expected pressure
Today the walker earns a good share of its XP from crafting (recipe XP up to 1,270 a craft). Under decision 1 that
share drops, which slows the walker. The tuning order: profession XP table first (§9.3.2), then `professionShare`
(0.25 to at most 0.35), then the logs added in §4. If the walker still misses §9.3.1, the plan asks the owner
before touching the character XP table or monsters.

## 10. Save
New save version (8):
- `professions`: XP per profession; `learned`: learned professions; `tools`: the worn tool per profession;
  `professionRng`: the profession stream; `tips`: tips told; on a Legendary item, its waiting stat roll (§7.3),
  which keeps it from stacking with another.
- On load of an older save: Mining and Crafting are learned, with the starter pickaxe and hammer worn; Woodcutting
  isn't. Profession XP = for every spot, `gathered.<item>` × its `xp`; for every recipe, `crafted.<output>` × its
  `xp`, with no fade (spec 0001-era saves without these counters start at 0). Level-up news for this catch-up is not
  shown; the Professions screen just opens on the earned levels. Character XP is untouched.
- A queued gather or craft whose profession level isn't met is skipped with today's skip line, naming the level.
- Every fixture in `app/test/fixtures/saves/` loads.

## 11. Out of scope
Fishing, Hunting, Cooking and their teachers (intent 0011); character origins (0012); quests; splitting Crafting;
profession talents or specialisations; selling gear; a bag cap; tools with bonus stats; showing drop or find chances.

## 12. Concerns
1. **Grinding ahead (medium, accepted in decision 7).** A player who mines and crafts all day can make mithril gear
   in a week or two at a low character level and walk into strong monsters. The sim walker doesn't do this, so the
   pacing test doesn't catch it. It's the intent's "single focus goes far"; the quarter XP and the monsters' levels
   are the brake.
2. **Losing crafting's XP (medium).** Old players saw big character XP from crafts; now crafts mostly raise
   Crafting. §9.4 says how the pace is won back.
3. **Seeds shift (medium).** Even with the profession stream, the walker's new choices move its fights. Expect a
   tuning pass in the plan, as in plan 0011.
4. **Starter tool rule (low).** "No tool, no work" plus "starter tools can't be salvaged" means nobody is stuck;
   the only risk is a confusing row if a tool is somehow missing, which the save load fixes by re-giving the starter.
5. **Old saves jump in level (low).** An old save that crafted a lot may open at Crafting 15 and see many recipes
   at once. That's earned; no news spam (§10).
6. **Long climbs at the top (low, accepted in decision 12).** Rerolling up from Rare or Epic takes dozens to hundreds
   of tries, so dust of those qualities piles up slowly. If playtests show nobody rerolls past Uncommon, a fixed
   upgrade chance per quality in data is the later fix.

## 13. Acceptance criteria
1. Mining, Woodcutting and Crafting each have a level from `professionXpToReachLevel`; spots and recipes need their
   profession level (not the character level) and that profession learned; no rule checks the character level for
   them (replaces spec 0008 amendment 2 criterion 4).
2. Profession XP per action is the action's `xp` × the profession fade (§2.3 table test).
3. Character XP from a gather or craft follows §2.4: 25% of `fightXpPerStep` at the character's level per step
   walked, times the fade; recipes and spots give no other character XP.
4. Teachers in camp teach their profession once, give a Common starter tool into its slot, and tell tips at
   profession levels 1, 10 and 20 that reveal the monster's armour and weakness.
5. Tools: one slot per profession; step cost follows tier and quality (§3.2, rounded up); tools roll quality, have
   no bonus stats; starter tools can't be salvaged; a profession can't be worked with no tool.
6. Woodcutting spots and log inputs match §4; swords keep their recipes.
7. Rare finds roll once per gathering action at §5.1's chance; over many seeded actions the rate is 0.5% ± 0.1 with
   a Common tool at the spot's level; ring and trinket recipes match §5.2 and fit their slots.
8. Salvage gives 1 dust of the item's quality, works only at a forge and only on unworn bag items, and rolls a
   shard of the item's tier boss at 2% + 0.5 points per quality step (seeded tests).
9. A quality reroll costs 3 dust of the item's quality, never lowers quality, keeps bonus stats and adds one per new
   quality step; tools can't be rerolled.
10. A Legendary stat reroll costs 3 Legendary dust, rerolls exactly the chosen stat from the item's tier pool, and
    the item keeps whichever of old and new the player picks; until then the old stat counts and no second reroll
    of that item starts.
11. Ten shards make the boss's unique at the §7.4 Crafting level.
12. Every roll in criteria 5–11 uses the profession stream: a game with the same seed and steps gives the same
    fights and drops whether or not those rolls happened (test with a walker that never salvages vs one that does,
    same fight sequence up to the first craft).
13. An old save loads with Mining and Crafting learned at the levels its counters earn, starter pickaxe and hammer
    worn, Woodcutting not learned, character XP unchanged; every fixture loads.
14. The Professions screen shows each profession's level, progress, tier, tool and where to practise with Go there;
    Crafting holds the recipe list; unlearned professions point to their teacher.
15. Simulated 5,000 steps a day on seeds 1–8 meet §9.3 targets 1–3 and report target 4; spec 0009 criterion 15
    still holds.
16. `.\scripts\check.ps1 -Release` is green, with no INTERNET permission.
