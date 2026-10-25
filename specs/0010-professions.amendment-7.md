# Spec 0010 amendment 7: tool lines say the saving, weapon recipes say their damage type

Status: accepted
Amends: [spec 0010](0010-professions.md) §8.1 (the words of the tool line) and the recipe rows of §8.1 with
[amendment 5](0010-professions.amendment-5.md) §2.1
Issues: #99, #100
Product owner: Zkalf (asked for both on 2026-10-25, playtest of main 69c3105)
Date: 2026-10-25

## Why
- A tool line says the share of the steps that an action costs with the tool: "Hilde's old pick · 100% steps". The
  owner read "100% steps" as a bonus. It means the tool gives no saving (#99).
- A weapon recipe row shows its stats and its slot ("+3 Attack · Main hand"), not its damage type. The damage type
  meets the armour type of a monster (spec 0009), but the player sees it only on the item card after the craft
  (#100).

## Change
1. **Tool lines** say the saving of the tool, not the share:
   - A tool with no saving (share 100%, the starter tools) says **"Full step cost"**.
   - Any other tool says **"−N% steps"**, where N is 100 minus its share. A Common copper tool says "−10% steps". An
     Uncommon one says "−12% steps".
   - This applies to each tool line: the tool row on a profession screen ("Iron pickaxe · −20% steps"), the item card
     ("Mining tool · −20% steps") and the row of a tool recipe.
   - The rule of §3.2 and its numbers stay. Only the words change.
2. **Weapon recipe rows** show the damage type and the hands of the weapon in place of its slot, before its stats:
   "Slash · One hand · +3 Attack". These are the words that the item card shows today.
3. Other recipe rows keep their words. Armour rows keep their slot: the armour type of the player's gear plays no
   part in a fight. Rings, trinkets, tools, meals and materials stay as they are.

## Acceptance criteria
**Tool lines**
1. A starter tool's line says "Full step cost", on its profession screen and on its item card.
2. A Common copper tool's line says "−10% steps", on its profession screen and on its item card.
3. A tool of higher quality takes 2 more points off per quality step: an Uncommon copper tool says "−12% steps".
4. The row of a tool recipe says the saving of a Common tool of its tier, for example "−10% steps" for the copper
   pickaxe.
5. No tool line shows "% steps" without the minus sign.

**Weapon recipe rows**
6. The row of a one-handed weapon recipe shows its damage type and "One hand" before its stats, for example
   "Slash · One hand · +3 Attack" for the copper sword.
7. The row of a two-handed weapon recipe shows "Two hands".
8. An armour recipe row keeps its slot and shows no armour type.

**Check and release**
9. Rules, numbers and the save do not change. The pacing test passes.
10. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
