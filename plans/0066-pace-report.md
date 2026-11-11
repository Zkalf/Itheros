# Plan 0066: Build "a pace report now and then"

Status: draft
Spec: none: a tool, not a game rule (issue #185) · Product owner: Zkalf · Date: 2026-11-11

Names of files, widgets and tests refer to `main` at `7103056`.

## Why
- The pacing test in each pull request runs 8 seeds, with wide ranges on purpose. It catches a real break, not
  slow drift.
- Several small changes can each move the pace a little. A bigger run now and then shows the drift.
- The report never fails and never blocks a pull request. The owner reads it and decides.

## Choices of the owner (2026-11-11)
1. The report shows the mixed walker and the fighter. The gatherer is left out: no target guards it since spec
   0002 amendment 3, erratum 1.
2. Each report goes into a file in the repo: `docs/sim/pace-reports.md`, newest first.
3. The report marks each day number that moved 5 days or more since the last report.

## What the report shows
One table with three columns: the measure, the value of this run and the change since the last report.

| Measure | How it is measured |
|---|---|
| Mixed L10, L20, L30 | The median day of the mixed walker for level 10, 20 and 30. A seed that misses the 105 days counts as day 106. |
| Fighter L10, L20, L30 | The same for the fighter, in 120 days. A seed that misses counts as day 121. |
| Meal gain | The median level 30 day without meals minus the median with meals, without the bonuses of feats (as in spec 0011 target 5). |
| Fight rounds | The median rounds of a fight of the mixed walker. |
| Fight HP taken | The median share of its HP that a fight of the mixed walker takes. |
| Hard fights | The share of the mixed walker's fights that take more than half its HP. |
| King rounds | The median rounds of a fight with the Graveyard King. |

- The run uses 32 seeds (1–32) at 5,000 steps a day. `-Seeds` changes the number.
- The change column marks a day number that moved 5 days or more with "⚠". The fight numbers show their change
  without a mark: no rule for "big" exists for them yet.
- Each report has a heading with the date, the commit and the number of seeds.
- The first report has no change column: it is the baseline.

## What changes in the code
- `packages/game_core/tool/pace_report.dart` (new):
  - The runs: per seed the mixed walker, the mixed walker with and without meals (no feat bonuses), and the
    fighter. That is 128 runs for 32 seeds. Each run goes into its own isolate, as in `pacing_test.dart`.
  - Pure functions: the medians, the table as markdown, the read of the values from the newest report in the file,
    and the change with its mark.
  - It prints the table and puts it at the top of `docs/sim/pace-reports.md`, under the file's short intro.
- `packages/game_core/test/pace_report_test.dart` (new): tests of the pure functions, on made-up numbers. No sim
  runs in it, so it stays fast and in the normal check (not tag `pacing`):
  - a median of an even and an odd list, with a missed seed counted as the last day plus one;
  - the read of the newest report from a file with two reports;
  - a move of 5 days gets a mark, a move of 4 days does not;
  - a first report has no change column.
- `scripts/pace-report.ps1` (new): runs the tool from `packages/game_core` with the commit of `HEAD`, and passes
  `-Seeds`. It prints the time of the run.
- `docs/sim/pace-reports.md` (new): a short intro (what it is, how to run it) and the first report.
- `tool/seeds.dart` stays: hand sims use it for a single seed table.
- No change to `lib/`, the data, the save, the app, `check.ps1` or the pacing test.
- No release note: players do not see it.

## When it runs
- When the owner asks for it, for example when he runs evals or after a few features merge.
- It takes the CPU for a few minutes. It does not run while a `check.ps1` runs.
- A report goes to `main` by the fast lane: a commit of `docs/sim/pace-reports.md` only.

## Order of work
### M1: the report (one PR)
- First, the tests of the pure functions, committed alone.
- Then the tool and the script.
- **Proof:**
  - `.\scripts\check.ps1` green.
  - One run of `.\scripts\pace-report.ps1` on `main`, with its time. Its table is the first report in
    `docs/sim/pace-reports.md`.
  - A second run with `-Seeds 8` into a copy of the file shows the change column. It is shown in the PR, not kept.
- Branch `feat/pace-report`. PR with this plan, "Closes #185", review per `REVIEW.md`. The owner merges.
