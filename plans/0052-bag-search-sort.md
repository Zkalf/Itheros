# Plan 0052: Build search and sort in the bag and the bank (spec 0020 amendment 4)

Status: accepted
Spec: `specs/0020-item-bank.amendment-4.md` · Issue: #221 · Product owner: Zkalf · Date: 2026-11-06

## What changes in the code
**game_core**
- No change. The sorts are screen order only; `bagOrder` stays the base of every sort (rule 11).

**app**
- `lib/game_controller.dart`: `sortPicks`, a map from list name to `ItemSort`, next to `kindPicks`. It lives in
  memory only (rules 13-15).
- `lib/ui/kind_chips.dart`:
  - `ItemSort` (`bagOrder`, `name`, `count`, `quality`) and its words on screen (rule 10).
  - `KindFilter` keeps the search text in its own state, so it clears when the list leaves the screen (rule 9).
  - Below the chips: a row with the search field (keys `search-<list>`, `search-<list>-clear`) and the sort button
    (key `sort-<list>`, menu items `sort-<list>-<sort>`).
  - It filters by kind, then by the words of rule 5, then sorts with a stable sort on top of `bagOrder` (rule 11).
  - The empty line of rule 8.
- `lib/ui/bag_grid.dart`, `lib/ui/bank_screen.dart`: they pass the counts to `KindFilter` for the Count sort.
- New `test/bag_search_sort_test.dart`: criteria 1-29.
- `releases/next/feat-bag-search-sort.md`: one line for players.

No change in `data/` or in the save.

## Order of work (one PR)
1. The tests: criteria 1-29.
2. The code and the notes line.
3. **Proof:** the bag on the Character tab and both tabs of the bank screen rendered at 408 dp wide, with a search and
   a sort picked (`CLAUDE.md`).
   - `.\scripts\check.ps1 -Release` green. The pacing sims do not run, as `packages/` does not change.
   - The verifier runs alongside the local check, before the PR.
   - Review per `REVIEW.md`; the owner merges.

Branch `feat/bag-search-sort`.
