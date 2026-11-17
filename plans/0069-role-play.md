# Plan 0069: Build "Role-play, chapter 1: The King Who Would Not Rest"

Status: draft
Spec: `specs/0023-role-play.md` · Product owner: Zkalf · Date: 2026-11-17

Names of files, widgets and tests refer to `main` at `686dbb2`.

## What changes in the code

### game_core
- `packages/game_core/data/story.json` (new):
  - `pageChance` (0.01);
  - the four people, with their lines (§2.7 of the spec);
  - the 16 lore pages, each with its place, source, title and text;
  - the King lines of the six teachers and Ysolde, with the condition "first King kill".
- `packages/game_core/data/achievements.json`: the six lore achievements of spec §2.6.
- `src/data/story.dart` (new): `PersonDef`, `LineDef`, `PageDef`, `PageSource`. A line's condition reuses
  `Criterion` (counter and level kinds only; the loader refuses the other kinds).
- `src/data/achievements.dart`: a new `LoreCriterion(place)`.
- `src/data.dart`:
  - load `story.json`;
  - `loreOf(place)`: the pages of the place and the notes about its monsters;
  - data tests in the loader: unknown places, monsters, origins and pages fail to load, and no two people, teachers or
    trainers share a name (criterion 8).
- `src/game/story.dart` (new), an extension on `Game`:
  - `openLines(s, who)`, `newestLine(s, who)` and `linesWaiting(s, who)`, for a person, a teacher or the trainer;
  - `hear(s, who)`: marks the open lines heard and gives their pages; it returns the pages that it gave;
  - `_givePages(s, events)`: gives each page of the start, a first visit or a deed whose source has happened.
- `src/game/run.dart`:
  - after each fight and each gathered item, the find roll of the place's find page. It uses a generator derived from
    the unit, as the lore note roll does (line 561), so it never shifts the streams;
  - after each unit and each arrival, `_givePages` for the visit and deed pages;
  - a `LorePageFound` event for each page found in a run.
- `src/game/achievements.dart`: `LoreCriterion` is met when each lore id of `loreOf(place)` is in `s.lore`.
- `src/game/progress.dart`: `teacherLine` and the trainer's greeting return the King line after the first King kill.
- `src/state.dart`: the set `heard`; `schemaVersion` 16 -> 17. An old save loads with `heard` empty.
- `src/game/migrate.dart`: on load, give the pages of the start, first visits and deeds, without events.
- `src/events.dart`: `LorePageFound(page)`.
- `test/pacing_test.dart` (and the milestone check in `achievements_rework_test.dart` if it holds the list): the six
  lore milestones join Smuggler's Secret and King's Bane as milestones that the walker may miss (spec §5).
- The sim walker does not change. It never opens a sheet.

### app
- `lib/ui/person_sheet.dart` (new): the sheet of spec §3.2. It calls `GameController.hear(who)` as it opens, as
  `showTeacher` calls `talk` today.
- `lib/game_controller.dart`: `hear(who)` through the one queue, then the Journal line for a page from a line.
- `lib/ui/now_tab.dart`, Here:
  - the person rows (portrait, "Name, the title", the dot), first in the list out in the world, and after the trainer
    at Camp;
  - the dot on a teacher's or the trainer's row also shows for a King line that is not heard.
- `lib/ui/teacher_sheet.dart` and `lib/ui/trainer_sheet.dart`: the King line at the top (through `teacherLine` and the
  trainer's line in game_core); the sheet marks the King line heard as it opens.
- `lib/ui/journal_screen.dart`, `_Lore`: the groups by place, "found N of M", "Not found yet" with the placeholder,
  the tips below.
- `lib/sync/away_summary.dart` and the report: "Found a lore page: <title>".
- `art/people.py` (new): the four flat SVG portraits and the page picture. `scripts/export-art.ps1 -Only` for the new
  ids.
- `releases/next/feat-role-play.md`: lines for players.

### What does not change
- The story card, the lore notes, the tips, the camp tour's words, the Next goal line (quests replace it in a later
  intent, #274).
- The sim walker and the pacing ranges.

## Order of work

### M1: The rules in game_core (one PR)
- First, the failing tests, committed alone (`packages/game_core/test/story_test.dart`):
  - lines: a line without a condition is open on a new game; a condition opens a line; an origin line opens only for
    its origin; `hear` makes every open line heard; the newest open line (criteria 9-11, 13, 15);
  - King lines for the teachers and Ysolde, before and after the first King kill (criteria 17-19);
  - pages: the charter on a new game, a first-visit page, The King's last words, a page from a line, each page once
    (criteria 22-25, 30);
  - the find roll at `pageChance`, no roll once found, and the same fights, loot and gathering with and without the
    roll over many seeded units (criteria 27-29);
  - a page gives no XP, no item and no gold (criterion 33);
  - the six lore achievements, with pages and notes counted (criteria 40, 42);
  - an old save: version 17, `heard` empty, The King's last words and the first-visit pages on load without events,
    every old lore note kept (criteria 43-46);
  - the data test of the names (criterion 8).
- Then the code.
- **Proof:** `.\scripts\check.ps1 -Release` green, with the pacing test (the change touches `packages/`). Each fixture
  in `app/test/fixtures/saves/` loads (criterion 47). The verifier checks criteria 8-11, 13, 15, 17-19, 22-25, 27-30,
  33, 40, 42-47 and 51-52.
- Branch `feat/role-play-rules`. PR with this plan, review per `REVIEW.md`. The owner merges.

### M2: The screens and the art (one PR)
- First, the failing widget tests, committed alone (`app/test/people_test.dart`, `app/test/lore_tab_test.dart`):
  - the rows of Odda, Pell, Aldous and Jory, their order in Here, and Jory's row only after the cove is revealed
    (criteria 1-5);
  - each row's portrait and name, and a tap opens the sheet (criteria 6-7);
  - the dot before and after the sheet opens, for a person and for a King line (criteria 12, 14, 20);
  - the sheet: the newest line on top, "What <name> told you", "New lore page: <title>" (criteria 15-16, 26);
  - the learn line and Learn do not change (criterion 21);
  - the report and the Journal name a page (criteria 31-32);
  - the Lore tab: groups in the order of `world.json`, "found N of M", found and not found pages, no cove group
    before the reveal, the tips below (criteria 34-39);
  - the six lore achievements on the achievements screen (criterion 41).
- Then the code and the art.
- **Proof:**
  - `.\scripts\check.ps1 -Release` green.
  - Screenshots at 408 dp of Now at Goblin Woods with Pell's row, Pell's sheet and the Lore tab, looked at as a player
    (criteria 48-50). The PR shows them and says what I checked: Can I tell the people apart? Does each thing have its
    picture?
  - The verifier checks criteria 1-7, 12, 14-16, 20-21, 26, 31-32, 34-41 and 48-52.
- Branch `feat/role-play-screens`. PR with the release note file, review per `REVIEW.md`. The owner merges.
- An install on the Fairphone only if the owner asks for one, to playtest.

## Choices this plan makes
- **One new data file.** `story.json` holds the people, the lines, the pages and the King lines, so the words of the
  story live in one place. The teachers' greetings and kin lines stay in `professions.json`.
- **Conditions reuse `Criterion`.** The counter and level kinds exist and are tested. No new condition language.
- **Pages share the set `lore` with the notes.** One set, one count, and no second field to migrate.
- **Two PRs.** The rules come first and stand alone: a test proves them, and the app ignores them until M2.

## Risks
- **The pacing test.** The walker can earn Carved in Stone and Still Waters (+250 bank cap each). If the pacing test
  trips, I report the numbers once and the owner decides (`CLAUDE.md`).
- **Speed.** `_givePages` runs after each unit, not after each step, so the sim run stays near its time of today
  (4.8 s, PR #270). The PR names the time.

## History
- 2026-11-17: first version (spec 0023). (draft)
