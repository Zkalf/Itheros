# Intent 0013 amendment 2: the supply chest gets its own screen

Status: accepted
Amends: [intent 0013](0013-daily-chest.md) outcome 3 (the chest shows on Now) and the constraint "one card on Now, no
new screen"; [amendment 1](0013-daily-chest.amendment-1.md) point 20 (the "Open all" button on the card on Now)
Issue: #57
Product owner: Zkalf (chose on 2026-11-01: the chest and its progress go on a screen of their own, opened from a
button left of Achievements)
Date: 2026-11-01

## Why
- Now holds the status, the queue and the place where the character stands.
- The owner wants the supply chest out of Now, on a screen of its own.

## Change
1. **A button in the top bar:** a supply chest button stands left of the Achievements button.
2. The button shows a dot when a chest waits.
3. **The supply chest screen:** the button opens it. The screen shows:
   - the progress of today toward the goal
   - the waiting chests, with "Open" and "Open all"
4. **Nothing on Now:** Now shows no chest card and no chest progress.
5. The constraint "Clean UI (intent 0008): one card on Now, no new screen" becomes: one screen for the chest, and
   nothing on Now.
6. The "While you were away" summary still says when the player earns a chest (outcome 3).
7. Everything else in intent 0013 and amendment 1 stays as it is.

## What it means for the specs
- Spec 0013 (draft) puts the chest on its own screen, §3.
