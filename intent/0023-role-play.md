# Intent: Role-play: the hero's story, the regions and their people

Status: draft
Product owner: Zkalf (chose on 2026-11-17: role-play first, quests after it; all four parts below; the player reads
and listens, with no choices)
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
2. The story moves on with the hero's deeds, such as the first kill of each boss.
3. The origin matters after the start. Now and then, a person speaks to the hero's origin, as the kin lines do today.
4. People react to what the hero did. After the first King kill, for example, Camp talks about it.

### A story for each region
5. Each region with monsters has a short story: what happened there, who lives there and what threatens it.
6. The player learns a region's story in parts: on the first visit, at the first boss kill and as they go deeper.

### People with a voice
7. A small cast of named people:
   - the people at Camp today: the six teachers, Odda and Ysolde
   - a few new people out in the world, for example at the Guild outposts in Grey Moor and Mountain Pass
8. Each person has a picture and a card, so the player can tell them apart.
9. A person's lines change as the hero's story moves on.
10. Each new person has a place in a region, so a later quest (#274) can use them.

### Lore to collect
11. More kinds of lore than the monster notes: pages of a region's story and memories of its people.
12. The hero finds lore while they walk: at places, from bosses and in messages in a bottle.
13. The Lore tab keeps all lore, grouped by region, with "found N of M".

### Read and listen
14. The player makes no choices. The story moves on with the hero's deeds, and the player reads it.

## Affected users and systems
- **Players:** every player, new saves and old saves.
- **Data:** new people, lines and lore in `data/*.json`. The world's words stay in data, not in code.
- **game_core:** rules for when a line or a lore page shows: a first visit, a first boss kill, a kill count or a
  level. The save keeps the lore found. Kill counts and explored places exist already.
- **App:**
  - the card of a person
  - the place where the player meets a person (Now, Here or Camp)
  - the Lore tab with groups by region
  - the story card, with more than one part
- **Art:** a picture for each person (see open question 3).
- **Old saves:** a save with past deeds (a King kill, explored places) gets the story parts of those deeds on load.
  No old save loses a lore note.

## Constraints
- **The pace does not move.** Role-play gives no XP, gold or items. Monster lore notes keep their use: they reveal a
  monster's weakness (spec 0009 decision 3). The spec has no sim targets; the pacing test in `check.ps1` is the guard.
- **Read and listen only.** No choices, no branches and no dialogue trees.
- **The words are a design decision.** The spec writes the lines, and the owner accepts them with the spec. The lines
  keep their own voice (`WRITING.md`).
- **Small first build.** The spec picks the regions of the first build. More regions follow as data.
- **Influences:**
  - World of Warcraft: zone stories, townsfolk, people who react to the hero.
  - Heroes of Might and Magic 3: the look of the portraits.
- **Out of scope:**
  - Quests: a second intent for #274, after this one.
  - Voices and sound.
  - Cut scenes.
  - Choices.

## Open questions
1. **The main story.** What threatens the lands, and what does the Guild want? Recommendation: the Young Dragon wakes
   on Dragon's Peak ("Something big sleeps at the top"), and each boss is one chapter on the way to it. Claude can
   offer two or three short stories to choose from.
2. **The new people.** How many in the first build? Recommendation: one for each region with monsters, so about five
   people.
3. **The pictures of the people.** Today Claude draws flat SVG icons (`CLAUDE.md`). A portrait in the look of Heroes 3
   is more than an icon. Does Claude draw them in the flat SVG style, or does the project need other art? #198 and the
   licence rule apply.
4. **Where the player meets a person.** On the Now tab under Here, on the World map, or on a list of people at a place?
5. **The first build.** Only the south of the river (Camp, Goblin Woods, Copper Hills, Old Graveyard, Mirror Lake
   and Smugglers' Cove), or the whole world?
6. **Lore and achievements.** Does a full set of a region's lore give an achievement?

## History
- 2026-11-17, #274: first version. (draft)
