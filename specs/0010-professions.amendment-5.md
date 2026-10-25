# Spec 0010 amendment 5: materials you have, need, use and keep

Status: draft
Amends: [spec 0010](0010-professions.md) §8.1 (the recipe rows) and
[spec 0016](0016-queue-rework.md) §7.2 (the action sheet)
Issue: #89
Product owner: Zkalf (issue #89, 2026-10-25)
Date: 2026-10-25

## Why
The recipe row shows "have/needed" for one craft only ("Copper ore 3/5"). The action sheet of a craft shows no
materials at all. So the player does not know:
- if they have enough materials for the number of crafts they pick,
- how many of each material the crafts will use,
- how many will be left for other recipes.

The owner chose in issue #89:
- The materials show in both places: on the recipe row and in the action sheet.
- A material that runs short shows in the short colour, with "Enough for N".
- A queued craft counts the materials that earlier actions in the queue will gather or use.

## 1. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | Where the materials show | **On the recipe row and in the action sheet** (owner's choice). |
| 2 | How a short material shows | **The short colour (`Quiet.short`) and "Enough for N"** (owner's choice). |
| 3 | Does a queued craft count earlier actions in the queue? | **Yes** (owner's choice). §3 gives the rules. |
| 4 | Which bag the recipe row counts | **The bag of now.** The row is a quick look; the action sheet counts the queue. |
| 5 | An earlier action with an unknown amount | **The game counts only what it knows.** §3.2 lists the cases. |
| 6 | The "Have mats" filter | **No change.** It still counts the bag of now (amendment 3 §2). |
| 7 | Rerolls | **Count in the queue** (§3.1). A reroll's own sheet does not get the materials table. |

## 2. Screens

### 2.1 The recipe row
- Each material keeps "have/needed" for one craft: "Copper ore 3/5". A short material keeps the short colour.
- The row adds "Enough for N" after the materials. N is the number of crafts that the bag of now allows.
- "Enough for 0" shows in the short colour.
- A recipe with no materials shows no "Enough for N".

### 2.2 The action sheet of a craft or a cook
The sheet shows a materials table below the stop choices. Each material of the recipe has one line:

| Material | Have | Uses | Left |
|---|---|---|---|
| Copper ore | 12 | 10 | 2 |
| Oak log | 3 | 4 | 0 |

- **Have** is the count at the place of the new action in the queue (§3). With an empty queue, it is the bag of now.
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

### 2.3 Start now and Add to queue
- With actions in the queue, the table counts the bag after the queue, as "Add to queue" would place the action.
- A line above the table then reads "After your queue". With an empty queue, the line is not shown.
- Start now clears the queue (spec 0016 §5). The table does not show a second set of numbers for Start now.

## 3. The bag after the queue

### 3.1 What the game counts
The game reads the queue from the front to the back, from the bag of now, as spec 0016 §3.1 reads the place:
1. **The current action** counts only what is still to come. A craft "Until 5 crafted" with 2 crafts done counts 3.
2. **A craft or a cook with a known number of crafts** uses its materials for that number and adds its outputs.
   If the materials run short, it counts only the crafts that the materials allow.
3. **A gather or a fight "Until I have N"** raises its item to at least N. It adds no other item.
4. **A reroll** uses its dust (3 Rare dust, or 3 Legendary dust for a stat reroll).
5. **A travel action** changes nothing in the bag.

### 3.2 What the game does not count
- A gather or a fight "Until grey" or "Never stop" adds nothing: its amount is unknown.
- The other drops of a fight or a gather "Until I have N" add nothing.
- A craft "Until a quality" uses all the materials that it can use: the game cannot know when it stops.
- Salvage is instant, so it is never in the queue.

So the table never promises more materials than the player will have. It can show fewer.

### 3.3 Rules
- The count is for the screens only. It never changes the bag, the save or what an action does when it starts.
- The count lives in `game_core` as one function, so the screens and the tests use the same rules.

## 4. Balance
- No change to the pace. The screens show numbers; the rules do not change.
- The pacing test in `check.ps1` stays green. A hand-run sim is not needed.

## 5. Out of scope
- A warning when the player adds a craft that the queue cannot feed. The table shows it; the game does not refuse.
- Materials in the action sheet of a gather or a fight.
- Queue-aware counts on the recipe row and in the "Have mats" filter.

## 6. Acceptance criteria

**Recipe row**
1. A recipe row shows "have/needed" for each material, as today.
2. A recipe row shows "Enough for N", with N from the bag of now.
3. "Enough for 0" shows in the short colour.
4. A recipe with no materials shows no "Enough for N".

**Action sheet**
5. The action sheet of a craft or a cook shows a materials table with Have, Uses and Left for each material.
6. With "Until 5 crafted" and a need of 2, Uses reads 10.
7. Left reads Have minus Uses, and never below 0.
8. A line with Have below Uses shows in the short colour.
9. "Enough for N" shows when N is below the number of crafts.
10. With "Until I have N" for a meal, the crafts are N minus the meals at the place in the queue.
11. With "Until a quality" or "Never stop", Uses and Left read "–", and "Enough for N" shows.
12. The table updates when the stop choice or the count changes.
13. With an empty queue, Have reads the bag of now and the "After your queue" line is not shown.

**The queue**
14. With actions in the queue, the sheet shows "After your queue", and Have counts the bag after the queue.
15. A queued craft "Until 3 crafted" lowers Have by its use for 3 crafts, and adds its outputs.
16. A queued gather "Until I have 20 Copper ore" raises Have of Copper ore to at least 20.
17. A queued gather "Until grey" or "Never stop" leaves Have as it is.
18. A queued craft "Until a quality" lowers Have to what is left after all the crafts its materials allow.
19. The current action counts only its crafts still to come.
20. A queued reroll lowers Have of its dust by 3.
21. The count never changes the bag or the save.
