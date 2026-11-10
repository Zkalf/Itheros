# Plan 0060: Build "Camp's services first" and "Hit as a chance, and a tap on a stat explains it"

Status: accepted
Specs: `specs/0020-item-bank.amendment-6.md`, `specs/0009-fights-with-depth.amendment-4.md` · Product owner: Zkalf ·
Date: 2026-11-10

Two small changes from the playtest of 2026-11-10 in one PR (#250, #252). Names of files, widgets and tests refer to
`main` at `2ccc950`.

## What changes in the code
**Camp's services first (spec 0020 amendment 6)**
- `app/lib/ui/now_tab.dart`, `_rows`: the Bank, Forge and Camp fire rows move before the teachers and the trainer.
  The Bank row loses its `trailing` button (`open-bank`); its `onTap` stays.
- `app/test/here_order_test.dart`: criteria 1 to 7.
- `app/test/bank_screens_test.dart` and `app/test/bank_one_tap_test.dart`: they open the bank with a tap on the row
  (`bank-card`) and no longer expect "Open bank". Other tests that tap `open-bank` change the same way.

**Hit and the stat sheets (spec 0009 amendment 4)**
- `packages/game_core/lib/src/game/odds.dart`: `hitChanceAtLevel(state)`, the hit chance at level difference 0 with
  the player's Hit and no Slayer.
- `packages/game_core/lib/src/game/progress.dart`: `statParts(state)` gives the sources of the stats one by one (the
  level, worn gear, talents, the meal, achievements). `stats` stays their sum.
- `app/lib/ui/stat_sheet.dart` (new): the sheet of one stat, with its words from the data.
- `app/lib/ui/character_tab.dart`: the Hit stat shows the chance. A tap on a stat but Level opens its sheet.
- `packages/game_core/test/hit_at_level_test.dart`: criteria 1 to 4 and 16, and that the parts add up to `stats`.
- `app/test/stat_sheet_test.dart`: criteria 1, 2 and 5 to 15. `app/test/ui_test.dart` (the Character stats test)
  expects "75%" for no Hit.

**Both**
- `releases/next/feat-camp-services-hit.md`: the lines for players.
- No change to the data, the save or the sim.

## Order of work
### M1: both changes (one PR)
- The tests first, then the code.
- **Proof:** `.\scripts\check.ps1 -Release` green. A render of Now at Camp at 408 dp wide, scrolled to "Here", of
  the stats block on Character and of the sheets of HP and Hit.
- Branch `feat/camp-services-hit`. PR with the two amendments and this plan, `Closes #250` and `Closes #252`, review
  per `REVIEW.md`. The owner merges.
