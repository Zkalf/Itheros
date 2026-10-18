# walk-sun-goose

Android-first mobile combat RPG where real-world steps (Health Connect) drive all progress.
Built with the AI-native SDLC playbook: intent → spec → plan → code, each accepted by the product owner (Zkalf).

## SDLC artifacts
- `intent/`, `specs/`, `plans/`: numbered markdown with a `Status:` line. **Accepted files are immutable**
  (a PreToolUse hook blocks edits). Changes go through a new numbered file or an amendment file the owner accepts.
- No code before an accepted plan. Each plan milestone ends with its proof, then a commit.

## Commands (Windows, PowerShell 5.1)
Run repo scripts directly, e.g. `.\scripts\check.ps1`. Never via `powershell -File …`: a nested interpreter can't be
auto-approved by permission rules (headless and eval runs deny it).
- `.\scripts\check.ps1` — format, analyze, tests. The definition of green.
- `.\scripts\check.ps1 -Release` — also builds the release APK and fails if it requests INTERNET.
- `.\scripts\device-smoke.ps1 [-Install]` — on the Fairphone (USB): app starts, reads steps, no crash; screenshot.
- Bug fixes follow the `bugfix` skill (failing test committed first; `.\scripts\lock-tests.ps1` freezes `test/` files).
- The `verifier` subagent checks a change against its spec's acceptance criteria before committing.
- `adb` is `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`. Shells started before the tool installs need PATH
  refreshed from Machine + User env vars (the scripts do this).

## Architecture
- `packages/game_core/` (from M2): pure Dart, no Flutter imports. All game rules. `applySteps(state, steps)` is
  deterministic; the seeded PRNG state lives in the save. Tunable numbers live in `data/*.json`, never in code.
- `app/`: Flutter Android app. `lib/steps/` step sources, `lib/sync/` sync, `lib/persistence/` atomic JSON save,
  `lib/ui/` screens (`GameController` via `ControllerScope`). Widget tests use `MemorySaveStore`, never real
  file I/O (it hangs in the fake-async test zone).

## Rules
- Health data stays on the device: no INTERNET permission, no network code.
- Read steps with Health Connect's **aggregate** (`getTotalStepsInInterval` with default args). Never pass
  `includeManualEntry: false`: the plugin then sums raw records without de-duplication (double-counts phone + watch).
- Steps are credited per local day (spec 0001 amendment 1, `lib/sync/sync_service.dart`); never per time window.
- `GameController` runs every change through one queue, and every player action syncs first, so steps
  walked earlier aren't credited to the new activity.
- `MainActivity` must stay a `FlutterFragmentActivity` (health plugin permission flow). `minSdk` is 26.

## Known mistakes
- PowerShell: `"$n:"` parses as a drive variable; write `"${n}:"`. Don't `Set-Location` in tool calls
  (it changes the session cwd); use `Push-Location`/`Pop-Location`.
- `JAVA_HOME` ends with a backslash; `.TrimEnd('\')` before quoting it.
- PowerShell pipes to `.bat` tools (sdkmanager) don't deliver stdin; use `cmd /c "tool < file"`.
- PowerShell 5.1 mangles double quotes in native args: write commit messages to a file and use `git commit -F`.
