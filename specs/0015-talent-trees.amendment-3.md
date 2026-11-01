# Spec 0015 amendment 3: the talents look like a tree

Status: draft
Amends: [spec 0015](0015-talent-trees.md) §2.8, §3.1, §6 and criteria 13, 50 and 51, and
[spec 0014](0014-quiet-teal.md) §4.3 (the look of the talents)
Issue: #153
Product owner: Zkalf (2026-11-01: "we need better graphics for talents, it needs to look like a tree like in wow
talents or d2 skills")
Date: 2026-11-01

## Why
- Each talent is a plate with its name and line under the one before it. The Talents tab reads as a list.
- A player does not see at a glance which talents lead to which, or how far each tree goes.
- The owner wants the shape of the talent trees of World of Warcraft and the skill trees of Diablo 2: icons on a grid,
  rows that open one by one, and lines between talents. We take the shape, not their art.

## Change
1. **The grid:** each tree shows its talents as icons on a grid of 6 rows and 3 columns. Row 1 is at the top.
   - Each talent has its own place: its row and its column.
   - An empty place shows nothing.
   - The grid scrolls when it does not fit on the screen.
2. **The icon:** each talent shows as one icon.
   - The talent's image sits in a dark socket of 56 dp, with radius 12.
   - A badge with the ranks ("2/5") hangs off the lower right corner, in the style of the count badge
     (spec 0014 §2.3).
   - The talent's name stands under the icon in muted text, on at most 2 lines.
   - The talent's line ("+0.8% Attack") leaves the grid. The talent sheet still shows it.
3. **The states of an icon:**

   | State | When | Look |
   |---|---|---|
   | Closed | its row is not open, or the talent it needs does not have all its ranks | the image at 40% opacity; a faint badge |
   | Open | not closed, ranks left to take, and no points left | the image in full; no ring |
   | Can learn | not closed, ranks left to take, and points left | a 1 dp teal hairline around the socket |
   | Full | all ranks taken | a 2 dp teal ring; the badge in teal |

   - An icon with at least 1 rank and not full shows its badge number in teal.
4. **The lines:** a line joins a talent to the talent that it needs.
   - The line is a 2 dp plain stroke. It runs straight down the column, from the lower edge of the needed talent to
     the upper edge of the talent that needs it.
   - The line is faint (`#7F8A90`) until the needed talent has all its ranks. Then it is teal.
   - The screen draws no other lines between talents.
   - No blur and no shadow (CLAUDE.md, #121).
5. **The rows that are not open:** one faint line of text sits above the first closed row: "Opens at 10 points in
   Combat". The rows below it are closed too and show no text of their own.
6. **What stays as it is:**
   - The heading with the points left, and the two tree tabs **Combat · 12** and **Utility · 0**. The screen shows one
     tree at a time.
   - The talent sheet of §3.1: its name, line, rank, "Now: … · Next: …", the **Learn · 1 point** button and the line
     why not ("Needs Keen eye 3/3" stays there).
   - The images: the app's icon set, as §6 says. New art for each talent is a separate issue.
   - The rules, the numbers and the save.
7. **The data:** each talent in `talents.json` gets `column`, from 1 to 3. The places of today's talents:

   | Row | Combat 1 | Combat 2 | Combat 3 | Utility 1 | Utility 2 | Utility 3 |
   |---|---|---|---|---|---|---|
   | 1 | Might | | Toughness | Deep pockets | | Nimble hands |
   | 2 | Guard | | Keen eye | Practised hands | Bountiful | Wary |
   | 3 | | Swift strikes | | Master crafter | | Quartermaster |
   | 4 | Precision | Evasion | | | | Light pack |
   | 5 | | Treasure hunter | | Lucky hammer | | |
   | 6 | | | Impale | | | Wayfarer |

   The lines: Keen eye to Impale (Combat column 3), Master crafter to Lucky hammer (Utility column 1), Light pack to
   Wayfarer (Utility column 3).
8. **The data check** of §2.8 also fails when:
   - a talent has no column, or a column that is not 1-3
   - two talents of one tree have the same row and column
   - a talent sits in another column than the talent that it needs
   - a talent sits in the same column between a talent and the talent that it needs (a line would run through it)
9. **Out of scope (§6):** "Arrows drawn between plates" leaves the list. The lines of change 4 take its place. Arrow
   heads, curved lines and lines across columns stay out.

## Acceptance criteria
These criteria replace criteria 13, 50 and 51 of spec 0015.

**The grid**
77. The Talents tab shows the talents of one tree as icons on a grid of 3 columns.
78. Each icon stands at the row and column of its talent in the data.
79. Each icon shows the talent's name under it.
80. Each icon shows a badge with its ranks taken and its ranks ("2/5").
81. No icon shows the talent's line. The talent sheet shows it.
82. A tap on an icon opens the talent sheet of that talent.

**The states**
83. An icon of a closed row shows its image at 40% opacity.
84. An icon of a talent whose needed talent does not have all its ranks shows its image at 40% opacity.
85. An icon of a talent that the player can take a rank of now has a teal hairline.
86. An icon with all its ranks taken has a teal ring.
87. An icon of an open row, with ranks left to take and no points left, has no ring.
88. Learn on the talent sheet raises the number on the icon's badge by 1.

**The lines**
89. A line joins Keen eye and Impale.
90. A line joins Master crafter and Lucky hammer.
91. A line joins Light pack and Wayfarer.
92. A line is faint while the needed talent does not have all its ranks.
93. A line is teal when the needed talent has all its ranks.
94. No line joins two talents where neither needs the other.

**Closed rows**
95. The first closed row of a tree has the line "Opens at 10 points in Combat" above it, with its own number and tree.
96. No other closed row has a line of its own.
97. A tree with all its rows open shows no "Opens at" line.

**Data**
98. Each talent in `talents.json` has a column from 1 to 3.
99. The data check fails on a talent with column 4.
100. The data check fails on two talents of one tree at the same row and column.
101. The data check fails on a talent in another column than the talent it needs.
102. The data check fails on a talent that sits on the line between two other talents.

**Check and release**
103. Rules, numbers and the save do not change. The pacing test passes.
104. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

## Open questions for the owner
- **One tree at a time** (as now, with the Combat and Utility tabs), or both trees side by side? Side by side makes
  each icon about 36 dp on the phone, too small for the image and the name. This draft keeps one at a time.
- **Names under the icons:** the trees of both games show icons only. This draft keeps the name, because the icon
  set has few images and several talents share one (Nimble hands and Practised hands both use `profession`).
- **The places of change 7:** move any talent you want. The data check only needs each line to run straight down an
  empty column.
