# Spec 0007: Sharing with friends

Status: accepted
Intent: [intent/0007-sharing-with-friends.md](../intent/0007-sharing-with-friends.md) (accepted, commit d7fdc2f)
Product owner: Zkalf
Date: 2026-10-20

## 1. Decisions
| # | Question | Decision |
|---|---|---|
| 1 | How do friends get the game? | From **GitHub Releases** of a public repo `Zkalf/itheros` (owner's choice), two ways (owner's choice): the **Obtainium** updater app, or a plain link that always serves the newest version. |
| 2 | Public or private repo? | **Public** (owner's choice, CV showcase). Drop chances in `data/*.json` are visible to anyone who looks; accepted. |
| 3 | Commit email | Every commit, past and future, uses `15740075+Zkalf@users.noreply.github.com` (owner's choice). The history is rewritten once, before the first upload. |
| 4 | Game name | **Itheros** (owner's choice; Latin *iter*, road). The hidden app ID stays `com.zkalf.walkingrpg`. |
| 5 | Icon | A simple drawn icon (a boot and a sword on the theme colour), Claude's design, replaceable later. |
| 6 | Owner's phone | Uninstall once to move to the real key; the level-7 save is lost (owner's choice). |
| 7 | Test walk | Only in **owner builds** (the PC install). Friends' builds have no test walk at all: the seven taps do nothing. |
| 8 | Where builds happen | On the owner's PC only. No cloud build, so the signing key never leaves the PC and its backups. |
| 9 | Version numbers | The first friend release is **0.2.0**. Each release raises the middle number (0.3.0, 0.4.0); a quick fix raises the last (0.3.1). The hidden build number goes up by one every release. |
| 10 | Licence | None: "all rights reserved", said in the README. Anyone may look; nobody may reuse. |

## 2. Repo and history
- Before the first upload: a full backup of the repo (a single git bundle file outside the repo), then every
  commit's author and committer email is rewritten to the address in decision 3. Names, dates, messages and files
  stay the same; only commit IDs change.
- Accepted documents name old commit IDs and can't be edited. `docs/commit-map.md` lists every old ID beside its new
  one, so those references can still be followed.
- The repo's git setting for future commits uses the same address.
- A `README.md` for visitors: what the game is (two or three lines), how it is built (intent → spec → plan → code,
  with links to the folders), the licence line, and a link to the install guide.

## 3. Signing key
- One release key, made once. It lives outside the repo (`%USERPROFILE%\.itheros\`), and a local, ignored
  `app/android/key.properties` tells the build where it is. Neither is ever committed (both are in `.gitignore`).
- **Backup (owner's step, before the first release):** the key file and its password are kept in two places away
  from the PC: (1) a password manager or cloud drive, and (2) a USB stick. Claude gives the exact files to copy.
- The key's public fingerprint is committed (`releases/signing-cert.txt`). The fingerprint is not a secret; it lets
  the release command prove the APK is signed with the right key.
- Builds without `key.properties` (eval worktrees, a fresh clone) still build with the debug key, so
  `check.ps1 -Release` works anywhere. They can never be published: the release command refuses any APK whose
  fingerprint differs.

## 4. Two kinds of build
- **Owner build** (`check.ps1 -Release`, installed by `device-smoke.ps1 -Install`): signed with the release key
  when it's present, and has test walk.
- **Friend build** (made only by the release command): signed with the release key, and no test walk.
- An old save with test walk switched on loads fine in a friend build; the test walk card just doesn't show.

## 5. The release command
`.\scripts\release.ps1` (add `-Fix` for a quick-fix number). In order, stopping at the first failure:
1. Refuses unless on `main`, the working tree is clean, and `releases/next.md` (the release notes) exists and isn't
   empty.
2. Raises the version (decision 9) in `app/pubspec.yaml`.
3. Runs the full check (format, analyze, tests).
4. Builds the friend APK, then checks **that exact file**: it doesn't request INTERNET, and its signing fingerprint
   matches `releases/signing-cert.txt`.
5. Renames `releases/next.md` to `releases/<version>.md`, commits "Release <version>", tags `v<version>`, pushes both.
6. Publishes a GitHub release `v<version>` with the notes, and the APK attached as `itheros.apk`.

If any step fails, nothing has been pushed or published, and the version change is undone.

**Release notes** are plain language for players: what's new, what got fixed, in a few short lines. Claude drafts
`releases/next.md` from the changes since the last release; the owner reads it before releasing.

## 6. Privacy
- The game still has no INTERNET permission, no network code, no analytics, no crash reporting (spec 0001).
- **Phone cloud backup is off** for the game (`android:allowBackup="false"`), so the save, with its daily step
  counts, isn't copied to Google Drive. The catch: a friend who gets a new phone starts over.
- Only Obtainium goes online, to check GitHub for new versions. It's a separate app the friend chooses to install.

## 7. In the game
- The home screen shows **Itheros** with the new icon.
- The Settings part of the Character screen shows "Version 0.2.0" at its end.

## 8. Saves survive updates
- Each release adds a sample save of its version to the tests (`app/test/fixtures/saves/`). Every later version must
  load each one without error, keeping level, XP, bank and items. The release command makes and commits the sample
  as part of step 5.

## 9. Install guide (`INSTALL.md`, linked from the README and every release)
Short, for non-technical friends:
- Needs: Android **9 or newer**, and the Health Connect app (built in on Android 14+; from the Play Store on 9 to 13).
- Way 1, Obtainium (gets told about updates): install Obtainium, allow it to install apps, add
  `https://github.com/Zkalf/itheros`, install.
- Way 2, plain link `https://github.com/Zkalf/itheros/releases/latest/download/itheros.apk`: open it on the phone,
  allow the browser to install apps, install. To update, open the same link again; the save stays.
- A possible "unknown app" or Play Protect warning, and what to tap.
- First start: allow the step permission in Health Connect.
- If something goes wrong: send the owner the version number (Character → Settings) and a screenshot.

## 10. Out of scope
Play Store, iPhone, in-game bug reports, a website, cloud builds (decision 8), Google developer verification (intent
heads-up; revisit in 2027), the "World of Walkcraft" achievement (owner's idea, later data-only content).

## 11. Acceptance criteria
1. `github.com/Zkalf/itheros` is public; no commit in it has the old email; `docs/commit-map.md` maps every
   old commit ID; the backup bundle exists outside the repo.
2. No key file, password or `key.properties` is in the repo or its history.
3. `release.ps1` refuses: on a dirty tree, without `releases/next.md`, and with a debug-signed APK. A failed run
   leaves no tag, no push, no release and an unchanged `pubspec.yaml`.
4. A successful run publishes `v0.2.0` with `itheros.apk` and the notes; the plain link downloads it.
5. The published APK: no INTERNET permission, fingerprint matches, `allowBackup` false, label "Itheros", no test walk
   (seven taps do nothing).
6. Owner builds still have test walk.
7. The Character screen shows the version number.
8. The save fixtures load in tests; a sample save from 0.2.0 is committed.
9. On the Fairphone: installing 0.2.0, then a later release over it (through Obtainium or the link), keeps the save.
10. `INSTALL.md` covers section 9's points, and a friend can follow it without help (owner judges after the first
    friend installs).
