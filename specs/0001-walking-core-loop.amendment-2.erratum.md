# Erratum to spec 0001 amendment 2

Status: accepted
Corrects: [specs/0001-walking-core-loop.amendment-2.md](0001-walking-core-loop.amendment-2.md), the example under
"Why this can't be exploited" and acceptance criterion 2
Date: 2026-10-19

The rule is unchanged. The example was wrong: it used a fight, but combat rounds cost 10 steps, so 9 walked steps
with the boost (18 progress) complete one round. That round was fought and paid for; only the 8 unspent steps are
refunded (bank 91 + 8 = 99).

Corrected example and criterion 2: bank 100, **travel**, walk 9 steps (progress 18, bank 91), stop or switch:
bank 109, the same as walking 9 steps while resting. Found by the criterion's test during implementation.
