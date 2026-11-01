# Spec 0013: The supply chest

Status: accepted
Intent: [intent/0013-daily-chest.md](../intent/0013-daily-chest.md) (accepted) with
[amendment 1](../intent/0013-daily-chest.amendment-1.md) (accepted 2026-11-01, issue #57) and
[amendment 2](../intent/0013-daily-chest.amendment-2.md) (its own screen)
Builds on: spec 0001 amendment 1 (steps per local day), spec 0001 amendment 2 (the step bank and its boost), spec
0005 (qualities, item levels), spec 0009 §5.1 (bonus stats), spec 0010 (professions, salvage shards), spec 0011
(meals), spec 0016 (the queue)
Overrides: nothing
Product owner: Zkalf
Date: 2026-11-01

Each day that the player spends 5,000 steps on actions, they earn a **supply chest**. The chest always holds
materials or meals, sometimes a piece of gear with a better quality roll than a monster drop, and rarely a boss
shard. The game rolls the contents when the player earns the chest. The player opens the chest on its own screen, from a button left of Achievements.

## 1. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | Which steps count | **Steps that go into actions: the walked steps and the boost steps of the bank** (owner, amendment 1). |
| 2 | Do walks count | **Yes, every kind of action** (owner, amendment 1). |
| 3 | Unopened chests | **No cap, and an "Open all" button** (owner, amendment 1). |
| 4 | The quality of chest gear | **Rare, epic and legendary get twice the chance of a monster drop** (owner, amendment 1). |
| 5 | Which gear | **Item level from the player's level minus 4 up to the player's level, chase items out** (owner, amendment 1). |
| 6 | When the contents roll | **When the player earns the chest** (owner, amendment 1). |
| 7 | The name | **Supply chest**, always. "Chest" alone already names a gear slot, and the sunken chest of spec 0011 §6.3 is another thing. |
| 8 | Talents and the chest's quality roll | **No talent changes it.** The chest has its own boost (§2.5). The level boost of spec 0005 §3 applies, as for any roll. |
| 9 | Which shard | **The boss shard of the tier of the player's level**, the same tiers as salvage (spec 0010 §7.1). |
| 10 | Where the chest and its progress show | **On a supply chest screen of its own, from a top bar button left of Achievements. Nothing on Now** (owner, amendment 2). |
| 11 | Chest rolls and fights | **A separate random stream.** A chest never changes a fight, a drop or a catch. |

## 2. Rules

### 2.1 The goal
1. The goal is `supplyChest.goal` in `economy.json`: **5,000** steps.
2. Each step that goes into an action counts toward the goal of its local day:
   - the walked step: 1
   - the boost step that the bank adds to it: 1 more
3. Every kind of action counts: fights, gathering spots, crafts, rerolls and walks.
4. A step that goes into the bank counts nothing. A step that is lost because the bank is full counts nothing.
5. Meals and talents do not add to the count. A meal or a talent that makes a unit cheaper does not change what a
   step counts.
6. The steps of a test walk count nothing.
7. The app passes the local day of each batch of steps to the game. The sync already splits the steps per day (spec
   0001 amendment 1). A call without a day counts nothing (test walks, the pacing sims without days, old tests).

### 2.2 Earning a chest
8. The step that brings the count of a day to the goal earns the chest of that day.
9. Each day pays at most one chest.
10. A day pays once, even if later steps of the same day come in a later sync.
11. Late steps for an earlier day count toward that day (spec 0001 amendment 1: late uploads from a watch). They can
    earn that day's chest after a later day's chest.
12. Days before the update count only the steps that come in after the update. Steps credited before the update do
    not count.
13. The game adds a `SupplyChestEarned` event with the day.

### 2.3 The contents roll at once
14. The game rolls the contents at the step that earns the chest (§2.2 point 8).
15. Every roll uses the state of that moment:
    - the player's level
    - the learned professions and their levels
16. The game stores the rolled contents in the chest. Opening only moves them into the bag.
17. A level up, a new profession or a talent after that moment does not change the chest.
18. The rolls use their own random stream, `supplyRng` in the save. A chest roll never shifts a fight, a drop, a catch
    or a craft.

### 2.4 What a chest holds
Each chest holds the common roll. Gear and a shard roll on their own, so a chest can hold both.

| Part | Chance | Data |
|---|---|---|
| The common roll | always | `supplyChest.materials`, `supplyChest.meals` |
| A piece of gear | 20% (about 1 in 5) | `supplyChest.gearChance` 0.2 |
| A boss shard | 2% (1 in 50) | `supplyChest.shardChance` 0.02 |

**The common roll**
19. The game picks one choice evenly from this list:
    - each gathering profession that the player has learned: Mining, Woodcutting, Fishing, Hunting
    - a meal
20. A gathering profession gives `supplyChest.materials` (**5**) of the plain item of its best spot that the player
    can work. For example:
    - Mining 12 gives 5 Iron ore.
    - Fishing 3 gives 5 Lake scale.
    - Hunting 20 gives 5 Ibex hide.
21. "Best spot" means the spot of that profession with the highest level that is at most the profession's level.
22. A meal gives `supplyChest.meals` (**2**) of one meal. The game picks it evenly among the meals of the meal tier
    for the player's level:

    | Player level | Meal tier | Meals today |
    |---|---|---|
    | 1-9 | 1 | the 6 tier 1 meals |
    | 10-19 | 2 | the 10 tier 2 meals |
    | 20 and up | 3 | the 6 tier 3 meals |

23. A meal from the chest is a normal dish, never a perfect one (spec 0011 §5).
24. Crafting and Cooking are not choices: they have no spots. A player without a gathering profession always gets
    a meal.

**The gear**
25. The window holds each piece of gear with an item level from the player's level minus 4 up to the player's
    level. The item level is the one of spec 0005 decision 2: the recipe's level, else the lowest monster that drops
    it, else 1.
26. The chest never gives gear with an item level above the player's level.
27. The game picks evenly among the gear in the window.
28. The gear in `supplyChest.exclude` never comes from a chest. Today the list holds the chase items:

    | Gear | Why it stays out |
    |---|---|
    | King's blade, Chieftain's amulet, Dragon's heart | made from 10 boss shards |
    | Golden antler mantle | made from a rare trophy (Golden antler) |
    | Drowned Captain's ring | the prize of the sunken chest (spec 0011 §6.3) |

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
37. The chances of gear at the player's level, with today's data:

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
41. The bag has no limit, so a chest never fails to open.
42. Opening uses no steps and no random roll.

## 3. Screens

### 3.1 The top bar button
43. The top bar shows a **supply chest button** left of the Achievements button, on the same plate. Its icon is the
    Material icon `inventory_2` until the chest has its own art.
44. The button shows a dot while at least one chest waits.
45. Now shows no chest card and no chest progress.

### 3.2 The supply chest screen
46. A tap on the button opens the **supply chest screen**. It slides in, like the Journal, and a swipe back closes
    it.
47. The screen shows the progress of today: "Today: 3,200 / 5,000 steps", with a thin bar.
48. When today's chest is earned, the line reads "Today: earned".
49. The screen shows the waiting chests:
    - none: "No chest waiting"
    - one: "1 supply chest" and the button **Open**
    - 2 or more: "3 supply chests" and the buttons **Open** and **Open all**

### 3.3 The chest sheet
50. A tap on Open or Open all opens a sheet. The sheet lists what came out:
    - each item with its count
    - gear in the colour of its quality, as on the item card
51. The sheet's title is "Supply chest", or "3 supply chests" after Open all.
52. A tap on a piece of gear in the sheet opens its item card.

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
- Drop chances and gear power move the pace, so this change needs a hand-run sim (`CLAUDE.md`).
- The pacing walkers get days: each sim day of `--steps-per-day 5000` earns its chest when its steps into actions
  reach the goal, and the walker opens it.
- **Sim target:** the average walker (5,000 steps a day) stays inside the level targets of the pacing test.
- The plan reports, at 5,000 steps a day: the share of days that pay a chest, and the levels at day 7, 30 and 90,
  with and without chests.
- **Balance cost:** one chest a day is small next to the drops of a day of fights. A full bank can halve the walked
  steps that the goal needs.

## 6. Out of scope
- Streaks, weekly or monthly chests, a goal that the player sets, chests bought with anything (intent 0013).
- A chest that the player keeps closed to roll later: the contents roll at once (decision 6).
- Talents or achievements that change the chest.
- Gear above the player's level.
- A cap on waiting chests.

## 7. Acceptance criteria

**The goal**
1. A walked step into a running action adds 1 to the count of its day.
2. A boost step of the bank adds 1 more to the count of its day.
3. A step into a walk counts.
4. A step into a fight, a gathering spot, a craft or a reroll counts.
5. A step that goes into the bank counts nothing.
6. A step lost to a full bank counts nothing.
7. The steps of a test walk count nothing.
8. `applySteps` without a day counts nothing.

**Earning**
9. The step that brings a day's count to 5,000 earns one chest.
10. A day never pays a second chest.
11. A sync that covers 3 days that each reach the goal earns 3 chests.
12. Late steps for an earlier day can earn that day's chest.
13. Steps credited before the update count nothing.

**Contents**
14. Each chest holds exactly one common roll.
15. The common roll picks evenly among the learned gathering professions and a meal.
16. A gathering profession gives 5 of the plain item of its best spot that the player can work.
17. A meal gives 2 of one meal of the tier for the player's level.
18. A player without a gathering profession always gets a meal.
19. About 1 chest in 5 holds a piece of gear (a seeded test of many chests).
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
47. The chest sheet shows gear in the colour of its quality.
48. A tap on gear in the chest sheet opens its item card.
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
58. The plan reports the sim results of §5.

**Check and release**
59. Every number of this spec lives in `economy.json` under `supplyChest`, except the existing `salvage.shards`,
    qualities and item levels.
60. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
61. `releases/next.md` has a line for players.
