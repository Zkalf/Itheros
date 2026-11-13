# Spec 0020 amendment 8: hold an item to select several

Status: accepted
Amends: [spec 0020](0020-item-bank.md) §3.2 (the bank screen) and [amendment 2](0020-item-bank.amendment-2.md) (the
tap on a row), [spec 0008](0008-character-and-world-layout.md) §3.5 (the tap on a square of the bag) and
[spec 0010 amendment 9](0010-professions.amendment-9.md) (a batch of salvages)
Issue: #267
Product owner: Zkalf (chose on 2026-11-13: Store and Take in the bank screen, Store and Salvage in the bag on
Character)
Date: 2026-11-13

## Why
- The player moves or salvages one item at a time: a tap on the item, then a tap on a button of its card.
- **Store all materials** and **Salvage all** of one quality help only when the player wants a whole group.
- A player who wants to store or salvage six of ten pieces of gear opens six cards.

## Change
**Where a selection can start**
1. A selection can start in three lists:

   | List | Where the character is | Actions |
   | --- | --- | --- |
   | The bank screen, tab Bag | at a place with a bank | Store |
   | The bank screen, tab Bank | at a place with a bank | Take |
   | The bag on Character | at a place with a bank | Store |
   | The bag on Character | at a forge | Salvage |

   Camp has a bank and a forge, so the bag on Character shows both actions there.
2. Elsewhere a hold on an item does nothing. A tap opens the item card, as today.

**How the player selects**
3. The player holds a finger on an item. The item becomes selected, and the selection starts.
4. While the selection runs, a tap on an item selects it, and a tap on a selected item removes it from the selection.
   A tap opens no item card.
5. A selected item is the whole item: all of its count. In the bag on Character, an item with several stacks has
   several squares; a hold or a tap on one of them selects all of them.
6. A selected row or square shows the fill of a selected chip behind it and a teal check mark on the top left corner
   of its socket. The picture, the ring of the quality and the count stay in view.
7. The kind chips, the search and the sort still work. A selected item that the list hides stays selected.

**The selection bar**
8. While the selection runs, a bar stands at the bottom of the screen. It does not scroll with the list.
9. The bar shows, from left to right:
   - a button × with the tooltip "Cancel";
   - the number of selected items as the list shows them, not their counts: "3 selected";
   - the actions of rule 1.
10. The buttons read **Store**, **Take** and **Salvage (14)**. The number on Salvage is the number of items that the
    salvage takes: the sum of the counts of the selected items that a single salvage takes (spec 0010 amendment 9
    rule 1).
11. Salvage shows only when that number is 1 or more.

**The actions**
12. **Store** moves the whole count of each selected item from the bag to the bank. It does not ask first.
13. **Take** moves the whole count of each selected item from the bank to the bag. It does not ask first. The bag can
    go over its spaces, as with Take on the item card (spec 0021).
14. **Salvage** is a batch of spec 0010 amendment 9, rules 4 to 6: it asks first with "Salvage 14 items?", it
    salvages in the bag's order, and it shows one message. Selected items that a salvage does not take (materials,
    meals, a starter tool) stay in the bag.
15. Each action is one player action: it syncs first and goes through the one queue of `GameController`. Store and
    Take use no steps and no roll.
16. A selected item that left its list during the sync does not move. The rest move.
17. After Store or Take a short note reads "Stored 12 items." or "Took 12 items.", with the sum of the counts. For one
    item it reads "Stored 1 item." or "Took 1 item."
18. A refusal of the rule shows as a note, and nothing moves.

**How the selection ends**
19. The selection ends:
    - after an action, also when the player answers "Keep them";
    - on a tap on ×;
    - on the back button or the back gesture, which then does not leave the screen;
    - when the player removes the last selected item;
    - when the player opens the other tab of the bank screen, another pane of Character or another tab of the game;
    - when no action of rule 1 is left, for example after a walk away from Camp.
20. When the selection ends, no item is selected and the bar goes.

**What stays**
21. Without a selection, a tap on an item opens its card. The card and its buttons do not change.
22. Store all materials and the Salvage all buttons stay.
23. Destroy stays on the item card only.
24. No number or save field changes. This does not move the pace, so it has no sim targets.

## Acceptance criteria
**Rules**
1. The rule for Store moves the whole count of each given item from the bag to the bank.
2. The rule for Take moves the whole count of each given item from the bank to the bag.
3. Each rule leaves the items that are not given where they are.
4. Each rule skips a given item that its list does not hold, and moves the rest.
5. Each rule refuses away from a place with a bank and changes nothing.
6. Each rule uses no steps and no roll.

**The start of a selection**
7. At Camp, a hold on a row of the bank screen's Bag tab selects it and shows the bar with "1 selected".
8. At Camp, a hold on a row of the Bank tab selects it and shows the bar.
9. At Camp, a hold on a square of the bag on Character selects it and shows the bar.
10. Away from a bank and a forge, a hold on an item in each of the three lists shows no bar.
11. Without a selection, a tap on an item opens its card.

**Select and look**
12. While the selection runs, a tap on a second item selects it, the bar reads "2 selected", and no card opens.
13. A tap on a selected item removes it from the selection.
14. A selected row and a selected square show the check mark; the others do not.
15. In the bag on Character, a hold on one square of an item with two stacks marks both squares, and the bar reads
    "1 selected".
16. A selected item stays selected after the player picks a kind chip that hides it.

**The actions**
17. Store on the Bag tab moves the whole count of each selected item to the bank, and the others stay.
18. Take on the Bank tab moves the whole count of each selected item to the bag, and the others stay.
19. Store in the bag on Character moves the selected items to the bank.
20. Store and Take open no dialog.
21. The note reads "Stored 12 items." after 12 items moved, and "Stored 1 item." after one. Take reads "Took …".
22. At a forge, the bar of the bag on Character shows "Salvage (N)", with N the sum of the counts of the selected gear
    and tools that a salvage takes.
23. With only materials selected, the bar shows no Salvage.
24. Salvage asks "Salvage N items?"; "Keep them" salvages nothing.
25. After "Salvage", the selected gear is gone, a selected material stays, and the message says the number of items
    and the dust.
26. The bank screen's bar shows no Salvage. At a forge without a bank the bar shows no Store.

**The end of a selection**
27. After Store, Take or Salvage, no item is selected and the bar is gone.
28. A tap on × ends the selection and moves nothing.
29. The back button ends the selection, and the screen stays open.
30. The selection ends when the player removes the last selected item.
31. The selection ends when the player opens the other tab of the bank screen.
32. The selection ends when the player opens another pane of Character.

**What stays**
33. Store all materials, the Salvage all buttons and the buttons of the item card stay.

**Check and release**
34. At 408 dp wide the bar with × , "12 selected", Store and "Salvage (140)" stands in one row and nothing is cut off.
35. Numbers and the save do not change. The pacing test passes.
36. The Bag tab of the bank screen and the bag on Character, each with a selection, are rendered at 408 dp wide
    before the PR (`CLAUDE.md`).
37. `releases/next/` has a line for players.
38. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
