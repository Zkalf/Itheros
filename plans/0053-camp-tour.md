# Plan 0053: Build the camp tour (spec 0022)

Status: accepted
Spec: `specs/0022-camp-tour.md` · Intent: `intent/0021-camp-tour.md` · Issue: #226 · Product owner: Zkalf ·
Date: 2026-11-06

## What changes in the code
**game_core**
- No change (rule 1).

**app**
- `lib/game_controller.dart`: `tourStep` (null, or 0-5), in memory only, with `startTour()`, `nextTourStep()` and
  `endTour()`. `setOut` starts the tour after the character is made (rule 3).
- New `lib/ui/camp_tour.dart`: the six steps (tab, pane, words, §3.3) and the `TourCard` widget (§3.2): the portrait
  socket, "Bram", the step, the words, Skip tour and Next or Done.
- `lib/ui/home_shell.dart`: while `tourStep` is set, the open tab follows the step, a clear barrier takes the taps
  above and over the bar (criteria 19-20), the card stands above the bar, and a `PopScope` ends the tour on back
  (criterion 18). When the tour ends, the Now tab opens (rule 16).
- `lib/ui/character_tab.dart`: the tour can open it on a pane (Gear or Bag, rule 18).
- `lib/ui/settings_screen.dart`: the entry Camp tour (§3.4).
- `lib/ui/images.dart`: `GuideThing` for Bram's portrait, with the placeholder portrait while no picture exists
  (rule 10).
- New `test/camp_tour_test.dart`: criteria 1-22.
- `releases/next/feat-camp-tour.md`: one line for players.

No change in `packages/`, `data/` or the save.

## Order of work (one PR)
1. The tests: criteria 1-22.
2. The code and the notes line.
3. **Proof:** the six cards rendered at 408 dp wide, and step 1 and step 5 at text size 2.0 (`CLAUDE.md`).
   - `.\scripts\check.ps1 -Release` green. The pacing sims do not run, as `packages/` does not change.
   - The verifier runs alongside the local check, before the PR.
   - Review per `REVIEW.md`; the owner merges.

Branch `feat/camp-tour`.
