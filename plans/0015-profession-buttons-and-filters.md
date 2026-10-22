# Plan 0015: Build "Profession buttons and recipe filters"

Status: accepted
Spec: `specs/0010-professions.amendment-3.md` (accepted) · Intent: the owner's playtest notes, 2026-10-22
Product owner: Zkalf · Date: 2026-10-22

## What changes in the code
- **App only** (`app/lib/ui/professions_tab.dart`): a row of six profession buttons above the cards (icon and
  level). A tap scrolls to the card with `Scrollable.ensureVisible`, the same way a Now row already opens a card
  (`focus`). Three filter chips under the buttons. The tab keeps the filter as view state (not saved). Crafting's and
  Cooking's recipe lists skip recipes the filter rules out, and say "Nothing matches the filter" when none are left.
- **Rules used, none added:** "Have mats" means every input in the bag in the needed amount (the same check that
  colours a short input red). "Have level" is `recipeLevelMet`. "Up to 5 levels ahead" means the recipe's profession
  level is at most the player's level + 5.
- **No change** to `game_core`, the data, the save, or the sim: nothing moves the pace.
- **Old tests:** none should break, since with no filter on the screen is as before (criterion 4).

## Order of work
### M1: Buttons and filters (one PR)
Failing widget tests first for criteria 1–4 (with `MemorySaveStore`), committed alone, then the screen. **Proof:**
`.\scripts\check.ps1` green; the verifier checks the change against amendment 3. Branch `plan15-m1`, PR, review per
`REVIEW.md`; the owner merges. A phone install only if the owner asks.

## Risks
| Risk | Mitigation |
|---|---|
| The button row is too wide for six on a phone | It scrolls sideways; the test runs at phone width |
| A filter hides the active craft | The active recipe always shows, filter or not |
