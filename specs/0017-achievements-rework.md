# Spec 0017: Achievements rework

Status: accepted
Intent: [intent/0017-achievements-rework.md](../intent/0017-achievements-rework.md) and
[amendment 1](../intent/0017-achievements-rework.amendment-1.md) (both accepted, PR #83)
Builds on: spec 0004 (achievements and counters), spec 0006 amendment 2 (the trophy button), spec 0016 (the queue
of 5), spec 0014 §3.1 (achievement pictures)
Overrides: the criteria of the 11 achievements in `achievements.json`; the 5 queue slots of spec 0016 §2 for a player
with Chieftain's Bane
Product owner: Zkalf
Date: 2026-10-24

The game gets 30 achievements: 10 early, 9 mid and 11 late. The 11 achievements of today stay, with new criteria.
A **milestone** comes on the way and gives a bigger step bank or an item. A **feat** costs a long grind and gives a
stat bonus or the queue slot. The game checks the achievements of each save again when it loads. A player who no
longer meets a criterion loses the achievement and its reward.

## 1. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | How many achievements? | **About 30** (owner): 10 early, 9 mid, 11 late. |
| 2 | What are they about? | Monsters and bosses, professions, loot, walking and exploring (owner). |
| 3 | The 11 of today | **They stay, with new criteria** (owner). Names, ids and pictures stay. |
| 4 | Old saves | **Checked again by the new criteria** (owner). |
| 5 | The rewards of a lost achievement | **Strict** (owner): the player loses the reward. §5 gives the rules. |
| 6 | Gear from a reward | **A fixed quality** (owner). It does not roll. |
| 7 | The queue slot | **Chieftain's Bane**, the boss of level 20 (owner: "around level 20, so you can enjoy the extra slot"). |
| 8 | Bonuses | Only feats give them. Each bonus is as big as its grind (intent amendment 1). |
| 9 | Two bonuses to one stat | They add up. |
| 10 | Reward items | Never from a monster or a spot of the criterion (intent amendment 1, outcomes 7–9). |
| 11 | The grind of a feat | The sim sets the counts, so that each feat costs about the days of §3.3. |

## 2. The achievements

The counts of the feats are a start. The sim sets the final counts (§3.3). The numbers in brackets are the kills of
the sim walker on the way to level 30 at 5,000 steps a day, without the feat.

### 2.1 Early (levels 1–10)

| # | Id | Name | Kind | Criterion | Reward |
|---|---|---|---|---|---|
| 1 | `first_steps` | First Steps | milestone | walk 10,000 steps | +250 bank cap |
| 2 | `prospector` | Prospector | milestone | gather 50 copper ore | +250 bank cap |
| 3 | `smith` | Smith | milestone | craft 20 items | Iron shield, Uncommon |
| 4 | `kings_bane` | King's Bane | milestone | kill the Graveyard King once | +500 bank cap |
| 5 | `adventurer` | Adventurer | milestone | reach level 10 | +500 bank cap |
| 6 | `angler` | Angler | milestone | reach Fishing level 10 | +250 bank cap |
| 7 | `lucky_find` | Lucky Find | milestone | find an item of Uncommon quality or better | +250 bank cap |
| 8 | `goblin_slayer_1` | Goblin Slayer I | feat | kill 1,000 Goblins (75) | +4 Attack |
| 9 | `brute_force` | Brute Force | feat | kill 2,000 Goblin Brutes (252) | +40 HP |
| 10 | `bone_collector` | Bone Collector | feat | kill 1,500 Skeletons (222) | +4 Defense |

### 2.2 Mid (levels 11–20)

| # | Id | Name | Kind | Criterion | Reward |
|---|---|---|---|---|---|
| 11 | `marathon` | Marathon | milestone | walk 100,000 steps | +500 bank cap |
| 12 | `seasoned` | Seasoned | milestone | reach level 20 | +1,000 bank cap |
| 13 | `master_smith` | Master Smith | milestone | craft 60 items | Mithril helm, Rare |
| 14 | `rare_find` | Rare Find | milestone | find an item of Rare quality or better | +500 bank cap |
| 15 | `smugglers_secret` | Smuggler's Secret | milestone | visit Smugglers' Cove | Sapphire ring, Rare |
| 16 | `chieftains_bane` | Chieftain's Bane | feat | kill the Ogre Chieftain 100 times (58) | +1 queue slot |
| 17 | `bear_hunter` | Bear Hunter | feat | kill the Old Bear 100 times (0) | +4 Crit |
| 18 | `wolf_pack` | Wolf Pack | feat | kill 3,000 Wolves (348) | +7 Attack |
| 19 | `ghost_hunter` | Ghost Hunter | feat | kill 5,000 Ghosts (740) | +4 Dodge |

### 2.3 Late (levels 21–30)

| # | Id | Name | Kind | Criterion | Reward |
|---|---|---|---|---|---|
| 20 | `travelling_salesman` | Travelling Salesman | milestone | visit 11 areas | +500 bank cap |
| 21 | `the_long_road` | The Long Road | milestone | walk 1,000,000 steps | +1,500 bank cap |
| 22 | `champion` | Champion | milestone | reach level 30 | Star diamond ring, Epic |
| 23 | `epic_find` | Epic Find | milestone | find an item of Epic quality or better | +1,000 bank cap |
| 24 | `dragonslayer` | Dragonslayer | feat | kill the Young Dragon 1,000 times (274) | +10 Attack |
| 25 | `golem_breaker` | Golem Breaker | feat | kill 5,000 Stone Golems (597) | +10 Defense |
| 26 | `troll_slayer` | Troll Slayer | feat | kill 1,000 Trolls (0) | +6 Block |
| 27 | `wyvern_hunter` | Wyvern Hunter | feat | kill 1,000 Wyverns (0) | +130 HP |
| 28 | `legendary_find` | Legendary Find | feat | find an item of Legendary quality | +6 Crit |
| 29 | `master_of_a_trade` | Master of a Trade | feat | reach level 30 in one profession | +6 Hit |
| 30 | `deep_waters` | Deep Waters | feat | reach Fishing level 25 | +6 Block |

### 2.4 In all
- Feats: +21 Attack, +14 Defense, +170 HP, +10 Crit, +12 Block, +6 Hit, +4 Dodge, and one queue slot.
- Milestones: +7,000 bank cap, and four items.

## 3. Rules

### 3.1 Criteria
A criterion is one of these kinds. Each lives in `achievements.json`.

| Kind | Example | Reads |
|---|---|---|
| A counter, at least a number | kill 1,000 Goblins | a counter of today, such as `kills.goblin`, `steps.walked`, `crafted.total`, `gathered.copper_ore`, `areas.visited`, `visited.smugglers_cove` |
| The level, at least a number | reach level 20 | the level of the character |
| A profession level, at least a number | reach Fishing level 10 | the level of that profession |
| Any profession level, at least a number | reach level 30 in one profession | the highest level of the six professions |
| A quality found, at least a quality | find an item of Rare quality or better | the new counter of §3.2 |

### 3.2 The quality found
- A new counter keeps the best quality of an item that the player got.
- These sources count: a drop, a first-kill drop, a craft, a catch, a chest, a reroll.
- An item from an achievement does not count.
- An old save starts the counter at the best quality of the items in its bag and on its doll when it loads.

### 3.3 The grind of a feat
The sim sets the count of each feat. A feat costs about these extra days for the average walker (5,000 steps a day),
on top of the way to level 30:

| Stage | Extra days |
|---|---|
| Early | about 3 |
| Mid | about 7 |
| Late | about 14 |

Legendary Find is luck, not a count. Its cost is the chance of a Legendary item (0.5% for each quality roll).

### 3.4 Rewards
- **Bank cap:** the cap grows by the number.
- **An item:** the item goes into the bag at its fixed quality. It has no bonus rolls.
- **A bonus:** the stat of the character grows by the number. The caps of today stay (Crit 50, Block 50, Dodge 30).
- **The queue slot:** the queue holds one more action (6 instead of 5).
- Two bonuses to one stat add up.
- A reward item is never an item that a monster of the criterion drops, or an item that is made from those drops.
  It is never the chest item of a spot in the criterion. A data test checks this rule for each reward.

## 4. When the game checks
- The game checks each achievement after each change, as today.
- The game also checks each achievement when it loads a save.
- An achievement that is earned and meets its criterion stays earned. The player keeps its reward and gets it no
  second time.
- An achievement that is not earned and meets its criterion becomes earned. The player gets its reward.
- An achievement that is earned and does not meet its criterion is lost (§5).

## 5. A lost achievement
- The achievement is not earned any more. The player can earn it again and then gets its reward again.
- **Bank cap:** the cap goes down. Steps in the bank above the new cap are lost.
- **An item:** the game removes one copy of the reward item, at its quality:
  - first from the bag;
  - else from the doll, and the slot becomes empty.
  - If the player no longer has the item, nothing more happens.
- **A bonus:** the stat goes down by the number.
- **The queue slot:** the queue holds one action less. If the queue holds more actions than the new size, the game
  removes the last waiting actions until it fits. The current action stays.
- The report of the next sync names each lost achievement and what the player lost.

## 6. Screens
- **Achievements:** the screen shows three headings: Early, Mid and Late. Each card shows its goal and a line
  "Reward: …", for example "Reward: +4 Attack" or "Reward: Iron shield (Uncommon)".
- A feat shows the word "Feat" on its card.
- A new achievement shows its picture if it has one, and else its placeholder (spec 0014 §3.2).
- The trophy button keeps its dot (spec 0006 amendment 2).
- The banner of an earned achievement names its reward.
- The Character header shows the stats with the bonuses.

## 7. Save
- The save keeps the earned achievements, as today.
- The save keeps the new counter of §3.2.
- The save version goes up by one. Each fixture in `app/test/fixtures/saves/` loads.

## 8. Sim
- The hand-run sim runs at 5,000 steps a day.
- The sim walker without feats reaches levels 10, 20 and 30 within 5% of today's days (days 16, 50 and 84).
- The sim walker earns each milestone of a stage by the end of that stage. Smuggler's Secret is the one exception:
  the cove needs the bottle, which is luck (spec 0011).
- The sim sets the count of each feat, so that it costs the extra days of §3.3.
- The plan records the table of the sim.

## 9. Out of scope
- Titles.
- Talent points from achievements.
- Achievements that compare players.
- Pictures for the 19 new achievements. They come later as content.

## 10. Acceptance criteria

**The list**
1. `achievements.json` holds the 30 achievements of §2, with their ids, names, kinds, criteria and rewards.
2. The 11 achievements of today keep their ids and their pictures.
3. Each feat count comes from the sim of §8.

**Criteria**
4. A counter criterion is earned when the counter reaches its number.
5. A level criterion is earned when the character reaches its level.
6. A profession criterion is earned when that profession reaches its level.
7. "Any profession" is earned when one of the six professions reaches its level.
8. A quality criterion is earned when the player gets an item of that quality or better from a source of §3.2.
9. An item from an achievement does not count for a quality criterion.

**Rewards**
10. A bank cap reward raises the bank cap by its number.
11. An item reward puts the item into the bag at its fixed quality.
12. A bonus raises its stat by its number. Two bonuses to one stat add up.
13. Chieftain's Bane raises the queue to 6 actions.
14. Only feats give bonuses or the queue slot.
15. No reward item drops from a monster of its criterion, or is made from such drops, or is the chest item of a
    spot of its criterion.

**Old saves and lost achievements**
16. A save loads, and the game checks each achievement by the new criteria.
17. An earned achievement that meets its criterion stays earned, and its reward comes no second time.
18. A lost achievement lowers the bank cap. Steps above the new cap are lost.
19. A lost achievement removes one copy of its item, first from the bag, else from the doll.
20. A lost achievement lowers its stat.
21. A lost Chieftain's Bane gives a queue of 5. Waiting actions beyond 5 go, from the back. The current action stays.
22. The report names each lost achievement and what the player lost.
23. A lost achievement can be earned again, and its reward comes again.
24. An old save starts the quality counter at the best quality in its bag and on its doll.
25. Each fixture in `app/test/fixtures/saves/` loads.

**Screens**
26. The Achievements screen shows the headings Early, Mid and Late.
27. Each card shows "Reward: …".
28. A feat card shows the word "Feat".
29. A new achievement without a picture shows its placeholder.
30. The banner of an earned achievement names its reward.

**Balance and build**
31. The sim walker without feats reaches levels 10, 20 and 30 within 5% of days 16, 50 and 84.
32. The sim walker earns each milestone by the end of its stage, except Smuggler's Secret.
33. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
