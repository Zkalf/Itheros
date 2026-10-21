# Spec 0009: Fights with depth

Status: accepted
Intent: [intent/0009-fights-with-depth.md](../intent/0009-fights-with-depth.md) (accepted, commit 44ad50c)
Builds on: spec 0002 + amendment 1 (combat, traits, bosses, gear checks), spec 0005 + amendments (qualities),
spec 0008 + amendments 1–3 (paper doll, the two-hand rule)
Overrides: spec 0001 §4 (every hit lands); spec 0002 §4 (stats), §7 (weapon rows, the maul), §10 (bestiary out of
scope), criterion 3 (level 5 on day 1–2), criteria 4 and 6 (who the reference player is); spec 0005 decision 7 (which stats quality raises), §5 and
§7 (stacks, affixes out of scope), criteria 5 and 8; spec 0006 decision 8 and criterion 3 (fight log lines); spec
0004 §2 (the journal becomes the Log tab); spec 0008 decision 3, §2.2, §3.2 (tapping a monster), §3.5 (item card),
§4 and criteria 6 and 8
Product owner: Zkalf
Date: 2026-10-21

Swings can miss, crit and be blocked. Monsters wear light, medium or heavy armour, and weapons deal slash, pierce
or crush damage. Gear above Common rolls random bonus stats. A shield brings Block, a two-hander hits harder. The
Journal gets a Bestiary that fills in as the player fights a monster or finds lore about it. A fight still resolves
from steps alone. All numbers are starting values in `data/*.json`, tuned with the pacing simulator.

## 1. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | Weapons for each damage type | **A full set per tier** (owner's choice), copper included: each tier has a sword (slash), a spear (pierce) and a mace (crush) from that tier's materials. Crafting all three copper weapons on day 1 moves level 5 to day 2 in the sim; the owner accepts that (spec 0002's level 5 target becomes day 1–2) and may drop the copper spear and mace later. |
| 2 | Two-handers | **One per tier from bone on** (owner's choice), rotating type: Bone greataxe (slash), Iron pike (pierce), Troll-bone maul (crush), Mithril greatsword (slash), Drake-fang halberd (pierce). |
| 3 | Is the type rule written down? | **No** (owner's choice). Nothing in the game states which type beats which armour. The first fight shows a monster's armour; its weakness shows after 10 kills or from a lore note. |
| 4 | Lore notes | **Notes about stronger foes** (owner's choice): each monster can drop one note about a tougher monster in or near its area (§7.2). About 1 in 100 kills; each note drops once. |
| 5 | Repeated bonus stats | **Repeats stack and values roll** (owner's choice): each bonus stat is drawn on its own, so an item can have Crit three times, each with its own value. |
| 6 | Does the type rule have a neutral? | Yes. Each armour has one strong type (+30%), one weak type (−20%) and one neutral type (§3). Each damage type is strong once, neutral once and weak once. |
| 7 | Monster crits and blocks | Monsters don't crit or block in this spec. They can have Dodge (data). |
| 8 | Bare hands | No damage type: always neutral. |
| 9 | How does a two-hander hit harder? | With a bigger Attack number in data; no extra rule. Tuned so a two-hander kills about 25% faster than the one-hander of its tier (§4.2). |
| 10 | Unknown bestiary entries | Every monster in an area that isn't fogged has a card. What isn't learned yet shows "???". |
| 11 | Tapping a monster | Opens one sheet: its bestiary card on top, today's fight choices (stop condition, Start, Queue) below. Starting a fight takes no extra tap. |

## 2. Hit, miss, crit and block

### 2.1 Every swing
Each swing (the player's or the monster's) goes through two rolls:

1. **Hit or miss**, the attacker's roll:
   `hit chance = 85% + 3% × (attacker level − defender level) + attacker Hit`, kept between 50% and 95%.
   A miss deals nothing: "You miss", "<Monster> misses".
2. **Dodge**, the defender's own roll, only on a hit: with chance Dodge the defender slips the blow and takes
   nothing: "<Monster> dodges", "You dodge". Dodge is 0% unless gear (or the monster's data) gives it.

So Hit only fights misses, and nothing lowers the defender's Dodge. A swing lands with
`hit chance × (1 − Dodge)`.
- **Crit:** a hit by the player is critical with chance Crit and deals **double** damage. The player has 5% Crit
  base. Monsters don't crit.
- **Block:** a monster's hit is blocked with chance Block and deals **30%** of its damage (rounded, at least 1).
  Block comes only from the off hand (a shield's base Block and its bonus stats).
- Damage before these is `max(1, attack − defense ÷ 2)` × the type factor (§3) × the ±20% roll, as today.
- Caps (data): Crit 50%, Block 50%, Dodge 30%. Hit is held in by the 50–95% bounds.
- Traits work as before: quick still strikes first, slow still swings every second round, ghostly still ignores
  defence (but can be dodged and blocked), regeneration still happens after the monster's turn, hit or miss.
- All the numbers above (85%, 3%, the bounds, base Crit, crit size, block share, caps) live in `economy.json`.

### 2.2 Stats
The player's stats are now HP, Attack, Defense, **Crit**, **Hit**, **Dodge** and **Block**. The level gives HP,
Attack and Defense as today. The others come from gear, plus the 5% base Crit. The Character screen shows them all.

## 3. Armour and damage types

| Monster armour | Strong (+30%) | Neutral | Weak (−20%) |
|---|---|---|---|
| Light | slash | pierce | crush |
| Medium | pierce | crush | slash |
| Heavy | crush | slash | pierce |

The factors live in data. The player's damage type is the main-hand weapon's; bare hands are neutral. Monsters'
attacks have no type.

**Monster armour and Dodge** (data; lore first, then balance):

| Light | Medium | Heavy |
|---|---|---|
| Goblin, Goblin brute, Zombie, Wolf (Dodge 8%), Ghost (Dodge 5%), Troll, Harpy (Dodge 10%) | Old Bear, Bandit, Giant spider (Dodge 8%), Ogre Chieftain, Wraith, Wyvern (Dodge 5%) | Skeleton, Graveyard King, Stone golem, Fire drake, Young Dragon |

The tutorial stays readable: the copper sword is strong against the light goblins, and the copper mace is ready
for the first heavy monster (Skeleton, level 6).

## 4. Weapons

### 4.1 The weapon list
Each weapon has a `damageType` in `items.json`. New recipes use the tier sword's materials and step cost;
two-handers cost more.

| Tier | Slash | Pierce | Crush | Two-hander |
|---|---|---|---|---|
| Copper (3) | Copper sword | **Copper spear**; Rusty dagger (drop) | **Copper mace** | — |
| Bone (6) | Bone sword | **Bone spear** | **Bone club** | **Bone greataxe** (8, slash: 10 bones, 3 copper ore) |
| Graveyard King | King's blade (unique) | | | |
| Iron (14) | Iron sword | **Iron spear** | **Iron mace** | **Iron pike** (16, pierce: 12 iron ore, 2 leather) |
| Troll (19) | | | | Troll-bone maul (crush; becomes two-handed) |
| Mithril (22) | Mithril sword | **Mithril spear** | **Mithril mace** | **Mithril greatsword** (24, slash: 12 mithril ore, 2 stone cores) |
| Drake-fang (28) | Drake-fang blade | **Drake-fang spear** | **Drake-fang hammer** | **Drake-fang halberd** (29, pierce: 6 drake fangs, 10 mithril ore) |

14 new weapons and recipes (bold). A spear or mace has the same Attack as its tier's sword.

### 4.2 One hand and shield, or two hands
- Two-handers follow spec 0008 §2.1 (Off hand greyed out; equipping one moves the shield to the bag).
- Shields get a base **Block**: Bone shield 10%, Ectoplasm ward 5%, Iron shield 15%, Golem-core shield 20%.
- **Targets** (simulated, even-level player with that stretch's gear, against the monsters of that stretch, using
  the strong type where the tier has it): a two-hander wins in about 25% fewer rounds than the tier's one-hander
  (at least 15%). The one-hander with a shield takes at least 20% less damage per fight. Starting Attack:
  greataxe 8, pike 14, maul 16, greatsword 23, halberd 27.

## 5. Bonus stats

### 5.1 Rolling
- When gear is crafted or dropped, after its quality roll, it rolls one bonus stat per quality step: Uncommon 1,
  Rare 2, Epic 3, Legendary 4. Common has none. All rolls use the save's seeded generator, so results stay
  deterministic.
- Each roll picks one stat at random (equal chance) from the pool open at the item's **tier**, then a whole-number
  value in that stat's range. Repeats stack (decision 5).
- An item's tier comes from its item level (spec 0005 decision 2): tier 1 up to level 9, tier 2 for 10–19, tier 3
  from 20.

| Tier | Pool | Crit | Health | Hit | Dodge | Block (shields only) |
|---|---|---|---|---|---|---|
| 1 | Crit, Health | 1–2% | 4–8 | — | — | — |
| 2 | + Hit, Dodge, Block | 1–3% | 10–18 | 2–4% | 2–4% | 3–5% |
| 3 | same | 2–4% | 20–34 | 3–5% | 3–5% | 3–6% |

Pools, ranges and tier bounds live in `economy.json`. Block is only in the pool for off-hand items.

### 5.2 What stays as it is
Quality still raises the item's **base** HP, Attack and Defense by spec 0005 decision 7. It doesn't raise base
Block or Dodge, or bonus stats. Boss uniques roll bonus stats like any drop.

### 5.3 Stacks and comparing
- Items stack only when item, quality **and bonus stats** match (overrides spec 0005 §5 and spec 0008 §2.2). Common
  gear still stacks freely.
- "Better" (bag order, best first in the slot sheet, Next goal, the simulated player) weighs every stat. Next goal
  compares a weapon only with weapons of the same damage type and hands, so it never tells a player to swap the
  mace they chose for a sword.

### 5.4 Gear already owned
On the first load of the new version, every owned item above Common (bag and worn) rolls its bonus stats once,
using the item's quality and tier and the save's generator. Common gear is unchanged.

## 6. The player's armour types
Every armour item gets a type in data, shown on its item card ("Light armour · Chest"). The type shapes the base
stats only: light items carry a small base Dodge, heavy items lean on Defense. It doesn't change how monster attacks
land (the intent's one-way rule; the owner may revisit it after playtests).

| Light (base Dodge) | Medium | Heavy |
|---|---|---|
| Hide vest 2%, Stitched armour 2%, Wolf-pelt vest 3%, Bear-pelt cloak 2%, Silk boots 2%, Feather boots 3% | Studded leather, Troll-hide armour, Wyvern-scale armour | Iron helm, Mithril armour, Mithril helm, Dragon-scale armour, Dragon helm |

Amulets, rings and trinkets have no armour type.

## 7. Learning foes

### 7.1 The bestiary
A card per monster, filled in by fighting it:

| Learned | Shows |
|---|---|
| Always | Name, level badge, area, flavour line, drops as on the map ("2 of 3 found") |
| First fight (won or lost) | Armour type |
| 10 kills | Weakness ("Weak to crush"), HP, Attack, Defense, Dodge and traits ("Quick: strikes first") |
| 50 kills | **Slayer** mark: +5% Hit against this monster |

- Kills count every kill so far: a save with 300 goblin kills opens with the goblin card full and Slayer earned.
  Old saves count a monster as fought once it has a kill.
- Drop chances are never shown.
- The card shows the kill count and the next goal on it ("7 more kills to learn its weakness").
- Slayer and the 10-kill reveal are level-up-style news in the report: "Goblin: weakness learned", "Slayer:
  Goblin".

### 7.2 Lore notes
- Each note is about one monster and reveals its **armour and weakness** (not its stats). It drops from one monster
  at 1% per kill (data) and only until found.
- Starting list (dropped by → about): Goblin → Goblin brute, Goblin brute → Old Bear, Skeleton → Zombie, Zombie →
  Graveyard King, Graveyard King → Wolf, Wolf → Ghost, Ghost → Bandit, Bandit → Giant spider, Giant spider → Troll,
  Troll → Ogre Chieftain, Ogre Chieftain → Stone golem, Stone golem → Harpy, Harpy → Wraith, Wraith → Wyvern,
  Wyvern → Fire drake, Fire drake → Young Dragon. 16 notes; the texts (two or three lines, in the voice of whoever
  wrote them) live in data and can be rewritten freely.
- A found note is named in the report ("Found a lore note: The King's armour") and kept in the Lore tab.
- Intent 0010's camp NPC tips will reveal the same two facts through the same mechanism.

## 8. Screens

### 8.1 Fight log (Now)
Each round's line names what happened: "You hit for 9", "Critical hit for 18", "You miss", "Skeleton dodges",
"Skeleton hits you for 7", "You dodge", "You block: 2 damage", "Skeleton misses". The log length stays
`fightLogRounds`. Overrides spec 0006 decision 8's wording.

### 8.2 Item card and slot sheet
Adds, under the base stats: the weapon's damage type and hands ("Pierce · One hand"), or the armour type; then the
bonus stats, one line each ("+3% Crit", "+12 Health"). Repeated stats show as separate lines. The comparison
against the worn item covers every stat. List rows (bag grid, doll, slot sheet rows) show no bonus stats (intent
0008's clean UI).

### 8.3 Bestiary card
Opened by tapping a monster in Now's Here list, the World area sheet, or the Bestiary tab. From Now and World, the
fight choices sit under the card (decision 11). The card follows §7.1.

### 8.4 Journal tabs
The Journal (top bar) gets three tabs:
- **Log:** today's journal, unchanged (spec 0004 §2).
- **Bestiary:** every monster with a card (decision 10), grouped by area in map order, each with its level badge, a
  "?" if its weakness isn't known, and a Slayer mark.
- **Lore:** found notes, newest first, with "6 of 16 found".

### 8.5 Character
The stats block shows Crit, Hit, Dodge and Block next to HP, Attack and Defense.

## 9. Balance

### 9.1 The reference player
The "even-level player with the gear of that stretch" of spec 0002 (§3 XP rate, §5.2 fight lengths, §5.3 gear
checks and amendment 1, criteria 4 and 6) now wields the best crafted one-hander of the **strong** type for the
monster, with a shield, where its tier has one. All its gear is common (no bonus stats). Overrides criteria 4 and 6's
reading of "best crafted gear".

### 9.2 The simulated player
It arms the weapon (and shield or two-hander) that wins fastest and safely before each fight, as a player who has
learned the monster would. It crafts each weapon type once per tier, as it does other upgrades.

### 9.3 Retuning
Monsters keep their XP and get new HP (and Attack where a boss check needs it), so spec 0002's XP per step and
fight lengths hold for the reference player. Bonus stats are then sized so the simulated walker keeps the pacing
targets.

### 9.4 Prototype numbers (throwaway sim in the scratchpad, 8 seeds, 5,000 steps a day)

| Version | Level 30 on day |
|---|---|
| main today | 81–87 |
| misses only (85% at even level) | 85–94 |
| everything, monsters unchanged | 56–80 (too fast) |
| everything, monster HP refitted (mostly +5% to +35%), bonus stats at the §5.1 sizes | 77–90 |

The prototype rolled bonus stats as their average, so the build adds the spread of real rolls. Plan 0011 tunes
until every seed lands in the targets below.

## 10. Save
New save version. Items carry their bonus stats. The save keeps fought monsters (for armour), found lore notes and
the Slayer marks (kills are already counted). On load: §5.4 rolls, and every monster with a kill counts as fought.
Every fixture in `app/test/fixtures/saves/` loads.

## 11. Out of scope
Weapon loadouts and automatic swaps between queued fights; dust, rerolls and salvage (intent 0010); the NPC tips
themselves (0010); monster crits and blocks; armour types that change how attacks land; new monsters or areas; set
items; anything that shows drop chances.

## 12. Concerns
1. **Swapping weapons by hand (medium).** Queued fights against different armour all use the weapon worn when they
   start. The simulated player swaps before each fight, which is a little kinder than a real player. Loadouts are
   the later fix; the sim's pacing has margin to spare against the top of the range (100).
2. **Wider luck spread (medium).** Stacking bonus stats make lucky runs faster (the prototype's fastest seed was day
   77). That's the Diablo chase the owner asked for, but it puts pressure on the "day 80" floor. If tuning can't
   hold every seed in range, the plan asks the owner before amending spec 0002.
3. **More recipes (low).** 14 new weapons make the Professions list longer. It keeps tier order, so the first rows
   are the ones the player can make.
4. **The hidden rule (low).** Players who never open the Bestiary may never learn the types. The loss hint (spec
   0002 §9.4) can point at it in plain words: "Its armour turns blades. Try something heavier."

## 13. Acceptance criteria
1. Hit chance follows §2.1 for every level difference from −10 to +12, with Hit, inside the 50–95% bounds (table
   test); Dodge never changes the hit chance.
2. Over many seeded swings at even level with no Hit or Dodge, 85% ± 1 point hit; misses deal nothing. With 10%
   Dodge, about 10% of the hits are dodged and deal nothing.
3. A crit deals double damage; a blocked hit deals 30% (at least 1); monsters never crit; Block comes only from the
   off hand; caps hold (deterministic tests).
4. The type factor follows the §3 table for all nine pairs; bare hands are neutral.
5. Every monster has an armour type, and every weapon a damage type; the weapon list matches §4.1; the Troll-bone
   maul and the four other two-handers are two-handed.
6. Each tier's two-hander and one-hander with shield meet the §4.2 targets in the tuning report.
7. Common gear has no bonus stats; each quality step above adds exactly one; each roll comes from the pool of the
   item's tier, inside its range; Block appears only on off-hand items; repeats can occur (seeded tests).
8. Bonus stats are deterministic: the same save and steps give the same items.
9. Items stack only with the same item, quality and bonus stats; no equip, swap or unequip loses an item or changes
   its bonus stats.
10. An existing save loads with every item above Common holding its bonus stats, Common gear unchanged, and every
    monster with kills counted as fought.
11. The bestiary card reveals armour after the first fight, weakness and stats at 10 kills, Slayer (+5% Hit) at 50,
    and never shows drop chances; a save with old kills opens with those cards filled in.
12. A lore note drops only from its monster, at most once, and reveals its subject's armour and weakness.
13. The fight log names hits, misses, dodges, crits and blocks as separate lines (§8.1); the item card shows the damage or armour type,
    hands and bonus stats; list rows show no bonus stats.
14. The Journal has Log, Bestiary and Lore tabs; tapping a monster in Now or World opens its card with the fight
    choices.
15. Spec 0002's targets hold with the §9.1 reference player: XP per step and step-up per monster (criterion 4), fight
    lengths (§5.2), and every boss's gear checks (criterion 6, amendment 1).
16. Simulated 5,000 steps a day on seeds 1–8: level 5 on day 1–2 (was day 1, decision 1), level 10 on day 12–16, level 30 on day 80–100.
17. `.\scripts\check.ps1 -Release` is green, with no INTERNET permission.
