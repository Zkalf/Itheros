# Plan 0045: Build "A picture for each profession" (spec 0014 amendment 7)

Status: accepted
Spec: `specs/0014-quiet-teal.amendment-7.md` · Issue: #198 · Product owner: Zkalf · Date: 2026-11-03

## What changes in the code
**art**
- `art/tools.py`: also writes `art/professions/<id>.svg`, the iron tool of each profession.
- `scripts/export-art.ps1`: exports `art/professions/` to `app/assets/images/professions/` as well.

**app**
- `pubspec.yaml`: the folder `assets/images/professions/`.
- `lib/ui/images.dart`: a `ProfessionThing(id)` with the key `professions/<id>`, and no placeholder: without a file,
  the caller shows the glyph (rule 3).
- A small widget `ProfessionPicture(profession, size: 32)`: the picture, or else the glyph. The three places use it:
  `professions_tab.dart`, `profession_screen.dart` and the teacher rows in `now_tab.dart`.
- `releases/next/feat-profession-pictures.md`: one line for players.

## Order of work (one PR)
1. The tests (`app/test/`): criteria 1-6.
2. The art, the code and the notes line.
3. **Proof:** the three places rendered at 408 dp wide, for the owner (CLAUDE.md). `.\scripts\check.ps1 -Release`
   green. Review per `REVIEW.md`; the owner merges.

Branch `feat/profession-pictures`.
