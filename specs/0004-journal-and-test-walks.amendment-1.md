# Spec 0004 amendment 1: every return is its own entry

Status: accepted
Amends: [spec 0004](0004-journal-and-test-walks.md) §2
Product owner: Zkalf (chose option a in the design talk, 2026-10-19)
Date: 2026-10-19

## Change
Spec 0004 §2 kept the report card working "as today": a report still on screen (never dismissed) kept growing
when the player left and came back, so two returns ended up in one journal entry with the first one's time. That
contradicts decision 1 (one entry per return).

Now **every return (open or resume) starts a new journal entry**, whether or not the previous card was dismissed.
The card on screen shows the newest return only; older ones are in the journal. Steps arriving in the grace minutes
after a return still join that return's entry (criterion 2, unchanged).

## Acceptance criterion
9. Two returns with the first card never dismissed make two journal entries, each with its own time, and the card
   shows only the second.
