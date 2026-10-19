# Intent: Journal and test walks

Status: accepted
Product owner: Zkalf
Date: 2026-10-19

## Problem
From the first playtest on a walk (2026-10-19):

- The "while you were away" report is easy to lose. It lives only while the app runs: if Android closes the app,
  or the player opens and closes it twice, the report is gone. The steps were credited, but the player never sees
  what they earned, and that feels like losing the walk.
- Testing the game at home means going for a walk. There is no way to try a change without walking.
- Travelling has no reward of its own. The owner wants a *Travelling Salesman* achievement.

## Proposed outcome
- **Journal:** every report is kept in a list with its date and time, newest first. The player can look back over
  the last 20 entries. Nothing is lost when the app closes.
- **Test walk:** a hidden switch turns on a button that adds pretend steps to the real character, as if walked.
  It is for testing at home. The owner will reset the character before the game is "ready", so pretend steps in
  the real save are fine (owner's choice, option a).
- **Travelling Salesman:** an achievement for arriving at every area at least once (owner's choice).

## Affected users and systems
The owner (playtests on the Fairphone). The app's save, the report card, the Character tab, achievements data.
Game rules change only for counting visited areas.

## Constraints
- Health data stays on the device; no network.
- Pretend steps never touch Health Connect and never change what real days are credited.
- Item qualities (common to legendary) and "Next goal" as camp NPCs are separate, later intents.

## Open questions
None. Owner's choices are recorded above.
