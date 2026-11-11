# Plan 0065: Build "the Gear page as a plain grid of four columns"

Status: accepted
Spec: `specs/0008-character-and-world-layout.amendment-8.md` · Product owner: Zkalf · Date: 2026-11-11

The owner's idea of 2026-11-11, in one PR. Names of files, widgets and tests refer to `main` at `b1547a4`.

## What changes in the code
- `app/lib/ui/paper_doll.dart`: the figure goes; the slots stand in the rows of change 2 (one list of rows); a slot
  that the data adds later joins a row under them. The squares keep their size. The key `paper-doll` stays.
- `app/test/simple_gear_test.dart` (new): criteria 1 to 5.
- `app/test/ui_test.dart`: the test "amendment 3: the hands alone in the bottom row" gives way to the new places.
- `releases/next/feat-simple-gear.md`: the line for players.
- No change to `game_core`, the data, the save or the sim.

## Order of work
### M1: the grid (one PR)
- Three trial renders came before this plan (two body shapes, then four columns); the owner chose four columns from
  them. The trial code is the start of the build.
- The tests, then the rest of the code.
- **Proof:** `.\scripts\check.ps1 -Release` green. A render of the Gear page at 408 dp wide.
- Branch `feat/simple-gear`. PR with the amendment and this plan, review per `REVIEW.md`. The owner merges.
