---
name: final-notes
description: Use when the owner asks for the final release notes before a release (spec 0007 §5, spec 0018 amendment 2). Joins the small files of releases/next/ into releases/next.md, checks them against every change since the last release, and opens the PR.
---

# The final notes before a release

The owner decides each release and runs `release.ps1`. Claude only drafts the notes, and only when the owner asks.
Never suggest a release.

1. **Branch** from the latest `main`: `docs/notes-<version>` (the version that the owner names, or `next`).
2. **Gather.**
   - The lines in `releases/next.md`, if the file exists.
   - Each small file in `releases/next/`.
   - Every change since the last release: `git log --oneline v<last>..main` (the last tag: `git describe --tags
     --abbrev=0`).
3. **Check each change against the notes.** A change that players notice needs a line. A test, script, spec or plan
   needs none. Add the missing lines. Drop lines of changes that a later change took back.
4. **Write `releases/next.md`** in the format of spec 0018 §3.3 and its amendment 1:
   - The first line sums up the release in one sentence, for players.
   - Then "- " items, the biggest changes first, the fixes ("**Fixed:** ...") last.
   - Plain words for players (the light touch of `WRITING.md`): no file names, no issue numbers, no code.
5. **Delete each small file** in `releases/next/`. `release.ps1` refuses while one is left.
6. **Commit and open the PR** (`ship-pr` steps 9-11). It is docs only, but `releases/` is in the release flow, so it
   takes the PR path. The body lists the changes since the last release and which line covers each one.
7. **Proof:** `.\scripts\test-copy-notes.ps1` and the release notes tests
   (`.\scripts\test.ps1 app\test\release_notes_test.dart`).
8. Tell the owner: read the notes in the PR, merge it, then run `release.ps1` (`RELEASING.md`). Claude may run
   `.\scripts\release.ps1 -DryRun` after the merge when the owner asks.
