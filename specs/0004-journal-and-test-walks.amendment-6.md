# Spec 0004 amendment 6: one step bank line when a report both used and saved steps

Status: accepted
Amends: [spec 0004](0004-journal-and-test-walks.md) and its amendment 2 (the lines of a report)
Issue: #255
Product owner: Zkalf (chose on 2026-11-10: one line when a report has both; a report with one of them keeps its
sentence)
Date: 2026-11-10

## Why
- One report said "You walked 5,000 steps.", "Used 1,185 steps from your step bank." and "Saved 3,815 steps in your
  step bank." The sums are right, but the reader must work out what the step bank gained.

## Change
1. A report that both used and saved step bank steps shows one line for them, where the "Saved" line stands today:
   "Step bank: +2,630 steps." The number is the saved steps minus the used steps.
2. When more was used than saved, the line shows a minus: "Step bank: −500 steps." When both are equal, it reads
   "Step bank: no change."
3. A report with only used steps, or only saved steps, keeps its sentence of today.
4. The line "Your step bank was full, so N steps could not be saved." stays.
5. The away screen, the short note and the Journal show the same lines, as today.

## Acceptance criteria
1. A report with 1,185 used and 3,815 saved shows "Step bank: +2,630 steps." and neither the "Used" nor the "Saved"
   sentence.
2. A report with more used than saved shows the difference with a minus.
3. A report with the same number used and saved shows "Step bank: no change."
4. A report with only used steps shows "Used N steps from your step bank." A report with only saved steps shows
   "Saved N steps in your step bank."

**Check and release**
5. Rules, numbers and the save do not change. The pacing test passes.
6. `releases/next/` has a line for players.
7. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
