# Spec 0022: The camp tour

Status: accepted
Intent: [intent/0021-camp-tour.md](../intent/0021-camp-tour.md) (accepted, issue #226)
Builds on: spec 0008 §3.1 (the four tabs), spec 0012 §4.1 ("Who are you?"), spec 0014 (Quiet Teal), spec 0018 §3.1
(the order of the screens at open)
Overrides: nothing
Product owner: Zkalf (accepted on 2026-11-06)
Date: 2026-11-06

Right after a new player makes the character, Bram, the quartermaster of the Guild camp, shows them around the game
in six short cards. Each card opens the real tab it talks about. The player can skip the tour at any card, and
Settings can play it again.

## 1. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | How does the tour look? | **A card at the bottom over the real tabs** (owner, intent 0021). |
| 2 | When does it start by itself? | **Once, right after "Who are you?" on a new game** (owner, intent 0021). |
| 3 | Who speaks? | **A guide at the Guild camp** (owner, intent 0021): **Bram, the camp quartermaster** (Claude's proposal, owner accepts with this spec). |
| 4 | Does the player get anything? | **Nothing** (owner, intent 0021). |
| 5 | Can the player tap the real screen during the tour? | **No.** The screen stays clear and visible, but only the card takes taps, so a step cannot get stuck (Claude). |
| 6 | Does the save keep the tour? | **No.** The tour lives in memory. If the app closes during the tour, it does not come back; Settings has it (Claude, intent 0021). |
| 7 | What does the back gesture do during the tour? | **It ends the tour, as Skip tour does** (Claude). |

## 2. Rules
1. No game rule, number or data file changes. `game_core` does not change.
2. The tour has six steps, in the order of §3.3.
3. The tour starts by itself when the player taps **Set out** on "Who are you?" and the character is made.
4. It starts at no other time by itself: not at an open of the app, and not for a save that already has a character.
5. Settings can start the tour at any time, from its first step.

## 3. Screens

### 3.1 Where the tour stands
6. The tour shows on the home screen (the four tabs), after "Who are you?". A new game has no "New in Itheros" card,
   no level-up card and no away report (spec 0018), so nothing stands between "Who are you?" and the tour.
7. If one of those screens opens during the tour (for example the away report after the app comes back), it opens as
   today. The tour waits under it and goes on when the home screen shows again.

### 3.2 The card
8. The card stands at the bottom of the screen, just above the bar of the four tabs, from edge to edge of the
   content. It has the plate look of spec 0014.
9. The card shows, from top to bottom:
   - a row with Bram's portrait in a 48 dp socket, the name "Bram", and the step, for example "1 / 6";
   - the words of the step (§3.3);
   - a row with **Skip tour** on the left and **Next** on the right. The last step shows **Done** in place of Next.
10. Bram has no picture yet. The socket shows the placeholder portrait until the portraits of #198 come.
11. Each step opens its tab, and the bar of the four tabs lights that tab, as a tap on the tab does.
12. The screen above the card stays as it is: no dark layer and no blur (`CLAUDE.md`, #121).
13. During the tour, taps on the screen outside the card do nothing. The tabs, the buttons at the top and the rows do
    not react.
14. **Next** goes to the next step. **Skip tour** and **Done** end the tour.
15. The back gesture ends the tour.
16. When the tour ends, the card goes away and the Now tab opens.
17. `{name}` stands for the character's name.

### 3.3 The steps
| # | Tab that opens | Words on the card |
|---|---|---|
| 1 | Now | Welcome to the Guild camp, {name}. I'm Bram, the quartermaster. Now shows what you are doing and what comes next. Every step you walk moves it on. |
| 2 | World | This is the map. Tap a place to travel there, or to see what lives there. Every road is open from the first day, but the far ones bite. |
| 3 | Professions | Mining, woodcutting, fishing, hunting, cooking, crafting. Each has a teacher somewhere out there. Learn from them, and go back for their tips. |
| 4 | Character, Gear | Your gear and your talents. Wear the best of what you find, and spend your talent points as you level. |
| 5 | Character, Bag | Your bag has only so many spaces, and past that you walk heavy. Keep the rest in the bank. Things move in and out of it only here at Camp. |
| 6 | Now | Up top: your supply chest, your achievements, the Journal and Settings. Settings can show you this tour again. Off you go, {name}. Walk. |

18. Steps 4 and 5 open the Character tab: step 4 on its Gear pane, step 5 on its Bag pane.

### 3.4 Settings
19. Settings has an entry **Camp tour**, with the line "Bram shows you around again", next to "New in Itheros".
20. A tap on it closes Settings and starts the tour at step 1.

## 4. Save
No change. The tour is not in the save (decision 6). Each fixture in `app/test/fixtures/saves/` loads as today.

## 5. Balance
No change to the pace. The pacing test stays green. No hand-run sim.

## 6. Out of scope
- Rings or arrows around single buttons (coach marks).
- A tour of each profession screen, the talent trees, the bank screen or the fight log.
- A glossary (#63).
- A reward of any kind.
- Bram's portrait (#198).

## 7. Acceptance criteria
**When it starts**
1. Set out on "Who are you?" opens the home screen with the card of step 1 on the Now tab.
2. An open of the app with a save that has a character shows no card.
3. After the app starts again in the middle of the tour, no card shows.

**The card**
4. The card shows Bram's placeholder portrait in a 48 dp socket, "Bram" and "1 / 6".
5. The card of step 1 reads the words of step 1, with the character's name in place of `{name}`.
6. The card stands above the bar of the four tabs.
7. The card shows Skip tour and Next.
8. The card of step 6 shows Done and no Next.
9. Nothing between the card and the screen dims or blurs it: no `BackdropFilter`, no `ImageFilter.blur` and no dark
   layer.

**The steps**
10. Next on step 1 opens step 2 on the World tab, and the bar lights World.
11. Step 3 opens the Professions tab.
12. Step 4 opens the Character tab on its Gear pane.
13. Step 5 opens the Character tab on its Bag pane.
14. Step 6 opens the Now tab.
15. Each step reads its words from §3.3.

**Ending the tour**
16. Skip tour on step 3 ends the tour and opens the Now tab.
17. Done on step 6 ends the tour, and the Now tab shows.
18. The back gesture during the tour ends the tour.
19. A tap on a tab of the bar during the tour does not change the tab.
20. A tap on a button at the top during the tour opens nothing.

**Settings**
21. Settings shows the entry Camp tour with the line "Bram shows you around again".
22. A tap on Camp tour closes Settings and shows the card of step 1 on the Now tab.

**Check and release**
23. Rules, numbers and the save do not change. The pacing test passes.
24. The six cards are rendered at 408 dp wide, and the longest card also at text size 2.0, before the PR (`CLAUDE.md`).
25. `releases/next/` has a line for players.
26. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
