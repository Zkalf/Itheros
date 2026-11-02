# Plan 0042: Build "A reroll at Camp takes its dust from the bank" (spec 0020 amendment 1)

Status: accepted
Spec: `specs/0020-item-bank.amendment-1.md` · Issue: #181 · Product owner: Zkalf · Date: 2026-11-02

## What changes in the code
**game_core** (`packages/game_core/lib/src/game/`)
- `queue.dart`:
  - `_rerollRefused`: counts the bank's dust too when the reroll happens at a place with a bank. The check that
    `craftUsesBank` does for a craft does this for a reroll.
  - `_missingToStart`: the same count for a reroll.
- `run.dart`: the reroll takes its dust with `_useInput` (bag first, then bank), not `addItem(dust, -n)`.
- `items.dart`, `bagAfterQueue`: a waiting reroll at a place with a bank counts the bank, as a waiting craft does.

**app**
- No screen code. The item card adds the reroll through the queue, which now counts the bank.
- `releases/next.md`: one line for players.

## Order of work (one PR)
1. The failing tests, committed alone:
   - `packages/game_core/test/bank_test.dart`: criteria 1-4.
   - `app/test/bank_screens_test.dart`: criterion 5.
2. The code and the `releases/next.md` line.
3. **Proof:** `.\scripts\check.ps1 -Release` green. Review per `REVIEW.md`; the owner merges.

Branch `feat/reroll-dust-from-bank`.
