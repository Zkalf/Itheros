# Spec 0017: Achievements rework

Status: accepted
Intent: [intent/0017-achievements-rework.md](../intent/0017-achievements-rework.md) (accepted, PR #83)
Builds on: spec 0004 (achievements and counters), spec 0006 amendment 2 (the trophy button), spec 0016 (the queue
of 5), spec 0014 §3.1 (achievement pictures)
Overrides: the criteria of the 11 achievements in `achievements.json`; the 5 queue slots of spec 0016 §2 for a player
with Chieftain's Bane
Product owner: Zkalf
Date: 2026-10-24

The game gets 30 achievements: 10 early, 8 mid and 12 late. The 11 achievements of 2026-10-24 stay, with new
criteria. A **milestone** comes on the way and gives a bigger step bank or an item. A **feat** costs a long grind and
gives a stat bonus or the queue slot. The game checks the achievements of each save again when it loads. A player who
no longer meets a criterion loses the achievement and its reward.

## 1. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | How many achievements? | **About 30** (owner): 10 early, 8 mid, 12 late. The first list had 9 mid and 11 late; Master Smith moved to late on 2026-10-24. |
| 2 | What are they about? | Monsters and bosses, professions, loot, walking and exploring (owner). |
| 3 | The 11 of 2026-10-24 | **They stay, with new criteria** (owner). Names, ids and pictures stay. |
| 4 | Old saves | **Checked again by the new criteria** (owner). |
| 5 | The rewards of a lost achievement | **Strict** (owner): the player loses the reward. §5 gives the rules. |
| 6 | Gear from a reward | **A fixed quality** (owner). It does not roll. |
| 7 | The queue slot | **Chieftain's Bane**, the boss of level 20 (owner: "around level 20, so you can enjoy the extra slot"). |
| 8 | Bonuses | Only feats give them. Each bonus is as big as its grind (intent 0017 outcome 17). |
| 9 | Two bonuses to one stat | They add up. |
| 10 | Reward items | Never from a monster or a spot of the criterion (intent 0017 outcomes 18-20). |
| 11 | The grind of a feat | The sim sets the counts, so that each feat costs about the days of §3.3. |
| 12 | Master of a Trade | **Level 30 in all four gathering professions** (owner, 2026-10-24). |
| 13 | Deep Waters | **Catch fish: a count** (owner, 2026-10-24). |
| 14 | Smith's reward | **+500 bank cap** (owner, 2026-10-24). |
| 15 | The meals comparison | **Compare without the bonuses of feats** (owner, 2026-10-24). |

## 2. The achievements

The counts of the feats are those of `achievements.json`: the sim of plan 0021 M2 set them (§3.3). The first
counts of this spec stand beside them as "first". The numbers in brackets are the kills of the sim walker on the way
to level 30 at 5,000 steps a day, without the feat, in that sim.

### 2.1 Early (levels 1–10)

| # | Id | Name | Kind | Criterion | Reward |
|---|---|---|---|---|---|
| 1 | `first_steps` | First Steps | milestone | walk 10,000 steps | +250 bank cap |
| 2 | `prospector` | Prospector | milestone | gather 30 copper ore | +250 bank cap |
| 3 | `smith` | Smith | milestone | craft 15 items | +500 bank cap |
| 4 | `kings_bane` | King's Bane | milestone | kill the Graveyard King once | +500 bank cap |
| 5 | `adventurer` | Adventurer | milestone | reach level 10 | +500 bank cap |
| 6 | `angler` | Angler | milestone | catch 5 fish at Lake shore | +250 bank cap |
| 7 | `lucky_find` | Lucky Find | milestone | find an item of Uncommon quality or better | +250 bank cap |
| 8 | `goblin_slayer_1` | Goblin Slayer I | feat | kill 1,200 Goblins (75; first 1,000) | +4 Attack |
| 9 | `brute_force` | Brute Force | feat | kill 1,000 Goblin Brutes (252; first 2,000) | +40 HP |
| 10 | `bone_collector` | Bone Collector | feat | kill 700 Skeletons (222; first 1,500) | +4 Defense |

- Angler counts `gathered.lake_scale`. Each catch at Lake shore gives one lake scale, and no other spot gives one.

### 2.2 Mid (levels 11–20)

| # | Id | Name | Kind | Criterion | Reward |
|---|---|---|---|---|---|
| 11 | `marathon` | Marathon | milestone | walk 100,000 steps | +500 bank cap |
| 12 | `seasoned` | Seasoned | milestone | reach level 20 | +1,000 bank cap |
| 14 | `rare_find` | Rare Find | milestone | find an item of Rare quality or better | +500 bank cap |
| 15 | `smugglers_secret` | Smuggler's Secret | milestone | visit Smugglers' Cove | Sapphire ring, Rare |
| 16 | `chieftains_bane` | Chieftain's Bane | feat | kill the Ogre Chieftain 275 times (58; first 100) | +1 queue slot |
| 17 | `bear_hunter` | Bear Hunter | feat | kill the Old Bear 1,050 times (0; first 100) | +4 Crit |
| 18 | `wolf_pack` | Wolf Pack | feat | kill 1,350 Wolves (348; first 3,000) | +7 Attack |
| 19 | `ghost_hunter` | Ghost Hunter | feat | kill 1,700 Ghosts (740; first 5,000) | +4 Dodge |

### 2.3 Late (levels 21–30)

| # | Id | Name | Kind | Criterion | Reward |
|---|---|---|---|---|---|
| 13 | `master_smith` | Master Smith | milestone | craft 60 items | Mithril helm, Rare |
| 20 | `travelling_salesman` | Travelling Salesman | milestone | visit 11 areas | +500 bank cap |
| 21 | `the_long_road` | The Long Road | milestone | walk 350,000 steps | +1,500 bank cap |
| 22 | `champion` | Champion | milestone | reach level 30 | Star diamond ring, Epic |
| 23 | `epic_find` | Epic Find | milestone | find an item of Epic quality or better | +1,000 bank cap |
| 24 | `dragonslayer` | Dragonslayer | feat | kill the Young Dragon 1,150 times (274; first 1,000) | +10 Attack |
| 25 | `golem_breaker` | Golem Breaker | feat | kill 2,150 Stone Golems (597; first 5,000) | +10 Defense |
| 26 | `troll_slayer` | Troll Slayer | feat | kill 3,100 Trolls (0; first 1,000) | +6 Block |
| 27 | `wyvern_hunter` | Wyvern Hunter | feat | kill 2,200 Wyverns (0; first 1,000) | +130 HP |
| 28 | `legendary_find` | Legendary Find | feat | find an item of Legendary quality | +6 Crit |
| 29 | `master_of_a_trade` | Master of a Trade | feat | reach level 30 in Mining, Woodcutting, Fishing and Hunting | +6 Hit |
| 30 | `deep_waters` | Deep Waters | feat | catch 500 fish at Cold tarn | +6 Block |

- Master Smith stands in the late stage, so its Mithril helm comes after level 20 (days 54–63 in the sim). It keeps
  its number 13.
- Deep Waters counts `gathered.tarn_scale`. Each catch at Cold tarn, the fishing spot of level 20, gives one tarn
  scale, and no other spot gives one. The Achievements screen names the goal as catches at Cold tarn: "Catch 500 fish
  at Cold tarn".

### 2.4 In all
- Feats: +21 Attack, +14 Defense, +170 HP, +10 Crit, +12 Block, +6 Hit, +4 Dodge, and one queue slot.
- Milestones: +7,500 bank cap, and three items. The first list had +7,000 and four items: Smith then gave an Iron
  shield.

## 3. Rules

### 3.1 Criteria
A criterion is one of these kinds. Each lives in `achievements.json`.

| Kind | Example | Reads |
|---|---|---|
| A counter, at least a number | kill 1,200 Goblins | a counter, such as `kills.goblin`, `steps.walked`, `crafted.total`, `gathered.copper_ore`, `gathered.lake_scale`, `areas.visited`, `visited.smugglers_cove` |
| The level, at least a number | reach level 20 | the level of the character |
| A profession level, at least a number | reach Fishing level 10 | the level of that profession |
| Each of a list of professions, at least a level | reach level 30 in Mining, Woodcutting, Fishing and Hunting | the lowest level of the professions in the list |
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

- Legendary Find is luck, not a count. Its cost is the chance of a Legendary item (0.5% for each quality roll).
- The cost of a feat is its days of grind: from the start of the grind to the feat. The days that a grind adds to
  level 30 are noisy, because the grind changes the gear that the walker makes later.

### 3.4 Rewards
- **Bank cap:** the cap grows by the number.
- **An item:** the item goes into the bag at its fixed quality. It has no bonus rolls.
- **A bonus:** the stat of the character grows by the number. The caps stay (Crit 50, Block 50, Dodge 30).
- **The queue slot:** the queue holds one more action (6 instead of 5). Since spec 0015, the Quartermaster talent
  adds a slot too, and the two add up (spec 0015 §2.4).
- Two bonuses to one stat add up.
- A reward item is never an item that a monster of the criterion drops, or an item that is made from those drops.
  It is never the chest item of a spot in the criterion. A data test checks this rule for each reward.

## 4. When the game checks
- The game checks each achievement after each change.
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
  "Reward: …", for example "Reward: +4 Attack" or "Reward: Mithril helm (Rare)".
- A feat shows the word "Feat" on its card.
- A new achievement shows its picture if it has one, and else its placeholder (spec 0014 §3.2).
- The trophy button keeps its dot (spec 0006 amendment 2).
- The banner of an earned achievement names its reward.
- The Character header shows the stats with the bonuses.

## 7. Save
- The save keeps the earned achievements.
- The save keeps the new counter of §3.2.
- The save version goes up by one. Each fixture in `app/test/fixtures/saves/` loads.

## 8. Sim
- The hand-run sim runs at 5,000 steps a day.
- The sim sets the count of each feat, so that it costs the extra days of §3.3.
- On each of the 8 seeds of the pacing test, the sim walker earns each milestone of a stage by the end of that stage.
  Two milestones are the exceptions:
  - Smuggler's Secret: the cove needs the bottle, which is luck (spec 0011).
  - King's Bane: the walker may never fight the Graveyard King. A boss fight is a choice.
- The pacing test pins no day for seed 1 (since 2026-11-02). Its ranges hold the pace (spec 0010 §9.3 target 1):
  - each seed reaches level 5 on day 1-2, level 10 on day 11-16 and level 30 on day 70-105;
  - the median seed reaches level 30 on day 80-100.
- The meals comparison of spec 0011 §9.3 (target 5) runs with the bonuses of feats set to nothing. The game keeps
  the bonuses. Only the comparison leaves them out: Legendary Find is luck, and its bonus (+6 Crit) lands on other
  days in the runs with and without meals.
- A reward of free gear slows the sim walker: it then skips a craft, and its crafts and gathering change. Smith's Iron
  shield made it reach level 30 on day 93 instead of 84. A player is not slower with a free shield, so Smith gives
  bank cap, and Master Smith's helm comes in the late stage.
- The plan records the table of the sim (`docs/sim/0017-achievements.md`).

## 9. Out of scope
- Titles.
- Talent points from achievements.
- Achievements that compare players.
- Pictures for the 19 new achievements. They come later as content.

## 10. Acceptance criteria

**The list**
1. `achievements.json` holds the 30 achievements of §2, with their ids, names, kinds, criteria and rewards.
2. The 11 achievements of 2026-10-24 keep their ids and their pictures.
3. Each feat count comes from the sim of §8.

**Criteria**
4. A counter criterion is earned when the counter reaches its number.
5. A level criterion is earned when the character reaches its level.
6. A profession criterion is earned when that profession reaches its level.
7. "Each of these professions" is earned when each profession of the list reaches its level.
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
31. Removed on 2026-11-02 (#173).
32. On each of the 8 seeds of the pacing test, the sim walker earns each milestone by the end of its stage, except
    Smuggler's Secret and King's Bane.
33. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
34. The pacing test has no test that pins seed 1 at fixed days.
35. The pacing test keeps the ranges of §8.

## History
- 2026-10-24: first version (intent 0017, plan 0021, #83). Criteria 1-33.
- 2026-10-24, amendment 1 (plan 0021 M1): Master of a Trade asks for four professions. Decision 12; §2.3 row 29;
  §3.1; criterion 7.
- 2026-10-24, amendment 2 (plan 0021 M2): Deep Waters counts catches at Cold tarn. Decision 13; §2.3 row 30.
- 2026-10-24, amendment 3 (plan 0021 M2): Prospector 30 ore, Smith 15 crafts and +500 bank cap, Angler 5 fish at
  Lake shore, Master Smith late, The Long Road 350,000 steps; criterion 31 on seed 1; King's Bane as an exception;
  the meals comparison without feat bonuses. Decisions 1, 14 and 15; §2; §3.3; §8; criteria 31 and 32.
- 2026-10-25, plan 0021 M2 (#84): the sim set the feat counts in `achievements.json`. §2.
- 2026-10-31, spec 0015: Quartermaster adds a queue slot that adds up with Chieftain's Bane. §3.4.
- 2026-11-01, spec 0013 amendment 1 (#57): criterion 31's day of level 10 became day 15.
- 2026-11-02, spec 0021 amendment 1 (#173): criterion 31's day of level 30 became day 91.
- 2026-11-02, amendment 4 (#173): no pinned days for seed 1. §8; criteria 31, 33, 34 and 35.
- 2026-11-02, spec 0009 amendment 3 (#181): each seed reaches level 30 by day 105. §8.
- 2026-11-15 (plan 0068): the amendments folded into this file. §2 now gives the feat counts of the data (Goblin
  Slayer I 1,200, Brute Force 1,000, Bone Collector 700, Chieftain's Bane 275, Bear Hunter 1,050, Wolf Pack 1,350,
  Ghost Hunter 1,700, Dragonslayer 1,150, Golem Breaker 2,150, Troll Slayer 3,100, Wyvern Hunter 2,200, Deep Waters
  500), with the first counts beside them. §2.4 gives the milestones' +7,500 bank cap and three items, and §6's
  example reward is the Mithril helm, both since amendment 3. No rule or criterion changed.
