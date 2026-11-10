# Spec 0010 amendment 13: XP numbers count in the level, and a locked row does not repeat its name

Status: accepted
Amends: [spec 0010](0010-professions.md) §8.1 (the XP line of a profession) and
[amendment 10](0010-professions.amendment-10.md) (the line of a locked spot or recipe)
Issue: #255
Product owner: Zkalf (chose on 2026-11-10: the numbers count in the level, for the professions and for the character's
bar on Now; a locked row reads "Needs Crafting 16 (you have 11)")
Date: 2026-11-10

## Why
- A profession's XP bar counts from the start of the level, and its numbers count from zero. Fishing showed
  "100 / 148 XP" over an empty bar. The character's bar on Now does the same.
- A locked recipe row says "Iron pike needs Crafting 16 (you have 11)" under the title "Iron pike".

## Change
**XP numbers**
1. The XP numbers of a profession count in the level, as its bar does: the XP earned since the level began, and the
   XP that the level takes. Fishing at 100 XP, where level 2 began at 100 and level 3 begins at 148, shows
   "0 / 48 XP". This goes for the profession's own screen and for the Professions tab.
2. The character's bar on Now reads the same way: "XP 0 / 48".
3. The bars do not change.

**Locked rows**
4. A recipe row or a spot row above the player's level reads "Needs Crafting 16 (you have 11)", without the name of
   the recipe or spot. The row has the name as its title.
5. The Journal and the away report keep the name where they say why an action was skipped: "Iron pike needs Crafting
   16 (you have 11)".
6. The lines "Learn Woodcutting from …" and "You need a hatchet" stay.

## Acceptance criteria
**XP numbers**
1. A profession with XP at the start of a level shows "0 / N XP", where N is the XP that the level takes, on its
   screen and on the Professions tab.
2. A profession part way through a level shows the XP earned in the level, and the bar's share equals the first
   number over the second.
3. The character's bar on Now shows "XP <in the level> / <the level takes>".

**Locked rows**
4. A recipe row above the player's Crafting level reads "Needs Crafting <level> (you have <N>)" and does not repeat
   the recipe's name in that line.
5. A spot row above the player's level reads "Needs <profession> <level> (you have <N>)".
6. The reason of a skipped locked action still names the recipe or spot.
7. A profession that is not learned still reads "Learn …".

**Check and release**
8. Rules, numbers and the save do not change. The pacing test passes.
9. `releases/next/` has a line for players.
10. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
