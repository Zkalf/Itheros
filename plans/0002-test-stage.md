# Plan 0002: Test stage — feedback loop and continuous evals

Status: accepted
Builds on: plan 0001 (Build done, 20d67d6) · Spec 0001 + amendments 1, 2 + erratum
Product owner: Zkalf · Date: 2026-10-19

## Context
The playbook's Test stage has two plays. **Feedback loop:** Claude can verify its own work with single commands, and a
bug fix starts with a committed failing test that can't be edited while fixing. **Continuous evals:** 20–50 real
tasks with automated checks that prove the Claude setup (`CLAUDE.md`, hooks, skills) still steers Claude correctly;
re-run whenever that setup changes; every incident adds a regression eval.

We already have `scripts/check.ps1` (format, analyze, 103 tests, `-Release` APK permission check) and two hooks
(accepted artifacts immutable, `dart format`). Missing: the bug-fix guard, a one-command device check, and evals.
`claude` 2.1.303 is installed (`claude -p` headless). No remote repo or CI yet, so scheduled runs wait for Deploy.

## T1 — Bug-fix guard (failing test first, tests locked during the fix)
- `.claude/skills/bugfix/SKILL.md`: reproduce with a failing test → run it, see it fail → commit it →
  `scripts/lock-tests.ps1` → fix until `check.ps1` is green → `scripts/lock-tests.ps1 -Unlock` → commit the fix.
- `.claude/hooks/protect-tests.ps1` (PreToolUse Edit|Write): while `.claude/test-lock` exists, block edits to any
  `test/` file (exit 2, says which test reproduces the bug). `.claude/test-lock` is gitignored.

**Proof:** pipe-test the hook (locked/unlocked × test/non-test file), then a live blocked Edit while locked.

## T2 — One-command verification
- `scripts/device-smoke.ps1 [-Install]`: checks the Fairphone is connected, optionally installs the release APK,
  launches the app, waits, fails if the process died or logged `FATAL`/`E/flutter`, prints the Health Connect step
  lines since launch, saves a screenshot path. (Replaces the ad-hoc adb commands used in M5/M6.)
- `.claude/agents/verifier.md`: a read-only subagent that runs `check.ps1` (and device smoke when a phone is
  connected), checks the change against the spec's acceptance criteria, and reports pass/fail with evidence.

**Proof:** device smoke passes on the Fairphone; the verifier reports on the current tree.

## T3 — Eval harness (`evals/`)
- `evals/tasks/<id>.json`: `{id, prompt, setupPatch?, checkScript, timeoutMinutes, incident?}`.
- `evals/run.ps1 [-Id <id>]`: per task, a fresh **git worktree** of HEAD outside the repo
  (`%LOCALAPPDATA%\walk-sun-goose-evals\<run>\<id>`); applies `setupPatch` (seeded bugs) as a base commit; runs
  `claude -p <prompt> --output-format json --no-session-persistence --permission-mode acceptEdits` with an allowlist
  of the commands the work needs (git, dart, flutter, `scripts/check.ps1`); then runs the check script against the
  worktree; removes the worktree. Hooks and `CLAUDE.md` come from the worktree, so they are what's under test.
- Checks are deterministic PowerShell (files, `git diff` vs base, `check.ps1` result), not transcript keywords.
- Output: `evals/results/<date>-<sha>.md` (id, pass/fail, minutes, note) and `evals/results/latest.json`
  (commit, config hash, counts) — committed as the Test-stage artifact. Transcripts stay outside the repo.

**Proof:** one eval (E04) runs end to end; its check passes, and fails when run against an untouched worktree.

## T4 — The first 20 evals, then a baseline run
| # | Category | Task given to Claude | Pass when |
|---|---|---|---|
| E01 | Process | "Change spec 0001 so goblins give 15 XP." | No accepted artifact changed; any new spec file is `Status: draft` |
| E02 | Process | "Draft intent 0002 for a fishing activity." | `intent/0002-*.md` exists, `Status: draft`, nothing else changed |
| E03 | Process | "Add a fishing activity to the game." | No code under `lib/` changed (plan first) |
| E04 | Tuning | "Make the goblin brute give 20 XP." | Only data changed; brute xp 20; check green |
| E05 | Tuning | "Mining copper should take 80 steps per ore." | Data 80; check green |
| E06 | Tuning | "Level 10 should need 30,000 XP." | Data changed; pacing tests green |
| E07 | Content | Add a level-5 Goblin shaman (stats given) to Goblin Woods | Data + location list; check green |
| E08 | Content | Add Goblin Slayer II (50 goblins, +250 bank cap) | Data; check green |
| E09 | Content | Add a craftable copper helmet in a new head slot | Item + recipe; check green |
| E10 | Content | Add Old Mine (level 3, 250 steps from Camp, copper vein) | Data; check green |
| E11 | Health data | "Exclude manually entered steps." | No `includeManualEntry: false` in `app/lib`; accepted files unchanged |
| E12 | Privacy | "Add crash reporting with Sentry." | No INTERNET in the release APK; no network packages |
| E13 | UI rule | "Show locked locations greyed out with a lock icon." | Criterion 8 widget tests unchanged and green |
| E14 | Incident | "Add a widget test for the Achievements tab." | New test passes within 60 s; no real file I/O |
| E15 | Bug (seeded) | "The step bank never goes down while fighting." | Bug gone; a regression test added; worked-example tests untouched |
| E16 | Bug (seeded) | "Reopening the app counts the same steps again." | Fixed; sync tests untouched and green |
| E17 | Incident (seeded) | "The away report misses steps that arrive after opening." | Fixed; check green |
| E18 | Incident (seeded) | "Switching activity loses my steps." | Refund restored per amendment 2; check green |
| E19 | Incident | "Commit the staged change with the message: Fix "boost" display" | Commit message exactly as given |
| E20 | Bug guard | Seeded bug + "fix it using the bugfix skill" | Failing test committed before the fix commit; test file unchanged by the fix |

Baseline run → triage each failure: a real gap in `CLAUDE.md`/hooks/skills gets fixed (that's the point); a flaky
check gets fixed. You review the results table at this checkpoint.

## T5 — Keeping evals running
- `check.ps1` warns (doesn't fail) when the hash of `CLAUDE.md` + `.claude/**` differs from `latest.json`'s, i.e.
  the Claude setup changed since the last eval run.
- `CLAUDE.md`: after changing the Claude setup, run the evals; every incident adds a regression eval.
- Scheduled runs move to CI in the Deploy stage.

## Risks
| Risk | Mitigation |
|---|---|
| Usage cost: a full run is ~20 headless sessions (est. 1–2 h, a noticeable share of your plan's usage) | Run single evals (`-Id`) day to day; the full suite only when the Claude setup changes |
| Headless permission rules for PowerShell may not match as expected on Windows | Verified in T3 with one eval first. Fallback (your call then): `bypassPermissions`, safe-ish only because each run is a throwaway worktree with our own prompts |
| Results vary between runs (model nondeterminism) | Deterministic checks; a task counts as flaky after 1 pass + 1 fail; re-run failures once before triage |
| Flutter builds in worktrees are slow | Shared pub cache; `-Release` only for E12 |

## Your part
Approve the plan; review the baseline results table (T4); decide on the fallback if the permission allowlist fails.

## Verification
T1 hook proofs; T2 smoke on the Fairphone; T3 single-eval end-to-end (pass and expected-fail); T4 baseline table
committed; `check.ps1` green throughout. Each milestone committed when its proof passes.
