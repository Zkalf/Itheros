# Spec 0004 amendment 2: a "While you were away" screen

Status: accepted
Amends: [spec 0004](0004-journal-and-test-walks.md) §2 (and its amendment 1), spec 0001's report card
Product owner: Zkalf (proposed it after playtesting; chose option a, 2026-10-19)
Date: 2026-10-19

## Change
The report no longer sits as a card at the top of the Adventure tab, where it pushed everything down and made it
jump back when dismissed.

- **A screen of its own.** When the player comes back and something happened (an action earned something, ended
  or was skipped; a level; an achievement), a full "While you were away" screen opens by itself, after any level-up
  cards. It looks like a journal entry (time, the same lines, quality colours) and has one **Continue** button.
- **Only when something happened** (owner's choice a). If the steps only went to the bank or toward an action
  without finishing anything, a short note shows at the bottom of the screen instead and fades ("You walked 1,200
  steps. Saved 1,200 steps in your step bank.").
- **Late steps** in the grace minutes join the same journal entry. They update the screen while it is open. Once
  it is closed it stays closed for that return.
- **The journal is unchanged:** every report is kept there as before. Test walks follow the same rule.

## Acceptance criteria
10. A return where something happened opens the screen (after level-up cards) with the time and the report lines;
    Continue closes it, and the Adventure tab never changes layout because of a report.
11. A return where steps only went to the bank or an unfinished unit shows the short note, not the screen.
12. Late steps after the screen was closed join the journal entry without reopening the screen.
