# Itheros

A fantasy combat RPG for Android where your real-world steps are the only currency. Every fight, every ore and
every crafted item is paid for with steps you walk, read from Health Connect. Your step data never leaves the
phone: the app has no internet permission at all.

**Play it:** [how to install](INSTALL.md) · [latest release](https://github.com/Zkalf/Itheros/releases/latest)

## How it's built
A solo hobby project, built with an AI-native development process: every change goes
**intent → spec → plan → code**, and the product owner accepts each stage before the next begins.
Accepted documents are never edited; changes come as numbered amendments. The AI assistant works on short
branches and opens pull requests; an automatic check runs on each, and the owner's merge is the approval. Only the
owner can release.

| Folder | What's in it |
|---|---|
| [`intent/`](intent/) | What the player is missing and why it matters |
| [`specs/`](specs/) | Exactly what the game does, with acceptance criteria |
| [`plans/`](plans/) | How each spec gets built, milestone by milestone, each with its proof |
| [`packages/game_core/`](packages/game_core/) | All game rules in pure Dart; tuning numbers in `data/*.json` |
| [`app/`](app/) | The Flutter Android app |
| [`evals/`](evals/), [`.claude/`](.claude/), [`CLAUDE.md`](CLAUDE.md) | The AI assistant's instructions, skills, hooks and the evals that test them |
| [`releases/`](releases/), [`RELEASING.md`](RELEASING.md) | Release notes for each version; how releases (and taking one back) work |
| [`REVIEW.md`](REVIEW.md), [`.github/`](.github/) | How each pull request is reviewed; the check that runs on every one |
| [`incidents/`](incidents/) | One record per bug from real use: cause, fix, lesson |

`docs/commit-map.md` maps commit IDs named in older documents to the current history.

## Licence
Copyright (C) 2026 Zkalf and contributors.

Itheros is free software: you can redistribute it and/or modify it under the terms of the
[GNU General Public License version 3](LICENSE) or (at your option) any later version. Copies and changed versions
you share must stay open under the same licence. It comes with no warranty. The name "Itheros" isn't part of the
licence: please give your own version another name.

Want to help? See [CONTRIBUTING.md](CONTRIBUTING.md).
