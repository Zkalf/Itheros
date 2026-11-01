# Spec 0013, erratum 1: the chase list

Status: accepted
Corrects: [spec 0013](0013-daily-chest.md) §2.4 point 28 (the table of `supplyChest.exclude`);
[intent 0013 amendment 1](../intent/0013-daily-chest.amendment-1.md) points 12 and 13
Issue: #57
Product owner: Zkalf
Date: 2026-11-01

## What was wrong
- Point 28 keeps out "gear made from a rare trophy" and names only the Golden antler mantle.
- Two more pieces of gear are made from a rare trophy in the same way:
  - Tusk mantle: from Old Tusk's tusk, the rare find of Moor tracks
  - Lynx mantle: from a Snow lynx pelt
- The level 30 example of intent 0013 amendment 1 point 12 lists the Lynx mantle as chest gear. That breaks the rule of
  point 13 in the same amendment.
- Claude's mistake: the list missed them. The code review of PR #164 found it.

## Correction
1. The table of spec 0013 §2.4 point 28 reads:

   | Gear | Why it stays out |
   |---|---|
   | King's blade, Chieftain's amulet, Dragon's heart | made from 10 boss shards |
   | Golden antler mantle, Tusk mantle, Lynx mantle | made from a rare trophy (Golden antler, Old Tusk's tusk, Snow lynx pelt) |
   | Drowned Captain's ring | the prize of the sunken chest (spec 0011 §6.3) |

2. Intent 0013 amendment 1 point 13 holds the Tusk mantle and the Lynx mantle with the Golden antler mantle.
3. The level 30 row of intent 0013 amendment 1 point 12 does not hold the Lynx mantle.
4. The rule does not change. Gear made from a gem or heartwood stays in the chest, as the level 6 example shows
   (Garnet ring, Oak charm).
