# Plan 0063: Build "the place's story stands under the current action"

Status: accepted
Spec: `specs/0008-character-and-world-layout.amendment-6.md` · Product owner: Zkalf · Date: 2026-11-10

One small change from the playtest of 2026-11-10 in one PR (#251). Names of files, widgets and tests refer to `main`
at `2654fd9`.

## What changes in the code
- `app/lib/ui/now_tab.dart`: `_Discoveries` moves under `_QueueCard` in the list of Now. The queue card gets the key
  `queue-card` for the test.
- `app/test/story_place_test.dart` (new): criteria 1 to 4.
- `releases/next/feat-story-under-action.md`: the line for players.
- No change to `game_core`, the data, the save or the sim.

## Order of work
### M1: the order (one PR)
- The tests first, then the code.
- **Proof:** `.\scripts\check.ps1 -Release` green. A render of Now at Old Graveyard with a fight and the story card
  at 408 dp wide.
- Branch `feat/story-under-action`. PR with the amendment and this plan, `Closes #251`, review per `REVIEW.md`. The
  owner merges.
