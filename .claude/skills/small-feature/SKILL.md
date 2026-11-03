---
name: small-feature
description: Use when the owner picks an idea or nit that changes a rule or a screen of an existing system (not data only, not a bug), so it needs a spec amendment or a short spec and a plan before code. Drafts both from the templates and asks only the owner's decisions.
---

# A small feature: amendment and plan

Small features stay small (`CLAUDE.md`): a short spec or amendment with a handful of criteria, and one PR.

## 1. Find what it changes
1. Read the issue (`gh issue view <n>`) and its "Open questions".
2. Find the accepted spec sections that it touches: `grep -n -i "<word>" specs/*.md`. Read those sections and their
   amendments. An accepted file never changes: the change comes as a new amendment.
3. Read the code that runs it today, enough to know what the change costs. Read `docs/game-direction.md` for a design
   choice.
4. **Pick the kind:**
   - Numbers or content that fit an existing system: data only in `data/*.json`, no spec. Stop this skill.
   - A broken rule: a bug. Use the `bugfix` skill.
   - A change to an existing system: an amendment, `specs/NNNN-<name>.amendment-N.md` (next free N).
   - A new system: an intent first, then a spec (`intent/`, `specs/TEMPLATE.md`).

## 2. Ask only the owner's decisions
5. Ask with `AskUserQuestion`, at most 2-4 questions in one go: game choices (what the player gets, what it costs,
   what asks first). Put the recommended option first. Decide plumbing yourself (names, files, order of work).
6. Use plain words. Name each choice so that it reads without the rest of the chat.

## 3. Draft
7. **The amendment** from `specs/AMENDMENT-TEMPLATE.md`, in the words of `WRITING.md`:
   - The header: `Status: draft`, what it amends (spec and sections), the issue, the owner's choices with the date.
   - **Why**: what the player misses today.
   - **Change**: numbered rules, with the words on screen, and **what stays**.
   - **Acceptance criteria**: one check each, grouped, numbered in one series. Screens: each item, monster or spot
     shows its picture and opens its card (`CLAUDE.md`). End with the "Check and release" group.
8. **The plan** from the newest plan in `plans/` (next free number): the files that change in `game_core`, `app`,
   scripts and docs; the tests with the criteria they cover; one PR; the proof; the branch.
9. A change that does not move the pace gets no sim targets: the pacing test is the guard.

## 4. Accept and build
10. Show the owner a short summary of both files (not the full text), with the choices you made yourself. Ask:
    "accepted", or what to change.
11. On "accepted": set `Status: accepted` in both, commit them alone on the branch
    (`Spec NNNN amendment N and plan NNNN: <what> (#issue)`). From now on the hook keeps them unchanged.
12. Build it: the tests of the criteria first, then the code. Then use the `ship-pr` skill.
