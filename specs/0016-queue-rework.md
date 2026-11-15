# Spec 0016: Queue rework

Status: accepted
Intent: [intent/0016-queue-rework.md](../intent/0016-queue-rework.md) (accepted, commit 182bf36)
Builds on: spec 0003 (the queue, stop conditions, the report), spec 0008 decisions 6–7 (fog, slots from level 1)
Overrides:
- spec 0003 decision 2 and §4 step 2 (automatic travel without a slot)
- spec 0003 §2 "Adding" (the 1-slot queue) and §8 "Start now" (it replaced only the running action)
- spec 0003 criteria 1–2
- spec 0008 decision 7 (3 slots) and criterion 3 (the queue takes 3 actions)
Product owner: Zkalf
Date: 2026-10-24

The queue holds 5 actions. Travel is an action in the queue and takes a slot. When the player picks an action at
another place, the game adds a travel action before it. A removed action leaves its travel action in the queue.
Start now with actions in the queue clears the queue first. Steps, routes and the pace do not change.

## 1. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | Stop on a running travel action that the next action needs | **Refused, like a removal** (owner's choice, review of PR #75). The message is the one of §4.3. |
| 2 | Start now with actions in the queue | **It clears the queue first** (owner's choice). The button then reads "Start now, clear queue". A confirm dialog is not used. |
| 3 | Where the game plans an action | At the place where the queue stands before it (§3.1). The game never stores a place for an action. |
| 4 | An action that starts at the wrong place | **Skipped**, and the report says why. The game never adds a walk when an action starts. |
| 5 | Old saves | The game adds the travel actions that the old queue needs (§6). The queue may then hold more than 5 actions. It shrinks as the actions end. |
| 6 | Talent slots | Out of scope. Spec 0015 adds them through `queueSlots(state)`. |
| 7 | Where a tap changes a stop condition | **Both places** (owner, 2026-10-28). The current action on Now, and its "Active" row in the lists, open the same sheet. |
| 8 | Can a waiting action change its stop condition? | **Yes, the same way** (owner, 2026-10-28). A tap on a waiting action on Now opens the sheet. |
| 9 | The new goal is already reached | **The action stops at once**, as when it reaches its goal on the way (owner, 2026-10-28). A fight in progress finishes first. |

## 2. Slots
- `queueSlots` in `economy.json` becomes **5**. The count includes the running action.
- A data check refuses `queueSlots` below 2. An action and its travel action must fit in an empty queue.
- The 1-slot queue of spec 0003 §2 goes. "Add to queue" never replaces the running action.
- Spec 0015 (the Quartermaster talent) and spec 0017 §3.4 (Chieftain's Bane) add slots through `queueSlots(state)`.

## 3. Travel in the queue

### 3.1 Where the queue stands
The game reads the queue from the front to the back:
1. Before the first action, the queue stands where the character stands. A running travel action moves this place
   to its destination.
2. A travel action moves the place to its destination.
3. Any other action leaves the place as it is. A fight, a gathering spot, a recipe or a reroll happens where the
   queue stands.

The place at the end of the queue is the **end place**.

### 3.2 Adding an action
When the player adds an action that is not travel:
1. If the action can happen at the end place, the game adds only the action.
2. Otherwise the game picks the nearest place for the action, from the end place. "Nearest" uses the open routes
   and the fog of now. The rules of spec 0003 pick the place: the monster's area, the spot's area, the nearest
   crafting place for the recipe, or the nearest forge for a reroll.
3. The game adds a travel action to that place, then the action. The two take 2 slots.

When the player adds a travel action from the Travel list, it takes 1 slot. A travel action to the end place is
refused with "The queue already ends at Camp."

### 3.3 Refusals
| Case | Message |
|---|---|
| No free slot | "The queue is full." |
| One free slot, and the action needs a travel action | "The queue is full. The walk to Old Mine needs a slot too." |
| The last action never stops | "The last action never stops. Change its stop condition first." (spec 0003) |
| No open route to any place for the action | "The way there is in the fog" (spec 0008) |
| The only route crosses the closed road | "Beat the Graveyard King to cross." (spec 0008 §2.3, since amendment 5) |

Travel actions never stop on a condition. "Never" stays allowed only for the last action that is not travel.

### 3.4 Running a travel action
- A travel action walks leg by leg along the shortest open route of the moment, as before.
- Each leg costs its route's steps, as before. Since spec 0015 the Light pack and Wayfarer talents, and since spec
  0021 the overload of a full bag, change the steps of a leg (spec 0021 §2).
- It ends on arrival.

### 3.5 Starting an action
- An action that is not travel starts only where it can happen.
- If the character stands somewhere else, the game skips the action. The reason is **not there**.
- The report reads, for example, "Mining: you are not at the Old Mine." For a recipe: "Smelt copper: you are not
  at a forge."
- The other skip reasons of spec 0003 §4 stay. Since spec 0008 amendment 5 a waiting action whose place lies beyond
  the closed road is skipped with the reason `noRoute`.

## 4. Removing actions

### 4.1 An action that is not travel
- The player can remove it. The travel action before it stays.
- The place of the queue does not change (§3.1), so no other action moves.

### 4.2 A travel action
- A travel action is **needed** when the action right after it is not travel and cannot happen at the place where
  the queue stands before the travel action.
- The player can remove a travel action that is not needed.
- The game refuses to remove a needed travel action.

### 4.3 The message
"Mining needs this walk. Remove Mining first." The name is the name of the action after the travel action.

### 4.4 Stop
- Stop on a running action that is not travel works as before: the next action starts.
- Stop on a running travel action follows §4.2: the game refuses Stop on a needed travel action (decision 1).
- Unspent progress of a stopped action goes to the bank, as before.

### 4.5 Changing the stop condition
Without this the player could not change the stop condition of an action after it started. To change the item or the
number of "Until I have N", the player had to stop the action and start it again, which gave its unspent progress to
the bank and ended a fight in progress (#116).

**The change sheet**
- A tap on the current action opens the **change sheet** (decision 7). The places to tap are:
  - the current action on the queue card of Now;
  - the "Active" row of the action in a list (Here, a profession screen, the World map).
- A tap on a waiting action on the queue card opens the change sheet too (decision 8). A tap on its remove button
  removes it, as before.
- The change sheet is the action sheet of spec 0003 §8, with these differences:
  - The stop condition of the action is selected when the sheet opens.
  - One button replaces "Start now" and "Add to queue": **"Change"**.
  - The sheet does not show the walk line of §7.2.
- A fight keeps its bestiary card on top of the sheet (spec 0009 decision 11).
- A walk has no stop condition. A tap on a walk opens nothing.
- The picker keeps its rules:
  - "Never" shows only for the last action (spec 0003 §3).
  - "Until grey" does not show for a monster that is already grey.
  - "Until I have N" names only found drops (spec 0006 criterion 6).
- "Until I have N" opens with the item and the number of the action. A new item picks its number as before: what
  the player has, plus 5 (#113).

**What a change does**
- The game syncs steps first, as for every player action. Steps from before the change count with the old stop
  condition.
- The action keeps its place in the queue.
- The action keeps all of its progress:
  - the steps paid toward its unit;
  - the fight in progress;
  - the fights lost in a row;
  - the items crafted by this action ("Until N crafted" counts them);
  - the items gained by this action ("Until quality" counts them);
  - its tally for the report.
- Nothing stops or starts again. No progress goes to the bank. A change costs no steps.

**A goal that is already reached** (decision 9)
- **The current action:** the game checks the new stop condition at once, as after each unit (spec 0003 §3).
  - If the goal is reached, the action ends with its reason (grey or enough). The next action starts.
  - Unspent progress goes to the bank, as when an action ends.
  - A fight in progress finishes first. The game checks the condition after the fight (spec 0003 §3).
- **A waiting action:** the game keeps it. It is skipped when it starts, if the goal is still reached then
  (spec 0003 §4, "already done").
- The change sheet warns before the tap, under the picker: "You have this already. The action stops now." For a
  waiting action: "You have this already. The action will be skipped."

## 5. Start now
- **Empty queue:** Start now replaces the running action, as before. If the action needs a travel action (§3.2), the
  travel action runs and the action waits after it.
- **Actions in the queue:** the button reads **"Start now, clear queue"**. A tap removes every waiting action,
  travel actions too. Then Start now works as with an empty queue.
- §4.2 does not apply here. The cleared queue holds no action that needs a walk.
- Unspent progress of the replaced action goes to the bank, as before.
- The action is the last one, so "never" is allowed. The stop condition picker keeps its rules (spec 0003 §8).

## 6. Save
- Save schema 11. The JSON shape does not change.
- A version 10 save loads as follows:
  1. A running action that is not travel and that walks (it has a leg) becomes a running travel action to its
     place. The progress paid toward the leg stays. The action waits first in the queue, with its stop condition.
  2. The game then reads the queue from the front (§3.1). Before each action that cannot happen where the queue
     stands, the game adds a travel action to its nearest place (§3.2).
- The queue may hold more than `queueSlots` actions after this (decision 5). The game refuses new actions until
  it has room.
- Each fixture in `app/test/fixtures/saves/` loads. No step, item or XP is lost.

## 7. Screens

### 7.1 The queue card
- Each travel action has its own line: "Walk to Old Mine · 1,200 steps". The steps are the shortest open route
  from where the queue stands before it.
- A running travel action keeps its walk bar.
- A tap on the remove button of a needed travel action removes nothing. It shows the message of §4.3.
- The slot count ("3 of 5 actions planned") counts travel actions.
- A tap on an action opens the change sheet of §4.5.
- Since spec 0014 amendment 8 each row starts with the action's picture, with its number as a badge.

### 7.2 The action sheet
- If the action needs a travel action, the sheet says "Walk to Old Mine first: 1,200 steps, one more slot."
- "Add to queue" shows the refusal of §3.3 when there is no room.
- The Start now button follows §5.

### 7.3 The report
The "while you were away" report lists travel actions like other actions: "Walked to Old Mine (1,200 steps)." The
skip of §3.5 reads as in §3.5.

### 7.4 One word for a walk
The game showed one action with two words, "travel" and "walk", and the owner read the change of word as a change of
action (owner, 2026-10-24: "walk everywhere"). `WRITING.md` rule 1 asks for one name for each thing; the glossary
names this action a **walk**.
- The button on the area sheet of the World map reads **"Walk here"** (spec 0006 §2.2, as spec 0008 §3.3 keeps it).
- A waiting walk on the queue card reads **"Walk to Copper Hills · 300 steps"** (§7.1).
- Every other text of a walk uses "walk": "Walk to Copper Hills first: 300 steps, one more slot." on the action sheet,
  "Walking to Copper Hills" for the current action, "Walked to Copper Hills (300 steps)." in the report.
- The code keeps its names (`Activity.travel`, `ActivityKind.travel`, `leg`). Players never see them.
- The achievement "Travelling Salesman" keeps its name. It is the name of an achievement, not the name of the action.

## 8. Balance
- No change to the pace. Travel costs the same steps as before.
- The pacing walkers do not queue. They start each action with an empty queue, so §5 keeps their walks.
- The pacing test in `check.ps1` stays green. A hand-run sim is not needed, unless the pacing test trips.

## 9. Out of scope
- The order of queued actions (spec 0003 §10). A new action goes to the end.
- A confirm dialog or an undo for "Start now, clear queue".
- A change of the action itself (another monster, spot or recipe). The player removes the action and adds a new one.
- An undo for a change of a stop condition.

## 10. Acceptance criteria

**Slots**
1. A new save has 5 queue slots.
2. The running action counts as one of the 5 slots.
3. A travel action counts as one slot, however many legs its route has.
4. The data check refuses `queueSlots` below 2.

**Adding**
5. An action that can happen at the end place goes into the queue alone.
6. An action that cannot happen at the end place goes in after a new travel action to its nearest place.
7. Two actions in the same area, added one after the other, take one travel action.
8. With one free slot, an action that needs a travel action is refused with "The queue is full. The walk to Old
   Mine needs a slot too."
9. A travel action from the Travel list to the end place is refused with "The queue already ends at Camp."

**Starting**
10. A travel action walks the shortest open route of the moment and costs the same steps as before.
11. An action that starts where it cannot happen is skipped, and the report says that the player is not there.
12. No action starts a walk of its own.

**Removing**
13. When the player removes an action that is not travel, the travel action before it stays.
14. The player can remove a travel action that is not needed.
15. The game refuses to remove a needed travel action, with "Mining needs this walk. Remove Mining first."
16. The game refuses Stop on a needed running travel action, with the same message.
17. Stop on a running action that is not travel starts the next action, as before.

**Start now**
18. With an empty queue, Start now on an action at another place runs a travel action, then the action.
19. With actions in the queue, the button reads "Start now, clear queue".
20. "Start now, clear queue" removes every waiting action, travel actions included.
21. Unspent progress of the replaced action goes to the bank.

**Save**
22. A version 10 save with a running action that walks loads as a running travel action, with the action next.
23. A version 10 save loads with a travel action before each waiting action that needs one.
24. A loaded queue with more than 5 actions keeps them all and refuses new actions until it has room.
25. Each fixture in `app/test/fixtures/saves/` loads, with no step, item or XP lost.

**Screens**
26. The queue card shows each travel action on its own line, with its destination and its steps.
27. The slot count on the queue card counts travel actions.
28. The action sheet says when the action needs a walk first, with its steps.

**Release**
29. The pacing test in `check.ps1` stays green.
30. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

**One word for a walk**
31. The area sheet of a place where the character is not shows the button "Walk here".
32. No screen shows the button "Travel here".
33. The queue card shows a waiting walk as "Walk to Copper Hills · 300 steps".
34. No screen shows a waiting walk as "Travel to …".

**Changing the stop condition: opening the sheet**
35. A tap on the current action on Now opens the change sheet.
36. A tap on the "Active" row of the current action in a list opens the change sheet.
37. A tap on a waiting action on Now opens the change sheet.
38. A tap on a walk opens nothing.
39. The change sheet opens with the stop condition of the action selected.
40. "Until I have N" opens with the item and the number of the action.
41. The change sheet shows one button, "Change", and no "Start now" or "Add to queue".

**Changing the stop condition: picker rules**
42. The change sheet shows "Never" for the last action in the queue.
43. The change sheet hides "Never" for an action that has another action after it.
44. The change sheet hides "Until grey" for a monster that is already grey.

**Changing the stop condition: the change**
45. After a change, the action has the new stop condition.
46. After a change, the action keeps its place in the queue.
47. After a change, the steps paid toward the unit of the current action stay.
48. After a change, a fight in progress goes on with the same rounds.
49. After a change, "Until N crafted" counts the items that the action crafted before the change.
50. A change puts no steps into the bank when the new goal is not reached.
51. The game syncs steps before the change.

**Changing the stop condition: a goal that is already reached**
52. The change sheet warns, before the tap, when the new goal is already reached.
53. A change of the current action to a reached goal ends it with "enough" or "grey", and the next action starts.
54. A change of the current action to a reached goal during a fight ends the action after that fight.
55. A waiting action with a reached goal stays in the queue after the change.

## History
- 2026-10-24: first version (intent 0016, plan 0018). Criteria 1-30.
- 2026-10-24, amendment 1 (plan 0019): one word for a walk, "Walk here" and "Walk to …". §7.1; §7.4; criteria 31-34.
- 2026-10-24, spec 0017: Chieftain's Bane adds a queue slot. §2; §9.
- 2026-10-28, amendment 2 (#116, plan 0028): change the stop condition of an action. Decisions 7-9; §4.5; §7.1; §9;
  criteria 35-55.
- 2026-10-31, spec 0015: the Quartermaster talent adds a queue slot; Light pack and Wayfarer cut the steps of a leg.
  §2; §3.4; §9.
- 2026-11-02, spec 0021: the overload of a full bag raises the steps of a leg. §3.4.
- 2026-11-06, spec 0014 amendment 8 (#86, plan 0047): pictures on the queue card. §7.1.
- 2026-11-07, spec 0008 amendment 5 (#233, plan 0055): the closed road; its refusal and its skip. §3.3; §3.5.
- 2026-11-15 (plan 0068): the amendments folded into this file. "As today" now reads "as before", and "(today)"
  names the spec of the rule: the words "today" would go stale in a living file. No rule, number or criterion
  changed. (draft)
