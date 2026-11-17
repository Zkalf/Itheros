# Plan 0070: Build "Portraits at Camp" (spec 0023 §3.6)

Status: accepted
Spec: `specs/0023-role-play.md` §3.6, criteria 53-57 (and spec 0014 criteria 79-80) · Product owner: Zkalf ·
Date: 2026-11-17

Names of files, widgets and tests refer to `main` at `2fc35d9`.

At Camp, Odda shows her portrait, but the six teachers show the pictures of their professions and Ysolde shows the
trainer icon. Each of them gets a portrait, so every person at Camp has a face.

## What changes in the code
- `art/people.py`: seven new portraits in the style of the four of today, written to `art/portraits/<id>.svg`. The
  id is the name in lower case: `hilde`, `bram`, `wen`, `sigrun`, `garrow`, `marta`, `ysolde`. Each one differs from
  the other ten in its shape and colours (§3.5):

  | Id | Who | The look |
  |---|---|---|
  | `hilde` | Hilde, the miner | A brass helmet with a lamp, a dusty face, slate and copper. |
  | `bram` | Bram, the woodcutter | A broad red beard, a green wool cap, an axe on the shoulder. |
  | `wen` | Wen, the fisherman | A knitted blue cap, a grey stubble, a pipe, lake blue. |
  | `sigrun` | Sigrun, the hunter | A fur hood, a long fair braid, a bow string across, moss green. |
  | `garrow` | Garrow, the smith | Bald, a black beard, a leather apron, the red glow of a forge. |
  | `marta` | Marta, the cook | A white headscarf, round red cheeks, a wooden spoon, warm cream and red. |
  | `ysolde` | Ysolde, the Guild trainer | Silver hair, a violet cloak with the Guild's clasp. |

- `scripts/export-art.ps1 -Only <ids>`: the seven files `app/assets/images/portraits/<id>.webp`.
- `app/lib/ui/person_sheet.dart`: `PersonPicture` becomes `Portrait(id, size)`, so the teachers and Ysolde use it
  too. `portraitId(name)` gives the name in lower case.
- `app/lib/ui/now_tab.dart`: the teacher rows and Ysolde's row show `Portrait` in place of `ProfessionPicture` and
  the trainer icon.
- `app/lib/ui/teacher_sheet.dart`, `trainer_sheet.dart`: the top of the sheet is the portrait at 72 dp and the name,
  as in `PersonSheet`.
- `art/icons/trainer.svg` and `app/assets/images/icons/trainer.webp`: deleted, as nothing shows them any more.
- No change to `game_core`, the data, the save or the sim.

## Order of work
### M1: Portraits at Camp (one PR)
- First, the failing tests, committed alone:
  - `people_test.dart`: each teacher's row and Ysolde's row show `Portrait` with the key `portraits/<id>`, and with
    the files on disk the picture is no placeholder (criteria 53-54); a teacher's sheet and Ysolde's sheet show the
    portrait and the name at the top (criterion 55).
  - `spot_pictures_test.dart`: the teacher-row test now expects the portrait, not `ProfessionPicture`. The tests of
    the Professions tab and the profession screens stay as they are (criterion 56).
  - `drawn_icons_test.dart`: the trainer row leaves the list of drawn icons.
  - A test that each teacher and Ysolde has a file `portraits/<id>` (criterion 53-54).
- Then the art and the code.
- **Proof:** `.\scripts\check.ps1 -Release` green. The verifier checks criteria 53-57 and spec 0014's criteria 79-80.
  The Now tab at Camp and Marta's sheet are rendered at 408 dp and looked at (criterion 57).
- Branch `feat/camp-portraits`. PR with the spec change and this plan, review per `REVIEW.md`. The owner merges.

## History
- 2026-11-17: first version (spec 0023 §3.6). Accepted.
