# Plan 0032: Build "the talents look like a tree" (spec 0015 amendment 3)

Status: draft
Spec: `specs/0015-talent-trees.amendment-3.md` · Product owner: Zkalf · Date: 2026-11-01

Names of files, widgets and tests refer to `main` at `6328bfb`.

## What changes in the code
- `packages/game_core/data/talents.json`: each talent gets `column`, with the places of change 7.
- `packages/game_core/lib/src/data/talents.dart`: `TalentDef.column`.
- `packages/game_core/lib/src/data.dart`: the four new checks of change 8, next to the talent checks.
- `app/lib/ui/talents_tab.dart`:
  - `TalentsTab` keeps its heading, its tree tabs and the tree's line. A new `TalentGrid` replaces the rows of
    `_TalentPlate`.
  - `TalentGrid` lays out 6 rows of 3 places. It draws the lines with a `CustomPainter` of plain 2 dp strokes, under
    the icons. The places come from the row and the column, so the painter knows each icon's centre.
  - `TalentNode`: the 56 dp socket with radius 12, the rank badge ("2/5") on the lower right corner, the name under
    it, and the state of change 3. Keys: `talent-<id>` (as today, for the tap), `node-<state>-<id>`.
  - Above the first closed row: the "Opens at N points in <tree>" line, key `opens-at`.
  - `_TalentPlate` and `Pips` go. `TalentSocket` keeps its 48 dp size for the talent sheet.
- The talent sheet, the trainer, the Character header and the level-up screen do not change.
- The save, the rules, the numbers and the sim do not change. No sim run: nothing moves the pace.
- `releases/next.md`: the Talents line says the trees show as trees. It is one change for players with the rest of
  the talents, since 0.6.0 had no talents.

## Choices this plan makes
- **The lines under the icons:** the painter draws first, and the sockets cover the ends of each line. Thus a line
  never crosses an image.
- **A state key on each icon** (`node-closed-…`, `node-open-…`, `node-learn-…`, `node-full-…`): the tests check the
  state by key, not by colour or opacity values.
- **A line key** (`line-<needed>-<talent>-faint` or `-teal`) on a small `Semantics` box for each line, so a test finds
  each line and its colour. A screen reader skips it.

## Order of work
### M1: the tree (one PR)
- First, the failing tests, committed alone:
  - `packages/game_core/test/talents_test.dart`: each talent has a column 1-3 (98); the data check fails on column 4
    (99), on two talents at one place (100), on a needed talent in another column (101), on a talent on a line (102).
  - `app/test/talents_screens_test.dart`: the grid and its places (77-78), the name and the badge (79-80), the talent's words
    only on the sheet (81), a tap opens the sheet (82), the four states (83-87), Learn raises the
    badge (88), the three lines and their colours (89-93), no other lines (94), the "Opens at" line (95-97).
  - The tests of criteria 13, 50 and 51 change to the new keys, since criteria 77-97 replace them.
- Then the code.
- **Proof:** `.\scripts\check.ps1 -Release` green. The verifier checks the change against criteria 77-104. A
  screenshot of each tree on the Fairphone, at the owner's request.
- Branch `feat/talent-tree-looks`. PR with the amendment and this plan, review per `REVIEW.md`. The owner merges.
