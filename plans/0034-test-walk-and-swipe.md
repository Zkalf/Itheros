# Plan 0034: Build "bigger test walks" and "swipe right to go back"

Status: draft
Specs: `specs/0004-journal-and-test-walks.amendment-4.md`, `specs/0014-quiet-teal.amendment-5.md` · Product owner:
Zkalf · Date: 2026-11-01

Names of files, widgets and tests refer to `main` at `79c5cc0`.

## What changes in the code
- `app/lib/ui/now_tab.dart`, `_TestWalkCard`: the buttons 100, 1,000, 5,000, 25,000 and 100,000. The card wraps
  onto a second line when they do not fit.
- `app/lib/ui/swipe_back.dart` (new): `SwipeBackPageTransitionsBuilder`. It draws the slide of
  `CupertinoPageTransitionsBuilder` and adds a full-screen horizontal drag:
  - a `HorizontalDragGestureRecognizer` in the gesture arena, so a tap or a vertical scroll of a child wins as
    before;
  - a drag to the right moves the route's animation, as Flutter's edge swipe does (same distance and speed rules);
  - a drag to the left, or a route that cannot pop, does nothing.
- `app/lib/ui/theme.dart`: `pageTransitionsTheme` uses the new builder on Android.
- Each pushed screen is checked for a part that drags to the side. One found keeps only the edge swipe.
- No change to game_core, the data, the save or the sim.
- `releases/next.md`: a line for players about the swipe. The test walk is not in the friends' build, so it has no
  line.

## Choices this plan makes
- **Flutter's own rules for the swipe:** the drag uses the controller of the route as Flutter's edge swipe does
  (`TransitionRoute.controller`). It is a protected member, so the code marks the one access. Thus the feel, the
  speed and the distance match the edge swipe of today.

## Order of work
### M1: both changes (one PR)
- First, the failing tests, committed alone:
  - `app/test/test_walk_test.dart` or the existing test walk tests: the five buttons (criterion 14), +100,000 during
    an action (15), one journal entry (16).
  - `app/test/swipe_back_test.dart`: criteria 29-34 of spec 0014 amendment 5, with a profession's screen.
- Then the code.
- **Proof:** `.\scripts\check.ps1 -Release` green. On the Fairphone: a swipe from the middle of a profession's screen
  goes back, and a tap on a recipe opens it.
- Branch `feat/test-walk-and-swipe`. PR with the amendments and this plan, review per `REVIEW.md`. The owner merges.
