# Spec 0014 amendment 1: pictures for gathering spots

Status: accepted
Amends: [spec 0014](0014-quiet-teal.md) §3.1 (what shows an image), §4.2 (Now, World) and §6 (out of scope)
Product owner: Zkalf (chose the scope on 2026-10-24)
Date: 2026-10-24

## Why
A monster row starts with the picture of the monster. A gathering spot row shows only a coloured level number.
Both rows stand in the same list on Now "Here" and on the area sheet of the World map. The owner wants the spot
rows to look like the monster rows. They use the placeholders that exist today. No new image is needed.

## Change
1. A gathering spot is a new thing of §3.1:

   | Thing | Key | Placeholder |
   |---|---|---|
   | Gathering spot | `spots/<spot id>` | the tool placeholder of its profession |

2. The placeholder of each spot:

   | Profession | Spots | Placeholder |
   |---|---|---|
   | Mining | Copper vein, Iron vein, Mithril vein | `tool_mining` |
   | Woodcutting | Oak tree, Ash tree, Pine tree | `tool_woodcutting` |
   | Fishing | Lake shore, Under the bridge, Cove rocks, Cold tarn | `tool_fishing` |
   | Hunting | Deer trail, Moor tracks, High crags | `tool_hunting` |

3. A spot row has the layout of a monster row (§2.3, §4.2):
   - The row starts with the picture of the spot in a 48 dp socket.
   - The level badge is on the name line, before the name.
   - The badge keeps its colour and its number.
4. This change applies to the spot rows on Now "Here" and on the area sheet of the World map.
5. Each other row stays as it is. This includes:
   - the profession buttons, the profession screens and their "Where to practise" row;
   - the recipes;
   - the teachers, the Forge row, the Camp fire row and the "Walk here" row;
   - the bestiary of the Journal.
6. Decision 7 stays: professions keep their icons.
7. §6 keeps "Images for professions, teachers and areas" out of scope. A gathering spot is not an area.
8. The placeholder check of §3.2 also lists each spot that shows a placeholder. The check never fails because of a
   placeholder.
9. A real image of a spot later comes as content: the file `app/assets/images/spots/<spot id>.webp`.

## Acceptance criteria
**Spot rows**
1. On Now "Here", each spot row starts with a 48 dp socket.
2. On the area sheet of the World map, each spot row starts with a 48 dp socket.
3. A spot without an image shows the tool placeholder of its profession, as the table of change 2 says.
4. A spot with an image file `spots/<spot id>` shows that image, without the PH mark.
5. The level badge of a spot is on the name line, before the name.
6. The level badge of a spot keeps the colour and the number that it shows today.

**Other rows**
7. The profession buttons and the profession screens keep their icons.
8. The teacher, Forge, Camp fire and "Walk here" rows keep their icons.

**Check and release**
9. The placeholder check lists each spot that shows a placeholder and passes.
10. Rules, numbers and the save do not change. The pacing test passes.
11. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
