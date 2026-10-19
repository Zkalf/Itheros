# Spec 0006: More screens

Status: accepted
Intent: [intent/0006-more-screens.md](../intent/0006-more-screens.md) (accepted, commit 863ab8c)
Builds on: spec 0002 §9 (guidance, map at level 10), spec 0003 (queue, stop conditions), spec 0004 (journal, test
walk), spec 0005 (qualities)
Product owner: Zkalf
Date: 2026-10-19

## 1. Decisions
The intent settled the feel. These are the details it left open, decided for the build.

| # | Question | Decision |
|---|---|---|
| 1 | Bottom bar | Now · Map · Craft · Character · Achievements. The app opens on Now. The journal stays the book button in the top bar of every screen. |
| 2 | Which areas are fogged? | Every area above the player's level, wherever it is. Today those are the lands beyond the river (level 10); Copper Hills (2) and Old Graveyard (6) are fogged for a new player the same way. |
| 3 | What a fogged area shows | "???" on the map, and on tap only "Thick fog. The Guild opens this road at level N." No name, flavour, monsters or veins. Paths to it are drawn dashed. |
| 4 | Map positions | Each area has a position in `world.json` (`map: {x, y}`, 0–1), plus the river as a line of points. No numbers in code. |
| 5 | "Found" drops | A drop counts as found for a monster the first time it drops for the player from that monster, any quality. Stored as counters `found.<monster>.<item>`. Bosses' unique items count the same way. |
| 6 | Existing saves | On load, a drop counts as found if the player has killed that monster at least once and owns or wears that item now. |
| 7 | The tally | Per running action: fights won and lost, and every item it gained (drops, ore, crafted gear by quality). It starts empty when the action starts, so each queued action has its own. It is saved, so it survives closing the app. |
| 8 | The fight log | The last 4 rounds (`fightLogRounds` in `economy.json`) of the running fight action, across fights: "Round 3 · You hit for 6 · Skeleton hits for 3", "Skeleton is beaten", "You are beaten". Saved with the action. |
| 9 | "Until a quality" | A crafting stop condition: "until Uncommon / Rare / Epic / Legendary or better". It stops when this action crafts an item of that quality or better. Opens at level 5 with the other count conditions (spec 0003). Running out of materials still ends it, as today. |
| 10 | Today's steps | The Health Connect total for today that the game has read, as on the step sync. Test-walk steps are not included. |

## 2. Screens
### 2.1 Now
Top to bottom: step-sync problem (if any); location, level, XP bar, step bank, "Walked today: 6,214"; test walk (if
on); Next goal; discoveries; the running action; the queue.
- **The running action:** its name, stop condition and Stop button, the progress bar for the next unit (as today).
  - Fights: both health bars, then the fight log (decision 8).
  - The tally (decision 7): "7 won · 1 lost" for fights, then gains as "Bone ×5, Bone sword ×1, Bone sword (Rare)
    ×1", names in quality colours. Nothing is shown for travel or before the first gain.
- **Resting:** "Resting. Your steps go to the step bank." and a button to the Map.

### 2.2 Map
- Areas are drawn at their positions, joined by their routes with the step cost on each path; the river is drawn
  as a line. The player's area is marked. The map fits the phone's width and scrolls up and down if needed.
- **Tap an open area:** a sheet with its name, distance ("here" / "800 steps away"), flavour, monsters (level
  badge, stats, XP, "Drops: Bone, Bone sword, ??? · 2 of 3 found") and veins. Tapping a monster or vein works as
  today (deadly warning, stop condition, start now or queue). A "Travel here" button unless the player is there.
- **Tap a fogged area:** decision 3.
- The level-up screen's "the map opens" line (level 10) is unchanged; the fog lifting is the map itself.

### 2.3 Craft
- A line saying where crafting happens: "At the forge (Camp)" or "Nearest forge: Camp · 400 steps away".
- Every unlocked recipe: its item and what it gives ("+5 Attack · Weapon"), each input as "Bone 5/3" (owned/needed,
  short in red), steps and XP. Tap: as today, with "Until a quality" among the stop choices from level 5.

### 2.4 Character
Equipment as today; the inventory under two headings, **Gear** then **Materials**, each in today's order; the
settings (Show "Next goal", test walk) at the bottom.

### 2.5 Achievements
Unchanged.

## 3. Out of scope
Selling or breaking down gear, camp people for "Next goal", new areas or content, any change to chances, XP or
pacing, zooming or panning the map sideways.

## 4. Acceptance criteria
1. The bottom bar has Now, Map, Craft, Character, Achievements; the app opens on Now; the journal opens from each.
2. Every action the old Adventure tab offered (fight, gather, craft, travel, stop, remove from queue) can still be
   done, from Now, Map or Craft.
3. The fight log shows the last `fightLogRounds` rounds with the damage each side dealt, and who was beaten.
4. The tally counts wins, losses and every item the running action gained, with quality; a new action starts at
   zero; closing and reopening the app keeps it.
5. Areas above the player's level show "???" and the level they open at, nothing else; at that level they show in
   full. Paths to fogged areas are dashed.
6. A monster lists only its found drops plus "???" for each one not found, and "N of M found"; no chances anywhere.
7. A drop is found the first time it drops from that monster; an existing save counts found drops by decision 6.
8. "Until Rare or better" ends the craft on the first item of rare or better, and not before; out of materials it
   ends as today.
9. The Craft screen shows owned/needed for each input and where the nearest forge is.
10. The inventory shows Gear and Materials headings.
11. Map positions and the river come from `world.json`; the fight log length from `economy.json`.
12. An existing save loads with nothing lost; pacing tests stay green.
13. `.\scripts\check.ps1 -Release` is green, with no INTERNET permission.
