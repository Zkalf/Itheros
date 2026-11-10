# Spec 0020 amendment 7: a gear or tool row in the bank shows its stats

Status: accepted
Amends: [spec 0020](0020-item-bank.md) §3 and [amendment 2](0020-item-bank.amendment-2.md) (the rows of the bank's
two lists)
Issue: #255
Product owner: Zkalf (chose on 2026-11-10: the stats and the bonus stats under the name)
Date: 2026-11-10

## Why
- Three rows read "Hide vest (Rare) ×1" with the same picture. Only their cards tell them apart (`CLAUDE.md`: the
  player can tell two alike things apart).

## Change
1. A row of a piece of gear in the bank's lists (Bank and Bag) shows a second line under its name: its stats, its
   slot, then each bonus stat, with " · " between them. For example "+2 Defense · +20 HP · Chest · +4% Hit". A weapon
   shows its damage type and hands in place of the slot, as a recipe row does.
2. A row of a tool shows its line of the item card: "Mining tool · −20% steps".
3. The words are those of the item card and the recipe rows.
4. Rows of materials and meals keep one line.
5. The name, the count, the picture, the colour of the quality and the tap that opens the card stay. So do the
   filters, the search and the sorts.

## Acceptance criteria
1. A gear row shows its base stats and its slot under the name.
2. Two pieces of the same gear and quality with different bonus stats show different second lines, each with its own
   bonus stat.
3. A tool row shows its tool line.
4. A material row and a meal row show no second line.
5. The rows of both lists (Bank and Bag) follow criteria 1 to 4.
6. At text size 2.0 on a 408 dp phone a gear row with bonus stats does not overflow.

**Check and release**
7. Rules, numbers and the save do not change. The pacing test passes.
8. The bank's list with look-alike gear is rendered at 408 dp wide before the PR (`CLAUDE.md`).
9. `releases/next/` has a line for players.
10. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
