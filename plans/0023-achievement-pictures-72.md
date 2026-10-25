# Plan 0023: Build "72 dp pictures on the Achievements screen"

Status: accepted
Spec: `specs/0014-quiet-teal.amendment-3.md` · Product owner: Zkalf · Date: 2026-10-25

Names of files, widgets and tests refer to `main` at `163dfd9`.

## What changes in the code
- `app/lib/ui/achievements_screen.dart`, `_AchievementTile`:
  - A `ListTile` caps its leading widget at 56 dp. So the card holds a `Row`: the 72 dp `PictureSocket`, then
    the `ListTile` without `leading`.
  - The socket keeps 16 dp from the start of the card, as the `ListTile` did.
- No change to `game_core`, the data, the save or the sim. No new image file.

## Order of work
### M1: 72 dp achievement pictures (one PR)
- First, the failing widget tests, committed alone:
  - `app/test/world_route_test.dart`, the test of spec 0014 criterion 12 on Achievements: the socket is 72 × 72 dp
    (criteria 1, 2). The test checks the 48 dp socket today, so it fails on purpose.
  - A new test: the socket of each row is centred on the height of its row, and the row still shows the name,
    the goal, the "Reward:" line and, for a locked one, the bar (criteria 3, 4).
  - A monster row and a spot row on Now "Here" keep their 48 dp sockets (criterion 5).
- Then the code.
- **Proof:** `.\scripts\check.ps1 -Release` green. The verifier checks the change against criteria 1–7.
- Branch `fix/achievement-pictures-72`, PR with the amendment and this plan, review per `REVIEW.md`. The owner
  merges.
- Work happens in its own git worktree, because another session works in the shared checkout.
