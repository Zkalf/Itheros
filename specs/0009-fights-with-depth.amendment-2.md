# Spec 0009 amendment 2: the worn row of the slot sheet shows its bonus stats

Status: accepted
Amends: [spec 0009](0009-fights-with-depth.md) §8.2 (item card and slot sheet: "List rows (bag grid, doll, slot
sheet rows) show no bonus stats")
Issue: #107
Product owner: Zkalf (chose in issue #107 on 2026-10-25 that the worn row shows its rolled stats)
Date: 2026-10-26

## Why
- In the slot sheet, the row of the worn item shows only its base stats ("+5 Attack").
- Its bonus stats (Crit, Hit, Dodge and so on) are missing.
- The bag rows under it show a change ("+2 Attack · −3% Crit") that counts every stat, the bonus stats too.
- So the worn row looks incomplete next to the bag rows.

## Change
1. **Worn row:** the row of the worn item in the slot sheet shows:
   - its base stats on one line, as today;
   - then each bonus stat on its own line ("+3% Crit"), in the quality colour of the item, as on the item card.
2. Repeated bonus stats show as separate lines, as on the item card.
3. The worn row does not show the damage type, the hands or the armour type. The item card shows them.
4. Only the worn row changes. These keep the rule "no bonus stats":
   - the bag grid;
   - the doll;
   - the bag rows of the slot sheet. They keep their change line.

## Acceptance criteria
**Slot sheet**
1. The worn row shows the base stats of the worn item.
2. The worn row shows each bonus stat of the worn item on its own line.
3. A worn item with two equal bonus stats shows two lines.
4. A worn Common item shows only its base stats line.
5. Each bag row of the slot sheet shows its change line and no bonus stat lines.

**Check and release**
6. Rules, numbers and the save do not change. The pacing test passes.
7. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
