# Intent: What's new

Status: accepted
Product owner: Zkalf
Date: 2026-10-29

## Problem
- The release notes of a version show only on its GitHub release page and in Obtainium (spec 0007).
- A friend who updates and does not read them there never learns what changed in the game.
- Since issue #119, `releases/next.md` grows with each change that players notice. The notes exist, but the game
  does not show them (issue #118).

## Proposed outcome

### The card at open
1. The first time a player opens a new version, the game shows a "What's new" card.
2. The card shows the release notes of that version.
3. The player closes the card with one tap. The card then does not show again for that version.

### Skipped versions
4. A player can skip versions, for example from 0.3.0 to 0.5.0.
5. The card then shows the notes of each version after the last version that the player opened, newest first.
6. Example: a player goes from 0.3.0 to 0.5.0. The card shows the notes of 0.5.0, then the notes of 0.4.0.

### Which releases
7. Each release shows the card: a release with new things to play (a y version) and a release of only fixes
   (a z version).

### Where it stands among the screens at open
8. Today the game opens in this order:
   1. character creation, if the player has no character
   2. the level-up cards
   3. the away report
   4. the home screen
9. The "What's new" card comes **first**, before the level-up cards and the away report.

### Read the notes again
10. Settings has a "What's new" entry next to the version number.
11. The entry shows the notes of the version that the player has, and of the versions before it.

### The owner's test builds
12. The card follows the version number only.
13. A test build has the version number of the last release, so it shows no card.
14. In a build with the test walk (the owner's build), Settings also shows the notes in `releases/next.md`.
15. A friend's build never shows `releases/next.md`.

## Affected users and systems
- **Players:** everyone who updates. A new player (no save) sees no card: everything in the game is new to them.
  The spec confirms this.
- **App:** a new screen for the card, a new entry in Settings, and the order of the screens at open (`app.dart`).
- **Save:** the save records the last version that the player opened. A save from before this change has no such
  version. The spec chooses what the game shows then, for example only the notes of the version that the player has.
  Each fixture in `app/test/fixtures/saves/` loads.
- **Release flow:** the app build takes the notes from `releases/*.md`. `release.ps1` already renames
  `releases/next.md` to `releases/<version>.md` (spec 0007). The spec says if that flow changes.

## Constraints
- **The notes come with the app.** The card works with no internet. The game has no INTERNET permission
  (spec 0007 §6).
- **No change to the pace.** No game rule changes. The pacing test in `check.ps1` stays green. A hand-run sim is
  not needed.
- The notes keep their voice and their format (a first line, then a list with bold words, `WRITING.md`). The card
  shows the bold words and the list as they look on GitHub.
- The card follows the Quiet Teal style (spec 0014) and fits at text size 2.0.
- Out of scope:
  - Notes of 0.1.0. That version has no notes file.
  - A change to the words of past notes.

## Open questions
1. **What does an old save show after the update?** It has no last version. Recommendation: the notes of the
   version that the player has, and nothing older. The spec chooses.
