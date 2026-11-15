# Spec 0015: Talent trees

Status: accepted
Intent: [intent/0015-talent-trees.md](../intent/0015-talent-trees.md) (accepted)
Builds on:
- spec 0002 decision 7 (one talent point per level from 10);
- spec 0005 §3 (the quality roll);
- spec 0009 §2 (combat);
- spec 0010 §3.2 and §7.2 (profession steps, rerolls);
- spec 0014 §4.3 (the look of the talent screen);
- spec 0016 §2 (`queueSlots(state)`);
- spec 0017 §3.4 (rewards that add to the bank and the queue).
Overrides: the words "Talents arrive in a later update" on the level-up screen, in the news and on Character.
Product owner: Zkalf
Date: 2026-10-31

## Summary
- The player spends talent points in two trees, **Combat** and **Utility**.
- Each tree has six rows. Points spent in a tree open its next row, as in World of Warcraft Classic.
- Combat makes fights a bit faster and loot a bit better.
- Utility makes the day easier: a bigger bank, cheaper actions and travel, an extra queue slot, more profession XP,
  more bag spaces and better crafts.
- The player resets the trees at a trainer in Camp.
- The Talents tab shows both trees side by side, each as a grid of icons with lines between them.

## 1. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | The shape | **6 rows. Each 5 points spent in a tree open its next row** (owner). Row 6 opens at 25 points. Combat holds 30 points. Utility holds 33, and 38 with Bigger bag (spec 0021). The soft cap gives 28 points (level 37). |
| 2 | The last Combat talent | **Impale: critical hits deal 2.5× damage instead of 2×** (owner). From World of Warcraft. |
| 3 | The last Utility talent | **Wayfarer: travel costs half its steps** (owner). |
| 4 | The reset price | **2,000 steps more for each paid reset, up to a cap, and the price falls again with walking** (owner). The first reset is free. The numbers are in §2.6. |
| 5 | How the price falls | **By steps walked since the last reset**, not by days. The game rules count steps and know no calendar. 35,000 steps are about a week for the average walker. Claude's choice. |
| 6 | The trainer | **Ysolde, the Guild trainer**, in Camp. Lines in §2.7. Claude's choice. |
| 7 | Where to spend | **Anywhere** (intent outcome 22). Spending is instant and costs no steps. |
| 8 | Talent numbers | The sim tuned them to the targets of §5. They live in `talents.json`. §2.3 and §2.4 give them. |
| 9 | Percent stats | Attack, HP and Defense talents add a percent of the stats from level and gear, rounded down, like a meal (spec 0011 §5.3). |
| 10 | Rows and pips | Each talent is an icon on a grid, with its ranks on a badge (§3.1). The first version made each talent a **path** of spec 0014 §4.3. |
| 11 | Talents that need another talent | **Three, as in World of Warcraft Classic** (owner, 2026-10-31): Impale needs Keen eye, Lucky hammer needs Master crafter, Wayfarer needs Light pack, each with all its ranks (§2.1). The other talents need only their row. |

## 2. Rules

### 2.1 Points
- The player has the talent points of spec 0002 decision 7: one per level from level 10.
- Points left = points earned − ranks taken in both trees.
- A rank costs 1 point.
- A player takes a rank of a talent when:
  - a point is left;
  - the talent's row is open;
  - the talent has a rank left;
  - the talent that it needs, if any, has all its ranks (the table below).
- A row opens when the ranks taken in its tree reach its number: row 1 at 0, row 2 at 5, row 3 at 10, row 4 at 15,
  row 5 at 20 and row 6 at 25.
- Ranks stay until a reset (§2.6). The player cannot take one rank back.
- Three talents need another talent of their tree with all its ranks:

| Talent | Needs |
|---|---|
| Impale (Combat, row 6) | Keen eye 3/3 (row 2) |
| Lucky hammer (Utility, row 5) | Master crafter 3/3 (row 3) |
| Wayfarer (Utility, row 6) | Light pack 5/5 (row 4) |

- A talent works from the moment that the player takes it. It changes nothing that already happened: a running
  fight keeps its rounds paid, and a gear item keeps its quality.

### 2.2 How the bonuses count
- The talents of both trees add up.
- A percent talent on Attack, HP or Defense adds that percent of the stats from level and gear, rounded down. The
  meal and the feats do not count into it.
- A percent talent on steps multiplies with the tool and the meal, then rounds up, as spec 0010 §3.2 does.
- A talent on quality chances multiplies the chance of each quality above Common in the roll of spec 0005 §3, like
  the overlevel bonus. Common takes what is left.
- No talent changes the quality roll of the supply chest (spec 0013 decision 8).

### 2.3 Combat (30 points)

| Row | Opens at | Column | Talent | Ranks | Each rank | Full |
|---|---|---|---|---|---|---|
| 1 | 0 | 1 | **Might** | 5 | +0.8% Attack | +4% Attack |
| 1 | 0 | 3 | **Toughness** | 5 | +3% HP | +15% HP |
| 2 | 5 | 1 | **Guard** | 3 | +2% Defense | +6% Defense |
| 2 | 5 | 3 | **Keen eye** | 3 | +1 Crit | +3 Crit |
| 3 | 10 | 2 | **Swift strikes** | 5 | a fight costs 0.5% fewer steps | 2.5% fewer |
| 4 | 15 | 1 | **Precision** | 3 | +1 Hit | +3 Hit |
| 4 | 15 | 2 | **Evasion** | 2 | +1 Dodge | +2 Dodge |
| 5 | 20 | 2 | **Treasure hunter** | 3 | +10% quality chances on monster drops | +30% |
| 6 | 25 | 3 | **Impale** | 1 | critical hits deal 2.5× damage instead of 2× | |

- **Swift strikes:**
  - A round still costs `combatRoundSteps` (10).
  - When a fight ends, won or lost, the steps that it saves go back to the current action as progress: the steps of
    its rounds × the share, rounded down. They pay for the next round.
  - The fight log keeps its rounds.
  - It gives back its share of the base round only. The overload of a full bag is not given back (spec 0021
    decision 9).
  - The share of an Attack or HP meal adds up with it (spec 0011 amendment 2).
- **Treasure hunter** changes the quality of gear that a monster drops. It does not give more drops. Drop chances,
  first-kill drops and boss drops keep their chances (intent outcomes 9-10). Crafts and rerolls do not use it.
- **Impale** replaces `critDamage` (2) with 2.5 for the player's critical hits. Monsters keep 2.
- Crit, Hit and Dodge from talents count toward their caps (spec 0009 §2.1).

### 2.4 Utility (38 points)

| Row | Opens at | Column | Talent | Ranks | Each rank | Full |
|---|---|---|---|---|---|---|
| 1 | 0 | 1 | **Deep pockets** | 5 | +600 bank cap | +3,000 |
| 1 | 0 | 2 | **Bigger bag** (spec 0021) | 5 | +2 bag spaces | +10 |
| 1 | 0 | 3 | **Nimble hands** | 5 | gathering and crafting cost 1% fewer steps | 5% fewer |
| 2 | 5 | 1 | **Practised hands** | 3 | +2% profession XP | +6% |
| 2 | 5 | 2 | **Bountiful** | 5 | 3% chance that a gathering action gives one more of its item | 15% |
| 2 | 5 | 3 | **Wary** | 2 | a lost fight pays +10 points of its XP share; rank 1 also warns before orange fights | 0.75 → 0.95 |
| 3 | 10 | 1 | **Master crafter** | 3 | +10% quality chances on crafted gear and tools | +30% |
| 3 | 10 | 3 | **Quartermaster** | 1 | +1 queue slot | |
| 4 | 15 | 3 | **Light pack** | 5 | travel costs 4% fewer steps | 20% fewer |
| 5 | 20 | 1 | **Lucky hammer** | 3 | +15% quality chances on a reroll | +45% |
| 6 | 25 | 3 | **Wayfarer** | 1 | travel costs half its steps | |

The tree holds 33 points without Bigger bag and 38 with it.

- **Deep pockets, then Nimble hands:** row 1 keeps this data order. The sim walker takes the talents of a row in data
  order.
- **Bigger bag (spec 0021 §2.3):** `bigger_bag`, line "More bag spaces.", effect `bagSpaces`, value 2, image `bag`.
  A reset takes its ranks back like any other. The bag can then be over its spaces, and nothing is lost.
- **Nimble hands** works on gathering and crafting actions. Rerolls, fights and travel do not use it.
- **Practised hands:**
  - It multiplies the profession XP of each gathering and crafting action, after the fade, rounded down.
  - It does not change character XP.
  - Effect: `professionXp`.
  - It stands in row 2, next to Bountiful and Wary. In row 4 a Utility player got it after level 25, too late for
    target 6 of §5.
- **Bountiful** adds one of the spot's own item (`item`: ore, log, scale or hide), not a catch or a rare find. The
  roll uses the profession stream (spec 0010 §9.1), so it shifts no fight or drop.
- **Wary:** the lost-fight XP share of spec 0003 §5 (`lossXpShare`, 0.75) rises by 0.10 per rank. With rank 1, the
  deadly-fight warning also shows for orange monsters, not only for red and skull ones.
- **Master crafter** works on crafted gear and tools. Meals, materials and rerolls do not use it.
- **Light pack** and **Wayfarer** multiply: with both, a road costs 0.8 × 0.5 = 40% of its steps, rounded up.
- **Quartermaster** adds to `queueSlots(state)` (spec 0016 §2), as Chieftain's Bane does (spec 0017 §3.4).
- **Lucky hammer** works on a quality reroll (spec 0010 §7.2). A Legendary stat reroll (§7.3) does not use it.
- **A reroll uses Lucky hammer only.** Master crafter does not boost a reroll. With both, a reroll's
  chances multiply by 1.45, not by more.

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
  - The free first reset leaves the saved price at its start.
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
Camp's Here list shows **Ysolde, the Guild trainer** under the teachers. A tap on her opens a sheet:
- Greeting: "Steps make the body, {name}. Talents make the fighter."
- Before level 10: "Come back when the Guild names you Adventurer."
- From level 10: the points left and the reset button.
- The reset button: **Reset my talents** (free) or **Reset my talents · 4,000 steps**.
- The confirmation: "Reset every talent? Your points come back to spend again." with **Reset** and **Keep**.
- After a reset: "There. Walk a new road."
- The lines live in `talents.json`, like the teachers' lines.

### 2.8 Data
`packages/game_core/data/talents.json` holds:
- `rowEvery` (5), the trainer's lines and location, and the reset numbers of §2.6;
- the two trees, each with its id, name and line;
- each talent: id, tree, row, `column` (1-3), name, one line, ranks, image, and its effect with
  the value of one rank;
- for a talent that needs another one: `needs`, the id of that talent.

The effects are a closed list. Each one names what it changes:

| Effect | What it changes |
|---|---|
| `attackPercent`, `hpPercent`, `defensePercent` | the stats (§2.2) |
| `crit`, `hit`, `dodge` | the stats, in points |
| `fightSteps` | the share of a fight's steps that comes back |
| `dropQuality` | the quality chances of monster drops |
| `critDamage` | the player's critical damage |
| `bankCap` | the bank cap, in steps |
| `bagSpaces` | the bag spaces (spec 0021) |
| `professionSteps` | the steps of gathering and crafting |
| `professionXp` | the profession XP of gathering and crafting |
| `extraGather` | the chance of one more item at gathering |
| `lossXpShare` | the lost-fight XP share; rank 1 warns before orange fights |
| `craftQuality` | the quality chances of crafted gear and tools |
| `queueSlot` | the queue slots |
| `travelSteps` | the steps of travel (Light pack: a share off; Wayfarer: half) |
| `rerollQuality` | the quality chances of a reroll |

The data check fails when:
- a talent names an unknown tree or effect;
- a row is not 1-6;
- a talent has fewer than 1 rank;
- a talent needs a talent of another tree, of its own row or a lower one, or an unknown talent;
- a tree holds fewer points than the soft cap gives (28);
- the reset numbers are not positive, or the cap is lower than the base;
- a talent has no column, or a column that is not 1-3;
- two talents of one tree have the same row and column;
- a talent sits in another column than the talent that it needs;
- a talent sits in the same column between a talent and the talent that it needs (a line would run through it).

## 3. Screens

### 3.1 Character: Talents
Character has a third tab, **Talents**, after Gear and Bag (spec 0008 §3.5).

**Both trees at once**
- The Talents tab shows Combat on the left and Utility on the right, 6 dp apart. Row 1 of both trees stands at the
  same height.
- Each tree is a plate of its own (radius 16, the 1 dp teal hairline of spec 0014 §2.2). No plate stands around both
  trees.
- Each plate has a title bar in deep teal (`#17292C`) with the tree's name and ranks in teal small caps:
  "Combat · 12". There are no tree tabs.
- The Talents tab shows no line of a tree under the title. `talents.json` keeps the line.

**Points**
- The Talents tab shows no "points left" heading. The Character header says it: "3 talent points to spend".
- The header's line is teal and in body text, not small text, so that a player does not miss it. With no points
  left, the header shows no line.
- Before level 10, the Talents tab says "Talents open at level 10.", because the header says nothing of talents then.

**The grid**
- Each tree shows its talents as icons on a grid of 6 rows and 3 columns. Row 1 is at the top.
- Each talent has its own place: its row and its column (§2.3, §2.4). An empty place shows nothing.
- The grid scrolls when it does not fit on the screen.
- Each row is as tall as the longest name of that row in either tree.

**The icon**
- The talent's image sits in a dark socket, with radius 12.
- The socket is 56 dp at most, and 16 dp narrower than its column. The image is 57% of the socket.
- A badge with the ranks ("2/5") hangs off the lower right corner, 4 dp past the socket's right edge, in the style of
  the count badge (spec 0014 §2.3).
- The talent's name stands under the icon in muted text, on at most 2 lines.
- In a column narrower than 90 dp, the name is 11 dp, with a line height of 1.2. A name may use 4 dp more than its
  column. A name whose longest word does not fit is smaller, so that no word breaks.
- The talent's line ("+0.8% Attack") is not on the grid. The talent sheet shows it.

**The states of an icon**

| State | When | Look |
|---|---|---|
| Closed | its row is not open, or the talent it needs does not have all its ranks | the image at 40% opacity; a faint badge |
| Open | not closed, ranks left to take, and no points left | the image in full; no ring |
| Can learn | not closed, ranks left to take, and points left | a 1 dp teal hairline around the socket |
| Full | all ranks taken | a 2 dp teal ring; the badge in teal |

- An icon with at least 1 rank and not full shows its badge number in teal.
- A closed row shows only its dim icons. The grid shows no "Opens at" line.

**The lines**
- A line joins a talent to the talent that it needs: Keen eye to Impale (Combat column 3), Master crafter to Lucky
  hammer (Utility column 1), Light pack to Wayfarer (Utility column 3).
- The line is a 2 dp plain stroke. It runs straight down the column, from the lower edge of the needed talent to the
  upper edge of the talent that needs it.
- The line is faint (`#7F8A90`) until the needed talent has all its ranks. Then it is teal.
- The screen draws no other lines between talents.
- No blur and no shadow (`CLAUDE.md`, #121).

**The talent sheet**
A tap on an icon opens a sheet:
- the name, the line and the rank: "Rank 2 of 5";
- what it gives now and at the next rank: "Now: +4% Attack · Next: +6% Attack";
- what the talent needs, under "Now: … · Next: …":
  - for a talent in rows 2-6: "Needs 25 points in Combat (13/25)". The first number is `rowOpensAt` of its row. The
    count in brackets is the ranks in the tree, at most the number needed;
  - for a talent with `needs`: "Needs 3 ranks of Keen eye (2/3)", with the ranks of the needed talent;
  - a talent of row 1 with no `needs` lists nothing;
- the colours of the needs:
  - a need that the player does not meet is red (`Quiet.short`, `#E08A7C`);
  - a need that the player meets is green (`Quiet.met`, `#8FC98A`, a colour for this use only);
- learn or why not:
  - when a need is not met, the sheet shows no Learn button and no other line why not. The red line says why;
  - when each need is met, the sheet shows **Learn · 1 point** (a slate button), or "No points left" or "All ranks
    taken".
- When a rank is refused, the message (`whyNotRank`) reads: "Opens at 20 points in Utility. You have 13/20."

The stat sheets on Character say how much of a stat comes from talents (spec 0009 §8.5).

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
- `resetPrice`: the saved price of the next paid reset (§2.6). A new or an old save has 0, which means the base price
  of the data (`resetBase`, 2,000). The price that the player pays does not change.
- `walkedSinceReset`: the steps walked since the last reset. An old save loads with 0.
- An old save keeps its points: the level earns them. The player can spend them at once.
- A talent id that the data no longer holds is dropped on load, and its points come back.
- Each fixture in `app/test/fixtures/saves/` loads.

## 5. Balance
Talents change where steps go, so a hand-run sim checked the pace (intent constraint). The first §5 compared the
builds at level 25, but every build reached it on about day 70: crafting, travel and the safe monsters decide that
race, not the talents. Amendment 1 replaced it with the parts below.

**The builds.** The walker spends each point at once, in a fixed order:
- **Combat:** Combat only, row by row.
- **Utility:** Utility only, row by row.
- **Split:** Might and Toughness first, then Deep pockets, Nimble hands, Quartermaster, then the rest of Combat.

**The two parts.** Each part is the mean of 12 seeds, at 5,000 steps a day:
- **Part A, the whole game:** a new character, 120 days, for each of the four builds (none, Combat, Utility, Split).
- **Part B, full builds:** the no-talent walker of part A on day 120 (about level 37, 28 points). Each build takes
  its points in its order, then plays 60 more days.

**The targets**
1. Part B: Combat gains 10-15% more XP than Utility.
2. Part B: Combat finds at least as many Rare-or-better monster drops as Utility.
3. Part B: no build gains more than 2% less XP than no talents.
4. Part A: on day 50, Combat has more XP than Utility.
5. Part A: on day 50, no build has more than 2% less XP than no talents.
6. Part A: on day 60, the profession levels of the Utility build add up to more than with no talents.
7. No-talent pace stays as it is: the pacing test passes.

**The record.** [`plans/0031-talent-trees.results.md`](../plans/0031-talent-trees.results.md) records parts A and B
and each number that the sim moved. All 7 targets were met, with Combat +13.2% over Utility in full builds
(the numbers of amendment 2).

## 6. Out of scope
- More than two trees.
- Talents for each profession.
- Talents that the player uses by hand.
- Talent points from anything but levels.
- A find chance from gear.
- Prerequisites between talents other than the three of §2.1.
- Arrow heads, curved lines and lines across columns. The straight lines of §3.1 replaced "arrows drawn between
  plates".
- New art for each talent is a separate issue (#198).

## 7. Acceptance criteria
A replaced criterion says what replaced it.

**Points and rows**
1. A level 9 player has 0 points, and a level 12 player has 3.
2. A rank costs 1 point.
3. A rank cannot be taken with 0 points left.
4. A row 2 talent cannot be taken with 4 ranks in its tree.
5. A row 2 talent can be taken with 5 ranks in its tree.
6. Ranks in Utility do not open Combat rows.
7. A talent cannot take more ranks than it has.
8. The Combat tree holds 30 points, and the Utility tree holds 33 without Bigger bag (spec 0021) and 38 with it.
9. Impale cannot be taken with Keen eye at rank 2, even with its row open.
10. Impale can be taken with Keen eye at rank 3 and its row open.
11. Lucky hammer cannot be taken before Master crafter has rank 3.
12. Wayfarer cannot be taken before Light pack has rank 5.
13. Replaced by criteria 77-104 (the grid), and the needs on the sheet by criteria 111-118.

**Combat effects**
14. Might at rank 5 adds 4% of the level-and-gear Attack, rounded down.
15. Toughness at rank 5 adds 15% of the level-and-gear HP, rounded down.
16. Guard at rank 3 adds 6% of the level-and-gear Defense, rounded down.
17. Keen eye, Precision and Evasion add their points to Crit, Hit and Dodge, within the caps.
18. With Swift strikes at rank 5, a won fight of 6 rounds gives 1 step back to the action (60 × 0.025, rounded
    down).
19. With Swift strikes, a lost fight also gives its steps back.
20. Treasure hunter at rank 3 multiplies the Uncommon-or-better chances of a monster drop by 1.3.
21. Treasure hunter does not change the drop chance of any item.
22. Treasure hunter does not change crafted quality.
23. With Impale, the player's critical hit deals 2.5× damage.
24. With Impale, a monster's critical hit still deals 2×.

**Utility effects**
25. Deep pockets at rank 5 adds 3,000 to the bank cap.
26. Nimble hands at rank 5 makes a 100-step gathering action with a starter tool cost 95 steps.
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
38. Lucky hammer at rank 3 multiplies the Uncommon-or-better chances of a quality reroll by 1.45. Criterion 75 adds
    to it.

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
49. Replaced by criteria 121-128.
50. Each icon shows a badge with its ranks taken and its ranks ("2/5").
51. Replaced by criteria 105-106.
52. The talent sheet's Learn button takes a rank. Criterion 88 says how the icon shows it.
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
62. The sim results meet the targets of §5, and the results file of plan 0031 records them.

**Check and release**
63. Rules, numbers and the save change only as this spec says. The pacing test passes.
64. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

**Practised hands and the sim**
65. Moved to criterion 8.
66. Practised hands at rank 3 gives 6% more profession XP from an action, rounded down.
67. Practised hands does not change the character XP of an action.
68. Moved to criterion 62.
69. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

**The tuned numbers**
70. Moved to criterion 14.
71. Moved to criterion 18.
72. Moved to criterion 26.
73. Moved to criterion 66.
74. Practised hands is a row 2 talent.
75. A quality reroll with Master crafter at rank 3 and Lucky hammer at rank 3 multiplies the Uncommon-or-better
    chances by 1.45, not by more.
76. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

**The grid**
- The grid:
  77. The Talents tab shows the talents of each tree as icons on a grid of 3 columns.
  78. Each icon stands at the row and column of its talent in the data.
  79. Each icon shows the talent's name under it.
  80. Moved to criterion 50.
  81. No icon shows the talent's line. The talent sheet shows it.
  82. A tap on an icon opens the talent sheet of that talent.
- The states:
  83. An icon of a closed row shows its image at 40% opacity.
  84. An icon of a talent whose needed talent does not have all its ranks shows its image at 40% opacity.
  85. An icon of a talent that the player can take a rank of now has a teal hairline.
  86. An icon with all its ranks taken has a teal ring.
  87. An icon of an open row, with ranks left to take and no points left, has no ring.
  88. Learn on the talent sheet raises the number on the icon's badge by 1.
- The lines:
  89. A line joins Keen eye and Impale.
  90. A line joins Master crafter and Lucky hammer.
  91. A line joins Light pack and Wayfarer.
  92. A line is faint while the needed talent does not have all its ranks.
  93. A line is teal when the needed talent has all its ranks.
  94. No line joins two talents where neither needs the other.
- Closed rows:
  95. Replaced by criterion 106.
  96. Replaced by criterion 106.
  97. Replaced by criterion 106.
- Data:
  98. Each talent in `talents.json` has a column from 1 to 3.
  99. The data check fails on a talent with column 4.
  100. The data check fails on two talents of one tree at the same row and column.
  101. The data check fails on a talent in another column than the talent it needs.
  102. The data check fails on a talent that sits on the line between two other talents.
- Check and release:
  103. Rules, numbers and the save do not change. The pacing test passes.
  104. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

**The tree line and closed rows**
105. The Talents tab does not show the line of a tree.
106. The grid shows no "Opens at" line, with closed rows or without.
107. Replaced by criteria 111-118.
108. The sheet of a talent in a closed row says "Needs 5 points in Combat (0/5)" with no ranks in its tree.
109. Rules, numbers and the save do not change. The pacing test passes.
110. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

**The needs on the talent sheet**
111. The sheet of Guard with 4 ranks in Combat says "Needs 5 points in Combat (4/5)" in red.
112. The sheet of Guard with 7 ranks in Combat says "Needs 5 points in Combat (5/5)" in green.
113. The sheet of Impale with Keen eye at rank 2 says "Needs 3 ranks of Keen eye (2/3)" in red.
114. The sheet of Impale with Keen eye at rank 3 says "Needs 3 ranks of Keen eye (3/3)" in green.
115. The sheet of Impale lists both needs: the points in Combat and Keen eye.
116. The sheet of Might lists no needs.
117. The sheet of a talent with a need not met shows no Learn button.
118. The sheet of a talent with each need met and a point left shows the Learn button.
119. Rules, numbers and the save do not change. The pacing test passes.
120. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

**Both trees at once**
121. The Talents tab shows the talents of both trees at once.
122. The Utility tree stands to the right of the Combat tree, with its row 1 at the height of Combat's.
123. The Talents tab has no switch between the trees.
124. Each tree has a title bar with its name and its ranks: "Combat · 0".
125. No plate stands around both trees.
126. Before level 10, the Talents tab says "Talents open at level 10."
127. From level 10, the Talents tab shows no "points left" line, and the Character header shows the points.
128. The header's line of talent points to spend is teal.
129. Rules, numbers and the save do not change. The pacing test passes.
130. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

**Reset, not Forget**
131. Ysolde's sheet says "Reset my talents", and "Reset my talents · 2,000 steps" for a paid reset.
132. The confirmation asks "Reset every talent? Your points come back to spend again." with Reset and Keep.
133. No screen of the trainer says "Forget".
134. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

Spec 0021 has the criteria of Bigger bag (its criteria 27-29).

## History
- 2026-10-31: first version (intent 0015, plan 0031). Criteria 1-64.
- 2026-10-31, amendment 1 (#55): the sim measures full builds; Utility gets Practised hands; Combat holds 30 points.
  Decision 1; §2.4; §2.8; §5; criteria 8, 62 and 65-69.
- 2026-10-31, amendment 2 (#55): the numbers that the sim tuned; Practised hands in row 2; a reroll uses Lucky hammer
  only; the saved reset price starts at 0. §2.3; §2.4; §4; §5; criteria 14, 18, 26, 66 and 70-76.
- 2026-11-01, amendment 3 (#153, plan 0032): the talents look like a tree: a grid of icons, with lines. §2.3; §2.4;
  §2.8; §3.1; §6; criteria 13, 50, 51 and 77-104.
- 2026-11-01, amendment 4 (#153): fewer words on the tree, the points on the sheet. §3.1; criteria 95-97 and 105-110.
- 2026-11-01, amendment 5 (#153): the talent sheet lists what a talent needs, in red or green. §3.1 "The talent
  sheet"; criteria 107-108 and 111-120.
- 2026-11-01, amendment 5 erratum 1: the row need is for rows 2-6, not "above row 1". §3.1 "The talent sheet".
- 2026-11-01, amendment 6 (#153): both trees side by side, each a card; the points in the Character header. §3.1;
  criteria 49 and 121-130.
- 2026-11-01, amendment 7 (#157, plan 0036): Ysolde says "Reset", not "Forget". §2.7; criteria 131-134.
- 2026-11-02, spec 0021 (#173): the Utility talent Bigger bag; Swift strikes gives back no overload. Decision 1;
  §2.3; §2.4; §2.8; criterion 8.
- 2026-11-15 (plan 0068): the amendments, the erratum and clean edition 1 folded into this file. Criteria 8, 14, 18,
  26, 50, 62 and 66 hold again the text that replaced them; 65, 68, 70-73 and 80 point there. No rule or number
  changed.
