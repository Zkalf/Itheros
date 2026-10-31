# Spec 0015: Talent trees

Status: accepted
Intent: [intent/0015-talent-trees.md](../intent/0015-talent-trees.md) (accepted)
Builds on: spec 0002 decision 7 (one talent point per level from 10), spec 0005 §3 (the quality roll), spec 0009
§2 (combat), spec 0010 §3.2 and §7.2 (profession steps, rerolls), spec 0014 §4.3 (the look of the talent screen),
spec 0016 §2 (`queueSlots(state)`), spec 0017 §3.4 (rewards that add to the bank and the queue)
Overrides: the words "Talents arrive in a later update" on the level-up screen, in the news and on Character
Product owner: Zkalf (chose on 2026-10-31: the two last talents, the shape, the reset price)
Date: 2026-10-31

The player spends talent points in two trees, **Combat** and **Utility**. Each tree has six rows. Points spent in a
tree open its next row, as in World of Warcraft Classic. Combat makes fights a bit faster and loot a bit better.
Utility makes the day easier: a bigger bank, cheaper actions and travel, an extra queue slot and better crafts. The
player resets the trees at a trainer in Camp.

## 1. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | The shape | **6 rows. Each 5 points spent in a tree open its next row** (owner). Row 6 opens at 25 points. Each tree holds 30 points. The soft cap gives 28 points (level 37). |
| 2 | The last Combat talent | **Impale: critical hits deal 2.5× damage instead of 2×** (owner). From World of Warcraft. |
| 3 | The last Utility talent | **Wayfarer: travel costs half its steps** (owner). |
| 4 | The reset price | **2,000 steps more for each paid reset, up to a cap, and the price falls again with walking** (owner). The first reset is free. The numbers are in §2.6. |
| 5 | How the price falls | **By steps walked since the last reset**, not by days. The game rules count steps and know no calendar. 35,000 steps are about a week for the average walker. Claude's choice. |
| 6 | The trainer | **Ysolde, the Guild trainer**, in Camp. Lines in §2.7. Claude's choice. |
| 7 | Where to spend | **Anywhere** (intent outcome 22). Spending is instant and costs no steps. |
| 8 | Talent numbers | The starting values in §2.3 and §2.4. The plan tunes them with the sim to the targets of §5. They live in `talents.json`. |
| 9 | Percent stats | Attack, HP and Defense talents add a percent of the stats from level and gear, rounded down, like a meal (spec 0011 §5.3). |
| 10 | Rows and pips | Each talent is one **path** of spec 0014 §4.3: a plate with an image, a name and one line. Its ranks are the pips. |
| 11 | Talents that need another talent | **Three, as in World of Warcraft Classic** (owner, 2026-10-31): Impale needs Keen eye, Lucky hammer needs Master crafter, Wayfarer needs Light pack, each with all its ranks (§2.1). The other talents need only their row. |

## 2. Rules

### 2.1 Points
- The player has the talent points of spec 0002 decision 7: one per level from level 10.
- Points left = points earned − ranks taken in both trees.
- A rank costs 1 point.
- A player takes a rank of a talent when:
  - a point is left
  - the talent's row is open
  - the talent has a rank left
  - the talent that it needs, if any, has all its ranks (the table below)
- A row opens when the ranks taken in its tree reach its number: row 1 at 0, row 2 at 5, row 3 at 10, row 4 at 15,
  row 5 at 20 and row 6 at 25.
- Ranks stay until a reset (§2.6). The player cannot take one rank back.
- Three talents need another talent of their tree with all its ranks:

| Talent | Needs |
|---|---|
| Impale (Combat, row 6) | Keen eye 3/3 (row 2) |
| Lucky hammer (Utility, row 5) | Master crafter 3/3 (row 3) |
| Wayfarer (Utility, row 6) | Light pack 5/5 (row 4) |

- A talent works from the moment the player takes it. It changes nothing that already happened: a running fight
  keeps its rounds paid, and a gear item keeps its quality.

### 2.2 How the bonuses count
- The talents of both trees add up.
- A percent talent on Attack, HP or Defense adds that percent of the stats from level and gear, rounded down. The
  meal and the feats do not count into it.
- A percent talent on steps multiplies with the tool and the meal, then rounds up, as spec 0010 §3.2 does.
- A talent on quality chances multiplies the chance of each quality above Common in the roll of spec 0005 §3, like
  the overlevel bonus. Common takes what is left.

### 2.3 Combat (30 points)

| Row | Opens at | Talent | Ranks | Each rank | Full |
|---|---|---|---|---|---|
| 1 | 0 | **Might** | 5 | +2% Attack | +10% Attack |
| 1 | 0 | **Toughness** | 5 | +3% HP | +15% HP |
| 2 | 5 | **Guard** | 3 | +2% Defense | +6% Defense |
| 2 | 5 | **Keen eye** | 3 | +1 Crit | +3 Crit |
| 3 | 10 | **Swift strikes** | 5 | a fight costs 3% fewer steps | 15% fewer |
| 4 | 15 | **Precision** | 3 | +1 Hit | +3 Hit |
| 4 | 15 | **Evasion** | 2 | +1 Dodge | +2 Dodge |
| 5 | 20 | **Treasure hunter** | 3 | +10% quality chances on monster drops | +30% |
| 6 | 25 | **Impale** | 1 | critical hits deal 2.5× damage instead of 2× | |

- **Swift strikes:** a round still costs `combatRoundSteps` (10). When a fight ends, won or lost, the steps that it
  saves go back to the running action as progress: the steps of its rounds × the share, rounded down. They pay for
  the next round. The fight log keeps its rounds.
- **Treasure hunter** changes the quality of gear that a monster drops. It does not give more drops. Drop chances,
  first-kill drops and boss drops keep their chances (intent outcomes 9-10). Crafts and rerolls do not use it.
- **Impale** replaces `critDamage` (2) with 2.5 for the player's critical hits. Monsters keep 2.
- Crit, Hit and Dodge from talents count toward their caps (spec 0009 §2.1).

### 2.4 Utility (30 points)

| Row | Opens at | Talent | Ranks | Each rank | Full |
|---|---|---|---|---|---|
| 1 | 0 | **Deep pockets** | 5 | +600 bank cap | +3,000 |
| 1 | 0 | **Nimble hands** | 5 | gathering and crafting cost 2% fewer steps | 10% fewer |
| 2 | 5 | **Bountiful** | 5 | 3% chance that a gathering action gives one more of its item | 15% |
| 2 | 5 | **Wary** | 2 | a lost fight pays +10 points of its XP share; rank 1 also warns before orange fights | 0.75 → 0.95 |
| 3 | 10 | **Master crafter** | 3 | +10% quality chances on crafted gear and tools | +30% |
| 3 | 10 | **Quartermaster** | 1 | +1 queue slot | |
| 4 | 15 | **Light pack** | 5 | travel costs 4% fewer steps | 20% fewer |
| 5 | 20 | **Lucky hammer** | 3 | +15% quality chances on a reroll | +45% |
| 6 | 25 | **Wayfarer** | 1 | travel costs half its steps | |

- **Nimble hands** works on gathering and crafting actions. Rerolls, fights and travel do not use it.
- **Bountiful** adds one of the spot's own item (`item`: ore, log, scale or hide), not a catch or a rare find. The roll
  uses the profession stream (spec 0010 §9.1), so it shifts no fight or drop.
- **Wary:** the lost-fight XP share of spec 0003 §5 (`lossXpShare`, 0.75) rises by 0.10 per rank. With rank 1, the
  deadly-fight warning also shows for orange monsters, not only for red and skull ones.
- **Master crafter** works on crafted gear and tools. Meals, materials and rerolls do not use it.
- **Light pack** and **Wayfarer** multiply: with both, a road costs 0.8 × 0.5 = 40% of its steps, rounded up.
- **Quartermaster** adds to `queueSlots(state)` (spec 0016 §2), as Chieftain's Bane does (spec 0017 §3.4).
- **Lucky hammer** works on a quality reroll (spec 0010 §7.2) and multiplies with Master crafter. A Legendary stat
  reroll (§7.3) does not use it.

### 2.5 Balance between the trees
- A full Combat build gives about 10-15% more progress for each step than a full Utility build (intent outcome 5).
- The progress counts XP, levels and loot (§5).
- Neither tree is a trap: each build gives more progress than no talents.

### 2.6 Reset
- Ysolde, in Camp, resets both trees. All ranks go, and every point is left to spend again.
- The reset is instant. The player confirms it first.
- The **first reset is free**.
- Each later reset costs steps **from the bank**. The save keeps the price of the next paid reset:
  - It starts at 2,000 steps (`resetBase`).
  - The price now is the saved price, less 2,000 (`resetStep`) for each 35,000 steps (`resetCooldownSteps`) walked
    since the last reset. It never goes below 2,000.
  - A paid reset pays the price now. The saved price becomes the price now + 2,000, at most 10,000 (`resetCap`).
  - The free first reset leaves the saved price at 2,000.
  - Each reset sets the steps walked since the last reset to 0.
- So a player who resets often pays more each time. A player who walks a long time between resets pays less again.
- The steps walked count all synced steps, also steps that go to the bank.
- A reset with too few steps in the bank is refused: "You need 4,000 steps in the bank."
- A player with no ranks taken cannot reset.

| Reset | Steps walked since the reset before | Price |
|---|---|---|
| 1st | any | free |
| 2nd | under 35,000 | 2,000 |
| 3rd | under 35,000 | 4,000 |
| 4th | under 35,000 | 6,000 |
| 4th | 35,000-69,999 | 4,000 |
| 4th | 70,000 or more | 2,000 |
| 5th, after a 4th for 2,000 | under 35,000 | 4,000 |
| any | under 35,000, after a reset for 10,000 | 10,000 (the cap) |

### 2.7 The trainer
Camp's Here list shows **Ysolde, the Guild trainer** under the teachers. Tapping her opens a sheet:
- Greeting: "Steps make the body, {name}. Talents make the fighter."
- Before level 10: "Come back when the Guild names you Adventurer."
- From level 10: the points left and the reset button.
- The reset button: **Forget my talents** (free) or **Forget my talents · 4,000 steps**.
- The confirmation: "Forget every talent? Your points come back to spend again." with **Forget** and **Keep**.
- After a reset: "There. Walk a new road."
- Lines live in `talents.json`, like the teachers' lines.

### 2.8 Data
`packages/game_core/data/talents.json` holds:
- `rowEvery` (5), the trainer's lines and location, and the reset numbers of §2.6
- the two trees, each with its id, name and line
- each talent: id, tree, row, name, one line, ranks, image, and its effect with the value of one rank
- for a talent that needs another one: `needs`, the id of that talent

The effects are a closed list. Each one names what it changes:

| Effect | What it changes |
|---|---|
| `attackPercent`, `hpPercent`, `defensePercent` | the stats (§2.2) |
| `crit`, `hit`, `dodge` | the stats, in points |
| `fightSteps` | the share of a fight's steps that comes back |
| `dropQuality` | the quality chances of monster drops |
| `critDamage` | the player's critical damage |
| `bankCap` | the bank cap, in steps |
| `professionSteps` | the steps of gathering and crafting |
| `extraGather` | the chance of one more item at gathering |
| `lossXpShare` | the lost-fight XP share; rank 1 warns before orange fights |
| `craftQuality` | the quality chances of crafted gear and tools |
| `queueSlot` | the queue slots |
| `travelSteps` | the steps of travel (Light pack: a share off; Wayfarer: half) |
| `rerollQuality` | the quality chances of a reroll |

The data check fails when:
- a talent names an unknown tree or effect
- a row is not 1-6
- a talent has fewer than 1 rank
- a talent needs a talent of another tree, of its own row or a lower one, or an unknown talent
- a tree holds fewer points than the soft cap gives (28)
- the reset numbers are not positive, or the cap is lower than the base

## 3. Screens

### 3.1 Character: Talents
Character gets a third tab, **Talents**, after Gear and Bag (spec 0008 §3.5). The look is spec 0014 §4.3.
- The heading shows the points left: "3 points left". With none: "No points left". Before level 10: "Talents open at
  level 10."
- Two tabs inside: **Combat · 12** and **Utility · 0**, with the ranks taken in each tree.
- Each row shows its talents as plates. A plate has the talent's image, its name, its line and one teal pip per
  rank. A taken rank is a filled pip.
- A row that is not open is dim and says "Opens at 10 points in Combat".
- A plate of a talent that needs another one says "Needs Keen eye 3/3" until that talent has all its ranks.
- A tap on a plate opens a sheet:
  - the name, the line and the rank: "Rank 2 of 5"
  - what it gives now and at the next rank: "Now: +4% Attack · Next: +6% Attack"
  - a slate button **Learn · 1 point**, when the player can take a rank
  - otherwise a line why not: "No points left", "Opens at 10 points in Combat", "Needs Keen eye 3/3" or "All ranks
    taken"
- The Character header keeps its talent line (spec 0014 criterion 8). It says "3 talent points to spend" when points
  are left, and nothing else when none are.

### 3.2 Words that change
- The level-up screen: "+1 talent point. Spend it on Character → Talents."
- The news line of a talent point: "+1 talent point."
- The Character line "Talents arrive in a later update." goes.

### 3.3 Camp
Ysolde's row in the Here list and her sheet (§2.7). A dot shows on her row when points are left.

## 4. Save
- Save version 13.
- `talents`: the ranks taken, by talent id. An old save loads with none.
- `talentResets`: the number of resets so far. An old save loads with 0.
- `resetPrice`: the saved price of the next paid reset (§2.6). An old save loads with 2,000.
- `walkedSinceReset`: the steps walked since the last reset. An old save loads with 0.
- An old save keeps its points: they are earned by level. The player can spend them at once.
- A talent id that the data no longer holds is dropped on load, and its points come back.
- Each fixture in `app/test/fixtures/saves/` loads.

## 5. Balance
Talents change where steps go, so a hand-run sim checks the pace (intent constraint).
- The sim gets three builds. The walker spends each point at once, in a fixed order:
  - **Combat:** Combat only, row by row.
  - **Utility:** Utility only, row by row.
  - **Split:** Might and Toughness first, then Deep pockets, Nimble hands, Quartermaster, then the rest of Combat.
- The sim walks 5,000 steps a day for 120 days, from a new character, with each build and with no talents.
- Targets:
  1. Each build reaches level 25 sooner than no talents.
  2. Combat reaches level 25 in 10-15% fewer days than Utility.
  3. Split reaches level 25 between Combat and Utility.
  4. Combat finds more Rare-or-better monster drops than Utility.
  5. No-talent pace stays as today: the pacing test passes with talents off.
- The plan records the results in a table: days to level 25, level on day 120, and Rare-or-better drops, for each
  build.
- The plan may tune the numbers of §2.3 and §2.4 to meet the targets. The owner sees the changed numbers in the PR.

## 6. Out of scope
- More than two trees.
- Talents for each profession.
- Talents that the player uses by hand.
- Talent points from anything but levels.
- A find chance from gear.
- Prerequisites between talents other than the three of §2.1.
- Arrows drawn between plates: they can come with the art.
- New art: the plates use the app's icon set until art comes.

## 7. Acceptance criteria
**Points and rows**
1. A level 9 player has 0 points, and a level 12 player has 3.
2. Taking a rank costs 1 point.
3. A rank cannot be taken with 0 points left.
4. A row 2 talent cannot be taken with 4 ranks in its tree.
5. A row 2 talent can be taken with 5 ranks in its tree.
6. Ranks in Utility do not open Combat rows.
7. A talent cannot take more ranks than it has.
8. Each tree holds 30 points.
9. Impale cannot be taken with Keen eye at rank 2, even with its row open.
10. Impale can be taken with Keen eye at rank 3 and its row open.
11. Lucky hammer cannot be taken before Master crafter has rank 3.
12. Wayfarer cannot be taken before Light pack has rank 5.
13. A plate of a talent that needs another one says what it needs until that talent has all its ranks.

**Combat effects**
14. Might at rank 5 adds 10% of the level-and-gear Attack, rounded down.
15. Toughness at rank 5 adds 15% of the level-and-gear HP, rounded down.
16. Guard at rank 3 adds 6% of the level-and-gear Defense, rounded down.
17. Keen eye, Precision and Evasion add their points to Crit, Hit and Dodge, within the caps.
18. With Swift strikes at rank 5, a won fight of 6 rounds gives 9 steps back to the action (60 × 0.15).
19. With Swift strikes, a lost fight also gives its steps back.
20. Treasure hunter at rank 3 multiplies the Uncommon-or-better chances of a monster drop by 1.3.
21. Treasure hunter does not change the drop chance of any item.
22. Treasure hunter does not change crafted quality.
23. With Impale, the player's critical hit deals 2.5× damage.
24. With Impale, a monster's critical hit still deals 2×.

**Utility effects**
25. Deep pockets at rank 5 adds 3,000 to the bank cap.
26. Nimble hands at rank 5 makes a 100-step gathering action with a starter tool cost 90 steps.
27. Nimble hands does not change travel, fight or reroll steps.
28. Bountiful gives one more of the spot's item in about 15% of gathering actions at rank 5 (seeded test).
29. Bountiful leaves the fights and drops of a seeded run as they were.
30. Wary at rank 2 pays a lost fight 0.95 of the XP for the health knocked off, not 0.75.
31. With Wary at rank 1, an orange fight shows the deadly-fight warning.
32. Without Wary, an orange fight shows no warning.
33. Master crafter at rank 3 multiplies the Uncommon-or-better chances of a craft by 1.3.
34. Quartermaster adds 1 queue slot, and it adds up with Chieftain's Bane.
35. Light pack at rank 5 makes a 500-step road cost 400 steps.
36. Wayfarer makes a 500-step road cost 250 steps.
37. Light pack at rank 5 with Wayfarer makes a 500-step road cost 200 steps.
38. Lucky hammer at rank 3 multiplies the Uncommon-or-better chances of a quality reroll by 1.45.

**Reset**
39. The first reset is free and returns every point.
40. The second reset costs 2,000 steps from the bank, and the third 4,000.
41. The price stops at 10,000.
42. After 35,000 steps walked since the last reset, the price is 2,000 lower.
43. The price never goes below 2,000.
44. After a reset paid at a fallen price of 2,000, the next reset costs 4,000.
45. A reset with too few steps in the bank is refused, and nothing changes.
46. A reset happens only in Camp.
47. A player with no ranks taken cannot reset.

**Screens**
48. Character has a Talents tab after Gear and Bag.
49. The Talents heading shows the points left.
50. A plate shows one pip per rank, with the taken ranks filled.
51. A closed row says at how many points it opens.
52. The talent sheet's Learn button takes a rank and fills a pip.
53. Ysolde shows in Camp's Here list, with a dot when points are left.
54. No screen says "Talents arrive in a later update."

**Save**
55. An old save loads with no ranks, 0 resets and its points to spend.
56. Ranks, resets and the steps since the last reset survive a save and a load.
57. A rank of a talent id that the data no longer holds is dropped on load, and its point comes back.
58. Each fixture in `app/test/fixtures/saves/` loads.

**Data**
59. The data check fails on a talent with an unknown effect.
60. The data check fails on a tree that holds fewer than 28 points.
61. The data check fails on a talent that needs a talent of another tree.

**Balance**
62. The sim results meet the targets of §5, and the plan records them.

**Check and release**
63. Rules, numbers and the save change only as this spec says. The pacing test passes.
64. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
