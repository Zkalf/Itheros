# Plan 0029: Build "What's new"

Status: accepted
Spec: `specs/0018-whats-new.md` · Product owner: Zkalf · Date: 2026-10-29

Names of files, widgets and tests refer to `main` at `975d8d8`.

## What changes in the code
- **The copy of the notes.** Flutter does not put files outside `app/` into the APK (see "Choices"). So:
  - `scripts/copy-notes.ps1` (new) copies each `releases/*.md` into `app/assets/releases/`. It first removes the
    old copies, so a removed or renamed file does not stay.
  - `check.ps1`, `test.ps1` and `release.ps1` run it before the tests and the build. In `release.ps1`, it runs
    after the rename of `next.md` (below).
  - `.gitignore`: the copies in `app/assets/releases/*.md`. A committed `app/assets/releases/.gitkeep` keeps the
    folder, so a build without the copy still works. Such a build has no notes and shows no card.
  - `app/pubspec.yaml`: the asset folder `assets/releases/`.
  - A test compares the copy with `releases/`, file by file, when the copy exists.
  - `releases/next.md` stays where it is. A change to it stays a fast-lane change.
- `app/lib/release_notes.dart` (new):
  - `Version`: parses "x.y.z" and compares the three numbers (§2.1 rule 4).
  - `ReleaseNotes`: the text of each version, and of `next.md` if it exists.
    - `ReleaseNotes.load(AssetBundle)` reads the keys `assets/releases/<x.y.z>.md` and
      `assets/releases/next.md` from the asset manifest. It skips each other file.
    - `ReleaseNotes.empty` has no notes. Tests use it unless they test the notes.
    - `toShow(lastVersion, appVersion)`: the versions of §2.3 rules 13-15 and 18, newest first.
    - `upTo(appVersion)`: the versions for Settings (§3.4), newest first.
  - `NoteBlock` and `parseNotes(text)`: the paragraphs and list items of §3.3, each a list of plain and bold
    parts. `usesOnlyKnownMarks(text)` is false for a heading, a link, a numbered list, `*` or `_` emphasis, code or
    a table.
- `app/lib/persistence/save_data.dart`: `lastVersion` (`String?`), save version 4. A save of version 3 or lower
  loads with `lastVersion` null.
- `app/lib/game_controller.dart`:
  - The constructor gets `notes` (default `ReleaseNotes.empty`) and `version` (default `appVersion`), so that tests
    can set both.
  - A new save gets `lastVersion: version` (§2.3 rule 19). `SyncService.newSave` does not change.
  - `newNotes`: `notes.toShow(_save!.lastVersion, version)`.
  - `dismissNewNotes()`: sets `lastVersion` to `version` through `_update`, so the game saves it. It needs no sync:
    it changes no game state.
- `app/lib/main.dart`: `ReleaseNotes.load(rootBundle)`, with `ReleaseNotes.empty` if it fails (as the image index
  does).
- `app/lib/ui/app.dart`: the order of §3.1. The card comes after character creation and before the level-up cards.
- `app/lib/ui/notes_screen.dart` (new):
  - `NotesView`: a list of versions, each with the heading "Itheros <version>" and its blocks. A list item has a
    bullet. Bold parts use the bold weight of the body font.
  - `NewNotesScreen`: the card at open, title "New in Itheros", on a plate like the level-up cards. One button,
    "Continue" (key `new-notes-continue`). `PopScope(canPop: false)`, so the back gesture does nothing.
  - `NotesScreen`: from Settings, title "New in Itheros", a back button like Licences. In a build with the test walk
    (`testWalkAllowed`), it starts with the notes of `next.md` under "Next release (test build)".
- `app/lib/ui/settings_screen.dart`: a plate with the row "New in Itheros" (key `settings-notes`), above the
  version number.
- `scripts/release.ps1`:
  - The `git mv releases/next.md releases/<version>.md` moves to step 2, after the version change in `pubspec.yaml`
    and `version.dart`.
  - Step 5 commits the renamed file with the rest, as before.
  - `Undo` already runs `git reset --hard` to the old commit. That reset also puts `next.md` back and removes the
    new file. M1 checks this with a dry run.
  - The comment at the top says that the rename comes before the check.
- `releases/next.md`: one line for players.
- `RELEASING.md`: one line, if it names the moment of the rename.
- No change to `game_core`, the data, the sim or the pacing.

## Choices this plan makes
- **A copy, not the folder `../releases/`.** A test on 2026-10-29 put `../releases/` into `pubspec.yaml`.
  `flutter test` found the notes, but the APK of `flutter build apk` did not carry them. Flutter dropped them
  without a warning.
- **The copy is not committed.** A committed copy would turn each change to `releases/next.md` into a change in
  `app/`, so it would need a PR.
- **The card reads the notes at each open**, not once at the start of the app. A save loaded later still gets the
  right card.
- **No new package for Markdown.** The notes use three marks (§3.3), and a test keeps it so.

## Risks
- **The APK.** A test passed while the APK had no notes. M1 thus checks the APK itself: after
  `check.ps1 -Release`, the APK holds `assets/flutter_assets/assets/releases/0.5.0.md`.
- **A build without the scripts** (a plain `flutter build apk`) has no notes. It still works, with no card. Only
  the scripts make the builds that the owner and friends install.
- **The release command runs only on `main`.** Criteria 29-31 (the dry run) thus get their proof after the merge.
  Claude runs `.\scripts\release.ps1 -DryRun` on `main` then and posts the result on the PR.

## Order of work
### M1: The card, Settings and the release command (one PR)
- First, the failing tests, committed alone:
  - `app/test/release_notes_test.dart`:
    - 0.10.0 comes after 0.9.0 (criterion 4)
    - `toShow` gives each row of the table in spec §2.4 (criteria 5-9, 13)
    - `releases/<appVersion>.md` exists in the repo (criterion 2)
    - each `releases/*.md` passes `usesOnlyKnownMarks`, and the check fails on a heading and a link (criterion 3)
    - `parseNotes` makes a list item of "- ", joins its continuation line, and finds the bold parts (criteria
      19-20)
  - `app/test/save_data_test.dart` (or the existing save test): version 4; a version 3 save loads with
    `lastVersion` null; a new save has `lastVersion` equal to the version (criteria 8, 32-33).
  - `app/test/new_notes_test.dart` (widget tests with `MemorySaveStore` and a small `ReleaseNotes`):
    - the card shows first, before level-up cards and the away report; after "Continue" they follow (criteria
      14-15)
    - a player with no character sees character creation (criterion 16)
    - the title, the headings "Itheros <version>", a bullet, bold text without `**` (criteria 17-20)
    - "Continue" sets `lastVersion` and saves; a new controller on that save shows no card (criteria 11-12)
    - a save with `lastVersion` after the version keeps it (criterion 10)
    - the back gesture does not close the card (criterion 23)
    - at text size 2.0: no overflow, and a scroll reaches "Continue" (criteria 21-22)
    - Settings: the row above the version, the notes newest first, `next.md` first only with the test walk, and no
      change to `lastVersion` (criteria 24-28)
  - The save fixture test loads each fixture (criterion 34, the existing test).
- Then the code.
- **Proof:**
  - `.\scripts\check.ps1 -Release` green (criteria 36-37).
  - The release APK holds `assets/flutter_assets/assets/releases/0.5.0.md` (criterion 1, the risk above).
  - A test checks that the copy equals `releases/`.
  - The verifier checks the change against criteria 1-28 and 32-37.
- Branch `feat/whats-new` in the main folder (one session). PR with the intent, the spec and this plan, review per
  `REVIEW.md`. The owner merges.

### M2: Proof on `main` and on the phone (no code)
- `.\scripts\release.ps1 -DryRun` on `main`. Its friend APK holds `releases/<new version>.md` and no
  `releases/next.md`. After the run, `next.md` is back and the tree is clean (criteria 29-31). Claude posts the
  result on the PR.
- If the owner wants an install: the owner's build from the main folder on the Fairphone. The save there has no
  `lastVersion`, so the card shows the notes of 0.5.0 once, then never again (criterion 35).
