# Spec 0008 amendment 8: the Gear page as a plain grid of four columns

Status: accepted
Amends: [spec 0008](0008-character-and-world-layout.md) §3.5 (Gear: "a simple figure outline … with slots around
it") and [amendment 3](0008-character-and-world-layout.amendment-3.md) change 1 and criterion 15 (two columns, the
hands in the bottom row)
Product owner: Zkalf (asked on 2026-11-11 for a simpler Gear page with no figure; chose four columns from a render; accepted on 2026-11-11)
Date: 2026-11-11

## Why
- The figure in the middle of the Gear page adds nothing, and it pushes the slots into two long columns: eight rows
  that need a scroll on a 408 dp phone.

## Change
1. **No figure.** The Gear page shows no figure outline.
2. **Four columns, four rows.** The 16 slots stand in a grid, centred:

   | | | | |
   |---|---|---|---|
   | Shoulder | Head | Neck | Cloak |
   | Main hand | Chest | Gloves | Off hand |
   | Ring 1 | Belt | Bracer | Ring 2 |
   | Trinket 1 | Legs | Boots | Trinket 2 |

   Head, Chest, Belt and Legs stand in the second column; the pairs (Shoulder and Cloak, the two hands, the two rings,
   the two trinkets) in the outer columns.
3. The squares keep their size of today: a quarter of the width, at most 72 dp and at least 48 dp.
4. A slot that the data adds later stands in a row under the grid, as today's bottom row takes it.

**What stays**
5. Each slot, its picture, its empty look with its slot icon, the greyed Off hand under a two-hander, and a tap that
   opens the item card or the slot sheet (amendment 3 change 2, amendment 4).
6. No rule, number or save field changes. This does not move the pace, so it has no sim targets.

## Acceptance criteria
1. The Gear page shows no figure.
2. The 16 slots stand in four rows of four, in the places of change 2.
3. On a 408 dp phone at the usual text size, all 16 slots are on the screen below the tabs without a scroll.
4. A tap on an empty slot opens its sheet; a tap on a filled slot opens the card of its item.
5. Under a two-hander the Off hand is greyed, as today.

**Check and release**
6. Rules, numbers and the save do not change. The pacing test passes.
7. The Gear page is rendered at 408 dp wide before the PR (`CLAUDE.md`).
8. `releases/next/` has a line for players.
9. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
