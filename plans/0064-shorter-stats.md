# Plan 0064: Build "a shorter stats block on Character"

Status: accepted
Spec: `specs/0008-character-and-world-layout.amendment-7.md` · Product owner: Zkalf · Date: 2026-11-10

The last idea from the playtest of 2026-11-10, in one PR (#254). Names of files, widgets and tests refer to `main` at
`cb00447`.

## What changes in the code
- `app/lib/ui/character_tab.dart`:
  - the header: the portrait at 48 dp; the name and "Level N" (key `stat-Level`) in a `Wrap`, so the level goes under
    the name at a large text size;
  - the stats: one `Wrap` (key `stats-row`) with the seven stats; `_Stat` shows its number in the medium title size,
    is at least 44 dp wide and writes the meal as "+N meal".
- `app/test/shorter_stats_test.dart` (new): criteria 1 to 8.
- Tests that expect the old block follow the new one (`ui_test.dart`: the "(+N meal)" line and the Level stat;
  `stat_sheet_test.dart`; others that the check finds).
- `releases/next/feat-shorter-stats.md`: the line for players.
- No change to `game_core`, the data, the save or the sim.

## Order of work
### M1: the block (one PR)
- A trial of the look came before this plan, to see that seven stats fit a 408 dp phone. The owner saw its render
  with the drafts. Its code is the start of the build.
- The tests, then the rest of the code.
- **Proof:** `.\scripts\check.ps1 -Release` green. Renders of Character at 408 dp wide at text size 1.0 and 2.0.
- Branch `feat/shorter-stats`. PR with the amendment and this plan, `Closes #254`, review per `REVIEW.md`. The owner
  merges.
