# Spec 0015 amendment 6: both trees side by side, each a card

Status: draft
Amends: [spec 0015](0015-talent-trees.md) §3.1 (the heading and the two tabs) and criterion 49, and
[amendment 3](0015-talent-trees.amendment-3.md) change 2 (the 56 dp socket) and change 6 (one tree at a time)
Issue: #153
Product owner: Zkalf (2026-11-01: "I meant A, but I see your concern about space. I do want to try it out to see how
it looks and we can revert if the space is a problem." After three looks on the phone: "I like trees as cards now with
more space. Also drop that line and save some height.")
Date: 2026-11-01

## Why
- The owner wants the whole build on one screen, as in the talent screens of World of Warcraft and Diablo 2.
- With one tree at a time, a player does not see the other tree while they spend points.
- Two trees side by side have little width. A plate around both trees, and a plate of its own inside it for each,
  take width that the icons need.

## Change
1. **Both trees at once:** the Talents tab shows Combat on the left and Utility on the right, 6 dp apart. Row 1 of
   both trees stands at the same height.
2. **Each tree is a plate:** each tree is a plate of its own (radius 16, the 1 dp teal hairline of spec 0014 §2.2).
   No plate stands around both trees.
3. **A title bar:** each plate has a title bar in deep teal (`#17292C`) with the tree's name and ranks in teal small
   caps: "Combat · 12". The tabs **Combat · 12** and **Utility · 0** go.
4. **No points heading:** the Talents tab no longer shows "3 points left". The Character header says it: "3 talent
   points to spend" (§3.1). Before level 10, the Talents tab still says "Talents open at level 10.", because the
   header says nothing of talents then.
5. **The socket fits the grid:** a socket is 56 dp at most, and 16 dp narrower than its column. The image is 57% of
   the socket. A badge hangs 4 dp past the socket's right edge.
6. **The names:** in a column narrower than 90 dp, the name is 11 dp, with a line height of 1.2. A name may use 4 dp
   more than its column. A name whose longest word does not fit is smaller, so that no word breaks.
7. **The rows line up:** each row is as tall as the longest name of that row in either tree.
8. **What stays:** the icons, their states and badges, the lines, the talent sheet and its needs.

## Acceptance criteria
These criteria replace criterion 49 of spec 0015.

**Talents tab**
121. The Talents tab shows the talents of both trees at once.
122. The Utility tree stands to the right of the Combat tree, with its row 1 at the height of Combat's.
123. The Talents tab has no switch between the trees.
124. Each tree has a title bar with its name and its ranks: "Combat · 0".
125. No plate stands around both trees.
126. Before level 10, the Talents tab says "Talents open at level 10."
127. From level 10, the Talents tab shows no "points left" line, and the Character header shows the points.

**Check and release**
128. Rules, numbers and the save do not change. The pacing test passes.
129. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
