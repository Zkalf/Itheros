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
| 1 | Which items have a quality? | Gear (items with a slot). Materials don't. |
| 2 | Item level for the over-level nudge | A recipe's unlock level; a drop's monster level. |
| 3 | How is the quality shown in text? | The quality in brackets after the name for anything better than common: "Bone sword (Rare)" (owner's choice). On the Character tab the name is also drawn in the quality colour. Common items keep their plain name. |
| 4 | Stop conditions | "Until I have N" counts every quality of an item. "Until N crafted" counts every craft. |
| 5 | "Next goal" and the simulated player | Compare gear by its stats including quality, so a rare Bone sword beats a common one. "Next goal" asks to craft an item only while none of it is owned, as today; it never asks to re-roll. |
| 6 | Boss uniques after the first kill | Each later kill drops the unique with `repeatChance` (data, per item: 0.05). The first kill still drops it for sure. Both roll a quality. |
| 7 | Rounding | Each stat the item has becomes `max(round(stat × (1 + bonus)), stat + tier)`, where tier is 1 (uncommon) to 4 (legendary). Stats the item lacks stay 0. |

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

## 4. Stats
Example, Bone sword (+5 Attack): uncommon +6, rare +7, epic +9, legendary +10. Hide vest (+2 Defense, +10 HP):
uncommon +3 / +12, rare +4 / +14, epic +5 / +17, legendary +6 / +20.

## 5. Inventory and equipment
- Each (item, quality) pair is its own stack and its own row. Rows keep the data order of items, then quality order.
- Equipping takes one item of that quality; the equipped one goes back to its own stack.
- Items in existing saves are common. Nothing is lost.

## 6. Report and journal
Crafted and dropped gear is named with its quality: "Crafted the Bone sword: +50 XP, Bone sword ×2, Bone sword
(Rare) ×1." Achievement counters (`crafted.<item>`, `kills.<monster>`) count every quality.

## 7. Out of scope
Salvaging or selling spare gear, quality on materials, sets, affixes, changing a quality after it is made.

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
9. Reports and the Character tab show the quality ("Bone sword (Rare)", and colour on the Character tab).
10. Spec 0002's pacing tests stay green with qualities on.
11. `.\scripts\check.ps1 -Release` is green, with no INTERNET permission.
