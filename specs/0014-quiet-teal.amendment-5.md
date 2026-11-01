# Spec 0014 amendment 5: swipe right to go back

Status: accepted
Amends: [spec 0014](0014-quiet-teal.md) §4 (screens): how a pushed screen goes back
Product owner: Zkalf (2026-11-01: "After choosing a profession it swipes like you descriped iphones do (which is nice)
and I can't help feel that a finger swipe should function as back as an alternative to pressing the back button."
To a swipe anywhere: "as long as it feels natural i.e. if I want to tap a recipe I don't want it to swipe intead")
Date: 2026-11-01

## Why
- A screen that slides in (a profession's screen, the Journal, Settings, Achievements) goes back with its Back button
  or the phone's back button.
- A swipe also goes back today, but only from a strip 20 dp wide at the left edge, as on iOS. A swipe in the middle
  of the screen does nothing, so the owner did not find it.

## Change
1. **Swipe right anywhere:** on a screen that slid in, a swipe to the right that starts anywhere on the screen goes
   back. The screen follows the finger, as the edge swipe does today.
2. **Let go halfway:** a swipe that ends before the middle of the screen, and slowly, slides the screen back in. A
   quick swipe goes back from any distance. These are the rules of the edge swipe of today.
3. **Taps stay taps:** a tap, or a touch that moves less than the touch slop of the phone (about 18 dp), never starts a
   swipe. A tap on a recipe, a button or a row works as before.
4. **Scrolls stay scrolls:** a touch that moves more up or down than to the side scrolls the screen, as before.
5. **A swipe to the left** does nothing.
6. **Where it does not apply:** the tabs of the bottom bar (they did not slide in), sheets and dialogs. A screen
   with a part that scrolls or drags to the side keeps only the edge swipe, if Claude finds one.
7. **What stays:** the slide-in of #141, the Back button, the phone's back button, and the edge swipe.

## Acceptance criteria
**Swipe back**
29. A swipe to the right from the middle of a profession's screen goes back to Professions.
30. A tap on a recipe row of a profession's screen opens the recipe, and does not go back.
31. A short slow swipe to the right, less than a third of the screen, leaves the profession's screen open.
32. A vertical scroll on a profession's screen scrolls it, and does not go back.
33. A swipe to the left on a profession's screen does not go back.
34. A swipe to the right on the Now tab changes nothing.

**Check and release**
35. Rules, numbers and the save do not change. The pacing test passes.
36. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
