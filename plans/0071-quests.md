# Plan 0071: Build "Quests, chapter 1" (spec 0024)

Status: accepted
Spec: `specs/0024-quests.md` · Product owner: Zkalf · Date: 2026-11-17

Names of files, widgets and tests refer to `main` at `f1102bd`.

Two milestones, as in plan 0069: the rules first, then the screens. M1 keeps Next goal running, so the app works
between the two PRs. M2 puts the quest card in its place and removes Next goal from the game and the app.

## What changes in the code

### game_core (M1)
- `data/quests.json` (new): the 17 quests of spec 0024 §2.8-§2.9 in the order of §2.8. Each: `id`, `giver`,
  `title`, `after`, `task` (`kind`, `target`, `count`, `words`), `xp`, `ask`, `thanks`.
- `lib/src/data/quests.dart` (new): `QuestDef`, `QuestTask`, `enum TaskKind {kill, gather, craft, bring, wear,
  visit}`.
- `lib/src/data.dart`: loads `quests`; `_validateQuests`: 17 quests, unique ids, each `after` and `giver` exists,
  each target is a known monster, item or place, each count is at least 1, the lines pass the `{name}` and
  `{a|b|c}` check of today.
- `lib/src/state.dart`: `quests` map (id → `QuestProgress`: `taken` or `done`, and the counter value at taking);
  `schemaVersion = 18`. `SupplyChest` gets an optional `quest` id, so the chest screen can say where it came from.
- `lib/src/game/quests.dart` (new, extension `GameQuests`): `questState`, `offeredQuests`, `takenQuests`,
  `questCount`, `isReady`, `takeQuest(s, id)`, `handIn(s, id)` (XP, the chest from `rollSupplyChest` on its own
  stream, the bring items lowest quality first, `QuestDone`), `questMark(s, giver)`.
- `lib/src/game/run.dart`: `dropped.<item>` for each item that a fight puts into the bag; after each step of a
  report, a `QuestReady` event for each taken quest that just became ready (counter tasks; a visit on arrival).
- `lib/src/events.dart`: `QuestReady(quest)`, `QuestDone(quest, xp)`.
- `lib/src/game/migrate.dart`: an old save gets an empty `quests` map. No old counter is copied, so old deeds do not
  count (spec 0024 §4).
- `tool/`: none. The hand check of spec 0024 §5 is a throwaway script, run once and reported in the PR.
- What does not change in M1: Next goal, the sim walker, the pacing numbers.

### app (M2)
- `lib/ui/now_tab.dart`: `_QuestCard` in place of `_NextGoal` (spec 0024 §3.1); the marks on the person rows, the
  teacher rows and Odda's row in place of the dot (§3.2).
- `lib/ui/quest_part.dart` (new): the quests on a sheet: offered (ask, task, reward, Take), taken (count), ready
  (Hand in), then the thanks with the XP and the chest (§3.3). Used by `person_sheet.dart` and
  `teacher_sheet.dart`.
- `lib/game_controller.dart`: `takeQuest` and `handIn`, each through the queue and after a sync, as every action;
  a hand-in goes into the Journal.
- `lib/ui/journal_screen.dart`: the fourth tab, Quests (§3.4).
- `lib/ui/labels.dart`, `lib/sync/away_summary.dart`: "Quest ready: …" and "Quest done: …" (§3.5).
- `lib/ui/settings_screen.dart`: "Show the quest card". `SaveData.nextGoalHidden` keeps its name.
- `art/icons.py`: the gold "!" and "?" marks, exported to `app/assets/images/icons/`.
- Removed: `packages/game_core/lib/src/goal.dart`, `nextGoal`, `_professionGoal`, `_safeSource` where nothing else
  uses it, `Labels.goal`, `_NextGoal`, and `goal_test.dart` with the Next goal cases of other tests.

## Order of work

### M1: The rules (one PR)
- First, the failing tests, committed alone:
  - `quests_test.dart` (game_core): the states and `after` (criteria 1-5); the data test (6); each task's count from
    the moment of taking (7-13); the count capped at N (14); `dropped.<item>` (15); hand-in only when ready (16);
    the XP (17); the chest and the daily chest (18-19); the seeded test that a quest roll shifts no fight, drop,
    catch or craft (20); the bring items, lowest quality first, none from the bank (21); the events (22).
  - `migrate` cases: an old save loads as 18 with `odda_goblins` offered (44), and its old kills do not count (45).
  - The version pins of today's tests move from 17 to 18.
- Then the data and the code.
- **Proof:** `.\scripts\check.ps1 -Release` green, the pacing sims included (`packages/` changes). The hand check
  of spec 0024 §5: the walker's level on day 10 and day 90, with and without 3,490 XP on day 1. The verifier checks
  criteria 1-22 and 44-46.
- Branch `feat/quest-rules`. PR, review per `REVIEW.md`. The owner merges.

### M2: The screens (one PR)
- First, the failing tests, committed alone:
  - `quest_card_test.dart`: the card's place, its lines, ready first, "+N more", the giver line, the hidden place,
    the last line, the switch (criteria 23-31).
  - `quest_sheet_test.dart`: the marks (32-34), the sheet's offered, taken and ready quests, Hand in and the thanks
    (35-37), the teacher's sheet (38).
  - `quest_log_test.dart`: the tabs, the order, the portraits (39-41), the report and the Journal lines (42-43).
  - `save_fixtures_test.dart`: each fixture loads (46).
  - The Next goal tests leave; the tests that the card moves (the order of Now) follow it.
- Then the code, the marks' art and the removal of Next goal.
- **Proof:** `.\scripts\check.ps1 -Release` green. The three screens of criteria 47-49 rendered at 408 dp and looked
  at. The verifier checks criteria 23-43 and 47-51.
- Branch `feat/quest-screens`. PR, review per `REVIEW.md`. The owner merges.

## Risks
- **Tests that read Next goal.** About ten test files name it today (`goal_test.dart`, `camp_tour_test.dart`,
  `bank_test.dart`, `quality_test.dart`, ...). M2 removes them or moves their checks to the quests. The PR lists
  each one and why.
- **The order of Now.** Tests that count Now's cards or scroll to Here may move with the card. M2 runs the full check
  before the PR.

## History
- 2026-11-17: first version (spec 0024). Accepted.
