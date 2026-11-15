# Intent: Achievements rework

Status: accepted
Product owner: Zkalf
Date: 2026-10-24
Issue: #56

## Problem
The game has 11 achievements. Five of them come in the first days (First Steps, Goblin Slayer I, Prospector, Smith,
Brute Force). Only Marathon gives a reward (+500 to the step bank cap). After the first days, an achievement is only a picture on the Achievements screen. The owner wants
achievements in every part of the game, and each one pays the player.

## Proposed outcome

### Achievements through the whole game
1. Achievements spread through the whole game: some early, some mid and some late.
2. The 11 achievements of today stay, with their names and their pictures.
3. Their criteria change, so that they fit the early, mid and late game.
4. New achievements join them.

### Rewards
5. Each achievement gives a reward.
6. The rewards get better later in the game.
7. A reward is one of these:
   - a bigger step bank (as Marathon gives today);
   - items or gear;
   - a permanent bonus to a stat, as big as its grind (outcome 17);
   - one more slot in the queue.
8. The queue slot comes from a hard achievement. It comes on top of the slot from the Utility talent tree (#55).
9. A bonus adds to one of the stats of the character: HP, Attack, Defense, Crit, Hit, Dodge or Block.

### Old saves
10. The game checks each achievement of an old save again by its new criterion.
11. If the player meets the new criterion, the achievement stays earned.
12. If the player does not meet the new criterion, the achievement is not earned any more. The player can earn it
    again.
13. When the player loses an achievement, the player loses its bonus too. The bonus comes back when the player earns
    the achievement again.

### Two kinds of achievement
14. A **milestone** comes on the way through the game. Its reward is a bigger step bank or an item.
15. A **feat** costs a sacrifice: a long grind of a monster after it pays well, or a long chase for luck.
16. Only a feat gives a stat bonus or the queue slot.

### The bonus of a feat
17. The bonus of a feat is as big as the grind, and it grows with the stage of the feat. The spec sets the numbers.
    A start:

    | Stage | Grind at 5,000 steps a day | A feat gives one of these |
    |---|---|---|
    | Early | about 3 days | +4 Attack, +4 Defense or +40 HP |
    | Mid | about 7 days | +7 Attack, +7 Defense, +80 HP, +4 Crit or +4 Dodge |
    | Late | about 14 days | +10 Attack, +10 Defense, +130 HP, +6 Crit, +6 Hit or +6 Block |

    The sim shows that an average walker earns kill counts such as "10 Goblin Brutes" or "kill the Young Dragon once"
    without any effort. A grind of days needs a reward of the same size: "+1 Attack" is less than one level gives.

### Reward items and monsters
18. An item that a reward gives is never an item that a monster of the criterion drops.
19. An item that a reward gives is never made from the drops of a monster of the criterion.
20. An item that a reward gives is never the chest item of a spot in the criterion.

## Affected users and systems
- **Players:** each player. An old save can lose an achievement that it earned under the old criterion.
- **Game rules:** the step bank cap, the queue size, the items that the player gets, and the stats that the bonuses
  change.
- **Data:** `packages/game_core/data/achievements.json` holds the achievements, their criteria and their rewards.
  The queue size is in `economy.json` (`queueSlots`, 5 today).
- **Save:** the earned achievements, and which rewards the player got. Each fixture in `app/test/fixtures/saves/`
  loads.
- **Screens:** the Achievements screen shows the reward of each achievement. The trophy button keeps its dot.
- **Content:** new achievements need pictures. A new achievement without a picture shows its placeholder (spec 0014
  §3.2).

## Constraints
- All numbers live in `data/*.json`, never in code.
- **Balance for the average walker** (about 5,000 steps a day), never for heavy walkers.
- **A hand-run sim checks the pace.** A bigger bank, a queue slot, gear and the bonuses move the pace.
- **Talents stay the main way to build a character** (intent 0015). A bonus from an achievement does not replace a
  talent. A player without feats still makes good progress.
- **Balance cost:** a player with many feats is about 30% stronger in Attack at level 30 than a player without feats.
  The player pays for this with weeks of grind. The sim checks that the pace of the average walker stays in its
  target.
- Health data stays on the device. No network code.
- Out of scope:
  - Titles.
  - Talent points from achievements (intent 0015 gives talent points only from levels).
  - Achievements that compare players.

## Open questions
None: spec 0017 settled them.

## History
- 2026-10-24: first version (#56). Outcomes 1-13.
- 2026-10-24, amendment 1 (PR #83): milestones and feats; the bonus of a feat is as big as its grind; reward items
  never come from the monsters or spots of their criterion. Outcomes 7 and 14-20; the constraint on bonuses; the
  balance cost.
- 2026-11-15 (plan 0068): the amendment folded into this file. Open questions closed by spec 0017. (draft)
