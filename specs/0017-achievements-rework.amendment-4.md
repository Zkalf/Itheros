# Spec 0017 amendment 4: no pinned days for seed 1

Status: accepted
Amends: [spec 0017](0017-achievements-rework.md) criterion 31 (with spec 0021 amendment 1 change 1)
Issue: #173
Product owner: Zkalf (accepted on 2026-11-02: "we need to loosen that")
Date: 2026-11-02

## Why
- Criterion 31 pins seed 1 at levels 10, 20 and 30 within 5% of fixed days. It held the pace still while the
  achievements were reworked.
- Since then it breaks on any small change. The bag limit moved level 30 from day 84 to day 91. That needed a spec
  amendment and two decisions from the owner, for a change that was not meant to move the pace.
- The wide ranges of the pacing test still catch a real break.

## Change
1. Criterion 31 and its test end. Spec 0021 amendment 1 change 1 (day 91) ends with it.
2. These checks of the pacing test stay:
   - Each seed reaches level 5 on day 1-2, level 10 on day 11-16 and level 30 on day 70-100.
   - The median seed reaches level 30 on day 80-100.
   - The meals, the professions, the fighter and the gatherer-crafter, as they are.

## Acceptance criteria
1. The pacing test has no test of criterion 31.
2. The other tests of the pacing test do not change.
3. `.\scripts\check.ps1 -Pacing` is green.
