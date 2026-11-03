---
name: ship-pr
description: Use when a change in this repo is written and must go to the owner as a pull request (anything outside the fast lane, see CLAUDE.md). Runs the full check, commits, opens the PR with its proof, reviews it per REVIEW.md and posts the review.
---

# Ship a pull request

The owner merges; Claude brings the change to a PR that is green, proven and reviewed. Do the steps in order.

## 1. Before the check
1. **Branch.** Work on a short branch (`feat/<name>`, `fix/<name>`), never on `main`. In parallel sessions, in a
   worktree (`CLAUDE.md`).
2. **Format.** Run `dart format` on each Dart file that a script or heredoc wrote: those skip the format hook.
3. **Line endings.** Python on Windows writes CRLF in text mode. Open files with `newline=''`, or fix them with
   `sed -i 's/\r$//'`. `git diff --stat` shows the real size of the change.
4. **Notes for players.** A change that players notice adds its own `releases/next/<branch>.md` (`feat/x` ->
   `feat-x.md`) with "- " lines in plain words. Never edit `releases/next.md` or another change's file.
5. **Look at each new or changed screen** (`CLAUDE.md`): render it at 408 dp wide (1224 px at device pixel ratio 3)
   with a throwaway widget test that loads the fonts, and read the image. Ask:
   - Can I tell the things apart?
   - Can I see what I choose?
   - Does each item, monster or spot show its picture and open its card?
   Delete the throwaway test before the commit. Show the owner the image when the look is new.

## 2. The check
6. Start `.\scripts\check.ps1 -Release` **in the background** (`run_in_background`). It takes 3-6 minutes. At most
   two run at a time on this PC.
7. While it runs, review your own diff (`git diff`), pass by pass of `REVIEW.md`. Do not poll the output file.
8. When it ends, read only the last lines: `CHECK PASSED in N s`, `APK CHECK PASSED`, and whether the pacing sims
   ran. If it fails, fix and run it again; the PR waits for a green check.

## 3. Commit and PR
9. Commit with `git commit -F .git-commit-msg.txt` (PowerShell mangles quotes). The message: one line in the words
   of `WRITING.md`, the plan and the issue in brackets, then the `Co-Authored-By` line.
10. Push with the branch named: `git push -u origin <branch>` (the gate blocks a bare push from `main`).
11. Write the PR body to a scratchpad file and run `gh pr create --title ... --body-file <file>`. The body has:
    - the spec and plan that it builds, in one line,
    - **What changes**: each file or part, in a short list,
    - **Proof**: each test file with the criteria it covers, the check line with its time, and what the owner can
      still check,
    - `Closes #N` for each issue it closes, so the merge closes them,
    - the attribution line. **No session link** (`claude.ai/code/session_...`): the repo is public.

## 4. Review
12. For a change with a spec: start the `verifier` agent in the background. Tell it the check already passed on this
    commit, so it runs only the new test files.
13. Prove each Important finding with a test before you post it. Fix what is cheap at once, in a new commit, and run
    the affected tests again.
14. Write the review per `REVIEW.md` (passes 1-7, at most 3 Nits) to a file and post it:
    `gh pr comment <number> --body-file <file>`.

## 5. Hand over
15. Tell the owner in plain words: what players get, the proof, anything that differs from the spec, and the merge
    command: `! scripts/merge.sh <number>`.
16. Update the project-status memory: the PR, its branch, what waits.
17. After the merge: steps that the plan puts after the merge (a dry run, an install on request). Never suggest a
    release.
