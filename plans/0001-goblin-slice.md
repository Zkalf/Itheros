# Plan 0001: Build the Goblin slice

Status: accepted
Spec: `specs/0001-walking-core-loop.md` (accepted, 4d99b98) · Intent: `intent/0001-walking-core-loop.md` (accepted, 28fac3e)
Product owner: Zkalf · Date: 2026-10-18

## Context
The intent and spec are accepted. This is the Build stage of the AI-native SDLC playbook: no code is written
before this plan is accepted. Once accepted, this plan is committed as `plans/0001-goblin-slice.md`, and work
follows the order below. Each milestone ends with its proof and a commit.

The machine has **no Flutter, Dart, JDK or Android SDK** (checked: none on PATH, no `ANDROID_HOME`, no SDK folder).
It has VS Code, winget, git, 307 GB free disk and 16 GB RAM. The test device is a Fairphone 5 on Android 15.

## Project layout
```
walk-sun-goose/
  CLAUDE.md                     short: commands, conventions, architecture, known mistakes (created in M1)
  intent/  specs/  plans/       SDLC artifacts (accepted ones are immutable, enforced by a hook)
  packages/game_core/           pure Dart, no Flutter dependency: all game rules
    data/*.json                 tunable numbers: enemies, items, recipes, routes, XP curve, bank cap, achievements
    lib/src/                    state, economy (step allocation + bank), activities, combat, progression, rng
    test/                       spec §2.3 worked examples, determinism, unlocks, achievements
    tool/simulate.dart          pacing simulator (acceptance criteria 5 and 6)
  app/                          Flutter Android app
    lib/steps/                  StepSource interface, HealthConnectStepSource, FakeStepSource
    lib/sync/                   SyncService: window [lastSyncEnd, now] → game_core → atomic save
    lib/persistence/            single JSON save file (state + lastSyncEnd + RNG state), temp-file + rename
    lib/ui/                     screens
  scripts/check.ps1             the one command that proves the build is green
  .claude/settings.json + .claude/hooks/*.ps1
  .gitignore  .gitattributes    (LF line endings, to stop the CRLF warnings)
```

**Key design choices:**
- **game_core is a pure function:** `applySteps(state, walkedSteps) → state`. It walks steps one at a time
  exactly as spec §2.2 says (simple, at most ~100k iterations per catch-up).
- **A small seeded PRNG** (splitmix/xorshift) whose state is saved with the game. `dart:math` Random can't be
  serialised, and combat must be reproducible.
- **Combat:** a combat round is the step-paid unit (10 steps). A fight is a sequence of rounds.
- **Crafting:** materials are checked when a unit starts and consumed when it completes. Switching away never
  loses materials.
- **App ID:** `com.zkalf.walkingrpg` as a placeholder. It can change freely before the first Play Store upload.

## Order of work

### M0 — Tooling and repo hygiene
1. Commit this plan as `plans/0001-goblin-slice.md`. Add `.gitignore` (Flutter/Dart/Android) and `.gitattributes`.
2. Install, all scripted and with no Android Studio GUI wizard:
   - JDK 17: `winget install Microsoft.OpenJDK.17`
   - Flutter stable: `git clone -b stable https://github.com/flutter/flutter.git %USERPROFILE%\dev\flutter`, added to user PATH
   - Android command-line tools: zip from Google into `%LOCALAPPDATA%\Android\Sdk`. `sdkmanager` installs
     platform-tools and build-tools, then licenses are accepted. Set `ANDROID_HOME`.
   - Android Studio is optional and left out. VS Code + the Flutter extension is the editor.
3. **Your part:** enable Developer options → Wireless debugging (or USB debugging) on the Fairphone. Wireless
   pairing (`adb pair`) avoids Windows USB driver trouble.

**Proof:** `flutter doctor` shows Flutter ✓ and Android toolchain ✓. `flutter devices` lists the Fairphone.

### M1 — Step probe on the Fairphone (spec concern 1, the decision gate)
1. `flutter create --org com.zkalf --platforms android app`. Add the `health` plugin.
2. Manifest: `READ_STEPS` Health Connect permission, the permission-rationale activity, and the Android 14+
   permission-usage activity-alias that Health Connect requires.
3. One screen: request permission. Show steps for today and the last hour from the aggregated total
   (manual entries excluded), plus their data origins. A refresh button.
4. `scripts/check.ps1 -Release` builds the release APK and fails if `aapt2 dump permissions` lists
   `android.permission.INTERNET`.
5. Claude config: `CLAUDE.md` (via `/init`, trimmed to under a page) and `.claude/settings.json` hooks:
   - **PreToolUse (Edit|Write):** block edits to any `intent/`, `specs/` or `plans/` file whose status is
     `accepted` (exit 2). Changes go through a new intent.
   - **PostToolUse (Edit|Write) on `*.dart`:** run `dart format` on that file.

**Proof:** you walk ~100 steps, press refresh, and the count rises by roughly 100 (Health Connect batches about
once a minute). The release APK has no INTERNET permission.
**Gate:** if no steps arrive, stop and revise this plan with a fallback (Google Recording API or the raw
step-counter sensor) before M4.

### M2 — Rules package, tests first (`packages/game_core`)
1. Write failing tests first for spec §2.3's five worked examples, combat determinism, and unlock gating. Commit them.
2. Implement in order: PRNG → state model + JSON (de)serialisation → data loading → bank and allocation →
   travel → combat → mining → crafting → XP/levels/stat growth → unlocks → achievements (Marathon raises the cap).
3. Content in `data/*.json` with the spec §4–6 numbers.

**Proof:** `scripts/check.ps1` is green (format, `dart analyze`, `dart test`). Acceptance criteria 1 and 2 pass.

### M3 — Pacing simulator
`dart run tool/simulate.dart --steps-per-day 5000` plays a scripted sensible player (travel → goblins → mine →
craft → brute) and prints the level reached per day and steps to level 2. Tune `data/*.json` until it passes.

**Proof:** acceptance criteria 5 (level 2 within 350 steps) and 6 (level 5 on day 1, level 10 in days 7–11) run as tests.

### M4 — Sync and persistence (`app/lib/sync`, `app/lib/persistence`)
SyncService reads `[lastSyncEnd, now]`, does nothing if `now < lastSyncEnd`, applies steps, and saves the
state and the new `lastSyncEnd` in one atomic file replace. It runs on app open and every ~30 s in the foreground.
It produces a "while you were away" summary (steps, fights won, items, levels, steps banked or lost).

**Proof:** `flutter test` with FakeStepSource. The same window applied twice changes nothing. A crash between
the temp-file write and the rename leaves the old save intact (acceptance criterion 3).

### M5 — Screens (placeholder art: Material icons and text)
Home (location, current activity, level/XP, step bank bar with cap, away summary) · Activities at the current
location, including travel · Character and gear (equip/unequip) · Inventory · Achievements. Locked systems are
hidden, not greyed out.

**Proof:** widget tests for unlock hiding (acceptance criterion 8). A manual run on the Fairphone through the first-session flow.

### M6 — End-to-end on the phone
Install the release build. Start "fight goblins", close the app, walk ~500 steps, reopen.

**Proof:** catch-up applies the steps in order and the summary matches (acceptance criterion 4). Criterion 7 is
re-checked on this exact APK. Hand over to the Test stage.

## Risks
| Risk | Mitigation |
|---|---|
| The `health` plugin lacks something we need (manual-entry filter, permission flow on Android 15) | Found in M1. Fallback: a small Kotlin platform channel against the Health Connect SDK directly |
| No Health Connect steps on the Fairphone | M1 gate, before any game code depends on it |
| Health Connect's ~1 minute batching makes live updates feel laggy | The UI says steps update about once a minute. Catch-up is unaffected |
| Plugins add INTERNET to the merged release manifest | The check runs on the built APK, not the source manifest; strip the permission with `tools:node="remove"` |
| The June 2026 change to how on-device steps are labelled | Use the aggregate API without filtering by data origin |
| Windows USB driver issues | Wireless debugging |
| Pacing numbers feel wrong in real use | All numbers are in data files. The simulator plus your playtests tune them |

## Your actions during Build
Approve the installer prompts (UAC) in M0 · enable debugging on the phone · walk for the M1 and M6 proofs ·
playtest after M5.

## Verification summary
`scripts/check.ps1` (format + analyze + all Dart and Flutter tests) and `scripts/check.ps1 -Release`
(+ APK permission check) are the single commands for green. On-device proofs are in M1 and M6. Each milestone is
committed only when its proof passes.
