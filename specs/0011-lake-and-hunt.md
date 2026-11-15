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
that buff the player for 6,000 steps; scales, hides and rare trophies craft gear for the five empty doll slots. A
message in a bottle leads to a hidden cove. All numbers are starting values in `data/*.json`, tuned with the pacing
simulator.

## 1. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | Where to fish | **One new lake area and two waters** (owner's choice): Mirror Lake (new area near Camp) is the tier 1 water; tier 2 and 3 are spots in areas that exist, the river under Troll Bridge and a cold tarn at Mountain Pass (§3.1). |
| 2 | Meal strength | **Noticeable** (owner's choice): one buff per meal, +6% / +10% / +14% by tier to HP, Attack or Defense, or as many percent fewer steps for profession actions. A perfect dish lasts twice as long (§5.3). **Meals help a little with the pace and a little in hard fights** (owner, 2026-11-06, #165): a meal lasts 6,000 steps, and Attack and HP meals make fights cost 12% / 20% / 28% fewer steps. |
| 3 | What hides, scales and trophies make | **Gear for the empty slots** (owner's choice): per tier, hides make Gloves, Bracers and a Belt, scales make Greaves (Legs), a rare hunting trophy makes a Shoulder mantle. Trophy fish make feasts (two buffs). 15 new gear items with small stats (§7). |
| 4 | Message in a bottle | **A chart to a hidden cove** (owner's choice): the first bottle reveals Smugglers' Cove, joined to Mirror Lake. Its water (Fishing 15) has trophy fish three times as often and a sunken chest holding a unique ring. Later bottles hold Rare dust (§6). |
| 5 | Where to cook | At the **camp fire** only, as the intent says. Meals keep in the bag, so a player cooks a batch before a long trip (concern 2). |
| 6 | Hunting danger | None: hunting is tracking, with no health bar or loss (intent). |
| 7 | Teachers' tips | Only the hunter tells monster tips (intent); the fisherman and the cook don't. Since spec 0010 amendment 8 the hunter and the fisherman also tell what lives at each spot. |
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

Spec 0012 gives each teacher a greeting and a line for a player of their kin.

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
`items.json` gains meals as a new item kind, `meal`, with a `buff` (one or two) and a tier. They stack in the bag:
since spec 0021 amendment 4, up to 20 in a bag space.

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
| Fight steps given back (Attack, HP and feasts) | 12% | 20% | 28% |

- A stat buff is a percent of the total stat with gear, rounded down, at least +1. Crit counts against spec 0009's
  crit cap. Fewer steps multiplies with the tool's step cost, rounded up to whole steps.
- A meal lasts 6,000 steps (`meals.steps` in `economy.json`). Every step spent on an action or travel counts down;
  steps that go to the step bank don't.
- **Perfect dish:** each cook rolls for one with spec 0010 §5.1's formula at base 10% (pot quality and Cooking levels
  above the recipe nudge it). A perfect dish lasts twice as long (12,000 steps) and shows as "Grilled perch
  (Perfect)" in text. It stacks apart from plain ones.
- **Faster fights:** while an Attack meal, an HP meal or a feast runs, each fight gives back its tier's share of its
  round steps to its action (`meals.fightSteps`), as the talent Swift strikes does (spec 0015 §2.3). The meal's share
  and the talent's share add up; the steps given back are rounded down. Defense, Crit and fewer-steps meals give back
  nothing.
  - Why: with supply chests, chest gear makes fights short, so an Attack or HP buff saved few rounds, and the steps
    of fishing, hunting and cooking cost about as much as the buff saved. Claude's hand-run sims (the mixed walker,
    seeds 1-16; the gain is the day of level 30 without meals minus the day with meals):

    | Variant | Gain (mean) | Gain (median) | Gain (lowest to highest) |
    |---|---|---|---|
    | Meals last 3,000 steps (before) | -2.6 days | -3.5 days | -14 to +10 |
    | A: meals last 6,000 steps | -0.4 days | -1.5 days | -15 to +16 |
    | B: Attack and HP meals give back 6 / 10 / 14% of each fight round's steps | -0.4 days | +0.5 days | -11 to +7 |
    | A and B | -0.2 days | +0.5 days | -14 to +11 |
    | **A and B at 12 / 20 / 28%** | **+3.2 days** | **+4.5 days** | -8 to +10 |

  - Before supply chests, meals gained about 5 days. The last variant brings back most of that.
  - A meal that runs when the player updates keeps the steps it has left.
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
- Travelling Salesman counts the 11 areas that aren't hidden; Smugglers' Cove is a bonus (spec 0004 decision 8). The
  owner chose this: the hidden cove is one most players never find.

### 6.3 The sunken chest
Each cast at Cove rocks rolls for a **sunken chest** at `chestChance` 0.2% (1 in 500), no bonuses. It holds the
**Drowned Captain's ring** (ring, item level 20: +3 Attack, +2 Crit, +20 HP (30)), which rolls quality and bonus stats
like a boss drop. Every chest holds another, so a better roll can come later. News: "A sunken chest! The Drowned
Captain's ring (Rare)".

## 7. Gear from hides, scales and trophies

| Tier | Crafting | Gloves | Bracers | Belt | Greaves (Legs) | Mantle (Shoulder, level +2) |
|---|---|---|---|---|---|---|
| 1 | 6 | Deer-hide gloves: 4 deer hide · +1 Attack, +3 HP (5) | Deer-hide bracers: 4 deer hide · +1 Defense, +3 HP (5) | Deer-hide belt: 3 deer hide, 1 copper ore · +7 HP (10) | Lake-scale greaves: 6 lake scale, 2 deer hide · +1 Defense, +5 HP (8) | Golden-antler mantle: 1 golden antler, 4 deer hide · +1 Attack, +1 Defense, +7 HP (10) |
| 2 | 16 | Elk-hide gloves: 5 elk hide · +2 Attack, +8 HP (12) | Elk-hide bracers: 5 elk hide · +2 Defense, +8 HP (12) | Elk-hide belt: 4 elk hide, 1 iron ore · +17 HP (25) | River-scale greaves: 8 river scale, 2 elk hide · +3 Defense, +12 HP (18) | Tusk mantle: 1 Old Tusk's tusk, 5 elk hide · +2 Attack, +2 Defense, +17 HP (25) |
| 3 | 26 | Ibex-hide gloves: 6 ibex hide · +3 Attack, +13 HP (20) | Ibex-hide bracers: 6 ibex hide · +3 Defense, +13 HP (20) | Ibex-hide belt: 5 ibex hide, 1 mithril ore · +27 HP (40) | Tarn-scale greaves: 10 tarn scale, 2 ibex hide · +4 Defense, +20 HP (30) | Lynx mantle: 1 snow lynx pelt, 6 ibex hide · +3 Attack, +3 Defense, +30 HP (45) |

- The HP is that of `items.json`, with the first HP in brackets: spec 0002 amendment 3 gave these pieces and every
  ring a third less HP (spec 0002 §4).

- Steps and XP follow the recipes of the same level (level 6: 200 steps, 50 XP; 16: 350, 230; 26: 500, 860;
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
- **Cooking** holds the meal recipes like Crafting's list ("Needs Cooking 12 (you have 7)" since spec 0010
  amendment 10; the order of spec 0010 amendment 12), the active meal and the auto-eat choice. Its Go there goes to
  the camp fire.

### 8.2 Now
- Under the step bank: the active meal, "Venison skewer · +6% Attack, −12% fight steps · 1,850 steps left ·
  auto-eat until out (4)"; tap opens its item card. No meal: nothing shown.
- Here: Mirror Lake, Troll Bridge, Mountain Pass and the cove show their fishing spots; Goblin Woods, Grey Moor and
  Mountain Pass their hunting spots, with profession level and colour like veins. Camp shows the three new teachers
  and the Camp fire row.
- The running cast or hunt shows its catches in the tally ("Perch 6 · Pike 2 · records 1").

### 8.3 Item card, bag, Character
- Meals: buff and length in words ("+6% Attack, −12% fight steps for 6,000 steps"; perfect: 12,000), **Eat**,
  **Auto-eat**. A feast reads "+6% HP, +6% Attack, −12% fight steps". A Defense, Crit or fewer-steps meal names no
  fight steps. The same words show on the meal line of Now and on the Cooking screen.
- Fish, meat, hides, scales and trophies are materials ("Used in: Grilled perch").
- Character's stats include the meal's buff, marked. Since spec 0008 amendment 7 a line under the stat reads
  "+2 meal".

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
  inputs and cooks a batch of its best Attack or HP meal (a batch of 10) and sets it to auto-eat until out. It
  never travels just to fish for records or the bottle.
  - It starts a meal batch only from **character level 10**. Cooking from level 5 stalled it: it spent about 3,000
    steps fishing perch for its first batch, at a quarter of a fight's XP, and reached level 10 on day 17 on three
    seeds.
  - It crafts a profession's tool only once that **profession's level reaches the tool recipe's level** (copper 3,
    iron 12, mithril 22), on top of spec 0010 amendment 2's rule (2 character levels past the recipe). At level 5 it
    had crafted a copper rod and pot for professions it had hardly worked.
  - Since spec 0013 amendment 3 it counts only the meals it would eat when it decides to cook.
  - Real players have none of these rules: they can cook and craft any tool whenever they like.
- **Fighter:** no professions, no meals. Since spec 0010 amendment 11 it learns every profession, salvages and eats
  (spec 0010 §9.2).
- **Gatherer-crafter:** also fishes and hunts, crafts the §7 gear from what it gathers, and eats its best fewer-steps
  meal. It starts meal batches from character level 10 too. Since spec 0002 amendment 3 erratum 1 it has no target;
  it stays in the tools for a hand look.

### 9.3 Targets (5,000 steps a day, seeds 1–8)
1–3. Spec 0010 §9.3 targets 1–3 hold, with the days that spec 0010 §9.3 gives them (the mixed walker's levels and
   professions, the fighter's range).
4. **Dropped** on 2026-11-09 (spec 0002 amendment 3 erratum 1). It was the gatherer-crafter's level 6–10 on day 90
   (seed 1).
5. **Meals help a little:**
   - In a hand-run sim on seeds 1-16, the mean gain of meals is 2 to 6 days.
   - In the pacing test on seeds 1-8, the median day of level 30 with meals is 0 to 10 days sooner than without
     meals. The comparison runs with the bonuses of feats set to nothing (spec 0017 §8).
   - It was "no later, and at most 5 days sooner" at first; spec 0013 amendment 3 made it "at most 5 days later and
     at most 5 days sooner", since chest gear made fights short; amendment 2 set it as above.
6. The plan reports the mixed walker's Fishing, Hunting and Cooking levels on days 30, 60 and 90; no target.
7. Spec 0002's reference targets (spec 0010 §9.3 target 5) are unchanged: no monster changes. Since spec 0002
   amendment 3 most of them are measured with the sim walker (spec 0002 §5.5).

### 9.4 Expected pressure
Fifteen gear pieces and meals add power, so the mixed walker will get faster; its trips to fish and hunt and to cook
in camp slow it. Tuning order if it runs too fast: the §7 stats first, then the batch size and when the walker cooks.
Meal sizes (decision 2) and monsters change only after asking the owner.

Plan 0013 M1 found that the professions ran ahead: with the 15 new pieces the walker practised Crafting 6 for the
first hide pieces on day 3, and reached Mining and Crafting 10 on day 4–7 and Crafting 20 on day 39. So the profession
XP table (`professionXpToReachLevel`) became **25% steeper**: each entry × 1.25, rounded. Mining 10 needs 572 XP (was
458), level 20 needs 4,255 (was 3,404). Spec 0010 §2.2 holds the table.

### 9.5 The numbers at the end of plan 0013 M1
5,000 steps a day, seeds 1–8:
- Level 5 on day 2, level 10 on day 14–15, level 30 on day 86–99 (median 89.5); without meals level 30 median 90.0.
- Mining 10 median day 21.5, Mining 20 56.5; Crafting 10 median day 8, Crafting 20 51.5.
- The fighter didn't reach level 30 by day 120; the gatherer was level 7 on day 90.
- Fishing / Hunting / Cooking medians: day 30 8 / 6 / 5, day 60 13 / 13.5 / 7, day 90 21 / 22 / 7.
- The walker's meals changed little: it cooks only when it passes camp (decision 5), which after the early levels is
  rare, so most seeds ate one or two batches. Meals on and off differed by up to 10 days on a single seed from the
  fights they reshuffle; the medians differed by half a day.

## 10. Save
New save version (9):
- `professions`, `learned` and `tools` gain Fishing, Hunting and Cooking (not learned on old saves; no tool until
  learned).
- `records`: heaviest weight per fish species. `meal`: the active meal (kind, perfect, steps left) or none.
  `autoEat`: meal kind and keep number, or none. `revealed`: revealed hidden areas. `bottles`: bottles found.
- Old saves load with no meal, no records, the cove hidden, and everything else unchanged. Every fixture in
  `app/test/fixtures/saves/` loads.

## 11. Out of scope
Quests (Wen's "bring me back some fish"), permanent food bonuses, cooking anywhere but the camp fire, weights for animals, danger while hunting, selling fish or meals, a trophy wall, a fishing minigame, meal
qualities beyond perfect, the player's armour type mattering in fights.

## 12. Concerns
1. **Power creep (medium).** Fifteen pieces and meals raise the mixed walker's power. §9.4 holds the line with their
   stats; the reference player ignores them so the monster targets stay honest.
2. **Camp-only fire (medium).** A player at Dragon's Peak is about 3,900 steps from camp. Meals keep, so a batch of 10
   covers twelve days (six while a meal lasted 3,000 steps); if playtests show the walk back hurts, fires at the
   forges are a later, small change.
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
   12,000 steps and stack apart.
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
16. Simulated 5,000 steps a day on seeds 1–8 meet §9.3 targets 1–3, 5 and 7 and report target 6.
17. `.\scripts\check.ps1 -Release` is green, with no INTERNET permission.

**Meals: rules**
18. A plain meal lasts 6,000 steps, and a perfect dish 12,000.
19. A fight under an Attack meal gives back its tier's share of the fight's round steps: 12% at tier 1.
20. A fight under an HP meal gives back the same share.
21. A fight under a feast gives back the same share.
22. A fight under a Defense, Crit or fewer-steps meal gives back no steps from the meal.
23. With the talent Swift strikes, the talent's share and the meal's share add up.
24. The shares 12 / 20 / 28 and the 6,000 steps come from `economy.json`.

**Meals: screens**
25. The card of an Attack meal reads "+6% Attack, −12% fight steps for 6,000 steps" at tier 1.
26. The card of a feast names HP, Attack and the fight steps.
27. The card of a Defense meal names no fight steps.

**Meals: the pace and the notes**
28. The plan reports the hand-run sim on seeds 1-16 with the final numbers: mean gain 2 to 6 days.
29. `releases/next/` has a line for players about meals.

## History
- 2026-10-22: first version (intent 0011, plan 0013). Criteria 1-17.
- 2026-10-22, amendment 1 (plan 0013 M1): the walker cooks from level 10 and crafts a tool at its profession's
  level; the profession XP table 25% steeper; Travelling Salesman counts the 11 areas that aren't hidden. §6.2; §9.2;
  §9.4; §9.5.
- 2026-10-22, spec 0012: the teachers' greetings and kin lines; character origins. §2.2; §11.
- 2026-10-24, spec 0017 amendment 3 (plan 0021 M2): the meals target runs without the bonuses of feats. §9.3.
- 2026-10-31, spec 0010 amendment 8 (#117, plan 0030): the hunter and the fisherman tell what lives at each spot.
  Decision 7.
- 2026-11-01, spec 0013 amendment 3 (#57): meals at most 5 days later and at most 5 days sooner; the walker counts
  only the meals it would eat. §9.2; §9.3.
- 2026-11-06, spec 0010 amendment 10 (#223): a locked recipe names the player's level. §8.1.
- 2026-11-06, amendment 2 (#165, plan 0054): meals last 6,000 steps, and Attack and HP meals make fights cost fewer
  steps; meals help a little. Decision 2; §5.3; §8.2; §8.3; §9.3; §12; criteria 9 and 18-29.
- 2026-11-07, spec 0010 amendment 11 (#237): the fighter learns every profession and eats. §9.2.
- 2026-11-09, spec 0021 amendment 4 (#228, plan 0056): up to 20 meals in a bag space. §5.2.
- 2026-11-09, spec 0002 amendment 3 and its erratum 1 (#234): the §7 pieces and the Drowned Captain's ring give a
  third less HP; the gatherer's target 4 dropped; the reference targets move to the walker. §6.3; §7; §9.2; §9.3;
  criterion 16.
- 2026-11-10, spec 0010 amendment 12 (#253): the order of the recipe list. §8.1.
- 2026-11-10, spec 0008 amendment 7 (#254): the meal line under a stat. §8.3.
- 2026-11-15 (plan 0068): the amendments folded into this file. §6.3 and §7 give the HP of `items.json` (the ring
  20; the pieces 3, 3, 7, 5, 7; 8, 8, 17, 12, 17; 13, 13, 27, 20, 30), with the first HP beside it; §9.3 targets
  1-3 point to spec 0010 §9.3, which holds their days. No rule or criterion changed. (draft)
