# Spec 0016 amendment 1: one word for a walk

Status: accepted
Amends:
- [spec 0016](0016-queue-rework.md) §7.1 (the line of a walk on the queue card)
- [spec 0006](0006-more-screens.md) §2.2 (the "Travel here" button), as spec 0008 §3.3 keeps it
Product owner: Zkalf (chose "walk everywhere" after the playtest of 0f14008, 2026-10-24)
Date: 2026-10-24

## Why
The game shows one action with two words:

| Where | Text before this amendment |
|---|---|
| World map, area sheet | "Travel here" |
| Queue card, a waiting walk | "Travel to Copper Hills · 300 steps" |
| Action sheet | "Walk to Copper Hills first: 300 steps, one more slot." |
| Queue card, the current action | "Walking to Copper Hills" |
| Report | "Walked to Copper Hills (300 steps)." |

The owner read the change of word as a change of action. `WRITING.md` rule 1 asks for one name for each thing.
The glossary words in issue #63 name this action a **walk**.

## Change
1. The button on the area sheet of the World map reads **"Walk here"**.
2. A waiting walk on the queue card reads **"Walk to Copper Hills · 300 steps"**.
3. Every other text of a walk stays as it is. They use "walk" already.
4. The code keeps its names (`Activity.travel`, `ActivityKind.travel`, `leg`). Players never see them.
5. The achievement "Travelling Salesman" keeps its name. It is the name of an achievement, not the name of the
   action.

## Acceptance criteria
**Screens**
1. The area sheet of a place where the character is not shows the button "Walk here".
2. No screen shows the button "Travel here".
3. The queue card shows a waiting walk as "Walk to Copper Hills · 300 steps".
4. No screen shows a waiting walk as "Travel to …".

**Release**
5. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
