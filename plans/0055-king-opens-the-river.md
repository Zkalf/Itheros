# Plan 0055: Build "the Graveyard King opens the river" (spec 0008 amendment 5)

Status: accepted
Spec: `specs/0008-character-and-world-layout.amendment-5.md` · Intent: 0022 · Issue: #233 · Product owner: Zkalf ·
Date: 2026-11-07

Names of files, widgets and tests refer to `main` at `f2750c0`.

## Choices this plan makes
- **Two PRs.** M1 holds the rules, the sim walker and the pace numbers. M2 holds the screens. The owner sees the pace
  (spec change 21) before M2 starts.
- **One rule for the closed road.** The routes (`_paths` in `queue.dart`) skip a closed road, as they skip fog today.
  Travel, auto-travel, the walk before a queued action and the `noRoute` skip then follow from it, with no new code
  path.
- **No new save field and no migration.** Change 2 reads the kill counter and the explored areas, which every save
  has.

## What changes in the code

### M1: game_core
- `data/world.json`: `"opensOn": "graveyard_king"` on the route `old_graveyard` -> `grey_moor` (change 1).
- `lib/src/data/world.dart` (`RouteDef`): a new field `opensOn` (`String?`), read from the route.
- `lib/src/game/world.dart`: `roadOpen(state, route)` (change 2) and `closedRoads(state)`, the closed routes, for the
  map.
- `lib/src/game/queue.dart`:
  - `_paths` skips a closed road (change 6).
  - `_explain` gives "Beat the Graveyard King to cross." when the closed road is what blocks the way (change 7). The
    test: the place is reachable when `_paths` ignores closed roads. The words name the boss from data.
- `lib/src/events.dart`: a new event `RoadOpened(from, to, boss)`.
- `lib/src/game/run.dart`: after a kill, if a road with `opensOn` equal to that monster was closed before the kill and
  is open after it, add `RoadOpened` (changes 13-14).
- `lib/simulation.dart`:
  - the walker's `_paths` skips a closed road, like the game's;
  - the walker's habit (change 20): from level 10, while a road is closed, it fights that road's boss first, unless it
    lost to the boss at this level (`_lostAtLevel`).
- New `test/king_road_test.dart`: criteria 1-13, 19-21 (at the event level), 23 and 25.
- `test/pacing_test.dart`: unchanged, unless the owner accepts new ranges (criterion 27).

### M2: app
- `art/places.py` -> `art/places/road_lock.svg` -> `app/assets/images/places/road_lock.webp`
  (`scripts/export-art.ps1 -Only road_lock`): a flat lock in the Quiet Teal style (change 10).
- `lib/ui/world_tab.dart`:
  - `MapView` puts the lock on the middle of each road in `closedRoads` (changes 10, 12);
  - `_AreaSheet` shows "Beat the Graveyard King to cross." in place of Travel here when a closed road is what blocks
    the area (change 11).
- `lib/sync/away_summary.dart` and `lib/ui/labels.dart`: `RoadOpened` gives the line "The King falls. The road to Grey
  Moor is open." (change 13). The names come from data.
- `lib/ui/camp_tour.dart`: the new words of card 2 (change 15).
- Tests in `test/king_road_screens_test.dart`: criteria 14-17, 19, 22; `test/save_fixtures_test.dart`: criterion 24.
- `releases/next/feat-king-road-screens.md`: one line for players.

No save change in either milestone.

## Order of work

### M1: the closed road and the pace (one PR)
1. The tests: criteria 1-13, 19-21, 23, 25.
2. The code and the data.
3. The hand sims at 5,000 steps a day, seeds 1-16, with `main` and with the branch (a throwaway like
   `tool/seeds.dart`): the median day of level 30 and the median day of the first King kill (criterion 26).
4. **Proof:**
   - `.\scripts\check.ps1 -Release -Pacing` green, or the pacing test trips and Claude reports its numbers once
     (criterion 27).
   - The sim numbers in the PR description.
   - The verifier runs alongside the local check, before the PR.
   - Review per `REVIEW.md`; the owner merges. If the pacing test trips, the owner decides before the merge: widen the
     range or tune.

Branch `feat/king-road`. No line in `releases/next/`: M1 alone already closes the road for players, so the line comes
with M2. Until M2 merges, Grey Moor's sheet says "No open road leads here" (today's words for an area with no route)
and shows no Travel here button. A fight button there refuses with "Beat the Graveyard King to cross.".

### M2: the lock, the sheet, the report line and the tour (one PR)
1. The lock picture: drawn, exported, shown to the owner as a render before it goes on the map.
2. The tests: criteria 14-17, 19, 22, 24.
3. The code.
4. **Proof:**
   - Renders at 408 dp wide and at text size 2.0: the World map with the lock, Grey Moor's sheet (criterion 18). The
     PR says what a player sees there (`CLAUDE.md`).
   - `.\scripts\check.ps1 -Release` green.
   - The verifier checks criteria 1-28, alongside the local check, before the PR.
   - Review per `REVIEW.md`; the owner merges.

Branch `feat/king-road-screens`.

## Risks
- **Small.** The gate is one boss kill. The fighter walker of `pacing_test.dart` gets the same habit as the mixed
  walker. If a seed has trouble with the King, M1 fixes it in the PR (owner, 2026-11-07: "we will deal with it").
