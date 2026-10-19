# Spec 0002: Levels that matter

Status: accepted
Intent: [intent/0002-levels-that-matter.md](../intent/0002-levels-that-matter.md) (accepted, commit 041ecbd)
Related: [intent/0003-running-your-day.md](../intent/0003-running-your-day.md) (accepted, commit 70469b0; its spec follows this one)
Product owner: Zkalf
Date: 2026-10-19

Monsters get levels and WoW-style colours, XP fades on monsters below the player, levels have no cap, and every
level from 1 to 30 unlocks something. Levels 1–10 are a guided tutorial ending in a boss and the Adventurer rank,
which opens the whole map. All numbers are starting values in `data/*.json`, tuned with the pacing simulator and
on the phone.

## 1. Decisions on the intent's open questions

| # | Question | Decision |
|---|---|---|
| 1 | Losing fights | Settled in intent 0003 and built with its spec. Until then a loss ends the fight activity, as today. |
| 2 | XP fade curve | Medium fade (option B): full XP within 2 levels, green 3–6 below fades to 20%, grey at 7+ below gives 5% (§3). |
| 3 | Monster roster | 15 monsters, 3 bosses (levels 10, 20, 30) and 1 lurker over 7 areas (§6). Each has a twist (§5). |
| 4 | Unlock per level | The ladder in §8. Levels 1–9 unlock features and areas. Level 10 opens the whole map. Later levels add recipes, gear slots, ranks and a talent point. |
| 5 | Stat growth | Small numbers (owner's choice): +10 HP, +1 Attack, +1 Defense per level. Gear is about a third of the player's power (§4). |
| 6 | At the soft cap | **Nothing built for it** (owner's choice). The answer to the soft cap is more content. Grey monsters still drop their loot. |
| 7 | Talent points | One point per level from 10, counted and shown but not spent until the talent spec. |
| 8 | *New:* bosses | A boss every 10 levels. Bosses are **optional**, never a gate. They check gear: at even level without crafted gear the player almost always loses. The reward is a guaranteed first-kill item, not extra XP (§5.3). |
| 9 | *New:* danger and guidance | The map opens at level 10, so far-too-strong monsters are visible and fightable (skulls, lurkers). The game guides the player with a warning before deadly fights, a hideable "Next goal" line and loss hints (§9). |
| 10 | *New:* role-play for the map opening | Ranks: the player starts as a *Recruit* who stays in the guarded lands. At level 10 they become an *Adventurer* and may cross the river. Then *Veteran* at 20 and *Champion* at 30. Names and lines are flavour in data and can change. |

## 2. Character levels

- **No level cap.** The XP thresholds are a list in data up to level 30. After the list, each further level costs
  the previous level's cost × `xpGrowthAfterList` (starting value 1.05), forever.
- **Pacing targets** for a simulated average walker (5,000 steps a day, sensible play including crafting and travel):

| Level | Walked steps (about) | Day |
|---|---|---|
| 5 | 3,500 | 1 (unchanged) |
| 10 | 65,000 | 12–16 |
| 20 | 240,000 | about 50 |
| 30 | 450,000 | 80–100 |

  The steps per level rise from 5,000 (level 5 → 6) to 17,000 (9 → 10), then from about 16,000 (10 → 11) to about
  22,000 (29 → 30). That's a level every 1–3 days in the tutorial and every 3–4 days after it.
- **Existing saves keep their level.** Their XP is moved to the same fraction of the way through that level in the
  new table.

## 3. Monster levels, colours and XP fade

Every monster has a level. Its colour depends on `monster level − player level`:

| Colour | Difference | XP multiplier |
|---|---|---|
| 💀 Skull (shown instead of the level) | +10 or more | 100% |
| Red | +5 to +9 | 100% |
| Orange | +3 to +4 | 100% |
| Yellow | −2 to +2 | 100% |
| Green | −3 / −4 / −5 / −6 | 80% / 60% / 40% / 20% |
| Grey | −7 or less | 5% |

- The multiplier applies to the XP of a won fight (and to the partial XP of a lost fight once spec 0003 is built).
  XP is rounded down, but a won fight always gives at least 1 XP.
- **Loot is never reduced.** Grey monsters drop exactly what they always do.
- **Gathering and crafting fade too.** Each gathering spot and recipe has a level (its unlock level), and its XP is
  multiplied by the same table. Without this, mining would bypass the soft cap. They still count as never "grey"
  for intent 0003's stop conditions: "until grey" isn't offered for them.
- **XP per step rises with monster level.** For an even-level player with the gear of that stretch, a monster of
  level M gives about `0.2 × 1.1^(M−1)` XP per step (±15%). Each monster in the roster gives at most a third more
  XP per step than the one before it (intent 0003 guardrail).
- **Soft cap.** With the top monster at 30, XP fades from player level 33 and is grey at 37. New content raises
  this without rule changes.
- The bands, multipliers and skull threshold live in data.

## 4. Stats and gear

- **Base at level 1:** HP 30, Attack 5, Defense 2 (unchanged). **Per level:** +10 HP, +1 Attack, +1 Defense (was +5 HP).
- **Gear slots** open by level: weapon and body (1), shield (7), head (12), feet (17), amulet (20). Slots and their
  unlock levels live in data. An item can only be equipped once its slot is open.
- **Gear is about a third of the player's power** at each stretch: the best craftable set for a level adds roughly
  half of that level's base Attack, Defense and HP. This is what makes the bosses' gear checks work.

## 5. Monster twists and bosses

### 5.1 Twists (new combat rules)
A monster can have any of these traits, listed in data:

| Trait | Rule | Gear that helps |
|---|---|---|
| Quick | The monster strikes first in each round. | Defence, HP |
| Slow | The monster attacks only every second round. | Pairs with huge HP and big hits: rewards defence |
| Ghostly | Its hits ignore the player's defence. | HP, killing it fast |
| Regenerates | After each of its turns, it heals a set amount (data), up to its full HP. | A strong weapon |

Monsters without traits get their twist from their stat shape: heavy armour with little HP rewards a strong weapon,
and big hits with little HP reward defence.

### 5.2 Fight length targets
For an even-level player with the gear of that stretch: normal monsters take 4–8 rounds (40–80 steps), and
slow tanks (zombie, stone golem) take 12–20 rounds. An even-level geared player wins at least 90% of normal fights.

### 5.3 Bosses
- **Graveyard King (10), Ogre Chieftain (20), Young Dragon (30).** A boss fight takes 25–40 rounds.
- **Gear check targets** (simulated, against each boss):
  - even level, base stats only (no gear): wins ≤ 10%
  - even level, best crafted gear available for that stretch: wins ≥ 70%
  - 5 levels above, no gear: wins ≥ 50%
- **XP per step like a normal monster of its level.** Losing to a boss repeatedly must never be the best way to
  level.
- **First kill:** a guaranteed unique item (King's blade, Chieftain's amulet, Dragon's heart) and an achievement.
  Later kills drop the boss's material as usual. *New rule:* `firstKillDrops` per monster, in data.
- **Optional:** nothing requires a boss kill.

### 5.4 Lurkers
A lurker is a monster far above the level of its area, visible from the moment the area opens. It follows the normal
rules for its level. The first one is the **Old Bear (16) in Goblin Woods**: a skull for a new player. More can be
added as data.

## 6. Areas, monsters and routes

Monsters keep their `unlockLevel` (the level from which they show). Tutorial monsters show at the level in §8.
Bosses and lurkers show from the moment their area opens.

| Area | Opens | Crafting | Monsters (level, traits/shape) | Drops |
|---|---|---|---|---|
| Camp | 1 | yes | — | — |
| Goblin Woods | 1 | | Goblin (1), Goblin brute (4, sturdy), *Old Bear* (16, quick, hits hard) | hide; hides; bear pelt (25%, a body item) |
| Copper Hills | 2 | | copper vein | copper ore |
| Old Graveyard | 6 | | Skeleton (6, heavy armour, little HP), Zombie (8, slow, huge HP, hits hard), **Graveyard King** (10, heavy armour, hits hard) | bones; grave cloth; bones + grave cloth |
| Grey Moor | 10 | yes (outpost) | Wolf (11, quick, light armour), Ghost (13, ghostly), Bandit (15, hits very hard, little HP) | wolf pelt; ectoplasm; leather, iron ore |
| Iron Ridge | 10 | | iron vein (mining from 12) | iron ore |
| Troll Bridge | 10 | | Giant spider (16, quick, little HP), Troll (18, regenerates), **Ogre Chieftain** (20, slow, enormous HP, crushing hits) | silk; troll hide; troll hide |
| Mountain Pass | 10 | yes (lodge) | Stone golem (21, slow, very heavy armour), Harpy (23, quick, ghostly), Wraith (25, ghostly, regenerates) | stone core; feathers; soul dust |
| Mithril Deep | 10 | | mithril vein (mining from 22) | mithril ore |
| Dragon's Peak | 10 | | Wyvern (27, quick, hits hard), Fire drake (28, regenerates, armour), **Young Dragon** (30, quick, regenerates, armour, hits hard) | wyvern scale; drake fang; dragon scale |

**Routes** (both directions, in steps). Existing routes are unchanged.

| From | To | Steps |
|---|---|---|
| Goblin Woods | Old Graveyard | 400 |
| Camp | Old Graveyard | 500 |
| Old Graveyard | Grey Moor (the river crossing) | 800 |
| Grey Moor | Iron Ridge | 500 |
| Grey Moor | Troll Bridge | 900 |
| Troll Bridge | Mountain Pass | 1,000 |
| Mountain Pass | Mithril Deep | 600 |
| Mountain Pass | Dragon's Peak | 1,200 |

Camp to Dragon's Peak is about 4,400 steps, nearly a day's walk. The outposts at Grey Moor and Mountain Pass make
crafting possible without walking back to Camp. Travel is still one leg at a time. Automatic multi-leg travel comes
with spec 0003.

## 7. Items and recipes

Item stats are tuned in data to meet §4 and §5. Recipe step costs start at 150 and rise with tier.

| Unlock | Item | Slot | Recipe |
|---|---|---|---|
| 3 | Copper sword, hide vest | weapon, body | unchanged |
| 6 | Bone sword | weapon | 6 bones, 2 copper ore |
| 7 | Bone shield | shield | 5 bones |
| 9 | Stitched armour | body | 6 goblin hides, 3 grave cloth |
| 10 | King's blade | weapon | Graveyard King first kill |
| 11 | Wolf-pelt vest | body | 6 wolf pelts, 2 grave cloth |
| 12 | Iron helm | head | 5 iron ore |
| 13 | Ectoplasm ward (adds HP, against ghostly hits) | shield | 4 ectoplasm, 4 bones |
| 14 | Iron sword, iron shield | weapon, shield | 8 iron ore each |
| 15 | Studded leather | body | 6 leather, 4 iron ore |
| 16 | Bear-pelt cloak | body | Old Bear drop |
| 17 | Silk boots | feet | 6 silk |
| 18 | Troll-hide armour | body | 6 troll hide, 4 leather |
| 19 | Troll-bone maul | weapon | 4 troll hide, 10 bones |
| 20 | Moor charm; Chieftain's amulet | amulet | 5 ectoplasm, 5 wolf pelts; Ogre Chieftain first kill |
| 22 | Mithril sword | weapon | 8 mithril ore |
| 23 | Feather boots | feet | 6 feathers, 4 silk |
| 24 | Mithril armour, mithril helm | body, head | 10 mithril ore + 4 troll hide; 6 mithril ore |
| 25 | Soul-dust amulet | amulet | 5 soul dust, 2 stone cores |
| 26 | Golem-core shield | shield | 4 stone cores, 6 mithril ore |
| 27 | Wyvern-scale armour | body | 8 wyvern scales, 4 mithril ore |
| 28 | Drake-fang blade | weapon | 4 drake fangs, 8 mithril ore |
| 29 | Fire-ward amulet | amulet | 3 drake fangs, 6 feathers |
| 30 | Dragon-scale armour, dragon helm; Dragon's heart | body, head; amulet | 6 dragon scales + 6 wyvern scales; 4 dragon scales + 4 mithril ore; Young Dragon first kill |

Recipes deliberately reuse materials from earlier monsters (bones, grave cloth, wolf pelts), so grey monsters stay
worth farming.

## 8. The level ladder

Every level-up gives stats (§4) and at least one named unlock. From level 10, every level also gives a talent point.

| Lvl | What's new |
|---|---|
| 1 | Goblin Woods, goblins, travel, the step bank. The Old Bear shows as a skull. |
| 2 | Copper Hills, mining |
| 3 | Crafting: copper sword, hide vest |
| 4 | Goblin brute |
| 5 | Queue of 2 actions, "until I have N" (spec 0003) |
| 6 | Old Graveyard, skeletons, bone sword. The Graveyard King shows (red). |
| 7 | Shield slot, bone shield |
| 8 | Queue of 3 actions (spec 0003), zombies |
| 9 | Stitched armour: the first two-monster recipe, which sends the player back to grey goblins |
| 10 | **Adventurer:** the whole map opens, first talent point, the King is the player's level |
| 11–30 | As in §7, plus the head slot (12), feet slot (17), amulet slot and **Veteran** (20), iron mining (12), mithril mining (22), **Champion** (30) |

Ranks (name, level, ceremony line) live in data. Until spec 0003 is built, the queue lines at 5 and 8 aren't shown.

## 9. Screens

### 9.1 Level-up cards
- Each level gained gets a card: the new level, the stats gained, and what's new. While the player was away, the
  cards show on app open before the report. While the app is open, they show when the level-up happens.
- The player swipes through them, or taps **Skip all**.
- **What's new** lists, in order:
  1. the rank ceremony line (levels 10, 20, 30)
  2. everything whose unlock level is this level (areas, monsters, gathering spots, recipes, gear slots, features)
  3. the talent point (from 10)
  4. monsters that are now the player's level
  5. monsters that just turned grey, with "still drops its loot"
- With more than 3 cards, all but the last can be collapsed into one summary card.

### 9.2 Colours in the fight list
Each monster shows its level in its colour, or a skull. Starting a fight against a red or skull monster asks for
confirmation: "Deadly: you will almost certainly lose." Orange shows "Risky" without asking.

### 9.3 Next goal
One line on the main screen, worked out from the save, with the first rule that applies:
1. An owned item is better than the one equipped: "Equip the bone shield."
2. A recipe that improves a slot can be crafted now: "Craft stitched armour at Camp."
3. A recipe that improves a slot is missing materials: "Get 3 more grave cloth from zombies." For a grey monster,
   it adds "(grey monsters still drop loot)".
4. Otherwise the yellow monster with the most XP per step: "Skeletons in the Old Graveyard are your level."

Always shown during levels 1–9. From level 10, it has a **Hide** switch, and it can be turned back on in settings.

### 9.4 Loss hints
After a loss, the report adds the monster's hint from data, for example "The Graveyard King's armour is heavy: a
stronger weapon helps." These are always shown.

### 9.5 Flavour
Areas and monsters have a one-line description in data, shown the first time they appear, for example "Grey Moor:
fog, wolves, and something that doesn't leave footprints."

## 10. Out of scope
The queue, stop conditions, losing rules, the bigger bank and automatic travel (spec 0003). Spending talent points
and the talent tree. Anything built for the soft cap (bestiary, rare-drop hunts, slayer tiers). Achievement reward
tuning. Art beyond the current text UI.

## 11. Concerns
1. **Content volume (medium).** 19 monsters, about 30 items and 9 areas is a lot of data to tune. The pacing
   simulator needs a smarter player (who crafts each tier, picks the best yellow monster and travels between
   outposts). That's the main build risk.
2. **The level 10 player meets a skull-filled world (low).** That's intended, but until spec 0003, a lost fight ends
   the activity and earns nothing. Building spec 0003 soon after this one keeps scary fights cheap.
3. **Gathering fades (decision for the owner).** §3 fades gathering and crafting XP like monsters, so mining can't
   bypass the soft cap. They still never count as "grey" for stop conditions, so intent 0003's rule holds.
4. **Talent points with nothing to spend them on (low).** The level 10 ceremony promises a speciality that
   arrives later. The card says so plainly.
5. **The level table changes for the existing save.** The level is kept, and the XP is moved to the same fraction
   of the way through that level.

## 12. Acceptance criteria
1. The XP multiplier for every level difference from −10 to +12 matches the §3 table, and loot is identical
   at every colour.
2. Levels continue past the end of the XP list: a save with enough XP reaches level 31 and beyond.
3. Simulated 5,000 steps a day: level 5 on day 1, level 10 on day 12–16, level 30 on day 80–100.
4. Each monster in the roster gives more XP per step than the previous one, and at most a third more, for an
   even-level player with that stretch's gear.
5. Each trait in §5.1 behaves as described, shown by a deterministic test per trait.
6. Each boss meets the §5.3 gear-check win rates over 200 simulated fights, and its XP per step is within the §3 rate for its level.
7. A boss's first-kill item drops exactly once, on the first kill.
8. Gear can't be equipped before its slot's level. Areas, monsters, spots and recipes are hidden before their unlock level.
9. The level-up cards appear on open, before the report, with the §9.1 contents, for a multi-level catch-up.
10. A red or skull fight asks for confirmation. "Next goal" follows the §9.3 rules and can be hidden from level 10.
11. An existing level 10 save loads at level 10, with its progress through the level kept as a fraction.
12. `.\scripts\check.ps1 -Release` is green, and the release build still declares no INTERNET permission.
