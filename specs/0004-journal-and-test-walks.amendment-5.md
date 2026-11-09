# Spec 0004 amendment 5: the Test walk card in one row

Status: accepted
Amends: [spec 0004](0004-journal-and-test-walks.md) decision 6 and [amendment 4](0004-journal-and-test-walks.amendment-4.md)
criterion 14 (the look and the button words of the Test walk card)
Product owner: Zkalf (2026-11-09: "the test walk takes too much space and I would like it to be just one row. maybe
one 1k instead of 1000 and so on.")
Date: 2026-11-09

## Why
The Test walk card takes four lines on the Now tab: a title, a line of text and two lines of buttons. The owner wants
the room for the game.

## Change
1. **One row:** the Test walk card shows the words "Test walk" and the five buttons in one row. The line "Adds
   pretend steps, as if you walked them." goes away.
2. **Short words:** the buttons say **+100**, **+1k**, **+5k**, **+25k** and **+100k**.
3. **What stays:** each button applies the same steps as before (100, 1,000, 5,000, 25,000 and 100,000). The card
   shows only in the owner's build, with the hidden switch on (spec 0007 §4). One journal entry marked "(test walk)"
   for each tap.

## Acceptance criteria
**Test walk card**
1. The Test walk card has the buttons +100, +1k, +5k, +25k and +100k, in that order.
2. At the Fairphone's size (408 dp wide), the words "Test walk" and all five buttons sit in one row.
3. "+1k" applies 1,000 steps, and "+100k" applies 100,000 steps, as walked steps would.

**Check and release**
4. Rules, numbers and the save do not change. The pacing test passes.
5. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
