# Plan 0019: Build "One word for a walk"

Status: accepted
Spec: `specs/0016-queue-rework.amendment-1.md` · Product owner: Zkalf · Date: 2026-10-24

## What changes in the code
- `app/lib/ui/world_tab.dart`: the button reads "Walk here".
- `app/lib/ui/now_tab.dart`: a waiting walk reads "Walk to X · N steps".
- No change to `game_core`, the data, the save or the sim.

## Order of work
### M1: The two texts (one PR)
- Failing widget tests first, committed alone, for criteria 1–4. The test of spec 0016 criterion 26 changes to the
  new text in the same commit.
- Then the two texts.
- **Proof:** `.\scripts\check.ps1 -Release` green. The verifier checks the change against criteria 1–5.
- Branch `spec-0016-amendment-1`, PR with the amendment and this plan, review per `REVIEW.md`. The owner merges.
