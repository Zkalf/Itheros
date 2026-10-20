# Itheros

A fantasy combat RPG for Android where your real-world steps are the only currency. Every fight, every ore and
every crafted item is paid for with steps you walk, read from Health Connect. Your step data never leaves the
phone: the app has no internet permission at all.

**Play it:** [how to install](INSTALL.md) · [latest release](https://github.com/Zkalf/Itheros/releases/latest)

## How it's built
A solo hobby project, built with an AI-native development process: every change goes
**intent → spec → plan → code**, and the product owner accepts each stage before the next begins.
Accepted documents are never edited; changes come as numbered amendments.

| Folder | What's in it |
|---|---|
| [`intent/`](intent/) | What the player is missing and why it matters |
| [`specs/`](specs/) | Exactly what the game does, with acceptance criteria |
| [`plans/`](plans/) | How each spec gets built, milestone by milestone, each with its proof |
| [`packages/game_core/`](packages/game_core/) | All game rules in pure Dart; tuning numbers in `data/*.json` |
| [`app/`](app/) | The Flutter Android app |
| [`evals/`](evals/), [`.claude/`](.claude/), [`CLAUDE.md`](CLAUDE.md) | The AI assistant's instructions, skills, hooks and the evals that test them |
| [`releases/`](releases/) | Release notes for each version |

`docs/commit-map.md` maps commit IDs named in older documents to the current history.

## Licence
All rights reserved. You're welcome to read the code; please don't reuse it without asking.
