# Spec 0021 amendment 4: a stack limit for each kind of item

Status: accepted
Amends: [spec 0021](0021-bag-limit.md) §1 decision 1, §2.1 rule 2 (what takes a space), §3.1 (the bag on the
Character tab), §3.2 point 16 (the Overloaded sheet); [amendment 3](0021-bag-limit.amendment-3.md) rule 3 ("Until the
bag is full")
Issue: #228
Product owner: Zkalf (chose on 2026-11-09, accepted on 2026-11-09: stacks of 100 for materials, 20 for meals, 1 for gear and tools; the bag
only, not the bank; one square for each stack)
Date: 2026-11-09

## Why
- The bag limit counts kinds of item, not amounts. One space holds 5 copper ore or 5,000.
- So a player who gathers one material for weeks never feels the limit.

## Change
**The rule**
1. Each kind of item has a **stack size**: the most of it that one bag space holds. The sizes are in
   `economy.json`, `bag.stacks`: materials 100, meals 20, gear 1, tools 1. The kind is the kind of the bag's filter
   chips (spec 0020 amendment 2).
2. An item in the bag uses one space for each stack size, or part of one: 100 copper ore use 1 space, 101 use 2,
   237 use 3. This replaces rule 2 of spec 0021 ("one space for each key").
3. Gear keeps one space for each piece, as today: each roll is its own item, and two pieces with the same roll now use
   two spaces.
4. The bank has no stack limit. It has no spaces, as today.
5. "Until the bag is full" (amendment 3) stops when a unit leaves no free space, as today. A gain that fills a stack
   and starts a new one uses a new space, so it can end the action. This replaces rule 3 of amendment 3: loot changes
   nothing only while it fits in a stack the bag already holds.

**The screens**
6. The bag grid on the Character tab shows one square for each stack. 237 copper ore show as three squares: 100, 100
   and 37. Full stacks come first.
7. Each square of an item opens the same item card, with the whole count.
8. The squares of one item stay together, in the place of today's one square. The filter chips, the search and the
   sorts (spec 0020 amendment 4) work as today; Count sorts by the whole count.
9. The item card of a material or a meal says "Up to 100 in a bag space." (20 for a meal).
10. The Overloaded sheet says "Your bag uses 43 spaces. It has 40." and "Each space over adds 5% to the steps of your
    actions, up to 50%." Its other lines stay.

**What stays**
11. The bag's 40 spaces, the overload and its numbers, Bigger bag, the bank, destroy and the "Spaces 32 / 40" line
    (it now counts stacks).
12. The bank screen keeps one row for each item, with the whole count, in both tabs.
13. No save change. An old save loads with its items as they are. If it holds big stacks, it can load overloaded, as
    spec 0021 point 21 allows. Nothing is lost.

**The sim walker**
14. It counts spaces by the new rule: when it decides to go to the bank, and before it takes items from the bank.

## Balance
`tool/bag.dart`, 16 seeds, 120 days, 5,000 steps a day, `main` at 44e3e0f and with rule 2 (a throwaway run):

| | Mixed today | Mixed with stacks | Fighter today | Fighter with stacks |
|---|---|---|---|---|
| Level 30, median day | 86 | 90.5 | 81 | 84 |
| Steps walked overloaded, median | 1.1% | 5.4% | 0.0% | 3.2% |
| Days that stored in the bank, per seed | 2-5 | 7-10 | 0 | 2-5 |
| Gap between those days, median | 16.5 days | 10 days | - | 31.5 days |

- The mixed walker reaches level 30 4.5 days later; the fighter 3 days later.
- It banks about twice as often, every 10 days: still "now and then, not every day" (intent 0020).
- The pacing test's ranges hold: mixed seed 1 reaches level 30 on day 91 (spec 0021 amendment 1: within 5% of day
  91), and the fighter's median of 84 is inside 70-100 (spec 0010 amendment 11).

## Acceptance criteria
**The rule**
1. `economy.json` has `bag.stacks` with material 100, meal 20, gear 1 and tool 1.
2. 100 copper ore use 1 space, 101 use 2, 237 use 3.
3. 21 of one meal use 2 spaces.
4. Two pieces of gear with the same roll use 2 spaces.
5. Items in the bank use no space, in any amount.
6. A bag of 39 spaces used, with 100 copper ore in it, is full after one more copper ore, and a gather with "Until the
   bag is full" stops at that ore.
7. A gather with "Until the bag is full" goes on while its catch fits in a stack the bag holds.
8. A save with more than 100 of a material loads with all its items, its spaces counted by the new rule.

**The screens**
9. 237 copper ore show as three squares in the bag grid: 100, 100 and 37, side by side.
10. A tap on any of them opens the card of copper ore with the count 237.
11. Sorted by Count, the item with the biggest whole count comes first, all its squares together.
12. The card of copper ore says "Up to 100 in a bag space."; the card of a meal says 20; the card of gear says
    neither.
13. The Overloaded sheet says "Your bag uses N spaces. It has M." and "Each space over adds".
14. The bank screen shows one row for copper ore with ×237, in the Bag tab and in the Bank tab.

**Check and release**
15. The sim walker counts spaces by the new rule (change 14).
16. The owner accepts the numbers of the Balance section, or the pacing test passes with them.
17. The bag grid with split stacks and the item card are rendered at 408 dp wide before the PR (`CLAUDE.md`).
18. `releases/next/` has a line for players.
19. `.\scripts\check.ps1 -Release -Pacing` is green, and the release build declares no INTERNET permission.
