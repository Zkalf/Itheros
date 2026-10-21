# Plan 0010: Build "Character and world layout"

Status: accepted
Spec: `specs/0008-character-and-world-layout.md` · Intent: `intent/0008-character-and-world-layout.md` (accepted, 2beba9f)
Product owner: Zkalf · Date: 2026-10-21

## What changes in the code
- **`data.dart` / JSON:** `unlockLevel` leaves `world.json`, `enemies.json`, nodes and recipes (and the loader
  rejects it, so none comes back by accident). `economy.json`: `gearSlots` becomes the ordered list of 16 slots
  (id, slot kind, no level); `queueSlots` becomes a single number, 3. `items.json`: `slot` uses the new kinds
  (`mainHand`, `offHand`, `chest`, `head`, `boots`, `neck`, `cloak`, `ring`, `trinket`, …), optional
  `twoHanded: true`; the Bear-pelt cloak moves to `cloak` with trimmed stats. Validation: every item's kind has a
  slot; `twoHanded` only on `mainHand`.
- **`state.dart`:** equipment keyed by slot id (`ring1`, `ring2`, …); the inventory is the bag (same item-key →
  count map, so stacking is free); new `explored` set. Save version 6; `migrate` maps old slots (spec decision 4),
  fills `explored` from the visit counters plus the current area.
- **`game.dart`:** every `unlockLevel` check goes; `isFogged` uses `explored` + routes; travel and auto-travel refuse
  fogged areas; arriving adds to `explored`. `equip(s, item, slot)` / `unequip(s, slot)` with the two-hand rules
  and ring/trinket choice, run through the controller's one queue like any action. Stop conditions offered from
  level 1. Level-up news drops "opens at this level" items (keeps stats, ranks, talent points, colour news). Next
  goal: Hide allowed from level 1. Queries for the UI: `compare(s, item, slot)`, `itemSources(item)`,
  `itemUses(item)`.
- **App:** `home_shell.dart` with Now · World · Professions · Character and the top bar (Journal, Trophies,
  Settings). `map_tab.dart` → `world_tab.dart` (new fog text); `craft_tab.dart` → `professions_tab.dart`;
  `now_tab.dart` gets the **Here** section (reusing the area sheet's monster and spot rows) and the Forge row; new
  `settings_screen.dart`; `character_tab.dart` rebuilt with Gear / Bag tabs, `paper_doll.dart`, `bag_grid.dart`,
  `item_card.dart`. `labels.dart`: a plain-name variant without the bracket for the doll, bag and card title.
  Icons are Flutter's built-in Material icons (no new assets).
- **Old tests:** tests that assert the gates spec 0008 removes (`unlocks_test.dart`, parts of `queue_test.dart`,
  `progression_test.dart`, `ui_test.dart`) are rewritten to the new rules in the same commit as their failing
  replacements, each change pointing to the spec 0008 line that overrides it.

## Order of work
### M1: Rules and save, tests first
Failing tests committed first for criteria 3, 4, 5, 6, 7, 11, 12, 13 (rules side), then implement. Cloak stats
tuned until the pacing tests pass. **Proof:** `.\scripts\check.ps1` green, pacing tests unchanged in their targets,
every fixture save loads.

### M2: New shell, Now, World, Professions, Settings (first install)
Four buttons and the top bar; the Here section and Forge row; World with the new fog; Professions = old Craft;
Settings page. Character keeps today's list for now. Widget tests (`MemorySaveStore`) for criteria 1, 2, 5 (UI side).
**Proof:** check green, `.\scripts\check.ps1 -Release`, `.\scripts\device-smoke.ps1 -Install`; the owner tries it on
a walk.

### M3: Character: doll, bag, item card (second install)
Paper doll, bag grid, item card with Equip / Swap / Unequip and the two-hand and ring messages. Widget tests for
criteria 6–10 (UI side) and 2 (equip from the new screens). **Proof:** check green, `-Release`, smoke with install,
the owner's save intact on the phone; the verifier checks the whole change against spec 0008.

Each milestone is its own branch and PR, reviewed per `REVIEW.md`; the owner merges.

## Risks
| Risk | Mitigation |
|---|---|
| The open world shifts the pacing simulator's choices | The simulator already picks the best yellow monster; M1 runs the pacing tests before any tuning and reports if a target moves |
| A doll with 16 slots is cramped on the phone | Two columns of 6 plus a bottom row of 4, squares sized from the screen width; checked on the Fairphone in M3 |
| An item lost while swapping (two-hander, rings) | Criterion 6 tests every equip path, checking the total item count before and after |
| The old save's equipment keys | Migration test on both fixture saves plus a hand-made save wearing a cloak |
