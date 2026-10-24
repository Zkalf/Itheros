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
   - a small permanent bonus to a stat;
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
- **The bonuses stay small.** Talents (intent 0015) are the main way to build a character. A bonus from an
  achievement does not replace a talent.
- Health data stays on the device. No network code.
- Out of scope:
  - Titles.
  - Talent points from achievements (intent 0015 gives talent points only from levels).
  - Achievements that compare players.

## Open questions
To settle in the spec:
1. The list of achievements: how many, and which are early, mid and late.
2. The new criteria of the 11 achievements of today.
3. The reward of each achievement, and which achievement gives the queue slot.
4. Whether gear from a reward rolls its quality, like a drop (game direction: Diablo 2).
5. How big each bonus is, and whether two bonuses to one stat add up.
6. What happens to a reward when an old save loses its achievement:
   - the step bank: the cap goes down, and steps above the new cap;
   - an item that the player has already got;
   - the queue slot, when the queue holds more actions than the new size.
7. Whether the player gets the reward again when they earn a lost achievement again.
8. Where the Achievements screen shows the reward.
