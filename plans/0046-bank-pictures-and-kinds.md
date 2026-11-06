# Plan 0046: Build "Pictures, item cards and kinds on the bank screen and in the bag" (spec 0020 amendment 2)

Status: accepted
Spec: `specs/0020-item-bank.amendment-2.md` · Issues: #197, #109 · Product owner: Zkalf · Date: 2026-11-06

## What changes in the code
**game_core**
- `lib/src/game/items.dart`: an `enum ItemKind { gear, tool, meal, material }` and `GameData.kindOf(key)` (rules 1-2),
  next to `bagOrder`. Exported from `game_core.dart`.
- A unit test for criterion 1.

**app**
- A new `lib/ui/kind_chips.dart`: the row of five choice chips (rules 3, 5-8). It takes the picked kind (`null` =
  All) and a callback.
- The picks live in memory in `GameController`: a map from the list (bag, bank's Bag tab, bank's Bank tab) to the
  picked kind (rules 9-11). The save does not change.
- `lib/ui/bag_grid.dart`: the chips above the grid, the grid filtered by the pick, the empty line (rule 8).
- `lib/ui/bank_screen.dart`:
  - the chips at the top of each tab;
  - each row starts with `PictureSocket.item` at 48 dp, which draws the ring (rules 12-14);
  - a tap opens the item card in a bank mode (rules 15-20). The Store/Take sheet goes away.
- `lib/ui/item_card.dart`: a bank mode, set by `showItemCard(..., bank: BankSide.bag | BankSide.bank)`:
  - it keeps the picture, the name, the kind, the stats and the bonus stats;
  - it hides Equip, Swap, Eat, Auto-eat, Salvage, Salvage all and Reroll;
  - at Camp it shows Store all and Store some…, or Take all and Take some…, with the `CountDialog`.
- `releases/next/feat-bank-pictures-and-kinds.md`: one line for players.

## Tests (`app/test/`)
- A new `bank_kinds_test.dart`: criteria 2-29.
- The bank tests of spec 0020 that tapped the old Store/Take sheet now tap the card. Their checks stay.

## Order of work (one PR)
1. The tests: criteria 1-29.
2. The code and the notes line.
3. **Proof:** the Character tab bag and both bank tabs, with All and with one kind, and the item card from the
   bank, rendered at 408 dp wide (`CLAUDE.md`). `.\scripts\check.ps1 -Release` green. Review per `REVIEW.md`; the
   owner merges.

Branch `feat/bank-pictures-and-kinds`.
