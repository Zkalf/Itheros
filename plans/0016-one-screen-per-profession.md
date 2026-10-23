# Plan 0016: Build "One screen per profession"

Status: accepted
Spec: `specs/0010-professions.amendment-4.md` (accepted) · Intent: the owner's playtest notes on 0.3.0, 2026-10-23
Product owner: Zkalf · Date: 2026-10-23

## What changes in the code
- **App only** (`app/lib/ui/professions_tab.dart`, a new `profession_screen.dart`, `home_shell.dart`):
  - The tab becomes a list of six profession buttons (icon, name, level, progress bar, tier; or "Learn from …").
    The amendment 3 button row and the scroll-to-card code (`focus`, `ensureVisible`) go away.
  - A tap pushes a `ProfessionScreen` holding that one card, built by the same card code as today, so contents don't
    change. Crafting's and Cooking's screens put the three filter chips on top.
  - The filter choice lives in the shell (one value for both screens, not saved), so it survives going back and
    forth and is off on app start.
  - `onOpenProfessions(profession)` (Forge row, Camp fire row) and the tool line push that profession's screen
    instead of scrolling. Starting an action pops the screen, then goes to Now as today.
- **No change** to `game_core`, the data, the save, or the sim: nothing moves the pace.
- **Old tests:** the amendment 3 and spec 0010/0011 screen tests that scroll to a card or look for all six cards at
  once are updated to open the profession's screen first. These are UI-layout tests, changed in the same PR as the
  screen; what they check on each card stays the same.

## Order of work
### M1: Profession screens (one PR)
Failing widget tests first for criteria 1–6 (with `MemorySaveStore`), committed alone, then the screens. **Proof:**
`.\scripts\check.ps1` green; the verifier checks the change against amendment 4 (and amendment 3's filter
criteria). Branch `plan16-m1`, PR, review per `REVIEW.md`; the owner merges. A phone install only if the owner asks.

## Risks
| Risk | Mitigation |
|---|---|
| A link still scrolls to a card that's gone | Criterion 5 tests each link (Forge, Camp fire, tool line) |
| A started action leaves the pushed screen open over Now | Criterion 6 test; start pops to the shell first |
