# Plan 0036: Build "Ysolde says Reset" (spec 0015 amendment 7)

Status: accepted
Spec: `specs/0015-talent-trees.amendment-7.md` · Product owner: Zkalf ("Do the nit we talked about before",
2026-11-01) · Date: 2026-11-01

Names of files, widgets and tests refer to `main` at `8726e07`.

## What changes in the code
- `app/lib/ui/trainer_sheet.dart`: "Reset my talents", "Reset my talents · N steps" and the button "Reset".
- `packages/game_core/data/talents.json`: the trainer's `confirm` line.
- `app/test/talents_screens_test.dart`: the trainer tests look for the new words (criteria 131-133).
- No rule, number, save or sim change. `releases/next.md`: the Talents line says "reset".

## Order of work
### M1: the words (one PR)
- First, the trainer tests with the new words, committed alone (they fail).
- Then the words.
- **Proof:** `.\scripts\check.ps1 -Release` green.
- Branch `fix/ysolde-reset`. PR, review per `REVIEW.md`. The owner merges. The PR closes #157.
