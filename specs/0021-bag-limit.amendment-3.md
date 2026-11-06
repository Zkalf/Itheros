# Spec 0021 amendment 3: "Until the bag is full"

Status: accepted
Amends: spec 0016 (the stop conditions), in the light of [spec 0021](0021-bag-limit.md) (the bag limit)
Issue: #224
Product owner: Zkalf (chose on 2026-11-06: the stop comes when all spaces are used, 40/40; the overload stays on
walks as today)
Date: 2026-11-06

## Why
- With the bag limit, an action that runs on and on fills the bag, and then the overload makes every unit cost more.
- The player wants to fight or gather until the bag is full, then walk to the bank at Camp or destroy what they do
  not want (#180), before any overload.

## Change
1. Fights and gathering get a new stop condition, **Until the bag is full**, on the action sheet beside the others.
2. The action stops when a unit leaves no free space in the bag: all its spaces used, for example 40 kinds of item in
   a bag of 40. So an action with this stop never takes the bag over its spaces by itself.
3. While a free space is left, loot that only adds to a stack the bag already holds changes nothing, and the action
   goes on.
4. An action with this stop that would start with no free space left is refused, as "Until I have N" is when the
   player already has N: "Your bag is already full".
5. On the queue card its stop line reads "Until the bag is full".
6. Crafts, cooks, rerolls and walks do not offer it.

**What stays**
7. The bag's spaces, the overload and its numbers, and the Bigger bag talent do not change. A walk pays the overload
   as today (spec 0021 rule 6).
8. The sim walker does not use the new stop. This does not move the pace, so it has no sim targets; the pacing test
   is the guard.

## Acceptance criteria
**The sheet**
1. The action sheet of a fight shows the stop "Until the bag is full".
2. The action sheet of a gather shows it too.
3. The action sheet of a craft does not show it.

**The stop**
4. A gather with this stop and one free space left stops at the unit that brings a new kind of item into the bag.
5. A gather with this stop goes on while its catch only adds to a stack in the bag.
6. A fight with this stop stops at the fight whose loot uses the last free space.
7. With no free space left, an action with this stop is refused with "Your bag is already full".
8. The queue card shows "Until the bag is full" under the action.
9. A save with this stop in its queue loads and keeps it.

**Check and release**
10. The pacing test passes.
11. The action sheet is rendered at 408 dp wide before the PR (`CLAUDE.md`).
12. `releases/next/` has a line for players.
13. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
