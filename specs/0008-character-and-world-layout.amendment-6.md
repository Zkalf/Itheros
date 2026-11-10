# Spec 0008 amendment 6: the place's story stands under the current action

Status: accepted
Amends: [spec 0008](0008-character-and-world-layout.md) §3.2 (the order of Now: "Next goal; discoveries; the running
action … the queue")
Issue: #251
Product owner: Zkalf (liked the idea in the playtest of 2026-11-10; accepted on 2026-11-10)
Date: 2026-11-10

## Why
- On the first visit to a place, the card with its story stands above the current action. At Old Graveyard it is four
  lines and an OK button, so the progress of the fight is half off the first screen.
- The current action is what the player opens the game to see.

## Change
1. On Now, the card with the story of the place and its monsters stands under the card of the current action and the
   waiting actions, and above "Here".
2. The order of Now from the top is then: the step problem (if any); the place, level and bars; the Test walk (if
   on); Next goal; the current action with the waiting actions; the story; "Here".
3. The card, its words and its OK button do not change. It still shows only until the player taps OK.
4. No rule, number or save field changes. This does not move the pace, so it has no sim targets.

## Acceptance criteria
1. On the first visit to a place with a story, the story card stands under the card of the current action.
2. The story card stands above "Here".
3. With no current action, the story card stands under "Resting".
4. A tap on OK still takes the story card away.

**Check and release**
5. Rules, numbers and the save do not change. The pacing test passes.
6. Now with a story card and a fight is rendered at 408 dp wide before the PR (`CLAUDE.md`).
7. `releases/next/` has a line for players.
8. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
