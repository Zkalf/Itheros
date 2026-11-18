# Intent: Role-play and quests, chapters 2 and 3: the north of the river

Status: draft
Product owner: Zkalf (chose on 2026-11-18: two chapters in one intent, the Chieftain ends chapter 2 and the Young
Dragon ends chapter 3; the story of the cage, with a Guild man as the buyer; one new person for each region with
monsters; about 17 quests for each chapter; Camp reacts to each boss; an end with a hook)
Date: 2026-11-18

## Problem
Chapter 1 covers the south of the river (spec 0023, spec 0024, released in 0.12.0). Past the river, the world is
silent:
- Grey Moor, Iron Ridge, Troll Bridge, Mountain Pass, Mithril Deep and Dragon's Peak have no people, no lore pages
  and no quests.
- The hero crosses the river at about level 10. The levels 11-30 take about 70-90 days at 5,000 steps a day, and no one
  in that part of the world asks the hero for anything.
- When the last quest of chapter 1 is done, the quest card says "No more work for now. The north will need you." It
  says so for the rest of the game.
- The story of chapter 1 leaves hooks that nothing follows up:
  - The goblins flee south from something up north (Pell, `pell_2`).
  - The King's last words: "It wakes. A hundred years I held it." (`page_kings_words`)
  - Jory Tarr ships crates to the Peak, paid in old gold (`jory_2`, `page_captains_log`). He sells the name of the
    buyer for a higher price (`jory_bass`).
  - The cove's manifest lists "One cage, large, iron, empty." (`page_manifest`)
- Specs 0023 and 0024 both say that the north comes later, mostly as data.

## Proposed outcome

### The story: the cage
1. The north has two chapters (owner). Each ends at the first kill of a boss, as chapter 1 ends at the King:
   - **Chapter 2:** Grey Moor, Iron Ridge and Troll Bridge. It ends at the first kill of the Ogre Chieftain.
   - **Chapter 3:** Mountain Pass, Mithril Deep and Dragon's Peak. It ends at the first kill of the Young Dragon.
2. The thread is **the cage** (owner, original): someone wants the Young Dragon caught alive, not killed.
   - Jory's crates and the iron cage go to that buyer.
   - The buyer pays in the King's old gold.
   - The buyer's work on the Peak woke the dragon fully. That is why everything flees south.
3. The buyer is **a Guild man**: the master of the Guild lodge at Mountain Pass (owner).
   - In chapter 3 he is a friendly quest giver at first.
   - The hero learns the truth before the Young Dragon falls.
   - The player makes no choice (spec 0023). The hero kills the dragon, and the buyer's plan fails.
4. The story ends with a hook (owner). The lands are safe, but a last page hints at more: the dragon was young, so
   where is its mother? It leaves room for a later chapter.
5. The story of each north place comes in parts, as in chapter 1: on the first visit, from finds, from a person's
   lines and at a boss kill.

### People
6. Four new people, one for each north region with monsters (owner), with a place, a portrait and lines:

| Place | Who (a role for the spec to name) |
|---|---|
| Grey Moor | The warden of the Guild outpost. Odda's word goes to this person ("Sent word north", `page_odda_ledger`). |
| Troll Bridge | Someone who lives by the toll. For example, a carter who hauls Jory's crates over the bridge. |
| Mountain Pass | The master of the Guild lodge: the buyer (outcome 3). |
| Dragon's Peak | Someone who watches the dragon, for example a grandchild of the dragon-hunter whose pages the hero finds. |

7. Iron Ridge and Mithril Deep get lore pages, but no person, as Copper Hills and Mirror Lake in chapter 1.
8. The people of chapter 1 react to the new deeds:
   - Odda gets lines for the new chapters.
   - Pell's goblins, Aldous's dead and Jory's crates get lines at the right points.
   - Jory sells his second secret: who pays for the crates.
9. Camp reacts to each boss (owner). Each teacher and Ysolde get a line after the first Chieftain kill and a line
   after the first Young Dragon kill, as their King lines today. The newest of these lines takes the place of the
   greeting.

### Quests
10. About 17 quests for each chapter (owner), so about 34 in all.
11. The quests use the tasks of today: kill, gather, craft, bring, wear and visit (spec 0024 §2.3).
12. Each chapter has a main line that leads the hero through its places to its boss. Side quests branch off it.
13. The givers are the new people, the people of chapter 1 and the teachers at Camp. The teachers send the hero to
    the north's spots and recipes: iron, ash, trout, mithril.
14. The tasks grow with the road: a side quest stays about a day of walking at the hero's level, as in chapter 1.
15. The reward stays XP and a supply chest (spec 0024 §2.4). The XP grows with the level of the quest.
16. The first quest of chapter 2 opens when chapter 1 ends (open question 1).
17. When the last quest of chapter 3 is done, the quest card shows the end words of the story, with the hook of
    outcome 4. "The north will need you" goes away.

### Lore
18. Each north place gets its lore pages, as the south did (spec 0023 §2.4).
19. Each north place gets its lore achievement: all its pages and notes found, +250 bank cap (spec 0023 §2.6).
20. The lore notes of the north's monsters stay as they are. The Lore tab counts them in their place, as today.

## Affected users and systems
- **Players:** every player, new saves and old saves.
- **Data (most of the work):**
  - `data/story.json`: the new people, their lines, the Camp lines and the lore pages;
  - `data/quests.json`: about 34 quests;
  - `data/achievements.json`: six lore achievements.
- **game_core, small changes where data does not fit today:**
  - Camp lines: a teacher or the trainer holds one line today, keyed by the teacher. Outcome 9 needs a line for each
    boss and the newest one on top.
  - The end words of the quest card are in code (`app/lib/ui/now_tab.dart`). Outcome 17 moves them into data.
- **App:** no new screen. The rows, sheets, marks, the quest card and the Lore tab work as they do today.
- **Art:** four portraits, flat SVG by Claude (`art/people.py`), until nabriis draws the real art.
- **Tests:** the data tests that count the quests, the people and the lore achievements change with the data.
- **Old saves:** a save with past deeds (a Chieftain kill, explored north places) gets the pages and lines of those
  deeds on load, as in chapter 1 (spec 0023 §4). No new save version is needed for data alone.

## Constraints
- **Data-only where the systems fit** (owner). The two code changes above are the only rule changes. They go in one
  small PR with the data, or before it.
- **The pace moves a little.** About 34 quests add XP and supply chests over the levels 11-30. The spec sets the XP
  and checks it by hand with the sim, as spec 0024 §5 did. The levels stay on the owner's targets: mixed level 30 on
  day 80-100. The pacing test in `check.ps1` stays green.
- **No level gates.** The whole north stays open after the King (`docs/game-direction.md`). A quest can warn of a
  strong monster, as `pell_bear` does. It never blocks the hero.
- **Read and listen only.** No choices and no branches in the story. The twist of the buyer is something the hero
  learns, not something the player decides.
- **The words are a design decision.** The spec writes every line, page and quest. The owner accepts them with the
  spec. The names of the four people are checked against the data, so no two characters share a name.
- **Art:** flat SVG portraits by Claude. No art comes in under a new licence.
- **Influences:**
  - World of Warcraft: zone stories, outposts with quest givers, and a traitor inside one's own faction.
  - Diablo 2: the reward chest rolls its loot; the bosses stay worth farming.
  - The cage and the buyer: original.
- **Out of scope:**
  - the dragon's mother as a monster or a place (only the hook);
  - new places, monsters, items or spots;
  - quests from Ysolde;
  - daily or repeated quests;
  - choices, branches, timed quests and dropping a quest.

## Open questions
1. **Where chapter 2 starts.** The first north quest can open after `odda_king` (a quest, data only), or at the
   first King kill (a deed, a small rule change). With the quest, an old hero who killed the King before 0.12.0
   first does the 17 quests of chapter 1. Claude's suggestion: after `odda_king`, data only. A strong hero finishes
   the chapter 1 quests quickly (spec 0024 decision 5).
2. **The twist in time.** Which line or page shows the hero that the lodge master is the buyer, and at what point of
   chapter 3. Claude's suggestion: a page from the Chieftain's kill hints at "the lodge", and the truth comes from the
   person at Dragon's Peak.
3. **The old gold.** How the lodge master holds the King's gold. Claude's suggestion: the King's war chest, lost in
   the pass a hundred years ago, among the wraiths in old grave cloth.
4. **The quest XP.** How much XP each quest of levels 11-30 gives. The spec checks it by hand with the sim.
5. **The names and the words.** The spec writes them. The owner accepts them with the spec.

## History
- 2026-11-18: first version, with the owner's answers to the first questions. (draft)
