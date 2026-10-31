# Plan 0030: Build "The hunter and the fisherman tell what lives at each spot"

Status: accepted
Spec: `specs/0010-professions.amendment-8.md` · Product owner: Zkalf · Date: 2026-10-31

Names of files, widgets and tests refer to `main` at `449f822`.

## What changes in the code
- `packages/game_core/data/professions.json`: three spot tips for Sigrun and four for Wen, with the texts of the
  amendment. Each spot tip has `node` and no `enemy`. Ids: `sigrun_deer_trail`, `sigrun_moor_tracks`,
  `sigrun_high_crags`, `wen_lake_shore`, `wen_under_the_bridge`, `wen_cove_rocks`, `wen_cold_tarn`. Each list
  stays sorted by level, lowest first.
- `packages/game_core/lib/src/data/professions.dart`: `TipDef.enemy` becomes `String?`. `TipDef` gets
  `String? node`.
- `packages/game_core/lib/src/data.dart`: the data check of the tips (today: a known monster) checks:
  - exactly one of `enemy` and `node`
  - a known monster, or a known spot of the teacher's profession
  - a spot tip's level equal to its spot's level
- `packages/game_core/lib/src/game/progress.dart`:
  - `tipsWaiting` leaves out a spot tip whose spot lies in a hidden area that is not revealed (`isHidden`).
  - New `tipHidden(s, tip)`: true for such a tip. The teacher sheet uses it for the next tip.
- `packages/game_core/lib/src/game/odds.dart`: `knowledge` does not change. It compares `t.enemy == enemy`, so a
  spot tip (`enemy` null) never reveals a monster.
- `app/lib/ui/teacher_sheet.dart`:
  - The next tip skips a tip that `tipHidden` names.
  - `TipCard` says "About the <monster>" for a monster tip and "About <spot>" for a spot tip (`labels.node`).
- `app/lib/ui/journal_screen.dart`: no change. The Lore tab already shows told tips under the teacher's name, and
  its count counts only lore notes.
- `releases/next.md`: one line for players.
- No change to the save schema, the catch chances or the sim. The pacing test runs, as the change touches
  `packages/`.

## Choices this plan makes
- **Ids name the teacher and the spot**, like `hilde_1` names the teacher and the level. A level alone would clash
  with Sigrun's monster tips at the same levels.
- **The spot's area decides "hidden".** No tip field says it. A later hidden spot then waits on its own.

## Order of work
### M1: Spot tips (one PR)
- First, the failing tests, committed alone:
  - `packages/game_core/test/spot_tips_test.dart`:
    - learning Hunting tells the Deer trail tip and the level 1 monster tip (criterion 1)
    - Hunting 9: no Moor tracks tip waiting; Hunting 10: it waits (criteria 2-3)
    - learning Fishing tells the Mirror Lake tip (criterion 4)
    - Fishing 15 without the cove: no Cove rocks tip waiting; with the cove revealed: it waits (criteria 5-6)
    - an old save at Hunting 12 (built from the 0.6.0 fixture or by hand, without spot tip ids) has the Moor tracks
      tip waiting (criterion 8)
    - all spot tips told: `knowledge` of every monster stays as without them (criterion 9)
    - each spot tip text holds the item or animal names of its common, uncommon and rare catch (criteria 10-11)
    - the data check throws `FormatException` for a tip with both fields, with neither, with a spot of another
      profession, and with a level unlike its spot's (criteria 15-18)
  - `app/test/spot_tips_test.dart` (widget tests with `MemorySaveStore`):
    - the teacher sheet shows "About Deer trail" above the Deer trail tip (criterion 12)
    - Sigrun's row shows a dot at Hunting 10 (criterion 3)
    - Wen's sheet at Fishing 10 without the cove says "Next tip at Fishing 20." (criterion 7)
    - the Lore tab shows the spot tip under Sigrun's name, and its "N of M found" stays as without spot tips
      (criteria 13-14)
- Then the code and the data.
- **Proof:** `.\scripts\check.ps1 -Release` green, with the pacing test (criteria 19-20). The verifier checks the
  change against criteria 1-20.
- Branch `feat/spot-tips`, in the main folder (one session). PR with the amendment and this plan, review per
  `REVIEW.md`. The owner merges.
