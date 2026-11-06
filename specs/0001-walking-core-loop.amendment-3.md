# Spec 0001 amendment 3: day one counts in full

Status: accepted
Amends: [spec 0001](0001-walking-core-loop.md) decision 6 ("Nothing from before install counts") and amendment 1
(steps credited per local day)
Issue: #225
Product owner: Zkalf (chose on 2026-11-06: "Give them the steps")
Date: 2026-11-06

## Why
- A new game marks the steps already walked that day as counted, so the game never gets them.
- "Walked today" on Now shows the day's whole total, these steps included. On day one the screen says that the
  player walked more than the game gave them.

## Change
1. A new game counts the whole day of its start: the steps walked earlier that day go to the game at the first
   sync, like any other steps of the day.
2. Days before the first day still do not count (the first day stays the first day of the window).
3. "Walked today" does not change: it shows the steps that the game got today, now true on day one too.
4. The step bank's cap and the other rules of a sync stay as they are. A player who walked more than the cap before
   the start keeps what the cap allows.

## Acceptance criteria
1. With 2,000 steps walked before the start of a new game, the first sync gives the game 2,000 steps.
2. Steps of the day before the start do not count.
3. On day one, "Walked today" equals the steps that the game got that day.
4. A save from before this change keeps its credit: the steps it did not count on its first day stay uncounted.
