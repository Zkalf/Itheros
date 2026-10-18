# walk-sun-goose

Android-first mobile combat RPG where real-world steps (Health Connect) drive all progress.
Built with the AI-native SDLC playbook: intent → spec → plan → code, each accepted by the product owner (Zkalf).

## SDLC artifacts
- `intent/`, `specs/`, `plans/`: numbered markdown with a `Status:` line. **Accepted files are immutable**
  (a PreToolUse hook blocks edits). Changes go through a new numbered file or an amendment file the owner accepts.
- No code before an accepted plan. Each plan milestone ends with its proof, then a commit.

## Commands (Windows, PowerShell 5.1)
- `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\check.ps1` — format, analyze, tests. The definition of green.
- `... scripts\check.ps1 -Release` — also builds the release APK and fails if it requests INTERNET.
- Device: Fairphone 5 over USB. `adb` is `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`.
  Install: `adb install -r app\build\app\outputs\flutter-apk\app-release.apk`. Screenshot: `adb shell screencap -p /sdcard/x.png` + `adb pull`.
- Shells started before the tool installs need PATH refreshed from Machine + User env vars (check.ps1 does this).

## Architecture
- `packages/game_core/` (from M2): pure Dart, no Flutter imports. All game rules. `applySteps(state, steps)` is
  deterministic; the seeded PRNG state lives in the save. Tunable numbers live in `data/*.json`, never in code.
- `app/`: Flutter Android app. `lib/steps/` step sources, `lib/sync/` sync, `lib/persistence/` atomic JSON save,
  `lib/ui/` screens. `lib/probe/` is the M1 step probe, removed in M5.

## Rules
- Health data stays on the device: no INTERNET permission, no network code.
- Read steps with Health Connect's **aggregate** (`getTotalStepsInInterval` with default args). Never pass
  `includeManualEntry: false`: the plugin then sums raw records without de-duplication (double-counts phone + watch).
- `MainActivity` must stay a `FlutterFragmentActivity` (health plugin permission flow). `minSdk` is 26.

## Known mistakes
- PowerShell: `"$n:"` parses as a drive variable; write `"${n}:"`. Don't `Set-Location` in tool calls
  (it changes the session cwd); use `Push-Location`/`Pop-Location`.
- `JAVA_HOME` ends with a backslash; `.TrimEnd('\')` before quoting it.
- PowerShell pipes to `.bat` tools (sdkmanager) don't deliver stdin; use `cmd /c "tool < file"`.
