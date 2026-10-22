# Spec 0012: Your character

Status: accepted
Intent: [intent/0012-your-character.md](../intent/0012-your-character.md) (accepted, commit b144d46)
Builds on: spec 0008 + amendments (top bar, Settings, Character screen), spec 0010 + amendments 1–2 (professions,
teachers, profession XP table, the walkers), spec 0011 + amendment 1 (Fishing, Hunting, Cooking, the 8-seed targets)
Overrides: spec 0010 §6.1 (the teacher sheet, §4.3), spec 0008 §3.5 (the Character header, §4.4), spec 0004's
journal title (§4.5), Bram's level 10 tip and the Adventurer rank line (data wording, decisions 4–5)
Product owner: Zkalf
Date: 2026-10-22

Before the first walk the player names their character, picks a gender and picks one of six origins, one per
profession. The origin's profession starts at level 5, already learned, and its teacher greets the player as kin.
Name and gender can be changed in Settings; the origin can't. Existing players see the screen once. No change to
steps, character XP, chances, drops or monsters. Origins, their lines and the gendered words live in `data/*.json`.

## 1. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | Head start size | **Profession level 5** (owner's choice): the profession XP for level 5 (148 today), about 7 tier 1 actions or 700 steps of work. No character XP. It opens no tier (tiers are at 10 and 20). |
| 2 | Is the origin's profession learned? | **Yes, with its starter tool worn.** "Starts with Fishing 5" can't mean "but go learn fishing first". The teacher still has a sheet: a kin line and tips. |
| 3 | Defaults to tap through | Name left empty becomes **Wanderer**; gender starts on **Neither**. No origin is preselected: one tap on a card picks it, so every player chooses. |
| 4 | Where gender shows | Only in data lines with a `{male\|female\|neither}` choice: the Woodcutter's title (son / daughter / child), the kin lines (lad / lass / friend and the like), and Bram's level 10 tip ("Point first, lad." follows gender). Everything else stays "you". |
| 5 | Where the name shows | The Character header, the journal title ("Zkalf's journal"), every teacher's sheet (a greeting, or the kin line), and the Adventurer rank line. Not in reports or fight logs, which stay "you". |
| 6 | When the screen shows | After step access is allowed, before level-up cards and "While you were away". A save with no character shows it; it can't be skipped. |
| 7 | Names | Any characters, 1–20 after trimming spaces. Only stored on the phone. |

## 2. Origins

### 2.1 The six
`origins.json` lists them in this order, each with an id, a title (gendered where marked), a line, a profession and
`headStartLevel` (5, one number for all in `economy.json`):

| Origin | Profession | Line |
|---|---|---|
| Miner's child | Mining | "You grew up under the Copper Hills. You hear rock crack before it falls." |
| Woodcutter's son / daughter / child | Woodcutting | "You can tell oak from ash by the sound of the axe." |
| Smith's apprentice | Crafting | "Your hands carry burns from a forge that was never quite yours." |
| Fisher from the coast | Fishing | "You learned to read the water before you could read words." |
| Hunter's apprentice | Hunting | "You walk soft, and you have never stepped on a dry branch." |
| Tavern cook | Cooking | "You have fed a full tavern at midnight. A camp fire holds no fear for you." |

### 2.2 The head start
When the character is made (new game, or an old save's one-time screen):
- The origin's profession is learned and its Common starter tool is worn, if it wasn't already (spec 0010 §6.1).
- Its profession XP is raised to `professionXpToReachLevel` for level 5, **only if lower**. Nothing is taken away.
- No level-up news, no character XP, no draws from any generator (spec 0010 §9.1).

### 2.3 Gendered words
A data line may hold `{a|b|c}`: male picks a, female b, neither c. `{name}` is the character's name. Only lines in
`origins.json`, `professions.json` (greetings, kin lines, tips) and `economy.json` (rank lines) are filled; a line
without them shows as written.

## 3. Teachers

### 3.1 Greetings
Each teacher's sheet opens with a line naming the player. A teacher of a different origin says their `greeting`; the
origin's own teacher says their `kinLine`, which replaces the learn line (the profession is already learned):

| Teacher | Greeting | Kin line |
|---|---|---|
| Hilde | "Back from the hills, {name}?" | "A miner's {son\|daughter\|child}, I'd know it anywhere. You know which end of a pick goes in the rock, {name}. Keep my old one." |
| Bram | "Mind the goblins in the oaks, {name}." | "{name}! You swing like one of us. Keep the old hatchet; it knows you." |
| Garrow | "Forge is hot, {name}. What are we making?" | "Burns on your hands and soot in your ears. Another smith, {name}. Any forge will do." |
| Wen | "Fish biting, {name}?" | "A coast {lad\|lass\|friend}! Salt in your hair, {name}. Take my old rod; you'll not need telling how." |
| Sigrun | "Walk soft, {name}." | "You walk like one of mine, {name}. Soft. The old bow is yours." |
| Marta | "Hungry, {name}?" | "Another tavern cook! Don't scorch my pot, {name}. Bring fish and meat and we'll feed this whole camp." |

Before the profession is learned the sheet shows the greeting, then today's "teaches" text and **Learn** button.

### 3.2 Tips
Unchanged (spec 0010 §6.2, spec 0011 §2.2). Bram's level 10 tip reads "Point first, {lad|lass|friend}. Never the
edge."

## 4. Screens

### 4.1 Your character (new)
One scrolling screen, title "Who are you?":
1. **Name**: a text field, hint "Wanderer".
2. **Gender**: three segments, Male · Female · Neither (Neither selected).
3. **Origin**: six cards, each:

   > **Fisher from the coast**
   > *"You learned to read the water before you could read words."*
   > **Starts with Fishing 5** · Wen, the fisherman, greets you as kin

   Titles and lines follow the gender as it's picked. Tapping a card selects it (outline in the theme colour).
4. **Set out**, enabled once an origin is picked. It makes the character (§2.2) and opens Now.

An old save's screen has one more line under the title: "Your progress stays. Your origin's profession rises to
level 5 if it is lower."

### 4.2 Settings
Three rows above today's switches:
- **Name** · Zkalf: tap opens a dialog with the text field (same rules, decision 7).
- **Gender** · Neither: tap opens the three choices.
- **Origin** · Fisher from the coast: not tappable; subtitle "Chosen when you set out".

Changes apply at once everywhere the name or gendered words show.

### 4.3 Teacher sheet
§3.1: greeting or kin line at the top, in italics, then today's content.

### 4.4 Character
The header gains the name above the rank, with the origin after the rank: "**Zkalf**", "Adventurer · Fisher from
the coast". The rank keeps its seven-tap test walk switch.

### 4.5 Journal
Its title is "{name}'s journal". Entries are unchanged.

## 5. Balance

### 5.1 No new sim work
The head start is about 700 steps of work in one profession, against about 450,000 steps to level 30. It can't
make one origin a best pick, and it needs no pacing run of its own. The mixed walker learns all six professions on
day 1 anyway and passes level 5 in each within its first days.

### 5.2 The walkers
Simulated walkers are made as **Miner's child**, so the existing pacing test (part of `check.ps1`) keeps running and
must stay green (spec 0011 §9.3 targets 1–5 and 7, as amended). If Mining starting at 5 shifts a seed past an edge,
the plan says so before any tuning; monsters and meals stay as they are. Each origin's head start is covered by unit
tests (criteria 4–5), not by the sim.

## 6. Save
New save version (10):
- `character`: `name`, `gender` (male, female or neither) and `origin` (an origin id), or none.
- An old save loads with no character, so the screen shows once (decision 6); §2.2 then raises the origin's
  profession only if it is lower. Everything else is unchanged. Every fixture in `app/test/fixtures/saves/` loads.
- A new game also starts with no character until Set out.

## 7. Out of scope
Portraits and appearance; origin quests (quests are a later system); changing the origin; origins that touch
fighting or the character level; more gendered text than decision 4; the name in reports, fight logs or news; a
second character or a new-game button; name filters (the name never leaves the phone).

## 8. Concerns
1. **Level 5 is still small (low, intended).** About 700 steps of work. It reads clearly on the card and in
   Professions on day 1; after the first week every walker is past it. That keeps origin a flavour choice.
2. **Existing players are stopped once (low).** The update opens on "Who are you?" before their report. The added
   line says their progress stays.
3. **Gendered tokens in data (low).** A typo in `{a|b|c}` would show raw braces. A data test checks every such line
   has exactly three choices.
4. **Seeds shift (low).** Mining at 5 from day 1 can nudge the walker's early choices, and the 8 seeds sit near
   their edges. The existing pacing test catches it; §5.2 says what happens then.

## 9. Acceptance criteria
1. A save with no character opens "Who are you?" after step access and before level-up cards and the away screen;
   it can't be left without Set out.
2. The screen has a name field (hint Wanderer), Male · Female · Neither (Neither selected) and the six §2.1 origin
   cards with title, line and "Starts with <Profession> 5 · <teacher> greets you as kin"; Set out is enabled only
   once an origin is picked.
3. An empty name becomes Wanderer; names are trimmed and 1–20 characters.
4. Set out on a new game: the origin's profession is learned at level 5 with its starter tool worn; character level
   and XP are unchanged; no level-up news; no draw from the shared generator or the profession stream.
5. Set out on an old save: the origin's profession is raised to level 5 only if lower and learned with its starter
   tool if it wasn't; nothing else changes.
6. Gendered lines follow the gender: Woodcutter's son / daughter / child, the kin lines' choices, Bram's level 10
   tip; changing gender in Settings changes them everywhere at once. Every `{a|b|c}` in data has three choices.
7. Every teacher's sheet opens with their greeting naming the player; the origin's teacher shows the kin line
   instead of the learn line.
8. The Character header shows the name, the rank and the origin; the journal title is "<name>'s journal"; the
   Adventurer rank line names the player.
9. Settings shows Name and Gender (changeable, same rules) and Origin (not changeable).
10. A save loads as version 10: an old save with no character and everything else unchanged; every fixture loads.
11. The existing pacing test stays green with walkers made as Miner's child.
12. `.\scripts\check.ps1 -Release` is green, with no INTERNET permission.
