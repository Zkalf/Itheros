# Plan 0068: Build "one current file per intent, spec and plan"

Status: accepted
Spec: none: a change of the process, not a game rule · Product owner: Zkalf · Date: 2026-11-15

Names of files, hooks and checks refer to `main` at `216a02f`.

## Why
- A spec that changed often has many files: spec 0010 has 17. A reader must apply each amendment and erratum in
  order to know what the game does today.
- The clean editions help, but they are a copy. They fall behind with each new amendment.
- The owner wants one file per spec that is always the current, correct version.

## Choices of the owner (2026-11-15)
1. Each spec is one living file. A change edits that file.
2. Each spec ends with a short **History** section: one line per change.
3. The amendment, erratum and clean edition files of specs are deleted. Git keeps the old texts and every diff.
4. Intents and plans follow the same rules. The templates change to match.

## The new rules
The rules hold for the three kinds of files: intents (`intent/`), specs (`specs/`) and plans (`plans/`).

**One file**
1. Each intent, spec or plan is one file, `<folder>/NNNN-<name>.md`. A spec says what the game on `main` does. An
   intent says what the player gets and why. A plan says how the work goes.
2. A change edits that file on a branch, in the same words as a new text (`WRITING.md`).
3. A change that touches several files edits each of them. No file lists the changes that other files make to it.

**Numbers stay**
4. A section, decision, outcome, milestone or criterion keeps its number for good. Code and tests that cite a
   number stay right.
5. A new one takes the next free number.
6. A criterion that a change removes keeps its number, with one line: "Removed on <date> (#N)."
7. A criterion that a change rewrites keeps its number. The History line names it.

**History**
8. The History section is the last section of the file. Each line has the date, the issue, the change in a few
   words, and the sections and criteria that it touched.
9. The History of a file moved from amendments keeps one line per old file, with the old name. A comment such as
   "spec 0010 amendment 9" then still leads to its line. For example:
   `- 2026-11-03, amendment 9 (#175): Salvage all. §7.4; criteria 120-136.`
10. Git holds the full text of every change: `git log -p <folder>/<file>`.

**Draft and accepted**
11. A new History line ends with "(draft)" until the owner has read the change. The owner says "accepted", and
    Claude removes "(draft)".
12. A new file starts with `Status: draft`, as before.
13. The `check` on a pull request fails while a file holds `Status: draft` or a "(draft)" History line.

**What stays as it is**
14. Old code comments keep their words, such as "spec 0013 amendment 4 criterion 2". New comments cite the
    section or criterion of the living file, such as "spec 0013 criterion 64".
15. Other records keep their own rules: incident records, `plans/0031-talent-trees.results.md`, the release notes
    and the eval results. Each tells what happened at one time.

## What changes in the tools
- `.claude/hooks/protect-accepted.ps1`: it allows edits to an accepted intent, spec or plan, but only on a branch
  other than `main`.
- `.github/workflows/check.yml`, the "No drafts" step: it also fails on a "(draft)" History line. A new step,
  "History line": a pull request that changes an existing intent, spec or plan adds a line to its History section.
- The templates:
  - `intent/TEMPLATE.md`, `specs/TEMPLATE.md` and `plans/TEMPLATE.md` get a History section at the end.
  - The three `AMENDMENT-TEMPLATE.md` files are deleted.
- `.claude/skills/small-feature/SKILL.md`: the change edits the spec and adds a "(draft)" History line, instead of
  a new amendment file.
- `.claude/skills/bugfix/SKILL.md` and `.claude/agents/verifier.md`: read the one file and its History.
- `CLAUDE.md`, `WRITING.md`, `CONTRIBUTING.md`, `README.md`, `REVIEW.md` and `GLOSSARY.md`: the new rules in short.
  The clean edition rule and the glossary words "amendment", "erratum" and "clean edition" go. "History" comes in.
- Eval E01 (`evals/tasks/E01.json`, `evals/checks/E01.ps1`, `evals/lib.ps1`): its prompt changes spec 0013. The
  check expects the spec edit with a "(draft)" History line.

## Moving the files over
- A file that still has amendment files moves over before its next change, in a commit of its own.
- The move changes no rule, number or criterion. The pull request or commit lists each old criterion and its new
  number. The file does not.
- Numbers in a moved spec are checked against `data/*.json`, as for the clean editions.
- An accepted intent, spec or plan without amendments gets its History section when it next changes.

| Kind | Files | The work |
|---|---|---|
| Spec with a clean edition | 0004, 0008, 0009, 0010, 0013, 0014, 0015 | The clean edition becomes the spec. Its reading notes, tags and tables go. The criteria of each amendment join the main list with the next free numbers. "Where each change went" becomes the History. |
| Spec with amendments, no clean edition | 0001, 0002, 0005, 0006, 0007, 0011, 0012, 0016, 0017, 0018, 0020, 0021, 0022 | The amendments and errata fold into the spec, in the same way. |
| Intent with amendments | 0013, 0017, 0020 | The same fold. |
| Plan with an amendment | 0021 | The same fold. |

## Order of work
### M1: the new rules, the tools, and the intent and spec of 0013 as the pilot (one PR)
- The tool and text changes above.
- Intent 0013 and spec 0013 move over. Their amendment, erratum and clean edition files are deleted.
- **Proof:**
  - `.\scripts\check.ps1` is green.
  - The hook, by hand: an edit of spec 0013 on the branch goes through; an edit of a file in `specs/` on `main` is
    blocked.
  - The pull request itself passes "History line" and "No drafts" once the owner has accepted the pilot.
  - Eval E01 passes (only that eval).
  - The owner reads the new spec 0013 and says whether the layout reads well.
- Branch `docs/living-specs`. PR with this plan, review per `REVIEW.md`. The owner merges.

### M2: the other six clean editions (fast lane)
- Specs 0004, 0008, 0009, 0010, 0014, 0015: one commit per spec on a short branch. The owner reads each and pushes
  them to `main`.

### M3: the specs with the most amendments (fast lane)
- Specs 0020, 0021, 0017, and intents 0017 and 0020.

### M4: the next specs (fast lane)
- Specs 0001, 0002, 0016, 0011.

### M5: the last files (fast lane)
- Specs 0005, 0006, 0007, 0012, 0018, 0022, and plan 0021.

## Risks
- **A fact lost in a fold.** The list of old and new criterion numbers in each commit shows that every criterion
  went somewhere. The owner reads each moved spec, as for a clean edition.
- **Mixed state while the files move.** Until M5, some files still have amendment files. The first rule of "Moving
  the files over" keeps a change from adding a new amendment.
- **Usage.** The folds are long texts. One milestone per session keeps each session small.

## History
- 2026-11-15: first version. The owner added intents, plans and the templates on acceptance.
