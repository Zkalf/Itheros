# Pace reports

A bigger sim now and then (plan 0066, issue #185). Each report runs the mixed walker and the fighter at 5,000
steps a day on many seeds and shows the medians. The change column compares with the report below it. "⚠" marks
a day number that moved 5 days or more. The report never fails: the owner reads it and decides.

- Run it with `.\scripts\pace-report.ps1 [-Seeds 32]`. It takes the CPU for a few minutes, so not during a check.
- A missed seed counts as day 106 for the mixed walker and day 121 for the fighter, as in the pacing test.
- Meal gain: the median level 30 day without meals minus the one with meals, without the bonuses of feats.
- The fight numbers come from the mixed walker's fights. "Hard fights" take more than half its HP.
- Newest report first.

## 2026-11-11 · 8e37d3e · 32 seeds

| Measure | Value |
|---|---|
| Mixed L10 | 13.0 |
| Mixed L20 | 46.0 |
| Mixed L30 | 90.0 |
| Fighter L10 | 13.0 |
| Fighter L20 | 64.0 |
| Fighter L30 | 113.0 |
| Meal gain | 2.0 |
| Fight rounds | 7.0 |
| Fight HP taken | 16.9% |
| Hard fights | 6.1% |
| King rounds | 31.0 |
