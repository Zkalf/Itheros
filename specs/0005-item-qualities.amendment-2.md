# Spec 0005 amendment 2: owned gear always names its quality

Status: accepted
Amends: [spec 0005](0005-item-qualities.md) decision 3, §6 and criterion 9
Product owner: Zkalf (tried it on the phone and chose to keep it, 2026-10-19)
Date: 2026-10-19

## Change
Gear the player owns (inventory, equipment, report and journal lines, "Next goal" equip lines) always shows its
quality in brackets, common included: "Hide vest (Common)", "Bone sword (Rare)". Materials keep their plain name.
Names that stand for a kind of item rather than one owned piece (recipes, activities, stop conditions, achievements)
stay plain: "Crafting Hide vest".

## Why
With only the better qualities in brackets, common gear looked unfinished, and it was hard to tell apart from
materials, which have no quality.

## Acceptance criterion
9 (replaces). Owned gear shows its quality in brackets in reports, the journal and the Character tab, common
included, and better than common also in its colour; materials and recipe names stay plain.
