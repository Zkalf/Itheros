# Spec 0008 amendment 4: a tap on a worn item opens its card

Status: accepted
Amends: [spec 0008 amendment 3](0008-character-and-world-layout.amendment-3.md) change 2 and criterion 16 (a tap on a
slot), and [spec 0008](0008-character-and-world-layout.md) §3.5 (the buttons of the item card)
Issue: #107
Product owner: Zkalf (chose option (a) in issue #107 on 2026-10-25)
Date: 2026-10-26

## Why
- Today a tap on a filled slot of the doll opens the slot sheet.
- The player must tap the worn item in the sheet a second time to see its item card.
- The owner finds the two taps not intuitive.

## Change
1. **Filled slot:** a tap on a filled slot of the doll opens the item card of the item worn there.
2. **Change button:** the item card of a worn item shows **Change** next to **Unequip**.
   - Change closes the item card and opens the slot sheet of that slot.
   - Unequip moves the item to the bag, as today.
3. **Empty slot:** a tap on an empty slot opens its slot sheet, as today. This includes the greyed Off hand under a
   two-hander.
4. What stays as it is:
   - The slot sheet keeps its rows and its Unequip, Equip and Swap buttons (amendment 3, changes 2 and 3).
   - A tap on the worn row in the slot sheet opens the item card of the worn item. That card now shows Change too.
   - The item card of a bag item keeps Equip or Swap. It shows no Change button.

## Acceptance criteria
**Doll**
1. A tap on a filled slot opens the item card of the item worn in that slot.
2. A tap on an empty slot opens the slot sheet of that slot.
3. With a two-hander worn, a tap on the greyed Off hand opens the Off hand slot sheet.

**Item card**
4. The item card of a worn item shows a Change button and an Unequip button.
5. Change closes the item card and opens the slot sheet of the slot that holds the item.
6. Unequip on the item card of a worn item moves the item to the bag.
7. The item card of a bag item shows no Change button.

**Check and release**
8. Rules, numbers and the save do not change. The pacing test passes.
9. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
