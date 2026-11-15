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

Later specs changed parts of this spec; each part says where. Since spec 0008 nothing opens by level but talents, and
the Graveyard King opens the road across the river.

## 1. Decisions on the intent's open questions

| # | Question | Decision |
|---|---|---|
| 1 | Losing fights | Settled in intent 0003 and built with spec 0003 (§5 there): a loss gives part of the XP, and the action ends after 3 losses in a row. |
| 2 | XP fade curve | Medium fade (option B): full XP within 2 levels, green 3–6 below fades to 20%, grey at 7+ below gives 5% (§3). |
| 3 | Monster roster | 14 normal monsters, 3 bosses (levels 10, 20, 30) and 1 lurker over 7 areas (§6): 18 in all. Each has a twist (§5). |
| 4 | Unlock per level | The ladder in §8. Levels 1–9 unlock features and areas. Level 10 opens the whole map. Later levels add recipes, gear slots, ranks and a talent point. Since spec 0008 decision 1 nothing opens by level but talents. |
| 5 | Stat growth | Small numbers (owner's choice): +10 HP, +1 Attack, +1 Defense per level. Gear is about a third of the player's power (§4). |
| 6 | At the soft cap | **Nothing built for it** (owner's choice). The answer to the soft cap is more content. Grey monsters still drop their loot. |
| 7 | Talent points | One point per level from 10. Spec 0015 spends them. |
| 8 | *New:* bosses | A boss every 10 levels. Bosses are **optional**, never a gate. They check gear: at even level without crafted gear the player almost always loses. The reward is a guaranteed first-kill item, not extra XP (§5.3). Since spec 0008 amendment 5 the Graveyard King opens the road across the river, so he is a gate; the Ogre Chieftain and the Young Dragon stay optional. |
| 9 | *New:* danger and guidance | The map opens at level 10, so far-too-strong monsters are visible and fightable (skulls, lurkers). The game guides the player with a warning before deadly fights, a hideable "Next goal" line and loss hints (§9). Since spec 0008 the south of the river is open from level 1. |
| 10 | *New:* role-play for the map opening | Ranks: the player starts as a *Recruit* who stays in the guarded lands. At level 10 they become an *Adventurer* and may cross the river. Then *Veteran* at 20 and *Champion* at 30. Names and lines are flavour in data and can change. Since spec 0008 decision 8 the ranks are titles: the Adventurer line no longer names the river. |

## 2. Character levels

- **No level cap.** The XP thresholds are a list in data up to level 30. After the list, each further level costs
  the previous level's cost × `xpGrowthAfterList` (starting value 1.05), forever.
- **Pacing targets** for a simulated average walker (5,000 steps a day, sensible play including crafting and travel):

| Level | Walked steps (about) | Day |
|---|---|---|
| 5 | 3,500 | 1–2 (1) |
| 10 | 65,000 | 11–16 (12–16) |
| 20 | 240,000 | about 50 |
| 30 | 450,000 | 80–100 for the median of seeds 1–8; 70–105 on each seed |

  Spec 0009 criterion 16 holds these days; the first ones are in brackets. Spec 0009 moved level 5 to day 1–2 (three
  copper weapons), spec 0010 amendment 1 widened level 10, and spec 0009 amendments 1 and 3 gave each seed its range
  for level 30.

  The steps per level rise from 5,000 (level 5 → 6) to 17,000 (9 → 10), then from about 16,000 (10 → 11) to about
  22,000 (29 → 30). That's a level every 1–3 days in the tutorial and every 3–4 days after it.
- **Existing saves keep their level.** Their XP is moved to the same fraction of the way through that level in the
  new table. A version 1 save at level 10 with XP past the old cap (28,000) keeps that extra XP as progress into
  level 10, up to one XP short of level 11.

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

- The multiplier applies to the XP of a won fight and to the partial XP of a lost fight (spec 0003 §5).
  XP is rounded down, but a won fight always gives at least 1 XP.
- **Loot is never reduced.** Grey monsters drop exactly what they always do.
- **Gathering and crafting fade too.** Each gathering spot and recipe has a level (its unlock level), and its XP is
  multiplied by the same table. Without this, mining would bypass the soft cap. They still count as never "grey"
  for intent 0003's stop conditions: "until grey" isn't offered for them. Since spec 0010 their character XP follows
  the profession's rules (spec 0010 §3).
- **XP per step rises with monster level.** For an even-level player with the gear of that stretch, a monster of
  level M gives about `0.2 × 1.1^(M−1)` XP per step (±15%). Each monster in the roster gives at most a third more
  XP per step than the one before it (intent 0003 guardrail). Since amendment 3 the sim walker measures this, not
  the reference player (§5.5).
- **Soft cap.** With the top monster at 30, XP fades from player level 33 and is grey at 37. New content raises
  this without rule changes.
- The bands, multipliers and skull threshold live in data. Spec 0014 draws the skull.

## 4. Stats and gear

- **Base at level 1:** HP 30, Attack 5, Defense 2 (unchanged). **Per level:** +10 HP, +1 Attack, +1 Defense (was +5 HP).
  Spec 0009 §2.2 adds Hit, Crit, Dodge and Block.
- **Gear slots** open by level: weapon and body (1), shield (7), head (12), feet (17), amulet (20). Slots and their
  unlock levels live in data. An item can only be equipped once its slot is open. Since spec 0008 all 16 gear slots
  are open from level 1.
- **Gear is about a third of the player's power** at each stretch: the best craftable set for a level adds roughly
  half of that level's base Attack, Defense and HP. This is what makes the bosses' gear checks work.
- **The trim of 2026-11-09 (amendment 3):** hide, scale and trophy pieces (`reference: false`) and every ring, neck
  and trinket give a third less HP: their base HP × 2/3, rounded. Their other stats, quality bonuses and bonus stats
  stay. A real player wears them, and had about 1.6 times the HP and 1.4 times the Attack of the reference player
  from level 20.

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
The sim walker is the yardstick (§5.5 targets 3–6): a fight takes a median 6–12 rounds and 10–25% of its HP.

The first targets were for an even-level player with the gear of that stretch: normal monsters took 4–8 rounds
(40–80 steps), slow tanks (zombie, stone golem) 12–20 rounds, and that player won at least 90% of normal fights.
Amendment 3 moved them to the walker: in common crafted gear alone a player now loses often from level 8.

### 5.3 Bosses
- **Graveyard King (10), Ogre Chieftain (20), Young Dragon (30).** A boss fight takes 25–40 rounds; the sim walker
  measures it on the King (§5.5 target 6).
- **Gear check targets** (the reference player of spec 0009 §9.1, over 200 simulated fights against each boss):

| Player | Graveyard King (10) | Ogre Chieftain (20), Young Dragon (30) |
|---|---|---|
| Even level, no gear | wins ≤ 10% | wins ≤ 10% |
| 8 levels above, no gear | wins ≥ 50% | — |
| 3 levels below, best crafted gear of their own level | — | wins ≤ 10% |

- Later bosses need both gear and levels. From level 20 gear was worth far more than 5 levels: for a level 35
  player without gear to beat the Young Dragon, the dragon had to hit so softly that a geared level 21 player
  farmed it (amendment 1).
- "Best crafted gear" never includes gear made from the boss's own drops (only materials no other monster or spot
  gives count as the boss's own).
- Out-levelling the King took 5 levels; since the tougher fights it takes 8 (amendment 3 erratum 1: 27.5% wins 5
  levels above, 100% 8 levels above).
- "Even level, best crafted gear of that stretch: wins ≥ 70%" (amendment 1) moved to the sim walker with
  amendment 3, like §5.2.
- **XP per step like a normal monster of its level.** Losing to a boss repeatedly must never be the best way to
  level.
- **First kill:** a guaranteed unique item (King's blade, Chieftain's amulet, Dragon's heart) and an achievement.
  Later kills drop the boss's material as usual. *New rule:* `firstKillDrops` per monster, in data. Since spec 0005
  decision 6 later kills also drop the unique with `repeatChance` (1%).
- **Optional:** nothing requires a boss kill. Since spec 0008 amendment 5 the King opens the road across the river.

### 5.4 Lurkers
A lurker is a monster far above the level of its area, visible from the moment the area opens. It follows the normal
rules for its level. The first one is the **Old Bear (16) in Goblin Woods**: a skull for a new player. More can be
added as data.

### 5.5 The sim walker as the yardstick
Since amendment 3 (#234) the fight targets are measured with the sim walker, not the reference player: the walker
wears what a player really wears. A study of 164,000 sim fights had shown that the walker won all but 30, a fight
took 5 rounds, the walker lost a median 4% of its HP, and from level 20 its hit chance sat at its cap in most fights.

| # | Target | Before | Round 3 of the study |
|---|---|---|---|
| 1 | Mixed walker: median day of level 30 in 80-100 (spec 0009 amendment 1) | 90.5 | 91.5 |
| 2 | Pure fighter: median day of level 30 in **80-120** (was 70-100) | 83.5 | 114 |
| 3 | Mixed walker: median rounds of a fight in 6-12 | 5 | 8 |
| 4 | Mixed walker: median HP taken in a fight in 10-25% | 4% | 15% |
| 5 | Mixed walker: 3-12% of fights take more than half its HP | 0.3% | 6.4% |
| 6 | Mixed walker: the Graveyard King takes a median 25-40 rounds | 18 | 30 |
| 7 | The player's hit chance in a fight never goes above 90% | at 95% in 68% of fights | at 90% in about half |

- The study ran 8 seeds, 120 days, 5,000 steps a day; the build checked the targets again on 16 seeds with the
  gentle start (§6).
- If a target fails, Claude reports the numbers to the owner before any tuning.
- **The walker's habits:** when no fight is safe, a walker takes the fight that pays the most XP per step among those
  it wins on average swings, not the first monster in the data. The fighter takes fights that it wins with at least
  10% of its HP left; the mixed walker keeps 25%. Spec 0010 §9.2 lists the walkers.
- **The reference checks that stay** (the reference player of spec 0009 §9.1): the boss checks of §5.3, the strong
  weapon type (spec 0009 §9.1), and the two-hander and shield checks (spec 0009 criterion 6). These compare the
  weapons 5 levels above each monster of the stretch, where the one-hander wins: about 25% fewer rounds (at least
  15%), and the shield takes at least 20% off the damage (amendment 3 erratum 1).

## 6. Areas, monsters and routes

Monsters keep their `unlockLevel` (the level from which they show). Tutorial monsters show at the level in §8.
Bosses and lurkers show from the moment their area opens.

| Area | Opens | Crafting | Monsters (level, traits/shape) | Drops |
|---|---|---|---|---|
| Camp | 1 | yes | — | — |
| Goblin Woods | 1 | | Goblin (1), Goblin brute (4, sturdy), *Old Bear* (16, quick, hits hard) | hide; hides; bear-pelt cloak, 58.93% (25%); a cloak since spec 0008 decision 2 |
| Copper Hills | 2 | | copper vein | copper ore |
| Old Graveyard | 6 | | Skeleton (6, heavy armour, little HP), Zombie (8, slow, huge HP, hits hard), **Graveyard King** (10, heavy armour, hits hard) | bones; grave cloth; bones + grave cloth |
| Grey Moor | 10 | yes (outpost) | Wolf (11, quick, light armour), Ghost (13, ghostly), Bandit (15, hits very hard, little HP) | wolf pelt; ectoplasm; leather, iron ore |
| Iron Ridge | 10 | | iron vein (Mining 10 since spec 0010; mining from level 12 at first) | iron ore |
| Troll Bridge | 10 | | Giant spider (16, quick, little HP), Troll (18, regenerates), **Ogre Chieftain** (20, slow, enormous HP, crushing hits) | silk; troll hide; troll hide |
| Mountain Pass | 10 | yes (lodge) | Stone golem (21, slow, very heavy armour), Harpy (23, quick, ghostly), Wraith (25, ghostly, regenerates) | stone core; feathers; soul dust |
| Mithril Deep | 10 | | mithril vein (Mining 20 since spec 0010; mining from level 22 at first) | mithril ore |
| Dragon's Peak | 10 | | Wyvern (27, quick, hits hard), Fire drake (28, regenerates, armour), **Young Dragon** (30, quick, regenerates, armour, hits hard) | wyvern scale; drake fang; dragon scale |

- Since spec 0008 every area opens at level 1 and `unlockLevel` left the data; the "Opens" column is the first
  build's. Spec 0011 adds Mirror Lake and Smugglers' Cove.
- The Old Bear's drop is that of `enemies.json`, with the first chance in brackets.

**The monsters' numbers** (`enemies.json`, amendment 3 and its erratum 1, 2026-11-09)
- Normal monsters and lurkers from level 8: HP × 2 and Attack × 1.35 of their numbers before.
- **The gentle start:** Goblin, Goblin brute and Skeleton (levels 1-6): HP × 1.5, the same Attack.
- Bosses: HP × 1.5 and Attack × 1.2.
- **XP follows the fight:** each monster's XP grew by the same factor as its fight length: the rounds of its fight
  against the reference player at its level, after ÷ before, with average swings (`estimateFight`). So XP per step
  stayed about the same. The Goblin is the exception: it gives **20 XP**, so one kill still gives level 2.
- **Loot follows the fight too:** each normal monster's drop chances grew by the same factor; gear drops by 1.5 times
  more. A chance above 100% became 100% with a bigger count. Boss drops stayed.
- The base hit chance is 75% and its top 90% (spec 0009 §2.1).

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
crafting possible without walking back to Camp. Spec 0003 added automatic travel over several legs. Since spec 0008
amendment 5 the road from Old Graveyard to Grey Moor opens with the first kill of the Graveyard King.

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

Since spec 0009 §4 each tier has a sword, a spear and a mace, and one two-hander from bone on; the troll-bone maul
is the two-hander of its tier. Since spec 0010 recipes need a Crafting level, and some take logs: the bone shield 2
oak logs, the iron shield 2 ash logs, the troll-bone maul 3 ash logs, the golem-core shield 2 pine logs.

## 8. The level ladder

Every level-up gives stats (§4) and at least one named unlock. From level 10, every level also gives a talent point.
Since spec 0008 decision 1 nothing opens by level but talents: the table is the ladder of the first build. A level-up
card now names stats, ranks, talent points and the monsters that are now the player's level or grey.

| Lvl | What's new |
|---|---|
| 1 | Goblin Woods, goblins, travel, the step bank. The Old Bear shows as a skull. |
| 2 | Copper Hills, mining |
| 3 | Crafting: copper sword, hide vest |
| 4 | Goblin brute |
| 5 | Queue of 2 actions, "until I have N" (spec 0003) |
| 6 | Old Graveyard, skeletons, bone sword. The Graveyard King shows (orange: level 10 against 6 is +4). |
| 7 | Shield slot, bone shield |
| 8 | Queue of 3 actions (spec 0003), zombies |
| 9 | Stitched armour: the first two-monster recipe, which sends the player back to grey goblins |
| 10 | **Adventurer:** the whole map opens, first talent point, the King is the player's level |
| 11–30 | As in §7, plus the head slot (12), feet slot (17), amulet slot and **Veteran** (20), iron mining (12), mithril mining (22), **Champion** (30). Levels 16 and 21 bring no new recipe: their named unlock is "a monster is now your level" (giant spider at 16, stone golem at 21). |

Ranks (name, level, ceremony line) live in data. Since spec 0008 decision 7 the queue holds 5 actions from level 1.

## 9. Screens

### 9.1 Level-up cards
- Each level gained gets a card: the new level, the stats gained, and what's new. While the player was away, the
  cards show on app open before the report. While the app is open, they show when the level-up happens.
- The player swipes through them, or taps **Skip all**.
- **What's new** lists, in order:
  1. the rank ceremony line (levels 10, 20, 30)
  2. everything whose unlock level is this level (areas, monsters, gathering spots, recipes, gear slots, features);
     since spec 0008 nothing has one
  3. the talent point (from 10)
  4. monsters that are now the player's level
  5. monsters that just turned grey, with "still drops its loot"
- With more than 3 cards, all but the last can be collapsed into one summary card.

### 9.2 Colours in the fight list
Each monster shows its level in its colour, or a skull. Starting a fight against a red or skull monster asks for
confirmation: "Deadly: you will almost certainly lose." Orange shows "Risky" without asking.

**"Low XP" on grey monsters** (owner, 2026-11-01: "I feel a warning that it is low xp might be worth while? Just like
the risky fights.")
- The row of a grey monster starts its line of stats with "Low XP · ", as an orange row starts with "Risky · ".
  Example: "Low XP · HP 19 · Atk 4 · Def 1 · 1 XP". A grey monster gives 5% of its XP, at least 1, and the row showed
  the number without saying why it was so low.
- Only the words "Low XP" are in the grey of the level badge (`#9E9E9E`, a band colour of spec 0014 §2.1). The rest
  of the line keeps its colour.
- No popup: a grey fight starts with no question. No setting is needed. Green monsters show no word.

### 9.3 Next goal
One line on the main screen, worked out from the save, with the first rule that applies:
1. An owned item is better than the one equipped: "Equip the bone shield."
2. A recipe that improves a slot can be crafted now: "Craft stitched armour at Camp."
3. A recipe that improves a slot is missing materials: "Get 3 more grave cloth from zombies." For a grey monster,
   it adds "(grey monsters still drop loot)".
4. Otherwise the yellow monster with the most XP per step: "Skeletons in the Old Graveyard are your level."

Always shown during levels 1–9. From level 10, it has a **Hide** switch, and it can be turned back on in settings.
Since spec 0008 decision 9 the switch is there from level 1.

### 9.4 Loss hints
After a loss, the report adds the monster's hint from data, for example "The Graveyard King's armour is heavy: a
stronger weapon helps." These are always shown.

### 9.5 Flavour
Areas and monsters have a one-line description in data, shown the first time they appear, for example "Grey Moor:
fog, wolves, and something that doesn't leave footprints."

## 10. Out of scope
Anything built for the soft cap (rare-drop hunts, slayer tiers). Later specs built the rest of this list: the queue,
stop conditions, losing rules, the bigger bank and automatic travel (spec 0003), the talent trees (spec 0015), the
bestiary and its Slayer mark (spec 0009 §7), achievement rewards (spec 0017) and art (spec 0014).

## 11. Concerns
1. **Content volume (medium).** 18 monsters, about 30 items and 9 areas is a lot of data to tune. The pacing
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
3. Simulated 5,000 steps a day: level 5 on day 1–2, level 10 on day 11–16, level 30 on day 80–100 (spec 0009
   criterion 16 holds these days; it was day 1 and day 12–16).
4. Each monster in the roster gives more XP per step than the previous one, and at most a third more, for an
   even-level player with that stretch's gear. Since amendment 3 the sim walker measures it (§5.5), not the
   reference player.
5. Each trait in §5.1 behaves as described, shown by a deterministic test per trait.
6. Each boss meets the §5.3 gear-check win rates over 200 simulated fights, and its XP per step is within the §3
   rate for its level (since amendment 3 measured with the sim walker).
7. A boss's first-kill item drops exactly once, on the first kill. Since spec 0005 decision 6 later kills drop it
   with `repeatChance`.
8. Removed on 2026-10-21: spec 0008 decision 1 opens every slot, area, monster, spot and recipe from level 1.
9. The level-up cards appear on open, before the report, with the §9.1 contents, for a multi-level catch-up.
10. A red or skull fight asks for confirmation. "Next goal" follows the §9.3 rules and can be hidden from level 10.
11. An existing level 10 save loads at level 10, with its progress through the level kept as a fraction. A version
    1 save at level 10 with XP past 28,000 keeps that XP as progress, up to one XP short of level 11.
12. `.\scripts\check.ps1 -Release` is green, and the release build still declares no INTERNET permission.

**Fight rows**
13. The row of a grey monster starts its stats with "Low XP".
14. Only the words "Low XP" are `#9E9E9E`.
15. The row of a green, yellow or orange monster does not say "Low XP".
16. Starting a fight against a grey monster asks no question.

**Tougher fights: the data** (a one-time script made the new numbers; PR #245 lists each monster's and item's old and
new numbers)
17. Each monster of level 8 and up but the bosses has HP × 2 and Attack × 1.35 of its numbers before 2026-11-09,
    rounded.
18. Goblin, Goblin brute and Skeleton have HP × 1.5 of their numbers before 2026-11-09, rounded, and the same Attack.
19. Each boss has HP × 1.5 and Attack × 1.2 of its numbers before 2026-11-09, rounded.
20. Each monster's XP is its XP before 2026-11-09 × its rounds factor (§6), rounded; the Goblin gives 20 XP.
21. Each normal monster's drops follow §6 "Loot follows the fight"; boss drops are as before.
22. `economy.json` has `hitBase` 75 and `hitMax` 90.
23. The pieces of the §4 trim have two thirds of their HP before 2026-11-09, rounded; other items are unchanged.

**Tougher fights: hit**
24. At even level with no Hit, about 75% of swings hit (± 1 point over many seeded swings).
25. No hit chance goes above 90%, with any Hit, Slayer or level gap.

**Tougher fights: the walker and the pace**
26. Targets 1-7 of §5.5 hold on 16 seeds (a hand-run sim), or the owner accepts the numbers.
27. The pacing test checks targets 1, 2 and 3-6 on seeds 1-8.
28. The reference checks that stay (§5.5) pass; the ones that moved to the walker are gone from `roster_test.dart`.

**Tougher fights: saves and notes**
29. No save change; every save fixture loads.
30. `releases/next/` has a line for players: monsters are tougher, fights are longer and pay more, and hits miss more
    often.

## History
- 2026-10-19: first version (intent 0002, plan 0003). Criteria 1-12.
- 2026-10-19, amendment 1 (plan 0003 M3): later bosses need both gear and levels; the verifier's corrections (the
  King orange at level 6, 18 monsters, levels 16 and 21, version 1 saves past 28,000 XP). Decision 3; §2; §5.3; §8;
  §11; criteria 6 and 11.
- 2026-10-19, spec 0003: the queue, losses with part of the XP, automatic travel. Decision 1; §3; §6; §10.
- 2026-10-19, spec 0005: boss uniques drop again with `repeatChance`. §5.3; criterion 7.
- 2026-10-21, spec 0008: nothing opens by level but talents; all gear slots from level 1; Next goal's Hide from level
  1. Decisions 4, 9 and 10; §4; §6; §8; §9.1; §9.3; criterion 8 removed.
- 2026-10-21, spec 0009: Hit, Crit, Dodge and Block; a weapon of each damage type per tier; the bestiary; level 5 on
  day 1-2; the reference player of spec 0009 §9.1. §2; §4; §7; §10; criteria 3, 4 and 6.
- 2026-10-21, spec 0010: profession levels; the mining veins need Mining 10 and 20; logs in some recipes. §3; §6; §7.
- 2026-10-21, spec 0010 amendment 1: level 10 on day 11-16. §2; criterion 3.
- 2026-10-21, spec 0009 amendment 1: each seed reaches level 30 on day 70-100, the median on day 80-100. §2.
- 2026-10-22, spec 0011: Mirror Lake and Smugglers' Cove. §6.
- 2026-10-22, spec 0014: the drawn skull, art. §3; §10.
- 2026-10-24, spec 0017: achievement rewards. §10.
- 2026-10-31, spec 0015: the talent points are spent. Decision 7; §10.
- 2026-11-01, amendment 2 (plan 0033): "Low XP" on grey monster rows. §9.2; criteria 13-16.
- 2026-11-02, spec 0009 amendment 3 (#181): each seed reaches level 30 by day 105. §2.
- 2026-11-07, spec 0008 amendment 5 (#233, plan 0055): the Graveyard King opens the river. Decisions 8 and 10; §5.3;
  §6.
- 2026-11-09, amendment 3 (#234, plan 0057): tougher, longer fights; the sim walker as the yardstick; base hit 75%.
  §3; §4; §5.2; §5.3; §5.5; §6; criteria 4, 6 and 17-30.
- 2026-11-09, amendment 3 erratum 1 (#234, plan 0057): the Goblin gives 20 XP; the King is out-levelled at 8 levels;
  the two-hander and shield checks 5 levels above; the gatherer's target dropped (spec 0010). §5.3; §5.5; §6;
  criterion 20.
- 2026-11-15 (plan 0068): the amendments and the erratum folded into this file. §6 gives the Old Bear's drop chance
  of `enemies.json` (58.93%), with the first 25% beside it; §2 and criterion 3 give the days of spec 0009 criterion 16
  (day 1-2, day 11-16), with the first ones beside them. No rule or criterion changed.
