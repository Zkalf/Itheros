# Spec 0014 amendment 3: 72 dp pictures on the Achievements screen

Status: accepted
Amends: [spec 0014](0014-quiet-teal.md) §2.3 (sockets: "48 dp in rows")
Fixes: issue #88 (bigger pictures on the Achievements screen)
Product owner: Zkalf (asked for 72 dp on 2026-10-25; saw a test render of the screen)
Date: 2026-10-25

## Why
- The pictures on the Achievements screen are too small at 48 dp.
- 72 dp is the size of heads and portraits in §2.3.
- The achievement pictures are 256 × 256 px, so they stay sharp at 72 dp.

## Change
1. Each row of the Achievements screen starts with its picture in a **72 dp** socket, not 48 dp.
2. The socket stands at the start of the row, centred on the height of the row, as today.
3. The row keeps everything else:
   - the name, the "Feat" chip, the goal, the "Reward:" line and the bar with its numbers;
   - the "New" chip at the end;
   - the teal rim of an earned achievement;
   - the locked patch for a locked achievement and the PH mark rules of §3.2.
4. The rows are a little taller, so fewer rows fit on one screen. The owner accepts this.
5. Each other row of the game keeps its 48 dp socket.

## Acceptance criteria
**Achievement rows**
1. Each row of the Achievements screen starts with a 72 × 72 dp socket.
2. A locked achievement shows the locked patch in the socket. An earned achievement shows its image.
3. The socket is centred on the height of its row.
4. The name, the goal, the "Reward:" line, the bar and the "New" chip still show in the row.

**Other rows**
5. The monster rows and the spot rows on Now "Here" keep their 48 dp sockets.

**Check and release**
6. Rules, numbers and the save do not change. The pacing test passes.
7. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
