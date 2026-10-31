# Spec 0010 amendment 8: the hunter and the fisherman tell what lives at each spot

Status: accepted
Amends: [spec 0010](0010-professions.md) §6.2 (tips) and [spec 0011](0011-lake-and-hunt.md) decision 7 and §2.2
(only the hunter tells tips)
Issue: #117
Product owner: Zkalf (chose on 2026-10-31: the teacher tells it; the tip names the usual catches and hints at the
rare one)
Date: 2026-10-31

## Why
- At Deer trail a hunt can give Venison or Boar meat. Rarely, the Golden stag gives a Golden antler. Nothing in the
  game says so.
- The owner wondered why Boar meat shows at Deer trail, and how to get a Golden antler at all.
- The other hunting spots and the four waters have the same gap.
- The chances stay as they are (owner, 2026-10-26: "no tuning").

## Change
1. **Spot tips:** a teacher tip can be about a spot instead of a monster. Sigrun tells one tip about each hunting
   spot. Wen tells one tip about each water.
2. **What a spot tip says:**
   - It names the common catch and the uncommon catch of the spot. It says the share of the uncommon one in words,
     for example "one in four".
   - Fishing spot tips also name the rare fish, without a share ("now and then a golden carp").
   - It hints at the spot's rare find as a rumour. It names the animal or fish, so the player knows that it exists.
   - It never states a chance as a number.
   - It never tells a rule that the game does not have.
3. **When a spot tip is told:** at the profession level of its spot, by the rules of spec 0010 §6.2. A tip waits for
   the next talk with the teacher, and the teacher's row shows a dot.
4. **The hidden cove:** Wen's tip about Cove rocks also waits until Smugglers' Cove is revealed (spec 0011 §6.1).
   Before that, the teacher sheet does not count it as the next tip.
5. **A spot tip reveals nothing about monsters.** It changes no chance, no number and no knowledge. Only monster tips
   reveal an armour and a weakness, as before.
6. **Where spot tips show:** where monster tips show today, in the teacher sheet and in the Lore tab under the
   teacher's name. Above the text, a monster tip says "About the Wolf". A spot tip says "About Deer trail".
7. **Spot tips do not count** in the Lore tab's "N of M found", like monster tips.
8. **What stays:**
   - Sigrun keeps her three monster tips.
   - Marta, the cook, tells no tips.
   - The spot card does not change.
   - The catches, their chances and the rare finds do not change.

### The tips

| Teacher | Level | Spot | Title | Text |
|---|---|---|---|---|
| Sigrun | Hunting 1 | Deer trail | The deer trail | "Red deer feed along the deer trail. One track in four is a wild boar's. And they say a golden stag walks there at dusk. Few hunters ever see it, fewer bring home its antler." |
| Sigrun | Hunting 10 | Moor tracks | Tracks on the moor | "Moor elk graze the Grey Moor, with black boar among them, one in four. The herders talk of Old Tusk, a boar as big as a cart. Nobody I know has brought back his tusk." |
| Sigrun | Hunting 20 | High crags | Up in the crags | "Ibex climb the crags above the pass, and snow grouse nest there, one in four. Watch the snow for a lynx's print. I've seen one, once. Its pelt is worth a season." |
| Wen | Fishing 1 | Lake shore | Mirror Lake | "Perch bite all day at Mirror Lake. One in five is a pike, and now and then a golden carp. Something old and green rolls out there at dawn. We call him Old Mossback." |
| Wen | Fishing 10 | Under the bridge | Under the bridge | "Brown trout hold under Troll Bridge, and eels, one in five. A silver salmon, if you're lucky. The trolls say a river king lives under the middle arch. Trolls lie, mostly." |
| Wen | Fishing 15 | Cove rocks | Smugglers' Cove | "So the chart was true. Sea bass off the rocks, mackerel one in five, a moonfish now and then. The old smugglers swore by a fish with one eye, big as a man. And by a chest they lost off the jetty." |
| Wen | Fishing 20 | Cold tarn | The cold tarn | "Arctic char in the cold tarn, and frostfin, one in five. Glacier pike, if you're patient. Something pale moves deep under the ice. I don't fish there alone." |

The texts live in `professions.json`, like the monster tips. The owner accepts them with this amendment.

### Data
- A tip in `professions.json` has either `enemy` (a monster tip) or `node` (a spot tip), never both.
- The data check fails when a tip has both fields or neither field.
- The data check fails when a spot tip names a spot of another profession.
- The data check fails when the level of a spot tip differs from its spot's level.

### Save
- The save does not change. Spot tips join the told tips (`tips`) by their ids.
- An old save loads as before. A player above a spot's level finds the tip waiting at the next talk with the
  teacher.

## Acceptance criteria
**Told at the right time**
1. A player who learns Hunting finds Sigrun's Deer trail tip told at once, with her level 1 monster tip.
2. A player at Hunting 9 has no Moor tracks tip waiting.
3. A player at Hunting 10 has the Moor tracks tip waiting, and Sigrun's row shows a dot.
4. A player who learns Fishing finds Wen's Mirror Lake tip told at once.
5. A player at Fishing 15 without Smugglers' Cove revealed has no Cove rocks tip waiting.
6. A player at Fishing 15 with Smugglers' Cove revealed has the Cove rocks tip waiting.
7. At Fishing 10 without the cove revealed, Wen's sheet names Fishing 20 as the next tip, not Fishing 15.
8. An old save of a player at Hunting 12 loads with the Moor tracks tip waiting.

**What a spot tip does**
9. A spot tip reveals no monster's armour or weakness.
10. Each spot tip text names the common catch and the uncommon catch of its spot.
11. Each spot tip text names the rare animal or the rare fish of its spot.

**Screens**
12. A spot tip shows "About Deer trail" (its spot's name) above its text, in the teacher sheet.
13. A spot tip shows under its teacher's name in the Lore tab.
14. The Lore tab's "N of M found" does not count spot tips.

**Data**
15. The data check fails on a tip with both `enemy` and `node`.
16. The data check fails on a tip with neither `enemy` nor `node`.
17. The data check fails on a spot tip whose spot belongs to another profession.
18. The data check fails on a spot tip whose level differs from its spot's level.

**Check and release**
19. Catch chances, rare finds and the save shape do not change. The pacing test passes.
20. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
