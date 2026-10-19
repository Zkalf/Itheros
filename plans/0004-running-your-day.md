# Plan 0004: Build "Running your day"

Status: accepted
Spec: `specs/0003-running-your-day.md` · Intent: `intent/0003-running-your-day.md` (accepted, 70469b0)
Product owner: Zkalf · Date: 2026-10-19

## What changes in the code
- **`packages/game_core/lib/src/state.dart`:** `GameState.activity` becomes `queue: List<QueuedAction>`
  (activity, stop condition, progress, fight in progress, legs left to walk, losses in a row, crafted count).
  Schema 3; a version 2 save's activity becomes a 1-action queue.
- **`activity.dart`:** `StopCondition` (untilGrey, untilHave(item, n), untilCrafted(n), never) with JSON.
- **`game.dart`:** `addAction`, `removeAction`, `stopAction` replace `startActivity`/`stopActivity`
  (kept as thin wrappers where the app or tests still need them). The step loop runs the head of the queue:
  start checks and skips, shortest-route travel legs, units, stop-condition checks, the loss rules, then the next
  action. New events: `ActionStarted`, `ActionSkipped`, `ActionEnded` (with reason), `FightLost` gains XP and the
  health share.
- **`data/economy.json`:** `bankCap` base 9,500; `queueSlots` by level; `lossXpShare` 0.75; `lossesToGiveUp` 3.
  `levelNews` gains a `feature` kind for the queue lines at levels 5 and 8.
- **`lib/simulation.dart`:** the scripted player queues one action at a time, so pacing stays comparable.
- **App:** `GameController` gets `addAction`/`removeAction`/`stop`; the queue card, the action sheet with the stop
  condition picker, world-wide activity lists grouped by area, and the per-action report.

## Order of work
### M1: Rules, tests first
Failing tests first, committed: queue size by level and refusal (criterion 1); auto-travel and next action
(2); skips with reasons (3); every stop condition and the validation rules (4); stop and remove (5); loss XP and
no loot (6); 3 losses in a row and the reset (7); bank cap (8); v2 → v3 migration (10). Then implement.
**Proof:** `.\scripts\check.ps1` green, including spec 0002's pacing tests (criterion 11).

### M2: Screens
Queue card, action sheet with the stop condition picker, world-wide lists with travel distance, the per-action
report (criterion 9), level 5 and 8 cards. Widget tests with `MemorySaveStore`.
**Proof:** check green.

### M3: On the phone
`.\scripts\check.ps1 -Release`, then `.\scripts\device-smoke.ps1 -Install`; the save carries over. The verifier
checks the change against spec 0003. The owner playtests.

## Risks
| Risk | Mitigation |
|---|---|
| The step loop gets complicated (travel inside actions, skips, conditions) | One small state machine per action, tested step by step; the worked examples become tests |
| Losing now pays XP, so the sim player might farm losses | The intent's guardrail is already tested (criterion 4 of spec 0002); the pacing tests catch drift |
| The bigger bank changes pacing | Banked steps are walked steps; the sim runs with the same rules and the pacing tests must stay green |
