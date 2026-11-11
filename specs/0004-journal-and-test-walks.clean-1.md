# Spec 0004: Journal and test walks (clean edition 1)

Status: draft
Clean edition of: [spec 0004](0004-journal-and-test-walks.md) with its amendments 1-6, and the parts of other specs
that change spec 0004 (see [Changes from other specs](#changes-from-other-specs))
Up to: 2026-11-11 (main c2eded8)
Issue: #59
Product owner: Zkalf

## How to read this edition
- This edition changes no rule, number or criterion. It says in one file what spec 0004 and its changes say today.
- The accepted files stay the record. If this edition and an accepted file differ, the accepted file wins, and an
  erratum fixes this edition.
- The section numbers (§1-§6), the decision numbers (1-9) and the criterion numbers (1-8) are those of spec 0004.
  Amendments 1-4 went on with that series (criteria 9-18). Amendments 5 and 6 start at 1. §6 keeps all of them.
  Code and tests that cite a number stay right.
- A tag such as **(am. 2)** marks a text that came from an amendment.
- [Where each change went](#where-each-change-went) lists every amendment and its place here.
- A new change to spec 0004 is a new amendment of spec 0004, as before. A later clean edition folds it in.

Intent: [intent/0004-journal-and-test-walks.md](../intent/0004-journal-and-test-walks.md)

Spec 0004 builds on spec 0001 (the report) and spec 0003 §7 (the report lines of each action).

## Summary
- Every return to the app makes one journal entry: the report of what the steps did.
- When something happened, a "While you were away" screen shows the report **(am. 2)**.
- The owner can add pretend steps with a hidden test walk, to try the game fast.
- The achievement Travelling Salesman counts the areas that the player has arrived at.

## Changes from other specs

| Spec | What it changes in spec 0004 | Folded in |
|---|---|---|
| Spec 0007 (sharing with friends) | The test walk is only in owner builds | §1, §3 |
| Spec 0008 (character and world layout) | The Adventure tab became Now; the rank's seven taps stay on Character | §1, §2, §3 |
| Spec 0009 (fights with depth) | The journal becomes the Log tab of the Journal, next to Bestiary and Lore | §1, §2 |
| Spec 0011 amendment 1 | Travelling Salesman: the 11 areas that are not hidden | §1, §4 |
| Spec 0012 (your character) | The Journal's title is "{name}'s journal" | §2 |
| Spec 0013 amendment 4 | The steps of a test walk count toward the supply chest | §3 |
| Spec 0014 (Quiet Teal) | Amendment 3's banner icons become pictures, or text only | §2 |
| Spec 0017 (achievements rework) | Travelling Salesman is a milestone with a reward | §4 |

## 1. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | What is one journal entry? | One "while you were away" report: everything credited from one return to the app (open or resume), with the steps that arrive in the grace minutes after it. Every return starts a new entry **(am. 1)**. One test walk is one entry too. |
| 2 | How many are kept? | The newest **20** (data: `journalEntries` in `economy.json`). The game drops older ones. |
| 3 | Where is it? | A **Journal** button (book icon) in the top bar opens a list, newest first. It replaced the "show last report" button. Since spec 0009 the list is the **Log** tab of the Journal. |
| 4 | Timestamp | "Today 14:05", "Yesterday 18:30", or "Sat 18 Oct 09:12": the time that the report started. |
| 5 | How is test walk hidden? | Seven taps on the rank name on the Character tab: "Test walk on". Seven more turn it off. |
| 6 | What does test walk do? | A one-row "Test walk" card on Now with **+100**, **+1k**, **+5k**, **+25k** and **+100k** **(am. 4, am. 5)**. Only owner builds have it (spec 0007 §4). |
| 7 | Do pretend steps count as walked? | Yes, fully: the bank, the boost, activities, "steps walked" achievements (owner's choice). The journal marks the entry "(test walk)". |
| 8 | Travelling Salesman: which areas? | Every area that is not hidden: 11 areas. Smugglers' Cove is a bonus **(spec 0011 am. 1)**. Camp counts from the start. An area counts once the character **arrives** there (a pass through on a walk of several legs counts). |
| 9 | Existing saves | The game does not know the areas visited before spec 0004. They count from the next arrival, plus the area that the character is in now. |

## 2. Journal
**Entries**
- The game saves each report with the save file the moment that it changes, so to close the app at any time loses
  nothing.
- Every return (open or resume) starts a new journal entry, whether or not the player closed the screen of the last
  one **(am. 1)**.
- Steps that arrive in the grace minutes after a return join that return's entry.
- An entry shows the same lines as the report (spec 0003 §7), under its timestamp.
- A sync with no walked steps makes no entry.
- The Journal's title is "{name}'s journal" (spec 0012 §4.5).
- The Journal has three tabs: Log (the entries), Bestiary and Lore (spec 0009 §8.4).

**The "While you were away" screen (am. 2)**
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

**Banners (am. 3)**
- Achievements and levels reached are not plain lines in the report.
- They show as banners at the top of the "While you were away" screen and of each journal entry, one per achievement
  or level: "Achievement unlocked: Prospector", "Reached level 6!".
- The banners use deep teal, not an item quality colour, so orange still means Legendary.
- Spec 0014 §4.2 gives their pictures: banners for levels, lore, professions and the sea chart are text only. The
  other banners start with the picture of the thing that they name.

**The step bank lines (am. 6)**
- A report that both used and saved step bank steps shows one line for them, where the "Saved" line stood:
  "Step bank: +2,630 steps." The number is the saved steps minus the used steps **(change 1)**.
- When more was used than saved, the line shows a minus: "Step bank: −500 steps." When both are equal, it reads
  "Step bank: no change." **(change 2)**.
- A report with only used steps, or only saved steps, keeps its sentence: "Used N steps from your step bank." or
  "Saved N steps in your step bank." **(change 3)**.
- The line "Your step bank was full, so N steps could not be saved." stays **(change 4)**.
- The away screen, the short note and the Journal show the same lines **(change 5)**.

## 3. Test walk
**The rules**
- Pretend steps go through the same rules as real steps (`applySteps`), after a normal sync, through the
  controller's one queue. So real steps walked before are credited first.
- The game does not add them to any day's Health Connect total, so later real syncs do not change.
- Each tap is its own journal entry, with its report.
- A test walk while the player rests fills the step bank up to its cap, as walked steps do. The card does not say so
  **(am. 4 change 2)**.
- The steps of a test walk count toward the supply chest of the local day of the test walk, as real steps on the
  current action do (spec 0013 amendment 4).

**The card (am. 4, am. 5)**
- The Test walk card shows the words "Test walk" and the five buttons in one row. It has no other line
  **(am. 5 change 1)**.
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
5. A test walk of 1,000 steps:
   - 5a. applies 1,000 steps exactly as 1,000 walked steps would;
   - 5b. makes a journal entry marked "(test walk)";
   - 5c. does not change what the next real sync credits.
   The button says "+1k" since amendment 5.

**Travelling Salesman**
6. Areas:
   - 6a. The first arrival at an area counts it once. A later arrival does not.
   - 6b. Camp counts for a new game.
   - 6c. A visit to every area that is not hidden unlocks Travelling Salesman.
7. An existing save loads with nothing lost. Its current area counts as visited.

**Check and release**
8. `.\scripts\check.ps1 -Release` is green, with no INTERNET permission.

**Amendment 1**
9. Two returns with the first card never dismissed make two journal entries, each with its own time, and the card
   shows only the second. (Since amendment 2 the report is a screen, not a card on the tab.)

**Amendment 2**
10. A return where something happened:
    - 10a. opens the screen (after level-up cards) with the time and the report lines;
    - 10b. Continue closes it;
    - 10c. the Now tab never changes its layout because of a report.
11. A return where the steps only went to the bank or a unit without an end shows the short note, not the screen.
12. Late steps after the player closed the screen join the journal entry without a reopen of the screen.

**Amendment 3**
13. A report with an achievement or a level shows each as a banner above the report lines, on the screen and in the
    journal, and not as a plain line.

**Amendment 4**
- Test walk card:
  14. Replaced by amendment 5 criterion 1 (the short words).
  15. "+100,000" (now "+100k") during an action applies 100,000 steps to the queue, as 100,000 walked steps would.
  16. "+100,000" (now "+100k") makes one journal entry marked "(test walk)".
- Check and release:
  17. The friend build has no Test walk card (spec 0007 §4).
  18. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

**Amendment 5**
- Test walk card:
  1. The Test walk card has the buttons +100, +1k, +5k, +25k and +100k, in that order.
  2. At the Fairphone's size (408 dp wide), the words "Test walk" and all five buttons sit in one row.
  3. "+1k" applies 1,000 steps, and "+100k" applies 100,000 steps, as walked steps would.
- Check and release:
  4. Rules, numbers and the save do not change. The pacing test passes.
  5. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

**Amendment 6**
1. A report with 1,185 used and 3,815 saved shows "Step bank: +2,630 steps." and neither the "Used" nor the "Saved"
   sentence.
2. A report with more used than saved shows the difference with a minus.
3. A report with the same number used and saved shows "Step bank: no change."
4. A report with only used steps shows "Used N steps from your step bank." A report with only saved steps shows
   "Saved N steps in your step bank."
- Check and release:
  5. Rules, numbers and the save do not change. The pacing test passes.
  6. `releases/next/` has a line for players.
  7. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

## Where each change went

| File | Its changes | Place in this edition |
|---|---|---|
| [Amendment 1](0004-journal-and-test-walks.amendment-1.md) | every return is its own entry | decision 1; §2 "Entries"; criterion 9 |
| [Amendment 2](0004-journal-and-test-walks.amendment-2.md) | the "While you were away" screen; the short note; late steps | §2 "The 'While you were away' screen"; criteria 10-12 |
| [Amendment 3](0004-journal-and-test-walks.amendment-3.md) | achievements and levels as banners | §2 "Banners"; criterion 13 |
| [Amendment 4](0004-journal-and-test-walks.amendment-4.md) | 1 two more buttons; 2 the same rules; 3 what stays | decision 6; §3; criteria 14-18 |
| [Amendment 5](0004-journal-and-test-walks.amendment-5.md) | 1 one row; 2 short words; 3 what stays | decision 6; §3 "The card"; amendment 5 criteria 1-5 |
| [Amendment 6](0004-journal-and-test-walks.amendment-6.md) | 1-3 one step bank line; 4-5 what stays | §2 "The step bank lines"; amendment 6 criteria 1-7 |
