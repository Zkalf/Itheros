# Spec 0020 amendment 1: a reroll at Camp takes its dust from the bank too

Status: accepted
Amends: [spec 0020](0020-item-bank.md) decision 5 and rules 7-9
Issue: #181
Product owner: Zkalf (accepted on 2026-11-02)
Date: 2026-11-02

## Why
- With the bag limit (spec 0021), players store dust in the bank to free a space.
- At Camp a craft takes its materials from the bank, but a reroll says "Not enough dust" while the dust sits in the
  bank. The player has to take the dust out first.

## Change
1. **Decision 5:** crafting, cooking and rerolls at a place with a bank use the bank's items. Eat, wear, salvage and
   auto-eat still use the bag only.
2. **A reroll at a place with a bank** (rule 7 for rerolls):
   - It counts its dust in the bag and the bank together.
   - It takes the dust from the bag first, then the rest from the bank.
3. **A reroll away from a place with a bank** uses the bag only, as today (rule 8).
4. **The queue** counts the bank for a reroll that will happen at a place with a bank (rule 9).
5. No screen, save or number changes. No sim work: this does not move the pace.

## Acceptance criteria
1. At Camp, with the dust only in the bank, a reroll starts and takes its dust from the bank.
2. At Camp, with 1 dust in the bag and the rest in the bank, a reroll takes the 1 from the bag and the rest from the
   bank.
3. At Grey Moor, with the dust only in the bank, a reroll is refused with "Not enough … dust", as today.
4. A reroll queued at Camp behind another action starts when the bag and the bank hold its dust.
5. On the item card at Camp, with the dust only in the bank, Reroll adds the reroll and it runs.
6. `releases/next.md` has a line for players. `.\scripts\check.ps1 -Release` is green.
