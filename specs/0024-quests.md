# Spec 0024: Quests, chapter 1: the people of the south ask for help

Status: accepted
Intent: [intent/0024-quests.md](../intent/0024-quests.md) (accepted, 2026-11-17)
Builds on: spec 0023 (people, lines, chapter 1), spec 0002 §9.3 (Next goal), spec 0008 §3.2 (Now), spec 0010 §6 (the
teachers), spec 0013 (the supply chest), spec 0016 (the queue), spec 0022 (the camp tour)
Product owner: Zkalf (accepted on 2026-11-17)
Date: 2026-11-17

The people of the south ask the hero for help. The hero takes a quest on a person's sheet, does the task and hands
the quest in to that person for XP and a supply chest. Seventeen quests lead from Camp through Goblin Woods and the
Old Graveyard to the Graveyard King. A quest card on Now takes the place of "Next goal".

## 1. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | What takes over the advice of Next goal | **Story quests teach it** (owner, 2026-11-17). The first quests teach wearing gear, gathering, crafting, cooking and fighting. After them, no gear advice. |
| 2 | The reward | **XP and a supply chest** (owner, 2026-11-17). |
| 3 | When a quest counts | **From the moment the hero takes it** (owner, 2026-11-17). |
| 4 | The first build | **The south of the river, chapter 1** (owner, 2026-11-17): 17 quests (§2.8). |
| 5 | Old saves | **They start the same quest lines as a new save** (owner, 2026-11-17). A strong hero finishes the first quests quickly. |
| 6 | The quest card | **Up to three open quests, ready ones first, and "+N more"** (owner, 2026-11-17). |
| 7 | The quest marks | **A gold "!" for a quest to take and a gold "?" for a quest to hand in**, as in World of Warcraft (Claude). |
| 8 | The quest log | **A fourth tab of the Journal: Quests** (Claude). |
| 9 | No quest left | **The card says "No more work for now. The north will need you."** (Claude). The Settings switch can hide it. |
| 10 | A stop condition "until the quest is done" | **None** (Claude). The stop conditions of today ("until I have N", a count of fights) cover it. |
| 11 | Dropping a quest | **Not possible** (Claude). A quest never runs out and never blocks another quest, so there is nothing to drop. |
| 12 | "Bring" and the rule of decision 3 | **A "bring" quest counts the items that came into the bag after the hero took it** (Claude): a new counter of items from fights (§2.3). |
| 13 | The size of the XP | **3,490 XP for all 17 quests** (Claude, §5): about 12% of the XP to level 11, and less than 1% of the XP to level 30. |

## 2. Rules

### 2.1 Quests
- A **quest** is a request from a person (`data/quests.json`). It has:
  - an id and a title;
  - a giver: a person of spec 0023 (`odda`, `pell`, `aldous`, `jory`) or a teacher, by the id of the profession
    (`mining`, `crafting`, ...), as in the King lines of spec 0023 §2.5;
  - the quest that must be done before it (`after`), or none;
  - one task (§2.3) with its words, for example "Kill 6 goblins in Goblin Woods";
  - the XP of the reward;
  - two lines: the **ask**, which the giver says when the quest is offered, and the **thanks**, which the giver says
    at hand-in. The lines may hold `{name}` and `{a|b|c}`, as the lines of spec 0023 do.
- Ysolde gives no quest in the first build.

### 2.2 The life of a quest
A quest is in one of four states:
1. **Closed:** its `after` quest is not done yet.
2. **Offered:** it is not taken, and its `after` quest is done (or it has none).
3. **Taken:** the hero took it. Its count runs.
4. **Done:** the hero handed it in. A done quest stays done.

- A taken quest is **ready** when its task is met (§2.3). A ready quest stays taken until the hero hands it in.
- The hero takes a quest on the giver's sheet (§3.3). Taking costs nothing and needs nothing.
- The hero hands a ready quest in on the giver's sheet. A sheet opens only from the giver's row at the giver's place,
  so the hero must be there.
- The hero can have any number of quests taken at once.
- The player can not drop a taken quest (decision 11).

### 2.3 Tasks and their counts
A task counts only what happens after the hero takes the quest (decision 3). At the moment of taking, the save keeps
the value of the counter that the task reads. The count is the counter now minus that value.

| Task | Its words in data, for example | Ready when | Counter |
|---|---|---|---|
| **Kill** a monster | "Kill 10 goblins in Goblin Woods" | the count reaches N | `kills.<monster>` |
| **Gather** an item | "Gather 25 copper ore in Copper Hills" | the count reaches N | `gathered.<item>` |
| **Craft** or cook an item | "Make a copper sword at the forge" | the count reaches N | `crafted.<item>` |
| **Bring** an item | "Bring Pell 15 goblin hides" | the count reaches N, and the bag holds N | `gathered.<item>` plus the new `dropped.<item>` |
| **Wear** an item | "Wear a hide vest" | the hero wears the item, of any quality | none: the gear of now |
| **Visit** a place | "Go to the Old Graveyard" | the hero arrives at the place, or stands there at the moment of taking | none |

- `dropped.<item>` is new. It counts each item that a fight puts into the bag, a boss's drop included.
- At hand-in, a "bring" quest takes N of the item from the bag: the lowest quality first, so the hero keeps the best.
  The bank does not count, even at Camp.
- A "wear" quest that is ready stops being ready when the hero takes the item off. It is ready again when they wear
  it again.
- A count shows at most N: "10 of 10", never "11 of 10".

### 2.4 The reward
- At hand-in, the hero gets the quest's XP and one supply chest.
- The XP counts as fight XP for the level, with its level-ups and talent points (spec 0002, spec 0015). No talent and
  no meal changes it.
- The chest rolls its contents at hand-in, by the rules of spec 0013 §2.3-§2.5: the hero's level and professions of
  that moment, its own random stream. A quest roll never shifts a fight, a drop, a catch or a craft.
- The chest waits on the supply chest screen, as a daily chest does. It does not count toward the daily goal of spec
  0013 §2.1, and the day keeps its own chest.
- The game adds a `QuestDone` event with the quest, the XP and the chest.

### 2.5 Ready during a walk
- When a task becomes ready during a walk or a sync, the game adds a `QuestReady` event with the quest.
- A quest that is ready at the moment of taking (a "wear" or a "visit" quest) gets no event: the sheet shows it ready
  at once.

### 2.6 The marks
- A person's row shows a gold **"!"** when the person has an offered quest.
- It shows a gold **"?"** when the person has a ready quest. The "?" wins over the "!".
- A mark takes the place of the dot of spec 0023 §3.1 and of the dot of a waiting tip (spec 0010 §6.2). The lines and
  the tips are still heard when the sheet opens.
- A taken quest that is not ready puts no mark on the row.

### 2.7 In place of Next goal
- The rules of Next goal (spec 0002 §9.3, spec 0010 §8.4) go away: the equip, craft, collect, profession and fight
  lines. Nothing in the game works out a next goal any more.
- The sim walker keeps its own goals (`simulation.dart`). It never read Next goal, and it takes no quests (§5).

### 2.8 The quest lines
The first build has 17 quests. The first one is offered on a new game. "After" names the quest that opens it.

| Id | Giver | Title | After | Task | XP |
|---|---|---|---|---|---|
| `odda_goblins` | Odda | Goblins at the door | none | Kill 10 goblins | 60 |
| `hilde_ore` | Hilde | Ore for the forge | `odda_goblins` | Gather 25 copper ore | 80 |
| `bram_logs` | Bram | Wood for the fire | `odda_goblins` | Gather 25 oak logs | 80 |
| `sigrun_deer` | Sigrun | Meat for the pot | `odda_goblins` | Gather 12 venison | 80 |
| `wen_perch` | Wen | Perch at dawn | `odda_goblins` | Gather 15 perch | 80 |
| `pell_hides` | Pell | Hides for the winter | `odda_goblins` | Bring 15 goblin hides | 120 |
| `garrow_blade` | Garrow | A blade of your own | `hilde_ore` | Craft 1 copper sword | 120 |
| `garrow_vest` | Garrow | Something between you and the teeth | `pell_hides` | Wear a hide vest | 120 |
| `marta_skewers` | Marta | Something hot | `sigrun_deer` | Cook 5 venison skewers | 100 |
| `pell_brutes` | Pell | The big brothers | `pell_hides` | Kill 20 goblin brutes | 200 |
| `pell_bear` | Pell | The old one | `pell_brutes` | Kill the Old Bear | 400 |
| `odda_graveyard` | Odda | The dead walk | `pell_brutes` | Go to the Old Graveyard | 100 |
| `aldous_guard` | Aldous | Keep them down | `odda_graveyard` | Kill 40 skeletons | 300 |
| `aldous_cloth` | Aldous | Cloth for the graves | `aldous_guard` | Bring 15 grave cloth | 300 |
| `garrow_shield` | Garrow | Bones for a shield | `aldous_guard` | Craft 1 bone shield | 250 |
| `odda_king` | Odda | The King Who Would Not Rest | `aldous_cloth` | Kill the Graveyard King | 800 |
| `jory_bass` | Jory Tarr | Fish for a secret | none | Bring 15 sea bass | 300 |

- The main line runs: `odda_goblins`, `pell_hides`, `pell_brutes`, `odda_graveyard`, `aldous_guard`, `aldous_cloth`,
  `odda_king`. The other quests branch off it.
- The Old Bear is level 16 and a skull for most heroes of chapter 1. `pell_bear` warns of it, and it stays out of the
  main line. The danger is a feature (`docs/game-direction.md`).
- Jory stands only at the revealed cove (spec 0023 §3.1), so `jory_bass` waits for the cove. Sea bass needs Fishing 15.
- The crafts and the cook need their profession. A hero who has not learned it sees Learn on the teacher's sheet, as
  today (spec 0010 §6).

### 2.9 The words
Each quest's task words, ask and thanks. `{name}` is the hero's name.

| Quest | Task words | Ask | Thanks |
|---|---|---|---|
| `odda_goblins` | Kill 10 goblins in Goblin Woods | "Goblins took a crate of rope off the Guild's road last night. The Guild pays its debts, {name}, and it collects them too. Ten of them should learn the price." | "Ten? That'll teach the rest. Pell the charcoal burner lives out in those woods. Go and see him. And the teachers here have work, if you want it." |
| `hilde_ore` | Gather 25 copper ore in Copper Hills | "Garrow's forge eats copper faster than I dig it. Dig twenty-five ore in Copper Hills, {name}, and mind the loose rock." | "Twenty-five good lumps. Keep them. Garrow will show you what they're for." |
| `bram_logs` | Gather 25 oak logs in Goblin Woods | "Marta's fire is hungry, and so am I. Twenty-five oak logs from Goblin Woods. Watch for little green hands." | "Good wood. That'll keep the pot on till morning." |
| `sigrun_deer` | Gather 12 venison on the deer trail | "The camp eats too much bread. Twelve cuts of venison from the deer trail in Goblin Woods. Shoot clean." | "Clean cuts. Keep them for Marta. She'll know what to do." |
| `wen_perch` | Gather 15 perch at Mirror Lake | "Perch bite all day at Mirror Lake, {name}. Fifteen of them, and keep your eyes on the water. Something big rolls out there." | "Fifteen perch, and you still have all your fingers. Good." |
| `pell_hides` | Bring Pell 15 goblin hides | "Odda sent you? Then make yourself useful. My roof leaks, and my walls too. Fifteen goblin hides will patch them. The goblins won't need them." | "Hm. They stink, but they'll keep the rain out. Thank you, {name}." |
| `garrow_blade` | Make a copper sword at the forge | "Five copper ore makes a sword, {name}. Not a good one. Your own. Make it at my forge." | "Ugly. It'll cut. Now go and hit something with it." |
| `garrow_vest` | Wear a hide vest | "You go out there in your shirt? Four goblin hides make a vest. Make it, wear it, show me." | "Better. Now there's something between you and the teeth." |
| `marta_skewers` | Cook 5 venison skewers at the camp fire | "You've got venison? Then you can cook, {name}. Five skewers at my fire. A hero who can cook never goes hungry on the road." | "Not bad at all! Eat one before a hard fight. You'll feel it." |
| `pell_brutes` | Kill 20 goblin brutes in Goblin Woods | "The small ones I can chase off with a stick. Not the big brothers. Twenty of them have been at my charcoal. Stop them." | "They came from the north, the brutes, same as the rest. Running. Go and tell Odda. She'll want to know." |
| `pell_bear` | Kill the Old Bear in Goblin Woods | "There's an old bear in the deep woods. Older than me. He kept to himself for years. Now the goblins push him out, and he's angry. Don't go unless you're ready." | "You beat the old one? Then the woods have a new old one, {name}." |
| `odda_graveyard` | Go to the Old Graveyard | "Goblins running south, and the dead walking in the Old Graveyard. It's the same trouble, {name}. I'd bet the ledger on it. Go and look. Aldous the sexton still lives out there." | "Skeletons in the old King's colours. I was afraid of that. Help Aldous. He won't ask, so I'm asking for him." |
| `aldous_guard` | Kill 40 skeletons in the Old Graveyard | "They climb out every night, {name}. Forty of them back in the ground, and I might sleep a week. Might." | "Forty. They'll be back. They always come back while he's awake." |
| `aldous_cloth` | Bring Aldous 15 grave cloth | "The zombies wear the old shrouds. I want them back, {name}. Fifteen pieces of grave cloth, to bind the graves shut. Don't ask me how I know that works." | "There. Bound. Now only one grave is still open, and it's the one with the crown." |
| `garrow_shield` | Make a bone shield at the forge | "Copper's soft. Bone from the graveyard is harder, if you can stomach it. Five bones and two oak logs make a shield." | "Good. Don't think about whose they were." |
| `odda_king` | Kill the Graveyard King | "Aldous says the King wakes his guard every night. Put him back in the ground, {name}, and the road north opens. The Guild has waited a hundred years for that road." | "The King is down. Whatever comes next comes from the north. Rest tonight. Tomorrow the road is yours." |
| `jory_bass` | Bring Jory 15 sea bass | "You want a secret? Secrets cost. Fifteen sea bass off my rocks, friend, and I'll owe you one. A small one." | "Fair trade. Here's your secret: the crates I ship go north, to the Peak. Who pays for them? That one costs more." |

## 3. Screens

### 3.1 The quest card on Now
- The quest card stands where Next goal stood: fourth in Now, after the test walk (spec 0008 §3.2).
- It has the title "Quests" and lists up to three taken quests, ready ones first, then in the order they were taken.
- Each line shows the quest's title and:
  - its task words and the count, for example "Kill 10 goblins in Goblin Woods · 4 of 10";
  - or, when it is ready, "Ready: hand it in to Pell in Goblin Woods".
- With more than three taken quests, a last line says "+2 more". A tap on the card opens the Quests tab (§3.4).
- With no quest taken, the card says who has a quest to give, the first in the order of §2.8: "Pell has work for you
  in Goblin Woods", or "Odda has work for you at Camp". A hidden place never shows.
- With every quest of the build done, the card says "No more work for now. The north will need you."
- The Settings switch of Next goal becomes **Show the quest card**. A save keeps its choice: a player who hid Next
  goal does not see the quest card until they turn it on.

### 3.2 The rows
- A person's row and a teacher's row show the mark of §2.6 at the right, in the place of the dot: a gold "!" or a
  gold "?".
- The marks are flat icons that Claude draws (`art/icons.py`).

### 3.3 The sheets
- A person's sheet and a teacher's sheet show their quests under the newest line (spec 0023 §3.2), in the order of
  §2.8:
  - an **offered** quest: its title, the ask in italics, the task words, the reward "120 XP and a supply chest" and
    a **Take** button;
  - a **taken** quest that is not ready: its title, the task words and the count;
  - a **ready** quest: its title, the task words and a **Hand in** button. A "bring" quest says "Gives 15 goblin
    hides".
- After Hand in, the sheet shows the thanks in italics in the quest's place, and the XP and the chest as on a level-up
  card. The next time the sheet opens, the done quest is gone from it.
- A quest whose "bring" items are not in the bag is not ready, so the sheet shows its count, for example "12 of 15".
- The learn line, Learn and the tips stay on the teacher's sheet (spec 0010 §6).

### 3.4 The quest log
- The Journal gets a fourth tab: **Log, Bestiary, Lore, Quests**.
- The Quests tab lists the taken quests first (ready ones first), then the done quests, newest first.
- A taken quest shows its giver's portrait, its title, the giver's name and place, the task words and the count.
- A done quest shows its giver's portrait, its title, the ask and the thanks.

### 3.5 The report and the Journal
- A quest that became ready shows in the report: "Quest ready: Goblins at the door. Hand it in to Odda."
- A hand-in goes into the Journal: "Quest done: Goblins at the door. +60 XP and a supply chest."

### 3.6 Look
- The "!" and the "?" are gold, so they read apart from the teal dot.
- Before the PR, these are rendered at 408 dp wide (`CLAUDE.md`): Now with the quest card at Goblin Woods, Pell's
  sheet with an offered and a ready quest, and the Quests tab.

## 4. Save
- A new map `quests` keeps each quest that was taken: its state (taken or done) and the counter value at the moment
  of taking. An old save starts it empty.
- A new counter `dropped.<item>` (§2.3). An old save starts it at 0 for each item.
- The save version goes from 17 to 18.
- An old save gets `odda_goblins` offered, as a new save does (decision 5). Its old kills and finds do not count
  toward any quest.
- The app's setting `nextGoalHidden` keeps its name in the save and now hides the quest card.
- Each fixture in `app/test/fixtures/saves/` loads.

## 5. Balance
- The 17 quests give 3,490 XP and 17 supply chests in all.
- 3,490 XP is about 12% of the 28,930 XP to level 11, and about 0.6% of the 560,170 XP to level 30. A hero who does
  every quest of chapter 1 reaches level 10 a little sooner. The level-30 target of day 80-100 does not move.
- 17 chests are about a fifth of the 80-100 daily chests on the way to level 30.
- The sim walker takes no quests: CLAUDE.md asks only for the simplest habit that keeps it playing. The pacing test
  in `check.ps1` stays the guard, and it stays green.
- One hand check before the PR: the walker's level on day 10 and day 90 with 3,490 XP added on day 1. Both stay
  inside the targets of spec 0002 and the owner's sim targets (mixed level 30 on day 80-100).

## 6. Out of scope
- North of the river: its people and quests come later, mostly as data.
- Daily or repeated quests.
- Work orders built from the old Next goal rules (decision 1).
- Choices, branches, timed quests and dropping a quest.
- Quests from Ysolde.
- A stop condition "until the quest is done" (decision 10).
- A quest achievement.

## 7. Acceptance criteria

**Quests and their states**
1. A new game has `odda_goblins` offered and every other quest closed, except `jory_bass`.
2. A quest is offered when its `after` quest is done.
3. Taking a quest makes it taken. Taking costs nothing.
4. A done quest stays done and is never offered again.
5. The hero can hold more than one taken quest at once.
6. The data has 17 quests, and each `after` and each giver exists (data test).

**Counting**
7. A kill task counts only the kills after the quest was taken.
8. A gather task counts only the items gathered after the quest was taken.
9. A craft task counts only the items crafted or cooked after the quest was taken.
10. A bring task counts the items dropped or gathered after the quest was taken.
11. A bring task is not ready while the bag holds fewer than N, even if the count is N.
12. A wear task is ready while the item is worn, of any quality, and not ready once it is taken off.
13. A visit task is ready when the hero arrives at the place, or stands there when taking the quest.
14. A count never shows more than N.
15. Fights count `dropped.<item>` for each item that they put into the bag.

**Hand-in and reward**
16. Hand in is possible only for a ready quest, on the giver's sheet.
17. Hand-in gives the quest's XP, with the level-ups it brings.
18. Hand-in gives one supply chest, rolled at that moment, which waits on the supply chest screen.
19. A quest chest does not change the daily chest of spec 0013.
20. A quest roll does not change the fights, drops, catches or crafts that follow it (seeded test).
21. A bring quest takes N of the item from the bag at hand-in, the lowest quality first, and none from the bank.
22. A task that becomes ready during a walk adds a `QuestReady` event. A hand-in adds a `QuestDone` event.

**The quest card**
23. The quest card stands where Next goal stood on Now.
24. The card lists up to three taken quests, ready ones first, with their task words and count.
25. A ready quest on the card says "Ready: hand it in to <name> in <place>".
26. With more than three taken quests, the card shows "+N more", and a tap opens the Quests tab.
27. With no quest taken, the card names the first person with an offered quest and their place.
28. A person at a hidden place is not named on the card.
29. With every quest done, the card says "No more work for now. The north will need you."
30. The Settings switch "Show the quest card" hides and shows the card. A save that hid Next goal keeps the card
    hidden.
31. Nothing on Now shows a Next goal line.

**Marks and sheets**
32. A row shows a gold "!" while its person has an offered quest.
33. A row shows a gold "?" while its person has a ready quest, also when they have an offered one.
34. A row with a mark shows no dot.
35. The sheet shows an offered quest with its title, ask, task words, reward and Take.
36. The sheet shows a taken quest with its count, and a ready quest with Hand in.
37. After Hand in, the sheet shows the thanks, the XP and the chest.
38. A teacher's sheet keeps its learn line, Learn and tips.

**The quest log and the report**
39. The Journal has the tabs Log, Bestiary, Lore and Quests.
40. The Quests tab lists the taken quests, ready ones first, then the done quests, newest first.
41. Each entry shows the giver's portrait.
42. The report shows "Quest ready: <title>. Hand it in to <name>."
43. The Journal shows "Quest done: <title>. +N XP and a supply chest."

**Save**
44. An old save loads as version 18 with no quest taken and `odda_goblins` offered.
45. An old save's kills and finds before the update do not count toward a quest.
46. Each fixture in `app/test/fixtures/saves/` loads.

**Screens**
47. Now with the quest card at Goblin Woods is rendered at 408 dp wide before the PR (`CLAUDE.md`).
48. Pell's sheet with an offered and a ready quest is rendered at 408 dp wide before the PR.
49. The Quests tab is rendered at 408 dp wide before the PR.

**Check and release**
50. Rules, numbers and the save change only as this spec says. The pacing test passes, and the hand check of §5
    stays inside the targets.
51. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

## History
- 2026-11-17: first version (intent 0024). The owner asked for higher task counts: each side quest is about a day of
  walking, and the main line spreads over the chapter. Accepted.
