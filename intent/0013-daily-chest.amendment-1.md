# Intent 0013 amendment 1: a goal of steps spent on actions

Status: accepted
Amends: [intent 0013](0013-daily-chest.md) outcome 1 (the daily goal), outcome 2 (the quality of chest gear),
outcome 3 (open the chest) and the constraint "Only real walked steps count toward the goal"
Issue: #57
Product owner: Zkalf (chose on 2026-11-01: all steps that go into actions count, walks count, no cap on unopened
chests and an "Open all" button, chest gear rolls higher qualities with a low chance)
Date: 2026-11-01

## Why
- Intent 0013 gives the chest for 5,000 walked steps in one day.
- Those steps count even when nothing runs and every step goes into the step bank.
- The owner wants the chest to reward play: the player must use the steps in the game to earn it.
- Gear from the chest rolls quality like a monster drop. The owner wants the chest to be a better chance at high
  quality, as in Diablo 2: a chase with low odds.

## Change

### The goal (outcome 1)
1. **Steps spent on actions:** the goal counts the steps that go into actions on each local day.
2. The steps that go into an action are:
   - the walked steps that pay the action
   - the boost steps that the step bank adds to them
3. Every kind of action counts:
   - fights
   - gathering spots
   - crafts
   - rerolls
   - walks between places
4. **Steps that go into the step bank do not count.** For example, the steps that the player walks while the character
   rests do not count.
5. The goal stays at 5,000 steps a day. One chest per day at most, as before.

### The quality of chest gear (outcome 2)
6. **A better quality roll:** gear from the chest rolls rare, epic and legendary more often than a monster drop
   does.
7. The high qualities stay rare. The spec sets the chances. A start: rare, epic and legendary get twice the chance
   of a monster drop. Uncommon keeps its chance, and common takes what is left.

   | Quality | Monster drop today | Chest gear (start) |
   |---|---|---|
   | Common | 70% | 60% |
   | Uncommon | 20% | 20% |
   | Rare | 7% | 14% |
   | Epic | 2.5% | 5% |
   | Legendary | 0.5% | 1% |

8. Gear still comes from about 1 chest in 5. With the start chances, about 1 chest in 500 gives a legendary piece.

### Which gear the chest gives (outcome 2)
Outcome 2 says "a piece of gear at the player's level". Each piece of gear has an item level: its recipe's level, or
the level of the lowest monster that drops it (spec 0005 decision 2). The game does not stop a level 1 player from
wearing level 30 gear. So the chest needs a rule:

9. **A window below the player's level:** the chest picks gear with an item level from the player's level minus 4
   up to the player's level. The level is the player's level at the moment the player earns the chest (point 18).
10. **Never above:** the chest never gives gear with an item level above the player's level.
11. The chest picks evenly among the gear in the window.
12. Examples:

    | Player level | Window | Gear in it today |
    |---|---|---|
    | 1 | 1 | Rusty dagger |
    | 6 | 2-6 | copper, bone and deer hide gear, Hide vest, Lake scale greaves, Garnet ring, Oak charm |
    | 16 | 12-16 | iron and elk hide gear, Ectoplasm ward, Studded leather, River scale greaves, Bear pelt cloak, Sapphire ring, Ash totem |
    | 30 | 26-30 | drake fang, dragon and ibex hide gear, Golem core shield, Tarn scale greaves, Wyvern scale armour, Lynx mantle, Fire ward amulet |

13. **Chase items stay out:** the chest never gives these:
    - gear made from shards: King's blade, Chieftain's amulet, Dragon's heart
    - gear made from a rare trophy: Golden antler mantle
14. The spec lists the gear that stays out. New content follows the same rule.

### What stays in outcome 2
15. The common roll in each chest and the shard in about 1 chest in 50 do not change.

### Unopened chests (outcome 3)
16. **No cap:** every chest that the player earns waits until the player opens it.
17. **The contents are fixed when the player earns the chest:** the game rolls them at that moment. Opening only
    shows them.
18. So the player gains nothing when they keep a chest for later:
    - The gear window uses the player's level at the moment the player reaches the goal.
    - The quality roll uses the same level.
    - A level up after that does not change the chest.
19. With days away (outcome 4), each chest uses the player's level at the moment the steps of its day reach the
    goal.
20. **Open all:** with more than one chest waiting, the card on Now offers a button that opens all of them.
21. A tap still opens one chest, as before.

### Real steps (constraint)
22. The constraint "Only real walked steps count toward the goal" becomes: only real steps count toward the goal.
    - Walked steps and the boost steps of the bank count.
    - The steps of a test walk do not count.
23. Days still count per local day (spec 0001 amendment 1).

### What stays
24. Outcome 4 (days away still count) and the other constraints do not change.

## Balance cost
- A player with steps in the bank reaches the goal sooner. A full bank can halve the walked steps that the goal needs.
- Chest gear is better on average than a monster drop. One chest a day keeps the effect small next to the drops of
  a day of fights.
- The chest gives loot, not steps or XP. The sim with the pacing test checks its chances, as intent 0013 says.

## What it means for the specs
- Spec 0013 does not exist yet. It follows intent 0013 with this amendment.
