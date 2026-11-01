# Spec 0015 amendment 4: fewer words on the tree, the points on the sheet

Status: accepted
Amends: [spec 0015](0015-talent-trees.md) §3.1, and [amendment 3](0015-talent-trees.amendment-3.md) change 5 and
criteria 95-97
Issue: #153
Product owner: Zkalf (2026-11-01, after the screenshots of the tree on the Fairphone: "Remove the text describing the
talent tree, so "A bigger bank...". Remove the text "Opens at...". When tapping a talent point instead of only saying
"opens at..." it should also state how many points you have e.g. 13/20 in utility.")
Date: 2026-11-01

## Why
- The tree's line ("A bigger bank, cheaper actions and travel, better crafts.") and the "Opens at" line take room and
  say little. The dim icons already show which rows are closed.
- The talent sheet says when a row opens, but not how far the player is from it.

## Change
1. **No tree line:** the Talents tab no longer shows the line of the tree under the tree tabs. `talents.json` keeps
   the line.
2. **No "Opens at" line on the grid:** amendment 3, change 5, goes. A closed row shows only its dim icons.
3. **The points on the talent sheet:** for a talent of a closed row, the line why not says when the row opens and
   the points in the tree: "Opens at 20 points in Utility. You have 13/20."
4. **What stays as it is:** the other lines why not ("Needs Keen eye 3/3", "No points left", "All ranks taken"), the
   grid, the icons, the states and the lines between talents.

## Acceptance criteria
These criteria replace criteria 95-97 of amendment 3.

**Talents tab**
105. The Talents tab does not show the line of a tree.
106. The grid shows no "Opens at" line, with closed rows or without.

**Talent sheet**
107. The sheet of a talent in a closed row says "Opens at 5 points in Combat. You have 4/5." with 4 ranks in Combat.
108. The sheet of a talent in a closed row says "You have 0/5." with no ranks in its tree.

**Check and release**
109. Rules, numbers and the save do not change. The pacing test passes.
110. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
