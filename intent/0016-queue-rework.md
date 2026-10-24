# Intent: Queue rework

Status: accepted
Product owner: Zkalf
Date: 2026-10-24

## Problem
The queue holds 3 actions from level 1 (spec 0008 decision 7). Travel to an action is automatic and takes no slot
(spec 0003 §4 step 2). Thus:
- A plan across five areas fits in the queue as easily as a plan in one area. The place of an action costs nothing
  in the plan.
- The queue does not show the walks between actions. The player does not see where those steps go.

The owner wants travel to take a place in the plan, so that travel is not free (issue #67).

## Proposed outcome

### 5 slots
1. The queue holds **5 actions** instead of 3. The count still includes the action that runs now.
2. The number lives in `queueSlots` in `economy.json`, as today.
3. Talents can add slots (intent 0015 outcome 4). The achievements rework (issue #56) may add one more slot later.

### Travel takes a slot
4. Travel is an action in the queue, like a fight, a gathering spot or a recipe.
5. A travel action takes one slot, however many legs its route has.
6. The player picks an action at another place, for example Mining at the Old Mine. The game then adds a travel
   action to the queue before the action.
7. The game plans the travel from the place where the action before it ends. A plan of two actions in the same
   area thus needs only one travel action.
8. If the queue has no room for the travel action and the action, the game refuses both. The message tells the
   player that the walk needs a slot too.
9. Travel keeps its step cost and its route (shortest open route, never through fog).
10. The player still sees each travel action on the queue card, with its destination and its distance in steps.

### Removing actions
11. When the player removes an action, the travel action before it stays in the queue. The game never removes a
    walk that the player did not remove.
12. That travel action becomes a plain travel action, like one from the Travel list. The player can remove it.
13. Example: the queue is "Travel to Camp, Craft". The player removes Craft and picks Smelt. The queue becomes
    "Travel to Camp, Smelt". The game adds no second travel action.
14. The player cannot remove a travel action while an action after it needs that walk. The game refuses with a
    message, for example "Mining needs this walk. Remove Mining first."
15. A new action still goes to the end of the queue. It does not fill the gap of a removed action.

### What stays
16. Stop, the stop conditions, the losses and the report keep their rules (spec 0003).
17. Arranging the queue stays free. Every change still syncs steps first.
18. Unspent progress still goes to the bank.

## Affected users and systems
- **Players:** everyone. A plan in one area gets 2 more slots. A plan across areas gets more slots, minus one for
  each walk.
- **Game rules:** the queue in `packages/game_core` (slots, the automatic travel, the check for a full queue).
- **Data:** `queueSlots` in `economy.json` becomes 5.
- **Save:** a queue in an old save loads. The game adds the travel actions that it needs, or keeps the old rule for
  that queue until it ends. The spec chooses. Each fixture in `app/test/fixtures/saves/` loads.
- **Screens:** the queue card and the action sheet show the travel actions and the slots they take.

## Constraints
- **No change to the pace.** Travel costs the same steps. The pacing sim does not use the queue. The pacing test
  in `check.ps1` stays green. A hand-run sim is not needed, unless the pacing test trips.
- **The screens come after Quiet Teal.** Plan 0017 is done, so the queue card can change now.
- All numbers live in `data/*.json`, never in code.
- Health data stays on the device. No network code.
- Where the idea comes from: the owner's idea (issue #67). The games in `docs/game-direction.md` do not have a
  queue like this one.
- Out of scope:
  - The order of queued actions. The player still removes and adds actions (spec 0003 §10).
  - The number of slots from talents. Spec 0015 sets it.

## Open questions
1. **Does a talent give +1 or +2 slots?** Spec 0015 chooses, with the other Utility talents. Recommendation: +1
   (6 slots in all).
