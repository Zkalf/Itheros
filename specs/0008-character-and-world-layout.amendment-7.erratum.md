# Spec 0008 amendment 7, erratum 1: the texts it changes, and a long name

Status: accepted
Corrects: [spec 0008 amendment 7](0008-character-and-world-layout.amendment-7.md), its "Amends" line, change 5 and
criteria 1 and 6
Issue: #254
Product owner: Zkalf (accepted on 2026-11-10)
Date: 2026-11-10

## What was wrong
- The "Amends" line names spec 0008 §3.5 and spec 0009 amendment 4 rule 10. The amendment also changes three other
  accepted texts and does not say so:
  - [spec 0014](0014-quiet-teal.md) §2.3: "72 dp in heads and portraits";
  - spec 0014 criterion 8: "the eight stats" of the Character header;
  - [spec 0011](0011-lake-and-hunt.md) §8.3: the example "Attack 34 (+2 meal)".
- Change 5 and criterion 1 put the level on the line of the name. A name of 20 letters, the longest the game takes,
  leaves no room for it on a 408 dp phone at the usual text size.
- Claude's mistake: the amendment did not search the other specs for the block, and the trial used a short name. The
  verifier found both before the PR.

## Correction
1. The amendment also amends spec 0014 §2.3 and criterion 8, and spec 0011 §8.3:
   - the portrait in the Character header is 48 dp. The other heads and portraits keep 72 dp;
   - the Character header keeps the level beside the name and the seven stats in their row, in place of "the eight
     stats";
   - the example of the meal reads "+2 meal" under Attack.
2. Change 5 reads: at a large text size the row wraps to two rows. When the name and the level do not fit one line,
   at any text size, the level stands under the name. Nothing is cut off.
3. Criterion 1 holds for a name that fits the line with the level. Criterion 6 is measured with such a name.
4. One test of spec 0014 criterion 8 changes with the portrait: "Adventurer · Woodcutter's daughter" now fits a phone
   360 dp wide, so the test of an origin that does not fit uses a phone 320 dp wide.
5. Nothing else changes.
