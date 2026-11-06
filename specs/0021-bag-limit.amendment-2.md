# Spec 0021 amendment 2: destroy an item

Status: accepted
Amends: [spec 0021](0021-bag-limit.md) §6 (out of scope: "A way to destroy items (#180)"), §2.1 (spaces) and §3.1
(the bag on the Character tab); spec 0020 amendment 2 rule 20 (the card on the bank screen)
Issue: #180
Product owner: Zkalf (chose on 2026-11-06: every item in the bag or the bank; always ask first; from the bag and the
bank, anywhere; no trader for now; accepted on 2026-11-06)
Date: 2026-11-06

## Why
- The bag limit counts each kind of item. Monster drops with little use (bones, hides, scales) fill most of the
  spaces.
- Today the only way to free such a space is the bank at Camp. The bank has no limit, so it fills with junk.
- The six teacher's tools stay in the bag once better tools replace them. They cannot be salvaged.

## Change
**The rule**
1. The player can destroy any item in the bag or in the bank. The items are gone for good.
2. A destroy takes a count, from 1 to the whole stack.
3. A destroy works anywhere. It needs no forge, no bank and no steps.
4. A destroy gives nothing back: no dust, no shard, no steps and no XP.
5. Worn gear and the tool in use are not in the bag, so the player cannot destroy them.
6. A destroy goes through the one queue of `GameController`, and it syncs first, like every player action.
7. A waiting action that needs the destroyed items finds them missing, as after any other loss of items (the skip
   rules of spec 0016).

**The screens**
8. The item card from the bag shows a button **Destroy** after its other buttons.
9. The card of an item on the bank screen shows **Destroy** too: in the Bag tab it destroys from the bag, in the Bank
   tab from the bank. Away from Camp, the card shows Destroy but no Store or Take.
10. For a stack of 2 or more, Destroy first asks "How many?" (the dialog of #115), filled with the whole stack.
11. Then a dialog always asks: "Destroy 12 Goblin bones?" with the line "They are gone for good." and the buttons
    **Keep them** and **Destroy**. For one item: "Destroy the Bone sword?", "It is gone for good." and **Keep it**.
12. After a destroy, a message says "Destroyed 12 Goblin bones." It replaces the message on screen, as salvage
    messages do (#176).

**What stays**
13. The bag limit, the step cost of an overloaded bag and the bank do not change.
14. No number or save field changes. The sim walker does not destroy, so this does not move the pace and has no sim
    targets.

## Acceptance criteria
**The rule**
1. A destroy of 3 of a stack of 12 leaves 9.
2. A destroy of the whole stack removes the item, and its bag space is free.
3. A destroy from the bank removes the items from the bank, not from the bag.
4. A destroy away from Camp works.
5. A destroy gives no dust, no shard, no steps and no XP.
6. A destroy of more than the stack holds, or of an item that is not there, is refused.
7. A destroy syncs first: steps walked before it go to the current action.

**The screens**
8. The item card from the bag shows Destroy.
9. The card of a worn item (from the doll) shows no Destroy.
10. The card of a Bag tab item on the bank screen shows Destroy, and it destroys from the bag.
11. The card of a Bank tab item on the bank screen shows Destroy, and it destroys from the bank.
12. Away from Camp, a bank screen card shows Destroy and no Store or Take.
13. For a stack, Destroy asks "How many?" with the whole stack filled in.
14. The confirm dialog names the count and the item, and Keep them leaves the items.
15. Destroy in the confirm dialog removes the items and shows "Destroyed N <items>.".

**Check and release**
16. Numbers and the save do not change. The pacing test passes.
17. The item card and the confirm dialog are rendered at 408 dp wide before the PR (`CLAUDE.md`).
18. `releases/next/` has a line for players.
19. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
