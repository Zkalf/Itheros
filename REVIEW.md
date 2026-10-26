# Reviewing a pull request

How Claude reviews each pull request before the owner merges it (plan 0009 D2). Claude runs `/code-review` on the
PR, adds the verifier's findings for the spec the change touches, and posts one review comment on the PR in plain
words. A finding that comes back in a second PR becomes a rule in `CLAUDE.md`.

## The passes
1. **Does it do what was accepted?** The spec's acceptance criteria the change touches, one by one, and nothing
   outside the accepted plan.
2. **Is it correct?** Logic, edge cases (0 steps, a new day, a full bank, level caps), and both the first start and
   an existing save.
3. **Health data stays on the phone.** No INTERNET permission, no network code or package that phones home,
   `allowBackup="false"`, nothing that logs step data outside the app.
4. **Saves load across versions.** Changed save fields have a default for old saves; the fixtures in
   `app/test/fixtures/saves/` still load.
5. **Do the tests prove it?** A test that fails without the change; bug fixes follow the `bugfix` skill.
6. **The project rules** in `CLAUDE.md` (tuning numbers in `data/*.json`, Health Connect aggregate reads, one queue
   in `GameController`, the production gate).
7. **The release notes.** A change that players notice adds a plain line to `releases/next.md` (#119). A missing
   line is Important; a line in words that are not for players is a Nit.

## Findings
- **Important**: must be fixed before the merge. A wrong result, a broken acceptance criterion, a privacy or
  save-compatibility risk, a missing test for new behaviour, a text that can be read two ways or that loses or
  changes a fact (`WRITING.md`). Each says what goes wrong and how to see it.
- **Nit**: small and optional (naming, a clearer comment, a simpler line, wording per `WRITING.md` with its rule
  number). **At most 3 per review**; the rest are dropped.
- No findings is a fine result: say so in one line.

## Never changed, so any change is Important
- The save fixtures (`app/test/fixtures/saves/`): only `release.ps1` adds one; none is edited or deleted.
- Accepted intent, spec and plan files: they're the yardstick, not the subject. Changes come as new files.

## Not reviewed line by line
- `docs/commit-map.md`, `evals/results/`, generated files (`*.g.dart`, `pubspec.lock`, build output).
