# Spec 0020 amendment 4: search and sort in the bag and the bank

Status: accepted
Amends: [spec 0020 amendment 2](0020-item-bank.amendment-2.md) (the filter buttons, rules 3-11); spec 0008 §3.5 (the
bag on the Character tab)
Issue: #221
Product owner: Zkalf (chose on 2026-11-06: the sorts Bag order, Name, Count and Quality, Bag order first; no
"newest first", so no save field; each list keeps its sort until the app closes, the search clears when the player
leaves the list; the search matches the name and the quality; accepted on 2026-11-06)
Date: 2026-11-06

## Why
- The bank has no space limit, so it grows long.
- The kind buttons of amendment 2 help, but Materials alone holds up to 65 kinds of item.
- The player cannot find one item by its name, and cannot put the list in another order.

## Change
**Where**
1. A search field and a sort button stand below the kind buttons, in one row, in the three lists of amendment 2:
   - the bag on the Character tab;
   - the Bag tab of the bank screen;
   - the Bank tab of the bank screen.
2. The search, the sort and the kind buttons work together. A list shows the items of the picked kind that match the
   search, in the picked sort.

**The search**
3. The field shows a search icon and the hint "Search". It is empty when the list opens.
4. The list shows only the items whose words contain the typed text. Upper and lower case do not matter. Spaces at the
   start and the end do not count.
5. The words of an item are:
   - its name, for example "Bone sword";
   - the name of its quality, for example "Rare", Common included;
   - "Perfect" for a Perfect meal.
6. An empty field hides nothing.
7. When the field has text, a clear button (×) stands at its end. A tap on it empties the field.
8. When no item of the list matches, the list reads `Nothing here matches "<text>".`, for example
   `Nothing here matches "hide".` When the field is empty and a kind has no items, the line of amendment 2 rule 8
   stays: "Nothing of this kind here."
9. The search clears when the player leaves the list: another tab of the bank screen, another pane or tab of the
   Character tab, or the bank screen closes.

**The sort**
10. The sort button shows a sort icon and the name of the picked sort. A tap opens a menu of four sorts:

    | Sort | Order |
    |---|---|
    | **Bag order** | The order of the bag, as today (spec 0008 §3.5). |
    | **Name** | By the name on the row, A to Z. |
    | **Count** | The biggest stack first. |
    | **Quality** | The best quality first. A Perfect meal comes before the other items of its quality. |

11. Items that a sort ranks the same keep the order of the bag among them.
12. Each list starts on **Bag order**.
13. Each of the three lists keeps its own sort. A sort in one list does not change the other two.
14. A list keeps its sort when the player leaves the list and comes back.
15. When the app starts, each list shows **Bag order**. The save does not keep the sorts.

**What stays**
16. The kind buttons, their looks and their memory stay as in amendment 2.
17. The rows, the squares and the item cards stay as they are.
18. The bag spaces line counts every item in the bag, whatever the search and the sort.
19. The Salvage all buttons count every item in the bag, whatever the search and the sort.
20. No rule, number or save field changes. This does not move the pace, so it has no sim targets.

## Acceptance criteria
**Where**
1. The bag on the Character tab shows the search field and the sort button below the kind buttons.
2. The Bag tab of the bank screen shows the search field and the sort button.
3. The Bank tab of the bank screen shows the search field and the sort button.

**The search**
4. The field shows the hint "Search" when it is empty.
5. "hide" shows only the items whose name contains "hide".
6. "HIDE" shows the same items as "hide".
7. "rare" shows the Rare items and no item of another quality.
8. "common" shows the Common items.
9. "perfect" shows a Perfect meal and not the plain meal.
10. The search and a kind button work together: Gear with "bone" shows only the gear whose name contains "bone".
11. The clear button empties the field and shows every item of the picked kind again.
12. A search that matches nothing reads `Nothing here matches "<text>".`
13. The search is empty after the player closes the bank screen and opens it again.
14. The search of the bag on the Character tab is empty after the player opens another pane and comes back.

**The sort**
15. The sort button shows "Bag order" when a list opens for the first time.
16. The menu offers Bag order, Name, Count and Quality.
17. Bag order shows the items in the order of the bag.
18. Name shows the items by name, A to Z.
19. Count shows the biggest stack first.
20. Quality shows the best quality first.
21. A Perfect meal comes before a plain meal under Quality.
22. Items that a sort ranks the same keep the order of the bag.
23. A sort in the bag on the Character tab leaves both tabs of the bank screen on Bag order.
24. A sort in the Bag tab of the bank screen leaves the Bank tab on its own sort.
25. A list keeps its sort after the player closes the bank screen and opens it again.
26. After a restart of the app, each list shows Bag order.

**What stays**
27. The bag spaces line counts every item in the bag while a search hides some items.
28. At a forge, the Salvage all buttons count every item in the bag while a search hides some items.
29. Each row and square still shows its picture and opens its card.

**Check and release**
30. Rules, numbers and the save do not change. The pacing test passes.
31. The screens are rendered at 408 dp wide before the PR (`CLAUDE.md`).
32. `releases/next/` has a line for players.
33. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
