# Spec 0020 amendment 6: Camp's services first on Now, and the Bank row without a button

Status: accepted
Amends: [spec 0020](0020-item-bank.md) §3.1 rule 11 (the Bank card on Now);
[amendment 5](0020-item-bank.amendment-5.md) rule 12 and criterion 17 (the Bank row keeps "Open bank")
Issue: #250
Product owner: Zkalf (chose on 2026-11-10: services first, all rows stay; the Bank row loses the look of its "Open
bank" button, and a tap on the row still opens the bank; accepted on 2026-11-10)
Date: 2026-11-10

## Why
- At Camp, the "Here" list on Now shows six teachers and the trainer before the Forge, the Bank and the Camp fire.
  The player uses those three on each visit and a teacher only now and then, so they are more than a screen down.
- The Bank row is the only row of "Here" with a button. The Forge and the Camp fire open with a tap on the row.

## Change
**The order of "Here"**
1. After the monsters and the gathering spots, the rows of "Here" stand in this order:
   - **Bank**
   - **Forge**
   - **Camp fire**
   - the teachers, in their order of today
   - the Guild trainer
2. A place shows only the rows that it has, as today.

**The Bank row**
3. The Bank row shows no "Open bank" button. It keeps its icon, its name "Bank" and its line "Store items and take
   them back".
4. A tap on the row opens the bank screen, as a tap on the Forge row opens Crafting.

**What stays**
5. Every row of "Here" stays, with its words, its picture and its dot.
6. The Bank button in the top bar and the Bank button under the bag stay (amendment 5).
7. No rule, number or save field changes. This does not move the pace, so it has no sim targets.

## Acceptance criteria
**The order of "Here"**
1. At Camp, the rows stand from top to bottom: Bank, Forge, Camp fire, the six teachers, the trainer.
2. The six teachers keep their order of today among themselves.
3. At 408 dp wide, on a phone 884 dp high, Bank, Forge and Camp fire are in view when the player scrolls "Here" to
   the top of the screen.

**The Bank row**
4. The Bank row shows no button and no text "Open bank".
5. The Bank row shows "Bank" and "Store items and take them back".
6. A tap on the Bank row opens the bank screen.
7. Away from Camp, Now shows no Bank row.

**Check and release**
8. Rules, numbers and the save do not change. The pacing test passes.
9. Now at Camp is rendered at 408 dp wide before the PR (`CLAUDE.md`).
10. `releases/next/` has a line for players.
11. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
