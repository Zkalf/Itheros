# Spec 0006: More screens

Status: accepted
Intent: [intent/0006-more-screens.md](../intent/0006-more-screens.md) (accepted, commit 863ab8c)
Builds on: spec 0002 §9 (guidance, map at level 10), spec 0003 (queue, stop conditions), spec 0004 (journal, test
walk), spec 0005 (qualities)
Product owner: Zkalf
Date: 2026-10-19

Spec 0008 replaced most screens of this spec: the bars, the fog, the resting card, Map, Craft and Character. Each
part says where.

## 1. Decisions
The intent settled the feel. These are the details it left open, decided for the build.

| # | Question | Decision |
|---|---|---|
| 1 | Bottom bar | Now · Map · Craft · Character. The app opens on Now. **Craft is hidden until the first recipe opens** (level 3): spec 0001 criterion 8 hid locked systems, and an empty Craft tab at levels 1–2 would be one. The journal stays the book button in the top bar of every screen. **A trophy button** sits next to it on every screen and opens the Achievements screen as its own page with a back arrow, like the journal (owner, 2026-10-20: each tab gets more room). When an achievement is earned that the player has not looked at yet, the trophy button shows a small dot until the Achievements screen is opened. Since spec 0008 §3.1 the bottom bar has Now · World · Professions · Character at all times, and the top bar holds the Journal, Trophies and Settings buttons; later specs add more (spec 0008 §3.1). |
| 2 | Which areas are fogged? | Every area above the player's level, wherever it is. At first those were the lands beyond the river (level 10); Copper Hills (2) and Old Graveyard (6) were fogged for a new player the same way. Since spec 0008 decision 5 fog lifts by exploring, not by level. |
| 3 | What a fogged area shows | "???" on the map, and on tap only "Thick fog. The Guild opens this road at level N." No name, flavour, monsters or veins. Paths to it are drawn dashed. Since spec 0008 §3.3 the tap reads "Thick fog. Walk to a neighbouring area to see what's there." |
| 4 | Map positions | Each area has a position in `world.json` (`map: {x, y}`, 0–1), plus the river as a line of points. No numbers in code. Since spec 0014 the map is a picture with its own river, and the river points left the data. |
| 5 | "Found" drops | A drop counts as found for a monster the first time it drops for the player from that monster, any quality. Stored as counters `found.<monster>.<item>`. Bosses' unique items count the same way. |
| 6 | Existing saves | On load, a drop counts as found if the player has killed that monster at least once and owns or wears that item now. |
| 7 | The tally | Per running action: fights won and lost, and every item it gained (drops, ore, crafted gear by quality). It starts empty when the action starts, so each queued action has its own. It is saved, so it survives closing the app. |
| 8 | The fight log | The last `fightLogRounds` rounds (`economy.json`: 50 since spec 0019; first 4) of the running fight action, across fights: "Round 3 · You hit for 6 · Skeleton hits for 3", "Skeleton is beaten", "You are beaten". Saved with the action. Since spec 0009 §8.1 each line names what happened in the round, and since spec 0019 a sheet holds the last fights and the rounds of the latest one. |
| 9 | "Until a quality" | A crafting stop condition: "until Uncommon / Rare / Epic / Legendary or better". It stops when this action crafts an item of that quality or better. It opened at level 5 with the other count conditions (spec 0003); since spec 0008 decision 7 it is offered from level 1. Running out of materials still ends it, as before. |
| 10 | Today's steps | The Health Connect total for today that the game has read, as on the step sync. Test-walk steps are not included. |

## 2. Screens
### 2.1 Now
Top to bottom: step-sync problem (if any); location, level, XP bar, step bank, "Walked today: 6,214"; test walk (if
on); Next goal; discoveries; the running action; the queue. Spec 0008 §3.2 gives the order of Now since then.
- **The running action:** its name, stop condition and Stop button, the progress bar for the next unit (as before).
  - Fights: both health bars, then the fight log (decision 8).
  - The tally (decision 7): "7 won · 1 lost" for fights, then gains as "Bone ×5, Bone sword (Common) ×1, Bone sword
    (Rare) ×1", names in quality colours. Nothing is shown for travel or before the first gain.
- **Resting:** "Resting. Your steps go to the step bank. Pick something to do on the Map or Craft screen." with an
  **Open the map** button and, from the first recipe, an **Open Craft** button next to it (owner, 2026-10-20: the
  text already points to both screens). Before the first recipe the card shows only the map button and says "Pick
  something to do on the Map." Since spec 0008 §3.2 the card has one button, **Open the World map**.

### 2.2 Map
- Areas are drawn at their positions, joined by their routes with the step cost on each path; the river is drawn
  as a line. The player's area is marked. The map fits the phone's width and scrolls up and down if needed.
- **Tap an open area:** a sheet with its name, distance ("You are here" / "800 steps away"), flavour, monsters (level
  badge, stats, XP, "Drops: Bone, Bone sword, ??? · 2 of 3 found") and veins. Tapping a monster or vein works as
  before (deadly warning, stop condition, start now or queue). A "Travel here" button unless the player is there;
  since spec 0016 §7.4 it reads "Walk here".
- **Tap a fogged area:** decision 3.
- The level-up screen's "the map opens" line (level 10) is unchanged; the fog lifting is the map itself.
- Since spec 0008 §3.3 this screen is the World map, and its area sheet keeps these rules.

### 2.3 Craft
- A line saying where crafting happens: "At the forge (Camp)" or "Nearest forge: Camp · 400 steps away".
- Every unlocked recipe: its item and what it gives ("+5 Attack · Weapon"), each input as "Bone 5/3" (owned/needed,
  short in red), steps and XP. Tap: as before, with "Until a quality" among the stop choices from level 5.
- Since spec 0008 §3.4 and spec 0010 the recipes stand on the Crafting screen of the Professions tab.

### 2.4 Character
Equipment as before; the inventory under two headings, **Gear** then **Materials**, each in the order it had before; the
settings (Show "Next goal", test walk) at the bottom. Since spec 0008 §3.5 the Character screen has the gear slots
and a bag grid, and since spec 0008 decision 12 the settings have a page of their own.

### 2.5 Achievements
Unchanged. Spec 0017 rebuilt it later.

## 3. Out of scope
Selling or breaking down gear, camp people for "Next goal", new areas or content, any change to chances, XP or
pacing, zooming or panning the map sideways. Spec 0010 added salvage later.

## 4. Acceptance criteria
1. The bottom bar has Now, Map, Craft (from the first recipe) and Character; the app opens on Now; the journal and
   the achievements open from top-bar buttons on each screen; a dot on the trophy button marks an achievement earned
   since the screen was last opened. Since spec 0008 criterion 1 the bottom bar has Now, World, Professions and
   Character at every level.
2. Every action the old Adventure tab offered (fight, gather, craft, travel, stop, remove from queue) can still be
   done, from Now, Map or Craft.
3. The fight log shows the last `fightLogRounds` rounds with the damage each side dealt, and who was beaten. Spec
   0019 criteria hold the fight log since then.
4. The tally counts wins, losses and every item the running action gained, with quality; a new action starts at
   zero; closing and reopening the app keeps it.
5. Areas above the player's level show "???" and the level they open at, nothing else; at that level they show in
   full. Paths to fogged areas are dashed. Since spec 0008 criterion 5 fog lifts by exploring.
6. A monster lists only its found drops plus "???" for each one not found, and "N of M found"; no chances anywhere.
7. A drop is found the first time it drops from that monster; an existing save counts found drops by decision 6.
8. "Until Rare or better" ends the craft on the first item of rare or better, and not before; out of materials it
   ends as before.
9. The Craft screen shows owned/needed for each input and where the nearest forge is. Spec 0010 holds the Crafting
   screen since then.
10. The inventory shows Gear and Materials headings. Since spec 0008 criterion 8 the bag tells gear and materials
    apart by their look.
11. Map positions and the river come from `world.json`; the fight log length from `economy.json`. Since spec 0014
    the river is part of the map picture.
12. An existing save loads with nothing lost; pacing tests stay green.
13. `.\scripts\check.ps1 -Release` is green, with no INTERNET permission.

## History
- 2026-10-19: first version (intent 0006, plan 0007). Criteria 1-13.
- 2026-10-19, amendment 1: Craft appears with the first recipe; "Trophies" in the bottom bar; "You are here"; the
  resting card names both screens. Decision 1; §2.1; §2.2; criterion 1. Amendment 2 replaced its bottom bar.
- 2026-10-20, amendment 2: Achievements move to a trophy button at the top, with a dot. Decision 1; criterion 1.
- 2026-10-20, amendment 3: the resting card opens Craft too. §2.1. Spec 0008 replaced it.
- 2026-10-21, spec 0008: four buttons at the bottom; fog by exploring; the World map; Professions; the bag grid; the
  Settings page; every stop condition from level 1. Decisions 1-3 and 9; §2.1-2.4; criteria 1, 5, 9 and 10.
- 2026-10-21, spec 0009: each fight log line names what happened. Decision 8.
- 2026-10-21, spec 0010: the Crafting screen; salvage. §2.3; §3; criterion 9.
- 2026-10-22, spec 0014: the map is a picture with its own river. Decision 4; criterion 11.
- 2026-10-24, spec 0016 amendment 1: "Walk here". §2.2.
- 2026-10-24, spec 0017: the Achievements screen rebuilt. §2.5.
- 2026-11-01, spec 0019: the fight sheet; 50 rounds. Decision 8; criterion 3.
- 2026-11-15 (plan 0068): the amendments folded into this file. Decision 8 gives the 50 rounds of the data, with the
  first 4 beside them. The tally example names common gear "(Common)", as spec 0005 amendment 2 asked. "As today"
  now reads "as before". No rule or criterion changed. (draft)
