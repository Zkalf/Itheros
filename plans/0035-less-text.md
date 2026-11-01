# Plan 0035: Build "fewer words on Now and World" (spec 0014 amendment 6)

Status: accepted
Spec: `specs/0014-quiet-teal.amendment-6.md` · Product owner: Zkalf · Date: 2026-11-01

Names of files, widgets and tests refer to `main` at `46bae46`.

## What changes in the code
- `app/lib/ui/now_tab.dart`:
  - the step bank `_Bar` sits in an `InkWell` (key `step-bank`) that opens a sheet (key `step-bank-sheet`) with the
    title and the two lines;
  - the line under the step bank and the line at the bottom of Now go.
- `app/lib/ui/world_tab.dart`: the hint under the map and its padding go.
- Tests that look for the old lines change to the sheet.
- No change to game_core, the data, the save or the sim.
- `releases/next.md`: a line for players.
- Issue #122 gets a note that its hint line is gone.

## Order of work
### M1: the texts (one PR)
- First, the failing tests, committed alone, in `app/test/less_text_test.dart`: criteria 37-40.
- Then the code.
- **Proof:** `.\scripts\check.ps1 -Release` green. On the Fairphone at the owner's request.
- Branch `feat/less-text`. PR with the amendment and this plan, review per `REVIEW.md`. The owner merges.
