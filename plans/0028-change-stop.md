# Plan 0028: Build "Change the stop condition of an action"

Status: accepted
Spec: `specs/0016-queue-rework.amendment-2.md` · Product owner: Zkalf · Date: 2026-10-28

Names of files, widgets and tests refer to `main` at `a7e05f1`.

## What changes in the code
- `packages/game_core/lib/src/state.dart`: `RunningActivity.stop` is no longer `final`. A change sets it on the
  running action, so its progress, fight, losses, crafted count, gains and tally stay.
- `packages/game_core/lib/src/game.dart`:
  - `changeStop(s, index, stop, {events})`: index 0 is the current action, 1 the first waiting action, as in
    `removeAction`. It refuses, with `ActivityError`:
    - an index that names no action
    - a walk
    - a stop condition that `_checkStop` refuses
    - "Never" for an action that has another action after it
  - For the current action, `changeStop` then checks the new condition with `_stopMet`, as `_advance` does after a
    unit. If it is met and no fight is in progress, the action ends as in `_end`: the unspent progress goes to the
    bank, `ActivityEnded` goes to [events], and the next action starts. During a fight it does nothing more:
    `_advance` checks the condition when the fight ends.
  - For a waiting action, `changeStop` replaces its `PlannedAction`. It never checks the goal.
  - `stopReached(s, index, stop)`: true when the new goal is already reached. The change sheet uses it for its
    warning.
- `app/lib/game_controller.dart`: `changeStop(index, stop)` through `_actSkipping`, so the game syncs steps first.
  It returns the waiting actions that could not start, as `removeAction` does.
- `app/lib/ui/action_sheet.dart`: `ActionSheet` gets `change`, the queue index of the action to change (null: a new
  action, as today). With `change` set:
  - the sheet opens with the stop condition of the action; "Until I have N" with its item and number
  - "Never" shows only when the action is the last one
  - one button, "Change" (key `change-stop`), instead of "Start now" and "Add to queue"
  - no walk line, no "Your current plan never stops" line
  - the warning line of the amendment §3.3 when `stopReached` is true
- `app/lib/ui/actions.dart`:
  - `changeAction(context, controller, index)` opens the change sheet and calls `controller.changeStop`. It shows
    an `ActivityError` and the skipped actions in a snack bar, as `_stop` on Now does.
  - `ActionTile`: the "Active" row opens the change sheet for index 0. A walk or a reroll row stays as today.
- `app/lib/ui/now_tab.dart`: on the queue card, a tap on the name or the stop line of the current action opens the
  change sheet (key `change-0`). A tap on a waiting row opens it (key `queued-$i`). The remove and Stop buttons
  stay. Walks and rerolls open nothing.
- `releases/next.md`: one line for players.
- No change to the data, the save schema or the sim.

## Choices this plan makes
- **A reroll opens nothing**, as a walk. Its stop condition is always one roll (spec 0010 §7.2), so there is
  nothing to change. The amendment names only walks.
- **No new event for the report.** A change ended by a reached goal adds the same `ActivityEnded` as a goal reached
  on the way.

## Order of work
### M1: Change the stop condition (one PR)
- First, the failing tests, committed alone:
  - `packages/game_core/test/change_stop_test.dart`:
    - a change of the current action keeps its place, its progress, its fight in progress and its crafted count
      (criteria 11-15)
    - a change of the current action puts no steps into the bank when the goal is not reached (criterion 16)
    - a change to a reached goal ends the current action with "enough", banks its progress and starts the next
      action (criterion 19)
    - a change to a reached goal during a fight ends the action after that fight (criterion 20)
    - a waiting action with a reached goal stays in the queue (criterion 21)
    - "Never" is refused for an action with another action after it; a walk is refused (criteria 4, 9)
    - `stopReached` is true for a reached goal, false otherwise (criterion 18)
  - `app/test/change_stop_test.dart` (widget tests with `MemorySaveStore`):
    - a tap on the current action on Now, on its "Active" row, and on a waiting action opens the change sheet
      (criteria 1-3)
    - a tap on a walk opens nothing (criterion 4)
    - the sheet opens with the stop condition, item and number of the action (criteria 5-6)
    - the sheet shows "Change" and no "Start now" or "Add to queue" (criterion 7)
    - "Never" shows for the last action and hides for an earlier one; "Until grey" hides for a grey monster
      (criteria 8-10)
    - the warning shows when the goal is reached (criterion 18)
    - a test of the controller: steps walked before the change count with the old stop condition (criterion 17)
- Then the code.
- **Proof:** `.\scripts\check.ps1 -Release` green (criteria 22-24). The verifier checks the change against
  criteria 1-24.
- Branch `feat/change-stop`, in its own git worktree (sessions run in parallel). PR with the amendment and this
  plan, review per `REVIEW.md`. The owner merges.
