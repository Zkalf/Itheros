# Plan 0020: Build "Pictures for gathering spots"

Status: accepted
Spec: `specs/0014-quiet-teal.amendment-1.md` · Product owner: Zkalf · Date: 2026-10-24

Names of files, widgets and tests refer to `main` at `4b7f11d`.

## What changes in the code
- `app/lib/ui/images.dart`:
  - A new `SpotThing(id)`.
  - `pictureOf` gives a spot the key `spots/<id>`, or else the placeholder `tool_<profession>`.
- `app/lib/ui/actions.dart`, `nodeTile`:
  - `leading` becomes a 48 dp `PictureSocket` with the picture of the spot, as in `enemyTile`.
  - The `LevelBadge` moves to `badge`. It keeps its key `spot-level-<id>`, so today's tests still find it.
- `app/test/placeholders_test.dart`: the check counts and lists the spots.
- No change to `game_core`, the data, the save or the sim. No new image file.

## Order of work
### M1: Spot pictures (one PR)
- First, failing widget tests, committed alone:
  - Now "Here" at Camp: the Copper vein row starts with a 48 dp socket that shows `placeholders/tool_mining`
    (criteria 1, 3).
  - The area sheet of the World map: a spot row starts with a 48 dp socket (criterion 2).
  - A spot of each profession shows its tool placeholder (criterion 3).
  - With an image index that holds `spots/copper_vein`, the row shows that image without the PH mark
    (criterion 4).
  - The badge of the Copper vein is on the name line, before the name, and keeps its colour (criteria 5, 6).
  - The placeholder check lists the 13 spots (criterion 9).
- Then the code.
- **Proof:** `.\scripts\check.ps1 -Release` green. The verifier checks the change against criteria 1–11.
- Branch `spec-0014-amendment-1`, PR with the amendment and this plan, review per `REVIEW.md`. The owner merges.
- After the merge, an install on the Fairphone (`.\scripts\device-smoke.ps1 -Install`), with a screenshot of Now.
