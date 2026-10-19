# Spec 0004: Journal and test walks

Status: accepted
Intent: [intent/0004-journal-and-test-walks.md](../intent/0004-journal-and-test-walks.md)
Builds on: spec 0001 (the report), spec 0003 §7 (per-action report lines)
Product owner: Zkalf
Date: 2026-10-19

## 1. Decisions
| # | Question | Decision |
|---|---|---|
| 1 | What is one journal entry? | One "while you were away" report: everything credited from one return to the app (open or resume), including steps that arrive in the grace minutes after it. One test walk is one entry too. |
| 2 | How many are kept? | The newest **20** (data: `journalEntries` in `economy.json`). Older ones are dropped. |
| 3 | Where is it? | A **Journal** button (book icon) in the top bar opens a list, newest first. It replaces today's "show last report" button. |
| 4 | Timestamp | "Today 14:05", "Yesterday 18:30", or "Sat 18 Oct 09:12": the time the report started. |
| 5 | How is test walk hidden? | Tap the rank name on the Character tab 7 times: "Test walk on". The same again turns it off. |
| 6 | What does test walk do? | A "Test walk" card on the Adventure tab with **+100**, **+1,000** and **+5,000** buttons. |
| 7 | Do pretend steps count as walked? | Yes, fully: bank, boost, activities, "steps walked" achievements (owner's choice). The journal marks the entry "(test walk)". |
| 8 | Travelling Salesman: which areas? | Every area in the game data. Camp counts from the start. An area counts once the character **arrives** there (passing through on a multi-leg walk counts). |
| 9 | Existing saves | Areas visited before this update aren't known. They count from the next arrival, plus the area the character is in now. |

## 2. Journal
- Each report is saved with the save file the moment it changes, so closing the app at any time loses nothing.
- The report card on the Adventure tab works as today. Dismissing it (OK) only hides the card; the entry stays in
  the journal.
- An entry shows the same lines as the report card (spec 0003 §7), under its timestamp.
- A sync with no walked steps makes no entry.

## 3. Test walk
- Pretend steps go through the same rules as real steps (`applySteps`), after a normal sync, through the
  controller's one queue (so real steps walked before are credited first).
- They are not added to any day's Health Connect total, so later real syncs are unchanged.
- Each tap is its own journal entry and shows its report card.

## 4. Travelling Salesman
- New counters: `visited.<area>` (1 once arrived) and `areas.visited` (how many areas). Achievement data:
  `travelling_salesman`, "Travelling Salesman", counter `areas.visited`, at least the number of areas (10 today;
  a content test keeps the two equal when areas are added).
- No reward beyond the achievement.

## 5. Out of scope
Item qualities, camp NPCs, search or filters in the journal, exporting it.

## 6. Acceptance criteria
1. After a walk is reported, the entry is in the journal with its time, and it survives closing and reopening the
   app (a fresh controller on the same save).
2. Late steps in the grace minutes join the same entry, not a new one.
3. The journal keeps the newest 20 entries.
4. Seven taps on the rank name show the Test walk card; seven more hide it. The setting is saved.
5. "+1,000" applies 1,000 steps exactly as 1,000 walked steps would, makes a journal entry marked "(test walk)",
   and doesn't change what the next real sync credits.
6. Arriving at an area for the first time counts it once; arriving again doesn't. Camp counts for a new game.
   Visiting every area unlocks Travelling Salesman.
7. An existing save loads with nothing lost; its current area counts as visited.
8. `.\scripts\check.ps1 -Release` is green, with no INTERNET permission.
