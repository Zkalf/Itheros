# Plan 0005: Build "Journal and test walks"

Status: accepted
Spec: `specs/0004-journal-and-test-walks.md` · Intent: `intent/0004-journal-and-test-walks.md`
Product owner: Zkalf · Date: 2026-10-19

## What changes in the code
- **`game_core/lib/src/game.dart`:** on every arrival, count `visited.<area>` once and `areas.visited`; a new game
  counts its start area; `migrate` counts the current area for older saves. **`data/achievements.json`:**
  Travelling Salesman. **`data/economy.json`:** `journalEntries: 20`.
- **`app/lib/sync/away_summary.dart`:** `AwaySummary` and `ActionLog` to and from JSON.
- **`app/lib/persistence/save_data.dart`:** save version 3 adds `journal` (entries: start time, test-walk flag,
  summary) and `testWalk` (switch). Version 2 saves load with an empty journal.
- **`app/lib/game_controller.dart`:** the report writes into the newest journal entry and saves; `testWalk(n)`
  syncs, applies `n` steps, and makes its own entry; `setTestWalk(on)`.
- **`app/lib/ui/`:** Journal screen and top-bar button; Test walk card; seven-tap switch on the rank name.

## Order of work
### M1: Rules and save, tests first
Failing tests committed first: visit counting and the achievement (criteria 6, 7); journal saved, reloaded,
grace merge, 20 cap (1–3); test walk equals walked steps and leaves real crediting alone (5). Then implement.
**Proof:** `.\scripts\check.ps1` green.

### M2: Screens
Journal screen, Test walk card, seven-tap switch (criterion 4). Widget tests with `MemorySaveStore`.
**Proof:** check green.

### M3: On the phone
`.\scripts\check.ps1 -Release`, `.\scripts\device-smoke.ps1 -Install`, save carries over. The verifier checks
against spec 0004. The owner playtests.

## Risks
| Risk | Mitigation |
|---|---|
| The save grows with the journal | 20 entries of a few lines each: a few KB |
| Test walk credits steps twice with real ones | Pretend steps bypass the per-day crediting entirely; tested (criterion 5) |
