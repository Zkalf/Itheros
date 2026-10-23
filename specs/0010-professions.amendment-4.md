# Spec 0010 amendment 4: one screen per profession

Status: accepted
Amends: [spec 0010](0010-professions.md) §8.1 (the Professions screen) and
[amendment 3](0010-professions.amendment-3.md) (profession buttons and recipe filters)
Product owner: Zkalf (playtest notes on 0.3.0, 2026-10-23)
Date: 2026-10-23

## Why
Amendment 3's buttons only scroll a long page that still holds all six profession cards, so the screen stays
crowded. Owner: "Each profession button (Mining, Woodcutting and so on) should open its own screen that holds only
that profession. The recipe filters stay on the screens that have recipes."

## Change
1. **The Professions tab is a list of six profession buttons**, in the card order of §8.1 (spec 0011 §8.1 for the
   six). Each button shows the profession's icon, name and level, a progress bar to the next level, and the tier
   name ("Iron"). An unlearned profession's button shows "Learn from <teacher> in camp" instead of level and bar.
   The cards themselves are no longer on this tab.
2. **A tap opens that profession's own screen** (a page pushed over the tab, with a back arrow and the profession's
   name as its title). It holds only that profession's card, with the same contents §8.1 and spec 0011 §8 give it:
   tool, Where to practise / Go there, records, meal and auto-eat, recipes, or the "Learn from …" line.
3. **Recipe filters** (amendment 3 §2: Have mats, Have level, Up to 5 levels ahead, and their rules) sit at the top
   of the screens that have recipes: Crafting and Cooking. The other screens have no chips. The filter choice is
   one view setting shared by both screens; it still isn't saved and is off each time the app starts.
4. **Links that went to a card now open its screen:** the Forge row in Now opens Crafting's screen, the Camp fire
   row opens Cooking's, and a tool line opens its profession's screen.
5. **Starting an action** from a profession screen (Go there, a recipe) goes to Now as today (playtest 3); the
   profession screen closes.

This replaces amendment 3 §1 (buttons that scroll to a card). Amendment 3 §2–§3 (the filters) stay, placed as in 3
above.

## Acceptance criteria
1. The Professions tab shows six profession buttons and no profession card.
2. Tapping a button opens a screen with only that profession's card; back returns to the tab.
3. Crafting's and Cooking's screens show the three filter chips, which work as amendment 3's criteria 2–4 say; the
   other four screens show none.
4. An unlearned profession's button and screen name its teacher.
5. The Forge row, the Camp fire row and a tool line open the matching profession's screen.
6. Starting an action from a profession screen closes it and shows Now.
