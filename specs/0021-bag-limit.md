# Spec 0021: the bag limit

Status: accepted
Intent: [intent/0020-item-bank.md](../intent/0020-item-bank.md) (accepted, 2026-11-02), with
[amendment 1](../intent/0020-item-bank.amendment-1.md) (no overload at the bank)
Issue: #173
Builds on: spec 0020 (the item bank), spec 0015 (talents, the Utility tree), spec 0010 §3.2 (tool steps), spec 0011
§5.3 (meal steps), spec 0003 (the queue), spec 0014 (the look)
Overrides: nothing
Product owner: Zkalf
Date: 2026-11-02

The bag gets 40 spaces. Each kind of item in the bag takes one space. The player can carry more, and nothing is
lost. A bag over its spaces makes the player **overloaded**: actions out in the world cost more steps. Crafts, cooks
and rerolls at Camp, where the bank is, cost their normal steps. The player stores items in the bank at Camp, or
salvages, eats or uses them. A new Utility talent, "Bigger bag", gives more spaces. This is
the second build of intent 0020. Spec 0020 built the bank.

## 1. Decisions
| # | Question | Decision |
|---|---|---|
| 1 | What takes a space | **Each kind of item in the bag, with any count** (owner, intent 0020 decision 1). A kind is one key in the bag: each piece of gear with its own roll is its own kind. Worn gear and worn tools take no space. |
| 2 | How many spaces | **40** (owner, intent 0020 decision 2). The sims of §5 back it. |
| 3 | The downside | **+5% to the steps of an action for each space over, up to +50%** (owner, intent 0020 decision 3). |
| 4 | The talent | **"Bigger bag", Utility, +2 spaces for each rank, 5 ranks** (owner, intent 0020 decision 6). |
| 5 | Which actions cost more | **Every unit of an action, but crafts, cooks and rerolls at a place with a bank** (owner, intent 0020 amendment 1). At Camp, a free store in the bank ends the overload at any moment, so a higher cost there gives no choice. Fight rounds, gathered items, travel legs (also the walk out of Camp) and crafts, cooks and rerolls at the other forges and fires cost more. |
| 6 | When the cost changes | **At once:** each unit costs the steps of the bag as it is when the unit completes (Claude). The game reads the cost of the next unit with each step today (`_costOf`). So when the player frees a space (a store in the bank, a salvage, a meal), the unit under way costs less at once. A store in the bank itself costs no steps (spec 0020 rule 4). |
| 7 | What else takes no space | **Supply chests that are not yet open, the bank, the step bank** (Claude). They are not in the bag. |
| 8 | Where Bigger bag sits | **Utility row 1, column 2**, between Deep pockets and Nimble hands (Claude). The cell is free. Row 1 is open from the first point, so a new player can take it when the bag first fills (about day 35, §5). Its image is a bag. |
| 9 | Swift strikes | **Gives back its share of the base round, as today** (Claude). The overload is not given back. |

## 2. Rules
### 2.1 Spaces
1. The bag's **spaces** are `bag.spaces` in `economy.json` (40), plus `value` (2) for each rank of Bigger bag.
2. The bag **uses** one space for each key in the bag with a count of 1 or more.
3. The player is **overloaded** when the bag uses more spaces than it has.
4. Every item still goes into the bag when the bag is full: loot, gathered items, crafts, cooks, supply chests,
   takes from the bank and gear that the player takes off. No rule refuses an item for a full bag.

### 2.2 The step cost
5. The **overload** is `bag.overloadStep` (0.05) for each space over, at most `bag.overloadMax` (0.5), both in
   `economy.json`. A bag that is not over its spaces has an overload of 0.
6. Each unit of an action costs its steps of today times (1 + overload), rounded up once at the end. The
   exception is rule 7.
   | Unit | Steps |
   |---|---|
   | A fight round | `combatRoundSteps` × (1 + overload) |
   | A gathered item, a craft, a cook | base × tool × meal × Nimble hands × (1 + overload) |
   | A reroll | `rerollSteps` × meal × (1 + overload) |
   | A travel leg | road steps × Light pack and Wayfarer × (1 + overload) |
7. A craft, a cook or a reroll at a place with a bank (`LocationDef.itemBank`) costs its steps of today, with no
   overload (decision 5).
8. Swift strikes gives back its share of `combatRoundSteps` for each round, as today (decision 9).
9. Each unit reads the bag when it completes (decision 6).
10. Every place that shows the steps of a unit, or counts with them, uses the same cost (`unitCost`): the queue, the
    action sheet and the step estimates.

### 2.3 The talent
11. `talents.json` has a new talent `bigger_bag`: tree `utility`, row 1, column 2, 5 ranks, name "Bigger bag", line
    "More bag spaces.", effect `bagSpaces`, value 2, image `bag`.
12. A reset of the talents (spec 0015 §2.6) takes its ranks back like any other. The bag can then be over its spaces.
    Nothing is lost.

## 3. Screens
### 3.1 The bag on the Character tab
13. The Bag pane shows a line above the grid: "Spaces 32 / 40". The first number is the spaces used, the second the
    bag's spaces.
14. When the player is overloaded, the line reads "Spaces 43 / 40 · Overloaded +15% steps", in the colour
    `Quiet.risky`.

### 3.2 Now
15. When the player is overloaded, the status card shows a line under "Walked today": a bag icon and "Overloaded:
    +15% steps", in `Quiet.risky`.
16. A tap on the line opens a sheet:
    - Title: "Overloaded"
    - "Your bag holds 43 kinds of item. It has 40 spaces."
    - "Each kind over adds 5% to the steps of your actions, up to 50%."
    - "At Camp, crafts and rerolls cost no more."
    - "Store items in the bank at Camp, or salvage, eat or use them."
17. The line does not show when the player is not overloaded.

### 3.3 The bank screen
18. The Bag tab of the bank screen shows the line of point 13 and point 14 above its list.

### 3.4 The talent
19. Bigger bag shows on the Utility grid at row 1, column 2, with the bag icon (`Icons.backpack`).
20. Its card says "More bag spaces." and, for each rank, "+2 bag spaces".

The numbers in the lines of points 13-16 follow the state: "43", "40" and "15%" are examples.

## 4. Save
No change. The spaces come from the data and the talent ranks, which the save holds today. The save version stays 16.
21. A save that holds more kinds than the bag's spaces loads overloaded, with all its items (intent 0020 constraint).

## 5. Balance
### 5.1 How fast the bag fills
`tool/bag.dart` (new) runs today's walker for 120 days at 5,000 steps a day on seeds 1-16. It counts the kinds in
the bag, as point 2 does. Today's walker never banks.

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
  go into the bank.
- A walker that never banks would walk 62-71% of its steps overloaded after day 38. That costs about 17-22% of its
  steps (an estimate: the sim does not apply the rule yet).

### 5.2 A walker that banks
A first walker that banks, in `tool/bag.dart`: when it holds more than 40 kinds, it walks to Camp. At Camp it stores
every material (the fighter: also its gear that it does not wear).

| Walker | Visits that stored, in 120 days | Steps walked overloaded | Level 30 (median day) |
|---|---|---|---|
| Mixed, never banks | 0 | 62-71% | 84 (today) |
| Mixed, banks | 3-6 | 1-2% | 93 |
| Fighter, never banks | 0 | 8-68% | 104.5 (today) |
| Fighter, banks | 1-3 | 0-1% | 104.5 |
| Gatherer, never banks | 0 | 63-74% | - (it never fights) |
| Gatherer, banks | 3-8 | 0-1% | - (it never fights) |

- The first bank visit comes about day 35-45. After it, the mixed walker banks every 2-4 weeks. That matches the
  intent: "now and then, not every day".
- The mixed walker that banks reaches level 30 nine days late. The cause is a habit of the walker, not the rule: it
  crafts at the nearest forge (Grey Moor, Mountain Pass), but its materials wait in the bank at Camp. Spec 0020 rule 8
  says a craft away from Camp uses the bag only.

### 5.3 The sim walker and the targets
22. The walker banks when it is overloaded (intent 0020):
    - It walks to Camp when its bag holds more kinds than its spaces, and the stores of the next point would end
      the overload.
    - At Camp, it stores every material, and the gear that it neither wears nor keeps (spec 0010 §9.2 keeps the best
      of each weapon group and off hand).
    - It crafts at Camp when the inputs of a craft are in the bank.
    - It takes no Bigger bag ranks (its talent order stays as today).
23. The pacing simulation applies the overloaded rule.

| # | Target (16 seeds, 120 days, 5,000 steps a day) | Today |
|---|---|---|
| 1 | Mixed walker: the median day of level 30 is at most 3 days later than today. | 84 |
| 2 | Fighter: the median day of level 30 is at most 3 days later than today. | 104.5 |
| 3 | Mixed walker: at most 5% of its steps are walked overloaded. | - |
| 4 | Mixed walker: the median gap between bank visits that store is 7 days or more. | - |
| 5 | The pacing test of `check.ps1` stays green. | green |

If a target fails, Claude reports the numbers to the owner before any tuning.

## 6. Out of scope
- A way to destroy items (#180). The bank has no limit, so it takes what the player does not want.
- A button that stores all materials at once (spec 0020 §6).
- Bag categories (#109).
- A warning before an action or a loot puts the bag over.
- Bigger bag ranks for the sim walker.
- Banks in other places.

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
14. A bag 3 spaces over makes a gathered item cost its steps of today × 1.15, rounded up.
15. A bag 3 spaces over makes a craft at Grey Moor cost its steps of today × 1.15, rounded up.
16. A bag 3 spaces over makes a reroll at Grey Moor cost its steps of today × 1.15, rounded up.
17. A bag 3 spaces over makes a travel leg cost its steps of today × 1.15, rounded up.
18. A bag 3 spaces over makes the travel leg out of Camp cost its steps of today × 1.15, rounded up.
19. A bag 3 spaces over leaves a craft at Camp at its steps of today.
20. A bag 3 spaces over leaves a cook at Camp at its steps of today.
21. A bag 3 spaces over leaves a reroll at Camp at its steps of today.
22. A bag 10 spaces over and a bag 20 spaces over both add 50%.
23. A bag that is not over its spaces costs the steps of today.
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
44. `releases/next.md` has a line for players about the bag limit and Bigger bag.
