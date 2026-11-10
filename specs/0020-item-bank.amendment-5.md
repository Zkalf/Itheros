# Spec 0020 amendment 5: the bank in one tap, and Store all materials

Status: accepted
Amends: [spec 0020](0020-item-bank.md) §3.1 (the way to the bank), §3.2 (the bank screen) and §6 (out of scope: "A
button that stores all materials at once")
Issue: #249
Product owner: Zkalf (chose on 2026-11-10: the two old ways to the bank stay; Store all materials does not ask first; accepted on 2026-11-10)
Date: 2026-11-10

## Why
- The supply chest, Achievements, the Journal and Settings are one tap from any tab. The bank is not:
  - At Camp the player scrolls Now past six teachers, the trainer and the forge to reach **Open bank**.
  - Elsewhere the player opens Character and scrolls to the end of the bag to reach **Bank**.
- Storing is one kind at a time: a tap on the item, then **Store all**. Ten kinds of loot take twenty taps.

## Change
**The Bank button in the top bar**
1. The plate in the top bar gets a fifth button, **Bank**, at its left end: Bank, Supply chest, Achievements, Journal,
   Settings.
2. It shows the bank icon of the Bank row on Now. Its tooltip is "Bank".
3. A tap opens the bank screen from any of the four tabs, at Camp and away from it.
4. During the camp tour the button does nothing, as the other four.

**Store all materials**
5. At Camp, the Bag tab of the bank screen shows a button **Store all materials** under the bag spaces line.
6. A tap moves every item of the kind Materials (amendment 2 rule 1) from the bag to the bank: the whole stack of
   each. It does not ask first.
7. Gear, tools and meals stay in the bag.
8. The move is one player action: it syncs first and goes through the one queue of `GameController`. It uses no
   steps and no roll.
9. After the move a short note reads "Stored 6 kinds of material.", with the count of kinds. For one kind it reads
   "Stored 1 kind of material."
10. The button does not show:
    - away from Camp;
    - when the bag holds no material.
11. The button stores every material in the bag, whatever kind button, search and sort the list shows.

**What stays**
12. The Bank row on Now at Camp and the Bank button under the bag on Character stay.
13. The bank screen, its tabs, its lists and its cards stay as they are. Store, Take and Destroy do not change.
14. No number or save field changes. This does not move the pace, so it has no sim targets.

## Acceptance criteria
**The Bank button in the top bar**
1. The top bar shows five buttons in this order: Bank, Supply chest, Achievements, Journal, Settings.
2. A tap on Bank opens the bank screen from each of the four tabs.
3. Away from Camp, a tap on Bank opens the bank screen with "Items move only at Camp."
4. During the camp tour a tap on Bank does nothing.
5. At 408 dp wide the five buttons stand in one row and no button is cut off.

**Store all materials**
6. At Camp, the Bag tab shows Store all materials when the bag holds a material.
7. A tap moves the whole stack of every material from the bag to the bank.
8. Gear, a tool and a meal stay in the bag after the tap.
9. The tap opens no dialog.
10. A note reads "Stored 2 kinds of material." after two kinds moved, and "Stored 1 kind of material." after one.
11. With the kind button Gear picked, the tap still stores every material.
12. Away from Camp, the Bag tab shows no Store all materials.
13. With no material in the bag, the Bag tab shows no Store all materials.
14. The Bank tab shows no Store all materials.
15. The rule refuses the move away from a place with a bank.
16. The move uses no steps and no roll.

**What stays**
17. Now at Camp still shows the Bank row with Open bank, and Character still shows Bank under the bag.

**Check and release**
18. Numbers and the save do not change. The pacing test passes.
19. The top bar and the Bag tab are rendered at 408 dp wide before the PR (`CLAUDE.md`).
20. `releases/next/` has a line for players.
21. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
