# Plan 0051: Build "Until the bag is full" (spec 0021 amendment 3)

Status: accepted
Spec: `specs/0021-bag-limit.amendment-3.md` · Issue: #224 · Product owner: Zkalf · Date: 2026-11-06

## What changes in the code
**game_core**
- `lib/src/activity.dart`: `StopKind.untilFull` and `StopCondition.untilFull()`. It saves as `{"kind": "untilFull"}`
  (criterion 9); old saves have no such stop.
- `lib/src/game/queue.dart` (`_stopMet`): `untilFull` ends the action when `spacesUsed >= bagSpaces` after a unit
  (rules 2-3). The check before a start refuses it when the bag has no free space: "Your bag is already full"
  (rule 4).
- New `test/stop_full_test.dart`: criteria 4-7 and 9.

**app**
- `lib/ui/action_sheet.dart`: the chip "Until the bag is full" for fights and gathering (rules 1, 6).
- `lib/ui/labels.dart`: the stop line "Until the bag is full" (rule 5).
- New `test/stop_full_screens_test.dart`: criteria 1-3 and 8.
- `releases/next/feat-stop-when-bag-full.md`: one line for players.

No change in `data/`.

## Order of work (one PR)
1. The tests: criteria 1-9.
2. The code and the notes line.
3. **Proof:** the action sheet of a fight and of a gather rendered at 408 dp wide (`CLAUDE.md`).
   - `.\scripts\check.ps1 -Release` green, with the pacing sims, as `game_core` changes.
   - The verifier runs alongside the local check, before the PR.
   - Review per `REVIEW.md`; the owner merges.

Branch `feat/stop-when-bag-full`.
