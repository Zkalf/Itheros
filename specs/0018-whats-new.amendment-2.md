# Spec 0018 amendment 2: one notes file for each change

Status: accepted
Amends: [spec 0018](0018-whats-new.md) §2.1 (the notes in the app) and §2.2 (the release command), and
[spec 0007](0007-sharing-with-friends.md) §5 (the release command: its refusal without notes)
Issue: #189
Product owner: Zkalf (chose on 2026-11-03: one small file for each change, so that pull requests never clash in the
release notes; no git merge driver; a merge with the script, the button on GitHub or the GitHub app on the phone all
work)
Date: 2026-11-03

## Why
- Each pull request that players notice adds a line to `releases/next.md`.
- Two pull requests that are open at the same time edit the same lines of that file: the first line and the end of the
  list. The second one then has a merge conflict. This happened several times.
- A release renames `releases/next.md`, so the first change after a release must create the file again (#189).

## Change
1. **One small file for each change:** a pull request or a fast-lane commit that players notice adds its own file in
   `releases/next/`.
   - The file name is the branch name: `releases/next/feat-salvage-all.md`.
   - The file holds only items: one or more lines that start with "- ", in the format of spec 0018 §3.3.
   - A later change to the same lines edits that file, or adds a file of its own.
   - A change never edits `releases/next.md` or another change's file.
2. **No conflict:** two pull requests add two different files. So a merge never conflicts on the notes, whether the
   owner merges with `merge.ps1`, with the button on GitHub or in the GitHub app on the phone.
3. **The final notes before a release:** the pull request of the final notes (spec 0007 §5) joins the small files into
   `releases/next.md`.
   - It writes a first line that sums up, and puts the biggest changes first.
   - It deletes the small files.
   - `releases/next.md` exists only from this pull request to the release.
4. **The release command:** `release.ps1` renames `releases/next.md` to `releases/<version>.md`, as today (spec 0018
   rules 7-11). It refuses:
   - when `releases/next.md` does not exist or is empty, as today,
   - when a file is left in `releases/next/`. The message says: join the small files into `releases/next.md` first.
5. **The owner's build:** `scripts/copy-notes.ps1` joins `releases/next.md` (if it exists) and the files of
   `releases/next/` (by name) into one copy, `next.md`, in the app. "Next release (test build)" in Settings shows it,
   as today.
6. **A friend's build:** the release refuses while small files are left (rule 4), and it renames `releases/next.md`. So
   the friend APK holds no `next.md`, as today (spec 0018 criterion 30).
7. **The notes on `main` today:** the lines in `releases/next.md` stay where they are. The final notes of the next
   release join them with the small files. New changes add small files only.
8. **What stays:**
   - The format of the notes (spec 0018 §3.3 and amendment 1).
   - The card never shows the notes of the next release.
   - A failure or a dry run of `release.ps1` puts everything back.

## Acceptance criteria
**The release command**
1. `release.ps1` refuses when a `.md` file is in `releases/next/`.
2. `release.ps1` still refuses when `releases/next.md` does not exist.
3. The friend APK of `release.ps1 -DryRun` holds no `next.md`.
4. After `release.ps1 -DryRun`, the working tree is clean.

**The copy in the app**
5. `copy-notes.ps1` joins `releases/next.md` and the files of `releases/next/` into one `next.md` in the app.
6. The joined copy holds the lines of `releases/next.md` first, then the files of `releases/next/` by name.
7. With only small files and no `releases/next.md`, the copy holds the small files.
8. With no `releases/next.md` and no small file, the app holds no `next.md`.

**Docs**
9. `RELEASING.md` and `CLAUDE.md` say that each change adds its own file in `releases/next/`.

**Check and release**
10. Rules, numbers and the save do not change.
11. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
