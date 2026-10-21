# Intent: Lake and hunt

Status: accepted
Product owner: Zkalf
Date: 2026-10-21

## Problem
Intent 0010 builds the profession system with Mining, Woodcutting and Crafting. The world still lacks the gentler,
RP-rich trades of a classic RPG: fishing at a lake, tracking game in the woods, and cooking what you bring home.
Owner: fish should be both crafting material and food, and "cooking will be a core mechanic as well".

This intent adds **Fishing**, **Hunting** and **Cooking** on the profession system from intent 0010 (own levels, tiers,
a tool each, a teacher in camp, about a quarter of the character XP per step).

## Proposed outcome
1. **Fishing at the lake.** A new lake area on the map. Fishing works like mining (steps per cast), but each catch is
   rolled from the lake's fish list, from common fish to rare and trophy fish (rough feel: three quarters common,
   well under 1% trophy). Better lakes and fish open with fishing level.
   - **Catch weight:** every fish also rolls a weight. The heaviest catch of each species is kept as a record, shown
     on the Professions screen and noted in the journal when beaten.
   - **Message in a bottle:** a very rare catch (around 1 in 2,000 casts) that leads to a hidden map spot or a unique
     item. A pure Diablo 2 style chase.
   - Fish go to Cooking; scales go to Crafting (scale armour).
2. **Hunting in the wild.** Hunting tracks animals; there is no health-bar fight. It works like gathering: steps per
   hunt, each catch rolled from the area's animals (deer, boar, wolf, and rare ones such as a white stag). Meat goes
   to Cooking, hides to Crafting, and rare trophies (a golden antler) to special recipes.
3. **Cooking at the camp fire.** In camp, Now offers the fire. Recipes turn fish and meat into **meals**:
   - One meal is active at a time and lasts a number of steps (about a solid walk, for example 3,000 steps).
   - Meals give a buff while they last: more health, more attack, cheaper gathering, and so on.
   - A cooked meal can roll as a **perfect dish**, stronger or longer lasting.
   - The player eats a meal from the bag, or picks one to **auto-eat** when the last one runs out: either until the
     meals run out, or **only N of them**, so the rest are saved for later (like the queue's "until N" choice).
   - No permanent bonuses from food; those may come later from other things.
4. **Tools:** rod, bow and cooking pot, crafted and rolling quality like the tools in intent 0010.
5. **Teachers in camp from level 1:** the fisherman, the hunter and the cook. Each teaches the profession and gives a
   Common starter tool with a line of RP. The fisherman: "Take my old rod. Bring me back some fish." The hunter also
   shares monster tips for the bestiary (intent 0009).

## Affected users and systems
All players. Game rules (fishing and hunting rolls, catch weights and records, the bottle, cooking, meals and their
buffs, perfect dishes, auto-eat), `data/*.json` (the lake and other spots, fish, animals, recipes, meals, tools,
chances), the map (new lake area), the save (three new professions, records, active meal, chosen auto-eat meal), Now
(the fire and NPCs in camp), the Professions screen, and the journal.

## Constraints
- **Balance for ~5,000 steps a day**, on the same sim as intent 0010: a mix stays the fastest way to grow; meals help
  without becoming a must. Pacing tests stay green.
- **Diablo-style rarity:** trophy fish, rare animals and the bottle stay low-chance; level and tool bonuses to them
  stay very minor.
- Existing saves load. The three new professions start at level 1 (character origins come with intent 0012).
- Clean UI (intent 0008): fishing and hunting start from Now at their place; cooking from Now at the camp fire;
  records and progress on the Professions screen.
- Out of scope: the fisherman's "bring fish back" as a real quest (quests are a later system); character origins
  (0012); permanent food bonuses.

## Open questions
None blocking. Exact numbers (fish and animal chances, weights, meal buffs and length, perfect dish chance, bottle
reward) are settled in the spec with the sim.
