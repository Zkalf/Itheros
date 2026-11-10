# Spec 0010 amendment 12: recipe lists start with the highest level the player can make

Status: accepted
Amends: [spec 0010](0010-professions.md) §8.1 (the recipe lists of Crafting and Cooking, "in tier order")
Issue: #253
Product owner: Zkalf (chose on 2026-11-10: locked recipes go to the end; only the recipe lists change, not the lists
of gathering spots; accepted on 2026-11-10)
Date: 2026-11-10

## Why
- A recipe list starts with its lowest level. At Crafting 13 the first screen is grey level 1 copper gear.
- The recipes worth making are several screens down: more than twenty rows of four lines each.

## Change
1. **Open recipes first, highest level first.** A recipe list of Crafting or Cooking starts with the recipes whose
   profession level the player has. They stand by level, the highest first.
2. **Locked recipes at the end, nearest first.** The recipes that need a higher profession level follow. They stand
   by level, the lowest first, so the next one to open leads them.
3. Recipes of the same level keep the order that they have among each other today.
4. The order follows the profession level as it is when the screen draws. A recipe that opens with a new level moves
   to the top.

**What stays**
5. The rows, their words, pictures and badges stay. So do the three filters and "Nothing matches the filter"
   (amendment 3): a filter takes rows out and does not change the order of the rest.
6. The current craft still shows with every filter, at its place in the order.
7. The lists of gathering spots stay as they are.
8. No rule, number or save field changes. This does not move the pace, so it has no sim targets.

## Acceptance criteria
**The order**
1. With Crafting 13, the first row of Crafting's list is a recipe of the highest level up to 13 that the data has.
2. The open recipes stand by level from the highest to the lowest.
3. Each locked recipe stands under every open recipe.
4. The locked recipes stand by level from the lowest to the highest.
5. Recipes of the same level stand in the order of today's list.
6. Cooking's list follows criteria 1 to 5 with the Cooking level.
7. With profession level 1, the list is in the order of today: nothing is open above level 1.

**What stays**
8. With "Have level" on, the rows are the open recipes in the order of criterion 2. With "Up to 5 levels ahead" on,
   the locked rows shown follow them.
9. The list has the same recipes as before, each once.

**Check and release**
10. Rules, numbers and the save do not change. The pacing test passes.
11. Crafting's list is rendered at 408 dp wide before the PR (`CLAUDE.md`).
12. `releases/next/` has a line for players.
13. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
