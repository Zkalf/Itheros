# Spec 0020, erratum 1: the name of the bank in the save

Status: draft
Corrects: [spec 0020](0020-item-bank.md) §4 point 23; [plan 0040](../plans/0040-item-bank.md) "What changes in the
code" (the field `GameState.bank` and the controller's `store` and `take`)
Issue: #66
Product owner: Zkalf
Date: 2026-11-02

## What was wrong
- Point 23 names the new save field `bank`. The save already has a field `bank`: the step bank.
- Plan 0040 names the controller's moves `store` and `take`. The controller already has a field `store`: the save
  storage.
- Claude's mistake: the spec and the plan did not check the names. The tests found the clash.

## Correction
1. Spec 0020 §4 point 23 reads: "Save schema 16 (`GameState.schemaVersion`). A new field `bankItems`: a map of item
   keys to counts."
2. In plan 0040, the field is `GameState.bankItems`, saved as `bankItems`.
3. In plan 0040, the controller's moves are `storeInBank(key, count)` and `takeFromBank(key, count)`.
4. Nothing else changes: the rules, the screens and the words stay as spec 0020 says.
