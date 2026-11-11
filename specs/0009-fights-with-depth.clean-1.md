# Spec 0009: Fights with depth (clean edition 1)

Status: accepted
Clean edition of: [spec 0009](0009-fights-with-depth.md) with its erratum 1, its amendments 1-4 and amendment 4
erratum 1, and the parts of other specs that change spec 0009 (see [Changes from other specs](#changes-from-other-specs))
Up to: 2026-11-11 (main 16bb9b9)
Issue: #59
Product owner: Zkalf

## How to read this edition
- This edition changes no rule, number or criterion. It says in one file what spec 0009 and its changes say today.
- The accepted files stay the record. If this edition and an accepted file differ, the accepted file wins, and an
  erratum fixes this edition.
- The section numbers (§1-§13), the decision numbers (1-11) and the criterion numbers (1-17) are those of spec 0009.
  Code and tests that cite them stay right.
- A tag such as **(am. 4 rule 6)** marks a text that came from an amendment.
- §13 keeps the criteria of each amendment under its own heading, with their own numbers.
- [Where each change went](#where-each-change-went) lists every amendment and erratum and its place here.
- A new change to spec 0009 is a new amendment of spec 0009, as before. A later clean edition folds it in.

Intent: [intent/0009-fights-with-depth.md](../intent/0009-fights-with-depth.md) (accepted, commit 44ad50c)

Spec 0009 builds on:
- spec 0002 and its amendment 1 (combat, traits, bosses, gear checks);
- spec 0005 and its amendments (qualities);
- spec 0008 and its amendments 1-3 (the gear slots, the two-hand rule).

Spec 0009 overrides:
- spec 0001 §4 (every hit lands);
- spec 0002 §4 (stats), §7 (weapon rows, the maul), §10 (bestiary out of scope), criterion 3 (level 5 on day 1-2),
  criteria 4 and 6 (who the reference player is);
- spec 0005 decision 7 (which stats quality raises), §5 and §7 (stacks, affixes out of scope), criteria 5 and 8;
- spec 0006 decision 8 and criterion 3 (fight log lines);
- spec 0004 §2 (the journal becomes the Log tab);
- spec 0008 decision 3, §2.2, §3.2 (a tap on a monster), §3.5 (item card), §4 and criteria 6 and 8.

## Summary
- Swings can miss, crit and be blocked.
- Monsters wear light, medium or heavy armour. Weapons deal slash, pierce or crush damage.
- Gear above Common rolls random bonus stats.
- A shield brings Block. A two-hander hits harder.
- The Journal gets a Bestiary that fills in as the player fights a monster or finds lore about it.
- A fight still resolves from steps alone.
- All numbers are values in `data/*.json`, tuned with the pacing simulator.

## Changes from other specs

| Spec | What it changes in spec 0009 | Folded in |
|---|---|---|
| Spec 0002 amendment 3 | §2.1: the base hit chance is 75% and its top is 90%; the reference checks of §9.1 move to the walker; monster numbers | §2.1, §9, criterion 15 |
| Spec 0008 amendment 7 | Amendment 4 rule 10: the meal line under a stat reads "+19 meal", without brackets | §8.5 |
| Spec 0015 (talent trees) | Talents add Crit, Hit and Dodge, within the caps; Impale raises the player's critical damage | §2.1 |
| Spec 0017 (achievements) | Some achievements add to stats, for example +6% Block | §8.5 |
| Spec 0019 (fight log) | §8.1: where the swing lines show | §8.1 |
| Spec 0010 (professions) | Dust, rerolls and salvage, which §11 left out | §11 |

## 1. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | Weapons for each damage type | **A full set per tier** (owner's choice), copper included: each tier has a sword (slash), a spear (pierce) and a mace (crush) from that tier's materials. Crafting all three copper weapons on day 1 moves level 5 to day 2 in the sim. The owner accepts that (spec 0002's level 5 target becomes day 1-2) and may drop the copper spear and mace later. |
| 2 | Two-handers | **One per tier from bone on** (owner's choice), with a rotating type: Bone greataxe (slash), Iron pike (pierce), Troll-bone maul (crush), Mithril greatsword (slash), Drake-fang halberd (pierce). |
| 3 | Is the type rule written down? | **No** (owner's choice). Nothing in the game states which type beats which armour. The first fight shows a monster's armour. Its weakness shows after 10 kills or from a lore note. |
| 4 | Lore notes | **Notes about stronger foes** (owner's choice): each monster can drop one note about a tougher monster in or near its area (§7.2). About 1 in 100 kills. Each note drops once. |
| 5 | Repeated bonus stats | **Repeats stack and values roll** (owner's choice): each bonus stat is drawn on its own, so an item can have Crit three times, each with its own value. |
| 6 | Does the type rule have a neutral? | Yes. Each armour has one strong type (+30%), one weak type (−20%) and one neutral type (§3). Each damage type is strong once, neutral once and weak once. |
| 7 | Monster crits and blocks | Monsters do not crit or block. They can have Dodge (data). |
| 8 | Bare hands | No damage type: always neutral. |
| 9 | How does a two-hander hit harder? | With a bigger Attack number in data, and no extra rule. Tuned so that a two-hander kills about 25% faster than the one-hander of its tier (§4.2). |
| 10 | Unknown bestiary entries | Every monster in an area that is not fogged has a card. What the player has not learned yet shows "???". |
| 11 | A tap on a monster | Opens one sheet: its bestiary card on top, the fight choices (stop condition, Start, Queue) below. A fight starts with no extra tap. |

## 2. Hit, miss, crit and block

### 2.1 Every swing
Each swing (the player's or the monster's) goes through two rolls:

1. **Hit or miss**, the attacker's roll:
   `hit chance = 75% + 5% × (attacker level − defender level) + attacker Hit`, kept between 50% and 90%.
   - The base 75% and the top 90% come from spec 0002 amendment 3 change 6. Spec 0009 had 85% and 95%.
   - 5% per level comes from erratum 1. Spec 0009 said 3%, but the data (`hitPerLevel` 5) and the game always used 5%.
   - A miss deals nothing: "You miss", "<Monster> misses".
2. **Dodge**, the defender's own roll, only on a hit: with chance Dodge the defender slips the blow and takes
   nothing: "<Monster> dodges", "You dodge". Dodge is 0% unless gear, a talent, an achievement or the monster's data
   gives it.

So Hit only fights misses, and nothing lowers the defender's Dodge. A swing lands with
`hit chance × (1 − Dodge)`.

- **Crit:** a hit by the player is critical with chance Crit and deals **double** damage. The player has 5% Crit
  base. Monsters do not crit. With the talent Impale, the player's critical hit deals 2.5× (spec 0015 §2.3).
- **Block:** a monster's hit is blocked with chance Block and deals **30%** of its damage (rounded, at least 1).
  From gear, Block comes only from the off hand (a shield's base Block and its bonus stats). Achievements can add
  Block too (spec 0017).
- Damage before these is `max(1, attack − defense ÷ 2)` × the type factor (§3) × the ±20% roll.
- Caps (data): Crit 50%, Block 50%, Dodge 30%. The bounds of the hit chance hold Hit in.
- Crit, Hit and Dodge from talents count toward their caps (spec 0015 §2.3).
- Traits work as before:
  - quick still strikes first;
  - slow still swings every second round;
  - ghostly still ignores defence (but can be dodged and blocked);
  - regeneration still happens after the monster's turn, hit or miss.
- All the numbers above (the base, the step per level, the bounds, base Crit, crit size, block share, caps) live in
  `economy.json` (`combat`).

### 2.2 Stats
- The player's stats are HP, Attack, Defense, **Crit**, **Hit**, **Dodge** and **Block**.
- The level gives HP, Attack and Defense.
- The others come from gear, plus the 5% base Crit. Talents, meals and achievements can add to them too.
- The Character screen shows them all (§8.5).

## 3. Armour and damage types

| Monster armour | Strong (+30%) | Neutral | Weak (−20%) |
|---|---|---|---|
| Light | slash | pierce | crush |
| Medium | pierce | crush | slash |
| Heavy | crush | slash | pierce |

- The factors live in data.
- The player's damage type is the main-hand weapon's. Bare hands are neutral.
- Monsters' attacks have no type.

**Monster armour and Dodge** (data; lore first, then balance):

| Light | Medium | Heavy |
|---|---|---|
| Goblin, Goblin brute, Zombie, Wolf (Dodge 8%), Ghost (Dodge 5%), Troll, Harpy (Dodge 10%) | Old Bear, Bandit, Giant spider (Dodge 8%), Ogre Chieftain, Wraith, Wyvern (Dodge 5%) | Skeleton, Graveyard King, Stone golem, Fire drake, Young Dragon |

The tutorial stays readable: the copper sword is strong against the light goblins, and the copper mace is ready for
the first heavy monster (Skeleton, level 6).

## 4. Weapons

### 4.1 The weapon list
- Each weapon has a `damageType` in `items.json`.
- New recipes use the tier sword's materials and step cost. Two-handers cost more.

| Tier | Slash | Pierce | Crush | Two-hander |
|---|---|---|---|---|
| Copper (3) | Copper sword | **Copper spear**; Rusty dagger (drop) | **Copper mace** | — |
| Bone (6) | Bone sword | **Bone spear** | **Bone club** | **Bone greataxe** (8, slash: 10 bones, 3 copper ore) |
| Graveyard King | King's blade (unique) | | | |
| Iron (14) | Iron sword | **Iron spear** | **Iron mace** | **Iron pike** (16, pierce: 12 iron ore, 2 leather) |
| Troll (19) | | | | Troll-bone maul (crush; becomes two-handed) |
| Mithril (22) | Mithril sword | **Mithril spear** | **Mithril mace** | **Mithril greatsword** (24, slash: 12 mithril ore, 2 stone cores) |
| Drake-fang (28) | Drake-fang blade | **Drake-fang spear** | **Drake-fang hammer** | **Drake-fang halberd** (29, pierce: 6 drake fangs, 10 mithril ore) |

- Spec 0009 added 14 new weapons and recipes (bold).
- A spear or a mace has the same Attack as its tier's sword.
- Spec 0010 §4 later added logs to the spears, maces, two-handers and shields.

### 4.2 One hand and shield, or two hands
- Two-handers follow spec 0008 §2.1: the Off hand is greyed out, and to equip one moves the shield to the bag.
- Shields have a base **Block**: Bone shield 10%, Ectoplasm ward 5%, Iron shield 15%, Golem-core shield 20%.
- **Targets** (simulated, against the monsters of the stretch, with the strong type where the tier has it):
  - a two-hander wins in about 25% fewer rounds than the tier's one-hander (at least 15%);
  - the one-hander with a shield takes at least 20% less damage per fight.
- Since spec 0002 amendment 3 erratum 1, the player of these checks stands 5 levels above each monster of the
  stretch, where the one-hander wins.
- Starting Attack: greataxe 8, pike 14, maul 16, greatsword 23, halberd 27.

## 5. Bonus stats

### 5.1 Rolling
- When gear is crafted or dropped, after its quality roll, it rolls one bonus stat per quality step: Uncommon 1,
  Rare 2, Epic 3, Legendary 4. Common has none.
- All rolls use a seeded generator of the save, so results stay deterministic. Crafts, rerolls and finds of spec 0010
  use the profession stream (spec 0010 §9.1).
- Each roll picks one stat at random (equal chance) from the pool open at the item's **tier**, then a whole-number
  value in that stat's range. Repeats stack (decision 5).
- An item's tier comes from its item level (spec 0005 decision 2): tier 1 up to level 9, tier 2 for 10-19, tier 3
  from 20.

| Tier | Pool | Crit | Health | Hit | Dodge | Block (shields only) |
|---|---|---|---|---|---|---|
| 1 | Crit, Health | 1-2% | 4-8 | — | — | — |
| 2 | + Hit, Dodge, Block | 1-3% | 10-18 | 2-4% | 2-4% | 3-5% |
| 3 | same | 2-4% | 20-34 | 3-5% | 3-5% | 3-6% |

- Pools, ranges and tier bounds live in `economy.json`.
- Block is only in the pool for off-hand items.

### 5.2 What stays as it is
- Quality still raises the item's **base** HP, Attack and Defense by spec 0005 decision 7.
- It does not raise base Block or Dodge, or bonus stats.
- Boss uniques roll bonus stats like any drop.

### 5.3 Stacks and comparing
- Items stack only when item, quality **and bonus stats** match (overrides spec 0005 §5 and spec 0008 §2.2). Common
  gear still stacks freely.
- "Better" (bag order, best first in the slot sheet, Next goal, the simulated player) weighs every stat.
- Next goal compares a weapon only with weapons of the same damage type and hands, so it never tells a player to swap
  the mace that they chose for a sword.

### 5.4 Gear already owned
- On the first load of the new version, every owned item above Common (bag and worn) rolls its bonus stats once,
  with the item's quality and tier and the save's generator.
- Common gear does not change.

## 6. The player's armour types
- Every armour item has a type in data, shown on its item card ("Light armour · Chest").
- The type shapes the base stats only: light items carry a small base Dodge, and heavy items lean on Defense.
- It does not change how monster attacks land (the intent's one-way rule; the owner may revisit it after playtests).

| Light (base Dodge) | Medium | Heavy |
|---|---|---|
| Hide vest 2%, Stitched armour 2%, Wolf-pelt vest 3%, Bear-pelt cloak 2%, Silk boots 2%, Feather boots 3% | Studded leather, Troll-hide armour, Wyvern-scale armour | Iron helm, Mithril armour, Mithril helm, Dragon-scale armour, Dragon helm |

- Amulets, rings and trinkets have no armour type.
- Spec 0011 §7 adds hide pieces (light) and scale greaves (medium).

## 7. Learning foes

### 7.1 The bestiary
A card per monster, filled in by fights with it:

| Learned | Shows |
|---|---|
| Always | Name, level badge, area, flavour line, drops as on the map ("2 of 3 found") |
| First fight (won or lost) | Armour type |
| 10 kills | Weakness ("Weak to crush"), HP, Attack, Defense, Dodge and traits ("Quick: strikes first") |
| 50 kills | **Slayer** mark: +5% Hit against this monster |

- Kills count every kill so far: a save with 300 goblin kills opens with the goblin card full and Slayer earned.
- Old saves count a monster as fought once it has a kill.
- Drop chances are never shown.
- The card shows the kill count and the next goal on it ("7 more kills to learn its weakness").
- Slayer and the 10-kill reveal are news in the report, like a level-up: "Goblin: weakness learned",
  "Slayer: Goblin".

### 7.2 Lore notes
- Each note is about one monster and reveals its **armour and weakness** (not its stats).
- It drops from one monster at 1% per kill (data), and only until found.
- The starting list (dropped by → about):
  - Goblin → Goblin brute, Goblin brute → Old Bear, Skeleton → Zombie, Zombie → Graveyard King;
  - Graveyard King → Wolf, Wolf → Ghost, Ghost → Bandit, Bandit → Giant spider;
  - Giant spider → Troll, Troll → Ogre Chieftain, Ogre Chieftain → Stone golem, Stone golem → Harpy;
  - Harpy → Wraith, Wraith → Wyvern, Wyvern → Fire drake, Fire drake → Young Dragon.
- 16 notes. The texts (two or three lines, in the voice of whoever wrote them) live in data and can be rewritten
  freely.
- A found note is named in the report ("Found a lore note: The King's armour") and kept in the Lore tab.
- The teachers' tips of spec 0010 §6.2 reveal the same two facts through the same mechanism.

## 8. Screens

### 8.1 Fight log (Now)
- Each round's line names what happened: "You hit for 9", "Critical hit for 18", "You miss", "Skeleton dodges",
  "Skeleton hits you for 7", "You dodge", "You block: 2 damage", "Skeleton misses".
- The log length stays `fightLogRounds`.
- Overrides spec 0006 decision 8's wording.
- Spec 0019 changed where these lines show: the fight sheet holds the story of the fights. The words of the lines stay.

### 8.2 Item card and slot sheet
- The item card adds, under the base stats:
  - the weapon's damage type and hands ("Pierce · One hand"), or the armour type;
  - then the bonus stats, one line each ("+3% Crit", "+12 Health"). Repeated stats show as separate lines.
- The comparison against the worn item covers every stat.
- List rows (the bag grid, the Gear page, the bag rows of the slot sheet) show no bonus stats (intent 0008's clean
  UI).
- **The worn row of the slot sheet (am. 2)** shows:
  - its base stats on one line;
  - then each bonus stat on its own line ("+3% Crit"), in the quality colour of the item, as on the item card.
    Repeated bonus stats show as separate lines;
  - not the damage type, the hands or the armour type. The item card shows them.
- The bag rows of the slot sheet keep their change line and show no bonus stats **(am. 2 change 4)**.

### 8.3 Bestiary card
- A tap on a monster in Now's Here list, the World area sheet, or the Bestiary tab opens it.
- From Now and World, the fight choices sit under the card (decision 11).
- The card follows §7.1.

### 8.4 Journal tabs
The Journal (top bar) has three tabs:
- **Log:** the journal of spec 0004 §2.
- **Bestiary:** every monster with a card (decision 10), grouped by area in map order, each with its level badge, a
  "?" if its weakness is not known, and a Slayer mark.
- **Lore:** found notes, newest first, with "6 of 16 found".

### 8.5 Character
- The stats block shows Crit, Hit, Dodge and Block next to HP, Attack and Defense. Spec 0008 amendment 7 puts the
  seven in one row.

**Hit shows a chance (am. 4 rules 1-2)**
- **Hit** in the stats block shows the player's chance to hit a monster of the player's own level: the base chance
  plus the player's Hit, kept within the bounds of the hit chance (`economy.json`, `combat`).
- With the data of 2026-11-10, a player with no Hit sees "75%", and nobody sees more than "90%".
- The number does not count Slayer: that mark is for one monster.

**A tap on a stat opens its sheet (am. 4 rules 3-9)**
- A tap on HP, Attack, Defense, Crit, Hit, Dodge or Block opens a sheet. Level has no sheet.
- The sheet shows, from top to bottom:
  - the name of the stat as its title;
  - the number of the stats block, with its words;
  - one line on what the stat does;
  - where the number comes from, one line for each source;
  - the limit of the stat, when it has one.
- The number and what the stat does, with the numbers of 2026-11-10:

  | Stat | The number | What it does |
  |---|---|---|
  | HP | "218 HP" | "You lose a fight when your HP reaches 0. Each fight starts at full HP." |
  | Attack | "27 Attack" | "A hit deals about your Attack minus half of the monster's Defense." |
  | Defense | "18 Defense" | "A monster's hit loses half of your Defense." |
  | Crit | "7% chance of a critical hit" | "A critical hit deals 2 times the damage." |
  | Hit | "77% against a monster of your level" | "Each level a monster is above you takes 5% off. Each level below adds 5%." |
  | Dodge | "2% chance to dodge a hit" | "A dodged hit deals no damage." |
  | Block | "25% chance to block a hit" | "A blocked hit deals 30% of its damage." |

  The 2 times, the 5% and the 30% come from the data and the talents (Impale raises the first).
- The sources, in this order. A source that adds nothing has no line, but the first line of each stat always shows:

  | Source | Line | Stats |
  |---|---|---|
  | The level | "From your level: 150" | HP, Attack, Defense |
  | The base chance | "Base: 75%" | Crit, Hit |
  | Worn gear | "From gear: +40" or "From gear: +2%" | all |
  | Talents | "From talents: +12" or "From talents: +1%" | all but Block |
  | The meal | "From your meal: +9" or "From your meal: +3%" | HP, Attack, Defense, Crit |
  | Achievements | "From achievements: +5" | any that an earned achievement adds to |

- Dodge and Block have no base, so their first line is "From gear", shown even at "+0%".
- The limits, with the numbers of the data:
  - Crit: "At most 50%."
  - Hit: "Never under 50% or over 90%."
  - Dodge: "At most 30%."
  - Block: "At most 50%. Gear gives Block only on a shield." **(am. 4 erratum 1)**
  - HP, Attack and Defense show no limit.
- The lines of the sources add up to the number of the stats block, unless a limit cuts it.

**What stays (am. 4 rules 10-13)**
- The labels and the other numbers of the stats block stay. The meal line under a stat reads "+19 meal", without
  brackets (spec 0008 amendment 7).
- Item cards and talents still name the bonus: "+2% Hit", "+1 Hit".
- The hit chance in a fight still follows the level of the monster (§2.1).
- No rule, number or save field changes.

## 9. Balance

### 9.1 The reference player
- The "even-level player with the gear of that stretch" of spec 0002 (§3 XP rate, §5.2 fight lengths, §5.3 gear
  checks and amendment 1, criteria 4 and 6) wields the best crafted one-hander of the **strong** type for the
  monster, with a shield, where its tier has one.
- All its gear is Common (no bonus stats).
- This overrides criteria 4 and 6's reading of "best crafted gear".
- Since spec 0002 amendment 3, most of these checks are measured against the sim walker, not against this player
  (spec 0002 amendment 3, "The reference player's checks change"). The strong weapon type check stays on this player.

### 9.2 The simulated player
- It arms the weapon (and shield or two-hander) that wins fastest and safely before each fight, as a player who has
  learned the monster would.
- It crafts each weapon type once per tier, as it does other upgrades.
- Later specs add its habits: spec 0010 §9.2 (professions), spec 0002 amendment 3 changes 8-9 (the fight it picks).

### 9.3 Retuning
- Monsters kept their XP and got new HP (and Attack where a boss check needed it), so spec 0002's XP per step and
  fight lengths held for the reference player.
- Bonus stats were then sized so that the simulated walker kept the pacing targets.
- Spec 0002 amendment 3 later changed the monsters again (tougher, longer fights).

### 9.4 Prototype numbers
A throwaway sim in the scratchpad, 8 seeds, 5,000 steps a day, before plan 0011:

| Version | Level 30 on day |
|---|---|
| main of 2026-10-21 | 81-87 |
| misses only (85% at even level) | 85-94 |
| everything, monsters unchanged | 56-80 (too fast) |
| everything, monster HP refitted (mostly +5% to +35%), bonus stats at the §5.1 sizes | 77-90 |

The prototype rolled bonus stats as their average, so the build added the spread of real rolls. Plan 0011 tuned the
numbers.

### 9.5 The pace targets (am. 1, am. 3)
On seeds 1-8 at 5,000 steps a day (the pacing test):
- level 5 on day 1-2;
- level 10 on day 12-16. Spec 0010 amendment 1 widened it to day 11-16;
- level 30 on day 70-105 on every seed **(am. 3 change 1)**. The pacing test's walker runs 105 days
  **(am. 3 change 2)**;
- the median of the 8 seeds reaches level 30 on day 80-100 **(am. 1, am. 3 change 3)**.

Why the range is wide:
- With bonus stats, luck spreads the walkers: a walker who finds strong gear early fights higher monsters sooner. The
  owner prefers that luck pays off (concern 2). A lucky walker may reach level 30 up to 10 days sooner **(am. 1)**.
- Since the bag limit (spec 0021), the slowest seeds sat just under day 100. The owner widened each seed's range to
  day 105, and the median still catches a real slowdown **(am. 3)**.

## 10. Save
- A new save version. Items carry their bonus stats.
- The save keeps fought monsters (for armour), found lore notes and the Slayer marks. Kills are already counted.
- On load: the rolls of §5.4, and every monster with a kill counts as fought.
- Every fixture in `app/test/fixtures/saves/` loads.

## 11. Out of scope
- Weapon loadouts and automatic swaps between queued fights.
- Dust, rerolls and salvage (later spec 0010).
- The teachers' tips themselves (later spec 0010).
- Monster crits and blocks.
- Armour types that change how attacks land.
- New monsters or areas.
- Set items.
- Anything that shows drop chances.

## 12. Concerns
1. **Swaps of weapons by hand (medium).** Queued fights against different armour all use the weapon worn when they
   start. The simulated player swaps before each fight, which is a little kinder than a real player. Loadouts are the
   later fix. The sim's pace has margin to spare against the top of the range.
2. **Wider luck spread (medium).** Bonus stats that stack make lucky runs faster (the prototype's fastest seed was day
   77). That is the Diablo chase that the owner asked for, but it puts pressure on the "day 80" floor. Amendment 1
   answered it: each seed may reach level 30 from day 70.
3. **More recipes (low).** 14 new weapons make the Professions list longer. Spec 0010 amendment 12 later put the
   recipes that the player can make first.
4. **The hidden rule (low).** Players who never open the Bestiary may never learn the types. The loss hint (spec 0002
   §9.4) can point at it in plain words: "Its armour turns blades. Try something heavier."

## 13. Acceptance criteria
The base criteria keep their numbers. A criterion that checks several things has a letter for each check (rule 13
of `WRITING.md`). A note says where a later change moved a check.

**Hit, miss, crit and block**
1. Hit chance:
   - 1a. Hit chance follows §2.1 for every level difference from −10 to +12, with Hit, inside its bounds (a table
     test). The bounds are 50-90% since spec 0002 amendment 3.
   - 1b. Dodge never changes the hit chance.
2. Seeded swings:
   - 2a. Over many seeded swings at even level with no Hit or Dodge, the base chance ± 1 point hit (85% in spec 0009,
     75% since spec 0002 amendment 3).
   - 2b. Misses deal nothing.
   - 2c. With 10% Dodge, about 10% of the hits are dodged and deal nothing.
3. Crit and block (deterministic tests):
   - 3a. A crit deals double damage (without Impale).
   - 3b. A blocked hit deals 30% (at least 1).
   - 3c. Monsters never crit.
   - 3d. From gear, Block comes only from the off hand.
   - 3e. The caps hold.
4. Types:
   - 4a. The type factor follows the §3 table for all nine pairs.
   - 4b. Bare hands are neutral.

**Weapons**
5. The lists:
   - 5a. Every monster has an armour type, and every weapon a damage type.
   - 5b. The weapon list matches §4.1.
   - 5c. The Troll-bone maul and the four other two-handers are two-handed.
6. Each tier's two-hander and one-hander with shield meet the §4.2 targets in the tuning report.

**Bonus stats**
7. Rolls (seeded tests):
   - 7a. Common gear has no bonus stats.
   - 7b. Each quality step above Common adds exactly one.
   - 7c. Each roll comes from the pool of the item's tier, inside its range.
   - 7d. Block appears only on off-hand items.
   - 7e. Repeats can occur.
8. Bonus stats are deterministic: the same save and steps give the same items.
9. Stacks:
   - 9a. Items stack only with the same item, quality and bonus stats.
   - 9b. No equip, swap or unequip loses an item or changes its bonus stats.
10. An existing save loads:
    - 10a. with every item above Common holding its bonus stats;
    - 10b. with Common gear unchanged;
    - 10c. with every monster with kills counted as fought.

**Learning foes**
11. The bestiary card:
    - 11a. reveals armour after the first fight;
    - 11b. reveals weakness and stats at 10 kills;
    - 11c. gives Slayer (+5% Hit) at 50 kills;
    - 11d. never shows drop chances;
    - 11e. A save with old kills opens with those cards filled in.
12. A lore note:
    - 12a. drops only from its monster;
    - 12b. drops at most once;
    - 12c. reveals its subject's armour and weakness.

**Screens**
13. Lines and cards:
    - 13a. The fight log names hits, misses, dodges, crits and blocks as separate lines (§8.1).
    - 13b. The item card shows the damage or armour type, the hands and the bonus stats.
    - 13c. List rows show no bonus stats. (Amendment 2: the worn row of the slot sheet does.)
14. The Journal:
    - 14a. The Journal has Log, Bestiary and Lore tabs.
    - 14b. A tap on a monster in Now or World opens its card with the fight choices.

**Balance**
15. Spec 0002's targets with the §9.1 reference player: XP per step and step-up per monster (criterion 4), fight
    lengths (§5.2), and every boss's gear checks (criterion 6, amendment 1). Since spec 0002 amendment 3, most of
    these are measured against the sim walker instead (§9.1).
16. Replaced by amendment 1, then amendment 3 (§9.5).

**Check and release**
17. `.\scripts\check.ps1 -Release` is green, with no INTERNET permission.

**Amendment 1** has no criteria of its own. It rewrote criterion 16: "simulated 5,000 steps a day on seeds 1-8: level
5 on day 1-2, level 10 on day 12-16, level 30 on day 70-100 on every seed, and the median of the 8 seeds on day
80-100." Amendment 3 widened "every seed" to day 70-105.

**Amendment 2** (the worn row of the slot sheet shows its bonus stats)
- Slot sheet:
  1. The worn row shows the base stats of the worn item.
  2. The worn row shows each bonus stat of the worn item on its own line.
  3. A worn item with two equal bonus stats shows two lines.
  4. A worn Common item shows only its base stats line.
  5. Each bag row of the slot sheet shows its change line and no bonus stat lines.
- Check and release:
  6. Rules, numbers and the save do not change. The pacing test passes.
  7. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

**Amendment 3** (each seed reaches level 30 by day 105)
1. The pacing test checks each seed's level 30 on day 70-105, and the median on day 80-100.
2. `.\scripts\check.ps1 -Pacing` is green.

**Amendment 4** (Hit as a chance, and a tap on a stat explains it; with erratum 1)
- Hit shows a chance:
  1. With no Hit from gear or talents, the stats block shows the base hit chance of the data: "75%".
  2. With +4% Hit from gear, it shows "79%".
  3. With more Hit than the top allows, it shows the top of the data: "90%".
  4. Slayer against a monster does not change the number.
- The sheets:
  5. A tap on each of HP, Attack, Defense, Crit, Hit, Dodge and Block opens a sheet with that name as its title.
  6. A tap on Level opens nothing.
  7. Each sheet shows the number of the stats block with its words of rule 5.
  8. Each sheet shows its line of rule 5 on what the stat does, with the numbers of the data.
  9. The HP sheet of a player with gear, a talent and an HP meal shows the lines "From your level", "From gear",
     "From talents" and "From your meal", and their numbers add up to the HP of the stats block.
  10. A source that adds nothing has no line: with no meal, no sheet shows "From your meal".
  11. The Hit sheet with +4% Hit from gear shows "79% against a monster of your level", "Base: 75%" and "From gear:
      +4%".
  12. The Dodge and Block sheets of a player with neither show "From gear: +0%".
  13. The Crit, Hit, Dodge and Block sheets show their limits of rule 8 (with the Block line of erratum 1). The HP,
      Attack and Defense sheets show none.
  14. With Impale, the Crit sheet shows the player's own critical damage, not "2 times".
- What stays:
  15. An item card with Hit still reads "+4% Hit".
  16. The chance to hit in a fight does not change.
- Check and release:
  17. Rules, numbers and the save do not change. The pacing test passes.
  18. The stats block and two sheets (HP and Hit) are rendered at 408 dp wide before the PR (`CLAUDE.md`).
  19. `releases/next/` has a line for players.
  20. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

## Where each change went

| File | Its changes | Place in this edition |
|---|---|---|
| [Erratum 1](0009-fights-with-depth.erratum.md) | the hit chance moves 5% per level, not 3% | §2.1 |
| [Amendment 1](0009-fights-with-depth.amendment-1.md) | criterion 16: each seed on day 70-100, the median on day 80-100 | §9.5; §12 concern 2; criterion 16 |
| [Amendment 2](0009-fights-with-depth.amendment-2.md) | 1-3 the worn row shows its bonus stats; 4 the other rows stay | §8.2; §13 |
| [Amendment 3](0009-fights-with-depth.amendment-3.md) | 1 each seed on day 70-105; 2 the walker runs 105 days; 3 the median stays | §9.5; §13 |
| [Amendment 4](0009-fights-with-depth.amendment-4.md) | 1-2 Hit shows a chance; 3-9 the stat sheets; 10-13 what stays | §8.5; §13 |
| [Amendment 4, erratum 1](0009-fights-with-depth.amendment-4.erratum.md) | the Block limit line | §8.5; §13 |
