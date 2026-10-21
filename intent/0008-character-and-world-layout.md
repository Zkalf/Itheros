# Intent: Character and world layout

Status: accepted
Product owner: Zkalf
Date: 2026-10-21

## Problem
The game is about to grow a lot: professions, deeper fights, camp NPCs, a bestiary (intents 0009-0012). Today's
screens can't carry that. Equipment and inventory are a list, the bottom bar is organised by feature (Map, Craft)
rather than by where things happen, and levels gate gear slots, queue slots and the map in a way that feels forced.
Owner: "the UI should feel easy and intuitive"; "I have played many RPGs where [a confusing UI] is a big problem";
NPCs and slots appearing "after a level would feel random or forced".

This intent is the base the next four build on: a clean layout, a classic RPG character screen, and no level gates.

## Proposed outcome
1. **Four bottom buttons**, each answering one plain question. Deeper options live inside them. A fifth button may
   come later if the game grows many more systems.
   - **Now**: what am I doing, and what can I do here? The running activity, the queue, live fight bars, steps
     banked, and everything the player's current place offers: in an area its monsters and gathering spots, in camp
     the forge (and from 0010 the NPCs, from 0011 the cooking fire). There is no separate Camp screen.
   - **World**: where can I go? The map and travel. Tapping an area shows what is there.
   - **Professions**: what am I good at? Crafting and its recipes now (moved from today's Craft screen). From 0010
     each profession's level, tier and tool, and where to practise it, with a way to go there.
   - **Character**: who am I? Small tabs inside: **Gear** and **Bag** now, **Talents** later.
   - The top bar keeps **Journal** and **Trophies**, plus settings.
2. **Classic equipment view (paper doll).** Slots around the character: Head, Neck, Shoulder, Cloak, Chest, Bracer,
   Gloves, Belt, Legs, Boots, two Rings, two Trinkets, and Main hand + Off hand (shield), or one two-handed weapon
   that fills both hands. Empty slots show a faint outline, so the player sees what can still be found.
3. **One big bag** shown as a grid of slots. Stacks show a count. Gear and materials have different icons, so
   Common gear doesn't look like a material. Space is unlimited for now; a cap comes later.
4. **Item detail card.** Tapping any item, in the bag or on the doll, opens a card with the name in its quality
   colour, the quality and type in words ("Rare one-hand sword"), its stats, a comparison with what is worn in that
   slot, and **Equip** / **Swap**. Equipping a two-hander moves the shield to the bag.
5. **No "(Rare)" in names.** Item names show in their quality colour only ("Bone sword" in blue). The quality word
   appears on the detail card and in reports and the journal, so colour is never the only signal.
6. **No level gates except talents.** Every gear slot and all three queue slots are open from level 1. Talents stay a
   reward for levelling. Monster difficulty, materials and (from 0010) profession levels hold players back instead.
7. **Fog lifts by exploring.** Instead of lifting at level 10, the mist over an area clears when the player reaches
   a neighbouring area.

## Affected users and systems
All players, existing and new. The screens and navigation (Now, World, Professions, Character, the top bar); game rules for
equipment slots, two-handed weapons, queue slots and fog; the save (new slots, explored areas); `data/*.json` (item
slots and types). It replaces the level ladder from spec 0002 (gear slot at L7, queue slots at L5/L8, map fog until
L10, Craft tab after the first recipe) through a new spec, since accepted specs are not edited.

## Constraints
- **Clean and intuitive first.** Every screen should be readable at a glance on a phone. When in doubt, fewer options
  per screen and one more tap.
- Existing saves load: today's gear moves to its matching slot (the Hide vest to Chest, weapons to Main hand), the
  inventory moves to the bag, and areas already visited count as explored.
- No change to steps, XP, chances or rewards. Opening slots earlier adds no new items; most new slots stay empty
  until later intents and content fill them. Pacing tests stay green.
- No art budget: the paper doll uses simple icons and outlines, not a drawn character.
- Out of scope: professions, NPCs, cooking (0010, 0011); hit/miss, affixes, armour types, bestiary (0009); character
  creation (0012); bag cap, loadouts, quests (later).

## Open questions
None blocking. The look of the doll and the bag grid is settled in the spec and on the phone.
