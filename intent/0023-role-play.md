# Intent: Role-play: the hero's story, the regions and their people

Status: draft
Product owner: Zkalf (chose on 2026-11-17: role-play first, quests after it; all four parts below; the player reads
and listens, with no choices; the Young Dragon as the main threat; one new person for each region with monsters;
flat SVG pictures by Claude until nabriis draws the real art; the south of the river first; an achievement for a
region's full lore)
Date: 2026-11-17
Issue: #274

## Problem
The game has pieces of role-play today:
- Six teachers at Camp. Each has a greeting, a kin line for a hero of the same origin, and tips (spec 0010).
- Odda, the quartermaster, shows a new player around Camp (spec 0022).
- Ysolde, the trainer, resets the talents (spec 0015).
- An origin with one line, picked on a new game (spec 0012).
- One flavour line for each place and each monster. The story card shows them on the first visit (spec 0008).
- Lore notes from monsters, kept in the Lore tab (spec 0009 §7.2).
- Messages in a bottle at the waters (spec 0011).

These pieces stand alone:
- No story ties them together.
- The player does not learn why the hero is here or what the Guild wants.
- A region has one line, not a history.
- The people stay at Camp. Out in the world, nobody lives or speaks.

`docs/game-direction.md` takes the feel of the world from World of Warcraft: NPCs and flavour. Today the world feels
like a map of spots, not a place with people. Quests (#274) also need people to give them and a reason to care.

## Proposed outcome

### The hero's story
1. One story ties the game together: why the hero came to the Guild, and what threatens the lands.
2. The threat is the Young Dragon. It wakes on Dragon's Peak ("Something big sleeps at the top").
3. Each boss is one chapter of the story on the way to the Young Dragon. The Graveyard King is the first chapter.
4. The story moves on with the hero's deeds, such as the first kill of each boss.
5. The origin matters after the start. Now and then, a person speaks to the hero's origin, as the kin lines do today.
6. People react to what the hero did. After the first King kill, for example, Camp talks about it.

### A story for each region
7. Each region with monsters has a short story: what happened there, who lives there and what threatens it.
8. The player learns a region's story in parts: on the first visit, at the first boss kill and as they go deeper.

### People with a voice
9. A small cast of named people:
   - the people at Camp today: the six teachers, Odda and Ysolde
   - one new person for each region with monsters, for example at the Guild outposts in Grey Moor and Mountain Pass
10. The world has six regions with monsters, so the whole world gets six new people.
11. Each person has a picture and a card, so the player can tell them apart.
12. A person's lines change as the hero's story moves on.
13. Each new person has a place in a region, so a later quest (#274) can use them.

### Where the player meets a person
14. A person shows as a row under Here at their place, as the teachers do at Camp today (spec 0010 §6.1).
15. The row has the person's picture and name.
16. A dot on the row shows that the person has a new line, as the dot of a waiting tip does today.
17. A tap on the row opens the person's card with their lines.

### Lore to collect
18. More kinds of lore than the monster notes: pages of a region's story and memories of its people.
19. The hero finds lore while they walk: at places, from bosses and in messages in a bottle.
20. The Lore tab keeps all lore, grouped by region, with "found N of M".
21. All the lore of one region gives an achievement, one for each region.

### Read and listen
22. The player makes no choices. The story moves on with the hero's deeds, and the player reads it.

### The first build
23. The first build covers the south of the river: Camp, Goblin Woods, Copper Hills, Old Graveyard, Mirror Lake and
    Smugglers' Cove.
24. Goblin Woods and Old Graveyard are the regions with monsters in the south, so the first build has two new people.
25. The first chapter of the story ends with the first kill of the Graveyard King. That kill opens the road across the
    river (intent 0022).
26. The regions north of the river follow later, mostly as data.

## Affected users and systems
- **Players:** every player, new saves and old saves.
- **Data:** new people, lines and lore in `data/*.json`. The world's words stay in data, not in code.
- **game_core:** rules for when a line or a lore page shows: a first visit, a first boss kill, a kill count or a
  level. The save keeps the lore found. Kill counts and explored places exist already.
- **App:**
  - the card of a person
  - the row of a person under Here
  - the Lore tab with groups by region
  - the story card, with more than one part
- **Achievements:** one new achievement for each region's full lore (spec 0017).
- **Art:** a picture for each person. Claude draws them as flat SVG. Later, nabriis draws the real art and replaces
  them.
- **Old saves:** a save with past deeds (a King kill, explored places) gets the story parts of those deeds on load.
  No old save loses a lore note.

## Constraints
- **The pace does not move.** Role-play gives no XP, gold or items. Monster lore notes keep their use: they reveal a
  monster's weakness (spec 0009 decision 3). The spec has no sim targets; the pacing test in `check.ps1` is the guard.
- **Read and listen only.** No choices, no branches and no dialogue trees.
- **The words are a design decision.** The spec writes the lines, and the owner accepts them with the spec. The lines
  keep their own voice (`WRITING.md`).
- **Small first build.** The south of the river first (outcomes 23-26). More regions follow as data.
- **Art.** Flat SVG pictures that Claude draws, as the icons today (`CLAUDE.md`). So no art comes in under a new
  licence.
- **Influences:**
  - World of Warcraft: zone stories, townsfolk, people who react to the hero.
  - Heroes of Might and Magic 3: the look of the portraits, when nabriis draws the real art.
- **Out of scope:**
  - Quests: a second intent for #274, after this one.
  - Voices and sound.
  - Cut scenes.
  - Choices.

## Open questions
The owner answered the first questions on 2026-11-17 (see the Product owner line). These stay for the spec:
1. **The story in words.** The spec writes the story of the first chapter, the lines of each person and the lore
   pages. The owner accepts the words with the spec.
2. **The two new people.** Their names, their places and their parts in the story. The spec checks the names against
   `data/*.json`, so no two people share a name (spec 0022 decision 3).
3. **A place with no monsters.** Copper Hills, Mirror Lake and Smugglers' Cove get lore but no new person. The spec
   can add a person to one of them, if the south feels empty with only two.
4. **What a story part needs.** Which deeds move the story on: a first visit, a first boss kill, a kill count or a
   level. The spec picks the simplest set.

## History
- 2026-11-17, #274: first version, with the owner's answers to the first open questions. (draft)
