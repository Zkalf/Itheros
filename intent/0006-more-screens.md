# Intent: More screens

Status: accepted
Product owner: Zkalf
Date: 2026-10-19

## Problem
The game has outgrown its three tabs. Adventure holds the status, "Next goal", discoveries, the queue, every area's
monsters and veins, all recipes and travel in one long scroll; Character mixes settings, equipment and inventory.
Playtest (owner): "more screens so the few we have are not so bloated", "a better overview", "we really need a map",
"merit in a current activity screen", "crafting should have a dedicated screen".

## Proposed outcome
The bottom bar gets five screens; the journal stays a button at the top.

1. **Now:** what the player is doing right now, the queue, steps banked and today's steps, test walk buttons.
   - While fighting: the player's and the monster's health bars, updating as steps arrive, and the last few rounds
     ("You hit for 6 · Skeleton hits for 3").
   - A running tally for the current activity ("7 won, 1 lost · 2 Bone, 0 Bone sword"; for crafts, the items made
     with their quality colours). It resets when a new activity starts.
2. **Map:** areas drawn as places joined by paths with their step costs. Tapping an area shows its flavour, its
   monsters (level colours as today) and veins, and lets the player fight, gather or travel from there.
   - **Fog** (owner's choice): before level 10, the lands beyond the river are covered in mist and named "???".
     Reaching level 10 lifts the fog.
   - **Loot found so far** (owner's choice): each monster lists only the drops the player has found ("Drops: Bone,
     Bone sword, ??? · 2 of 3 found"). Chances stay hidden. A drop counts as found the first time the player gets it,
     whatever its quality.
3. **Craft:** recipes with the materials the player has against what each needs, and where the nearest forge is.
   - **Craft until a quality** (owner's choice): a new stop choice, "until Rare or better" (or Epic, Legendary).
     Crafting continues until an item of that quality or better is made, or the materials run out. It sits beside the
     existing stop choices and follows the same queue rules.
4. **Character:** equipment and inventory, the inventory split under **Gear** and **Materials** headings, and the
   settings.
5. **Achievements**, as today.

## Affected users and systems
All players. The screens and navigation; game rules for the new stop choice; the save (drops found per monster, the
current activity's tally, the last few fight rounds).

## Constraints
- No change to pacing, chances or rewards. The new stop choice only automates crafting the player could already do.
- Existing saves: drops count as found for gear and materials the player owns or wears now.
- The map works on a phone screen without zooming to read it; the drawing can be simple.
- The order of the screens is a starting layout and may change after playtests.
- Out of scope: selling or breaking down gear (later; the Craft screen is its natural home), "Next goal" as people
  in camp (parked), new areas or content.

## Open questions
None blocking. Screen layout details are settled in the spec and on the phone.
