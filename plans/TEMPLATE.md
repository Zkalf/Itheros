# Plan NNNN: Build "<name of the spec or amendment>"

<!--
A guide, not a form. Keep the header, the code changes and one section per milestone with its proof.
Add "Choices this plan makes" or "Risks" when they help. Follow WRITING.md. Copy this file to the next free number.
-->

Status: draft
Spec: `specs/NNNN-<name>.md` · Product owner: Zkalf · Date: <YYYY-MM-DD>

Names of files, widgets and tests refer to `main` at `<short commit>`.

## What changes in the code
<!-- Per file or package: what changes. Say what does not change: game_core, the data, the save, the sim. -->
- `<path>`: <change>.

## Order of work
### M1: <name> (one PR)
- First, the failing tests, committed alone:
  - <test> (criterion N).
- Then the code.
- **Proof:** `.\scripts\check.ps1 -Release` green. The verifier checks the change against criteria 1–N.
- Branch `<branch>`, in its own git worktree. PR with the spec and this plan, review per `REVIEW.md`. The owner
  merges.

<!-- More milestones as ### M2, M3: each ends with its proof, then a commit. -->
