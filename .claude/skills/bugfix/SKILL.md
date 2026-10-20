---
name: bugfix
description: Use when fixing a bug or reported misbehaviour in this repo (wrong numbers, steps counted wrong or twice, lost steps, crashes, wrong UI state). Reproduce with a failing test, commit it, lock tests, then fix.
---

# Bug fix: failing test first

A fix is only trusted when a test that failed before it passes after it, and the fix did not change that test.

0. **Branch first.** On `main`, make a branch `fix/<name>` before any commit (the owner merges it later via a PR).
1. **Find the rule.** Locate the spec section, amendment or acceptance criterion the bug breaks
   (`specs/`). If no rule covers it, ask the product owner before fixing.
2. **Reproduce.** Write the smallest test that fails because of the bug, in the package where the rule lives
   (`packages/game_core/test/` for game rules, `app/test/` for sync, saving and UI). Name it after the behaviour,
   not the bug. Widget tests use `MemorySaveStore`, never real file I/O.
3. **See it fail.** Run only that test (`dart test <file>` or `flutter test <file>`) and confirm it fails for the
   reason you expect.
4. **Commit the test alone.** Message: `Reproduce: <behaviour>`. Write the message to a file and use
   `git commit -F` (PowerShell mangles quotes).
5. **Lock tests:** `.\scripts\lock-tests.ps1`.
   While locked, a hook blocks edits to every `test/` file.
6. **Fix the code** until `.\scripts\check.ps1` is green. If the test itself turns out to be wrong, stop and tell the
   product owner instead of unlocking to change it.
7. **Unlock** (`.\scripts\lock-tests.ps1 -Unlock`) and **commit the fix**: `Fix: <behaviour>`, naming the reproducing
   commit.
8. If the owner says the bug came from real use (an incident), add a regression eval under `evals/tasks/` and an
   incident record: copy `incidents/TEMPLATE.md` to `incidents/NNNN-<name>.md` (next free number) and fill it in.
   If the lesson is a rule others could break again, add it to `CLAUDE.md`.
9. **Open a pull request:** push the branch and `gh pr create` with both commits named in the description; the
   owner merges. A finding too big for a fix (a missing rule or system) becomes a new `intent/` file instead.
