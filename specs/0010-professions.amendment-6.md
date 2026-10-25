# Spec 0010 amendment 6: the profession screen says its name once and hides filters until learned

Status: accepted
Amends: [spec 0010 amendment 4](0010-professions.amendment-4.md) change 2 (the contents of the card) and change 3
with criterion 3 (the recipe filters)
Issue: #62
Product owner: Zkalf (chose both fixes on 2026-10-25)
Date: 2026-10-25

## Why
- The profession screen shows the name of the profession twice: as the title in the top bar, and on the first line
  of its card.
- The screens of Crafting and Cooking show the three recipe filters also when the player has not learned the
  profession. The screen then holds only "Learn from <teacher> in camp", so the filters have nothing to filter.

## Change
1. **Name once:** the top bar keeps the name of the profession as its title (amendment 4 change 2). The first line
   of the card shows the icon of the profession and, when learned, "Level N". It no longer shows the name.
2. **Filters only when learned:** the three recipe filters show on the screens of Crafting and Cooking only when the
   player has learned that profession. This replaces "sit at the top of the screens that have recipes" in amendment 4
   change 3.
3. The rest of amendment 4 stays:
   - The filter choice is one view setting, shared by both screens, not saved.
   - The other four screens have no filters.
   - An unlearned screen names its teacher.

## Acceptance criteria
**Name**
1. A profession screen shows the name of the profession as the title of the top bar.
2. The card on a profession screen does not show the name of the profession.
3. The first line of the card shows the icon of the profession, and "Level N" when learned.

**Filters**
4. The screens of Crafting and Cooking show the three filter chips when the player has learned the profession.
5. The screens of Crafting and Cooking show no filter chip when the player has not learned the profession.
6. The other four screens show no filter chip.

**Check and release**
7. Rules, numbers and the save do not change. The pacing test passes.
8. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
