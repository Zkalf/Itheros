# Spec 0010 amendment 10: a locked spot or recipe names the player's level

Status: accepted
Amends: [spec 0010](0010-professions.md) §2.2 (the level of a spot or a recipe) and the reason that a locked spot or
recipe shows ("Oak tree needs Woodcutting 8")
Issue: #223
Product owner: Zkalf (playtest of 2026-11-06: "just add 'you have N'")
Date: 2026-11-06

## Why
- A spot or recipe above the player's profession level has a red badge and the line "Oak tree needs Woodcutting 8".
- The line does not say the player's level. A player who compares the badge with their character level thinks a spot
  "equal to my level" is red for no reason.

## Change
1. The line of a locked spot or recipe names the player's level in that profession too:
   "Oak tree needs Woodcutting 8 (you have 5)".
2. The same words appear where the queue says why it skipped a locked action, as they do today.
3. What stays: the red badge, and the lines for a profession that is not learned ("Learn Woodcutting from …") or a
   missing tool ("You need a hatchet").

## Acceptance criteria
1. A spot above the player's Woodcutting level reads "<spot> needs Woodcutting <level> (you have <N>)".
2. A recipe above the player's Crafting level reads "<recipe> needs Crafting <level> (you have <N>)".
3. A profession that is not learned still reads "Learn …", with no "(you have …)".
