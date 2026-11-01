# Plan 0031: Build "Talent trees"

Status: accepted
Spec: `specs/0015-talent-trees.md` · Product owner: Zkalf · Date: 2026-10-31

Names of files, widgets and tests refer to `main` at `79bce22`.

## What changes in the code

### Data and data classes
- `packages/game_core/data/talents.json` (new): `rowEvery`, the trainer (name, title, location, lines), the reset
  numbers (`resetBase`, `resetStep`, `resetCap`, `resetCooldownSteps`), the two trees and the 18 talents of spec
  §2.3 and §2.4, with `needs` on Impale, Lucky hammer and Wayfarer.
- `packages/game_core/lib/src/data/talents.dart` (new part of `data.dart`): `TalentTreeDef`, `TalentDef` (id, tree,
  row, name, line, ranks, image, `effect`, `value`, `needs`), `TalentEffect` (the closed list of spec §2.8),
  `TrainerDef`, `ResetRules`.
- `packages/game_core/lib/src/data.dart`: loads `talents.json` and adds the data checks of spec §2.8.

### Save
- `packages/game_core/lib/src/state.dart`: schema version 13. New fields `talents` (`Map<String, int>`),
  `talentResets` (int), `resetPrice` (int) and `walkedSinceReset` (int), with the defaults of spec §4 for old saves.
- `packages/game_core/lib/src/game/migrate.dart`: drops ranks of unknown talent ids.
- A fixture `13`-shaped save is not added by hand: `release.ps1` adds the 0.7.0 fixture.

### Rules (`packages/game_core/lib/src/game/talents.dart`, a new part of `game.dart`)
- Queries: `talentPointsLeft(s)`, `ranksIn(s, tree)`, `rowOpen(s, talent)`, `canTakeRank(s, talent)` (null, or the
  reason of spec §3.1), `talentValue(s, effect)` (the sum of rank × value over the taken talents of one effect).
- Actions: `takeRank(s, talent)` and `resetTalents(s)`, which throw `ActivityError` with the words of spec §2.6 and
  §3.1. `resetPriceNow(s)` gives the price of spec §2.6.
- The effects, each where its rule lives today:
  - `progress.dart` `stats`: the percent and point talents (spec §2.2). The percent is of `_gearStats`.
  - `progress.dart` `bankCap`: `bankCap` talents.
  - `progress.dart` `professionSteps`: `professionSteps` multiplies with the tool and the meal.
  - `items.dart` `queueSlots`: `queueSlot`.
  - `world.dart` `_costOf` and `run.dart` (travel legs): `travelSteps` (Light pack, then Wayfarer), rounded up.
  - `odds.dart` `rollQuality`: a new `boost` argument (1 by default). `run.dart` passes `dropQuality` for monster
    drops, `craftQuality` for crafted gear and tools, `craftQuality` × `rerollQuality` for a quality reroll.
  - `run.dart` swing: the player's critical hit uses `critDamage` + the `critDamage` talent value. A monster's
    does not.
  - `run.dart` fight end (`_win`, `_lose`): `fightSteps` gives the saved steps back as progress (spec §2.3).
  - `run.dart` `_lose`: `lossXpShare` adds to `data.lossXpShare`.
  - `run.dart` gathering: `extraGather`, rolled on the profession stream.
  - `items.dart` `applySteps`: adds the walked steps to `walkedSinceReset`.
  - `deadlyWarning(s, enemy)`: true for red and skull, and for orange with `lossXpShare` rank 1 or more. The app
    uses it in place of its own colour test (`actions.dart`).

### Sim
- `packages/game_core/lib/simulation.dart`: `SensiblePlayer` gets `talentOrder` (a list of talent ids, empty by
  default). `decide` takes a rank of the first talent in the order that it can take, while points are left. With
  the default, nothing changes for the pacing test.
- `packages/game_core/tool/talents.dart` (new): runs the four builds of spec §5 (Combat, Utility, Split, none) for
  120 days at 5,000 steps, and prints days to level 25, the level on day 120 and the Rare-or-better monster drops.

### App
- `app/lib/ui/character_tab.dart`: a third tab, **Talents**, after Gear and Bag. The header line of spec §3.1.
- `app/lib/ui/talents_tab.dart` (new): the heading, the two tree tabs with their counts, the rows of plates with
  pips, the dim closed rows, the "Needs …" line.
- `app/lib/ui/talent_sheet.dart` (new): the sheet of spec §3.1 with **Learn · 1 point**.
- `app/lib/ui/trainer_sheet.dart` (new): Ysolde's sheet of spec §2.7, with the confirmation.
- `app/lib/ui/now_tab.dart`: Ysolde's row in Camp's Here list, under the teachers, with a dot when points are left.
- `app/lib/game_controller.dart`: `takeRank(id)` and `resetTalents()`, through the one queue. Each syncs first.
- `app/lib/ui/labels.dart` and `level_up_screen.dart`: the words of spec §3.2.
- `app/lib/ui/actions.dart`: the deadly-fight warning asks `game.deadlyWarning`.
- `app/lib/ui/images.dart`: each talent's `image` names an icon of the app's icon set (spec §6).
- `releases/next.md`: lines for players, one per milestone.

## Choices this plan makes
- **`talentValue` sums by effect**, so a talent added later with an effect that exists needs only data.
- **Swift strikes gives the steps back at the fight's end**, not round by round, so every round still costs 10 steps
  and the fight log does not change.
- **The deadly-fight rule moves into `game_core`** (`deadlyWarning`), as Wary changes it. Today the colour test sits
  in the app.
- **Two milestones, two PRs.** M1 has the rules, the data, the save and the sim, with no screen. The game looks as
  before in M1 (the ranks cannot be taken without the screen). M2 has the screens and the trainer.

## Order of work

### M1: Rules, data, save and sim (one PR)
- First, the failing tests, committed alone (`packages/game_core/test/talents_test.dart`):
  - points and rows: criteria 1-12
  - Combat effects: criteria 14-24
  - Utility effects: criteria 25-30, 33-38; and `deadlyWarning` for orange with and without Wary (criteria 31-32
    in the rules)
  - reset: criteria 39-47
  - save: criteria 55-57, by a round trip of `toJson`/`fromJson` and `migrate`
  - data: criteria 59-61, by `loadGameData` with a changed `talents.json`
- Then the code and the data.
- Then the sim: `dart run tool/talents.dart`. The numbers go into the results file (see Sim results). If a target
  of spec §5 is not met, the talent numbers move in `talents.json`, and the PR names each change.
- **Proof:** `.\scripts\check.ps1 -Release` green, with the pacing test (criteria 58, 63-64). The results file meets
  spec §5 (criterion 62). The verifier checks criteria 1-12, 14-47, 55-64 in the rules.
- Branch `feat/talents-rules`. PR with the spec and this plan, review per `REVIEW.md`. The owner merges.

### M2: Screens and the trainer (one PR)
- First, the failing tests, committed alone (`app/test/talents_screens_test.dart`, widget tests with
  `MemorySaveStore`):
  - the Talents tab, its heading, plates, pips and closed rows (criteria 48-51)
  - the "Needs Keen eye 3/3" line (criterion 13)
  - Learn takes a rank and fills a pip (criterion 52)
  - Ysolde in Camp with a dot; her sheet resets after the confirmation and shows the price (criteria 53, 39-40 on
    screen)
  - the deadly warning for an orange fight with Wary rank 1, and none without (criteria 31-32)
  - no screen shows "Talents arrive in a later update" (criterion 54)
- Then the code.
- **Proof:** `.\scripts\check.ps1 -Release` green (criteria 63-64). The verifier checks criteria 13, 31-32 and
  48-54. A phone install for the owner's playtest when the owner asks.
- Branch `feat/talents-screens`. PR, review per `REVIEW.md`. The owner merges.

## Sim results
An accepted plan does not change, so M1 writes the results in a new file of this plan:
`plans/0031-talent-trees.results.md`. It holds one table: days to level 25, the level on day 120 and the
Rare-or-better monster drops, for the builds None, Combat, Utility and Split. It also names each talent number that
the sim moved. That file is the record of spec criterion 62.
