# walk-sun-goose (the game: Itheros)

Android-first mobile combat RPG where real-world steps (Health Connect) drive all progress.
Built with the AI-native SDLC playbook: intent → spec → plan → code, each accepted by the product owner (Zkalf).

## SDLC artifacts
- `intent/`, `specs/`, `plans/`: numbered markdown with a `Status:` line. **Accepted files are immutable**
  (a PreToolUse hook blocks edits). Changes go through a new numbered file or an amendment file the owner accepts.
- No code before an accepted plan. Each plan milestone ends with its proof, then a commit.
- Project texts (intents, specs, plans, PRs, reviews, commits, code comments, incidents, release notes) follow
  `WRITING.md`: read it before drafting one. Accepted files keep their wording (see WRITING.md for clean editions).
- Ideas, parked topics, small fixes and bugs live in GitHub Issues (labels `idea`, `parked`, `nit`, `bug`), not in
  local notes. A new issue follows its template in `.github/ISSUE_TEMPLATE/` and `WRITING.md`.
  `docs/game-direction.md` holds the owner's direction for the game: read it before proposing a design.

## Commands (Windows, PowerShell 5.1)
Run repo scripts directly, e.g. `.\scripts\check.ps1`. Never via `powershell -File …`: a nested interpreter can't be
auto-approved by permission rules (headless and eval runs deny it).
- `.\scripts\check.ps1` — format, analyze, tests. The definition of green.
- `.\scripts\check.ps1 -Release` — also builds the owner's release APK (with test walk) and runs
  `scripts\apk-check.ps1` on it (fails on INTERNET or cloud backup).
- `.\scripts\release.ps1 [-Fix] [-DryRun]` — releases to friends (spec 0007): version bump, check, friend APK (no
  test walk), signature check, commit + tag + push, GitHub release from `releases/next.md`. The owner runs it; Claude
  drafts `releases/next.md` (plain words for players) and may run `-DryRun`. Runbook: `RELEASING.md`.
- The production gate (plan 0009, `.claude/hooks/production-gate.ps1`) blocks Claude from releasing, merging PRs,
  pushing to `main` (or from eval worktrees) and touching the release key. Work on a short branch per change, open a
  PR (`gh pr create`, proof in the description), review it per `REVIEW.md` and post the review on it
  (`gh pr comment <number> --body-file <file>`); the owner merges with `.\scripts\merge.ps1 <number>` (from the Claude Code prompt, which runs Git Bash:
  `! scripts/merge.sh <number>`) once the CI
  check (`.github/workflows/check.yml`, the same `check.ps1 -Release`) is green. Don't look for ways around the
  gate: if it blocks you, ask the owner. It judges the programs a command runs, not words in messages, heredocs or
  echo; its cases are in `scripts\test-gate.ps1` (part of `check.ps1`), and a new false alarm or gap gets a case.
- Fast lane: a change that touches only config, docs or wording (not `app/`, `packages/`, `data/`, `scripts/`,
  `.github/`, the gate hook, saves, health data or the release flow) skips the PR. Claude commits it on a short branch,
  shows the diff, and the owner pushes it to `main` (`! git push origin <branch>:main`). Everything else takes the PR
  path. When unsure, PR.
- Several sessions run at once on this PC. **Each change gets its own worktree**: `.\scripts\new-worktree.ps1
  <branch>` makes `..\walk-sun-goose-<branch>` from the latest `origin/main`. Never switch branches or leave edits in
  the main folder: it stays on `main`, clean, for reading and for the owner's release builds and installs (only it
  has the release key). In a worktree, run scripts by their full path and push with the branch named
  (`git push -u origin <branch>`). `merge.sh` removes the worktree and branch when the owner merges the PR.
  `check.ps1` waits its turn while another full check runs on the PC (memory; `scripts\check-turn.ps1`).
- `gh` is `C:\Program Files\GitHub CLI\gh.exe` (signed in as the owner); shells started before its install don't have
  it on PATH.
- `.\scripts\test.ps1 <test file> [-Name <test name>]` — one test file, from the repo root.
- One command per tool call: no `;` chains or pipes (`Push-Location app; flutter test …`). Chained commands are never
  auto-approved; use the scripts above.
- `.\scripts\device-smoke.ps1 [-Install]` — on the Fairphone (USB): app starts, reads steps, no crash; screenshot.
- Bug fixes follow the `bugfix` skill (failing test committed first; `.\scripts\lock-tests.ps1` freezes `test/` files).
- The `verifier` subagent checks a change against its spec's acceptance criteria before committing.
- Evals (`evals/README.md`): after changing `CLAUDE.md` or `.claude/`, commit and run `.\evals\run.ps1`; every
  incident from real use adds a regression eval.
- `adb` is `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`. Shells started before the tool installs need PATH
  refreshed from Machine + User env vars (the scripts do this).

## Architecture
- `packages/game_core/` (from M2): pure Dart, no Flutter imports. All game rules. `applySteps(state, steps)` is
  deterministic; the seeded PRNG state lives in the save. Tunable numbers live in `data/*.json`, never in code.
- `app/`: Flutter Android app. `lib/steps/` step sources, `lib/sync/` sync, `lib/persistence/` atomic JSON save,
  `lib/ui/` screens (`GameController` via `ControllerScope`). Widget tests use `MemorySaveStore`, never real
  file I/O (it hangs in the fake-async test zone).

## Rules
- Content and tuning that fit existing systems (enemies, locations, items, gear slots, achievements, numbers) are
  data-only changes in `data/*.json`: no new spec needed, but `check.ps1` (pacing tests) stays green. Spec 0001's
  scope list (decision 11) bounded the first build, not later content. New rules or systems go intent → spec → plan.
- Sim work by hand (`tool/seeds.dart` tables, tuning loops, sim targets in specs) only for changes that move the
  pace: monster stats, XP tables or fade, drop/quality/find chances, gear power or buffs, the walker's choices, a
  system that changes where steps go. Otherwise the pacing test in `check.ps1` is enough; if it trips, ask first.
- Health data stays on the device: no INTERNET permission, no network code, `allowBackup="false"`.
- The release key (`%USERPROFILE%\.itheros\`, `app/android/key.properties`): never read, print, copy or commit it.
  Friends' phones only accept updates signed with it.
- Saves must load across versions: `app/test/fixtures/saves/` holds one per release; never edit or delete them.
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
- PowerShell 5.1 mangles double quotes in native args: write commit messages to `.git-commit-msg.txt`
  (git ignores it; overwrite it each time, never delete it) and use `git commit -F .git-commit-msg.txt`.
