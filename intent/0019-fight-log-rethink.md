# Intent: a new fight log

Status: accepted
Product owner: Zkalf
Date: 2026-11-01
Issue: #58

## Problem
- The fight log on the Now screen shows the last 4 rounds of the current fight, one line per swing. A round costs
  steps, so after a walk the player sees only the last few swings of a fight that is still going.
- The player does not see how the fights of the walk went: how many rounds they took, how much damage the player
  took, whether a crit or a block decided one.
- The Now screen shows too much text. The log adds up to 8 lines under the HP bars.
- The log reads backwards. The newest round is at the top, and the oldest is at the bottom. A story reads from top
  to bottom: round 1 or fight 1 first, then the next one below it.

## Proposed outcome
**On the Now screen: less text**
- During a fight, the Now screen keeps the two HP bars.
- One short line under them tells how the last fight ended, for example "Beat the Goblin in 4 rounds".
- A tap on the fight part of the Now screen opens the fight details.

**The fight details: the story of the fights (direction 1)**
- The details list the finished fights of the current fight action, one line each. For example: "Goblin beaten in
  4 rounds · took 9 damage · 1 crit".
- The list runs from the oldest at the top to the newest at the bottom.

**The fight details: the current fight, round by round (direction 2)**
- Below the finished fights, the details show the current fight, round by round, from round 1 at the top.
- Each kind of swing has its own look:
  - a crit is bright and large
  - a block, a dodge and a miss each have their own colour
  - a big hit stands out from a small one
- Influences: the fight results of Diablo 2 and idle games (direction 1), and the combat text of World of Warcraft
  (direction 2).

## Affected users and systems
- Every player who fights. Android phone.
- `app/lib/ui/now_tab.dart` (the fight part of the Now screen) and a new fight details screen or sheet.
- `packages/game_core`: the current action keeps a short summary of each finished fight. Today it keeps only the
  last `fightLogRounds` rounds. This is a save change.
- `packages/game_core/data/economy.json`: how many fights and rounds the details keep.

## Constraints
- No change to the fight rules, the numbers or the pace. The sims do not move.
- Old saves load. An action from before this change shows its fights from the change onwards.
- No live blur and no animation that redraws a large area on each frame (CLAUDE.md, #121).
- The words on the screen come with the spec. The owner accepts them there.

## Decisions
The owner chose Claude's defaults on 2026-11-01.
1. The details keep the last 10 finished fights of the current action. `economy.json` sets the number.
2. The details open as a sheet over the Now screen.
3. The fight log keeps no fights after the action ends. A new fight action starts an empty list.
4. A big hit or a crit does not move on the screen in the first build. Only colour and size set it apart.
