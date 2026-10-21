# Plan 0012: Build "Professions"

Status: accepted
Spec: `specs/0010-professions.md` (accepted, 2d0390c) · Intent: `intent/0010-professions.md` (accepted, 9e8208a)
Product owner: Zkalf · Date: 2026-10-21

## What changes in the code
- **Data:** new `professions.json` (Mining, Woodcutting, Crafting: name, icon, tool slot, tiers, teacher name,
  lines, starter tool, tips by level). `world.json`: Oak, Ash and Pine trees in Goblin Woods, Grey Moor and Mountain
  Pass; every spot gets `profession` and `rareFind`; spot `level` is now the profession level (Copper 1, Iron 10,
  Mithril 20). `items.json`: logs, gems, heartwoods, dust (five), shards (three), starter and crafted tools (`tool`:
  profession, tier step factor), rings and trinkets (spec §5.2); log inputs per spec §4; tool, ring, trinket and
  shard recipes. Recipes' `level` becomes the Crafting level (numbers unchanged). `economy.json`:
  `professionXpToReachLevel`, `professionBands`, `professionShare`, `fightXpPerStep`, `toolQualityStep`, `rareBase`,
  rare-find nudges, `shardBase`, shard step per quality, `rerollSteps`, `rerollDust` (3). Validation: every spot and
  recipe names a profession that exists, every rare find and shard is an item, tips name real monsters.
- **`rng.dart` / `state.dart`:** a second generator, the profession stream, seeded by a fixed hash (spec §9.1). Save
  version 8: `professions` (XP), `learned`, `tools`, `professionRng`, `tips`; a Legendary's waiting stat roll lives in
  its item key (`…+pending:hit4`), so stacking and saving need no new map. `migrate` per spec §10: XP from the
  `gathered.*` / `crafted.*` counters × data `xp`, Mining and Crafting learned, starter pickaxe and hammer worn.
- **`game.dart`:** `professionLevel`, `professionFade`; `nodeLevelMet` / `recipeLevelMet` read the profession
  level and `learned` (the character-level checks of spec 0008 amendments 1–2 go); gather and craft pay profession XP
  and the quarter character XP (spec §2.4); tool step discount; rare-find roll per gather; `learn(s, profession)`
  and tips; `salvage`, `reroll` (a forge activity like a craft of one), `keepRoll(s, item, keepNew)`; shard
  recipes. Every new roll draws from the profession stream only. News events for profession level-ups, finds, tips,
  shards and rerolls. Next goal names a missing profession level.
- **Simulator and tools:** `SensiblePlayer` learns all three on day 1, counts tools as upgrades, gathers logs,
  salvages, rerolls and crafts uniques (spec §9.2). New `FighterPlayer` and `GathererPlayer`. `tool/tune.dart` writes
  `fightXpPerStep` from the reference player. `tool/seeds.dart` reports, per seed, the day of level 5/10/30, the day
  of Mining and Crafting 10 and 20, and the fighter's and gatherer's results (spec §9.3).
- **App:** `professions_tab.dart` rebuilt as the three profession cards (spec §8.1) with Crafting's recipe list
  inside; camp teachers in Now's Here list and a `teacher_sheet.dart`; spot rows with profession level and colour;
  item card: tool lines, Salvage, Reroll, the Legendary stat reroll and Keep new / Keep old; Lore tab shows tips
  under each teacher; labels for the new news lines.
- **Old tests:** tests that check a character level on spots or recipes, or character XP from crafting and mining,
  are rewritten in one commit next to their failing replacements, each pointing to the spec 0010 line that
  overrides it. The pacing test adds spec §9.3 targets 2–3.

## Order of work
### M1: Profession levels, character XP, woodcutting, save version 8, tuning
Failing tests first for criteria 1–3, 6, 13 and the stream part of 12, then the rules, data (professions, trees,
logs), `migrate`, the three walkers and `fightXpPerStep`. Teachers exist in rules (learn, starter tools), with no
screen yet. Tools other than starters, rare finds and salvage wait for M2. Tune per spec §9.4: profession XP table,
then `professionShare` (at most 0.35), then logs. If the mixed walker can't meet §9.3 target 1, stop and ask the
owner. **Proof:** `.\scripts\check.ps1` green; every fixture save loads with the expected profession levels; the
8-seed table with the fighter and gatherer columns in the PR description; the gatherer's day-90 level put to the
owner (target 4).

### M2: Tools, rare finds, rings and trinkets, salvage, rerolls, shards
Failing tests first for criteria 4–5, 7–12, then crafted tools and their discount, rare finds, ring and trinket
recipes, salvage, quality and Legendary stat rerolls, shards and shard recipes, tips. The walker uses all of it. Retune
until §9.3 holds again. **Proof:** check green; the criterion 12 test (same fights with and without salvaging); the
8-seed table in the PR.

### M3: Screens (install)
Failing widget tests first for criteria 4, 13–14 (with `MemorySaveStore`), then the Professions cards, teachers in
Now, the teacher sheet, item card actions, Lore tips and the news lines. **Proof:** check green,
`.\scripts\check.ps1 -Release`, `.\scripts\device-smoke.ps1 -Install` (owner asked first), the owner's save loads
on the phone with Mining and Crafting at the levels it earned; the verifier checks the whole change against spec
0010.

Each milestone is its own branch and PR, reviewed per `REVIEW.md`; the owner merges.

## Risks
| Risk | Mitigation |
|---|---|
| The quarter-XP rule slows the walker past day 100 | Spec §9.4 order of tuning in M1; the owner decides before monsters or the XP table change |
| The walker's new trips (logs, tools) shift the 8 seeds | Tuned by targets, not exact days; all new rolls on the profession stream (criterion 12 test) |
| Profession pace fits the walker but feels slow to real players who craft more | Seeds report profession days; the owner playtests after M3 and tuning stays data-only |
| A waiting Legendary roll in the item key confuses old code paths (labels, equip) | Tests equip, swap, save and reload an item with a waiting roll; labels strip it like bonus stats |
| Old saves with lots of crafting open at high Crafting | Expected (spec concern 5); migrate shows no level-up news |
| Three walkers make the pacing test slower | Fighter and gatherer run in `tool/seeds.dart` and one pacing test seed each; the mixed walker keeps all 8 |
