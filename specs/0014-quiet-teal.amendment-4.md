# Spec 0014 amendment 4: a clear selected look, and an outline on button labels

Status: accepted
Amends: [spec 0014](0014-quiet-teal.md) §2.1 (colours: "lit `#2E3740` … the lit tab and selected chips") and §2.2
(chips and segments: "A selected chip is lit and has a teal label"; bottom bar: "The lit tab is teal"; type: button
labels)
Issue: #101
Product owner: Zkalf (chose from test renders on 2026-10-26: look E, teal 35% with a white label, also on the
Journal tabs and the open tab of the bottom bar; and the thin black outline on every button label except the teal
buttons)
Date: 2026-10-26

## Why
- A selected chip or segment is hard to tell from one that is not selected.
- Today the selected fill is lit `#2E3740`, and the other fill is slate `#2B333B`. The two colours are almost the
  same.
- Only the label shows the choice: teal on the selected one, light text on the others. Teal and light text are close
  in brightness.

## Change
**The selected look**
1. A selected chip, segment, Journal tab or bottom bar tab has:
   - the fill **selected `#4C6768`**: teal `#8AC7BC` at 35% over slate `#2B333B`;
   - a **white `#FFFFFF`** label;
   - a white icon, where it has an icon.
2. These controls have the selected look:
   - the segments, such as Gear and Bag on the Character tab and the gender on "Who are you?";
   - the choice chips and the filter chips, such as the stop choices, Auto-eat, Have mats, Have level and Up to 5
     levels ahead;
   - the tabs of the Journal: Log, Bestiary and Lore;
   - the open tab of the bottom bar: Now, World, Professions or Character.
3. A chip, segment or Journal tab that is not selected stays slate with a light text label, as today.
4. A bottom bar tab that is not open stays as today: no fill, and a muted icon and label.
5. Lit `#2E3740` stays only for the thumb of a switch that is off.

**The outline on button labels**
6. A **thin black outline** surrounds the letters of each button label. The outline is four black shadows of 0.8 dp,
   one on each side, with no blur.
7. These labels have the outline:
   - slate buttons, such as Go there, Equip, Swap, Unequip, Change and Reroll;
   - ghost buttons: Cancel, Not now, Keep it and Skip all;
   - segments, choice chips and filter chips, selected or not;
   - the tabs of the Journal;
   - the labels of the bottom bar.
8. These labels do not have the outline:
   - teal buttons. Their label is dark `#0D1416` on teal, and an outline makes it heavier, not clearer.
   - status chips, such as "Active". They are not buttons.
9. Icons have no outline.

**What stays**
10. The 2 dp black border, the shapes, the sizes, the fonts and the words of each control stay as they are.
11. Text that is not on a button keeps its look: body text, titles, names, list headings and numbers.

## Acceptance criteria
**Selected look**
1. A selected segment has the fill `#4C6768`, a white label and a white icon.
2. A selected choice chip and a selected filter chip have the fill `#4C6768` and a white label.
3. The open tab of the Journal has the fill `#4C6768` and a white label.
4. A segment, chip or Journal tab that is not selected has the fill slate `#2B333B` and the label `#E3EAEC`.
5. The open tab of the bottom bar has the fill `#4C6768`, a white icon and a white label. The other tabs have no fill
   and a muted icon and label.

**Outline**
6. The label of a slate button has the four black shadows of 0.8 dp with no blur.
7. The label of a ghost button has the outline.
8. The label of each segment, choice chip, filter chip and Journal tab has the outline, selected or not.
9. Each label of the bottom bar has the outline.
10. The label of a teal button has no shadow.
11. A status chip has no shadow.

**Colours**
12. Each colour literal in `app/lib/` is a colour of §2.1 with this amendment, a quality or band colour, black,
    white or transparent (spec 0014 criterion 2).

**Check and release**
13. Rules, numbers and the save do not change. The pacing test passes.
14. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
