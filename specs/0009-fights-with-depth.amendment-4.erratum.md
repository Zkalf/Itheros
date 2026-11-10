# Spec 0009 amendment 4, erratum 1: Block does not come from a shield alone

Status: accepted
Corrects: [spec 0009 amendment 4](0009-fights-with-depth.amendment-4.md) rule 8 (the limit line of Block) and the
example of criterion 13
Issue: #252
Product owner: Zkalf (chose the new words on 2026-11-10)
Date: 2026-11-10

## What was wrong
- Rule 8 gives the Block sheet the line "At most 50%. Only a shield gives Block."
- Two achievements, Troll Slayer and Deep Waters, each give +6% Block (`achievements.json`). A player with one would
  read "From achievements: +6%" right above "Only a shield gives Block."
- Claude's mistake: the amendment did not check the achievements. The verifier found it before the PR.

## Correction
1. The limit line of Block reads: "At most 50%. Gear gives Block only on a shield."
2. Nothing else changes.
