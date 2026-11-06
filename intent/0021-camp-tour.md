# Intent: The camp tour

Status: accepted
Product owner: Zkalf (chose on 2026-11-06: cards over the real tabs, it starts after "Who are you?" on a new game,
a guide at Camp speaks, no reward; accepted on 2026-11-06)
Date: 2026-11-06
Issue: #226

## Problem
- Friends who try the game do not know where to start.
- The game has many screens now:
  - the four tabs: Now, World, Professions and Character;
  - the buttons at the top: the supply chest, the achievements, the Journal and Settings;
  - the bank, the talents, the profession screens and their teachers.
- Nothing in the game tells a new player where these are or what they do. Today a friend has to ask the owner.

## Proposed outcome

### The tour
1. A short tour shows a new player the real screens of the game, one step at a time.
2. Each step opens the tab or screen that it talks about. A card at the bottom of the screen says what the player
   can do there. The rest of the screen stays visible above the card.
3. Each card has **Next** and **Skip tour**. The last card has **Done** in place of Next.
4. Skip tour ends the tour at once, on any step. The player is then on the Now tab.

### The steps
5. The tour has a handful of steps, about six. A first order, for the spec to settle:
   1. **Now:** what the player does now, the queue of what comes next, and that steps drive all of it.
   2. **World:** the map, travel to a place, and that the whole world is open from level 1, danger included.
   3. **Professions:** gathering and crafting, and the teachers who give tips.
   4. **Character:** the gear, the bag and the talents.
   5. **The bank at Camp:** items move only at Camp, and the bag has a space limit.
   6. **The buttons at the top:** the supply chest, the achievements, the Journal and Settings. Settings can play the
      tour again.
6. The tour shows and tells. It does not ask the player to tap a real button, so a step cannot get stuck.

### The guide
7. A guide at the Guild camp speaks the cards, in the game's voice, as a quest giver in World of Warcraft does. The
   guide greets the player by the name from "Who are you?".
8. The guide has a name and a short line of flavour. A portrait can come later with the other portraits (#198). Until
   then the card shows the placeholder portrait.

### When it plays
9. The tour starts by itself once, on a new game, right after the player makes the character on "Who are you?".
10. A player with a save from before this change does not get the tour by itself.
11. Settings has an entry that plays the tour again, at any time.

### What the player gets
12. The tour only teaches. It gives no item, no XP and no achievement.

## Affected users and systems
- **Players:** each new player, once. Every player can play it again from Settings.
- **App:** a tour layer over the home screen, the order of the screens at open (`app.dart`), and a new entry in
  Settings.
- **game_core:** no change. No rule, number or data file changes.
- **Save:** no change is needed if the tour starts only in the moment the character is made. If the app closes during
  the tour, the tour does not come back by itself; Settings still has it. The spec confirms this.

## Constraints
- **No change to the pace.** No game rule changes. The pacing test in `check.ps1` stays green. A hand-run sim is not
  needed.
- The cards follow the Quiet Teal style (spec 0014) and fit at text size 2.0 and at 408 dp wide.
- No live blur behind the card (`CLAUDE.md`, #121). A plain dark scrim or none.
- The card does not hide what it talks about: the spec places it so the part of the screen that the step names stays
  visible.
- The tour does not protect the player (`docs/game-direction.md`, "Explore and fail"): it tells, it does not gate or
  slow anything.
- Out of scope:
  - Rings or arrows around single buttons (coach marks).
  - A tour of each profession screen, the talent trees or the fight log in detail.
  - A glossary (#63).
  - Rewards.

## Open questions
1. **The guide's name and flavour.** Recommendation: a quartermaster of the Guild camp, for example "Bram, the camp
   quartermaster". The spec chooses with the owner.
2. **The words of each card.** The spec writes them, short: at most three lines each at text size 1.0.
3. **The tour and the "New in Itheros" card.** A new player sees no notes card (spec 0018), so the two do not meet on
   a new game. The spec confirms the order at open.
