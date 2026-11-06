# Spec 0022, erratum 1: the guide's name and the teachers' place

Status: accepted
Corrects: [spec 0022](0022-camp-tour.md) decision 3, §3.2 points 9-10, §3.3 steps 1 and 3, §3.4 point 19, criteria 4
and 21; [plan 0053](../plans/0053-camp-tour.md) (`GuideThing` for Bram's portrait)
Issue: #226
Product owner: Zkalf (chose on 2026-11-06: a new quartermaster, not a teacher; card 3 says the teachers are at Camp; accepted on 2026-11-06)
Date: 2026-11-06

## What was wrong
- Spec 0022 names the guide Bram. The game already has a Bram: Bram the woodcutter, one of the six teachers at Camp
  (`professions.json`). The Professions tab says "Learn from Bram in camp".
- Step 3 says each profession "has a teacher somewhere out there". All six teachers teach at Camp.
- Claude's mistake: the spec did not check the names and the places in the data. A test of the existing game showed
  the clash during the build.

## Correction
1. The guide is **Odda, the camp quartermaster**: a new character. No other character in the game has this name.
2. Every "Bram" of spec 0022 that names the guide reads "Odda":
   - decision 3: **Odda, the camp quartermaster**;
   - point 9 and criterion 4: the card shows the name "Odda";
   - point 10: Odda has no picture yet;
   - point 19 and criterion 21: the Settings line reads "Odda shows you around again".
3. Step 1 reads: "Welcome to the Guild camp, {name}. I'm Odda, the quartermaster. Now shows what you are doing and
   what comes next. Every step you walk moves it on."
4. Step 3 reads: "Mining, woodcutting, fishing, hunting, cooking, crafting. Each has a teacher here at Camp. Learn
   from them, and go back for their tips."
5. Plan 0053: the guide's picture is `GuideThing('odda')`, for the key `portraits/odda`.
6. Nothing else changes: the rules, the other steps, the screens and the criteria stay as spec 0022 says.
