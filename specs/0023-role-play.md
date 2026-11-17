# Spec 0023: Role-play, chapter 1: The King Who Would Not Rest

Status: accepted
Intent: [intent/0023-role-play.md](../intent/0023-role-play.md) (accepted, 2026-11-17)
Builds on: spec 0008 §3.2 (Here), spec 0009 §7.2 (lore notes), spec 0010 §6 (teachers), spec 0011 §6 (Smugglers'
Cove), spec 0012 (origins), spec 0015 §2.7 (the trainer), spec 0017 (achievements), spec 0022 (Odda)
Product owner: Zkalf (accepted on 2026-11-17)
Date: 2026-11-17

The south of the river gets a story. Four people out in the world and at Camp talk to the hero, and their words move
on with the hero's deeds. The hero finds lore pages that tell the story of each place. The first chapter ends when
the Graveyard King falls and says that the dragon wakes.

## 1. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | The threat | **The Young Dragon wakes on Dragon's Peak** (owner, intent 0023). Each boss is one chapter. |
| 2 | Chapter 1 | **"The King Who Would Not Rest"** (owner, 2026-11-17): the dragon's stir wakes the dead King first. |
| 3 | The new people | **Pell, Aldous and Jory Tarr** (owner, 2026-11-17), and **Odda** gets a row at Camp (§2.1). |
| 4 | Where the player meets a person | **A row under Here at the person's place**, as the teachers at Camp (intent 0023 outcomes 14-17). |
| 5 | Pictures | **Flat SVG portraits by Claude** (owner). nabriis can replace them with real art later. |
| 6 | The first build | **The south of the river** (owner). |
| 7 | Lore achievements | **One for each place of the south** (owner), as a milestone with +250 bank cap (§2.6). |
| 8 | Choices | **None** (owner). The player reads and listens. |
| 9 | What moves the story on | **Deeds that the save counts today:** the start, a first visit, a kill count, a first boss kill and the character level (§2.3). No new counter. |
| 10 | The story card | **No change** (spec 0008 §3.2). The first-visit page goes to the report and the Lore tab instead. |
| 11 | The old lore notes | **They stay as they are.** The Lore tab groups them by the place of the monster that they are about. |
| 12 | Pictures at Camp | **The six teachers and Ysolde get portraits too** (owner, 2026-11-17), so every person at Camp shows a face (§3.6). |

## 2. Rules

### 2.1 People
- A **person** is a named character with a place, a picture and lines (`data/story.json`).
- The first build has four people:

| Id | Name and title | Place | Who they are |
|---|---|---|---|
| `odda` | Odda, the quartermaster | Camp | She runs the Guild camp and keeps its ledger. She leads the camp tour today (spec 0022). |
| `pell` | Pell, the charcoal burner | Goblin Woods | An old man who has lived alone in the woods for forty years. Gruff and kind. |
| `aldous` | Aldous, the sexton | Old Graveyard | The keeper of the graveyard for fifty years. Tired and a little frightened. |
| `jory` | Jory Tarr, the smuggler | Smugglers' Cove | He sells rumours and never gives a straight answer. He hides something for a later chapter. |

- No other character in the data has these names. A data test checks that no two people, teachers or trainers share
  a name.
- The six teachers and Ysolde stay as they are. They get one new line each (§2.5) and a portrait (§3.6).

### 2.2 Lines
- Each person has a list of **lines** in data order.
- A line can have a **condition** (§2.3). A line without a condition is open from the start.
- A line can have an **origin**. It is open only for a hero of that origin.
- A line can give a **lore page** (§2.4).
- A line is **open** when its condition holds and its origin fits.
- A line is **heard** when the player opens the person's sheet while the line is open.
- When the player opens a sheet, every open line of that person becomes heard. The game gives the lore page of each
  of these lines.
- An open line that is not heard puts a dot on the person's row (§3.1).
- A heard line stays heard. A condition never closes again: the counters only grow.
- The newest line is the open line that stands last in data order.

### 2.3 Conditions
A condition is one of the kinds of spec 0017 §3.1 that the save counts today:

| Kind | Example | Reads |
|---|---|---|
| A counter, at least a number | after the first visit to Old Graveyard | `visited.old_graveyard` at least 1 |
| | after 50 Goblin kills | `kills.goblin` at least 50 |
| | after the first King kill | `kills.graveyard_king` at least 1 |
| The level, at least a number | at level 10 | the character level |

The data uses the same shape as a criterion in `achievements.json`.

### 2.4 Lore pages
- A **lore page** is a piece of lore about a place or the story. It belongs to one place.
- A lore page comes from one of these sources:

| Source | When the game gives the page |
|---|---|
| The start | On a new game, and when an old save loads (§4). |
| A first visit | When the character first stands in the place. |
| A deed | When a condition of §2.3 first holds, such as the first King kill. |
| A line | When the player hears the line (§2.2). |
| A find | By chance, after a fight or a gathered item in the place (below). |

- **A find:** after each fight and each gathered item in the place, the game rolls for the place's find page.
  - The chance is `pageChance`, 1% (`data/story.json`).
  - The game rolls only until the page is found.
  - The roll uses a generator derived from the unit, as the lore note roll does (spec 0009 §7.2, `run.dart`). So it
    never shifts the fights, the loot or the gathering after it.
- Each page is found once. The save keeps it in the same set as the lore notes (`lore`).
- The report names a page that the hero found while they walked: "Found a lore page: The sexton's ledger". A page
  from a line shows on the person's sheet instead (§3.2).
- A page gives no XP, no item, no gold and no knowledge of a monster. Only lore notes and tips reveal an armour and a
  weakness.

### 2.5 Camp after the King
- After the first King kill, each teacher and Ysolde has a **King line**.
- The King line replaces the greeting at the top of the sheet. For the teacher of the hero's origin, it replaces the
  kin line.
- The King line works as a line of §2.2: it is open after the first King kill, and it puts a dot on the row until
  the player opens the sheet.
- The learn line and **Learn** stay as they are (spec 0010 §6.1).
- Odda's own lines are in §2.7.

### 2.6 Lore achievements
- Each place of the south gets one achievement: **all the lore of the place is found**.
- The lore of a place is:
  - its lore pages;
  - the lore notes about the monsters of the place.
- Each is a milestone with +250 bank cap. A new criterion kind reads the lore of a place: `{ "lore": "<place>" }`.

| Id | Name | Stage | Place | Lore |
|---|---|---|---|---|
| `lore_camp` | Guild Archivist | early | Camp | 2 pages |
| `lore_goblin_woods` | Woodland Tales | early | Goblin Woods | 3 pages, 2 notes |
| `lore_old_graveyard` | Keeper of Graves | early | Old Graveyard | 4 pages, 2 notes |
| `lore_copper_hills` | Carved in Stone | early | Copper Hills | 2 pages |
| `lore_mirror_lake` | Still Waters | early | Mirror Lake | 2 pages |
| `lore_smugglers_cove` | Smuggler's Tale | mid | Smugglers' Cove | 3 pages |

- The notes about Goblin Woods' monsters: Brute's hide (Goblin brute) and Bear sign (Old Bear). No note is about the
  Goblin.
- The notes about Old Graveyard's monsters: Gravedigger's note (Zombie) and The King's armour (Graveyard King). No
  note is about the Skeleton.
- The places north of the river get their achievements when their pages come, in a later chapter.

### 2.7 The words
The words are a design decision (`WRITING.md`). The owner accepts them with this spec. `{name}`, `{son|daughter|child}`
and `{lad|lass|friend}` fill in as today (spec 0012).

**Odda, the quartermaster (Camp)**

| Id | Condition | Gives | Line |
|---|---|---|---|
| `odda_1` | none | | "The dead walk in the Old Graveyard, {name}. They haven't done that in a hundred years. The Guild wants to know why. So do I." |
| `odda_2` | first visit to Old Graveyard | | "You've seen them, then. Skeletons in the old King's colours. Aldous the sexton still lives out there. If anyone knows why, he does." |
| `odda_3` | first King kill | Odda's ledger | "The King is down, and the road north is open. Whatever he said at the end, I've written it down. The Guild will want to hear it." |

**Pell, the charcoal burner (Goblin Woods)**

| Id | Condition | Gives | Line |
|---|---|---|---|
| `pell_1` | none | | "Forty years I've burned charcoal in these woods. Goblins were always here. Never this many, and never this bold." |
| `pell_kin` | origin: woodcutter's child | | "A woodcutter's {son|daughter|child}, are you? Then you've heard it too. The woods have gone quiet. The birds left first." |
| `pell_2` | 50 Goblin kills | Pell's story | "They're not raiding, {name}. They're running. Something up north drives them south, and they push everything before them." |
| `pell_3` | first King kill | | "Heard the King fell. The goblins heard too. They're still running, though. Whatever's up north didn't fall with him." |

**Aldous, the sexton (Old Graveyard)**

| Id | Condition | Gives | Line |
|---|---|---|---|
| `aldous_1` | none | | "Mind the graves, {name}. Fifty years I've kept them. I never thought I'd have to keep them shut." |
| `aldous_2` | 25 Skeleton kills | Aldous's story | "Those are his own guard, you know. They followed him to the Peak and back, and into the ground. They wake when he wakes." |
| `aldous_3` | first King kill | | "You laid him down again. Thank you. He spoke at the end, didn't he? He always did talk of the dragon." |

**Jory Tarr, the smuggler (Smugglers' Cove)**

| Id | Condition | Gives | Line |
|---|---|---|---|
| `jory_1` | none | | "Nobody finds this cove by chance, friend. So who sent you? No, don't tell me. I sell secrets. I don't buy them." |
| `jory_kin` | origin: fisher from the coast | | "Coast folk. You'll keep your mouth shut, then. Coast folk always do." |
| `jory_2` | first King kill | | "The King's dead? Then the north road is open, and my old cargo moves again. Crates for the Peak, friend. Don't ask what's in them." |
| `jory_3` | level 10 | Jory's story | "You've made a name. The captain who sank off my jetty had a name too. Want to hear it? It'll cost you nothing. This time." |

**The King lines (Camp, after the first King kill)**

| Who | Line |
|---|---|
| Hilde | "The King, {name}? Under the hills we'll drink to that." |
| Bram | "The woods feel lighter since the King fell. Not the goblins, mind." |
| Wen | "They say the river runs clearer with the King gone. The fish don't care. I do." |
| Sigrun | "You walked soft and hit hard. The King never heard you coming." |
| Garrow | "Full plate, they said, and you cracked it. Bring me a piece. I'd like to see that steel." |
| Marta | "The King's Bane eats free tonight, {name}." |
| Ysolde | "One king down. Steps made that, {name}. Steps and talents." |

**The lore pages**

| Id | Place | Source | Title | Text |
|---|---|---|---|---|
| `page_charter` | Camp | the start | The Guild's charter | Pinned to the notice board: "The Guild takes any hand that can hold a blade or a pick. Pay in coin, or pay in stories. The lands south of the river are ours to keep." |
| `page_odda_ledger` | Camp | line `odda_3` | Odda's ledger | A new line in Odda's neat hand: "{name}: the Graveyard King, laid to rest. His last words: it wakes. Sent word north." |
| `page_goblin_tally` | Goblin Woods | first visit | Goblin tally | A stick dropped by a goblin. Rows of little running feet are carved on it, and above them a great burning eye. |
| `page_pell` | Goblin Woods | line `pell_2` | Pell's story | What Pell told you: "My grandfather was a boy the year the King rode north. The woods burned to the river that summer. Now the goblins smell the same smoke he did." |
| `page_hunter_1` | Goblin Woods | a find | Hunter's book, page 1 | A page torn from a hunter's book: "Day one. The King rides north with three hundred spears. I go with them, to see a dragon and live to write of it." |
| `page_sexton_ledger` | Old Graveyard | first visit | The sexton's ledger | The first page of an old ledger: "Buried this day: His Majesty, in his plate, with his guard around him. The dragon lives. May the graves stay shut." |
| `page_kings_words` | Old Graveyard | the first King kill | The King's last words | As the King falls, a voice rises from the helm: "It wakes. A hundred years I held it. It wakes..." |
| `page_aldous` | Old Graveyard | line `aldous_2` | Aldous's story | What Aldous told you: "Fifty years I've heard them under the turf, turning. Waiting for him. I used to think it was the wind." |
| `page_hunter_2` | Old Graveyard | a find | Hunter's book, page 2 | "The King swore over his father's grave: no dragon would burn his lands while he drew breath. He kept his word. In his way." |
| `page_miners_carving` | Copper Hills | first visit | Miner's carving | Cut into the rock above the old copper vein: a dragon with its wings spread, and under it one word: HIDE. |
| `page_hunter_3` | Copper Hills | a find | Hunter's book, page 3 | "We dug in under the hills to wait out its flight. The miners say the rock stayed warm for a week after it passed." |
| `page_reed_charm` | Mirror Lake | first visit | Reed charm | A charm of woven reeds on a post at the shore: "For the eleven who came home." |
| `page_hunter_4` | Mirror Lake | a find | Hunter's book, page 4 | "We came back across the lake, eleven of three hundred, with the King on a shield. The water showed us what we had become." |
| `page_manifest` | Smugglers' Cove | first visit | Smuggler's manifest | A manifest, the ink run: "Twelve crates, sealed. Rope, salt, lamp oil. One cage, large, iron, empty." |
| `page_captains_log` | Smugglers' Cove | a find | The captain's log | Log of the Gull, the last entry: "Cargo for the Peak, paid in old gold. The crew won't say whose. Storm rising. If this book is found, burn the manifest." |
| `page_jory` | Smugglers' Cove | line `jory_3` | Jory's story | What Jory told you: "The Gull sank off this jetty with cargo for the Peak, paid in old gold. Whose gold? Ask the King. Oh, wait." |

- The hunter's book ends with the note that the Young Dragon drops today: "The dragon-hunter's last page" (spec 0009
  §7.2). That note does not change.
- The finds of Copper Hills and Mirror Lake come only from gathering, because these places have no monsters.

## 3. Screens

### 3.1 The row of a person
- A person shows as a row under Here at their place (spec 0008 §3.2).
- The row shows the person's portrait and "Pell, the charcoal burner".
- At Camp, Odda's row stands after the trainer's row. Out in the world, the person's row stands first in Here.
- A dot on the row shows an open line that is not heard (§2.2), as the dot of a waiting tip does today.
- A tap on the row opens the person's sheet.
- Jory's row shows only after the cove is revealed, as the cove itself (spec 0011 §6.2).

### 3.2 The sheet of a person
- The sheet shows, from the top:
  1. the portrait and "Pell, the charcoal burner";
  2. the newest line, in italics, in quotes;
  3. "New lore page: Pell's story", if this opening gave a page;
  4. "What Pell told you": the other heard lines, newest first.
- A tap on "New lore page" opens the Lore tab.
- The sheet of a teacher or Ysolde shows the King line in place of the greeting (§2.5). The rest of the sheet does
  not change.

### 3.3 The Lore tab
- The Lore tab groups its lore by place, in the order of `world.json`.
- Each group has a heading with the place and "found N of M", for example "Goblin Woods · 2 of 5".
- Under the heading stand the lore pages and the lore notes of the place:
  - a found page or note shows its picture, its title and its text;
  - a page or note that is not found shows the placeholder and "Not found yet".
- A page shows a page picture. A note keeps its picture of today. Claude draws the page picture as a flat SVG.
- A hidden place has no group until it is revealed (spec 0011 §6.2).
- The teachers' tips stay below the groups, as today.
- The line "N of M found" at the top counts all pages and notes.

### 3.4 The report
- A page from the start, a first visit, a deed or a find shows in the report: "Found a lore page: <title>". It also
  goes into the Journal, as a found lore note does.
- The Journal names a page from a line in the same way, at the time of the opening.

### 3.5 Look
- The portraits are flat SVG, in the style of the game's icons today (`art/README.md`).
- Each portrait differs in its shape and colours, so the player can tell all eleven people apart at a glance: the
  four people of §2.1, the six teachers and Ysolde.
- Before the PR, the Now tab at Goblin Woods with Pell's row, Pell's sheet and the Lore tab are rendered at 408 dp
  wide (`CLAUDE.md`).

### 3.6 The portraits at Camp
- Each teacher's row under Here shows the teacher's portrait at 32 dp, in place of the picture of the profession.
- Ysolde's row shows her portrait at 32 dp, in place of the trainer icon.
- The subtitles stay: "Cooking 12" or "Teaches Cooking" on a teacher's row, "Talents" on Ysolde's.
- The sheet of a teacher and Ysolde's sheet show the portrait at 72 dp and the name at the top, as a person's sheet
  does (§3.2).
- The Professions tab and the profession screens keep the pictures of the professions.
- Before the PR, the Now tab at Camp with all eight rows of people and one teacher's sheet are rendered at 408 dp
  wide.

## 4. Save
- A new set `heard` keeps the heard lines, King lines included. An old save starts it empty.
- Lore pages go into the set `lore`, beside the lore notes.
- The save version goes from 16 to 17.
- When an old save loads, the game gives each page whose source has already happened: the start, first visits and
  deeds. It gives them without a report. Finds and lines wait for play.
- Old saves see the dots of the lines that are open for their deeds.
- Each fixture in `app/test/fixtures/saves/` loads.

## 5. Balance
- Pages and lines give no XP, no items and no gold.
- The six lore achievements give +250 bank cap each. The sim walker never opens a sheet, so it can earn only Carved in
  Stone and Still Waters.
- The find rolls use derived generators, so they shift no fight, loot or gathering.
- No sim targets. The pacing test stays green.
- The pacing test of spec 0017 §8 lets the walker miss the six lore milestones, as it lets it miss Smuggler's Secret
  and King's Bane today.

## 6. Out of scope
- Quests (#274, a later intent).
- The places north of the river, and their people and pages.
- Choices and dialogue trees.
- Voices, sound and cut scenes.
- A change to the story card.
- A change to the lore notes and the tips.
- Real art: nabriis can replace the portraits later.

## 7. Acceptance criteria

**People**
1. Odda's row shows under Here at Camp, after the trainer's row.
2. Pell's row shows first under Here at Goblin Woods.
3. Aldous's row shows first under Here at Old Graveyard.
4. Jory's row shows first under Here at Smugglers' Cove.
5. Jory's row does not show before the cove is revealed.
6. Each row shows the person's portrait and their name and title.
7. A tap on a row opens the person's sheet.
8. No two characters in the data share a name (data test).

**Lines**
9. A line without a condition is open on a new game.
10. A line with a condition opens when the condition first holds.
11. An origin line is open only for a hero of that origin.
12. A row shows a dot while an open line is not heard.
13. Opening the sheet makes every open line of that person heard.
14. After the sheet opens, the row shows no dot until a new line opens.
15. The sheet shows the newest open line at the top.
16. The sheet lists the other heard lines under "What <name> told you", newest first.

**Camp after the King**
17. Before the first King kill, a teacher's sheet shows the greeting or kin line of today.
18. After the first King kill, each teacher's sheet shows its King line at the top.
19. After the first King kill, Ysolde's sheet shows her King line at the top.
20. A King line puts a dot on the row until the sheet opens.
21. The learn line and Learn do not change.

**Lore pages**
22. A new game has The Guild's charter.
23. The first visit to a place gives its first-visit page.
24. The first King kill gives The King's last words.
25. Hearing a line that gives a page adds that page to the lore.
26. The sheet shows "New lore page: <title>" when the opening gave a page.
27. A find page rolls at `pageChance` after each fight and each gathered item in its place (seeded test).
28. A find page rolls no more once found.
29. A find roll does not change the fights, loot or gathering that follow it (same results with and without the
    roll, seeded test).
30. Each page is found at most once.
31. The report names a page from the start, a first visit, a deed or a find: "Found a lore page: <title>".
32. A found page goes into the Journal.
33. A page gives no XP, no item and no gold.

**The Lore tab**
34. The Lore tab groups lore by place, in the order of `world.json`.
35. Each group heading shows the place and "found N of M".
36. A found page shows its picture, title and text.
37. A page or note that is not found shows the placeholder and "Not found yet".
38. Smugglers' Cove has no group before it is revealed.
39. The teachers' tips still show below the groups.

**Achievements**
40. Finding all the lore of a place of the south earns its achievement and +250 bank cap.
41. The six lore achievements show on the achievements screen with their stage.
42. A lore achievement counts both the pages and the notes of its place.

**Save**
43. An old save loads as version 17 with an empty `heard` set.
44. An old save with a King kill gets The King's last words on load, without a report.
45. An old save gets the first-visit pages of its explored places on load.
46. An old save keeps every lore note that it had.
47. Each fixture in `app/test/fixtures/saves/` loads.

**Screens**
48. The Now tab at Goblin Woods with Pell's row is rendered at 408 dp wide before the PR (`CLAUDE.md`).
49. Pell's sheet is rendered at 408 dp wide before the PR.
50. The Lore tab with its groups is rendered at 408 dp wide before the PR.

**Check and release**
51. Rules, numbers and the save change only as this spec says. The pacing test passes.
52. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

**The portraits at Camp**
53. Each teacher's row shows the teacher's portrait, not the picture of the profession.
54. Ysolde's row shows her portrait, not the trainer icon.
55. A teacher's sheet and Ysolde's sheet show the portrait and the name at the top.
56. The Professions tab and the profession screens still show the pictures of the professions.
57. The Now tab at Camp and one teacher's sheet are rendered at 408 dp wide before the PR.

## History
- 2026-11-17: first version (intent 0023). Accepted.
- 2026-11-17 (plan 0070): portraits for the six teachers and Ysolde. At Camp only Odda had a face, which made no
  sense to the owner. Decision 12; §2.1; §3.5; new §3.6; criteria 53-57. Spec 0014 §4.2 "Now", §6 and criteria
  79-80 follow. Accepted.
