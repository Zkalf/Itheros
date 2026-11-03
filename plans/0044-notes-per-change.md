# Plan 0044: Build "One notes file for each change" (spec 0018 amendment 2)

Status: accepted
Spec: `specs/0018-whats-new.amendment-2.md` · Issue: #189 · Product owner: Zkalf · Date: 2026-11-03

## What changes in the code
**scripts**
- `copy-notes.ps1`: copies `releases/<version>.md` as today. It writes `next.md` in the app from `releases/next.md`
  (if it exists) and then the files of `releases/next/`, sorted by name. With neither, it writes no `next.md`
  (criteria 5-8).
- `release.ps1`, step 1: refuses when a `.md` file is in `releases/next/` (criterion 1). The other refusals stay.
- `test-copy-notes.ps1` (new): runs `copy-notes.ps1 -Root` on a temporary folder for each case of criteria 5-8.
  `check.ps1` runs it next to `test-gate.ps1`.

**app**
- No code. The app reads the joined `next.md` as today.
- `test/release_script_test.dart`: criteria 1 and 2. The test reads the script, as its other tests do.

**docs**
- `RELEASING.md`: "The notes grow with each change" and the final notes step (criterion 9).
- `CLAUDE.md`: the line about `releases/next.md` (criterion 9). No eval run for it unless the owner asks.
- `releases/next/README.md` is not added: Git keeps no empty folder, and `copy-notes.ps1` handles a missing folder.

## Order of work (one PR)
1. The tests: `scripts/test-copy-notes.ps1` and `app/test/release_script_test.dart`.
2. The code and the docs. No notes line: players do not notice it.
3. **Proof:** `.\scripts\check.ps1 -Release` green. Review per `REVIEW.md`; the owner merges. The PR body says
   "Closes #189".
4. **After the merge:** `.\scripts\release.ps1 -DryRun` on `main` proves criteria 3 and 4. Claude runs it and posts
   the result on the PR.

Branch `fix/next-md-template`.
