# Intent: The daily chest

Status: draft
Product owner: Zkalf
Date: 2026-10-22

## Problem
Nothing in the game rewards walking a good day as such: steps only push the current action along. The owner asked
for a daily reward for the average walker (about 5,000 steps a day). Paying it in steps (+500 in the bank) would
just be a flat 10% speed-up for everyone, which moves the pace and gives nothing to look forward to. The owner likes
the Diablo grind: low-chance loot worth chasing.

## Proposed outcome
1. **A daily goal of 5,000 steps.** On each day the player walks at least that many, they earn one **supply chest**.
   One chest per day at most.
2. **The chest is a mix, weighted for the chase** (owner's choice, 2026-10-22):
   - **Always:** one useful common roll: mats for a profession the player has learned, or a meal.
   - **Sometimes (about 1 in 5):** a piece of gear at the player's level, with a normal quality roll.
   - **Rarely (about 1 in 50):** a shard.
3. **Opening it is a moment:** the chest shows on Now and in the "While you were away" summary, and the player opens
   it with a tap to see what came out.
4. **Days away still count:** a sync that covers several days gives one chest for each day that reached the goal.

## Affected users and systems
All players. Game rules (the daily goal, the chest roll); `data/*.json` (the goal, the chest's table and chances);
the save (chests earned but not opened, which days already paid); Now, the away summary and the journal.

## Constraints
- **The pace doesn't move by much:** the chest gives loot, not steps or XP. Its chances are data, and they're
  checked in the sim with the pacing test, since drop chances move the pace.
- Only real walked steps count toward the goal, per local day (spec 0001 amendment 1). Test walks don't.
- **Existing saves keep everything.** Days walked before the update don't pay out.
- Clean UI (intent 0008): one card on Now, no new screen.
- Out of scope: streaks, weekly or monthly chests, a goal the player sets, chests bought with anything.

## Open questions
None blocking. To settle in the spec: what happens to unopened chests (do they pile up or wait for a tap), the exact
chances and mats amounts, and the "gear at your level" rule.
