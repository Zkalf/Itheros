# Itheros

Android-first mobile combat RPG where real-world steps (Health Connect) drive all progress.
Built with the AI-native SDLC playbook: intent → spec → plan → code, each accepted by the product owner (Zkalf).

## SDLC artifacts
- `intent/`, `specs/`, `plans/`: numbered markdown with a `Status:` line. **Accepted files are immutable**
  (a PreToolUse hook blocks edits). Changes go through a new numbered file or an amendment file the owner accepts.
- No code before an accepted plan. Each plan milestone ends with its proof, then a commit.
- Project texts (intents, specs, plans, PRs, reviews, commits, code comments, incidents, release notes) follow
  `WRITING.md`: read it before drafting one. Accepted files keep their wording (see WRITING.md for clean editions).
- Ideas, parked topics, small fixes and bugs live in GitHub Issues (labels `idea`, `parked`, `nit`, `bug`; each idea
  also `soon` or `later`), not in local notes. A new issue follows its template in `.github/ISSUE_TEMPLATE/` and
  `WRITING.md`.
  `docs/game-direction.md` holds the owner's direction for the game: read it before proposing a design.

## Commands (Windows, PowerShell 5.1)
Run repo scripts directly, e.g. `.\scripts\check.ps1`. Never via `powershell -File …`: a nested interpreter can't be
auto-approved by permission rules (headless and eval runs deny it).
- `.\scripts\check.ps1` — format, analyze, tests. The definition of green. The pacing sims (tag `pacing`) run only
  when the change touches `packages/` (compared with `origin/main`) or with `-Pacing`; `release.ps1` always passes
  `-Pacing`. Each step prints its time.
- `.\scripts\check.ps1 -Release` — also builds the owner's release APK (with test walk) and runs
  `scripts\apk-check.ps1` on it (fails on INTERNET or cloud backup).
- `.\scripts\release.ps1 [-Fix] [-DryRun]` — releases to friends (spec 0007): version bump, check, friend APK (no
  test walk), signature check, commit + tag + push, GitHub release from `releases/next.md`. The owner runs it; Claude
  drafts the final `releases/next.md` before each release (plain words for players) and may run `-DryRun`. Runbook:
  `RELEASING.md`.
- Release notes, one file per change (spec 0018 am. 2): every PR or fast-lane commit with a change that players
  notice adds its own `releases/next/<branch>.md` (`feat/x` -> `feat-x.md`) with "- " lines for players (the light
  touch of `WRITING.md`). Never edit `releases/next.md` or another change's file there, so PRs never clash on the
  notes. The final-notes PR before a release joins them into `releases/next.md` and deletes them. Tests, scripts,
  specs and plans add no line.
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
- **Parallel sessions, only when the owner says so.** By default one session works on a short branch in the main
  folder. In parallel, each change gets a worktree (`.\scripts\new-worktree.ps1 <branch>` -> `..\Itheros-<branch>`
  from `origin/main`); the main folder stays on `main`, unedited (only it has the release key for the owner's builds).
  Run scripts and `git push -u origin <branch>` with the shell in the worktree; `merge.ps1` removes it on merge. A
  session told mid-change finishes on its branch in the main folder, then uses a worktree. Eval runs stay in theirs.
- At most two full checks run at a time on this PC: a third `check.ps1` (or `release.ps1`) waits for a turn
  (memory; `scripts\check-turn.ps1`). A wait adds the other check's time, so start a full check in the background.
- `gh` is `C:\Program Files\GitHub CLI\gh.exe` (signed in as the owner); shells started before its install don't have
  it on PATH.
- `.\scripts\test.ps1 <test file> [-Name <test name>]` — one test file, from the repo root.
- One command per tool call: no `;` chains or pipes (`Push-Location app; flutter test …`). Chained commands are never
  auto-approved; use the scripts above.
- `.\scripts\device-smoke.ps1 [-Install]` — on the Fairphone (USB): app starts, reads steps, no crash; screenshot.
- Bug fixes follow the `bugfix` skill (failing test committed first; `.\scripts\lock-tests.ps1` freezes `test/` files).
  Other skills: `small-feature` (amendment + plan), `ship-pr` (check, PR, review), `final-notes` (before a release).
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
- Every row or square of an item, monster or spot shows its picture and opens its card (details, stats, bonus stats),
  so the player can tell two alike things apart. A spec that wants less says why.
- Before a PR that adds or changes a screen, render it at the Fairphone's size (408 dp wide) and look at it as a
  player: Can I tell the things apart? Can I see what I choose? Does each thing have its picture? The PR says so.
- No session links (`claude.ai/code/session_...`) in PRs, commits, issues or comments: the repo is public.
- Art, icons, fonts and packages under a licence the project does not use yet: ask the owner first. Icons are flat
  SVG that Claude draws.
- Content and tuning that fit existing systems (enemies, locations, items, gear slots, achievements, numbers) are
  data-only changes in `data/*.json`: no new spec needed, but `check.ps1` (pacing tests) stays green. Spec 0001's
  scope list (decision 11) bounded the first build, not later content. New rules or systems go intent → spec → plan.
- Sim work by hand (`tool/seeds.dart` tables, tuning loops, sim targets in specs) only for changes meant to move
  the pace: monster stats, XP tables or fade, drop/quality/find chances, gear power or buffs. A new system that is
  not meant to move the pace (the bag limit, a new screen, a convenience) gets no sim targets in its spec: the
  pacing test in `check.ps1` is the guard. Teach the sim walker only the simplest habit that keeps it playing. If the
  pacing test trips, report the numbers once and let the owner decide (accept and widen the range, or tune). No
  digging for causes unless the owner asks.
- Small features stay small: a short spec (a handful of criteria), and rules and screens in one PR.
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
- No live blur on a screen that a sheet slides over or that animates (`ImageFilter.blur`, `MaskFilter.blur`, a
  `BoxShadow` with a large blur): the renderer (Impeller) draws it again on each frame, and the World map lagged at
  20 frames a second (#121). Bake the effect once into an image (`FogImage` in `world_tab.dart`), into the art, or
  draw it with plain strokes. Measure on the phone: `dumpsys SurfaceFlinger --latency` on the app's layer.

## Known mistakes
- PowerShell: `"$n:"` parses as a drive variable; write `"${n}:"`. Don't `Set-Location` in tool calls
  (it changes the session cwd); use `Push-Location`/`Pop-Location`.
- `JAVA_HOME` ends with a backslash; `.TrimEnd('\')` before quoting it.
- PowerShell pipes to `.bat` tools (sdkmanager) don't deliver stdin; use `cmd /c "tool < file"`.
- PowerShell 5.1 mangles double quotes in native args: write commit messages to `.git-commit-msg.txt`
  (git ignores it; overwrite it each time, never delete it) and use `git commit -F .git-commit-msg.txt`.
- A profile build (`flutter build apk --profile`, `flutter run --profile`) is signed with the debug key. Never install
  it over the owner's game: the only way is an uninstall, which loses the save.
