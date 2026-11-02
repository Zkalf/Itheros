# Spec 0020, erratum 1: the names of the two banks

Status: draft
Corrects: [spec 0020](0020-item-bank.md) §4 point 23; [plan 0040](../plans/0040-item-bank.md) "What changes in the
code" (the field `GameState.bank` and the controller's `store` and `take`)
Issue: #66
Product owner: Zkalf
Date: 2026-11-02

## What was wrong
- Point 23 names the new save field `bank`. The save already has a field `bank`: the step bank.
- With two banks, the plain name `bank` does not say which one it is.
- Plan 0040 names the controller's moves `store` and `take`. The controller already has a field `store`: the save
  storage.
- Claude's mistake: the spec and the plan did not check the names. The tests found the clash.

## Correction
1. The item bank is `GameState.itemBank`, saved as `itemBank`.
2. A place with an item bank has `"itemBank": true` in `world.json` (`LocationDef.itemBank`).
3. The step bank is `GameState.stepBank`, saved as `stepBank` (the owner asked for this on 2026-11-02).
4. A save from before version 16 has the step bank under `bank`. The game reads it as `stepBank`, so every old save
   keeps its steps.
5. Spec 0020 §4 point 23 reads: "Save schema 16 (`GameState.schemaVersion`). A new field `itemBank`: a map of item
   keys to counts. The step bank's field becomes `stepBank`; a save before 16 loads its `bank` into it."
6. The controller's moves are `storeInBank(key, count)` and `takeFromBank(key, count)`.
7. Nothing else changes: the rules, the screens and the words stay as spec 0020 says.
