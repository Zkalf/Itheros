# Spec 0019: a new fight log

Status: accepted
Intent: [intent/0019-fight-log-rethink.md](../intent/0019-fight-log-rethink.md) (accepted, 2026-11-01)
Builds on: spec 0006 decision 8 (the fight log), spec 0009 §8.1 (the swings in the log), spec 0014 (the look)
Overrides: spec 0006 decision 8 and criterion 3 (the last 4 rounds across fights); spec 0009 §8.1 only in where
the lines show
Product owner: Zkalf
Date: 2026-11-01

The Now screen shows less text during a fight: the two HP bars, one line about the last fight and a button. The
button opens a sheet with the story of the fights. The sheet lists the last 10 fights, one line each, and the latest
fight round by round. Both read from the top down: the oldest first, the newest last. Crits, blocks, dodges and
misses each have their own look.

## 1. Decisions
| # | Question | Decision |
|---|---|---|
| 1 | How many finished fights the sheet keeps | **The last 10 of the current action**, `fightLogFights` in `economy.json` (owner, intent 0019). |
| 2 | A sheet or a screen | **A sheet over the Now screen** (owner, intent 0019). |
| 3 | Fights after the action ends | **None are kept.** A new fight action starts an empty list (owner, intent 0019). |
| 4 | Movement on a big hit or a crit | **None in this build.** Only colour, size and weight (owner, intent 0019). |
| 5 | How many rounds of the latest fight the sheet keeps | **The last 50**, `fightLogRounds` in `economy.json` (today 4) (Claude). A fight of more than 50 rounds is rare. |
| 6 | What counts as a big hit | **A hit for at least a quarter of the full HP of the one who takes it** (Claude). |
| 7 | The colours | **Colours of the Quiet Teal look only** (spec 0014), no new colour (Claude). See §3.3. |

## 2. Rules
1. Each finished fight of the current fight action leaves a **fight summary**:
   - its number in the action: the first fight is 1
   - how it ended: won or lost
   - its rounds
   - the damage that the player took
   - the crits of the player
2. The action keeps the last `fightLogFights` summaries (10). An older one drops off.
3. The **round log** of the action holds the rounds of the latest fight only. The first round of a new fight empties
   it first.
4. The round log keeps the last `fightLogRounds` rounds of that fight (50). An older round drops off.
5. A new fight action starts with no summaries and an empty round log. The summaries and the round log end with the
   action.
6. The fight rules, the rolls and the numbers of the fights do not change. A summary uses no roll.

## 3. Screens
### 3.1 The Now screen during a fight
7. The Now screen shows the two HP bars, as today.
8. The Now screen no longer shows the round lines under the HP bars.
9. After the first finished fight of the action, one line under the HP bars tells how the last fight ended:
   - won: "Last fight: Goblin beaten in 4 rounds"
   - lost: "Last fight: beaten by the Goblin in 6 rounds"
10. "1 round" when the fight took one round.
11. A text button **Fight details** stands under that line. It shows as soon as the action has a round or a summary.
12. A tap on Fight details opens the fight sheet.
13. The rest of the Now screen does not change: the loss streak line, "So far" with the tally, and the queue.

### 3.2 The fight sheet
14. The sheet's title is "Fights: Goblin", with the name of the monster of the action.
15. The first part has the heading "Last fights". It lists the summaries, one line each, the oldest at the top:
    - won: "Fight 3 · beaten in 4 rounds · took 9 damage · 1 crit"
    - lost: "Fight 4 · you are beaten in 6 rounds · took 30 damage"
16. "took no damage" when the player took none.
17. The crits part is left out when the player made no crit. "2 crits" for more than one.
18. A won fight's line starts with a small check mark in the colour `Quiet.met`. A lost fight's line starts with a
    small cross in the colour `Quiet.short`.
19. The second part has the heading "Fight 5, round by round", with the number of the fight in the round log.
20. It lists the rounds of the round log, the oldest at the top. Each round is one row: "Round 1" in `Quiet.faint`,
    then its swings, in the order of spec 0009 §8.1 (the quick monster first).
21. The swing words are the words of spec 0009 §8.1: "You hit for 6", "Critical hit for 14", "You miss", "Goblin
    dodges", "Goblin hits you for 3", "Goblin misses", "You dodge", "You block: 1 damage".
22. When the fight in the round log ended, the last row ends with "Goblin is beaten" or "You are beaten".
23. A fight that is longer than the round log shows "Earlier rounds are not kept" above the first row.
24. The sheet scrolls when it is longer than the screen. It opens at the bottom, so the newest round shows first.
25. A fight that ends while the sheet is open adds its summary and starts a new round log, without a close and an
    open of the sheet.

### 3.3 The look of the swings
| Swing | Look |
|---|---|
| A hit of the player | `Quiet.text` |
| A hit on the player | `Quiet.short` |
| A crit | `Quiet.risky`, bold, one size larger than the other swings |
| A block | `Quiet.steel` |
| A dodge (either side) | `Quiet.teal` |
| A miss (either side) | `Quiet.faint` |
| A big hit (decision 6) | bold, in the colour of its row above |

26. The sheet shows each swing in the look of the table.
27. No swing moves on the screen: no flash, no shake, no animation.
28. The sheet uses no live blur (CLAUDE.md, #121).

## 4. Save
29. Save schema 15 (`GameState.schemaVersion`). The running fight action gets a new field `fights`: the list of
    fight summaries of §2.1. Each summary saves `number`, `outcome`, `rounds`, `taken` and `crits`.
30. A save from before schema 15 loads with an empty `fights` list. Its round log loads as it was saved. The first
    round of a new fight then empties it (rule 3).
31. Every save fixture in `app/test/fixtures/saves/` loads.

## 5. Balance
The fights, the rolls and the numbers do not change. The pacing test stays green.

## 6. Out of scope
- Fights in the journal or the away summary.
- Movement on the screen (decision 4).
- Fights of an action that ended.
- A log for gathering, crafting or cooking.

## 7. Acceptance criteria
**Fight summaries**
1. A won fight leaves a summary with its number, "won", its rounds, the damage taken and the crits.
2. A lost fight leaves a summary with "lost".
3. The action keeps 10 summaries at most: the 11th fight drops the 1st.
4. A new fight action starts with no summaries.
5. The summaries use no roll: the same seed gives the same fights, with and without them.

**The round log**
6. The first round of a new fight empties the round log first.
7. The round log keeps 50 rounds at most.

**The Now screen**
8. During a fight, the Now screen shows no round lines.
9. After a won fight, the Now screen shows "Last fight: Goblin beaten in 4 rounds".
10. After a lost fight, the Now screen shows "Last fight: beaten by the Goblin in 6 rounds".
11. A fight of one round reads "1 round".
12. The button Fight details shows once the action has a round or a summary.
13. A tap on Fight details opens the fight sheet.

**The fight sheet**
14. The title reads "Fights: Goblin".
15. "Last fights" lists the summaries with the oldest at the top.
16. A won summary reads "Fight 3 · beaten in 4 rounds · took 9 damage · 1 crit".
17. A lost summary reads "Fight 4 · you are beaten in 6 rounds · took 30 damage".
18. A summary with no damage reads "took no damage".
19. A summary with no crit has no crits part.
20. A summary with 2 crits reads "2 crits".
21. A won summary starts with a check mark in `Quiet.met`, a lost one with a cross in `Quiet.short`.
22. "Fight 5, round by round" lists the rounds with round 1 at the top.
23. Each round row starts with "Round N" in `Quiet.faint`.
24. A quick monster's swing comes first in its row.
25. The last row of an ended fight says who was beaten.
26. A fight longer than the round log shows "Earlier rounds are not kept".
27. The sheet opens at the bottom.
28. A fight that ends while the sheet is open shows in the sheet without a close and an open.

**The look**
29. A crit shows in `Quiet.risky`, bold and one size larger.
30. A block shows in `Quiet.steel`.
31. A dodge shows in `Quiet.teal`.
32. A miss shows in `Quiet.faint`.
33. A hit on the player shows in `Quiet.short`.
34. A hit for at least a quarter of the full HP of the one who takes it is bold.

**Save**
35. The save version is 15.
36. A save of schema 14 with a running fight loads with no summaries and its round log.
37. Every save fixture loads.

**Check and release**
38. Rules, numbers and the save change only as this spec says. The pacing test passes.
39. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
40. `releases/next.md` has a line for players about the new fight log.
