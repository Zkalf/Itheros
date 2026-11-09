# Plan 0058: Build "the Test walk card in one row"

Status: accepted
Spec: `specs/0004-journal-and-test-walks.amendment-5.md` · Product owner: Zkalf · Date: 2026-11-09

Names of files, widgets and tests refer to `main` at `50f84d6`.

## What changes in the code
- `app/lib/ui/now_tab.dart`, `_TestWalkCard`: one `Row` with the title "Test walk" and five buttons in `Expanded`
  slots, with small padding. The line of text goes away. The labels come from a small helper (1,000 -> "1k").
- `app/test/test_walk_test.dart`: the new words (criterion 1), one row at 408 dp (2), "+1k" and "+100k" (3).
- `app/test/ui_test.dart` and `app/test/quiet_teal_test.dart`: the tap on "+1,000" and the slate check use "+1k".
- No change to game_core, the data, the save or the sim.
- No release note: the test walk is not in the friends' build.

## Order of work
### M1: the card (one PR)
- The tests first, then the code.
- **Proof:** `.\scripts\check.ps1 -Release` green. A render of the Now tab at 408 dp wide, with the card in one row.
- Branch `feat/test-walk-row`. PR with the amendment and this plan, review per `REVIEW.md`. The owner merges.
