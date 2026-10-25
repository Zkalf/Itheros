# Spec 0014 amendment 2: names on the map stay next to their place

Status: accepted
Amends: [spec 0014](0014-quiet-teal.md) §2.3 (the ring: names and step plates) and criterion 18
Fixes: issue #68 (map labels move when Smugglers' Cove shows on the map)
Product owner: Zkalf (chose the look from test renders on 2026-10-25)
Date: 2026-10-25

## Why
- The bottle reveals Smugglers' Cove. The code then places all names and step plates again, and some names jump.
- After the jump, the name "Mirror Lake" stands under the marker of Camp. It reads as the name of Camp.
- In another placement, the road from Camp to Copper Hills runs through the middle of "Mirror Lake".
- Today's rules allow both. A name only has to lie within 8 dp of its own marker and overlap no marker, plate or
  name. Nothing keeps a name away from other markers or from roads.
- A place in the fog shows the name "???". When the player explores it, its real name is longer, and names jump too.
- The Camp marker covers the camp that the map picture shows (tents and a campfire).

## Change
1. **Own marker:** the marker nearest to the middle of a name is the marker of its own place.
2. **Roads:** a road can cross the edge of a name. The distance from the middle of a name to each road with a step
   plate is at least half the height of the name.
3. The rules of §2.3 stay:
   - Nothing on the map overlaps: no two names, step plates or markers.
   - Each name lies inside the map, at most 8 dp from its marker.
   - Each step plate lies on its road.
4. **Name size:** the names on the map are 13 dp, not 14 dp. They keep their font (Cormorant Garamond 600) and
   their colours.
5. **Places on the map** (`map` in `packages/game_core/data/world.json`, parts of the width and the height of the
   map):

   | Place | Today | New |
   |---|---|---|
   | Camp | x 0.5, y 0.92 | x 0.36, y 0.92 |
   | Mirror Lake | x 0.72, y 0.94 | x 0.72, y 0.89 |
   | Copper Hills | x 0.8, y 0.8 | x 0.84, y 0.76 |

   - Camp moves left, so the camp of the map picture shows to the right of its marker.
   - The roads keep their step counts. Rules, numbers and the save do not change.
6. **Room for each place:** the World map keeps room for each place and each road, also when the place is hidden
   or in the fog:
   - The placement uses the real name of each place and the step count of each road.
   - The map draws only what it draws today: no hidden place, no hidden road, and no step count on a road into
     the fog.
   - A name in the fog ("???") stands inside the room of the real name, as near to its marker as it can.
   - Thus no name moves when the bottle reveals Smugglers' Cove or when a place leaves the fog.
7. The rules of changes 1 to 4 also apply to the strip of the route map. The strip shows only the places of its
   route, so change 6 does not apply to it.

## Acceptance criteria
**Placement**
1. At 360 dp, for each of the 12 places as the current place, the marker nearest to the middle of each name is the
   marker of its own place.
2. At 360 dp, for each current place, the distance from the middle of each name to each road with a step plate is at
   least half the height of the name.
3. At 360 dp, for each current place, criterion 18 of spec 0014 still holds: nothing overlaps, and each name stays
   inside the map.
4. The names on the map are 13 dp.

**Names do not move**
5. At 360 dp, with Camp as the current place, each name has the same rect before and after the bottle reveals
   Smugglers' Cove.
6. At 360 dp, with Camp as the current place, the "???" name of a place in the fog lies inside the rect that its
   real name has when the place leaves the fog.
7. At 360 dp, the World map draws no hidden place, no road to a hidden place, and no step count on a road into the
   fog.

**Places**
8. Camp, Mirror Lake and Copper Hills have the map points of the table in change 5.
9. Each other place keeps its map point.

**Check and release**
10. Rules, numbers and the save do not change. The pacing test passes.
11. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
