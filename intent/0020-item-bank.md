# Intent: an item bank and a bag with a limit

Status: accepted
Product owner: Zkalf
Date: 2026-11-02
Issue: #66

## Problem
- The bag has no limit. The player carries every item that they find, so the game asks no choice about what to keep.
- Loot does not feel heavy. The player never asks "do I go back to Camp, or do I keep going?"
- The Utility talent tree promises "A bigger bank", but only the step bank exists.

## Proposed outcome
**The bank (built first)**
- Camp has a bank. At Camp, the player moves items from the bag to the bank and back.
- The bank keeps items safe and out of the bag.

**The bag gets a limit (built after the bank)**
- The bag has a number of spaces. Each kind of item takes one space.
- The player can carry more than the limit. Nothing is lost when the bag is full: loot, crafts and chests still go into
  the bag.
- A bag over its limit has a downside: the player is **overloaded**. Each action costs more steps while overloaded.
- The player removes the downside: they walk to Camp and move items to the bank, or they salvage, eat or use items.
- Utility talents give more bag spaces.

**The feel**
- The bag fills slowly. A player of about 5,000 steps a day goes back to Camp to bank now and then, not every day.
- Influences: the bags and the bank of World of Warcraft, and the stash of Diablo 2.

## Affected users and systems
- Every player. Android phone.
- `packages/game_core`: the bank in the save, the bag limit, the overloaded rule in the step costs, a new talent.
- `packages/game_core/data`: the bag size, the downside, the bank's place, the talent.
- `app`: a bank screen at Camp, the bag's spaces on the Character tab, an overloaded warning on Now.
- The sim walker: it banks when it is overloaded.

## Constraints
- No item is ever lost to a full bag.
- The pace for a player of about 5,000 steps a day does not move while they bank now and then. The sims check how
  fast the bag fills (spec stage).
- Old saves load. A save that holds more kinds of item than the limit loads overloaded, with all its items.
- The bank and the limit come as two builds: the bank first, then the limit (the owner, 2026-11-02).

## Decisions
The owner chose on 2026-11-02.
1. **What takes a space:** each kind of item in the bag takes one space, with any count: 40 copper ore is one space.
   Each piece of gear with its own roll is its own kind, so loot fills the bag faster than materials. Worn gear and
   worn tools take no space.
2. **The bag:** 40 spaces at the start. The sims at the spec stage check how fast a player of about 5,000 steps a
   day fills it.
3. **The downside:** each space over the limit adds 5% to the steps of every action (a fight round, a gathered item,
   a craft, a travel leg), up to +50%.
4. **The bank's place:** Camp only, in the first build. More banks in towns can come later as content.
5. **The bank's size:** no limit.
6. **The talent:** a new Utility talent, "Bigger bag": +2 spaces for each rank, 5 ranks. "Deep pockets" stays the
   talent of the step bank.
7. **Crafting and the bank:** crafting and cooking at Camp use materials from the bag and from the bank. What they
   make goes into the bag.
