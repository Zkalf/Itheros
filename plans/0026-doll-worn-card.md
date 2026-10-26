# Plan 0026: Build "A tap on a worn item opens its card" and "The worn row shows its bonus stats"

Status: accepted
Spec: `specs/0008-character-and-world-layout.amendment-4.md` and `specs/0009-fights-with-depth.amendment-2.md` ·
Product owner: Zkalf · Date: 2026-10-26

Names of files, widgets and tests refer to `main` at `a80bdc1`.

## What changes in the code
- `app/lib/ui/paper_doll.dart`: a tap on a filled slot calls `showItemCard(context, c, worn, wornIn: id)`. A tap on
  an empty slot calls `showSlotSheet`, as today.
- `app/lib/ui/item_card.dart`: `_gearActions` for a worn item (`wornIn` set) shows a row with two buttons:
  - **Change** (key `card-change`): it closes the card and calls `showSlotSheet(host, c, slot)`.
  - **Unequip** (key `card-unequip`), as today.
- `app/lib/ui/slot_sheet.dart`: the subtitle of the worn row becomes a column:
  - the base stats line, as today;
  - one line for each entry of `data.bonusRolls(worn)`, in `itemColour`, as on the item card.
- `app/test/ui_test.dart` and `app/test/images_test.dart`: tests that tap a filled slot and expect the slot sheet
  (for example the chest slot in `images_test.dart` and "Swap compares with what is worn; Unequip from the doll")
  follow the new route. They open the card, or tap Change to reach the sheet.
- No change to `game_core`, the data, the save or the sim.

## Order of work
### M1: The worn card and the worn row (one PR)
- First, the failing widget tests, committed alone:
  - A tap on the filled Head slot opens the item card of the worn item (amendment 4, criterion 1).
  - A tap on an empty slot opens its slot sheet (amendment 4, criterion 2).
  - With a two-hander worn, a tap on the Off hand opens the Off hand slot sheet (amendment 4, criterion 3).
  - The card of a worn item shows Change and Unequip; Change opens the sheet of that slot; Unequip moves the item
    to the bag (amendment 4, criteria 4-6).
  - The card of a bag item has no Change (amendment 4, criterion 7).
  - In the slot sheet, the worn row of an Epic item shows its base stats and each bonus stat on its own line; two
    equal stats show two lines; a Common item shows only the base stats line (amendment 2, criteria 1-4).
  - A bag row in the slot sheet shows its change line and no bonus stat line (amendment 2, criterion 5).
  - The existing tests that tap a filled slot change to the new route in the same commit.
- Then the code.
- **Proof:** `.\scripts\check.ps1 -Release` green. The verifier checks the change against both amendments.
- Branch `fix/doll-worn-card`, in the main folder (one session). PR with the two amendments and this plan, review
  per `REVIEW.md`. The owner merges.
