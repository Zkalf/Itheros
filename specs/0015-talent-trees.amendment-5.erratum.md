# Spec 0015 amendment 5, erratum 1: below row 1, not above

Status: accepted
Corrects: [amendment 5](0015-talent-trees.amendment-5.md) Change 1
Product owner: Zkalf (2026-11-01: "What do you mean "for any talent above row 1". Visually it is below right?")
Date: 2026-11-01

## What was wrong
Change 1 says "for a talent above row 1". Row 1 is at the top of the grid, so the talents of rows 2-6 stand below it.
Claude's wording mistake. The code and the tests already follow the meaning.

## Correction
- Change 1 reads: "for a talent in rows 2-6: "Needs 25 points in Combat (13/25)"."
