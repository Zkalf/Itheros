# Plan 0008: Build "Sharing with friends"

Status: accepted
Spec: `specs/0007-sharing-with-friends.md` (accepted, 18f8fa8) · Intent: `intent/0007-sharing-with-friends.md`
(accepted, d7fdc2f)
Product owner: Zkalf · Date: 2026-10-20

## What changes in the code
- **`AndroidManifest.xml`:** label "Itheros", `android:allowBackup="false"`, adaptive icon (`mipmap-anydpi-v26`:
  a vector boot-and-sword foreground on the theme colour; minSdk 26, so every phone gets it). Old PNG mipmaps go.
- **Test walk flag:** `const bool.fromEnvironment('TEST_WALK')`. The seven taps and the test walk card only exist
  when it's true. `check.ps1 -Release` builds with `--dart-define=TEST_WALK=true`; the release command doesn't.
  Widget tests run both ways (the flag is passed in, so tests don't depend on how they were compiled).
- **Version line:** `package_info_plus` is not needed: the release command writes the version name to
  `app/lib/version.dart` (`const appVersion = '0.2.0';`) alongside `pubspec.yaml`, and the Settings card shows it.
- **`build.gradle.kts`:** a `release` signing config read from `key.properties` when it exists, else the debug key.
- **`scripts/apk-check.ps1 <apk> [-RequireReleaseKey]`:** the INTERNET check moved out of `check.ps1`, plus
  `allowBackup` false, plus (with the switch) the signing fingerprint must equal `releases/signing-cert.txt`
  (`apksigner verify --print-certs`). `check.ps1 -Release` calls it without the switch.
- **`scripts/release.ps1 [-Fix] [-DryRun]`:** spec §5. `-DryRun` does steps 1-4 and then restores `pubspec.yaml`
  and `version.dart`: no commit, tag, push or release. Publishing uses the GitHub CLI (`gh`).
- **Save fixtures:** `app/test/save_fixtures_test.dart` loads every `app/test/fixtures/saves/*.json`.
  `tool/sample_save.dart` (game_core) plays a fixed seed for a few days of steps and writes a save; the release
  command runs it for `<version>.json`.
- **Docs:** `README.md`, `INSTALL.md`, `docs/commit-map.md`, `releases/signing-cert.txt`, `releases/next.md`.
  `CLAUDE.md` gets the release command and the key rule ("never read, print or commit `key.properties` or the key").

## Order of work
### M1: The game side (no key needed)
Name, icon, `allowBackup`, test walk flag, version line, save fixtures test.
**Proof:** `check.ps1 -Release` green; widget tests show the version line, test walk absent without the flag and
present with it; `apk-check.ps1` passes on the APK (INTERNET absent, `allowBackup` false). Commit.

### M2: The signing key
Claude makes the key with `keytool` (random strong password, written only to `key.properties`), sets up gradle,
commits the fingerprint.
**Your part:** copy two things to a password manager or cloud drive, and to a USB stick: the key file and the
password (Claude names the exact paths). Say "backed up".
Then your phone moves to the real key: Claude uninstalls the old game (your level-7 save goes, as agreed) and
installs the new build.
**Proof:** the APK's fingerprint matches; `device-smoke.ps1 -Install` passes; "Itheros" with the new icon on the
home screen (screenshot). Commit.

### M3: The release command and the guides
`release.ps1`, `README.md`, `INSTALL.md`, `releases/next.md` (Claude's draft notes for 0.2.0).
**Proof:** it refuses a dirty tree, missing notes and a debug-signed APK (build with `key.properties` moved away);
`-DryRun` passes and leaves the tree clean. An update test without publishing: install the M2 build, build the
next version with the same key, `adb install -r` over it, the save is intact. Commit.

### M4: Onto GitHub
Claude installs the GitHub CLI (winget). **Your part:** `! gh auth login` in this prompt (a browser opens; sign in).
Claude then: backup bundle in `%USERPROFILE%\.itheros\`, rewrites the email on every commit, writes and commits
`docs/commit-map.md`, sets the repo's email, scans the whole history for keys and old emails, and (after a last
"go" from you) creates the public repo `Zkalf/itheros` and pushes.
**Proof:** spec criteria 1 and 2 checked on GitHub's copy. Claude updates its own notes to the new commit IDs.

### M5: The first release
**Your part:** read `releases/next.md`, then run `.\scripts\release.ps1`.
**Proof:** release `v0.2.0` on GitHub; Claude downloads `itheros.apk` through the plain link and runs `apk-check`
on the downloaded file; on the Fairphone, Obtainium finds and installs the same version. Then the `verifier` checks
the change against spec 0007, and you send your friend the `INSTALL.md` link.

## Risks
| Risk | Handling |
|---|---|
| The key is lost | Two backups away from the PC (M2) before anything is shared |
| The key leaks | It lives outside the repo; `.gitignore` covers it; M4 scans the full history before the push |
| The history rewrite breaks something | Backup bundle first; the commit map; tests run on the rewritten tree before the push |
| A friend's save is lost by an update | Save fixtures (M1) checked by every release; update test in M3 |
| Play Protect blocks the APK | `INSTALL.md` explains the warning; if it hard-blocks, we come back to the owner |
| Claude setup changed (`CLAUDE.md`) | The full eval run is still owed (check.ps1 warning); run it when usage allows |
