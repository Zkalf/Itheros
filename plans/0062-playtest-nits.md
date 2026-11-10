# Plan 0062: Build the small fixes of the playtest (#255) and the tour's Bank button

Status: accepted
Specs: `specs/0010-professions.amendment-13.md`, `specs/0004-journal-and-test-walks.amendment-6.md`,
`specs/0020-item-bank.amendment-7.md`, `specs/0022-camp-tour.amendment-1.md` · Product owner: Zkalf ·
Date: 2026-11-10

Five small fixes in one PR. Names of files, widgets and tests refer to `main` at `c1b4025`.

## What changes in the code
**XP numbers (spec 0010 amendment 13, changes 1 to 3)**
- `app/lib/ui/profession_screen.dart`, `app/lib/ui/professions_tab.dart`: the XP line shows `xp - floor` and
  `next - floor`.
- `app/lib/ui/now_tab.dart`: the label of the character's bar does the same.

**Locked rows (spec 0010 amendment 13, changes 4 to 6)**
- `packages/game_core/lib/src/game/queue.dart`: `lockedReason` takes `named` (true by default). With `named: false`
  the line starts with "Needs". The skip reasons keep the name.
- `app/lib/ui/profession_screen.dart` (recipe rows) and `app/lib/ui/actions.dart` (spot rows) ask for the line
  without the name.

**Step bank line (spec 0004 amendment 6)**
- `app/lib/ui/away_summary_card.dart`, `reportLines`: one line when a report has both used and saved steps.

**Bank rows (spec 0020 amendment 7)**
- `app/lib/ui/labels.dart`: `rowLine(item)`, the second line of a gear or tool row, from the words of the item card.
- `app/lib/ui/bank_screen.dart`: the rows show it as their subtitle.

**Tour (spec 0022 amendment 1)**
- `app/lib/ui/camp_tour.dart`: the words of step 6.

**Tests**
- `app/test/playtest_nits_test.dart` (new): the criteria of the four amendments but "Check and release".
- `packages/game_core/test/`: `lockedReason` with and without the name.
- Tests that expect the old words follow the new ones.

**Also**
- `releases/next/fix-playtest-nits.md`: the lines for players.
- No change to the data, the save or the sim.

## Order of work
### M1: all five (one PR)
- The tests first, then the code.
- **Proof:** `.\scripts\check.ps1 -Release` green. A render of the bank's list with look-alike gear at 408 dp wide.
- Branch `fix/playtest-nits`. PR with the four amendments and this plan, `Closes #255`, review per `REVIEW.md`. The
  owner merges.
