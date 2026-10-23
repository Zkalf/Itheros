# Intent: Talent trees

Status: accepted
Product owner: Zkalf
Date: 2026-10-23

## Problem
From level 10, each level gives one talent point (spec 0002 decision 7). The player cannot spend the points. The
level 10 ceremony promises a speciality, but nothing follows (spec 0002 risk 4). The owner wants talents like World
of Warcraft: trees where the player invests points and builds a character.

## Proposed outcome

### Two trees
1. The game has two talent trees: **Combat** and **Utility**.
2. Talents give passive bonuses only (spec 0001 §7).
3. **Combat** makes fights better:
   - Attack, HP and Defense.
   - Critical hits.
   - Fewer steps for each fight.
   - A better chance that a drop has a higher quality.
4. **Utility** makes the day better:
   - A bigger step bank, cheaper travel and an extra queue slot. The achievements rework may give another queue
     slot later.
   - Fewer steps for each gather and craft, more materials and better quality odds when the player crafts.
   - A better chance that a reroll raises the quality of an item (spec 0010 §7.2).
   - Safety: the player loses less after a lost fight and sees deadly fights earlier.

### Balance
5. **Combat is a bit faster** (owner's choice). A full Combat build gives about 10–15% more progress for each step
   than a full Utility build.
6. The gap counts all progress: XP, levels and loot.
7. Utility gives up that gap for comfort.
8. Neither tree is a trap. A player who picks either tree still makes good progress.

### Find and reroll chances
9. The find chance in Combat changes quality only. It does not give more drops.
10. First-kill drops and boss drops keep their chances.
11. The find chance and the reroll chance sit deep in their trees. A player who splits points cannot easily take
    both.
12. The find chance counts inside the gap of outcome 5. Thus the other Combat talents get smaller.

### Shape
13. Each tree has rows, like World of Warcraft Classic.
14. Points spent in a tree open its next row.
15. The last row of each tree holds one strong talent.
16. Each tree holds about as many points as the player has at the soft cap (about 28). Thus the player cannot fill
    both trees. The player goes deep in one tree or splits the points.
17. The trees grow with content. Each content update that raises the soft cap adds rows. The trees always hold a
    few more points than the player has.

### Reset
18. The player can reset all points and spend them again.
19. A reset happens only at **Camp**, with a trainer.
20. The first reset is free.
21. Each later reset costs steps from the bank. The price grows with each reset.
22. The player can spend new points anywhere.

## Affected users and systems
- **Players:** each player from level 10. Existing saves keep their points, and the player can spend them.
- **Game rules:** stats, fights, step costs, the bank cap, travel, the queue, gathering, crafting, rerolls, the
  drop quality roll and the lost-fight penalty.
- **Data:** `data/*.json` holds the trees, the talents, their numbers and the reset prices.
- **Save:** the spent points and the number of resets. Each fixture in `app/test/fixtures/saves/` loads.
- **Screens:** a Talents tab on Character (intent 0008). The look comes from Quiet Teal (spec 0014 §4.3).
- **Content:** a talent trainer at Camp.

## Constraints
- **The screen waits for Quiet Teal.** Plan 0017 changes the screens now. The talent screens start after it lands.
  The rules in `packages/game_core` and the data can come first.
- **Balance for the average walker** (about 5,000 steps a day), never for heavy walkers.
- **A hand-run sim checks the pace.** Talents change where steps go. The sim compares a full Combat build, a full
  Utility build and a split build.
- All numbers live in `data/*.json`, never in code.
- Health data stays on the device. No network code.
- Out of scope:
  - More than two trees.
  - Talents for each profession.
  - Talents that the player uses by hand.
  - Talent points from any source other than levels.
  - A find chance from gear.

## Open questions
None blocking. To settle in the spec:
1. The talents in each row and their numbers.
2. The points for each row.
3. The strong talent at the bottom of each tree.
4. The reset prices.
5. The trainer: a name and lines.
6. How the rows of a tree fit the pips of spec 0014 §4.3.
7. The sim targets for the three builds.
