# Plan 0047: Build "Pictures for the actions in the queue" (spec 0014 amendment 8)

Status: accepted
Spec: `specs/0014-quiet-teal.amendment-8.md` · Issue: #86 · Product owner: Zkalf · Date: 2026-11-06

## What changes in the code
**app**
- `lib/ui/images.dart`: a function `thingOf(GameData, Activity)` that maps an action to the `Thing` of its picture
  (rule 1): `MonsterThing`, `SpotThing`, `ItemThing` of the recipe's output or of the rerolled item, or `PlaceThing`.
- A small widget `ActionPicture(controller, activity, number:)`: the picture in a 48 dp socket, with the ring of a
  gear or tool item (rule 3), and the number badge on its top-left corner when `number` is set (rule 6).
- `lib/ui/now_tab.dart` (`_QueueCard`): the current action's row and each waiting row start with `ActionPicture`;
  the number circles go away (rules 4-7).
- `lib/ui/action_sheet.dart`: the title of a gather or a craft gets the picture in a 72 dp socket beside it (rule 8).
- `releases/next/feat-queue-pictures.md`: one line for players.

No change in `game_core`, `data/` or the save.

## Tests (`app/test/`)
- A new `queue_pictures_test.dart`: criteria 1-12.
- Tests of the queue card that looked for the number circles (`CircleAvatar` with "2", "3") change to the badge.
  Their checks stay.

## Order of work (one PR)
1. The tests: criteria 1-12.
2. The code and the notes line.
3. **Proof:** the queue card with a fight, a gather, a craft and a walk, and the sheet of a gather and of a craft,
   rendered at 408 dp wide (`CLAUDE.md`). `.\scripts\check.ps1 -Release` green. Review per `REVIEW.md`; the owner
   merges.

Branch `feat/queue-pictures`.
