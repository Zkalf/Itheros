---
name: small-feature
description: Use when the owner picks an idea or nit that changes a rule or a screen of an existing system (not data only, not a bug), so it needs a spec change or a short spec and a plan before code. Drafts both from the templates and asks only the owner's decisions.
---

# A small feature: spec change and plan

Small features stay small (`CLAUDE.md`): a short spec or spec change with a handful of criteria, and one PR.

## 1. Find what it changes
1. Read the issue (`gh issue view <n>`) and its "Open questions".
2. Find the spec sections that it touches: `grep -n -i "<word>" specs/*.md`. Read those sections. Each spec is one
   living file (plan 0068).
3. Read the code that runs it today, enough to know what the change costs. Read `docs/game-direction.md` for a design
   choice.
4. **Pick the kind:**
   - Numbers or content that fit an existing system: data only in `data/*.json`, no spec. Stop this skill.
   - A broken rule: a bug. Use the `bugfix` skill.
   - A change to an existing system: an edit of its spec, `specs/NNNN-<name>.md`, and of each other spec it touches.
   - A new system: an intent first, then a spec (`intent/`, `specs/TEMPLATE.md`).

## 2. Ask only the owner's decisions
5. Ask with `AskUserQuestion`, at most 2-4 questions in one go: game choices (what the player gets, what it costs,
   what asks first). Put the recommended option first. Decide plumbing yourself (names, files, order of work).
6. Use plain words. Name each choice so that it reads without the rest of the chat.

## 3. Draft
7. **The spec change**, in the words of `WRITING.md`:
   - Edit the sections that change. Each section and criterion keeps its number; a new one takes the next free number.
     A removed criterion keeps its number with "Removed on <date> (#N)."
   - Screens: each item, monster or spot shows its picture and opens its card (`CLAUDE.md`). Keep the "Check and
     release" criteria true.
   - Add one History line, ending with "(draft)": the date, the issue, the change, the owner's choices, and the
     sections and criteria.
   - Put the "why" (what the player misses today) in the History line or the plan, not in a new section.
8. **The plan** from `plans/TEMPLATE.md` (next free number): the files that change in `game_core`, `app`,
   scripts and docs; the tests with the criteria they cover; one PR; the proof; the branch.
9. A change that does not move the pace gets no sim targets: the pacing test is the guard.

## 4. Accept and build
10. Show the owner a short summary of the spec change and the plan (not the full text), with the choices you made
    yourself. Ask:
    "accepted", or what to change.
11. On "accepted": remove "(draft)" from the History line and set `Status: accepted` in the plan. Commit them alone
    on the branch (`Spec NNNN and plan NNNN: <what> (#issue)`). A later change to either adds a new History line.
12. Build it: the tests of the criteria first, then the code. Then use the `ship-pr` skill.
