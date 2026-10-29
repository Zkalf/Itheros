# Spec 0018: What's new

Status: accepted
Intent: [intent/0018-whats-new.md](../intent/0018-whats-new.md) (accepted, 2026-10-29, issue #118)
Builds on: spec 0007 §5 (the release command) and §7 (the version in Settings), spec 0002 §9.1 (the level-up cards),
spec 0004 (the away report), spec 0014 (Quiet Teal)
Overrides: spec 0007 §5 step 5, only the moment of the rename of `releases/next.md` (§2.2 below)
Product owner: Zkalf
Date: 2026-10-29

After an update, the game shows the release notes of the new version on a "What's new" card. A player who skipped
versions sees the notes of each one. Settings keeps the notes, so the player can read them again. The notes come
with the app: the game still has no internet access.

## 1. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | A player skipped versions. What does the card show? | **The notes of each version after the last version that the player opened, newest first** (owner). |
| 2 | Where does the card stand among the screens at open? | **First**, before the level-up cards and the away report (owner). |
| 3 | Does a release of only fixes show the card? | **Yes**, the same card (owner). |
| 4 | What does a test build of the owner show? | **No card.** The card follows the version number only. Settings of the owner's build also shows `releases/next.md` (owner). |
| 5 | What does a save from before this spec show? | **Only the notes of the version that the player has**, nothing older (owner, intent open question 1). |
| 6 | What does a new player see? | **No card.** A new save records the version that the player has (intent, "Affected users"). |
| 7 | How does a friend's build get the notes of its own version? | `release.ps1` renames `releases/next.md` to `releases/<version>.md` **before** the check and the build (§2.2). The app thus always finds `releases/<its version>.md` (Claude). |
| 8 | How does the card show the bold words and the lists of the notes? | With a small reader for the format of the notes (§3.3), not with a new package (Claude). |
| 9 | What do the screens call the card? | **"New in Itheros"** (owner). The level-up cards keep their heading "What's new" (spec 0002 §9.1), so each name has one meaning. This spec and its intent keep the name "What's new" for the feature. |

## 2. Rules

### 2.1 The notes in the app
1. The app carries each file `releases/<version>.md` of the repo, for example `releases/0.5.0.md`.
2. The app also carries `releases/next.md`, if the file exists.
3. The app knows the version of each notes file from its file name.
4. The game compares versions by their three numbers: first x, then y, then z. For example, 0.10.0 comes after
   0.9.0.
5. The version that the player has is `appVersion` (`app/lib/version.dart`).
6. On `main`, the file `releases/<appVersion>.md` always exists. A test checks this.

### 2.2 The release command
7. `release.ps1` renames `releases/next.md` to `releases/<version>.md` together with the raise of the version
   (spec 0007 §5 step 2). Before this spec, the rename came in step 5.
8. The check (step 3) and the friend build (step 4) thus see `releases/<version>.md` and no `releases/next.md`.
9. A failure or a dry run puts `releases/next.md` back, as it puts the version back today.
10. Step 5 commits the renamed file with the version change, as today.
11. Step 6 still publishes `releases/<version>.md` as the notes of the GitHub release.

### 2.3 When the card shows
12. The save records `lastVersion`: the last version that the player opened (§4).
13. At open, the game lists the versions to show:
    - Each version that has a notes file, comes after `lastVersion`, and is at most `appVersion`.
    - `releases/next.md` never goes on this list.
14. If `lastVersion` is empty (a save from before this spec), the list holds only `appVersion`, if it has notes.
15. If the list is empty, the game shows no card.
16. The player closes the card. The game then sets `lastVersion` to `appVersion` and saves.
17. If the player closes the app before closing the card, the card shows again at the next open.
18. If `lastVersion` comes after `appVersion` (an older build on the phone), the game shows no card. It does not
    change `lastVersion`.
19. A new save sets `lastVersion` to `appVersion`. A new player thus sees no card.

### 2.4 Example
| `lastVersion` | `appVersion` | Notes files | The card shows |
|---|---|---|---|
| 0.3.0 | 0.6.0 | 0.2.0 to 0.6.0 | 0.6.0, 0.5.0, 0.4.0 |
| 0.5.0 | 0.5.1 | 0.2.0 to 0.5.1 | 0.5.1 |
| 0.5.0 | 0.5.0 (a test build) | 0.2.0 to 0.5.0, next | no card |
| empty (old save) | 0.6.0 | 0.2.0 to 0.6.0 | 0.6.0 |
| none (new player) | 0.6.0 | 0.2.0 to 0.6.0 | no card |
| 0.6.0 | 0.5.0 (an older build) | 0.2.0 to 0.5.0 | no card |

## 3. Screens

### 3.1 The order at open
The game shows the first screen of this list that applies:
1. Character creation, if the player has no character.
2. **The "What's new" card**, if §2.3 lists a version.
3. The level-up cards.
4. The away report.
5. The home screen.

### 3.2 The "What's new" card
1. The card is one screen, like the away report (spec 0004). Its title is "New in Itheros".
2. The card lists the notes of each version from §2.3, newest first.
3. Each version starts with a heading: "Itheros 0.6.0".
4. The notes of each version follow its heading, in the format of §3.3.
5. The card scrolls when the notes do not fit on the screen.
6. One button closes the card: "Continue", like the away report.
7. The phone's back gesture does not close the card. Only "Continue" closes it.
8. The card follows Quiet Teal (spec 0014): the plate, the fonts and the teal button.
9. The card fits at text size 2.0: no text overflows, and the player can scroll to "Continue".

### 3.3 The format of the notes
The notes use a small part of Markdown (`WRITING.md`, `releases/*.md`). The card shows:
1. A line of text as a paragraph. An empty line ends a paragraph.
2. A line that starts with "- " as an item of a list, with a bullet.
3. A line that starts with two spaces and follows an item, as more text of that item.
4. Text between `**` and `**` in bold.
5. Any other Markdown as plain text, with its marks. A test checks that each notes file in `releases/` uses only
   the format above.

### 3.4 Settings
1. Settings gets a row "New in Itheros", on its own plate, above the row of the version number.
2. A tap on the row opens a screen with the title "New in Itheros".
3. The screen lists the notes of each version up to `appVersion`, newest first, in the format of §3.2 and §3.3.
4. The screen has a back button, like Licences. It does not change `lastVersion`.
5. In the owner's build (with the test walk, spec 0007 §4), the screen starts with the notes of
   `releases/next.md`, if they exist. Their heading is "Next release (test build)".
6. A friend's build never shows the notes of `releases/next.md`.

## 4. Save
1. The save gets the field `lastVersion`: a version as text, for example "0.6.0". It can be empty.
2. The save version goes from 3 to 4.
3. A save of version 3 or lower loads with `lastVersion` empty.
4. Each fixture in `app/test/fixtures/saves/` loads, with its level, XP, bank and items.

## 5. Balance
No game rule changes. The pacing test stays green.

## 6. Out of scope
- The notes of 0.1.0. That version has no notes file.
- A change to the words of past notes.
- Pictures, links or headings inside the notes.
- A "What's new" for the owner's test builds at open (decision 4).

## 7. Acceptance criteria

**The notes in the app**
1. The app carries each `releases/<version>.md` of the repo.
2. A test fails when `releases/<appVersion>.md` does not exist.
3. A test fails when a notes file in `releases/` uses Markdown outside §3.3.
4. The game puts 0.10.0 after 0.9.0.

**When the card shows**
5. A save with `lastVersion` 0.3.0 in version 0.6.0 shows the notes of 0.6.0, 0.5.0 and 0.4.0, in that order.
6. A save with `lastVersion` equal to `appVersion` shows no card.
7. A save with an empty `lastVersion` shows only the notes of `appVersion`.
8. A new save shows no card.
9. A save with `lastVersion` after `appVersion` shows no card.
10. A save with `lastVersion` after `appVersion` keeps its `lastVersion`.
11. A tap on "Continue" sets `lastVersion` to `appVersion` and saves.
12. After "Continue", the next open shows no card.
13. The notes of `releases/next.md` never show on the card.

**The order at open**
14. With a card, level-up cards and an away report, the card shows first.
15. After "Continue", the level-up cards show, then the away report.
16. A player with no character sees character creation, not the card.

**The card**
17. The card has the title "New in Itheros".
18. Each version on the card has the heading "Itheros <version>".
19. A line that starts with "- " shows as a list item with a bullet.
20. Text between `**` shows in bold, without the `**`.
21. At text size 2.0, the card shows no overflow.
22. At text size 2.0, the player can scroll to "Continue".
23. The back gesture does not close the card.

**Settings**
24. Settings shows a "New in Itheros" row above the version number.
25. The row opens the notes of each version up to `appVersion`, newest first.
26. The owner's build shows the notes of `releases/next.md` first, under "Next release (test build)".
27. A friend's build does not show the notes of `releases/next.md`.
28. Opening the notes from Settings does not change `lastVersion`.

**The release command**
29. `release.ps1 -DryRun` builds a friend APK that holds `releases/<new version>.md`.
30. The friend APK of `release.ps1 -DryRun` holds no `releases/next.md`.
31. After `release.ps1 -DryRun`, `releases/next.md` is back and the working tree is clean.

**Save**
32. The save version is 4.
33. A save of version 3 loads with an empty `lastVersion`.
34. Each fixture in `app/test/fixtures/saves/` loads.

**On the phone**
35. On the Fairphone, an install over the current game shows the card once, then never again for that version.

**Check and release**
36. Rules, numbers and the save change only as this spec says. The pacing test passes.
37. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
