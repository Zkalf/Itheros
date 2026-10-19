# Spec 0003: Running your day

Status: accepted
Intent: [intent/0003-running-your-day.md](../intent/0003-running-your-day.md) (accepted, commit 70469b0)
Builds on: [spec 0002](0002-levels-that-matter.md) + amendment 1 (monster levels, "grey", the level ladder)
Product owner: Zkalf
Date: 2026-10-19

The single activity becomes a short queue of actions, each with a stop condition. Travel to an action is
automatic. Losing a fight earns part of the XP and only ends the action after 3 losses in a row. The step bank
grows to 10,000 at level 1. All numbers live in data.

## 1. Decisions
The intent left no open questions. These are the details it didn't fix, decided for the build.

| # | Question | Decision |
|---|---|---|
| 1 | Queue before level 5 | The queue has **1 slot** before level 5 (2 at level 5, 3 at level 8). Picking a new activity replaces the current one, as today. |
| 2 | Automatic travel before level 5 | Yes, for everyone. Picking a fight, spot or recipe elsewhere walks there first along the shortest open route. Travel stays available as an action of its own (it ends on arrival). |
| 3 | Adding behind a "never" action | Refused, with the message "The last action never stops. Change its stop condition first." |
| 4 | "Until I have N" before level 5 | Not offered (the ladder unlocks it at 5). Fights default to "until grey"; gathering and crafting to "never", as today. |
| 5 | Where crafting happens | At the crafting location nearest to the character when the action starts. |
| 6 | Lost-fight XP and fading | The 75% share is faded by the monster's colour like any XP, and is at least 1 if any damage was done. |
| 7 | The level ladder | Levels 5 and 8 now show the queue lines on their level-up cards (spec 0002 §8). |

## 2. The queue
- The queue holds up to `queueSlots` actions for the player's level (data: 1 from level 1, 2 from 5, 3 from 8).
  The count includes the running action, which is always the first.
- **Actions:** fight a monster, gather at a spot, craft a recipe, travel to a location.
- **Adding:** a new action goes to the end of the queue. With an empty queue it starts at once. With a 1-slot
  queue it replaces the current action (decision 1). A full queue refuses with "The queue is full."
- **Removing:** any queued action can be removed. Removing the running one is the same as **Stop**.
- **Stop:** ends the running action and starts the next one. With nothing next, the character rests.
- Arranging the queue is free. Every change syncs steps first, so steps already walked go to the old plan
  (spec 0001 §2.1 rule, unchanged). Unspent progress of a stopped or replaced action goes to the bank (spec 0001
  amendment 2, unchanged).

## 3. Stop conditions
| Condition | For | Stops when |
|---|---|---|
| Until grey (default for fights) | fights | the monster is grey for the player (spec 0002 §3) |
| Until I have N | fights, gathering | the player owns N of the chosen item (inventory plus equipped) |
| Until N crafted | crafting | N items were crafted by this action |
| Never | all | never; only allowed for the last action |

- A fight's "until I have N" item is one of the monster's drops. Gathering's item is the spot's item.
- Crafting also stops when materials run out (unchanged). Travel always ends on arrival.
- **Validation:** "never" is only allowed in the last slot. Gathering in an earlier slot needs "until I have N"
  (gathering never turns grey).
- Conditions are checked before an action starts and after each unit (fight, item, craft). They aren't checked
  in the middle of a fight: the fight in progress finishes first.

## 4. Running an action
1. **Can it start?** It is skipped, with a reason, if: it isn't unlocked; its stop condition is already met
   (the monster is already grey, the player already has N); a craft lacks materials; or no open route reaches it.
2. **Travel:** if the action belongs somewhere else, the character walks there leg by leg along the shortest open
   route. Each leg costs its route's steps, like travel today. Travel belongs to the action and takes no slot.
3. **Work:** units run as today (combat rounds, ore, crafts).
4. **Ends** with one of these reasons: grey, enough (N reached), out of materials, 3 losses, arrived (travel
   actions), stopped by the player, or skipped (with why). The next action then starts the same way.
5. **Queue empty:** the character rests and steps go to the bank.

## 5. Losing a fight
- A loss keeps everything already earned and refunds nothing.
- It gives `lossXpShare` (75%) of the monster's XP times the share of its health the player knocked off,
  faded by colour (decision 6). Example: a zombie brought to 20% health gives 0.75 × 0.8 = 60% of its XP.
- No loot.
- After `lossesToGiveUp` (3) losses in a row in one action, the action ends ("3 losses"). A win resets the count.

**Guardrail (intent 0003):** each monster gives at most a third more XP per step than the one below it. Spec 0002
criterion 4 already tests this.

## 6. The step bank
`cap = 9,500 + 500 × level` (level 1: 10,000; level 10: 14,500; level 30: 24,500), plus achievement bonuses as
today. Existing saves get the new cap at once.

## 7. The report
For each action that ran while the player was away, in order: what it earned (XP, wins and losses, items) and why
it ended. Then which action started next. Examples:
- "Fought the Skeleton: 41 wins, +780 XP, Bones ×24. Stopped: the Skeleton turned grey. Next: Zombie."
- "Lost to a Zombie (knocked off 80% of its health), +37 XP." (one line per loss, with its loss hint from spec 0002)
- "Skipped the Bone shield: not enough Bones."
- The existing lines (steps walked, banked, lost to a full bank, levels, achievements) stay.

## 8. Screens
- **The queue card** replaces the current-activity card: each action with its stop condition and progress (for
  example "Bones 4 / 10"), a **Stop** button on the running one and a remove button on the others.
- **Choosing an action:** tapping an activity opens a small sheet with its stop condition (default preselected)
  and **Start now** (replaces the running action) or **Add to queue** (if there is room). Below level 5 it starts
  at once, as today.
- **Stop condition picker:** "Until grey", "Until I have N" with the item and a number, "Until N crafted",
  "Never". Choices that aren't allowed in that slot are hidden.
- The fight, gather and craft lists show every unlocked option in the world, grouped by area, with the travel
  distance, so the player can plan a day without walking there first. Travel stays as its own list.

## 9. Save
Save schema 3: the running activity becomes a queue. A version 2 save's activity becomes a 1-action queue with
the default stop condition for its kind. Its progress and fight in progress carry over.

## 10. Out of scope
A 4th slot as a reward, achievement and talent bonuses to the bank, the Marathon reward, a hardcore character,
reordering queued actions (remove and add instead).

## 11. Acceptance criteria
1. The queue holds 1 action before level 5, 2 from level 5, 3 from level 8. Adding past that is refused.
2. When an action ends, the next starts by itself, walking there first along the shortest open route. Travel takes
   no slot.
3. An action that can't start is skipped, and the report says why.
4. "Until grey" stops a fight when the monster turns grey; "until I have N" when N are owned; "until N crafted"
   after N crafts. "Never" is refused anywhere but the last slot, and gathering in an earlier slot needs "until I
   have N".
5. Stop ends the running action and starts the next. Removing a queued action leaves the rest in order.
6. A lost fight gives 75% of the XP for the health share knocked off (faded), no loot, and keeps everything earned.
7. After 3 losses in a row the action ends; a win in between resets the count.
8. The bank cap is 10,000 at level 1 and grows by 500 per level.
9. The report lists each action's earnings and end reason, and what started next.
10. A version 2 save loads with its running activity as a 1-action queue, nothing lost.
11. Spec 0002's pacing tests stay green (simulated player uses the queue the same way it played before).
12. `.\scripts\check.ps1 -Release` is green, and the release build still declares no INTERNET permission.
