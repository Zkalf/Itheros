# Spec 0010 amendment 11, erratum 1: what target 3 copies, and what the amendment amends

Status: accepted
Corrects: [spec 0010 amendment 11](0010-professions.amendment-11.md) the Amends line, change 2 and criterion 2
Issue: #237
Product owner: Zkalf (accepted on 2026-11-07, on PR #240)
Date: 2026-11-07

## What was wrong
- Change 2 says target 3's range 70-100 is "the same range as the mixed walker's". For the mixed walker, 70-100 was
  the range of each seed (spec 0009 amendment 1). Its median range is 80-100 (spec 0010 §9.3 target 1). Target 3
  checks a median, so the words read two ways.
- The Amends line leaves out two lines that change 1 replaces:
  - spec 0010 §9.2: "Fighter: never learns a profession; wears only drops.";
  - spec 0011 §9.2: "Fighter: unchanged (no professions, no meals).".
- Criterion 2 checks two things (WRITING.md rule 13), and "gathers for none" leaves out "for gear": a meal can still
  make the fighter gather.
- Claude's mistake: the amendment was marked accepted in its draft, before the verifier read it.

## Correction
1. The amendment also amends spec 0010 §9.2 and spec 0011 §9.2 (the fighter's line in each).
2. Change 2 reads: "**Target 3 becomes:** the fighter's median day of level 30 (seeds 1-8) is in 70-100, the range
   that each mixed walker seed had in spec 0009 amendment 1. It does not need to be later than the mixed walker.
   Fighting first is a fine way to play."
3. Criterion 2 becomes two criteria; the later criteria keep their numbers and their checks:
   - 2a. The fighter crafts a gear upgrade when it holds the materials.
   - 2b. The fighter never gathers or practises a profession for gear.
4. Nothing else changes: the habit, the numbers and the other criteria stay as amendment 11 says.
