# Intent: Running your day

Status: accepted
Product owner: Zkalf
Date: 2026-10-19

## Problem
The player can set only one activity at a time, and changing it means opening the app. Walking doesn't follow the
player's schedule, so steps end up spent badly:

- A fight keeps going long after it has stopped being useful: after the monster turns grey (intent 0002), or after
  the player has enough hides for a recipe. Those steps earn little, and to the player they feel wasted.
- When an activity ends while the app is closed, the rest of the walk goes to the step bank. The bank holds 1,500
  at level 1 and 6,000 at level 10, less than an average day of walking (about 5,000) for most of the early game,
  so steps overflow and are lost.
- Losing a fight earns nothing for the steps spent on it, and it ends the activity on a single unlucky roll.

The rule both intents share is that **steps never feel wasted**.

## Proposed outcome
The player plans a short day in a few seconds, and the game follows that plan while the phone stays in a pocket.

### Queue of 3 actions
- The queue unlocks at **level 5 with 2 actions** (about the end of day 1 for an average walker) and grows to
  **3 actions at level 8**. Both counts include the action running now. When one ends, the next starts by itself.
  Before level 5, the player does each activity by hand, as today.
- **Travel is automatic and doesn't use a slot.** If the next action is somewhere else, the character walks there
  first. The walk is paid with steps like any travel.
- **If an action can't start** (missing materials, monster already grey, not unlocked), it is skipped and the
  report says why.
- **When the queue is empty, the character rests** and steps go to the bank.
- **Stop ends the current action and moves on to the next one.** Queued actions can be removed one by one to
  clear the plan.
- Arranging the queue is free, like every choice that isn't an activity. As always, steps are synced first, so steps
  already walked aren't credited to the new plan.

### Stop conditions
Each action in the queue has its own stop condition:
- **Until grey:** for fights. Stops when the monster turns grey. This is the default for fights, so a new player never
  has to think about it.
- **Until I have N:** stops when the player owns N of an item (for example "until I have 4 goblin hides"), or for
  crafting, after N items are crafted. Crafting still also stops when materials run out.
- **Never:** keeps going. Only allowed in the last slot, since nothing after it would ever run.

Gathering never turns grey, so a gathering action in an earlier slot needs "until I have N".

### A bigger step bank
- **10,000 steps at level 1, +500 per level** (level 10: 14,500; level 30: 24,500). An average walker can go about
  two days without opening the app and lose nothing.
- This doesn't speed up the game: banked steps are steps already walked. It only makes the game more forgiving.
- Achievements and talents can raise the cap further. Their values are tuned later.

### Losing a fight
- **The loser keeps everything already earned.** No XP, items or levels are ever taken away, and there is no refund
  of the steps spent on rounds already fought.
- **A lost fight gives 75% of the XP for the share of the monster's health the player knocked off**, and no loot.
  Example: a zombie is brought down to 20% health before it wins, so 80% of its health was dealt and the player gets
  60% of its XP.
- **After 3 losses in a row, the action gives up** and the queue moves on (or the character rests). A win resets the
  count, so a single unlucky loss, or a few spread over many fights, no longer ends the plan.
- The report explains each loss: "Lost to a Zombie (knocked off 80% of its health), +12 XP."
- **Tuning guardrail:** each step up in monsters gives at most about a third more XP per step than the one below. Above
  that, losing to a stronger monster at 75% would earn more than winning against an even one.

### The report
The "while you were away" report says, for each action, what it earned and why it ended: grey, enough items, out of
materials, 3 losses, or arrival. It also says which action started next.

## Affected users and systems
- **Players:** everyone. Existing saves get the bigger bank cap straight away.
- **Game rules:** the current single activity becomes a queue with stop conditions; losing rules; bank cap numbers.
- **Screens:** building and editing the queue, choosing a stop condition, and a more detailed report.

## Constraints
- Depends on intent 0002 for monster levels and "grey".
- Balance for the average walker (about 5,000 steps a day). Bank cap, queue length and loss numbers live in data.
- The existing rules stay: the Stop button and switching never lose steps (unspent steps go to the bank), every
  action syncs steps first, and steps are credited per local day.
- Levels 1 to 10 are a natural tutorial with something new at each level, ending with talents at 10 (intent
  0002). The queue is part of that ladder: 2 actions at level 5, 3 at level 8.
- **Later, tuned separately:** a 4th queue slot as a talent or achievement reward, the Marathon reward and other
  bank cap bonuses, and an optional hardcore character (one life, a badge to prove it).

## Open questions
None blocking. The unlock levels, queue sizes, bank numbers and the 75% loss rate are starting values. How they
feel can only be judged by playing, so they are tuned on the phone.
