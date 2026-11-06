# Spec 0020 amendment 2: pictures, item cards and kinds on the bank screen and in the bag

Status: accepted
Amends: [spec 0020](0020-item-bank.md) §3.2 (the bank screen, rules 15-19); spec 0008 §3.5 (the bag on the Character
tab)
Issue: #197, #109
Product owner: Zkalf (chose on 2026-11-06: filter buttons with All, four kinds, each list remembers its own pick
until the app closes, no counts on the buttons; accepted on 2026-11-06)
Date: 2026-11-06

## Why
- The bank screen lists each item as text only, for example "Rare Bone sword ×1". It shows no picture.
- A tap on an item opens only Store or Take, with no stats and no bonus stats. Two Rare items of the same kind look
  the same, so the player cannot tell which one to store or take.
- The bag and the bank show gear, tools, meals and materials in one long run. The bank has no space limit, so it gets
  long.

## Change
**The four kinds**
1. Each item has one of four kinds:
   - **Gear:** an item with a gear slot.
   - **Tools:** a tool.
   - **Meals:** a meal.
   - **Materials:** every other item.
2. The kind comes from the item data that exists today. No item gets a new field.

**The filter buttons**
3. A row of choice chips stands above the items: **All**, **Gear**, **Tools**, **Meals**, **Materials**. The chips
   show no counts.
4. The row stands in three lists:
   - the bag on the Character tab, above the grid;
   - the Bag tab of the bank screen;
   - the Bank tab of the bank screen.
5. **All** shows every item, in the order of the bag, as today.
6. Each other chip shows only the items of its kind, in the order of the bag.
7. The picked chip has the selected look of spec 0014 amendment 4. The other chips have the look of a chip that is not
   selected.
8. A kind with no items in that list reads "Nothing of this kind here."
9. Each of the three lists keeps its own pick. A pick in one list does not change the other two.
10. A list keeps its pick when the player leaves the screen and comes back.
11. When the app starts, each list shows **All**. The save does not keep the picks.

**The rows of the bank screen**
12. Each row of the Bag tab and the Bank tab starts with the item's picture in a 48 dp socket.
13. Gear and tools show the ring of their quality around the picture, as on the item card.
14. The row keeps its name in its quality colour and its count, for example "Bone sword ×1".

**The item card on the bank screen**
15. A tap on a row opens the item card: its picture, its name and kind, its stats and its bonus stats.
16. At Camp, the card of an item in the Bag tab shows **Store all** and **Store some…**.
17. At Camp, the card of an item in the Bank tab shows **Take all** and **Take some…**.
18. **Store some…** and **Take some…** ask "How many?", as today (the dialog of #115).
19. Away from Camp, a tap opens the card without Store or Take. The line "Items move only at Camp." stays.
20. The card on the bank screen shows no Equip, Eat, Auto-eat, Salvage or Reroll. Those stay on the card that the bag
    on the Character tab opens.

**What stays**
21. The bag on the Character tab keeps its grid, its squares and its card.
22. The bag spaces line counts every item in the bag, whatever chip is picked.
23. The Salvage all buttons count every item in the bag, whatever chip is picked.
24. The rules of Store and Take do not change.
25. No rule, number or save field changes. This does not move the pace, so it has no sim targets.

## Acceptance criteria
**The four kinds**
1. A sword, a pickaxe, a meal and an ore have the kinds Gear, Tools, Meals and Materials.

**The filter buttons**
2. The bag on the Character tab shows the chips All, Gear, Tools, Meals and Materials above the grid.
3. The Bag tab of the bank screen shows the same five chips.
4. The Bank tab of the bank screen shows the same five chips.
5. The chips show no counts.
6. All shows every item, in the order of the bag.
7. Gear shows only the gear, in the order of the bag.
8. Tools shows only the tools.
9. Meals shows only the meals.
10. Materials shows only the materials.
11. The picked chip has the selected look. The other chips do not.
12. A kind with no items reads "Nothing of this kind here."
13. A pick in the bag on the Character tab leaves both tabs of the bank screen on their own picks.
14. A pick in the Bag tab of the bank screen leaves the Bank tab on its own pick.
15. A list keeps its pick after the player closes the bank screen and opens it again.
16. After a restart of the app, each list shows All.

**The rows of the bank screen**
17. Each row of the Bag tab starts with the item's picture in a 48 dp socket.
18. Each row of the Bank tab starts with the item's picture in a 48 dp socket.
19. Gear and tools show the ring of their quality.
20. The row shows the name in its quality colour and the count.

**The item card on the bank screen**
21. A tap on a row opens the item card with its stats and bonus stats.
22. At Camp, the card of a Bag tab item shows Store all and Store some….
23. At Camp, the card of a Bank tab item shows Take all and Take some….
24. Store all on the card moves the whole stack to the bank.
25. Take some… on the card moves the count that the player types to the bag.
26. Away from Camp, a tap opens the card, and the card shows no Store or Take.
27. The card on the bank screen shows no Equip, Eat, Auto-eat, Salvage or Reroll.

**What stays**
28. The bag spaces line counts every item in the bag when a chip other than All is picked.
29. At a forge, the Salvage all buttons count every item in the bag when a chip other than All is picked.

**Check and release**
30. Rules, numbers and the save do not change. The pacing test passes.
31. The screens are rendered at 408 dp wide before the PR (`CLAUDE.md`).
32. `releases/next/` has a line for players.
33. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
