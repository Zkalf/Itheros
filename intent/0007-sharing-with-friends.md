# Intent: Sharing with friends

Status: accepted
Product owner: Zkalf
Date: 2026-10-20

## Problem
The game runs only on the owner's Fairphone, installed over USB. A friend wants to try it. Today there is no way for
them to install it, no way to get updates, and every release build is signed with the throwaway debug key, so no
update could be installed over an earlier one on a friend's phone.

## Proposed outcome
1. **The code is on GitHub**, so it has a backup off the PC and a home for releases.
2. **A friend can install the game** on their Android phone from a link and a one-page guide: what they need
   (Android 9 or newer, Health Connect), how to allow "install unknown apps", and how to give the step permission.
3. **A friend gets updates** when the owner releases a new version, without the owner touching their phone. Their
   save carries over to every new version.
4. **One command releases a version:** it raises the version number, runs the full check, builds and signs the APK,
   and publishes it with short release notes in plain language.
5. **The signing key** is real, never committed, and backed up so it can't be lost. Losing it would mean friends
   have to uninstall (and lose their saves) to get any later version.
6. **Health data still stays on the phone.** No INTERNET permission, no analytics, no crash reports. The release
   check keeps proving it on the exact APK that gets published. The phone's cloud backup is also turned off for the
   game, because the save holds the player's daily step counts.
7. **Friends can tell the owner which version they run:** the version shows in the Character screen's settings.

## Affected users and systems
The owner and a few friends (Android phones). Touches the Android build setup (signing, version), the release
script and check, the app's settings screen, the repo's hosting, and a player install guide. No game rules change.

## Constraints
- **Test walk is not in friends' builds** (Claude's call). It hands out pretend steps in the real save, so a friend
  who finds it skips the game and their playtest tells the owner nothing. The owner's own builds from the PC keep it.
- No network code in the game. Whatever delivers updates is a separate app or store on the friend's phone.
- Free, or close to it. No store review cycles for each release.
- **The owner's own phone:** the installed game is signed with the debug key. Moving it to the real key needs one
  uninstall, which wipes the save (level 7). Friends start fresh anyway.
- **Heads-up, not now:** Google is rolling out "developer verification" for apps installed outside the Play Store,
  globally in 2027. A free hobbyist account covers up to 20 phones. Nothing to do yet; we revisit when it reaches us.
- Out of scope: the Play Store public listing, iPhone, in-game bug reporting.

## Open questions
1. How friends get the app and its updates (GitHub Releases plus an updater app, or Play Store internal testing).
   Claude recommends one before the spec.
2. Public or private repo. Claude lists what is fine to show before the owner picks.
3. Does the owner already have a GitHub account?
4. The owner's own phone: accept losing the level-7 save when it moves to the real key, or ask for a one-time save
   transfer (more work)?
5. The name and icon friends see on their home screen: today it's "walkingrpg" with the default Flutter icon.
