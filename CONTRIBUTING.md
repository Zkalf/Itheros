# Contributing to Itheros

Thanks for helping! Itheros is built with an AI-native process (see [README.md](README.md)); the product owner,
Zkalf, accepts every stage and every merge.

## Licence of your changes
Itheros is licensed under the [GPL-3.0](LICENSE) (or later). By opening a pull request you agree that your change is
licensed the same way.

## Small changes (a fix, new content, a tuning number)
1. Make a short branch from `main` (`fix/<name>`, `content/<name>`); keep it to one change, merged within a day or
   two.
2. Run `.\scripts\check.ps1` before you push (Windows, PowerShell 5.1; Flutter 3.47.7 and Java 17).
3. Open a pull request saying what changes and how you proved it. The `check` runs on it automatically (format,
   analyze, all tests, an APK build and the APK check).
4. Zkalf merges. Pull requests are squash-merged: one commit per change on `main`.

Content and tuning that fit existing systems (enemies, locations, items, gear slots, achievements, numbers) are
data-only changes in `data/*.json`; the pacing tests in `check.ps1` must stay green.

## New features
A new rule or system starts as an **intent**: copy `intent/TEMPLATE.md` to the next free number, describe what the
player is missing and why it matters, and open a pull request with it (status `draft`). Once Zkalf accepts it, a
spec and a plan follow, then the code. Accepted intent, spec and plan files are never edited.

## Ground rules
- **Health data stays on the phone:** no internet permission, no network code, no analytics, no cloud backup.
- **Saves load across versions:** never edit or delete `app/test/fixtures/saves/`.
- Bug fixes start with a failing test (see `.claude/skills/bugfix/SKILL.md`).
- **Releases are the owner's.** Only Zkalf releases (`scripts/release.ps1`); the signing key never leaves their PC,
  and version tags and published releases are locked to the owner.
- Project rules for the AI assistant (and good guidance for people) are in [CLAUDE.md](CLAUDE.md); reviews follow
  [REVIEW.md](REVIEW.md).
- Specs, plans, pull requests and other project texts follow the rules in [WRITING.md](WRITING.md).
