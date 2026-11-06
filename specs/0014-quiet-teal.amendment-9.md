# Spec 0014 amendment 9: pictures on recipe rows and in the materials table

Status: accepted
Amends: [spec 0014](0014-quiet-teal.md) §3.1 (the pictures of things) and the recipe rows that plan 0017 kept as
they were; spec 0010 §8.1 (the recipe rows) and amendment 5 §2.2 (the materials table); spec 0016 §7.1 (the stop
line of the queue card)
Issue: none (a follow-up of #86, PR #216)
Product owner: Zkalf (chose on 2026-11-06: pictures wherever one exists; asked for this change after #86)
Date: 2026-11-06

## Why
- The recipe rows on the profession screens show a level badge and words only. The player reads each name to find
  the item.
- The materials table in the sheet of a craft or a cook lists the materials by name only.
- Each item that a recipe makes or uses has a picture. The bag, the bank, the queue and the sheet header show them
  (amendment 8, spec 0020 amendment 2).
- A waiting reroll on the queue card shows the stop line "Until 1 crafted (0 / 1)". A reroll is one roll, with no
  stop condition to pick, so the line says nothing useful.

## Change
**The recipe rows**
1. Each recipe row on a profession screen starts with the picture of the item that it makes, in a 48 dp socket.
2. Gear and tools show the ring of their quality, as in the bag. Meals and materials have no ring.
3. The level badge moves to the title line, before the recipe's name, as in a monster row or a spot row. It keeps its
   colour.
4. The words of the row stay: the kind, the stats, the materials, "Enough for N", the steps and the XP, or why it is
   locked.
5. A tap on the row still opens the action sheet. The row does not open the item card: its subtitle already shows the
   item's stats, and the sheet shows the picture large (amendment 8).

**The materials table**
6. Each line of the materials table starts with the material's picture in a 32 dp socket, before its name.
7. A tap on a line opens the material's card: where it comes from and what uses it. The card has no buttons, as the
   card of a material has today.
8. The columns Have, Uses and Left stay.

**The stop line of a reroll**
9. A reroll on the queue card shows no stop line, as a walk shows none. This holds for the current action and for a
   waiting one.

**What stays**
10. No rule, number or save field changes. This does not move the pace, so it has no sim targets.

## Acceptance criteria
**The recipe rows**
1. Each recipe row on the Crafting screen starts with the picture of the item that it makes, in a 48 dp socket.
2. Each recipe row on the Cooking screen starts with the picture of the meal that it makes, in a 48 dp socket.
3. A gear or tool recipe shows the ring of its item's quality.
4. A meal recipe shows no ring.
5. The level badge stands on the title line, before the recipe's name.
6. A locked recipe also shows its picture, and its badge keeps the colour of a locked recipe.
7. A tap on a recipe row still opens its action sheet.

**The materials table**
8. Each line of the materials table starts with the material's picture in a 32 dp socket, before its name.
9. A tap on a line opens the card of that material.
10. The card of a material from the table shows no buttons.

**The stop line of a reroll**
11. A waiting reroll on the queue card shows no stop line.
12. A current reroll on the queue card shows no stop line.
13. A waiting fight still shows its stop line.

**Check and release**
14. Rules, numbers and the save do not change. The pacing test passes.
15. The Crafting screen, the Cooking screen and the sheet of a craft are rendered at 408 dp wide before the PR
    (`CLAUDE.md`).
16. `releases/next/` has a line for players.
17. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
