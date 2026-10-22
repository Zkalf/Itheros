# Spec 0011: Lake and hunt

Status: accepted
Intent: [intent/0011-lake-and-hunt.md](../intent/0011-lake-and-hunt.md) (accepted, commit 8d4837c)
Builds on: spec 0010 + amendments 1–2 (profession levels, fade, the quarter character XP, tools, teachers and tips,
rare finds, the profession stream, the walkers), spec 0009 + amendment 1 (fights, bonus stats, 8-seed pacing), spec
0008 + amendments (Here list, Professions screen, item card, fog)
Overrides: spec 0008 decision 5 (fog) for hidden areas (§6.2); spec 0010 §8.1's card list (six professions), §9.2
(the walkers) and §9.3 (adds targets 5–6)
Product owner: Zkalf
Date: 2026-10-22

Fishing, Hunting and Cooking join the profession system of spec 0010: own levels and fade, a quarter of a fight's
character XP per step, a tool each, a teacher in camp, and every new roll on the profession stream. Fishing and
hunting are gathering: steps per action, each catch rolled from the spot's table. Fish and meat cook into meals
that buff the player for 3,000 steps; scales, hides and rare trophies craft gear for the five empty doll slots. A
message in a bottle leads to a hidden cove. All numbers are starting values in `data/*.json`, tuned with the pacing
simulator.

## 1. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | Where to fish | **One new lake area and two waters** (owner's choice): Mirror Lake (new area near Camp) is the tier 1 water; tier 2 and 3 are spots in areas that exist, the river under Troll Bridge and a cold tarn at Mountain Pass (§3.1). |
| 2 | Meal strength | **Noticeable** (owner's choice): one buff per meal, +6% / +10% / +14% by tier to HP, Attack or Defense, or as many percent fewer steps for profession actions. A perfect dish lasts twice as long (§5.3). |
| 3 | What hides, scales and trophies make | **Gear for the empty slots** (owner's choice): per tier, hides make Gloves, Bracers and a Belt, scales make Greaves (Legs), a rare hunting trophy makes a Shoulder mantle. Trophy fish make feasts (two buffs). 15 new gear items with small stats (§7). |
| 4 | Message in a bottle | **A chart to a hidden cove** (owner's choice): the first bottle reveals Smugglers' Cove, joined to Mirror Lake. Its water (Fishing 15) has trophy fish three times as often and a sunken chest holding a unique ring. Later bottles hold Rare dust (§6). |
| 5 | Where to cook | At the **camp fire** only, as the intent says. Meals keep in the bag, so a player cooks a batch before a long trip (concern 2). |
| 6 | Hunting danger | None: hunting is tracking, with no health bar or loss (intent). |
| 7 | Teachers' tips | Only the hunter tells monster tips (intent); the fisherman and the cook don't. |
| 8 | Catch weights | Fish only. Each species rolls a weight; heavy fish are rarer (§3.4). Animals have no weight. |

## 2. Professions

### 2.1 Three more professions
`professions.json` gains three entries in the spec 0010 shape (id, name, icon, tool, tiers, teacher, tips):

| Profession | Tool | Tier 1 (level 1) | Tier 2 (level 10) | Tier 3 (level 20) |
|---|---|---|---|---|
| Fishing | Rod | Lake | River | Tarn |
| Hunting | Bow | Deer | Elk | Ibex |
| Cooking | Cooking pot | recipes of level 1–9 | 10–19 | 20 and up |

Everything in spec 0010 §2 applies unchanged: the one profession XP table, the fade bands, level-up news ("Fishing
10: the river under Troll Bridge is yours to fish"), and character XP = steps walked × `professionShare` ×
`fightXpPerStep` × fade, after the tool's discount.

### 2.2 Teachers in camp
Camp's Here list gains **Wen, the fisherman**, **Sigrun, the hunter** and **Marta, the cook**, working as spec 0010
§6.1 (learn once, free; starter tool into its slot):

| Teacher | Starter tool | Line |
|---|---|---|
| Wen | Wen's old rod | "Take my old rod. Bring me back some fish." |
| Sigrun | Sigrun's old bow | "My old bow. Walk soft, aim low, and never follow a golden stag past dusk." |
| Marta | Marta's old pot | "Here's my old pot. Bring me fish and meat, and I'll show you what a fire is for." |

Sigrun tells tips (spec 0010 §6.2) at Hunting 1, 10 and 20:

| Level | Monster | Tip |
|---|---|---|
| 1 | Goblin brute | "Brutes wear goblin hide and nothing else. An edge does the work; just don't let it get its arms round you." |
| 10 | Wolf | "I've skinned a hundred wolves. Thin pelt over lean meat. Cut, don't poke." |
| 20 | Wyvern | "Wyvern scales lie like roof tiles. Swing and you slide off. Find the seam with a point." |

### 2.3 Tools
Rod, bow and cooking pot use spec 0010 §3 as it stands: one slot each, shown on the Professions screen; no tool, no
work; starter tools can't be salvaged; crafted copper / iron / mithril tools at Crafting 3 / 12 / 22 with the same
inputs and steps as the pickaxe; step cost 100 / 90 / 80 / 70% minus 2 points per quality step above Common. The
pot's discount applies to cooking steps.

## 3. Fishing

### 3.1 Waters

| Spot | Area | Fishing | Steps | XP | Scale per catch |
|---|---|---|---|---|---|
| Lake shore | Mirror Lake (new) | 1 | 100 | 20 | Lake scale |
| Under the bridge | Troll Bridge | 10 | 120 | 55 | River scale |
| Cove rocks | Smugglers' Cove (hidden, §6) | 15 | 130 | 90 | River scale |
| Cold tarn | Mountain Pass | 20 | 150 | 175 | Tarn scale |

Spots live in `world.json` next to the veins and trees, with `profession: fishing` and a `catches` table instead of
one `item`. Mirror Lake is a new area joined to Camp (300 steps) and Copper Hills (300 steps), with no monsters.

### 3.2 The catch
Each cast gives **one fish** rolled from the spot's table, plus **one scale** of the spot. The table has four rows:

| Row | Chance | Lake | River | Cove | Tarn |
|---|---|---|---|---|---|
| Common | 75% | Perch | Brown trout | Sea bass | Arctic char |
| Uncommon | 20% | Pike | Eel | Mackerel | Frostfin |
| Rare | 4.5% | Golden carp | Silver salmon | Moonfish | Glacier pike |
| Trophy | the rest | Old Mossback | River king | Old One-Eye | The Pale One |

- The trophy row is the spot's rare find and uses spec 0010 §5.1's formula: 0.5% × (1 + 5% per rod quality step) ×
  (1 + 1% per Fishing level above the spot, at most +10%). The cove's base is 1.5% (decision 4). The common row
  shrinks by what the trophy takes.
- A trophy fish is news: "Caught Old Mossback, 14.2 kg!".

### 3.3 The bottle
Each cast also rolls for a **message in a bottle**: `bottleChance` 0.05% (1 in 2,000), at every water, with no tool or
level bonus. What it holds is §6.

### 3.4 Weights and records
- Each species has a weight range in data (Perch 0.2–1.5 kg … The Pale One 15–40 kg). A catch's weight is
  `min + (max − min) × u²` for a uniform roll `u`, to one decimal, so heavy fish are rare.
- The save keeps the heaviest catch of each species. The first catch sets the record quietly; beating it is news and
  a journal line: "New record: Pike, 6.3 kg (was 4.8)".
- Fish in the bag don't carry their weight: weight is only for records.

## 4. Hunting

| Spot | Area | Hunting | Steps | XP | Common (75%) | Uncommon | Rare (trophy) | Hide |
|---|---|---|---|---|---|---|---|---|
| Deer trail | Goblin Woods | 1 | 100 | 20 | Red deer → venison | Wild boar → boar meat | Golden stag → golden antler | Deer hide |
| Moor tracks | Grey Moor | 10 | 120 | 55 | Moor elk → elk meat | Black boar → black boar meat | Old Tusk → Old Tusk's tusk | Elk hide |
| High crags | Mountain Pass | 20 | 150 | 175 | Ibex → ibex meat | Snow grouse → grouse | Snow lynx → snow lynx pelt | Ibex hide |

- Each hunt rolls one animal and gives its meat plus one hide of the spot. The rare animal is the spot's rare find
  (spec 0010 §5.1, 0.5% base); it gives its trophy, a hide and one common meat. The uncommon row takes the rest
  after 75% common.
- A rare animal is news: "Tracked the Golden stag: a golden antler!".
- The intent's "wolf" is left out: Wolf is a monster on the same moor, and an animal of the same name would confuse.

## 5. Cooking and meals

### 5.1 The camp fire
Camp's Here list gains a **Camp fire** row, which opens Professions on the Cooking card (like the Forge row). Cooking
recipes work like crafts: steps, profession XP, queueable, with "until I have N". They can only run at the camp
fire. Each cook makes one meal.

### 5.2 Meals
`items.json` gains meals as a new item kind, `meal`, with a `buff` (one or two) and a tier. They stack in the bag.

| Tier | Cooking | Steps / XP | HP | Defense | Crit | Attack | Fewer steps | Feast (HP + Attack) |
|---|---|---|---|---|---|---|---|---|
| 1 | 1 (Crit 3, feast 5) | 60 / 15 | Grilled perch (2 perch) | Pike steak (2 pike) | Golden carp curry (1 golden carp, 1 perch) | Venison skewer (2 venison) | Boar stew (2 boar meat) | Mossback feast (Old Mossback, 2 venison, 2 perch) |
| 2 | 10 (12, 15) | 80 / 45 | Smoked trout | Eel pie | Salmon on a plank | Elk roast | Black boar stew | River king feast |
| Cove | 15 (17, 18) | 80 / 45 | Baked sea bass | Salted mackerel | Moonfish broth | — | — | One-Eye feast |
| 3 | 20 (22, 25) | 100 / 140 | Char soup | Frostfin fillet | Glacier pike roast | Ibex haunch | Grouse pie | Pale One feast |

Inputs follow tier 1's pattern (two of the fish or meat; the Crit meal one rare and one common fish; the feast the
trophy fish, two common meats of its tier (cove: elk meat) and two common fish). Feasts take twice the steps and XP.

### 5.3 Buffs

| Buff | Tier 1 | Tier 2 / cove | Tier 3 |
|---|---|---|---|
| HP, Attack or Defense | +6% | +10% | +14% |
| Crit | +2 points | +3 points | +4 points |
| Fewer steps (gathering, crafting, cooking, rerolls) | 6% | 10% | 14% |

- A stat buff is a percent of the total stat with gear, rounded down, at least +1. Crit counts against spec 0009's
  crit cap. Fewer steps multiplies with the tool's step cost, rounded up to whole steps.
- A meal lasts `mealSteps` (3,000) steps. Every step spent on an action or travel counts down; steps that go to the
  step bank don't.
- **Perfect dish:** each cook rolls for one with spec 0010 §5.1's formula at base 10% (pot quality and Cooking levels
  above the recipe nudge it). A perfect dish lasts twice as long (6,000 steps) and shows as "Grilled perch
  (Perfect)" in text. It stacks apart from plain ones.
- No meal gives anything permanent.

### 5.4 Eating and auto-eat
- One meal is active at a time. A meal's item card has **Eat**; with one active it reads "Replaces Venison skewer
  (1,240 steps left)" and asks to confirm. Eating is instant and works anywhere.
- The card also has **Auto-eat**: off, **until out**, or **only N** (keep the rest; a number picker as in "until I
  have N"). One meal kind can be the auto-eat meal; picking another replaces it.
- When the active meal runs out, the auto-eat meal is eaten if the bag holds more than its keep number; plain ones
  first, then perfect. It happens at the exact step, so the rest of a sync's steps run under the new meal.
- News in the report: "Ate Venison skewer (auto, 4 left)", and once: "Out of Venison skewer: no meal running".

## 6. The bottle and Smugglers' Cove

### 6.1 What a bottle holds
- **First bottle:** a sea chart. "A message in a bottle! An old sea chart, an X beside the lake: Smugglers' Cove."
  The cove is revealed (§6.2). Journal entry and a banner like a level-up.
- **Every later bottle:** 1 Rare dust. "Another bottle: a few grains of Rare dust inside."

### 6.2 Hidden areas
- An area can be `hidden: true` in `world.json`. Until revealed it isn't drawn on the World map, isn't "???", isn't
  listed anywhere and no route uses it. Once revealed, spec 0008's fog rules apply as for any area.
- Smugglers' Cove is hidden, joined to Mirror Lake (700 steps), with no monsters and the Cove rocks spot (§3.1).
- The save keeps the set of revealed areas.

### 6.3 The sunken chest
Each cast at Cove rocks rolls for a **sunken chest** at `chestChance` 0.2% (1 in 500), no bonuses. It holds the
**Drowned Captain's ring** (ring, item level 20: +3 Attack, +2 Crit, +30 HP), which rolls quality and bonus stats
like a boss drop. Every chest holds another, so a better roll can come later. News: "A sunken chest! The Drowned
Captain's ring (Rare)".

## 7. Gear from hides, scales and trophies

| Tier | Crafting | Gloves | Bracers | Belt | Greaves (Legs) | Mantle (Shoulder, level +2) |
|---|---|---|---|---|---|---|
| 1 | 6 | Deer-hide gloves: 4 deer hide · +1 Attack, +5 HP | Deer-hide bracers: 4 deer hide · +1 Defense, +5 HP | Deer-hide belt: 3 deer hide, 1 copper ore · +10 HP | Lake-scale greaves: 6 lake scale, 2 deer hide · +1 Defense, +8 HP | Golden-antler mantle: 1 golden antler, 4 deer hide · +1 Attack, +1 Defense, +10 HP |
| 2 | 16 | Elk-hide gloves: 5 elk hide · +2 Attack, +12 HP | Elk-hide bracers: 5 elk hide · +2 Defense, +12 HP | Elk-hide belt: 4 elk hide, 1 iron ore · +25 HP | River-scale greaves: 8 river scale, 2 elk hide · +3 Defense, +18 HP | Tusk mantle: 1 Old Tusk's tusk, 5 elk hide · +2 Attack, +2 Defense, +25 HP |
| 3 | 26 | Ibex-hide gloves: 6 ibex hide · +3 Attack, +20 HP | Ibex-hide bracers: 6 ibex hide · +3 Defense, +20 HP | Ibex-hide belt: 5 ibex hide, 1 mithril ore · +40 HP | Tarn-scale greaves: 10 tarn scale, 2 ibex hide · +4 Defense, +30 HP | Lynx mantle: 1 snow lynx pelt, 6 ibex hide · +3 Attack, +3 Defense, +45 HP |

- Steps and XP follow today's recipes of the same level (level 6: 200 steps, 50 XP; 16: 350, 230; 26: 500, 860;
  mantles at 8, 18, 28). They roll quality and bonus stats like any gear (item level = recipe level).
- Hide pieces are light armour, scale greaves medium (spec 0009's armour types; monsters still ignore the player's).
- The spec 0002 **reference player** doesn't wear these pieces or eat meals, so spec 0002's reference targets and
  `fightXpPerStep` stay as they are; the stats above are the tuning knob for the walker (§9.3).

## 8. Screens

### 8.1 Professions
Six cards in the order Mining, Woodcutting, Fishing, Hunting, Crafting, Cooking, each as spec 0010 §8.1 (level,
progress, tier, tool, where to practise with Go there; not learned → "Learn from Wen in camp").
- **Fishing** also shows **Records**: one row per species found ("Pike · 6.3 kg"), and "???" for species not yet
  caught, as many as the waters you know hold (the cove's only once revealed).
- **Cooking** holds the meal recipes like Crafting's list ("Needs Cooking 12"), the active meal and the auto-eat
  choice. Its Go there goes to the camp fire.

### 8.2 Now
- Under the step bank: the active meal, "Venison skewer · +6% Attack · 1,850 steps left · auto-eat until out (4)";
  tap opens its item card. No meal: nothing shown.
- Here: Mirror Lake, Troll Bridge, Mountain Pass and the cove show their fishing spots; Goblin Woods, Grey Moor and
  Mountain Pass their hunting spots, with profession level and colour like veins. Camp shows the three new teachers
  and the Camp fire row.
- The running cast or hunt shows its catches in the tally ("Perch 6 · Pike 2 · records 1").

### 8.3 Item card, bag, Character
- Meals: buff and length in words ("+6% Attack for 3,000 steps"; perfect: 6,000), **Eat**, **Auto-eat**.
- Fish, meat, hides, scales and trophies are materials ("Used in: Grilled perch").
- Character's stats include the meal's buff, marked: "Attack 34 (+2 meal)".

### 8.4 World
Mirror Lake on the map near Camp. The cove appears only once revealed.

## 9. Balance

### 9.1 Random rolls
Every roll this spec adds (catch rows, weights, trophies, bottles, chests, animals, perfect dishes, the new gear's
quality and bonus stats, the Drowned Captain's ring) uses the profession stream (spec 0010 §9.1). Fights and gear
drops keep their draws from the shared generator.

### 9.2 The simulated walkers
- **Mixed walker:** learns all six professions on day 1. Counts the §7 gear as upgrades and fishes or hunts for
  their inputs as it gathers ore and logs (spec 0010 amendment 1's rules, practising when only a profession level
  holds an upgrade back). Crafts mantles when it has a trophy. New tools follow amendment 2 (2 levels past the
  recipe). **Meals:** keeps a meal running while it fights: when it is in camp with fewer than two meals, it gets the
  inputs and cooks a batch of its best Attack or HP meal (batch size set by the plan's tuning, starting at 10) and
  sets it to auto-eat until out. It never travels just to fish for records or the bottle.
- **Fighter:** unchanged (no professions, no meals).
- **Gatherer-crafter:** also fishes and hunts, crafts the §7 gear from what it gathers, and eats its best fewer-steps
  meal.

### 9.3 Targets (5,000 steps a day, seeds 1–8)
1–3. Spec 0010 §9.3 targets 1–3 as amended hold (mixed walker level 5 on day 1–2, 10 on day 11–16, 30 on day 70–100
   with median 80–100; Mining and Crafting 10 by day 8–22, 20 by 45–65; the fighter's median level 30 at least 15%
   later or not by day 120).
4. The gatherer-crafter is level 6–10 on day 90 (seed 1).
5. **Meals help, they aren't a must:** the mixed walker's median level 30 day with meals is no later than the same
   walker's without meals, and at most 5 days sooner.
6. The plan reports the mixed walker's Fishing, Hunting and Cooking levels on days 30, 60 and 90; no target.
7. Spec 0002's reference targets (spec 0010 §9.3 target 5) are unchanged: no monster changes.

### 9.4 Expected pressure
Fifteen gear pieces and meals add power, so the mixed walker will get faster; its trips to fish and hunt and to cook
in camp slow it. Tuning order if it runs too fast: the §7 stats first, then the batch size and when the walker cooks.
Meal sizes (decision 2) and monsters change only after asking the owner.

## 10. Save
New save version (9):
- `professions`, `learned` and `tools` gain Fishing, Hunting and Cooking (not learned on old saves; no tool until
  learned).
- `records`: heaviest weight per fish species. `meal`: the active meal (kind, perfect, steps left) or none.
  `autoEat`: meal kind and keep number, or none. `revealed`: revealed hidden areas. `bottles`: bottles found.
- Old saves load with no meal, no records, the cove hidden, and everything else unchanged. Every fixture in
  `app/test/fixtures/saves/` loads.

## 11. Out of scope
Quests (Wen's "bring me back some fish"), character origins (0012), permanent food bonuses, cooking anywhere but the
camp fire, weights for animals, danger while hunting, selling fish or meals, a trophy wall, a fishing minigame, meal
qualities beyond perfect, the player's armour type mattering in fights.

## 12. Concerns
1. **Power creep (medium).** Fifteen pieces and meals raise the mixed walker's power. §9.4 holds the line with their
   stats; the reference player ignores them so the monster targets stay honest.
2. **Camp-only fire (medium).** A player at Dragon's Peak is about 3,900 steps from camp. Meals keep, so a batch of 10
   covers six days; if playtests show the walk back hurts, fires at the forges are a later, small change.
3. **The bottle is very rare (low, intended).** A player who fishes 10 casts a day waits about 200 days on average;
   many never see the cove. That is the Diablo chase the intent asks for. Spec 0010's rare finds have the same shape.
4. **Hidden areas bend the fog rule (low).** A hidden area is the one place the map hides more than "???". It is
   needed so the cove is a real discovery; old saves never see it until a bottle.
5. **Bag clutter (low).** Sixteen fish, six meats, hides, scales, trophies and 22 meals are many new materials. The bag
   keeps gear first, then materials; headings can come later.
6. **Seeds shift (medium).** New walker choices move its fights again; expect a tuning pass as in plans 0011 and 0012.

## 13. Acceptance criteria
1. Fishing, Hunting and Cooking are professions with the spec 0010 rules: own level from the shared XP table, fade,
   learned from their teacher, character XP at `professionShare` of `fightXpPerStep` per step after the tool.
2. Wen, Sigrun and Marta in camp teach once and give Common starter tools; Sigrun tells the §2.2 tips at Hunting 1,
   10 and 20; rod, bow and pot follow spec 0010 §3 (tiers, quality step cost, no salvage of starters, no tool no work).
3. Mirror Lake is a new area joined to Camp and Copper Hills; the four waters and three hunting spots match §3.1 and
   §4 (area, level, steps, XP).
4. Each cast gives one fish from the table plus one scale; over many seeded casts the rows come out at 75 / 20 / 4.5%
   ± 1 and the trophy at 0.5% ± 0.1 with a Common rod at the spot's level (cove 1.5% ± 0.3).
5. Each hunt gives one animal's meat plus one hide; the rare animal gives its trophy at 0.5% ± 0.1.
6. Weights follow §3.4; the save keeps the heaviest per species; beating a record is news and a journal line; the
   first catch isn't news.
7. A bottle rolls at 1 in 2,000 casts (seeded test over many casts); the first reveals Smugglers' Cove, later ones
   give 1 Rare dust.
8. A hidden area is absent from the map, lists and routes until revealed, then follows the fog rules; Cove rocks
   rolls a sunken chest at 0.2% that holds the Drowned Captain's ring, rolling quality and bonus stats.
9. Cooking runs only at the camp fire; recipes match §5.2; a cook rolls perfect at §5.3's chance; perfect dishes last
   6,000 steps and stack apart.
10. One meal is active at a time; its buff applies per §5.3 (percent of the total stat, rounded down, at least 1;
    fewer steps multiplied with the tool); it counts down on action and travel steps, not banked steps.
11. Auto-eat: "until out" eats until the bag has none; "only N" stops with N left; it eats at the exact step the
    last meal ends, plain ones first; Eat with a meal running asks and replaces it.
12. The §7 gear fits Gloves, Bracer, Belt, Legs and Shoulder with the listed inputs and stats and rolls quality and
    bonus stats; the reference player doesn't use it.
13. Every roll in criteria 4–12 uses the profession stream: the same seed and steps give the same fights and drops
    whether or not those rolls happened (test as spec 0010 criterion 12).
14. An old save loads as version 9 with the three new professions unlearned, no meal, no records, the cove hidden,
    everything else unchanged; every fixture loads.
15. The Professions screen shows six cards; Fishing shows records with "???" for uncaught species; Cooking holds its
    recipes, the active meal and auto-eat; Now shows the active meal, the new spots, teachers and the Camp fire.
16. Simulated 5,000 steps a day on seeds 1–8 meet §9.3 targets 1–5 and 7 and report target 6.
17. `.\scripts\check.ps1 -Release` is green, with no INTERNET permission.
