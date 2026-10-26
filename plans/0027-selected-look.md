# Plan 0027: Build "A clear selected look, and an outline on button labels"

Status: accepted
Spec: `specs/0014-quiet-teal.amendment-4.md` · Product owner: Zkalf · Date: 2026-10-26

Names of files, widgets and tests refer to `main` at `4543f34`.

## What changes in the code
- `app/lib/ui/theme.dart`:
  - `Quiet.selected = Color(0xFF4C6768)`: the fill of a selected chip, segment or Journal tab.
  - `labelOutline`: the four black shadows of 0.8 dp with no blur.
  - `_button` gets an `outline` choice. Slate and ghost buttons have the outline. `tealButton` has none.
  - `segmentedButtonTheme`: selected fill `Quiet.selected`, selected label and icon `Quiet.white`, the label style
    with `labelOutline`.
  - `chipTheme`: selected fill `Quiet.selected`, selected label `Quiet.white`, the label style with `labelOutline`.
  - `tabBarTheme`: selected label `Quiet.white`, both label styles with `labelOutline`.
  - `navigationBarTheme`: the open tab's icon and label `Quiet.white`, both label styles with `labelOutline`.
- `app/lib/ui/journal_screen.dart`: the open tab box has the fill `Quiet.selected`, not `Quiet.lit`.
- `app/lib/ui/home_shell.dart`: the open tab box of the bottom bar has the fill `Quiet.selected`, not `Quiet.lit`.
- The status chips (`statusChip`) keep their own style with no outline. The code checks this and changes nothing if
  their style does not take the theme's chip label style.
- `app/test/quiet_teal_files_test.dart`: the allowed colours include `#4C6768`.
- `app/test/quiet_teal_test.dart`: the test of the selected chips and segment expects `#4C6768` and a white label.
- No change to `game_core`, the data, the save or the sim.

## Order of work
### M1: The selected look and the outline (one PR)
- First, the failing tests, committed alone:
  - The selected Gear segment has the fill `#4C6768`, a white label and a white icon. Bag has slate and `#E3EAEC`
    (criteria 1 and 4).
  - A selected stop-choice chip and a selected Have mats chip have `#4C6768` and a white label (criterion 2).
  - The open Journal tab has `#4C6768` and a white label (criterion 3).
  - The open bottom bar tab has `#4C6768`, a white icon and a white label; the other tabs have no fill and muted
    (criterion 5).
  - The label of Go there (slate), Not now (ghost), each segment, chip and Journal tab, and each bottom bar label
    has the four shadows (criteria 6-9).
  - The label of Start (teal) and the "Active" status chip have no shadow (criteria 10-11).
  - The colours test allows `#4C6768` (criterion 12).
- Then the code.
- **Proof:** `.\scripts\check.ps1 -Release` green. The verifier checks the change against criteria 1-14. A render of
  the Character tab, the Crafting screen and a fight sheet goes in the PR for the owner.
- Branch `fix/selected-look`, in the main folder (one session). PR with the amendment and this plan, review per
  `REVIEW.md`. The owner merges.
