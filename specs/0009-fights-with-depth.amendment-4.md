# Spec 0009 amendment 4: Hit as a chance, and a tap on a stat explains it

Status: accepted
Amends: [spec 0009](0009-fights-with-depth.md) §5 (the stats block shows Crit, Hit, Dodge and Block)
Issue: #252
Product owner: Zkalf (chose on 2026-11-10: Hit shows the chance against a monster of the player's level; a tap on
each stat shows what it does and where its number comes from; accepted on 2026-11-10)
Date: 2026-11-10

## Why
- The stats block on Character shows Hit as the bonus from gear and talents alone, for example "2%". Crit, Dodge and
  Block beside it show the whole chance. So "2% Hit" reads as "I almost never hit".
- Hits matter more since the tougher fights (spec 0002 amendment 3): the base chance is 75%.
- No screen says what a stat does, or how much of it comes from the level, the gear, the talents and the meal. The
  bonus shows only item by item on the cards.

## Change
**Hit shows a chance**
1. **Hit** in the stats block shows the player's chance to hit a monster of the player's own level: the base chance
   plus the player's Hit, kept within the bounds of the hit chance (`economy.json`, `combat`). With the numbers of
   today a player with no Hit sees "75%", and nobody sees more than "90%".
2. The number does not count Slayer: that mark is for one monster.

**A tap on a stat opens its sheet**
3. A tap on HP, Attack, Defense, Crit, Hit, Dodge or Block opens a sheet. Level has no sheet.
4. The sheet shows, from top to bottom:
   - the name of the stat as its title;
   - the number of the stats block, with its words (rule 5);
   - one line on what the stat does (rule 5);
   - where the number comes from, one line for each source (rules 6 and 7);
   - the limit of the stat, when it has one (rule 8).
5. The number and what the stat does, with the numbers of today:

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
6. The sources, in this order. A source that adds nothing has no line, but the first line of each stat always shows:

   | Source | Line | Stats |
   |---|---|---|
   | The level | "From your level: 150" | HP, Attack, Defense |
   | The base chance | "Base: 75%" | Crit, Hit |
   | Worn gear | "From gear: +40" or "From gear: +2%" | all |
   | Talents | "From talents: +12" or "From talents: +1%" | all but Block |
   | The meal | "From your meal: +9" or "From your meal: +3%" | HP, Attack, Defense, Crit |
   | Achievements | "From achievements: +5" | any that an earned achievement adds to |

7. Dodge and Block have no base, so their first line is "From gear", shown even at "+0%".
8. The limits, with the numbers of the data:
   - Crit: "At most 50%."
   - Hit: "Never under 50% or over 90%."
   - Dodge: "At most 30%."
   - Block: "At most 50%. Only a shield gives Block."
   - HP, Attack and Defense show no limit.
9. The lines of the sources add up to the number of the stats block, unless a limit cuts it.

**What stays**
10. The labels and the other numbers of the stats block stay, with the "(+N meal)" line under a stat.
11. Item cards and talents still name the bonus: "+2% Hit", "+1 Hit".
12. The hit chance in a fight still follows the level of the monster (spec 0009 §2.1).
13. No rule, number or save field changes. This does not move the pace, so it has no sim targets.

## Acceptance criteria
**Hit shows a chance**
1. With no Hit from gear or talents, the stats block shows the base hit chance of the data: "75%".
2. With +4% Hit from gear, it shows "79%".
3. With more Hit than the top allows, it shows the top of the data: "90%".
4. Slayer against a monster does not change the number.

**The sheets**
5. A tap on each of HP, Attack, Defense, Crit, Hit, Dodge and Block opens a sheet with that name as its title.
6. A tap on Level opens nothing.
7. Each sheet shows the number of the stats block with its words of rule 5.
8. Each sheet shows its line of rule 5 on what the stat does, with the numbers of the data.
9. The HP sheet of a player with gear, a talent and an HP meal shows the lines "From your level", "From gear", "From
   talents" and "From your meal", and their numbers add up to the HP of the stats block.
10. A source that adds nothing has no line: with no meal, no sheet shows "From your meal".
11. The Hit sheet with +4% Hit from gear shows "79% against a monster of your level", "Base: 75%" and "From gear:
    +4%".
12. The Dodge and Block sheets of a player with neither show "From gear: +0%".
13. The Crit, Hit, Dodge and Block sheets show their limits of rule 8. The HP, Attack and Defense sheets show none.
14. With Impale, the Crit sheet shows the player's own critical damage, not "2 times".

**What stays**
15. An item card with Hit still reads "+4% Hit".
16. The chance to hit in a fight does not change.

**Check and release**
17. Rules, numbers and the save do not change. The pacing test passes.
18. The stats block and two sheets (HP and Hit) are rendered at 408 dp wide before the PR (`CLAUDE.md`).
19. `releases/next/` has a line for players.
20. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
