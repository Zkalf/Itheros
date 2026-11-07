# Spec 0008 amendment 5: the Graveyard King opens the river

Status: draft
Amends: [spec 0008](0008-character-and-world-layout.md) decision 1 (the open world) and criterion 4; also
[spec 0002](0002-levels-that-matter.md) decision 8 (bosses never a gate) and
[spec 0022](0022-camp-tour.md) card 2 (the words of the World step)
Intent: [0022](../intent/0022-king-opens-the-river.md)
Issue: #233
Product owner: Zkalf (chose on 2026-11-07: only the King closes a road, the first kill opens it for good, the road
shows with a lock, a save that has stood in Grey Moor keeps the road; accepted intent 0022 on 2026-11-07)
Date: 2026-11-07

## Why
- Today a player can walk across the river on day one and never fight the Graveyard King.
- The owner wants a clear goal for the first part of the game, and a boss that matters (intent 0022).

## Change

### The closed road
1. **A road can wait for a boss.** A route in `data/world.json` can name a boss in a new field `opensOn`. Only one
   route gets it: `old_graveyard` to `grey_moor`, with `"opensOn": "graveyard_king"`.
2. **When the road is open.** A road with `opensOn` is open when either of these is true:
   - the player has killed its boss at least once (the counter `kills.graveyard_king`);
   - the player has explored both ends of the road.
3. Otherwise the road is **closed**, in both directions.
4. The second case of change 2 keeps old saves whole: a save that has stood in Grey Moor keeps the road, with or
   without a kill. The save gets no new field.
5. **The first kill opens it for good.** The kill counter never goes down, so a later loss never closes the road.
6. **What a closed road does.** Travel and the routes treat it as a road that does not exist:
   - auto-travel and the walk before a queued action never plan a path across it;
   - Travel to Grey Moor, or to any area that only the closed road reaches, is refused;
   - an action that only happens beyond the river is refused when the player adds it;
   - a waiting action whose place lies beyond the road is skipped with the reason of today (`noRoute`).
7. **The words of a refusal.** A refusal or a skip because of the closed road says: "Beat the Graveyard King to
   cross." Fog keeps its own words ("The way there is in the fog").
8. A walk that is already on the road when the game updates finishes that leg, as today. The player arrives in Grey
   Moor, which then counts as explored.

### The fog
9. Fog does not change (spec 0008 decision 5). Grey Moor shows in full once Old Graveyard is explored: its monsters,
   its spots and its sheet. The areas beyond Grey Moor stay fogged until the player explores Grey Moor.

### The World map
10. **The lock.** While the road is closed, a small lock sits on the middle of the road on the World map. It is a flat
    SVG that Claude draws, in the Quiet Teal style (spec 0014). The road keeps its look of today under it.
11. The lock is not a button. Grey Moor's area sheet says why: it shows "Beat the Graveyard King to cross." in place of
    the Travel here button.
12. When the road opens, the lock leaves the map.

### The first kill
13. The first kill of the Graveyard King adds one line to the report of that walk (the away summary and the news):
    "The King falls. The road to Grey Moor is open."
14. The line shows only when the kill opens the road. A save that already had the road through change 2 gets no line.

### The camp tour
15. Card 2 (World) of spec 0022 gets new words, at most three lines at text size 1.0 (spec 0022):
    "This is the map. Tap a place to travel there, or to see what lives there. Beat the Graveyard King to cross the
    river."

### What stays the same
16. The south of the river stays open from level 1: Camp, Goblin Woods, Copper Hills, Old Graveyard, Mirror Lake and
    Smugglers' Cove.
17. Any player can fight the King from level 1. The road opens on a win, never at a level.
18. The King's stats, drops, first-kill drop and the King's Bane achievement do not change.
19. The Ogre Chieftain and the Young Dragon stay optional (spec 0002 decision 8 still holds for them).

### The sim walker and the pace
20. **The walker's habit.** From level 10, while the road is closed, the walker fights the King before it picks
    anything else. After a loss it waits for its next level, as it does today for any lost fight.
21. **The pace can move.** Plan milestone 1 measures it with hand sims at 5,000 steps a day:
    - 16 seeds, the median day of level 30, before and after the change;
    - the day of the first King kill.
22. Intent 0022 asked the spec for these numbers. They come in plan milestone 1 instead, because the sim needs the new
    rule and the walker's habit, which the plan builds. The owner sees the numbers before the screens.
23. If the pacing test in `check.ps1` trips, Claude reports the numbers once. The owner decides: widen the range, or
    tune.

## Acceptance criteria

**The road**
1. `data/world.json` has `"opensOn": "graveyard_king"` on the route from `old_graveyard` to `grey_moor`, and on no
   other route.
2. A new save has the road closed.
3. A save with one kill of the Graveyard King has the road open.
4. A save that has explored both Old Graveyard and Grey Moor, with no King kill, has the road open.
5. A save with the road open keeps it open after a loss to the King.

**Travel and the queue**
6. With the road closed, the walking distances from Camp reach no area beyond the river.
7. With the road closed, Travel to Grey Moor throws an error that says "Beat the Graveyard King to cross."
8. With the road closed, adding a fight with a Wolf (Grey Moor) from Camp throws the same error.
9. With the road closed, a waiting action whose place lies beyond the river is skipped with `noRoute`.
10. With the road open, Travel from Camp to Grey Moor walks through Old Graveyard, as today.
11. A walk that is on the closed road's leg finishes it and arrives in Grey Moor.

**Fog**
12. With Old Graveyard explored and the road closed, Grey Moor is not fogged.
13. With the road closed, Iron Ridge and Troll Bridge are fogged for a player who has not explored Grey Moor.

**The World map**
14. With the road closed, the World map shows the lock on the road between Old Graveyard and Grey Moor.
15. With the road open, the World map shows no lock.
16. With the road closed, Grey Moor's area sheet shows "Beat the Graveyard King to cross." and no Travel here button.
17. With the road open, Grey Moor's area sheet shows Travel here.
18. The lock and the sheet fit at 408 dp wide and at text size 2.0. The PR says so, with a render.

**The first kill**
19. The walk with the first King kill reports "The King falls. The road to Grey Moor is open."
20. A second King kill reports no such line.
21. A save whose road is open through criterion 4 reports no such line on its first King kill.

**The camp tour**
22. Card 2 of the camp tour shows the words of change 15.

**Save**
23. The save schema does not change.
24. Each save fixture in `app/test/fixtures/saves/` loads. A fixture that has explored Grey Moor has the road open.

**The sim and the pace**
25. The walker beats the King before it crosses the river, on every seed of the pacing test.
26. Plan milestone 1 reports the median day of level 30 (16 seeds) before and after, and the owner sees it before
    milestone 2.
27. The pacing test passes, or the owner has accepted new ranges for it.

**Check and release**
28. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
