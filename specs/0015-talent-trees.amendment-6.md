# Spec 0015 amendment 6: both trees side by side

Status: draft
Amends: [spec 0015](0015-talent-trees.md) §3.1 (the two tabs), and [amendment 3](0015-talent-trees.amendment-3.md)
change 2 (the 56 dp socket) and change 6 (one tree at a time)
Issue: #153
Product owner: Zkalf (2026-11-01: "I meant A, but I see your concern about space. I do want to try it out to see how
it looks and we can revert if the space is a problem.")
Date: 2026-11-01

## Why
- The owner wants the whole build on one screen, as in the talent screens of World of Warcraft and Diablo 2.
- With one tree at a time, a player does not see the other tree while they spend points.

## Change
1. **Both trees at once:** the Talents tab shows Combat on the left and Utility on the right, each as its grid of 3
   columns, with 12 dp between them. Row 1 of both trees stands at the same height.
2. **No switch:** the tabs **Combat · 12** and **Utility · 0** go. Each tree has a heading in teal small caps over
   its grid, with the same words: "Combat · 12".
3. **The socket fits the grid:** a socket is 56 dp at most, and 16 dp narrower than its column. On the Fairphone 5
   that gives about 52 dp. The image is 57% of the socket.
4. **The names:** in a column narrower than 90 dp, the name is 11.5 dp, with a line height of 1.2. A name may use
   8 dp more than its column.
5. **What stays:** the points heading, the icons, their states and badges, the lines, the talent sheet and its needs.

## Acceptance criteria
**Talents tab**
121. The Talents tab shows the talents of both trees at once.
122. The Utility tree stands to the right of the Combat tree, with its row 1 at the height of Combat's.
123. The Talents tab has no switch between the trees.
124. Each tree has a heading with its name and its ranks: "Combat · 0".

**Check and release**
125. Rules, numbers and the save do not change. The pacing test passes.
126. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

## If the space is a problem
The owner tries this on the phone. If the trees are too tight, the owner rejects this draft, and the Talents tab keeps
one tree at a time (amendment 3).
