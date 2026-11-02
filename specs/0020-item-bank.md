# Spec 0020: the item bank

Status: accepted
Intent: [intent/0020-item-bank.md](../intent/0020-item-bank.md) (accepted, 2026-11-02)
Builds on: spec 0008 (the bag on the Character tab), spec 0010 (crafting), spec 0011 (cooking), spec 0003 (the
queue)
Overrides: nothing
Product owner: Zkalf
Date: 2026-11-02

Camp gets a bank. At Camp, the player moves items from the bag to the bank and back, at no cost. Crafting and cooking
at Camp use materials from the bag and the bank. This is the first build of intent 0020. The bag limit and the
overloaded rule come in a later spec, with the sims of how fast the bag fills.

## 1. Decisions
| # | Question | Decision |
|---|---|---|
| 1 | Where is the bank | **At Camp only** (owner, intent 0020 decision 4). `world.json` marks a location with `"bank": true`. |
| 2 | How big is the bank | **No limit** (owner, intent 0020 decision 5). |
| 3 | Crafting and the bank | **Crafting and cooking at Camp use the bag and the bank. What they make goes into the bag** (owner, intent 0020 decision 7). |
| 4 | Which items the bank takes | **Every item in the bag.** Worn gear and worn tools stay worn: the player takes them off first (Claude). |
| 5 | What uses the bank's items | **Only crafting and cooking at a place with a bank.** Eat, wear, salvage, reroll and auto-eat use the bag only (Claude). |
| 6 | What counts the bank's items | **Whatever counts what the player owns:** "Until I have N", the next goal, the "found" lists and the item card's "You have" (Claude). |
| 7 | Can the player look in the bank away from Camp | **Yes, but not move items** (Claude). The player can plan what to fetch. |

## 2. Rules
1. The save holds a bank: each kind of item with its count, as the bag does.
2. At a location with a bank, the player can **store** an item: a count of it moves from the bag to the bank.
3. At a location with a bank, the player can **take** an item: a count of it moves from the bank to the bag.
4. A move uses no steps and no roll. It changes nothing else.
5. Away from a place with a bank, the game refuses a move.
6. A move of more than the bag or the bank holds is refused.
7. A craft or a cook at a location with a bank:
   - It counts the inputs in the bag and the bank together.
   - It takes each input from the bag first, then the rest from the bank.
   - What it makes goes into the bag.
8. A craft away from a place with a bank uses the bag only, as today.
9. The queue counts the bank for a craft or a cook that will happen at a place with a bank. A craft queued at Camp
   then starts when the bag and the bank hold its inputs.
10. Whatever counts what the player owns counts the bank too (decision 6). Owning an item in the bank counts as
    owning it.

## 3. Screens
### 3.1 The way to the bank
11. At Camp, the Now screen's "Here" part shows a card **Bank** with a button **Open bank**.
12. The Character tab shows a button **Bank** under the bag, everywhere.
13. Both open the bank screen. It slides in, like the Journal, and a swipe back closes it.

### 3.2 The bank screen
14. The title is "Bank".
15. The screen has two tabs: **Bag** and **Bank**. Each lists its items with their counts, in the order of the bag on
    the Character tab.
16. Away from Camp, a line under the tabs reads "Items move only at Camp." The Store and Take buttons do not show.
17. At Camp, a tap on an item in the Bag tab opens a sheet with:
    - the item's name and count
    - **Store all**
    - **Store some…**, which asks "How many?" (the dialog of #115)
18. At Camp, a tap on an item in the Bank tab opens the same sheet with **Take all** and **Take some…**.
19. Gear in both tabs shows in the colour of its quality, as on the item card.
20. An empty Bank tab reads "The bank is empty."

### 3.3 Crafting and cooking at Camp
21. At Camp, the "have" count of each recipe input counts the bag and the bank together.
22. At Camp, the filter "Have the materials" on a profession screen counts the bag and the bank.

## 4. Save
23. Save schema 16 (`GameState.schemaVersion`). A new field `bank`: a map of item keys to counts.
24. A save from before schema 16 loads with an empty bank.
25. Every save fixture in `app/test/fixtures/saves/` loads.

## 5. Balance
The bank adds no steps and no items. The sim walker does not use the bank. The pacing test stays green.

## 6. Out of scope
- The bag limit and the overloaded rule (a later spec of intent 0020).
- The "Bigger bag" talent (with the bag limit).
- Banks in other places.
- A button that stores all materials at once.

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
14. Gear in the bank counts as owned for the next goal.
15. Eat, wear and salvage refuse an item that is only in the bank.

**Screens**
16. At Camp, Now shows the Bank card with Open bank.
17. The Character tab shows Bank everywhere.
18. The bank screen has the tabs Bag and Bank with their items and counts.
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
32. `releases/next.md` has a line for players about the bank.
