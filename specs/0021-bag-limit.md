# Spec 0021: the bag limit

Status: accepted
Intent: [intent/0020-item-bank.md](../intent/0020-item-bank.md) (accepted, 2026-11-02)
Issue: #173
Builds on: spec 0020 (the item bank), spec 0015 (talents, the Utility tree), spec 0010 §3.2 (tool steps), spec 0011
§5.3 (meal steps), spec 0003 (the queue), spec 0016 (the stop conditions), spec 0014 (the look)
Product owner: Zkalf
Date: 2026-11-02

The bag gets 40 spaces. Each stack of an item in the bag takes one space: up to 100 of a material, 20 of a meal, and
one piece of gear or one tool. The player can carry more, and nothing is lost. A bag over its spaces makes the
player **overloaded**: actions out in the world cost more steps. Crafts, cooks and rerolls at Camp, where the bank
is, cost their normal steps. The player stores items in the bank at Camp, or salvages, eats, uses or destroys them. A
new Utility talent, "Bigger bag", gives more spaces. This is the second build of intent 0020. Spec 0020 built the
bank.

## 1. Decisions
| # | Question | Decision |
|---|---|---|
| 1 | What takes a space | **Each stack of an item in the bag** (owner, intent 0020 decision 1; stacks since 2026-11-09). An item is one key in the bag: each piece of gear with its own roll is its own item. A stack holds up to 100 of a material, 20 of a meal, and 1 piece of gear or 1 tool. Only the bag has stacks, not the bank. Worn gear and worn tools take no space. |
| 2 | How many spaces | **40** (owner, intent 0020 decision 2). The sims of §5 back it. |
| 3 | The downside | **+5% to the steps of an action for each space over, up to +50%** (owner, intent 0020 decision 3). |
| 4 | The talent | **"Bigger bag", Utility, +2 spaces for each rank, 5 ranks** (owner, intent 0020 decision 6). |
| 5 | Which actions cost more | **Every unit of an action, but crafts, cooks and rerolls at a place with a bank** (owner, intent 0020 decision 3). At Camp, a free store in the bank ends the overload at any moment, so a higher cost there gives no choice. Fight rounds, gathered items, travel legs (also the walk out of Camp) and crafts, cooks and rerolls at the other forges and fires cost more. |
| 6 | When the cost changes | **At once:** each unit costs the steps of the bag as it is when the unit completes (Claude). The game reads the cost of the next unit with each step (`_costOf`). So when the player frees a space (a store in the bank, a salvage, a meal), the unit under way costs less at once. A store in the bank itself costs no steps (spec 0020 point 4). |
| 7 | What else takes no space | **Supply chests that are not yet open, the bank, the step bank** (Claude). They are not in the bag. |
| 8 | Where Bigger bag sits | **Utility row 1, column 2**, between Deep pockets and Nimble hands (Claude). The cell is free. Row 1 is open from the first point, so a new player can take it when the bag first fills (about day 35, §5). Its image is a bag. |
| 9 | Swift strikes | **Gives back its share of the base round** (Claude). The overload is not given back. |
| 10 | Destroy | **Every item in the bag or the bank, from both, anywhere. Always ask first. No trader for now** (owner, 2026-11-06). |
| 11 | "Until the bag is full" | **The stop comes when all spaces are used, 40/40. A walk pays the overload as before** (owner, 2026-11-06). |
| 12 | How the bag shows stacks | **One square for each stack** (owner, 2026-11-09). |

## 2. Rules
### 2.1 Spaces
1. The bag's **spaces** are `bag.spaces` in `economy.json` (40), plus `value` (2) for each rank of Bigger bag.
42. Each kind of item (spec 0020 point 26) has a **stack size**: the most of it that one bag space holds. The sizes
    are in `economy.json`, `bag.stacks`: materials 100, meals 20, gear 1, tools 1.
2. An item in the bag uses one space for each stack size, or part of one: 100 copper ore use 1 space, 101 use 2, 237
   use 3.
43. Each piece of gear uses one space: each roll is its own item, and two pieces with the same roll use two spaces.
44. The bank has no stack limit. It has no spaces.
3. The player is **overloaded** when the bag uses more spaces than it has.
4. Every item still goes into the bag when the bag is full: loot, gathered items, crafts, cooks, supply chests,
   takes from the bank and gear that the player takes off. No rule refuses an item for a full bag.

### 2.2 The step cost
5. The **overload** is `bag.overloadStep` (0.05) for each space over, at most `bag.overloadMax` (0.5), both in
   `economy.json`. A bag that is not over its spaces has an overload of 0.
6. Each unit of an action costs its steps without the overload times (1 + overload), rounded up once at the end.
   The exception is rule 7.
   | Unit | Steps |
   |---|---|
   | A fight round | `combatRoundSteps` × (1 + overload) |
   | A gathered item, a craft, a cook | base × tool × meal × Nimble hands × (1 + overload) |
   | A reroll | `rerollSteps` × meal × (1 + overload) |
   | A travel leg | road steps × Light pack and Wayfarer × (1 + overload) |
7. A craft, a cook or a reroll at a place with a bank (`LocationDef.itemBank`) costs its steps without the overload
   (decision 5).
8. Swift strikes gives back its share of `combatRoundSteps` for each round (decision 9).
9. Each unit reads the bag when it completes (decision 6).
10. Every place that shows the steps of a unit, or counts with them, uses the same cost (`unitCost`): the queue, the
    action sheet and the step estimates.

### 2.3 The talent
11. `talents.json` has a talent `bigger_bag`: tree `utility`, row 1, column 2, 5 ranks, name "Bigger bag", line
    "More bag spaces.", effect `bagSpaces`, value 2, image `bag`.
12. A reset of the talents (spec 0015 §2.6) takes its ranks back like any other. The bag can then be over its spaces.
    Nothing is lost.

### 2.4 Destroy
24. The player can destroy any item in the bag or in the bank. The items are gone for good.
25. A destroy takes a count, from 1 to the whole stack.
26. A destroy works anywhere. It needs no forge, no bank and no steps.
27. A destroy gives nothing back: no dust, no shard, no steps and no XP.
28. Worn gear and the tool in use are not in the bag, so the player cannot destroy them.
29. A destroy goes through the one queue of `GameController`, and it syncs first, like every player action.
30. A waiting action that needs the destroyed items finds them missing, as after any other loss of items (the skip
    rules of spec 0016).

### 2.5 "Until the bag is full"
36. Fights and gathering have a stop condition **Until the bag is full**, on the action sheet beside the others
    (spec 0016).
37. The action stops when a unit leaves no free space in the bag: all its spaces used, for example 40 spaces used in a
    bag of 40. So an action with this stop never takes the bag over its spaces by itself.
38. While a free space is left, loot that fits in a stack the bag already holds changes nothing, and the action goes
    on. A gain that fills a stack and starts a new one uses a new space, so it can end the action.
39. An action with this stop that would start with no free space left is refused, as "Until I have N" is when the
    player already has N: "Your bag is already full".
40. On the queue card its stop line reads "Until the bag is full".
41. Crafts, cooks, rerolls and walks do not offer it. A walk pays the overload (rule 6).

## 3. Screens
### 3.1 The bag on the Character tab
13. The Bag pane shows a line above the grid: "Spaces 32 / 40". The first number is the spaces used (the stacks),
    the second the bag's spaces.
14. When the player is overloaded, the line reads "Spaces 43 / 40 · Overloaded +15% steps", in the colour
    `Quiet.risky`.
45. The bag grid shows one square for each stack. 237 copper ore show as three squares: 100, 100 and 37. Full stacks
    come first.
46. Each square of an item opens the same item card, with the whole count.
47. The squares of one item stay together, in the place of the item's one square. The kind chips, the search and the
    sorts (spec 0020 §3.4 and §3.6) work on them; Count sorts by the whole count.
48. The item card of a material or a meal says "Up to 100 in a bag space." (20 for a meal).

### 3.2 Now
15. When the player is overloaded, the status card shows a line under "Walked today": a bag icon and "Overloaded:
    +15% steps", in `Quiet.risky`.
16. A tap on the line opens a sheet:
    - Title: "Overloaded"
    - "Your bag uses 43 spaces. It has 40."
    - "Each space over adds 5% to the steps of your actions, up to 50%."
    - "At Camp, crafts and rerolls cost no more."
    - "Store items in the bank at Camp, or salvage, eat or use them."
17. The line does not show when the player is not overloaded.

### 3.3 The bank screen
18. The Bag tab of the bank screen shows the line of point 13 and point 14 above its list.
49. The bank screen keeps one row for each item, with the whole count, in both tabs.

### 3.4 The talent
19. Bigger bag shows on the Utility grid at row 1, column 2, with the bag icon (`Icons.backpack`).
20. Its card says "More bag spaces." and, for each rank, "+2 bag spaces".

### 3.5 Destroy
31. The item card from the bag shows a button **Destroy** after its other buttons.
32. The card of an item on the bank screen shows **Destroy** too: in the Bag tab it destroys from the bag, in the Bank
    tab from the bank. Away from Camp, the card shows Destroy but no Store or Take.
33. For a stack of 2 or more, Destroy first asks "How many?" (the dialog of #115), filled with the whole stack.
34. Then a dialog always asks: "Destroy 12 Goblin bones?" with the line "They are gone for good." and the buttons
    **Keep them** and **Destroy**. For one item: "Destroy the Bone sword?", "It is gone for good." and **Keep it**.
35. After a destroy, a message says "Destroyed 12 Goblin bones." It replaces the message on screen, as salvage
    messages do (#176).

The numbers in the lines of points 13-16 follow the state: "43", "40" and "15%" are examples.

## 4. Save
The spaces come from the data and the talent ranks, which the save holds. The save version stays 16.
21. A save that uses more spaces than the bag has loads overloaded, with all its items (intent 0020 constraint). A
    save from before the stacks loads with its items as they are; big stacks can make it load overloaded. Nothing is
    lost.

## 5. Balance
### 5.1 How fast the bag fills
`tool/bag.dart` (new) runs the walker of 2026-11-02 for 120 days at 5,000 steps a day on seeds 1-16. It counts the
kinds in the bag, as point 2 did before the stacks. That walker never banks.

| Day | Mixed walker: kinds (median, min-max) | Fighter | Gatherer |
|---|---|---|---|
| 7 | 17 (13-21) | 9 | 15 |
| 14 | 22.5 (20-25) | 12 | 19.5 |
| 30 | 30.5 (26-36) | 19 | 34 |
| 45 | 41.5 (39-46) | 27 | 46.5 |
| 60 | 45.5 (42-51) | 37 | 54 |
| 90 | 61.5 (51-67) | 46 | 56 |
| 120 | 69.5 (66-76) | 54 | 56.5 |

- The mixed walker first goes over 40 on day 34-47 (median 38). The gatherer goes over on day 32-44. The fighter goes
  over on day 39-111.
- Materials take most of the spaces: 44.5 of the mixed walker's 69.5 kinds on day 120. Monster drops (bones, hides,
  scales) pile up. The walker salvages its spare gear at a forge, so gear takes 3-15 kinds.
- The six teacher's tools stay in the bag once better tools replace them: 6 spaces. They cannot be salvaged. They can
  go into the bank, and since amendment 2 the player can destroy them.
- A walker that never banks would walk 62-71% of its steps overloaded after day 38. That costs about 17-22% of its
  steps (an estimate: the sim did not apply the rule yet).

### 5.2 A walker that banks
A first walker that banks, in `tool/bag.dart`: when it holds more than 40 kinds, it walks to Camp. At Camp it stores
every material (the fighter: also its gear that it does not wear).

| Walker | Visits that stored, in 120 days | Steps walked overloaded | Level 30 (median day) |
|---|---|---|---|
| Mixed, never banks | 0 | 62-71% | 84 (before spec 0021) |
| Mixed, banks | 3-6 | 1-2% | 93 |
| Fighter, never banks | 0 | 8-68% | 104.5 (before spec 0021) |
| Fighter, banks | 1-3 | 0-1% | 104.5 |
| Gatherer, never banks | 0 | 63-74% | - (it never fights) |
| Gatherer, banks | 3-8 | 0-1% | - (it never fights) |

- The first bank visit comes about day 35-45. After it, the mixed walker banks every 2-4 weeks. That matches the
  intent: "now and then, not every day".
- The mixed walker that banks reaches level 30 nine days late. The cause is a habit of the walker, not the rule: it
  crafts at the nearest forge (Grey Moor, Mountain Pass), but its materials wait in the bank at Camp. Spec 0020 point
  8 says a craft away from Camp uses the bag only.

### 5.3 The sim walker and the targets
22. The walker banks when it is overloaded (intent 0020):
    - It walks to Camp when its bag uses more spaces than it has, and the stores of the next point would end the
      overload.
    - At Camp, it stores every material, and the gear that it neither wears nor keeps (spec 0010 §9.2 keeps the best
      of each weapon group and off hand).
    - It crafts at Camp when the inputs of a craft are in the bank.
    - It takes no Bigger bag ranks (its talent order stays as it was).
    - It counts spaces by point 2: when it decides to go to the bank, and before it takes items from the bank.
23. The pacing simulation applies the overloaded rule.

| # | Target (16 seeds, 120 days, 5,000 steps a day) | Before spec 0021 |
|---|---|---|
| 1 | Mixed walker: the median day of level 30 is at most 3 days later than before. | 84 |
| 2 | Fighter: the median day of level 30 is at most 3 days later than before. | 104.5 |
| 3 | Mixed walker: at most 5% of its steps are walked overloaded. | - |
| 4 | Mixed walker: the median gap between bank visits that store is 7 days or more. | - |
| 5 | The pacing test of `check.ps1` stays green. | green |

If a target fails, Claude reports the numbers to the owner before any tuning.

**The result (2026-11-02).** With the bag limit, the mixed walker reaches level 30 on day 91.5 (median of 16
seeds), not day 84. The owner accepted day 91 (criterion 41). The fighter's days spread from 84 to 116, so one seed,
or 8, says little:

| Fighter | Mixed | Gap |
|---|---|---|
| 16 seeds, median 105.5 | 16 seeds, median 91.5 | 15.3% |
| 8 seeds, median 97 | 8 seeds, median 92 | 5.4% |
| seed 1, day 96 | 8 seeds, median 92 | 4% |

**The pacing test.** The pacing test runs the fighter on seeds 1-8, as the mixed walker. A fighter seed that does
not reach level 30 in 120 days counts as day 121. Its median day of level 30 is in 80-120 (spec 0010 §9.3 target 3).
Seed 1 has no pinned days (spec 0017 §8).

### 5.4 The stacks
`tool/bag.dart`, 16 seeds, 120 days, 5,000 steps a day, `main` at 44e3e0f and with point 2 (a throwaway run):

| | Mixed, one space for each key | Mixed with stacks | Fighter, one space for each key | Fighter with stacks |
|---|---|---|---|---|
| Level 30, median day | 86 | 90.5 | 81 | 84 |
| Steps walked overloaded, median | 1.1% | 5.4% | 0.0% | 3.2% |
| Days that stored in the bank, per seed | 2-5 | 7-10 | 0 | 2-5 |
| Gap between those days, median | 16.5 days | 10 days | - | 31.5 days |

- The mixed walker reaches level 30 4.5 days later; the fighter 3 days later.
- It banks about twice as often, every 10 days: still "now and then, not every day" (intent 0020).
- The pacing test's ranges held on 2026-11-09: mixed seed 1 reached level 30 on day 91, and the fighter's median of
  84 was inside the fighter's range of that day (70-100; 80-120 since spec 0002 amendment 3).

## 6. Out of scope
- A warning before an action or a loot puts the bag over.
- Bigger bag ranks for the sim walker.
- Banks in other places.
- A trader that buys items (decision 10).

## 7. Acceptance criteria
**Spaces**
1. A bag with 40 kinds and 40 spaces is not overloaded.
2. A bag with 41 kinds and 40 spaces is overloaded.
3. A kind with a count of 40 uses one space.
4. Two pieces of the same gear with different rolls use two spaces.
5. Worn gear and worn tools use no space.
6. Items in the bank use no space.
7. An unopened supply chest uses no space.
8. The bag's spaces come from `bag.spaces` in `economy.json`.

**Nothing is lost**
9. Loot goes into a bag that is over its spaces.
10. A craft and a cook put their item into a bag that is over its spaces.
11. A supply chest opens into a bag that is over its spaces.
12. A take from the bank works when the bag is over its spaces.

**The step cost**
13. A bag 3 spaces over makes a fight round cost `combatRoundSteps` × 1.15, rounded up.
14. A bag 3 spaces over makes a gathered item cost its steps without the overload × 1.15, rounded up.
15. A bag 3 spaces over makes a craft at Grey Moor cost its steps without the overload × 1.15, rounded up.
16. A bag 3 spaces over makes a reroll at Grey Moor cost its steps without the overload × 1.15, rounded up.
17. A bag 3 spaces over makes a travel leg cost its steps without the overload × 1.15, rounded up.
18. A bag 3 spaces over makes the travel leg out of Camp cost its steps without the overload × 1.15, rounded up.
19. A bag 3 spaces over leaves a craft at Camp at its steps without the overload.
20. A bag 3 spaces over leaves a cook at Camp at its steps without the overload.
21. A bag 3 spaces over leaves a reroll at Camp at its steps without the overload.
22. A bag 10 spaces over and a bag 20 spaces over both add 50%.
23. A bag that is not over its spaces costs its steps without the overload.
24. A store in the bank that ends the overload lowers the cost of the next unit.
25. Swift strikes gives back the same steps with and without the overload.
26. `unitCost` includes the overload.

**The talent**
27. `talents.json` has Bigger bag in Utility row 1, column 2, with 5 ranks.
28. Each rank of Bigger bag adds 2 spaces.
29. A reset of the talents removes the spaces of Bigger bag and keeps every item.

**Screens**
30. The Bag pane shows "Spaces N / M".
31. An overloaded Bag pane shows "Overloaded +P% steps" in `Quiet.risky`.
32. An overloaded player sees the Overloaded line on Now.
33. A player who is not overloaded sees no Overloaded line on Now.
34. A tap on the Overloaded line opens the sheet with its title and four lines.
35. The Bag tab of the bank screen shows the spaces line.
36. Bigger bag shows on the Utility grid at row 1, column 2, with the bag icon.

**Save**
37. The save version stays 16.
38. A save with more kinds than 40 loads overloaded, with all its items.
39. Every save fixture loads.

**Balance**
40. The sim walker banks when it is overloaded, as point 22 says.
41. Targets 1-4 of §5.3 hold, or the owner accepts the numbers.

**Check and release**
42. Rules, numbers and the save change only as this spec says. The pacing test passes.
43. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
44. `releases/next.md` has a line for players about the bag limit and Bigger bag. Each later change adds its own line
    in `releases/next/`.

**Destroy: the rule**
45. A destroy of 3 of a stack of 12 leaves 9.
46. A destroy of the whole stack removes the item, and its bag space is free.
47. A destroy from the bank removes the items from the bank, not from the bag.
48. A destroy away from Camp works.
49. A destroy gives no dust, no shard, no steps and no XP.
50. A destroy of more than the stack holds, or of an item that is not there, is refused.
51. A destroy syncs first: steps walked before it go to the current action.

**Destroy: the screens**
52. The item card from the bag shows Destroy.
53. The card of a worn item (from the doll) shows no Destroy.
54. The card of a Bag tab item on the bank screen shows Destroy, and it destroys from the bag.
55. The card of a Bank tab item on the bank screen shows Destroy, and it destroys from the bank.
56. Away from Camp, a bank screen card shows Destroy and no Store or Take.
57. For a stack, Destroy asks "How many?" with the whole stack filled in.
58. The confirm dialog names the count and the item, and Keep them leaves the items.
59. Destroy in the confirm dialog removes the items and shows "Destroyed N <items>.".
60. The item card and the confirm dialog are rendered at 408 dp wide before the PR (`CLAUDE.md`).

**"Until the bag is full": the sheet**
61. The action sheet of a fight shows the stop "Until the bag is full".
62. The action sheet of a gather shows it too.
63. The action sheet of a craft does not show it.

**"Until the bag is full": the stop**
64. A gather with this stop and one free space left stops at the unit that brings a new kind of item into the bag.
65. A gather with this stop goes on while its catch only adds to a stack in the bag.
66. A fight with this stop stops at the fight whose loot uses the last free space.
67. With no free space left, an action with this stop is refused with "Your bag is already full".
68. The queue card shows "Until the bag is full" under the action.
69. A save with this stop in its queue loads and keeps it.
70. The action sheet is rendered at 408 dp wide before the PR (`CLAUDE.md`).

**Stacks: the rule**
71. `economy.json` has `bag.stacks` with material 100, meal 20, gear 1 and tool 1.
72. 100 copper ore use 1 space, 101 use 2, 237 use 3.
73. 21 of one meal use 2 spaces.
74. Two pieces of gear with the same roll use 2 spaces.
75. Items in the bank use no space, in any amount.
76. A bag of 39 spaces used, with 100 copper ore in it, is full after one more copper ore, and a gather with "Until
    the bag is full" stops at that ore.
77. A gather with "Until the bag is full" goes on while its catch fits in a stack the bag holds.
78. A save with more than 100 of a material loads with all its items, its spaces counted by point 2.

**Stacks: the screens**
79. 237 copper ore show as three squares in the bag grid: 100, 100 and 37, side by side.
80. A tap on any of them opens the card of copper ore with the count 237.
81. Sorted by Count, the item with the biggest whole count comes first, all its squares together.
82. The card of copper ore says "Up to 100 in a bag space."; the card of a meal says 20; the card of gear says
    neither.
83. The Overloaded sheet says "Your bag uses N spaces. It has M." and "Each space over adds".
84. The bank screen shows one row for copper ore with ×237, in the Bag tab and in the Bank tab.

**Stacks: the balance**
85. The sim walker counts spaces by point 2.
86. The owner accepts the numbers of §5.4, or the pacing test passes with them.
87. The bag grid with split stacks and the item card are rendered at 408 dp wide before the PR (`CLAUDE.md`).

## History
- 2026-11-02: first version (intent 0020 and its amendment 1, plan 0041, #173). Criteria 1-44.
- 2026-11-02, amendment 1 (#173, plan 0041): the pacing test with the bag limit; the owner accepted day 91 for level
  30; the fighter on 8 seeds. §5.3. Its three criteria ended later: the day of seed 1 with spec 0017 amendment 4, the
  fighter against the mixed walker with spec 0010 amendment 11.
- 2026-11-02, spec 0017 amendment 4 (#173): no pinned days for seed 1; amendment 1's day 91 ended with it. §5.3.
- 2026-11-06, spec 0020 amendment 2 (#197, #109): the kinds of item and their chips; "Bag categories" left the out
  of scope list. §6.
- 2026-11-06, amendment 2 (#180): destroy an item. Decision 10; points 24-35; §2.4; §3.5; §5.1; §6; criteria 45-60.
- 2026-11-06, amendment 3 (#224): the stop "Until the bag is full". Decision 11; points 36-41; §2.5; criteria 61-70.
- 2026-11-07, spec 0010 amendment 11 (#237): the fighter's median day of level 30 is a range; it need not be later
  than the mixed walker. §5.3.
- 2026-11-09, spec 0002 amendment 3 (#234): the fighter's range is 80-120. §5.3; §5.4.
- 2026-11-09, amendment 4 (#228, plan 0056): a stack limit for each kind of item. Decisions 1 and 12; points 2, 13,
  16, 21, 22, 37-38 and 42-49; §5.4; criteria 71-87.
- 2026-11-10, spec 0020 amendment 5 (#249): Store all materials left the out of scope list. §6.
- 2026-11-15 (plan 0068): the amendments folded into this file. "Its steps of today" now reads "its steps without
  the overload". No rule, number or criterion changed.
