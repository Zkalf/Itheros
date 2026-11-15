# Intent: The daily chest

Status: accepted
Product owner: Zkalf
Date: 2026-10-22

## Problem
Nothing in the game rewards walking a good day as such: steps only push the current action along. The owner asked
for a daily reward for the average walker (about 5,000 steps a day). Paying it in steps (+500 in the bank) would
just be a flat 10% speed-up for everyone, which moves the pace and gives nothing to look forward to. The owner likes
the Diablo grind: low-chance loot worth chasing.

The chest rewards play, not only walking: the player must use the steps in the game to earn it. Its gear is a better
chance at high quality than a monster drop, as in Diablo 2: a chase with low odds.

## Proposed outcome
1. **A daily goal of 5,000 steps spent on actions.** On each day that the player puts at least that many steps into
   actions, they earn one **supply chest**. One chest per day at most.
   - The steps that go into an action count: the walked steps that pay it, and the boost steps that the step bank
     adds to them.
   - Every kind of action counts: fights, gathering spots, crafts, rerolls and walks between places.
   - Steps that go into the step bank do not count. For example, the steps that the player walks while the
     character rests do not count.
2. **The chest is a mix, weighted for the chase** (owner's choice, 2026-10-22):
   - **Always:** one useful common roll: materials for a profession the player has learned, or a meal. A player who
     has learned Crafting gets one more choice: the inputs of one craft of a gear recipe at their Crafting level.
   - **Sometimes (about 1 in 10):** a piece of gear at the player's level.
   - **Rarely (about 1 in 50):** a shard.
3. **Opening it is a moment, on a screen of its own.** A supply chest button in the top bar, left of Achievements,
   shows a dot when a chest waits. It opens the supply chest screen:
   - the progress of today toward the goal
   - the waiting chests, with "Open" and "Open all"

   Now shows no chest card and no chest progress. The "While you were away" summary says when the player earns a
   chest. Every chest that the player earns waits until the player opens it: no cap.
4. **Days away still count:** a sync that covers several days gives one chest for each day that reached the goal.
   Each chest uses the player's level at the moment the steps of its day reach the goal.
5. **Chest gear rolls a better quality** than a monster drop. The high qualities stay rare. The spec sets the
   chances. A start: rare, epic and legendary get twice the chance of a monster drop; uncommon keeps its chance;
   common takes what is left.

   | Quality | Monster drop | Chest gear (start) |
   |---|---|---|
   | Common | 70% | 60% |
   | Uncommon | 20% | 20% |
   | Rare | 7% | 14% |
   | Epic | 2.5% | 5% |
   | Legendary | 0.5% | 1% |

   With these chances and gear in 1 chest in 10, about 1 chest in 1,000 gives a legendary piece.
6. **Which gear:** an item level from the player's level minus 4 up to the player's level, picked evenly. Never
   above the player's level. Chase items stay out: gear made from shards (King's blade, Chieftain's amulet, Dragon's
   heart) and gear made from a rare trophy (Golden antler mantle), and no inputs for their recipes. The spec lists
   the gear that stays out; new content follows the same rule.
7. **The contents are fixed when the player earns the chest.** The game rolls them at that moment, with the player's
   level at that moment. Opening only shows them, so the player gains nothing when they keep a chest for later.

## Affected users and systems
All players. Game rules (the daily goal, the chest roll); `data/*.json` (the goal, the chest's table and chances);
the save (chests earned but not opened, which days already paid); the supply chest screen, the top bar, the away
summary and the journal.

## Constraints
- **The pace doesn't move by much:** the chest gives loot, not steps or XP. Its chances are data, and they're
  checked in the sim with the pacing test, since drop chances move the pace.
  - A player with steps in the bank reaches the goal sooner: a full bank can halve the walked steps it needs.
  - Chest gear is better on average than a monster drop. One chest a day keeps the effect small next to the drops
    of a day of fights.
  - Professions still matter: in the sim of plan 0037, a fighter that never gathers or crafts reached level 30
    about 19% later than the walker with professions (spec 0010 wants at least 15%).
- Only real steps count toward the goal, per local day (spec 0001 amendment 1): walked steps and the boost steps of
  the bank. The steps of a test walk count too, so that the owner can try the chest; only owner builds have the
  test walk (spec 0013 §2.1 point 6).
- **Existing saves keep everything.** Days walked before the update don't pay out.
- Clean UI (intent 0008): one screen for the chest, and nothing on Now.
- Out of scope: streaks, weekly or monthly chests, a goal the player sets, chests bought with anything.

## Open questions
None.

## History
- 2026-10-22: first version (outcomes 1-4).
- 2026-11-01, amendment 1 (#57): the goal counts steps spent on actions, walks too; no cap; "Open all"; chest
  gear rolls a better quality; the gear window and the chase items; the contents roll at once. Outcomes 1-7; the
  real steps constraint.
- 2026-11-01, amendment 2 (#57): the chest gets its own screen from a top bar button; nothing on Now. Outcome 3;
  the Clean UI constraint.
- 2026-11-01, amendment 3 (#57): gear in 1 chest in 10, not 1 in 5; Crafting materials in the common roll.
  Outcomes 2, 5 and 6; the pace constraint.
- 2026-11-01, spec 0013 amendment 4 (#170): test walks count toward the chest. The real steps constraint.
- 2026-11-15 (plan 0068): the three amendments folded into this file. Open questions closed by spec 0013.
