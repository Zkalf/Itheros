# Spec 0002 amendment 2: "Low XP" on grey monsters

Status: accepted
Amends: [spec 0002](0002-levels-that-matter.md) §9.2 (colours in the fight list)
Product owner: Zkalf (2026-11-01: "I like that grey gives 5% :) however I feel a warning that it is low xp might be
worth while? Just like the risky fights." Then, of a label or a popup: "Go with A, the Low XP label")
Date: 2026-11-01

## Why
- A grey monster gives 5% of its XP, at least 1 (the level bands of `economy.json`). The row shows the number ("1
  XP"), but nothing says why it is so low.
- An orange monster says "Risky" on its row. A grey monster has no word of its own.

## Change
1. **"Low XP":** the row of a grey monster starts its line of stats with "Low XP · ", as an orange row starts with
   "Risky · ". Example: "Low XP · HP 19 · Atk 4 · Def 1 · 1 XP".
2. **The colour:** only the words "Low XP" are in the grey of the level badge (`#9E9E9E`, a band colour of spec 0014
   §2.1). The rest of the line keeps its colour.
3. **No popup:** a grey fight starts as before, with no question. No setting is needed.
4. **What stays:** the 5% and the at-least-1 XP; "Risky" on orange rows; the "Deadly" question on red and skull
   fights; green monsters show no word.

## Acceptance criteria
**Fight rows**
13. The row of a grey monster starts its stats with "Low XP".
14. Only the words "Low XP" are `#9E9E9E`.
15. The row of a green, yellow or orange monster does not say "Low XP".
16. Starting a fight against a grey monster asks no question.

**Check and release**
17. Rules, numbers and the save do not change. The pacing test passes.
18. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
