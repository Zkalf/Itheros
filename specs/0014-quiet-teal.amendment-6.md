# Spec 0014 amendment 6: fewer words on Now and World

Status: accepted
Amends: [spec 0014](0014-quiet-teal.md) §4.2 (Now and World, screen by screen)
Issue: #122 (only its line "Tap a place to see what lives there.")
Product owner: Zkalf (2026-11-01: "the text under step bank feels off. i dont want it to be there, maybe add a tap
to the step bank where the information can be." "Also in map remove "Tap a place..."" "Also the text at the bottom
"Step arrive from Health..." should be in the tap on the bank." Of the Now screen: "too much scrolling and too much
text". The rest of the look of Now waits for the owner and nabriis.)
Date: 2026-11-01

## Why
- Now has two lines that explain the game in place, under the step bank and at the bottom of the screen. They make
  Now longer, and a player reads them once.
- The World map has a hint under it, "Tap a place to see what lives there." Issue #122 removes it with a larger
  rework; the owner wants it gone now.

## Change
1. **The step bank opens a sheet:** a tap on the step bank row (its label and its bar) opens a sheet:
   - the title "Step bank"
   - "Steps walked while resting are saved here. During an activity, each step you walk uses one banked step and
     counts double."
   - "Steps arrive from Health Connect about once a minute. Pull down to check now."
2. **Under the step bank:** the line "Steps walked while resting are saved here. …" goes.
3. **At the bottom of Now:** the line "Steps arrive from Health Connect about once a minute. Pull down to check now."
   goes.
4. **Under the World map:** the line "Tap a place to see what lives there." goes, with its padding.
5. **What stays:** the step bank bar and its label, "Walked today", pull to refresh, and the rest of the World map.
   Issue #122 keeps the rest of its rework.

## Acceptance criteria
**Now**
37. Now does not show "Steps walked while resting are saved here."
38. Now does not show "Steps arrive from Health Connect about once a minute."
39. A tap on the step bank opens a sheet with the title "Step bank" and both lines.

**World**
40. The World tab does not show "Tap a place to see what lives there."

**Check and release**
41. Rules, numbers and the save do not change. The pacing test passes.
42. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
