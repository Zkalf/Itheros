# Spec 0010 amendment 9: salvage all

Status: accepted
Amends: [spec 0010](0010-professions.md) §7.1 (salvage) and §8.3 (the item card at a forge)
Issue: #175
Product owner: Zkalf (chose on 2026-11-03: both buttons, one for each quality on the Bag and one for each item on
the item card; every batch asks first, Common too)
Date: 2026-11-03

## Why
- In a playtest at the forge, the owner had 14 Common items in the bag.
- The owner salvaged them one at a time: 14 taps on an item, 14 taps on Salvage.

## Change
1. **Which items a batch takes:** the same items that a single salvage takes (§7.1):
   - gear and tools in the bag,
   - not worn,
   - not a starter tool (a teacher's gift).
   - Items in the bank stay where they are.
2. **Salvage all of one quality:** at a forge, the Bag shows one button for each quality that has items for a batch.
   - The button says "Salvage all Common (14)": the quality and the number of items.
   - One tap salvages every item of that quality that rule 1 allows.
   - A quality with no such item shows no button.
   - Away from a forge, the Bag shows no button and no hint. The item card keeps its hint "Salvage and reroll at a
     forge".
3. **Salvage all of one item:** at a forge, the item card shows "Salvage all (5)" next to Salvage when the bag holds
   2 or more of that item.
   - "The same item" is the same square in the Bag: the same item, quality and bonus stats.
   - One tap salvages all of them.
4. **Every batch asks first:** a dialog asks before a batch of any quality, Common too.
   - Title: "Salvage 14 Common items?" or "Salvage 5 Bone swords?".
   - Text: "They break down into dust for good."
   - Buttons: "Keep them" and "Salvage".
5. **A batch is single salvages in a row:** each item gives 1 dust of its quality and rolls once for a boss shard, as
   in §7.1.
   - The rolls take the bag's order (spec 0008 §3.5).
   - So 14 single salvages in that order and one batch give the same dust, the same shards and the same save.
6. **One message for the batch:** the message replaces the one on screen (#176).
   - It says the number of items and the dust: "Salvaged 14 items: 14 Common dust."
   - It names each shard found with the count that its recipe needs: "Found a shard of the Graveyard King (4 of
     10)!". Two shards of one boss: "Found 2 shards of the Graveyard King (5 of 10)!".
7. **What stays:**
   - The single Salvage button and its rule: Rare and better ask first, Common and Uncommon do not.
   - The dust, the shard chance and the shard of each tier.
   - A waiting reroll in the queue whose item a batch salvages: the queue skips it, as after a single salvage.
   - The save shape.

## Acceptance criteria
**Rules**
1. A batch of one quality salvages every bag item of that quality, and nothing else.
2. A batch leaves worn items as they are.
3. A batch leaves starter tools in the bag.
4. A batch leaves the bank as it is.
5. A batch of 3 Common items gives 3 Common dust.
6. A batch gives the same state as single salvages of the same items in the bag's order, from the same seed.
7. A batch away from a forge throws an error and changes nothing.

**Screens**
8. At a forge, the Bag shows "Salvage all Common (N)" when the bag holds N Common items for a batch.
9. At a forge, the Bag shows no button for a quality without items for a batch.
10. Away from a forge, the Bag shows no Salvage all button.
11. At a forge, the item card of a stack of 2 or more shows "Salvage all (N)".
12. At a forge, the item card of a single item shows no "Salvage all" button.
13. A Common batch asks first, and "Keep them" salvages nothing.
14. After "Salvage", the message says the number of items and the dust.
15. A batch that finds a shard names it in the message with its count.

**Check and release**
16. Dust, shard chances and the save shape do not change. The pacing test passes.
17. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
