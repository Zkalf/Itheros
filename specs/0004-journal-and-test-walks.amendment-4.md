# Spec 0004 amendment 4: bigger test walks

Status: accepted
Amends: [spec 0004](0004-journal-and-test-walks.md) decision 6 (the buttons of the Test walk card)
Product owner: Zkalf (2026-11-01: "add more test step options, I don't want to spam 5k step when I want to power
level to test something". To +25,000 and +100,000: "sound good")
Date: 2026-11-01

## Why
To test something at a high level, the owner taps "+5,000" many times. One level late in the game takes tens of
thousands of steps.

## Change
1. **Two more buttons:** the Test walk card has **+100**, **+1,000**, **+5,000**, **+25,000** and **+100,000**.
2. **The same rules:** each button applies its steps exactly as walked steps would (criterion 5). A test walk while
   the player rests fills the step bank up to its cap, as walked steps do. The card does not say so.
3. **What stays:** the card shows only in the owner's build, with the hidden switch on (spec 0007 §4). One journal
   entry marked "(test walk)" for each tap.

## Acceptance criteria
**Test walk card**
14. The Test walk card has the buttons +100, +1,000, +5,000, +25,000 and +100,000, in that order.
15. "+100,000" during an action applies 100,000 steps to the queue, as 100,000 walked steps would.
16. "+100,000" makes one journal entry marked "(test walk)".

**Check and release**
17. The friend build has no Test walk card (spec 0007 §4).
18. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
