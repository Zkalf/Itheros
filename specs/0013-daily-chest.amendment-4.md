# Spec 0013 amendment 4: test walks fill the chest, fresh steps on the chest screen, grey gear in the chest sheet

Status: accepted
Amends: [spec 0013](0013-daily-chest.md) criteria 6 and 7 (test walks), §3.2 (the supply chest screen), §3.3 (the
chest sheet)
Issue: #167, #168
Product owner: Zkalf (chose on 2026-11-01: gear that left the bag stays in the sheet, grey, with no tap; test walks
count toward the chest, so the owner can playtest it)
Date: 2026-11-01

## Why
- A test walk counts nothing toward the supply chest (criteria 6 and 7). The owner cannot playtest the chest without
  a real walk of the whole goal.
- The supply chest screen shows today's steps as of the last sync. Steps walked since then are missing until the
  next sync (#167).
- The chest sheet lists every piece of gear that came out of the chests. After the player wears or salvages one, its
  row still opens the item card. The card then refuses the action with a message (#168).

## Change
1. **Test walks:** the steps of a test walk count toward today's supply chest, as real steps on the current action
   do. They count for the local day of the test walk.
2. Only owner builds have the test walk (spec 0007 §4). Friends' builds do not change.
3. **Sync on open:** when the supply chest screen opens, the game syncs. The progress line and its bar then show the
   steps of that sync.
4. **Gear that left the bag:** in the chest sheet, a row of gear that is no longer in the bag turns grey. A tap on it
   does nothing.
5. The row stays in the sheet, with its count. The sheet still lists all that came out (criterion 50).
6. A row of gear that is still in the bag keeps the colour of its quality and opens its item card (criteria 50 and 52).
7. Rows of items that are not gear do not change.

## Acceptance criteria
**Test walks**
1. The steps of a test walk on an action count toward today's supply chest.
2. A test walk that reaches the goal earns today's chest.

**The supply chest screen**
3. Steps walked after the last sync show on the supply chest screen after it opens, with no other action.

**The chest sheet**
4. After the player wears a piece of gear from the sheet, its row stays in the sheet and turns grey.
5. After the player salvages a piece of gear from the sheet, its row stays in the sheet and turns grey.
6. A tap on a grey row opens nothing.
7. A row of gear that is still in the bag keeps its quality colour and opens its item card.

**Check and release**
8. The numbers and the save do not change. The pacing test passes.
9. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
