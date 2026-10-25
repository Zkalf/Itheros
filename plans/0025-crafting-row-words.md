# Plan 0025: Build "Tool lines say the saving, weapon recipes say their damage type"

Status: accepted
Spec: `specs/0010-professions.amendment-7.md` · Product owner: Zkalf · Date: 2026-10-25

Names of files, widgets and tests refer to `main` at `69c3105`.

## What changes in the code
- `app/lib/ui/labels.dart`:
  - A new `Labels.stepSaving(key)`: "Full step cost" for a share of 100%, else "−N% steps".
  - `toolLine` uses it: "Mining tool · −20% steps".
- `app/lib/ui/profession_screen.dart`:
  - The tool row uses `stepSaving` in place of `"${stepShare}% steps"`.
  - `_RecipeTile`: for an output with a damage type, the kind line starts with `typeLine` ("Slash · One hand") and
    drops the slot. Other outputs keep their kind line.
- `app/test/ui_test.dart`: the three checks of "% steps" get the new words.
- No change to `game_core`, the data, the save or the sim.

## Order of work
### M1: The words (one PR)
- First, the failing widget tests, committed alone:
  - A starter tool says "Full step cost" on the Mining screen and on its item card (criterion 1).
  - A Common copper pickaxe says "−10% steps" on the Mining screen and on its item card (criterion 2).
  - An Uncommon copper pickaxe says "−12% steps" (criterion 3).
  - The copper pickaxe recipe row says "−10% steps" (criterion 4).
  - On the Crafting screen, the copper sword row shows "Slash · One hand · +3 Attack", a two-handed weapon row
    shows "Two hands", and an armour row keeps its slot with no armour type (criteria 6-8).
  - The three checks of "% steps" in `ui_test.dart` change to the new words in the same commit (criterion 5).
- Then the code.
- **Proof:** `.\scripts\check.ps1 -Release` green. The verifier checks the change against criteria 1–10.
- Branch `fix/crafting-row-words`, in its own git worktree. PR with the amendment and this plan, review per
  `REVIEW.md`. The owner merges.
