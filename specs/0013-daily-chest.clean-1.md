# Spec 0013: The supply chest (clean edition 1)

Status: draft
Clean edition of: [spec 0013](0013-daily-chest.md) with its erratum 1 and amendments 1-4, and the parts of other
specs that change spec 0013 (see [Changes from other specs](#changes-from-other-specs))
Up to: 2026-11-11 (main 20d80a4)
Issue: #59
Product owner: Zkalf

## How to read this edition
- This edition changes no rule, number or criterion. It says in one file what spec 0013 and its changes say today.
- The accepted files stay the record. If this edition and an accepted file differ, the accepted file wins, and an
  erratum fixes this edition.
- The section numbers (§1-§7), the decision numbers (1-11), the rule points (1-59) and the criterion numbers (1-61)
  are those of spec 0013. Code and tests that cite them stay right.
- A tag such as **(am. 1 change 2)** marks a text that came from an amendment or the erratum.
- §7 keeps the criteria of each amendment under its own heading, with their own numbers.
- [Where each change went](#where-each-change-went) lists every amendment and erratum and its place here.
- A new change to spec 0013 is a new amendment of spec 0013, as before. A later clean edition folds it in.

Intent: [intent/0013-daily-chest.md](../intent/0013-daily-chest.md) (accepted) with
[amendment 1](../intent/0013-daily-chest.amendment-1.md) (accepted 2026-11-01, issue #57) and
[amendment 2](../intent/0013-daily-chest.amendment-2.md) (its own screen)

Spec 0013 builds on:
- spec 0001 amendment 1 (steps per local day) and amendment 2 (the step bank and its boost);
- spec 0005 (qualities, item levels);
- spec 0009 §5.1 (bonus stats);
- spec 0010 (professions, salvage shards);
- spec 0011 (meals);
- spec 0016 (the queue).

Spec 0013 overrides nothing.

## Summary
- Each day that the player spends 5,000 steps on actions, they earn a **supply chest**.
- The chest always holds materials or meals. Sometimes it holds a piece of gear with a better quality roll than a
  monster drop. Rarely it holds a boss shard.
- The game rolls the contents when the player earns the chest.
- The player opens the chest on its own screen, from a button in the top bar.

## Changes from other specs

| Spec | What it changes in spec 0013 | Folded in |
|---|---|---|
| Spec 0011 amendment 2 | The meals target and the buffs that amendment 3 kept | amendment 3 (notes) |
| Spec 0017 amendment 4 | Spec 0017 criterion 31 ends, and with it amendment 1 change 7 | amendment 1 (notes) |
| Spec 0002 amendment 3 | Spec 0010 §9.3 target 3 (the fighter), which amendment 1 measured | amendment 1 (note) |
| Spec 0020 amendment 5 | A Bank button stands left of the supply chest button | §3.1 |
| Spec 0021 (bag limit) | The bag has spaces; an unopened chest uses none; a chest opens into a full bag | §2.6 |
| Spec 0022 amendment 1 | The camp tour names the supply chest in the top bar | (pointer) |

## 1. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | Which steps count | **Steps that go into actions: the walked steps and the boost steps of the bank** (owner, intent amendment 1). |
| 2 | Do walks count | **Yes, every kind of action** (owner, intent amendment 1). |
| 3 | Unopened chests | **No cap, and an "Open all" button** (owner, intent amendment 1). |
| 4 | The quality of chest gear | **Rare, epic and legendary get twice the chance of a monster drop** (owner, intent amendment 1). |
| 5 | Which gear | **Item level from the player's level minus 4 up to the player's level, chase items out** (owner, intent amendment 1). |
| 6 | When the contents roll | **When the player earns the chest** (owner, intent amendment 1). |
| 7 | The name | **Supply chest**, always. "Chest" alone already names a gear slot, and the sunken chest of spec 0011 §6.3 is another thing. |
| 8 | Talents and the chest's quality roll | **No talent changes it.** The chest has its own boost (§2.5). The level boost of spec 0005 §3 applies, as for any roll. |
| 9 | Which shard | **The boss shard of the tier of the player's level**, the same tiers as salvage (spec 0010 §7.1). |
| 10 | Where the chest and its progress show | **On a supply chest screen of its own, from a top bar button left of Achievements. Nothing on Now** (owner, intent amendment 2). |
| 11 | Chest rolls and fights | **A separate random stream.** A chest never changes a fight, a drop or a catch. |

## 2. Rules

### 2.1 The goal
1. The goal is `supplyChest.goal` in `economy.json`: **5,000** steps.
2. Each step that goes into an action counts toward the goal of its local day:
   - the walked step: 1;
   - the boost step that the bank adds to it: 1 more.
3. Every kind of action counts: fights, gathering spots, crafts, rerolls and walks.
4. A step that goes into the bank counts nothing. A step that is lost because the bank is full counts nothing.
5. Meals and talents do not add to the count. A meal or a talent that makes a unit cheaper does not change what a
   step counts.
6. The steps of a test walk count toward today's supply chest, as real steps on the current action do. They count
   for the local day of the test walk **(am. 4 change 1)**. Only owner builds have the test walk (spec 0007 §4)
   **(am. 4 change 2)**.
7. The app passes the local day of each batch of steps to the game. The sync already splits the steps per day (spec
   0001 amendment 1). A call without a day counts nothing (the pacing sims without days, old tests).

### 2.2 Earning a chest
8. The step that brings the count of a day to the goal earns the chest of that day.
9. Each day pays at most one chest.
10. A day pays once, even if later steps of the same day come in a later sync.
11. Late steps for an earlier day count toward that day (spec 0001 amendment 1: late uploads from a watch). They can
    earn that day's chest after a later day's chest.
12. Days before spec 0013 count only the steps that came in after the update. Steps credited before the update do
    not count.
13. The game adds a `SupplyChestEarned` event with the day.

### 2.3 The contents roll at once
14. The game rolls the contents at the step that earns the chest (point 8).
15. Every roll uses the state of that moment:
    - the player's level;
    - the learned professions and their levels.
16. The game stores the rolled contents in the chest. To open it only moves them into the bag.
17. A level up, a new profession or a talent after that moment does not change the chest.
18. The rolls use their own random stream, `supplyRng` in the save. A chest roll never shifts a fight, a drop, a catch
    or a craft.

### 2.4 What a chest holds
Each chest holds the common roll. Gear and a shard roll on their own, so a chest can hold both.

| Part | Chance | Data |
|---|---|---|
| The common roll | always | `supplyChest.materials`, `supplyChest.meals` |
| A piece of gear | 10% (about 1 in 10) **(am. 1 change 1)** | `supplyChest.gearChance` 0.1 |
| A boss shard | 2% (1 in 50) | `supplyChest.shardChance` 0.02 |

**The common roll**
19. The game picks one choice evenly from this list **(am. 1 change 2)**:
    - each gathering profession that the player has learned: Mining, Woodcutting, Fishing, Hunting;
    - Crafting, if the player has learned it;
    - a meal.
20. A gathering profession gives `supplyChest.materials` (**5**) of the plain item of its best spot that the player
    can work. For example:
    - Mining 12 gives 5 Iron ore.
    - Fishing 3 gives 5 Lake scale.
    - Hunting 20 gives 5 Ibex hide.
21. "Best spot" means the spot of that profession with the highest level that is at most the profession's level.
22. A meal gives `supplyChest.meals` (**2**) of one meal. The game picks it evenly among the meals of the meal tier
    for the player's level:

    | Player level | Meal tier | Meals on 2026-11-01 |
    |---|---|---|
    | 1-9 | 1 | the 6 tier 1 meals |
    | 10-19 | 2 | the 10 tier 2 meals |
    | 20 and up | 3 | the 6 tier 3 meals |

23. A meal from the chest is a normal dish, never a perfect one (spec 0011 §5).
24. Cooking is not a choice. A player without a gathering profession and without Crafting always gets a meal
    **(am. 1 change 6)**.

**The Crafting choice (am. 1 changes 3-5)**
- The Crafting choice gives the inputs of one craft.
- The game picks the recipe evenly among the gear recipes with a Crafting level from the player's Crafting level
  minus 4 (`supplyChest.gearWindow`) up to the Crafting level.
- The game never picks a recipe of the gear in `supplyChest.exclude`.
- For example, Crafting 3 can give the inputs of a copper sword (5 Copper ore).

**The gear**
25. The window holds each piece of gear with an item level from the player's level minus 4 up to the player's
    level. The item level is the one of spec 0005 decision 2: the recipe's level, else the lowest monster that drops
    it, else 1.
26. The chest never gives gear with an item level above the player's level.
27. The game picks evenly among the gear in the window.
28. The gear in `supplyChest.exclude` never comes from a chest. The list holds the chase items **(erratum 1)**:

    | Gear | Why it stays out |
    |---|---|
    | King's blade, Chieftain's amulet, Dragon's heart | made from 10 boss shards |
    | Golden antler mantle, Tusk mantle, Lynx mantle | made from a rare trophy (Golden antler, Old Tusk's tusk, Snow lynx pelt) |
    | Drowned Captain's ring | the prize of the sunken chest (spec 0011 §6.3) |

    Gear made from a gem or heartwood stays in the chest, for example the Garnet ring and the Oak charm
    **(erratum 1 correction 4)**.
29. New chase gear goes on the list in the same change that adds it.
30. If the window holds no gear, the chest holds no gear. The gear roll does not move to another part.
31. The gear rolls its quality as in §2.5, then its bonus stats as a drop does (spec 0009 §5.1), with its item level.

**The shard**
32. The shard is the boss shard of the tier of the player's level (`salvage.shards` in `economy.json`):

    | Player level | Shard |
    |---|---|
    | 1-9 | King's shard |
    | 10-19 | Chieftain's shard |
    | 20 and up | Dragon's shard |

### 2.5 The quality roll of chest gear
33. The chest multiplies the chances of rare, epic and legendary by `supplyChest.qualityBoost` (**2**).
34. Uncommon keeps its chance. Common takes what is left.
35. The level boost of spec 0005 §3 applies on top, as for any roll: gear below the player's level rolls a little
    better (`qualityPerLevel`, at most `qualityMaxLevels`).
36. No talent changes the roll (decision 8).
37. The chances of gear at the player's level, with the data of 2026-11-01:

    | Quality | Monster drop | Supply chest |
    |---|---|---|
    | Common | 70% | 60% |
    | Uncommon | 20% | 20% |
    | Rare | 7% | 14% |
    | Epic | 2.5% | 5% |
    | Legendary | 0.5% | 1% |

### 2.6 Opening
38. Every chest waits until the player opens it. There is no cap.
39. "Open" opens the oldest chest. Its contents go into the bag.
40. "Open all" opens every waiting chest. All contents go into the bag.
41. A chest never fails to open. Spec 0013 had a bag with no limit. Since spec 0021 the bag has spaces: an unopened
    chest uses no space, and a chest opens into a bag that is over its spaces.
42. To open a chest uses no steps and no random roll.

## 3. Screens

### 3.1 The top bar button
43. The top bar shows a **supply chest button** left of the Achievements button, on the same plate. Its icon is the
    Material icon `inventory_2` until the chest has its own art. Since spec 0020 amendment 5, the top bar shows five
    buttons in this order: Bank, Supply chest, Achievements, Journal, Settings.
44. The button shows a dot while at least one chest waits.
45. Now shows no chest card and no chest progress.

### 3.2 The supply chest screen
46. A tap on the button opens the **supply chest screen**. It slides in, like the Journal, and a swipe back closes
    it.
    - When the screen opens, the game syncs. The progress line and its bar then show the steps of that sync
      **(am. 4 change 3)**.
47. The screen shows the progress of today: "Today: 3,200 / 5,000 steps", with a thin bar.
48. When today's chest is earned, the line reads "Today: earned".
49. The screen shows the waiting chests:
    - none: "No chest waiting";
    - one: "1 supply chest" and the button **Open**;
    - 2 or more: "3 supply chests" and the buttons **Open** and **Open all**.

### 3.3 The chest sheet
50. A tap on Open or Open all opens a sheet. The sheet lists what came out:
    - each item with its count;
    - gear in the colour of its quality, as on the item card.
51. The sheet's title is "Supply chest", or "3 supply chests" after Open all.
52. A tap on a piece of gear in the sheet opens its item card.
    - **Gear that left the bag (am. 4 changes 4-7):** a row of gear that is no longer in the bag turns grey. A tap on
      it does nothing.
    - The row stays in the sheet, with its count. The sheet still lists all that came out.
    - A row of gear that is still in the bag keeps the colour of its quality and opens its item card.
    - Rows of items that are not gear do not change.

### 3.4 The away summary and the journal
53. The "While you were away" summary adds one line: "Supply chest earned" or "2 supply chests earned".
54. The journal keeps that line with the summary, as it keeps the other lines.
55. The summary does not show the contents. The player sees them when they open the chest.

## 4. Save
56. Save schema 14 (`GameState.schemaVersion`). New fields:

    | Field | What it holds | Default for an old save |
    |---|---|---|
    | `supplySteps` | the count of each local day (`yyyy-mm-dd` to steps) | empty |
    | `supplyPaid` | the days that paid a chest | empty |
    | `supplyChests` | the waiting chests, oldest first: the day and the item keys with counts | empty |
    | `supplyRng` | the state of the chest's random stream | derived from the seed state of the save |

57. The game keeps `supplySteps` and `supplyPaid` for the 14 most recent days. The sync reads 7 days back, so older
    days never get steps again.
58. Gear keys in `supplyChests` hold the quality and the bonus stats (spec 0009 §5.1), as in the bag.
59. Each fixture in `app/test/fixtures/saves/` loads. No step, item or XP is lost. No old day pays a chest.

## 5. Balance
- The chest gives loot, not steps or XP. Gear at the player's level and a better quality roll make the character a
  little stronger.
- Drop chances and gear power move the pace, so this change needed a hand-run sim (`CLAUDE.md`).
- The pacing walkers get days: each sim day of `--steps-per-day 5000` earns its chest when its steps into actions
  reach the goal, and the walker opens it.
- **Sim target:** the average walker (5,000 steps a day) stays inside the level targets of the pacing test.
- Plan 0037 reports, at 5,000 steps a day: the share of days that pay a chest, and the levels at day 7, 30 and 90,
  with and without chests.
- **Balance cost:** one chest a day is small next to the drops of a day of fights. A full bank can halve the walked
  steps that the goal needs.
- **The pace with chests (am. 1):** the owner accepts that the character levels a little faster with chests. The
  targets that chests moved:
  - Mining and Crafting 10: day 5-22 for Mining and 6-22 for Crafting (medians of seeds 1-8)
    **(am. 1 change 8)**.
  - Crafting 20: day 40-65. Mining 20: day 45-65 **(am. 2)**.
  - The clean edition of spec 0010 (§9.3 target 2) holds these numbers too.
- **The sim walker (am. 1 change 9):** the walker of plan 0037 makes two choices that a player makes. They change no
  rule of the game:
  - It practises a gathering profession one level short of its next tier, once its character level has reached
    that tier.
  - In the last 3 levels of a stage, it gathers for a milestone of that stage that counts a gathered item.
  - Without them, chest materials filled the walker's recipes, and it stopped gathering: Mining 10 came on day 50
    instead of day 6, and the Angler milestone came weeks late **(am. 1 change 10)**.
- **Meals (am. 3 change 4):** when the walker decides to cook, it counts only the meals that it would eat. Chest meals
  with another buff (Crit, Defense, fewer steps) piled up in its bag, and it never cooked again: 0 meals cooked in 7
  of 8 seeds. It changes no rule of the game.

## 6. Out of scope
- Streaks, weekly or monthly chests, a goal that the player sets, chests bought with anything (intent 0013).
- A chest that the player keeps closed to roll later: the contents roll at once (decision 6).
- Talents or achievements that change the chest.
- Gear above the player's level.
- A cap on waiting chests.

## 7. Acceptance criteria
The base criteria keep their numbers. A criterion that a later change replaced says so in one line.

**The goal**
1. A walked step into a running action adds 1 to the count of its day.
2. A boost step of the bank adds 1 more to the count of its day.
3. A step into a walk counts.
4. A step into a fight, a gathering spot, a craft or a reroll counts.
5. A step that goes into the bank counts nothing.
6. A step lost to a full bank counts nothing.
7. Replaced by amendment 4 criteria 1-2: the steps of a test walk count.
8. `applySteps` without a day counts nothing.

**Earning**
9. The step that brings a day's count to 5,000 earns one chest.
10. A day never pays a second chest.
11. A sync that covers 3 days that each reach the goal earns 3 chests.
12. Late steps for an earlier day can earn that day's chest.
13. Steps credited before the update count nothing.

**Contents**
14. Each chest holds exactly one common roll.
15. Replaced by amendment 1 criterion 2: the choices include Crafting, if learned.
16. A gathering profession gives 5 of the plain item of its best spot that the player can work.
17. A meal gives 2 of one meal of the tier for the player's level.
18. Replaced by amendment 1 criterion 5: a meal, without a gathering profession and without Crafting.
19. Replaced by amendment 1 criterion 1: about 1 chest in 10 holds gear.
20. About 1 chest in 50 holds a boss shard (a seeded test of many chests).
21. The shard is the one of the tier of the player's level.
22. Chest gear has an item level from the player's level minus 4 up to the player's level.
23. Chest gear never has an item level above the player's level.
24. A level 1 player only gets the Rusty dagger as gear.
25. No gear in `supplyChest.exclude` comes from a chest.
26. Chest gear rolls rare, epic and legendary at twice the chance of a monster drop.
27. Chest gear rolls uncommon at the chance of a monster drop.
28. A talent does not change the quality roll of chest gear.
29. Chest gear has bonus stats as a drop of its item level has.

**Rolled at once**
30. The contents are fixed when the player earns the chest.
31. A level up after that does not change the contents.
32. A chest roll does not change the fights, drops, catches or crafts after it (the same seed gives the same fights
    with and without a chest).

**Opening**
33. Open moves the oldest chest's contents into the bag.
34. Open all moves every waiting chest's contents into the bag.
35. Opening uses no steps.

**Screens**
36. The top bar shows the supply chest button left of the Achievements button.
37. The button shows a dot while a chest waits.
38. The button shows no dot while no chest waits.
39. Now shows no chest card and no chest progress.
40. A tap on the button opens the supply chest screen.
41. The screen shows today's count and the goal: "Today: 3,200 / 5,000 steps".
42. After today's chest, the screen reads "Today: earned".
43. With no chest waiting, the screen reads "No chest waiting".
44. With one chest waiting, the screen shows Open.
45. With 2 or more chests waiting, the screen shows Open and Open all.
46. The chest sheet lists each item with its count.
47. The chest sheet shows gear in the colour of its quality. (Amendment 4: gear that left the bag is grey.)
48. A tap on gear in the chest sheet opens its item card. (Amendment 4: not for gear that left the bag.)
49. The away summary says "Supply chest earned" for one chest.
50. The away summary says "2 supply chests earned" for two.
51. The journal keeps the chest line of the summary.

**Save**
52. The save version is 14.
53. A version 13 save loads with no waiting chest and no paid day.
54. Each fixture in `app/test/fixtures/saves/` loads, with no step, item or XP lost.
55. Waiting chests survive a save and a load, with their gear keys whole.

**Balance**
56. The pacing walkers earn and open chests.
57. The pacing test passes.
58. Plan 0037 reports the sim results of §5.

**Check and release**
59. Every number of this spec lives in `economy.json` under `supplyChest`, except the existing `salvage.shards`,
    qualities and item levels.
60. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
61. `releases/next.md` has a line for players.

**Amendment 1** (rarer chest gear, Crafting materials, the pace with chests)
- The chest:
  1. About 1 chest in 10 holds a piece of gear (a seeded test of many chests). It replaces criterion 19.
  2. The common roll picks evenly among the learned gathering professions, Crafting if learned, and a meal. It
     replaces criterion 15.
  3. The Crafting choice gives the inputs of one gear recipe with a Crafting level from the player's Crafting level
     minus 4 up to the Crafting level.
  4. The Crafting choice never gives the inputs of a recipe of the gear in `supplyChest.exclude`.
  5. A player without a gathering profession and without Crafting always gets a meal. It replaces criterion 18.
- The pace:
  6. The pacing test checks level 10 of the walker without feats within 5% of day 15. This check ended with spec
     0017 criterion 31 (spec 0017 amendment 4).
  7. The pacing test checks the median of Crafting 10 on day 6-22.
  8. The pacing test passes.
- Check and release:
  9. `.\scripts\check.ps1 -Pacing` is green.

Amendment 1 also changed two targets of other specs, with this table of the sim (seeds 1-8, 5,000 steps a day, with
chests, gear in 1 chest in 10 and the Crafting choice):

| Target | Before | With chests | New target |
|---|---|---|---|
| Spec 0017 criterion 31, level 10 (seed 1, without feats) | within 5% of day 16 | day 15 | within 5% of day **15** |
| Spec 0017 criterion 31, level 20 | within 5% of day 50 | day 48 | no change |
| Spec 0017 criterion 31, level 30 | within 5% of day 84 | day 88 | no change |
| Spec 0010 amendment 1 point 4, Crafting 10 (median) | day 8-22 | day 7 | day **6-22** |
| Spec 0010 §9.3 target 3, the fighter to level 30 | at least 15% later | day 105 against day 88: 19% later | no change |
| Spec 0011 §9.3 target 5, meals | no later, at most 5 days sooner | 0.5 days sooner | no change |

- Change 7 (spec 0017 criterion 31 at days 15, 50 and 84) ended with spec 0017 amendment 4.
- Spec 0010 §9.3 target 3 changed later: spec 0010 amendment 11, then spec 0002 amendment 3 (the fighter's median in
  80-120).

**Amendment 2** (Crafting 20 with chests)
1. The pacing test checks the median of Crafting 20 on day 40-65.
2. The pacing test checks the median of Mining 20 on day 45-65.
3. `.\scripts\check.ps1 -Pacing` is green.

**Amendment 3** (meals and the pace with chests)
1. The pacing test checks the meals target from -5 to 5 days.
2. The meal buffs in `economy.json` stay 6 / 10 / 14.
3. `.\scripts\check.ps1 -Pacing` is green.

Amendment 3 changed spec 0011 §9.3 target 5. Spec 0011 amendment 2 later changed it again: meals help a little, and
the median level 30 day with meals is 0 to 10 days sooner than without. It also changed the meal buffs and their
length. So criteria 1 and 2 of amendment 3 no longer hold. Spec 0011 amendment 2 owns those numbers now. Amendment
3's walker rule (change 4) stays (§5).

**Amendment 4** (test walks fill the chest, fresh steps on the chest screen, grey gear in the chest sheet)
- Test walks:
  1. The steps of a test walk on an action count toward today's supply chest.
  2. A test walk that reaches the goal earns today's chest.
- The supply chest screen:
  3. Steps walked after the last sync show on the supply chest screen after it opens, with no other action.
- The chest sheet:
  4. After the player wears a piece of gear from the sheet, its row stays in the sheet and turns grey.
  5. After the player salvages a piece of gear from the sheet, its row stays in the sheet and turns grey.
  6. A tap on a grey row opens nothing.
  7. A row of gear that is still in the bag keeps its quality colour and opens its item card.
- Check and release:
  8. The numbers and the save do not change. The pacing test passes.
  9. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

## Where each change went

| File | Its changes | Place in this edition |
|---|---|---|
| [Erratum 1](0013-daily-chest.erratum.md) | 1 the chase list holds the Tusk and Lynx mantles; 2-3 intent 0013 amendment 1; 4 gem and heartwood gear stays in | §2.4 point 28 |
| [Amendment 1](0013-daily-chest.amendment-1.md) | 1 gear in 1 chest in 10; 2-6 the Crafting choice; 7-8 the pace targets; 9-10 the sim walker | §2.4; §5; §7 |
| [Amendment 2](0013-daily-chest.amendment-2.md) | 1 Crafting 20 on day 40-65; 2 Mining 20 stays; 3 the rest stays | §5; §7 |
| [Amendment 3](0013-daily-chest.amendment-3.md) | 1 the meals target; 2-3 the buffs stay; 4 the walker cooks; 5 a later issue | §5; §7 (replaced by spec 0011 amendment 2, but for change 4) |
| [Amendment 4](0013-daily-chest.amendment-4.md) | 1-2 test walks count; 3 sync on open; 4-7 grey gear in the sheet | §2.1 point 6; §3.2; §3.3; §7 |
