# Intent: The Graveyard King opens the river

Status: accepted
Product owner: Zkalf (chose on 2026-11-07: only the King closes a road, the first kill opens it for good, the map
shows the road with a lock, a save that has stood in Grey Moor keeps the road; accepted on 2026-11-07 by the push to
main)
Date: 2026-11-07
Issue: #233

## Problem
- Today the whole world is open from level 1 (spec 0008 decision 1), and every boss is optional (spec 0002
  decision 8).
- The first part of the game has no clear goal. A player can walk past the Graveyard King and never fight him.
- The owner wants the second half of the world to feel earned, and a boss that matters.

## Proposed outcome

### The closed road
1. The road from Old Graveyard to Grey Moor is closed until the player beats the Graveyard King once.
2. This road is the only road across the river (`data/world.json`). So Grey Moor, Iron Ridge, Troll Bridge, Mountain
   Pass, Mithril Deep and Dragon's Peak stay out of reach until then.
3. The first kill opens the road for good. A later loss to the King does not close it again.
4. Only the King closes a road. The Ogre Chieftain and the Young Dragon stay optional, as today.

### What the player sees
5. On the World map the road shows with a lock on it.
6. Grey Moor shows in full, as a neighbour of an explored Old Graveyard does today (spec 0008 decision 5). The areas
   beyond it follow the fog rules of today.
7. A tap on the lock, or on Travel to an area beyond the river, says why: "Beat the Graveyard King to cross."
8. The first kill opens the road with a moment in the game: a line in the report and the lock gone from the map.

### What stays the same
9. The south of the river stays open from level 1: Camp, Goblin Woods, Copper Hills, Old Graveyard, Mirror Lake and
   Smugglers' Cove.
10. Any player can fight the King from level 1, as today. The road opens on a win, not at a level.
11. The King's fight, stats and drops do not change. #234 (fights in depth) can change them later.

### Old saves
12. A save that has already explored Grey Moor keeps the road open, with or without a King kill.
13. A save with a King kill keeps the road open.
14. So no player loses a spot that they use today, and no player stands beyond the river with no road back.

## Affected users and systems
- **Players:** every new player, and old saves that never crossed the river.
- **game_core:** travel and routing refuse the closed road. Auto-travel never plans a path across it. A queued action
  beyond the river cannot start while the road is closed. The King kill count exists already (`kills.graveyard_king`,
  King's Bane), so the save needs no new counter. Old saves need a rule for "explored Grey Moor" (item 12).
- **App:** the lock on the World map, the line on a tap, the line in the report on the first kill.
- **The camp tour (spec 0022):** step 2 says that every road is open from the first day. Its words change.
- **The sim walker:** today it may never fight the King (spec 0017 amendment 3). With the gate it must beat him before
  it crosses. It learns the simplest habit that keeps it playing.
- **Specs:** amendments to spec 0008 (decision 1, the open world), spec 0002 (decision 8, bosses never a gate) and
  spec 0022 (the tour's words).

## Constraints
- **The pace can move.** The walker crosses the river later, so level 30 can come later. The spec runs hand sims
  (16 seeds) and names the change in days. If the pacing test in `check.ps1` trips, the owner decides: widen the range
  or tune.
- **Game direction.** `docs/game-direction.md` says "Do not propose level gates or other help that protects new
  players". This gate is a boss gate, not a level gate. The same commit as this intent changes the doc (the owner
  accepts both):
  - "The whole world south of the river is open from level 1. The Graveyard King closes the road across the river
    until the first kill (intent 0022). The danger is a feature."
  - "Do not propose level gates. A boss may close a road; a level never does."
- Influence: World of Warcraft, where a quest or a boss opens the next zone.
- Out of scope:
  - Gates for the Ogre Chieftain or the Young Dragon.
  - A change to the King's fight or his drops.
  - New art beyond a lock on the map, drawn as a flat SVG by Claude.

## Open questions
1. **The line in the report on the first kill.** Recommendation: "The King falls. The road to Grey Moor is open." The
   spec writes it.
2. **The lock on the map.** A small lock on the middle of the road, in the Quiet Teal style (spec 0014). The spec
   places it and checks that it fits at 408 dp.
3. **The pace in days.** The spec measures it with hand sims before the plan.
