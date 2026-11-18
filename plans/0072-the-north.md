# Plan 0072: Build "Role-play and quests, chapters 2 and 3: the north" (spec 0025)

Status: accepted
Spec: `specs/0025-the-north.md` · Product owner: Zkalf · Date: 2026-11-18

Names of files, widgets and tests refer to `main` at `7e5d986`.

Two milestones, as in plans 0069 and 0071: the rules and the data first, then the screens. Most of the work is data.
The code changes are the list of Camp lines (spec 0025 §2.4) and the end words in data (§2.9).

## What changes in the code

### game_core (M1)
- `data/story.json`:
  - `people`: Maud, Tobin, Corvin and Nessa with their lines (spec 0025 §2.2, §2.10);
  - the new lines of Odda, Pell, Aldous and Jory, after their lines of today;
  - `campLines`: the 14 lines after the Chieftain and the dragon, after the King lines;
  - `pages`: the 18 pages of §2.10.
- `data/quests.json`: the 34 quests after the 17 of chapter 1, in the order of §2.8; a new top-level `endWords`.
- `data/achievements.json`: the six lore achievements of §2.7, after `lore_smugglers_cove`.
- `lib/src/data.dart`:
  - `campLines` becomes `Map<String, List<LineDef>>`: the lines of each teacher or the trainer, in data order. The
    check of today runs on each line.
  - `questEndWords`, read from `endWords`, must not be empty.
  - Any pin of the quest count in the checks goes; the data test counts instead.
- `lib/src/game/story.dart`:
  - `campLine(s, who)`: the newest open Camp line, the last open one in data order;
  - `campLineWaiting(s, who)`: any open Camp line that is not heard;
  - `hear`: every open Camp line of `who` becomes heard.
- `lib/src/game/progress.dart` and `trainerLine`: no change; they read `campLine`.
- What does not change: the save (version 18), the sim walker, the pacing numbers, the find rolls.

### app (M1, so the tests compile)
- `app/test/people_test.dart`: reads the King line as the first Camp line of the list.

### app (M2)
- `art/people.py`: `maud()`, `tobin()`, `corvin()` and `nessa()`, flat SVG in the style of the eleven of today;
  exported with `scripts/export-art.ps1 -Only` to `app/assets/images/portraits/`.
- `lib/ui/now_tab.dart`: the quest card reads the end words from `game.data.questEndWords`, not a string in code.
- `lib/ui/teacher_sheet.dart` and `lib/ui/trainer_sheet.dart`: no change expected; they show `campLine`. M2 checks it with a
  test.
- `releases/next/feat-north-screens.md`: one line for players.

## Order of work

### M1: The rules and the data (one PR)
- First, the failing tests, committed alone:
  - `north_test.dart` (game_core, new):
    - the people at their places, and no name shared (spec 0025 criteria 5-6, the data part);
    - the lines and their conditions, the origin lines, the order after the lines of today, `corvin_3` (8-11);
    - the Camp lines: the lists, the Chieftain line, the dragon line on top, the dot, heard on opening, the King
      line or the greeting before, the learn line (12-18);
    - the pages: first visits, the Chieftain, 30 wraiths, the dragon, the story pages, the seeded finds (19-24);
    - the lore achievements (26);
    - the quests: 51, the order, the quests offered after `odda_king` and `tobin_chieftain`, the XP (28-31, 33);
    - the end words in data (34-35, the data part);
    - the save: version 18, The Chieftain's hoard on load, the five quests offered on load (37-39).
  - The pins of today that move: `quests_test.dart` (17 quests and 3,490 XP become 51 and 40,090),
    `story_test.dart` (the Camp line keys, the lore map), `achievements_rework_test.dart` (the six new ids).
- Then the data and the code.
- **Proof:**
  - `.\scripts\check.ps1 -Release` green, the pacing sims included (`packages/` changes).
  - The hand check of spec 0025 §5: a throwaway script adds the XP of chapter 2 when the walker reaches level 11 and
    the XP of chapter 3 when it reaches level 20. It reports the level on day 53 and day 99, with and without the
    XP. The PR gives the numbers.
  - The verifier checks criteria 6, 8-24, 26, 28-35 and 37-40.
- Branch `feat/north-rules`. PR, review per `REVIEW.md`. The owner merges.

### M2: The screens (one PR)
- First, the failing tests, committed alone:
  - `north_screens_test.dart` (app, new):
    - Maud, Tobin, Corvin and Nessa first under Here at their places, with portrait, name and title (criteria 1-5);
    - a teacher's sheet and Ysolde's sheet with the Chieftain line, then the dragon line (13-14, on screen);
    - the Lore tab groups of the north, in order, with "found N of M" (25);
    - the six lore achievements on the achievements screen (27);
    - the quest card with the end words, and no "The north will need you." (34-36).
  - `quest_card_test.dart`: the last-line test reads the new end words.
  - `save_fixtures_test.dart`: each fixture loads (40).
- Then the portraits, the end words in the app and the release note.
- **Proof:**
  - `.\scripts\check.ps1 -Release` green.
  - The six screens of §3 rendered at 408 dp and looked at as a player (criterion 41). The four portraits next to
    the eleven of today, so they read apart (criterion 7).
  - The verifier checks criteria 1-5, 7, 13-14, 25, 27, 34-36 and 40-43.
- Branch `feat/north-screens`. PR, review per `REVIEW.md`. The owner merges.

## Choices this plan makes
- **Portraits in M2.** Between the two PRs the four new rows show the placeholder portrait. No release falls
  between them.
- **The data in one PR.** The 34 quests, the lines and the pages go together, so the story never stands half in the
  game.

## Risks
- **Tests that read `campLines[who]` as one line.** `story_test.dart` and `people_test.dart` do today. M1 moves them
  to the list. A search for `campLines` before the PR finds any others.
- **A hidden pin of 17 quests.** If the data checks or a test pins the quest count, M1 moves it to 51. The quest
  card's order test reads the first offered quest, so it may change once chapter 1 is done in a test save.

## History
- 2026-11-18: first version (spec 0025). Accepted.
