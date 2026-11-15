# Spec 0005: Item qualities

Status: accepted
Intent: [intent/0005-item-qualities.md](../intent/0005-item-qualities.md) (accepted, commit f86dd0a)
Builds on: spec 0002 §4 (gear) and §5.3 (boss first kills), spec 0003 (stop conditions)
Product owner: Zkalf
Date: 2026-10-19

## 1. Decisions
The intent settled the feel. These are the details it left open, decided for the build.

| # | Question | Decision |
|---|---|---|
| 1 | Which items have a quality? | Gear (items with a slot). Materials don't. Since spec 0010 tools roll a quality too (spec 0010 §3.2); meals have none. |
| 2 | Item level for the over-level nudge | A recipe's unlock level; a drop's monster level. |
| 3 | How is the quality shown in text? | Gear the player owns always shows its quality in brackets after the name, common included: "Hide vest (Common)", "Bone sword (Rare)" (owner, 2026-10-19, after trying it on the phone). This holds in the inventory, the equipment, report and journal lines and "Next goal" equip lines. Gear better than common is also drawn in its quality colour on the Character tab and in report and journal lines (§6). Materials keep their plain name. Names that stand for a kind of item rather than one owned piece (recipes, activities, stop conditions, achievements) stay plain: "Crafting Hide vest". Since spec 0008 decision 10 the brackets show only where items are written as text; where an item is drawn as an object, its picture's ring (spec 0014 §2.3) and the colour of its name show the quality. | With only the better qualities in brackets, common gear looked unfinished, and it was hard to tell apart from materials, which have no quality. |
| 4 | Stop conditions | "Until I have N" counts every quality of an item. "Until N crafted" counts every craft. |
| 5 | "Next goal" and the simulated player | Compare gear by its stats including quality, so a rare Bone sword beats a common one. "Next goal" asks to craft an item only while none of it is owned, as before; it never asks to re-roll. |
| 6 | Boss uniques after the first kill | Each later kill drops the unique with `repeatChance` (data, per item: **0.01**; first 0.05). The first kill still drops it for sure. Both roll a quality. Since spec 0010 ten shards of a boss also make its unique at a forge. | At 5% the pacing simulator's average walker, which kills bosses about 200 times by day 90, collected several boss uniques with epic or legendary quality and reached level 30 on day 70-80, outside spec 0002's target (80-100). At 1% it reached level 30 on day 80-89, and a boss farmer still finds a repeat about once per 100 kills (owner chose this, 2026-10-19). |
| 7 | Rounding | Each stat the item has becomes `max(round(stat × (1 + bonus)), stat + tier)`, where tier is 1 (uncommon) to 4 (legendary). Stats the item lacks stay 0. Since spec 0009 §5.2 quality raises only the base HP, Attack and Defense, not Block, Dodge or bonus stats. |

## 2. Qualities (data)
In `economy.json`, in order:

| Quality | Colour | Bonus | Chance |
|---|---|---|---|
| common | white | 0 | 70% |
| uncommon | green | 0.20 | 20% |
| rare | blue | 0.40 | 7% |
| epic | purple | 0.70 | 2.5% |
| legendary | orange | 1.00 | 0.5% |

Over-level nudge: `qualityPerLevel` 0.02, `qualityMaxLevels` 10.

## 3. Rolling a quality
- When gear is crafted or dropped, one roll of the save's seeded generator picks its quality.
- With `L = min(qualityMaxLevels, max(0, player level − item level))`, every quality above common has its chance
  multiplied by `1 + qualityPerLevel × L`; common gets the rest. At 10 levels above, legendary is 0.6% and common
  64%.
- Results stay deterministic: the same save and steps always give the same qualities.
- Other specs change the roll:
  - spec 0009 §5.1: after its quality, gear rolls one bonus stat per quality step;
  - spec 0010: for a craft, `L` counts against the Crafting level, not the character level; a reroll at a forge rolls
    the quality again (spec 0010 §7.2);
  - spec 0013 §2.5: the gear of the supply chest has its own boost;
  - spec 0015 §2.2: talents on quality chances multiply the chances above common, like the over-level nudge.

## 4. Stats
Example, Bone sword (+5 Attack): uncommon +6, rare +7, epic +9, legendary +10. Hide vest (+2 Defense, +10 HP):
uncommon +3 / +12, rare +4 / +14, epic +5 / +17, legendary +6 / +20. Since spec 0009 the Hide vest also has 2 Dodge,
which quality does not raise.

## 5. Inventory and equipment
- Each (item, quality) pair is its own stack and its own row. Rows keep the data order of items, then quality order.
  Since spec 0009 §5.3 gear stacks only when item, quality and bonus stats match.
- Equipping takes one item of that quality; the equipped one goes back to its own stack.
- Items in existing saves are common. Nothing is lost.

## 6. Report and journal
- Crafted and dropped gear is named with its quality: "Crafted the Bone sword: +50 XP, Bone sword (Common) ×2, Bone
  sword (Rare) ×1." Achievement counters (`crafted.<item>`, `kills.<monster>`) count every quality.
- In the "While you were away" card and the journal, gear better than common is drawn in its quality colour where a
  line names it: "Hide vest (Rare)" in blue (owner, 2026-10-19, after playtesting). The rest of the line, common gear
  and materials stay in the normal text colour.

## 7. Out of scope
Quality on materials, sets, affixes, changing a quality after it is made. Since then spec 0009 added bonus stats,
and spec 0010 added salvage and the reroll, which changes a quality after it is made.

## 8. Acceptance criteria
1. Crafted and dropped gear always has one of the five qualities; materials never do.
2. Over many seeded rolls at even level, each quality comes up within ±1 percentage point of its chance (legendary
   within ±0.2).
3. At 10 levels above the item, legendary comes up about 0.6% and common about 64%; more levels above change
   nothing.
4. Stats follow §1 decision 7 (the §4 examples are tests).
5. Different qualities of one item are separate stacks; equipping and removing move one item between its stack and
   the slot without changing its quality.
6. A boss's unique item drops for sure on the first kill and with `repeatChance` on later kills, rolling a quality.
7. "Until I have N" counts every quality; "Next goal" and the simulated player rank gear by stats with quality.
8. An existing save loads with its items common and nothing lost.
9. Owned gear shows its quality in brackets in reports, the journal and the Character tab, common included, and
   better than common also in its colour; materials and recipe names stay plain. Since spec 0008 decision 10 the
   brackets show only in text.
10. Spec 0002's pacing tests stay green with qualities on.
11. `.\scripts\check.ps1 -Release` is green, with no INTERNET permission.
12. Report and journal lines draw gear names of uncommon or better in their quality colour, and nothing else.

## History
- 2026-10-19: first version (intent 0005, plan 0006). Criteria 1-11.
- 2026-10-19, amendment 1: boss uniques repeat at 1% (was 5%). Decision 6.
- 2026-10-19, amendment 2: owned gear always names its quality, common included. Decision 3; §6; criterion 9.
- 2026-10-19, amendment 3: quality colour in reports and the journal. §6; criterion 12.
- 2026-10-21, spec 0008: brackets only where items are written as text. Decision 3; criterion 9.
- 2026-10-21, spec 0009: bonus stats; quality raises only base HP, Attack and Defense; stacks match bonus stats too.
  Decision 7; §3; §4; §5; §7.
- 2026-10-21, spec 0010: tools roll a quality; crafts count the Crafting level; shards, salvage and the reroll.
  Decisions 1 and 6; §3; §7.
- 2026-10-22, spec 0014: a ring in the quality colour on gear and tools. Decision 3.
- 2026-10-31, spec 0015: talents on quality chances. §3.
- 2026-11-01, spec 0013: the supply chest's own quality boost. §3.
- 2026-11-15 (plan 0068): the amendments folded into this file. The report example of §6 now names common gear
  "(Common)", as amendment 2 asked. No rule, number or criterion changed. (draft)
