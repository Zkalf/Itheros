# Spec 0001 amendment 2: unspent activity steps return to the bank; a Stop button

Status: accepted
Amends: [specs/0001-walking-core-loop.md](0001-walking-core-loop.md) §2.2 (leftover progress is discarded) and
decision 1 (stopping an activity, deferred)
Product owner: Zkalf
Date: 2026-10-19

Found on the Fairphone during M6: switching from fighting goblins to travel and back reset the round counter, and
the steps already paid toward the unfinished round were lost. The product owner decided that switching must never
lose steps, and that a Stop button is needed.

## Replaces the §2.2 rule "leftover progress is discarded when the activity ends"
- **Whenever an activity ends, is stopped or is replaced by another**, its unspent progress (steps paid toward the
  unfinished unit, including bank boost steps) goes to the step bank.
- The bank cap still applies: a refund fills the bank up to the cap, like any banked step.
- In practice this matters when stopping or switching. When an activity ends by itself (arrival, defeat, out of
  materials) the leftover is at most 1 boost step.
- A fight in progress is abandoned: the next fight starts at full HP for both sides, as before.
- Materials are untouched; they are only consumed when a craft completes (unchanged).

## Resolves decision 1 "Stopping an activity"
- The current-activity card has a **Stop** button. Stopping ends the activity, refunds its unspent steps to the bank,
  and the character rests: further steps go to the bank until a new activity starts.
- Stopping and switching are free (no step cost) and, like every action, sync steps first.

## Why this can't be exploited
The refund is the walked steps plus the boost steps they used. The boost steps came from the bank, so the result is
the same as having walked those steps while resting. Example: bank 100, walk 9 steps in a fight (progress 18,
bank 91), switch or stop: bank 109. Walking 9 steps while resting also gives 109.

## Acceptance criteria added
1. Fighting with 7 steps toward the next round, bank 0, switching to travel: bank 7, travel progress 0.
2. Bank 100, fight, walk 9 steps, switch: bank 109, the same as walking 9 steps while resting.
3. Stopping refunds the same way and leaves the character resting; the next walked steps go to the bank.
4. The refund respects the cap: bank 5 below the cap with 18 unspent steps gives a full bank.
5. Switching away from crafting or stopping it keeps all materials and refunds the paid steps.
6. The Stop button is shown only while an activity is running.
