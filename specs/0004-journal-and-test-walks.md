# Spec 0004: Journal and test walks

Status: accepted
Intent: [intent/0004-journal-and-test-walks.md](../intent/0004-journal-and-test-walks.md)
Builds on: spec 0001 (the report) and spec 0003 §7 (the report lines of each action).
Product owner: Zkalf
Date: 2026-10-19

## Summary
- Every return to the app makes one journal entry: the report of what the steps did.
- When something happened, a "While you were away" screen shows the report.
- The owner can add pretend steps with a hidden test walk, to try the game fast.
- The achievement Travelling Salesman counts the areas that the player has arrived at.

## 1. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | What is one journal entry? | One "while you were away" report: everything credited from one return to the app (open or resume), with the steps that arrive in the grace minutes after it. Every return starts a new entry. One test walk is one entry too. |
| 2 | How many are kept? | The newest **20** (data: `journalEntries` in `economy.json`). The game drops older ones. |
| 3 | Where is it? | A **Journal** button (book icon) in the top bar opens a list, newest first. It replaced the "show last report" button. Since spec 0009 the list is the **Log** tab of the Journal. |
| 4 | Timestamp | "Today 14:05", "Yesterday 18:30", or "Sat 18 Oct 09:12": the time that the report started. |
| 5 | How is test walk hidden? | Seven taps on the rank name on the Character tab: "Test walk on". Seven more turn it off. |
| 6 | What does test walk do? | A one-row "Test walk" card on Now with **+100**, **+1k**, **+5k**, **+25k** and **+100k**. Only owner builds have it (spec 0007 §4). |
| 7 | Do pretend steps count as walked? | Yes, fully: the bank, the boost, activities, "steps walked" achievements (owner's choice). The journal marks the entry "(test walk)". |
| 8 | Travelling Salesman: which areas? | Every area that is not hidden: 11 areas. Smugglers' Cove is a bonus (spec 0011 amendment 1). Camp counts from the start. An area counts once the character **arrives** there (a pass through on a walk of several legs counts). |
| 9 | Existing saves | The game does not know the areas visited before spec 0004. They count from the next arrival, plus the area that the character is in now. |

## 2. Journal
**Entries**
- The game saves each report with the save file the moment that it changes, so to close the app at any time loses
  nothing.
- Every return (open or resume) starts a new journal entry, whether or not the player closed the screen of the last
  one.
- Steps that arrive in the grace minutes after a return join that return's entry.
- An entry shows the same lines as the report (spec 0003 §7), under its timestamp.
- A sync with no walked steps makes no entry.
- The Journal's title is "{name}'s journal" (spec 0012 §4.5).
- The Journal has three tabs: Log (the entries), Bestiary and Lore (spec 0009 §8.4).

**The "While you were away" screen**
- When the player comes back and something happened, a full "While you were away" screen opens by itself, after any
  level-up cards. "Something happened" means:
  - an action earned something, ended or was skipped;
  - a level;
  - an achievement.
- The screen looks like a journal entry (the time, the same lines, quality colours) and has one **Continue** button.
- No report sits on the Now tab, so a report never changes its layout.
- If the steps only went to the bank or toward an action without an end, a short note shows at the bottom of the
  screen instead and fades: "You walked 1,200 steps. Saved 1,200 steps in your step bank."
- Late steps in the grace minutes join the same journal entry. They update the screen while it is open. Once the
  player closes it, it stays closed for that return.
- The journal keeps every report. Test walks follow the same rule.

**Banners**
- Achievements and levels reached are not plain lines in the report.
- They show as banners at the top of the "While you were away" screen and of each journal entry, one per achievement
  or level: "Achievement unlocked: Prospector", "Reached level 6!".
- The banners use deep teal, not an item quality colour, so orange still means Legendary.
- Spec 0014 §4.2 gives their pictures: banners for levels, lore, professions and the sea chart are text only. The
  other banners start with the picture of the thing that they name.

**The step bank lines**
- A report that both used and saved step bank steps shows one line for them, where the "Saved" line stood:
  "Step bank: +2,630 steps." The number is the saved steps minus the used steps.
- When more was used than saved, the line shows a minus: "Step bank: −500 steps." When both are equal, it reads
  "Step bank: no change."
- A report with only used steps, or only saved steps, keeps its sentence: "Used N steps from your step bank." or
  "Saved N steps in your step bank."
- The line "Your step bank was full, so N steps could not be saved." stays.
- The away screen, the short note and the Journal show the same lines.

## 3. Test walk
**The rules**
- Pretend steps go through the same rules as real steps (`applySteps`), after a normal sync, through the
  controller's one queue. So real steps walked before are credited first.
- The game does not add them to any day's Health Connect total, so later real syncs do not change.
- Each tap is its own journal entry, with its report.
- A test walk while the player rests fills the step bank up to its cap, as walked steps do. The card does not say so.
- The steps of a test walk count toward the supply chest of the local day of the test walk, as real steps on the
  current action do (spec 0013 §2.1 point 6).

**The card**
- The Test walk card shows the words "Test walk" and the five buttons in one row. It has no other line.
- The buttons, in this order:

  | Button | Steps |
  |---|---|
  | +100 | 100 |
  | +1k | 1,000 |
  | +5k | 5,000 |
  | +25k | 25,000 |
  | +100k | 100,000 |

- The card shows only in an owner build, with the hidden switch on (spec 0007 §4). A friend build has no test walk at
  all: the seven taps do nothing.
- The card stands on Now, under the place, the level and the bars (spec 0008 §3.2).

## 4. Travelling Salesman
- Counters: `visited.<area>` (1 once arrived) and `areas.visited` (how many areas).
- The achievement `travelling_salesman`, "Travelling Salesman", counts `areas.visited`.
- It needs the 11 areas that are not hidden (spec 0011 amendment 1). A content test keeps the number equal to the
  areas when areas are added.
- Spec 0017 made it a milestone: "visit 11 areas", with the reward +500 bank cap. Spec 0004 had no reward.

## 5. Out of scope
- Item qualities (later spec 0005).
- Camp NPCs (later spec 0010).
- Search or filters in the journal.
- An export of the journal.

## 6. Acceptance criteria
**Journal**
1. After a walk is reported:
   - 1a. the entry is in the journal with its time;
   - 1b. it survives a close and a reopen of the app (a fresh controller on the same save).
2. Late steps in the grace minutes join the same entry, not a new one.
3. The journal keeps the newest 20 entries.

**Test walk**
4. The hidden switch:
   - 4a. Seven taps on the rank name show the Test walk card.
   - 4b. Seven more hide it.
   - 4c. The game saves the setting.
5. A test walk of +1k (1,000 steps):
   - 5a. applies 1,000 steps exactly as 1,000 walked steps would;
   - 5b. makes a journal entry marked "(test walk)";
   - 5c. does not change what the next real sync credits.

**Travelling Salesman**
6. Areas:
   - 6a. The first arrival at an area counts it once. A later arrival does not.
   - 6b. Camp counts for a new game.
   - 6c. A visit to every area that is not hidden unlocks Travelling Salesman.
7. An existing save loads with nothing lost. Its current area counts as visited.

**Check and release**
8. `.\scripts\check.ps1 -Release` is green, with no INTERNET permission.

**Every return is its own entry**
9. Two returns, with the report of the first never closed, make two journal entries, each with its own time. The
   report shows only the second.

**The "While you were away" screen**
10. A return where something happened:
    - 10a. opens the screen (after level-up cards) with the time and the report lines;
    - 10b. Continue closes it;
    - 10c. the Now tab never changes its layout because of a report.
11. A return where the steps only went to the bank or a unit without an end shows the short note, not the screen.
12. Late steps after the player closed the screen join the journal entry without a reopen of the screen.

**Banners**
13. A report with an achievement or a level shows each as a banner above the report lines, on the screen and in the
    journal, and not as a plain line.

**The Test walk card**
14. The Test walk card has the buttons +100, +1k, +5k, +25k and +100k, in that order.
15. "+100k" during an action applies 100,000 steps to the queue, as 100,000 walked steps would.
16. "+100k" makes one journal entry marked "(test walk)".
17. The friend build has no Test walk card (spec 0007 §4).
18. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
19. At the Fairphone's size (408 dp wide), the words "Test walk" and all five buttons sit in one row.
20. "+1k" applies 1,000 steps, and "+100k" applies 100,000 steps, as walked steps would.
21. The pacing test passes.

**The step bank line**
22. A report with 1,185 used and 3,815 saved shows "Step bank: +2,630 steps." and neither the "Used" nor the "Saved"
    sentence.
23. A report with more used than saved shows the difference with a minus.
24. A report with the same number used and saved shows "Step bank: no change."
25. A report with only used steps shows "Used N steps from your step bank." A report with only saved steps shows
    "Saved N steps in your step bank."
26. `releases/next/` has a line for players.

## History
- 2026-10-19: first version (intent 0004, plan 0005). Criteria 1-8.
- 2026-10-19, amendment 1: every return is its own entry. Decision 1; §2 "Entries"; criterion 9.
- 2026-10-19, amendment 2: the "While you were away" screen; the short note; late steps. §2; criteria 10-12.
- 2026-10-19, amendment 3: achievements and levels as banners. §2 "Banners"; criterion 13.
- 2026-10-20, spec 0007: the test walk is only in owner builds. Decision 6; §3 "The card".
- 2026-10-21, spec 0008: the Adventure tab became Now; the seven taps stay on Character. Decisions 5-6; §3.
- 2026-10-21, spec 0009: the journal is the Log tab of the Journal. Decision 3; §2 "Entries".
- 2026-10-22, spec 0011 amendment 1: Travelling Salesman needs the 11 areas that are not hidden. Decision 8; §4.
- 2026-10-22, spec 0012: the Journal's title is "{name}'s journal". §2 "Entries".
- 2026-10-22, spec 0014: the banners get pictures, or text only. §2 "Banners".
- 2026-10-24, spec 0017: Travelling Salesman is a milestone with a reward. §4.
- 2026-11-01, amendment 4: two more buttons, +25,000 and +100,000. Decision 6; §3; criteria 14-18.
- 2026-11-01, spec 0013 amendment 4 (#170): the steps of a test walk count toward the supply chest. §3.
- 2026-11-09, amendment 5 (plan 0058): the Test walk card in one row, with short words. Decision 6; §3 "The card";
  criteria 5, 14-16 and 19-21.
- 2026-11-10, amendment 6 (#255): one step bank line when a report both used and saved steps. §2 "The step bank
  lines"; criteria 21-26.
- 2026-11-15 (plan 0068): the amendments and clean edition 1 folded into this file. No rule, number or criterion
  changed. (draft)
