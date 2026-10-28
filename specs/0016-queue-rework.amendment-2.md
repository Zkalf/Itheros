# Spec 0016 amendment 2: change the stop condition of an action

Status: accepted
Amends:
- [spec 0016](0016-queue-rework.md) §4 (actions in the queue) and §7.1 (the queue card)
- [spec 0003](0003-running-your-day.md) §8 (the stop condition picker and the "Active" row)
Issue: #116
Product owner: Zkalf (decided on 2026-10-26 that this is needed, and chose "tap to change")
Date: 2026-10-28

## Why
- The player cannot change the stop condition of an action after it starts.
- The current action shows "Active" in the lists, and that row does not open.
- To change the item or the number of "Until I have N", the player must stop the action and start it again.
- A stop gives the unspent progress to the bank, and a fight in progress ends.

## Decisions

| # | Question (issue #116) | Decision |
|---|---|---|
| 1 | Where does the tap go? | **Both places.** The current action on Now, and its "Active" row in the lists, open the same sheet. |
| 2 | Can a waiting action change its stop condition? | **Yes, the same way.** A tap on a waiting action on Now opens the sheet. |
| 3 | The new goal is already reached | **The action stops at once**, as when it reaches its goal on the way. A fight in progress finishes first. |

Claude proposed decisions 1-3. The owner accepts or changes them with this amendment.

## Change

### 1. The change sheet
1. A tap on the current action opens the **change sheet**. The places to tap are:
   - the current action on the queue card of Now
   - the "Active" row of the action in a list (Here, a profession screen, the World map)
2. A tap on a waiting action on the queue card opens the change sheet too. A tap on its remove button removes it, as
   today.
3. The change sheet is the action sheet of spec 0003 §8, with these differences:
   - The stop condition of the action is selected when the sheet opens.
   - One button replaces "Start now" and "Add to queue": **"Change"**.
   - The sheet does not show the walk line of spec 0016 §7.2.
4. A fight keeps its bestiary card on top of the sheet (spec 0009 decision 11).
5. A walk has no stop condition. A tap on a walk opens nothing.
6. The picker keeps its rules:
   - "Never" shows only for the last action (spec 0003 §3).
   - "Until grey" does not show for a monster that is already grey.
   - "Until I have N" names only found drops (spec 0006 criterion 6).
7. "Until I have N" opens with the item and the number of the action. A new item picks its number as today: what
   the player has, plus 5 (#113).

### 2. What a change does
1. The game syncs steps first, as for every player action. Steps from before the change count with the old stop
   condition.
2. The action keeps its place in the queue.
3. The action keeps all of its progress:
   - the steps paid toward its unit
   - the fight in progress
   - the fights lost in a row
   - the items crafted by this action ("Until N crafted" counts them)
   - the items gained by this action ("Until quality" counts them)
   - its tally for the report
4. Nothing stops or starts again. No progress goes to the bank.

### 3. A goal that is already reached
1. **The current action:** the game checks the new stop condition at once, as after each unit (spec 0003 §3).
   - If the goal is reached, the action ends with its reason (grey or enough). The next action starts.
   - Unspent progress goes to the bank, as when an action ends.
   - A fight in progress finishes first. The game checks the condition after the fight (spec 0003 §3).
2. **A waiting action:** the game keeps it. It is skipped when it starts, if the goal is still reached then
   (spec 0003 §4, "already done").
3. The change sheet warns before the tap, under the picker: "You have this already. The action stops now." For a
   waiting action: "You have this already. The action will be skipped."

### 4. What stays
- The rules of each stop condition (spec 0003 §3).
- The queue, its slots, its walks and their order (spec 0016).
- The save. Its JSON shape does not change. The save schema stays at its number.
- The pace. A change of a stop condition costs no steps.

## Out of scope
- A change of the action itself (another monster, spot or recipe). The player removes the action and adds a new one.
- A change of the order of the queue (spec 0016 §9).
- An undo for a change.

## Acceptance criteria
**Opening the sheet**
1. A tap on the current action on Now opens the change sheet.
2. A tap on the "Active" row of the current action in a list opens the change sheet.
3. A tap on a waiting action on Now opens the change sheet.
4. A tap on a walk opens nothing.
5. The change sheet opens with the stop condition of the action selected.
6. "Until I have N" opens with the item and the number of the action.
7. The change sheet shows one button, "Change", and no "Start now" or "Add to queue".

**Picker rules**
8. The change sheet shows "Never" for the last action in the queue.
9. The change sheet hides "Never" for an action that has another action after it.
10. The change sheet hides "Until grey" for a monster that is already grey.

**The change**
11. After a change, the action has the new stop condition.
12. After a change, the action keeps its place in the queue.
13. After a change, the steps paid toward the unit of the current action stay.
14. After a change, a fight in progress goes on with the same rounds.
15. After a change, "Until N crafted" counts the items that the action crafted before the change.
16. A change puts no steps into the bank when the new goal is not reached.
17. The game syncs steps before the change.

**A goal that is already reached**
18. The change sheet warns, before the tap, when the new goal is already reached.
19. A change of the current action to a reached goal ends it with "enough" or "grey", and the next action starts.
20. A change of the current action to a reached goal during a fight ends the action after that fight.
21. A waiting action with a reached goal stays in the queue after the change.

**Check and release**
22. Rules, numbers and the save schema do not change. The pacing test passes.
23. Each fixture in `app/test/fixtures/saves/` loads.
24. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
