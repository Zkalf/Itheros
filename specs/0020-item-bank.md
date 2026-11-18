# Spec 0020: the item bank

Status: accepted
Intent: [intent/0020-item-bank.md](../intent/0020-item-bank.md) (accepted, 2026-11-02)
Builds on: spec 0008 §3.5 (the bag on the Character tab), spec 0010 (crafting, rerolls, salvage all), spec 0011
(cooking), spec 0003 (the queue), spec 0014 §2.2 (the selected look), spec 0021 (the bag limit)
Product owner: Zkalf
Date: 2026-11-02

Camp gets a bank. At Camp, the player moves items from the bag to the bank and back, at no cost. Crafting, cooking
and rerolls at Camp use items from the bag and the bank. This is the first build of intent 0020. Spec 0021 adds the
bag limit and the overloaded rule, with the sims of how fast the bag fills.

## 1. Decisions
| # | Question | Decision |
|---|---|---|
| 1 | Where is the bank | **At Camp only** (owner, intent 0020 decision 4). `world.json` marks a location with `"itemBank": true`. |
| 2 | How big is the bank | **No limit** (owner, intent 0020 decision 5). |
| 3 | Crafting and the bank | **Crafting and cooking at Camp use the bag and the bank. What they make goes into the bag** (owner, intent 0020 decision 7). |
| 4 | Which items the bank takes | **Every item in the bag.** Worn gear and worn tools stay worn: the player takes them off first (Claude). |
| 5 | What uses the bank's items | **Crafting, cooking and rerolls at a place with a bank.** Eat, wear, salvage and auto-eat use the bag only (Claude; the owner added rerolls on 2026-11-02). |
| 6 | What counts the bank's items | **Whatever counts what the player owns:** "Until I have N", the "found" lists and the item card's "You have" (Claude). |
| 7 | Can the player look in the bank away from Camp | **Yes, but not move items** (Claude). The player can plan what to fetch. |
| 8 | How the bag and the bank sort items by kind | **Filter buttons: All and four kinds, no counts. Each list remembers its own pick until the app closes** (owner, 2026-11-06). |
| 9 | The tabs of the bank screen | **Buttons in boxes, as the Journal's. Bank first, and the screen opens on it** (owner, playtest of 2026-11-06). |
| 10 | Search and sort | **The sorts Bag order, Name, Count and Quality, Bag order first. No "newest first", so no save field. Each list keeps its sort until the app closes. The search clears when the player leaves the list, and it matches the name and the quality** (owner, 2026-11-06). |
| 11 | The way to the bank | **A Bank button in the top bar. The two old ways stay. Store all materials does not ask first** (owner, 2026-11-10). |
| 12 | Camp's rows on Now | **Bank, Forge and Camp fire first; every row stays. The Bank row has no button: a tap on the row opens the bank** (owner, 2026-11-10). |
| 13 | Look-alike gear in the bank | **The stats and the bonus stats under the name** (owner, 2026-11-10). |
| 14 | Several items at once | **A hold selects. Store and Take on the bank screen, Store and Salvage in the bag on Character** (owner, 2026-11-13). |

## 2. Rules
1. The save holds a bank: each kind of item with its count, as the bag does.
2. At a location with a bank, the player can **store** an item: a count of it moves from the bag to the bank.
3. At a location with a bank, the player can **take** an item: a count of it moves from the bank to the bag. Since
   spec 0021 the bag has spaces: a take can put the bag over them (spec 0021 point 4).
4. A move uses no steps and no roll. It changes nothing else.
5. Away from a place with a bank, the game refuses a move.
6. A move of more than the bag or the bank holds is refused.
7. A craft, a cook or a reroll at a location with a bank:
   - It counts its inputs in the bag and the bank together. For a reroll, the inputs are its dust.
   - It takes each input from the bag first, then the rest from the bank.
   - What a craft or a cook makes goes into the bag.
8. A craft, a cook or a reroll away from a place with a bank uses the bag only.
9. The queue counts the bank for a craft, a cook or a reroll that will happen at a place with a bank. A craft or a
   reroll queued at Camp then starts when the bag and the bank hold its inputs.
10. Whatever counts what the player owns counts the bank too (decision 6). Owning an item in the bank counts as
    owning it.

## 3. Screens
### 3.1 The way to the bank
11. At Camp, the "Here" part of the Now screen shows a row **Bank**, with its icon and the line "Store items and take
    them back". The row has no button: a tap on it opens the bank screen, as a tap on the Forge row opens Crafting.
12. The Character tab shows a button **Bank** under the bag, everywhere.
13. Each way to the bank opens the bank screen: the Bank row, the Bank button under the bag and the Bank button of
    the top bar (point 61). It slides in, like the Journal, and a swipe back closes it.

**The Bank button in the top bar**
61. The plate in the top bar has a fifth button, **Bank**, at its left end: Bank, Supply chest, Achievements, Journal,
    Settings.
62. It shows the bank icon of the Bank row on Now. Its tooltip is "Bank".
63. A tap opens the bank screen from any of the four tabs, at Camp and away from it.
64. During the camp tour the button does nothing, as the other four.

**The order of "Here" at Camp**
72. After the monsters and the gathering spots, the rows of "Here" stand in this order:
    - **Bank**
    - **Forge**
    - **Camp fire**
    - the teachers, in their order of 2026-11-10
    - the Guild trainer
73. A place shows only the rows that it has.

### 3.2 The bank screen
14. The title is "Bank".
15. The screen has two tabs, **Bank** and **Bag**, in that order: Bank stands on the left. They are buttons in boxes
    on a plate, as the Journal's tabs are (spec 0014 §2.2): the selected one has the selected look. Each tab lists
    its items with their counts, in the order of the bag on the Character tab.
45. The screen opens on the Bank tab.
16. Away from Camp, a line under the tabs reads "Items move only at Camp." A tap on an item opens its card without
    Store or Take.
17. At Camp, the item card of an item in the Bag tab shows **Store all** and **Store some…**. Store some… asks "How
    many?" (the dialog of #115).
18. At Camp, the item card of an item in the Bank tab shows **Take all** and **Take some…**. Take some… asks "How
    many?".
19. Gear in both tabs shows in the colour of its quality, as on the item card.
20. An empty Bank tab reads "The bank is empty."

Since spec 0021, the Bag tab shows the bag's spaces line above its list (spec 0021 point 18).

**Store all materials**
65. At Camp, the Bag tab of the bank screen shows a button **Store all materials** under the bag spaces line.
66. A tap moves every item of the kind Materials (point 26) from the bag to the bank: the whole stack of each. It does
    not ask first.
67. Gear, tools and meals stay in the bag.
68. The move is one player action: it syncs first and goes through the one queue of `GameController`. It uses no
    steps and no roll.
69. After the move a short note reads "Stored 6 kinds of material.", with the count of kinds. For one kind it reads
    "Stored 1 kind of material."
70. The button does not show:
    - away from Camp;
    - when the bag holds no material.
71. The button stores every material in the bag, whatever kind button, search and sort the list shows.

### 3.3 Crafting and cooking at Camp
21. At Camp, the "have" count of each recipe input counts the bag and the bank together.
22. At Camp, the filter "Have the materials" on a profession screen counts the bag and the bank.

### 3.4 The kinds of item and the kind chips
26. Each item has one of four kinds:
    - **Gear:** an item with a gear slot.
    - **Tools:** a tool.
    - **Meals:** a meal.
    - **Materials:** every other item.
27. The kind comes from the item data. No item has a field for it.
28. A row of choice chips stands above the items: **All**, **Gear**, **Tools**, **Meals**, **Materials**. The chips
    show no counts.
29. The row stands in three lists:
    - the bag on the Character tab, above the grid;
    - the Bag tab of the bank screen;
    - the Bank tab of the bank screen.
30. **All** shows every item, in the order of the bag.
31. Each other chip shows only the items of its kind, in the order of the bag.
32. The picked chip has the selected look of spec 0014 §2.2. The other chips have the look of a chip that is not
    selected.
33. A kind with no items in that list reads "Nothing of this kind here."
34. Each of the three lists keeps its own pick. A pick in one list does not change the other two.
35. A list keeps its pick when the player leaves the screen and comes back.
36. When the app starts, each list shows **All**. The save does not keep the picks.
42. The bag on the Character tab keeps its grid, its squares and its card (spec 0008 §3.5).
43. The bag spaces line counts every item in the bag, whatever chip, search and sort the list shows.
44. The Salvage all buttons count every item in the bag, whatever chip, search and sort the list shows.

### 3.5 The rows and the item card on the bank screen
37. Each row of the Bag tab and the Bank tab starts with the item's picture in a 48 dp socket.
38. Gear and tools show the ring of their quality around the picture, as on the item card.
39. The row keeps its name in its quality colour and its count, for example "Bone sword ×1".
74. A row of a piece of gear shows a second line under its name: its stats, its slot, then each bonus stat, with
    " · " between them. For example "+2 Defense · +20 HP · Chest · +4% Hit". A weapon shows its damage type and hands
    in place of the slot, as a recipe row does.
75. A row of a tool shows its line of the item card: "Mining tool · −20% steps".
76. The words are those of the item card and the recipe rows.
77. Rows of materials and meals keep one line.
40. A tap on a row opens the item card: its picture, its name and kind, its stats and its bonus stats. At Camp it
    shows Store or Take (points 17 and 18).
41. The card on the bank screen shows no Equip, Eat, Auto-eat, Salvage or Reroll. Those stay on the card that the bag
    on the Character tab opens. Since spec 0021 amendment 2, the card shows **Destroy** (spec 0021 point 32).

### 3.6 Search and sort
46. A search field and a sort button stand below the kind chips, in one row, in the three lists of point 29.
47. The search, the sort and the kind chips work together. A list shows the items of the picked kind that match the
    search, in the picked sort.

**The search**
48. The field shows a search icon and the hint "Search". It is empty when the list opens.
49. The list shows only the items whose words contain the typed text. Upper and lower case do not matter. Spaces at
    the start and the end do not count.
50. The words of an item are:
    - its name, for example "Bone sword";
    - the name of its quality, for example "Rare", Common included;
    - "Perfect" for a Perfect meal.
51. An empty field hides nothing.
52. When the field has text, a clear button (×) stands at its end. A tap on it empties the field.
53. When no item of the list matches, the list reads `Nothing here matches "<text>".`, for example
    `Nothing here matches "hide".` When the field is empty and a kind has no items, the line of point 33 stays:
    "Nothing of this kind here."
54. The search clears when the player leaves the list: another tab of the bank screen, another pane or tab of the
    Character tab, or the bank screen closes.

**The sort**
55. The sort button shows a sort icon and the name of the picked sort. A tap opens a menu of four sorts:

    | Sort | Order |
    |---|---|
    | **Bag order** | The order of the bag (spec 0008 §3.5). |
    | **Name** | By the name on the row, A to Z. |
    | **Count** | The biggest stack first. |
    | **Quality** | The best quality first. A Perfect meal comes before the other items of its quality. |

56. Items that a sort ranks the same keep the order of the bag among them.
57. Each list starts on **Bag order**.
58. Each of the three lists keeps its own sort. A sort in one list does not change the other two.
59. A list keeps its sort when the player leaves the list and comes back.
60. When the app starts, each list shows **Bag order**. The save does not keep the sorts.

### 3.7 Select several items
**Where a selection can start**
78. A selection can start in three lists:

    | List | Where the character is | Actions |
    | --- | --- | --- |
    | The bank screen, tab Bag | at a place with a bank | Store |
    | The bank screen, tab Bank | at a place with a bank | Take |
    | The bag on Character | at a place with a bank | Store |
    | The bag on Character | at a forge | Salvage |

    Camp has a bank and a forge, so the bag on Character shows both actions there.
79. Elsewhere a hold on an item does nothing. A tap opens the item card.

**How the player selects**
80. The player holds a finger on an item. The item becomes selected, and the selection starts.
81. While the selection runs, a tap on an item selects it, and a tap on a selected item removes it from the
    selection. A tap opens no item card.
82. A selected item is the whole item: all of its count. In the bag on Character, an item with several stacks has
    several squares; a hold or a tap on one of them selects all of them.
83. A selected row or square shows the fill of a selected chip behind it and a teal check mark on the top left corner
    of its socket. The picture, the ring of the quality and the count stay in view.
84. The kind chips, the search and the sort still work. A selected item that the list hides stays selected.

**The selection bar**
85. While the selection runs, a bar stands at the bottom of the screen. It does not scroll with the list.
86. The bar shows, from left to right:
    - a button × with the tooltip "Cancel";
    - the number of selected items as the list shows them, not their counts: "3 selected";
    - the actions of point 78.
87. The buttons read **Store**, **Take** and **Salvage (14)**. The number on Salvage is the number of items that the
    salvage takes: the sum of the counts of the selected items that a single salvage takes (spec 0010 §7.1).
88. Salvage shows only when that number is 1 or more.

**The actions**
89. **Store** moves the whole count of each selected item from the bag to the bank. It does not ask first.
90. **Take** moves the whole count of each selected item from the bank to the bag. It does not ask first. The bag can
    go over its spaces, as with Take on the item card (spec 0021).
91. **Salvage** is a batch of spec 0010 §7.1 "Salvage all": it asks first with "Salvage 14 items?", it salvages in
    the bag's order, and it shows one message. Selected items that a salvage does not take (materials, meals, a
    starter tool) stay in the bag.
92. Each action is one player action: it syncs first and goes through the one queue of `GameController`. Store and
    Take use no steps and no roll.
93. A selected item that left its list during the sync does not move. The rest move.
94. After Store or Take a short note reads "Stored 12 items." or "Took 12 items.", with the sum of the counts. For one
    item it reads "Stored 1 item." or "Took 1 item."
95. A refusal of the rule shows as a note, and nothing moves.
98. Destroy stays on the item card only. The selection bar has no Destroy.

**How the selection ends**
96. The selection ends:
    - after an action, also when the player answers "Keep them";
    - on a tap on ×;
    - on the back button, the back gesture or a swipe to the right on the screen (as the swipe of spec 0014
      amendment 5), which then does not leave the screen;
    - when the player removes the last selected item;
    - when the player opens the other tab of the bank screen, another pane of Character or another tab of the game;
    - when no action of point 78 is left, for example after a walk away from Camp.
97. When the selection ends, no item is selected and the bar goes.

## 4. Save
23. Save schema 16 (`GameState.schemaVersion`). A new field `itemBank`: a map of item keys to counts. The step
    bank's field becomes `stepBank`; a save before 16 loads its `bank` into it, so every old save keeps its steps.
24. A save from before schema 16 loads with an empty bank.
25. Every save fixture in `app/test/fixtures/saves/` loads.

The names in the code: the item bank is `GameState.itemBank`, and a place with an item bank has
`LocationDef.itemBank`. The step bank is `GameState.stepBank`. The controller's moves are
`storeInBank(key, count)` and `takeFromBank(key, count)`. The plain name `bank` would not say which bank it is.

## 5. Balance
The bank adds no steps and no items. The sim walker of spec 0020 did not use the bank; spec 0021 §5.3 teaches it to
bank. The kinds, the search, the sort, the top bar button, the order of "Here", the second line of a row and the
selection do not move the pace, so they have no sim targets. The pacing test stays green.

## 6. Out of scope
- The bag limit, the overloaded rule and the "Bigger bag" talent: spec 0021 builds them.
- Banks in other places.

## 7. Acceptance criteria
**Moves**
1. At Camp, Store moves the count from the bag to the bank.
2. At Camp, Take moves the count from the bank to the bag.
3. A move uses no steps and no roll.
4. Away from Camp, a move is refused.
5. A move of more than the bag or the bank holds is refused.
6. Worn gear cannot be stored.

**Crafting and cooking**
7. At Camp, a craft with its inputs only in the bank starts and runs.
8. At Camp, a craft takes its inputs from the bag first, then from the bank.
9. At Camp, a cook uses inputs from the bank.
10. What a craft at Camp makes goes into the bag.
11. Away from Camp, a craft does not count the bank.
12. A craft queued for Camp counts the bank.

**Owning**
13. "Until I have N" counts the bank.
14. Removed on 2026-11-17 (spec 0024: Next goal went away).
15. Eat, wear and salvage refuse an item that is only in the bank.

**Screens**
16. At Camp, Now shows the Bank row.
17. The Character tab shows Bank everywhere.
18. The bank screen has the tabs Bank and Bag with their items and counts.
19. Away from Camp, the screen reads "Items move only at Camp." and shows no Store or Take.
20. At Camp, Store all and Store some… move the item to the bank.
21. At Camp, Take all and Take some… move the item to the bag.
22. Gear shows in its quality colour.
23. An empty bank reads "The bank is empty."
24. At Camp, a recipe's "have" counts the bag and the bank.
25. At Camp, "Have the materials" counts the bank.

**Save**
26. The save version is 16.
27. A schema 15 save loads with an empty bank.
28. Every save fixture loads.

**Check and release**
29. Rules, numbers and the save change only as this spec says. The pacing test passes.
30. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
31. Every bank move syncs first and goes through the one queue of `GameController`.
32. `releases/next.md` has a line for players about the bank. Each later change adds its own line in
    `releases/next/`.

**Rerolls at Camp**
33. At Camp, with the dust only in the bank, a reroll starts and takes its dust from the bank.
34. At Camp, with 1 dust in the bag and the rest in the bank, a reroll takes the 1 from the bag and the rest from the
    bank.
35. At Grey Moor, with the dust only in the bank, a reroll is refused with "Not enough … dust".
36. A reroll queued at Camp behind another action starts when the bag and the bank hold its dust.
37. On the item card at Camp, with the dust only in the bank, Reroll adds the reroll and it runs.

**The four kinds**
38. A sword, a pickaxe, a meal and an ore have the kinds Gear, Tools, Meals and Materials.

**The kind chips**
39. The bag on the Character tab shows the chips All, Gear, Tools, Meals and Materials above the grid.
40. The Bag tab of the bank screen shows the same five chips.
41. The Bank tab of the bank screen shows the same five chips.
42. The chips show no counts.
43. All shows every item, in the order of the bag.
44. Gear shows only the gear, in the order of the bag.
45. Tools shows only the tools.
46. Meals shows only the meals.
47. Materials shows only the materials.
48. The picked chip has the selected look. The other chips do not.
49. A kind with no items reads "Nothing of this kind here."
50. A pick in the bag on the Character tab leaves both tabs of the bank screen on their own picks.
51. A pick in the Bag tab of the bank screen leaves the Bank tab on its own pick.
52. A list keeps its pick after the player closes the bank screen and opens it again.
53. After a restart of the app, each list shows All.

**The rows of the bank screen**
54. Each row of the Bag tab starts with the item's picture in a 48 dp socket.
55. Each row of the Bank tab starts with the item's picture in a 48 dp socket.
56. Gear and tools show the ring of their quality.
57. The row shows the name in its quality colour and the count.

**The item card on the bank screen**
58. A tap on a row opens the item card with its stats and bonus stats.
59. At Camp, the card of a Bag tab item shows Store all and Store some….
60. At Camp, the card of a Bank tab item shows Take all and Take some….
61. Store all on the card moves the whole stack to the bank.
62. Take some… on the card moves the count that the player types to the bag.
63. Away from Camp, a tap opens the card, and the card shows no Store or Take.
64. The card on the bank screen shows no Equip, Eat, Auto-eat, Salvage or Reroll.

**The kind chips leave the counts whole**
65. The bag spaces line counts every item in the bag when a chip other than All is picked.
66. At a forge, the Salvage all buttons count every item in the bag when a chip other than All is picked.
67. The bag and the bank screen with the kind chips are rendered at 408 dp wide before the PR (`CLAUDE.md`).

**The tabs of the bank screen**
68. The bank screen shows Bank on the left and Bag on the right, each in a button box.
69. The selected tab has the selected look of spec 0014 §2.2; the other does not.
70. The bank screen opens on the Bank tab.
71. A tap on Bag shows the bag's items; a tap on Bank shows the bank's.

**Search and sort: where**
72. The bag on the Character tab shows the search field and the sort button below the kind chips.
73. The Bag tab of the bank screen shows the search field and the sort button.
74. The Bank tab of the bank screen shows the search field and the sort button.

**The search**
75. The field shows the hint "Search" when it is empty.
76. "hide" shows only the items whose name contains "hide".
77. "HIDE" shows the same items as "hide".
78. "rare" shows the Rare items and no item of another quality.
79. "common" shows the Common items.
80. "perfect" shows a Perfect meal and not the plain meal.
81. The search and a kind chip work together: Gear with "bone" shows only the gear whose name contains "bone".
82. The clear button empties the field and shows every item of the picked kind again.
83. A search that matches nothing reads `Nothing here matches "<text>".`
84. The search is empty after the player closes the bank screen and opens it again.
85. The search of the bag on the Character tab is empty after the player opens another pane and comes back.

**The sort**
86. The sort button shows "Bag order" when a list opens for the first time.
87. The menu offers Bag order, Name, Count and Quality.
88. Bag order shows the items in the order of the bag.
89. Name shows the items by name, A to Z.
90. Count shows the biggest stack first.
91. Quality shows the best quality first.
92. A Perfect meal comes before a plain meal under Quality.
93. Items that a sort ranks the same keep the order of the bag.
94. A sort in the bag on the Character tab leaves both tabs of the bank screen on Bag order.
95. A sort in the Bag tab of the bank screen leaves the Bank tab on its own sort.
96. A list keeps its sort after the player closes the bank screen and opens it again.
97. After a restart of the app, each list shows Bag order.

**The search leaves the counts whole**
98. The bag spaces line counts every item in the bag while a search hides some items.
99. At a forge, the Salvage all buttons count every item in the bag while a search hides some items.
100. Each row and square still shows its picture and opens its card.
101. The three lists with the search and the sort are rendered at 408 dp wide before the PR (`CLAUDE.md`).

**The Bank button in the top bar**
102. The top bar shows five buttons in this order: Bank, Supply chest, Achievements, Journal, Settings.
103. A tap on Bank opens the bank screen from each of the four tabs.
104. Away from Camp, a tap on Bank opens the bank screen with "Items move only at Camp."
105. During the camp tour a tap on Bank does nothing.
106. At 408 dp wide the five buttons stand in one row and no button is cut off.

**Store all materials**
107. At Camp, the Bag tab shows Store all materials when the bag holds a material.
108. A tap moves the whole stack of every material from the bag to the bank.
109. Gear, a tool and a meal stay in the bag after the tap.
110. The tap opens no dialog.
111. A note reads "Stored 2 kinds of material." after two kinds moved, and "Stored 1 kind of material." after one.
112. With the kind chip Gear picked, the tap still stores every material.
113. Away from Camp, the Bag tab shows no Store all materials.
114. With no material in the bag, the Bag tab shows no Store all materials.
115. The Bank tab shows no Store all materials.
116. The rule refuses the move away from a place with a bank.
117. The move uses no steps and no roll.
118. The top bar and the Bag tab are rendered at 408 dp wide before the PR (`CLAUDE.md`).

**The order of "Here"**
119. At Camp, the rows stand from top to bottom: Bank, Forge, Camp fire, the six teachers, the trainer.
120. The six teachers keep their order among themselves.
121. At 408 dp wide, on a phone 884 dp high, Bank, Forge and Camp fire are in view when the player scrolls "Here" to
     the top of the screen.

**The Bank row**
122. The Bank row shows no button and no text "Open bank".
123. The Bank row shows "Bank" and "Store items and take them back".
124. A tap on the Bank row opens the bank screen.
125. Away from Camp, Now shows no Bank row.
126. Now at Camp is rendered at 408 dp wide before the PR (`CLAUDE.md`).

**A gear or tool row shows its stats**
127. A gear row shows its base stats and its slot under the name.
128. Two pieces of the same gear and quality with different bonus stats show different second lines, each with its
     own bonus stat.
129. A tool row shows its tool line.
130. A material row and a meal row show no second line.
131. The rows of both lists (Bank and Bag) follow criteria 127 to 130.
132. At text size 2.0 on a 408 dp phone a gear row with bonus stats does not overflow.
133. The bank's list with look-alike gear is rendered at 408 dp wide before the PR (`CLAUDE.md`).

**Select several: the rules**
134. The rule for Store moves the whole count of each given item from the bag to the bank.
135. The rule for Take moves the whole count of each given item from the bank to the bag.
136. Each rule leaves the items that are not given where they are.
137. Each rule skips a given item that its list does not hold, and moves the rest.
138. Each rule refuses away from a place with a bank and changes nothing.
139. Each rule uses no steps and no roll.

**The start of a selection**
140. At Camp, a hold on a row of the bank screen's Bag tab selects it and shows the bar with "1 selected".
141. At Camp, a hold on a row of the Bank tab selects it and shows the bar.
142. At Camp, a hold on a square of the bag on Character selects it and shows the bar.
143. Away from a bank and a forge, a hold on an item in each of the three lists shows no bar.
144. Without a selection, a tap on an item opens its card.

**Select and look**
145. While the selection runs, a tap on a second item selects it, the bar reads "2 selected", and no card opens.
146. A tap on a selected item removes it from the selection.
147. A selected row and a selected square show the check mark; the others do not.
148. In the bag on Character, a hold on one square of an item with two stacks marks both squares, and the bar reads
     "1 selected".
149. A selected item stays selected after the player picks a kind chip that hides it.

**The actions of a selection**
150. Store on the Bag tab moves the whole count of each selected item to the bank, and the others stay.
151. Take on the Bank tab moves the whole count of each selected item to the bag, and the others stay.
152. Store in the bag on Character moves the selected items to the bank.
153. Store and Take open no dialog.
154. The note reads "Stored 12 items." after 12 items moved, and "Stored 1 item." after one. Take reads "Took …".
155. At a forge, the bar of the bag on Character shows "Salvage (N)", with N the sum of the counts of the selected
     gear and tools that a salvage takes.
156. With only materials selected, the bar shows no Salvage.
157. Salvage asks "Salvage N items?"; "Keep them" salvages nothing.
158. After "Salvage", the selected gear is gone, a selected material stays, and the message says the number of items
     and the dust.
159. The bank screen's bar shows no Salvage. At a forge without a bank the bar shows no Store.

**The end of a selection**
160. After Store, Take or Salvage, no item is selected and the bar is gone.
161. A tap on × ends the selection and moves nothing.
162. The back button ends the selection, and the screen stays open.
163. The selection ends when the player removes the last selected item.
164. The selection ends when the player opens the other tab of the bank screen.
165. The selection ends when the player opens another pane of Character.

**What stays with a selection**
166. Store all materials, the Salvage all buttons and the buttons of the item card stay.

**The selection at 408 dp**
167. At 408 dp wide the bar with ×, "12 selected", Store and "Salvage (140)" stands in one row and nothing is cut
     off.
168. The Bag tab of the bank screen and the bag on Character, each with a selection, are rendered at 408 dp wide
     before the PR (`CLAUDE.md`).

## History
- 2026-11-02: first version (intent 0020, plan 0040, #66). Criteria 1-32.
- 2026-11-02, erratum 1 (#66): the names of the two banks, `itemBank` and `stepBank`; the controller's moves.
  Decision 1; point 23; §4.
- 2026-11-02, spec 0021 (#173): the bag has spaces; a take can put it over them; the Bag tab shows the spaces line.
  Point 3; §3.2; §6.
- 2026-11-02, amendment 1 (#181, plan 0042): a reroll at Camp takes its dust from the bank too. Decision 5; points
  7-9; criteria 33-37.
- 2026-11-06, amendment 2 (#197, #109): the four kinds and their chips; pictures and the item card on the bank
  screen. Decision 8; points 16-18 and 26-44; §3.4; §3.5; criteria 38-67.
- 2026-11-06, spec 0021 amendment 2 (#180): the card on the bank screen shows Destroy. Point 41.
- 2026-11-06, amendment 3 (#220): the tabs as buttons, Bank first, and the screen opens on Bank. Decision 9; points
  15 and 45; criteria 18 and 68-71.
- 2026-11-06, amendment 4 (#221): search and sort in the bag and the bank. Decision 10; points 43-44 and 46-60;
  §3.6; criteria 72-101.
- 2026-11-10, amendment 5 (#249, plan 0059): the Bank button in the top bar; Store all materials. Decision 11;
  points 13 and 61-71; §6; criteria 102-118.
- 2026-11-10, amendment 6 (#250, plan 0060): Bank, Forge and Camp fire first on "Here"; the Bank row has no button.
  Decision 12; points 11 and 72-73; criteria 16 and 119-126.
- 2026-11-10, amendment 7 (#255, plan 0062): a gear or tool row in the bank shows its stats. Decision 13; points
  74-77; criteria 127-133.
- 2026-11-13, amendment 8 (#267, plan 0067): hold an item to select several. Decision 14; points 78-98; §3.7;
  criteria 134-168.
- 2026-11-15 (plan 0068): the amendments and the erratum folded into this file. No rule, number or criterion
  changed.
- 2026-11-17, spec 0024: quests replace Next goal. Decision 6; criterion 14. Accepted.
- 2026-11-18 (#287): a swipe to the right on the screen also ends the selection, as the owner asked. Point 96.
  Accepted.
