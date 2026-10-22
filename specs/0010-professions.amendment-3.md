# Spec 0010 amendment 3: profession buttons and recipe filters

Status: accepted
Amends: [spec 0010](0010-professions.md) §8.1 (the Professions screen)
Product owner: Zkalf (playtest notes, 2026-10-22)
Date: 2026-10-22

## Why
With six professions (spec 0011), the Professions screen is a long scroll: Cooking is far down, and Crafting's
recipe list mixes what the player can make now with what is ten levels away. Owner: "Professions should be buttons
instead of having to scroll so far down", and a filter for "I have mats", "I have the level" and "I'm soon the
level (+5)", the last two never on together.

## Change
§8.1 gains, above the cards:
1. **Profession buttons:** one row of six buttons with each profession's icon and level, in card order. A tap
   scrolls to that profession's card. Unlearned professions have a button too, and it goes to their "Learn from …"
   card.
2. **Recipe filters:** three chips that filter every recipe list on the screen (Crafting's and Cooking's):
   - **Have mats:** recipes the player can make at least once with what's in the bag now.
   - **Have level:** recipes whose profession level the player has.
   - **Up to 5 levels ahead:** recipes the player has the level for, plus those that need up to 5 more profession
     levels: a peek at what comes next.

   Turning on "Have level" or "Up to 5 levels ahead" turns the other off. "Have mats" combines with either. With no chip
   on, the lists show as before. A card whose list is filtered empty says "Nothing matches the filter".
3. The filters are a view setting: they aren't saved and are off each time the app starts.

Nothing else in §8.1 changes: the cards, their order and contents stay as they are.

## Acceptance criteria
1. Tapping a profession's button brings its card into view.
2. Each filter shows exactly the recipes its rule describes, on Crafting's and Cooking's lists.
3. "Have level" and "Up to 5 levels ahead" are never on together; "Have mats" combines with either.
4. With no filter on, the screen lists the same recipes as before this amendment.
