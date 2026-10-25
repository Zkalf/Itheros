# Spec NNNN: <short name>

<!--
A guide, not a form. Keep the header and the acceptance criteria. Use the other sections that fit, rename them,
add your own, and leave out the rest. Follow WRITING.md. Copy this file to the next free number.
-->

Status: draft
Intent: [intent/NNNN-<name>.md](../intent/NNNN-<name>.md) (accepted, PR #N)
Builds on: <specs and sections this one starts from>
Overrides: <specs, sections or criteria this one replaces; "nothing" if none>
Product owner: Zkalf
Date: <YYYY-MM-DD>

<Two to four sentences: what the player gets, in plain words.>

## 1. Decisions
<!-- Each choice the intent left open, and who made it. -->

| # | Question | Decision |
|---|---|---|
| 1 | <question> | **<answer>** (owner). |

## 2. Rules
<!-- What the game does: the rules in game_core, with the numbers or where they live in data/*.json. -->

## 3. Screens
<!-- What the player sees and taps, with the words on screen. -->

## 4. Save
<!-- New or changed save fields, their defaults for old saves, and the save version. "No change" if none. -->

## 5. Balance
<!-- Does it move the pace? If so: the sim target. If not: "The pacing test stays green." -->

## 6. Out of scope
-

## 7. Acceptance criteria
<!-- One check per criterion (WRITING.md rule 13), grouped under short headings, numbered in one series (rule 14). -->
**<Group>**
1. <one thing that a test or the owner can check>

**Check and release**
2. Rules, numbers and the save change only as this spec says. The pacing test passes.
3. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
