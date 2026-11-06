# Plan 0050: Build the playtest fixes of 2026-11-06 (four small amendments)

Status: accepted
Specs: `specs/0020-item-bank.amendment-3.md` (#220), `specs/0014-quiet-teal.amendment-10.md` (#222),
`specs/0010-professions.amendment-10.md` (#223), `specs/0001-walking-core-loop.amendment-3.md` (#225) · Product
owner: Zkalf · Date: 2026-11-06

## What changes in the code
**#220, the bank screen's tabs**
- `app/lib/ui/journal_screen.dart`: the tab box (`_TabBox`) and its plate become a shared widget in
  `app/lib/ui/tab_boxes.dart`.
- `app/lib/ui/bank_screen.dart`: the tabs Bank, Bag in boxes on a plate, Bank first and open by default
  (`initialIndex: 0` with Bank first). The tab keys stay (`bank-tab-bank`, `bank-tab-bag`).

**#222, the launcher icon**
- The `ic_launcher_foreground.png` and `ic_launcher_monochrome.png` of each density, scaled up so the emblem is about
  74 dp across. A throwaway Flutter test does it with `dart:ui` (Pillow is not installed); it is not committed.
- `app/test/quiet_teal_files_test.dart`: the safe-zone test becomes "the emblem covers the 72 dp circle".

**#223, the reason line**
- `packages/game_core/lib/src/game/queue.dart` (`_needs`): "… needs Woodcutting 8 (you have 5)".

**#225, day one**
- `app/lib/sync/sync_service.dart` (`newSave`): the save of a new game credits nothing on its first day, so the
  first sync gives the game the whole day. Old saves keep their `credited` map, so they do not change.

- `releases/next/fix-playtest-fixes.md`: lines for players.

## Tests
- #220: the bank tests open the bank on the Bank tab; a new test for criteria 1-4.
- #222: `quiet_teal_files_test.dart` criteria 1-3.
- #223: a game_core test for criteria 1-3; the app and queue tests with the old line follow it.
- #225: a sync test for criteria 1-2, a controller test for criterion 3, a save test for criterion 4.

## Order of work (one PR)
1. The tests, then the code and the icon files.
2. **Proof:** the bank screen and the icon rendered at 408 dp (`CLAUDE.md`), the smoke test on the phone for the icon.
   `.\scripts\check.ps1 -Release` green (with the pacing sims: `game_core` changes). Review per `REVIEW.md`; the owner
   merges.

Branch `fix/playtest-fixes`.
