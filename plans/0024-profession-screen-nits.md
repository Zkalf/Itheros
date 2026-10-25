# Plan 0024: Build "The profession screen says its name once and hides filters until learned"

Status: accepted
Spec: `specs/0010-professions.amendment-6.md` · Product owner: Zkalf · Date: 2026-10-25

Names of files, widgets and tests refer to `main` at `12da8a7`.

## What changes in the code
- A new file `app/lib/ui/profession_screen.dart` takes `ProfessionScreen`, `_ProfessionCard` and the widgets that
  only they use, out of `app/lib/ui/professions_tab.dart` (issue #62, third point). This move changes no behaviour.
- `_ProfessionCard`: the first row drops `Text(p.name)` and keeps the icon and "Level N".
- `ProfessionScreen`: the filter card shows when the profession has recipes **and** the player has learned it.
- No change to `game_core`, the data, the save or the sim.

## Order of work
### M1: Name once, filters when learned (one PR)
- First, the move of the file alone, committed with the check green. It changes no test.
- Then the failing widget tests, committed alone:
  - A profession screen shows the name in the top bar, and its card does not show the name (criteria 1, 2).
  - The first line of the card shows the icon, and "Level N" when learned (criterion 3).
  - Crafting with the profession learned shows the three chips (criterion 4).
  - Cooking without the profession learned shows no chip (criterion 5).
  - Mining shows no chip (criterion 6).
- Then the code.
- **Proof:** `.\scripts\check.ps1 -Release` green. The verifier checks the change against criteria 1–8.
- Branch `fix/profession-screen-nits`, PR with the amendment and this plan, review per `REVIEW.md`. The owner
  merges.
