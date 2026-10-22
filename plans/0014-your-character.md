# Plan 0014: Build "Your character"

Status: accepted
Spec: `specs/0012-your-character.md` (accepted, 0ec58a0) · Intent: `intent/0012-your-character.md` (accepted, b144d46)
Product owner: Zkalf · Date: 2026-10-22

## What changes in the code
- **Data:** new `origins.json` (six origins: id, title with `{a|b|c}` where gendered, line, profession).
  `economy.json`: `headStartLevel` 5; the Adventurer rank line names `{name}`. `professions.json`: each teacher
  gains `greeting` and `kinLine` (spec §3.1); Bram's level 10 tip gets `{lad|lass|friend}`. Validation: every origin
  names a known profession, one origin per profession, every `{…|…|…}` has exactly three choices.
- **`state.dart`:** save version 10, `character` (`name`, `gender`, `origin`) or none; old saves load with none.
- **`game.dart`:** `makeCharacter(state, name, gender, origin)`: trims the name (empty → Wanderer, at most 20),
  learns the origin's profession with its starter tool if needed, raises its XP to level 5 only if lower, no news, no
  draws. `renameCharacter` and `setGender` for Settings. One `fill(line, character)` for `{name}` and `{a|b|c}`.
- **Simulator:** `SensiblePlayer`, the fighter and the gatherer are made as Miner's child. No new sim tool or report.
- **App:** "Who are you?" screen (name field, gender segments, six origin cards, Set out) in `app.dart`'s flow after
  permission and before level-up cards and the away screen; Settings rows Name, Gender, Origin; the teacher sheet's
  greeting or kin line; the Character header (name, rank · origin); the journal title "<name>'s journal".
- **Old tests:** widget tests that build a fresh game and expect Now get a character made in their setup (a test
  helper), since a save with no character now opens the new screen.

## Order of work
### M1: Rules, data, save version 10
Failing tests first for criteria 3–6 (rules side), 7's data, 10 and the token check, then the data, rules, `migrate`
and the walkers. **Proof:** `.\scripts\check.ps1` green, including the existing pacing test with Miner's child
walkers (criterion 11); every fixture save loads as version 10 with no character; a test that `makeCharacter` takes
no draw from either generator. If the pacing test tips a seed, the PR shows the 8-seed table and asks the owner before
any tuning. Branch `plan14-m1`, PR, review per `REVIEW.md`; the owner merges.

### M2: Screens (install)
Failing widget tests first for criteria 1, 2, 6 (screen side), 7, 8 and 9 (with `MemorySaveStore`), then the screens.
**Proof:** `.\scripts\check.ps1 -Release` green; `.\scripts\device-smoke.ps1 -Install` (owner asked first): the
owner's save opens on "Who are you?" once, keeps its level and items, and the origin's profession shows at least 5;
the verifier checks the whole change against spec 0012. Branch `plan14-m2`, PR, review; the owner merges.

## Risks
| Risk | Mitigation |
|---|---|
| Many widget tests start from a fresh save and now land on the new screen | One helper that makes a character, added to their setup in M2's first commit |
| Starting Mining at 5 tips a pacing seed past an edge | Shown in M1's PR with the table; tuning only with the owner (spec §5.2) |
| A typo in a `{a|b|c}` line shows raw braces | Data validation test (spec concern 3) |
| The device smoke script expects Now after launch | Script waits for either Now or "Who are you?"; the owner's save is checked by hand on the phone |
