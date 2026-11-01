# Spec 0015 amendment 5: the talent sheet lists what a talent needs

Status: accepted
Amends: [spec 0015](0015-talent-trees.md) §3.1 (the talent sheet), [amendment 4](0015-talent-trees.amendment-4.md)
change 3 and criterion 107, and [spec 0014](0014-quiet-teal.md) §2.1 (one new colour)
Issue: #153
Product owner: Zkalf (2026-11-01: "tapping a talent it, if there is a required talent above from a line it should
also state in text below totalt required talents in tree. e.g. impale req 3 keen eye. I also like the idea of the
required text for both to be red if not met and green if met.")
Date: 2026-11-01

## Why
- The sheet says only the first thing that is missing. A player who opens Impale with its row closed does not learn
  that Impale also needs Keen eye 3/3.
- The sheet does not show what a talent needs once the player has it, so the tree's rules stay hidden.

## Change
1. **The needs of a talent:** the talent sheet lists what the talent needs, under "Now: … · Next: …":
   - for a talent above row 1: "Needs 25 points in Combat (13/25)". The first number is `rowOpensAt` of its row. The
     count in brackets is the ranks in the tree, at most the number needed.
   - for a talent with `needs`: "Needs 3 ranks of Keen eye (2/3)", with the ranks of the needed talent.
   - A talent of row 1 with no `needs` lists nothing.
2. **The colours:** a need that the player does not meet is red (`Quiet.short`, `#E08A7C`, as the inputs the player
   does not have). A need that the player meets is green: `Quiet.met`, `#8FC98A`, a new colour for this use only.
3. **Learn or why not:**
   - When a need is not met, the sheet shows no Learn button and no other line why not. The red line says why.
   - When each need is met, the sheet shows **Learn · 1 point**, or "No points left" or "All ranks taken", as before.
4. **What stays:** `whyNotRank` keeps the words of amendment 4 for the message when a rank is refused. The grid, the
   icons, the states and the lines do not change.

## Acceptance criteria
These criteria replace criterion 107 of amendment 4.

**Talent sheet**
111. The sheet of Guard with 4 ranks in Combat says "Needs 5 points in Combat (4/5)" in red.
112. The sheet of Guard with 7 ranks in Combat says "Needs 5 points in Combat (5/5)" in green.
113. The sheet of Impale with Keen eye at rank 2 says "Needs 3 ranks of Keen eye (2/3)" in red.
114. The sheet of Impale with Keen eye at rank 3 says "Needs 3 ranks of Keen eye (3/3)" in green.
115. The sheet of Impale lists both needs: the points in Combat and Keen eye.
116. The sheet of Might lists no needs.
117. The sheet of a talent with a need not met shows no Learn button.
118. The sheet of a talent with each need met and a point left shows the Learn button.

**Check and release**
119. Rules, numbers and the save do not change. The pacing test passes.
120. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
