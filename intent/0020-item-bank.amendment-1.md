# Intent 0020 amendment 1: no overload at the bank

Status: accepted
Amends: [intent 0020](0020-item-bank.md) decision 3 (the downside: "every action (a fight round, a gathered item, a
craft, a travel leg)")
Issue: #173
Product owner: Zkalf (chose on 2026-11-02, at the spec stage of the bag limit: crafts and rerolls at Camp cost no more
when the bag is over its limit)
Date: 2026-11-02

## Why
- At Camp, the player can end the overload at any moment: a store in the bank is free.
- A higher cost there gives no choice. It only makes the player store items first, then craft.
- The limit is there for the walk out in the world. Loot fills the bag there, and the player asks "Do I go back to
  Camp, or do I keep going?"
- A reroll in the queue could cost more steps than the player planned, after a take from the bank fills the bag.

## Change
1. **Crafts, cooks and rerolls at a place with a bank** cost their normal steps, also when the player is overloaded.
2. Every other action still costs more when the player is overloaded:
   - a fight round
   - a gathered item
   - a travel leg, also the walk out of Camp
   - a craft, a cook or a reroll at a place without a bank (Grey Moor, Mountain Pass)
3. The rate stays as decision 3 says: +5% for each space over the limit, up to +50%.
4. Everything else in intent 0020 stays as it is.

## What it means for the specs
- Spec 0021 (draft) takes this change in its rules. No accepted spec changes.
