# Plan 0007: Build "More screens"

Status: accepted
Spec: `specs/0006-more-screens.md` · Intent: `intent/0006-more-screens.md` (accepted, 863ab8c)
Product owner: Zkalf · Date: 2026-10-19

## What changes in the code
- **`state.dart`:** `RunningActivity` gains `won`, `lost`, `gained` (item key → count) and `log` (last rounds:
  round, damage dealt, damage taken, or who was beaten). Save version 5; older saves load with an empty tally.
- **`activity.dart`:** `StopKind.untilQuality` with the quality id in `item`.
- **`game.dart`:** combat rounds append to the log (trimmed to `fightLogRounds`); wins, losses, drops, ore and
  crafts add to the tally; a drop sets `found.<monster>.<item>`; `_stopMet` for until-quality reads the tally;
  `stopKindsFor` offers it for crafts from level 5; `migrate` back-fills found drops (spec decision 6). Queries for
  the UI: `foundDrops(s, enemy)`, `isFogged(s, area)`, `nearestForge(s)`.
- **`data.dart` / JSON:** `world.json` locations get `map: {x, y}` and a top-level `mapRiver` point list and
  `mapAspect`; `economy.json` gets `fightLogRounds`. Validation: every location has a position in 0–1.
- **App:** `home_shell.dart` with five destinations; new `now_tab.dart`, `map_tab.dart` (a `CustomPaint` for paths
  and river under positioned, tappable area chips; an area sheet), `craft_tab.dart`; `adventure_tab.dart` is split
  into these and removed; `character_tab.dart` gets the headings and keeps settings; `action_sheet.dart` gets the
  quality choice; `labels.dart` gets log and tally lines. "Walked today" reads today's credited total from the save.

## Order of work
### M1: Rules, tests first
Failing tests committed first for criteria 3, 4, 7, 8, 11 (rules side) and 12, then implement. **Proof:**
`.\scripts\check.ps1` green, pacing tests included.

### M2: Now, Craft, Character (first install)
Bottom bar with all five screens; Map shows the area list from the old Adventure tab for now. Widget tests with
`MemorySaveStore` for criteria 1, 2, 3, 4, 9, 10. **Proof:** check green, then `.\scripts\check.ps1 -Release` and
`.\scripts\device-smoke.ps1 -Install`; the owner tries it on a walk.

### M3: The map (second install)
Drawn map, area sheet, fog, found drops (criteria 5, 6, 11). Widget tests tap areas and fogged areas.
**Proof:** check green, `-Release`, smoke with install, save intact; the verifier checks against spec 0006.

## Risks
| Risk | Mitigation |
|---|---|
| A drawn map is hard to read on a small screen | Labels under each chip, map scales to width and scrolls vertically; positions are data, so tweaks need no code |
| Losing an action while splitting the Adventure tab | Criterion 2 widget test does every action from the new screens |
| Save grows with the log | The log is a few short entries, trimmed every round |
