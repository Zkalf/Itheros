# Plan 0018: Build "Queue rework"

Status: accepted
Spec: `specs/0016-queue-rework.md` (accepted, commit 32ab615) · Intent: `intent/0016-queue-rework.md` (accepted,
commit 182bf36)
Product owner: Zkalf · Date: 2026-10-24

## What changes in the code

### `packages/game_core`
- **Data:** `queueSlots` in `economy.json` becomes 5. The data check in `data.dart` refuses values below 2.
- **Where the queue stands (spec §3.1):** a new helper reads the queue from the front and returns the place before
  each action and the end place.
- **`_placeFor` and `_paths`** take a start place, so the game can plan from the end place instead of the
  character's place.
- **`addAction` (spec §3.2–3.3):** adds a travel action first when the action cannot happen at the end place. It
  gives the new refusals. The 1-slot branch goes.
- **`startActivity` (spec §5):** clears the queue, then starts a travel action and puts the action after it when
  the action happens elsewhere.
- **Starting an action (spec §3.5):** an action that is not travel never gets a leg. It starts only where it can
  happen. Otherwise `_startNext` skips it with the new `SkipReason.notThere`.
- **`removeAction` and `stopActivity` (spec §4):** refuse a needed travel action with the §4.3 message.
- **Save (spec §6):** `schemaVersion` 11. The version 10 migration turns a walking running action into a travel
  action plus the action, and adds the travel actions that the old queue needs.
- **Pacing walkers:** no change. `simulation.dart` starts each action with an empty queue, and it rerolls only at
  a forge. No sim run and no new pacing test (owner's choice). The pacing test inside `check.ps1` runs as
  always.

### `app`
- `action_sheet.dart`, `actions.dart`: the "Walk to Old Mine first" line, the refusals, and the "Start now, clear
  queue" label. The 1-slot path in `actions.dart` goes.
- `now_tab.dart`: one line for each travel action with its steps, the slot count, and the remove button of a
  needed travel action.
- The report: the "not there" skip line and the "Walked to" line.

### No change
- Health data, the step sources and the sync.
- Routes, step costs, fog, the stop conditions, the losses.

## Order of work

### M1: Rules, data and save (one PR)
- Failing tests first, committed alone: `packages/game_core/test/queue_test.dart` and a migration test with a
  version 10 save. They cover spec criteria 1–25 and 29.
- Then the code in `game_core` and `economy.json`.
- Old tests that expect 3 slots or a walk without a slot (`layout_test.dart`, `queue_test.dart`) change in the same
  PR. Spec 0016 overrides the criteria they check.
- The app keeps working: it calls the same `Game` methods. Screen texts wait for M2.
- **Proof:** `.\scripts\check.ps1` green. Each fixture in `app/test/fixtures/saves/` loads. The verifier checks
  the change against spec criteria 1–25 and 29.
- Branch `plan18-m1`, PR, review per `REVIEW.md`. The owner merges.

### M2: Screens (one PR)
- Failing widget tests first (with `MemorySaveStore`), committed alone, for spec criteria 19 and 26–28 and the
  texts of spec §7.
- Then the screens.
- **Proof:** `.\scripts\check.ps1 -Release` green. The verifier checks the change against spec criteria 19 and
  26–30.
- Branch `plan18-m2`, PR, review per `REVIEW.md`. The owner merges.
- At the end of M2, Claude asks the owner whether to install it on the phone for a playtest.

## Risks
| Risk | Mitigation |
|---|---|
| An old save loses a walk in the middle of a route | Spec criterion 22 test with a version 10 save whose running action has a leg |
| A monster or spot in two areas picks a different place than today | Tests for the nearest place from the end place, with a monster in two areas |
| The app shows the old text for a refusal | M2 widget tests for each message of spec §3.3 and §4.3 |
