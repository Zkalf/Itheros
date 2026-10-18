# Evals

Real tasks given to headless Claude (`claude -p`) on throwaway git worktrees, graded by deterministic checks. They
test the Claude setup (`CLAUDE.md`, hooks, skills, the verifier agent), not the game: if a change to that setup makes
Claude stop following the project's rules, an eval fails. Plan: `plans/0002-test-stage.md`.

## Run
- One eval: `.\evals\run.ps1 -Id E04` (a few minutes, about $0.30 of usage at API prices)
- The suite: `.\evals\run.ps1` (about an hour). Writes `results/<run>-<commit>.md` and `results/latest.json`.
- Check the checks, no Claude, no cost: `.\evals\run.ps1 -NoAgent` (every check must give its expected verdict on an
  untouched worktree; most must fail).

Run the suite after changing `CLAUDE.md` or anything in `.claude/`; `scripts\check.ps1` warns when the setup no longer
matches the last full run. Worktrees are made from HEAD, so commit first.

## Add an eval
- `tasks/<id>.json`: `id`, `title`, `prompt`, `check`, `timeoutMinutes`; optional `setup` (a script that plants a
  seeded bug with `Set-Seed`, committed as the base unless `setupCommit` is false) and `noAgent` (`pass` when doing
  nothing is the right answer).
- `checks/<id>.ps1`: dot-source `..\lib.ps1`, use the `Expect*` helpers, end with `Finish`. Check files and git
  state, never transcript wording. Checks run from this repo, so an agent can't weaken them.
- Every incident from real use gets a regression eval (E14, E17–E19, E21 so far).
- Confirm with `-NoAgent` that the check fails without the change, then run the eval once.
