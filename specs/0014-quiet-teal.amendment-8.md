# Spec 0014 amendment 8: pictures for the actions in the queue

Status: accepted
Amends: [spec 0014](0014-quiet-teal.md) §3.1 (the pictures of things) and §4.2 (Now); spec 0016 §7.1 (the queue card)
Issue: #86
Product owner: Zkalf (chose on 2026-11-06: a 48 dp picture starts each row of the queue card, with the number as a
badge on its corner; pictures go wherever one exists; accepted on 2026-11-06)
Date: 2026-11-06

## Why
- The queue card on Now is text only. The player reads each line to see what comes next.
- The monster rows, spot rows, Bestiary and bag show pictures (spec 0014, amendment 1, #196). The queue card is one of
  the last lists without them.
- The action sheet of a gather or a craft shows only a title. The sheet of a fight shows the monster's card with its
  picture.

## Change
**The picture of an action**
1. Each action has the picture of the thing that it is about:

   | Action | Picture |
   |---|---|
   | Fight | the monster |
   | Gather | the spot (amendment 1) |
   | Craft | the item that the recipe makes |
   | Reroll | the item that the player rerolls |
   | Walk | the marker of the place |

2. A thing without a picture file shows its placeholder, as everywhere (§3.2). No new picture is needed.
3. The item of a craft or a reroll shows the ring of its quality when it is gear or a tool, as in the bag.

**The queue card**
4. The row of the current action starts with its picture in a 48 dp socket, before the action's name.
5. Each row of a waiting action starts with its picture in a 48 dp socket. The picture takes the place of the number
   circle.
6. The number of each row (1 for the current action, then 2, 3, …) is a small round badge on the top-left corner of
   its picture.
7. When the queue has only one slot, the current action shows no number, as today.

**The action sheet**
8. The sheet of a gather or a craft starts with the picture in a 72 dp socket, beside the title.
9. The sheet of a fight keeps the monster's card, with its picture (spec 0009 decision 11).

**What stays**
10. The words, the stop lines, the bars, the tally, Stop, Remove and the tap that changes a stop condition stay as they
    are.
11. No rule, number or save field changes. This does not move the pace, so it has no sim targets.

## Acceptance criteria
**The queue card**
1. The current action's row starts with the picture of its thing in a 48 dp socket, for a fight, a gather, a craft
   and a walk.
2. Each waiting action's row starts with the picture of its thing in a 48 dp socket, for a fight, a gather, a craft, a
   reroll and a walk.
3. A craft of gear shows the ring of the quality of its item.
4. A reroll shows the ring of the quality of the item that the player rerolls.
5. Each waiting row shows its number as a badge on its picture: 2, 3, ….
6. With two or more slots, the current action shows the badge 1 on its picture.
7. With one slot, the current action shows no number.
8. No waiting row shows the old number circle beside its picture.
9. A tap on a waiting row still opens its change sheet, and Remove still removes it.

**The action sheet**
10. The sheet of a gather starts with the spot's picture in a 72 dp socket, beside the title.
11. The sheet of a craft starts with the picture of the item that it makes, in a 72 dp socket, beside the title.
12. The sheet of a fight still starts with the monster's card.

**Check and release**
13. Rules, numbers and the save do not change. The pacing test passes.
14. The queue card and the action sheet are rendered at 408 dp wide before the PR (`CLAUDE.md`).
15. `releases/next/` has a line for players.
16. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
