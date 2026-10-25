# Spec 0017 amendment 3: milestones on the way, Smith's reward and the meals comparison

Status: accepted
Amends: [spec 0017](0017-achievements-rework.md) §2 (the milestones of rows 2, 3, 6, 13 and 21), §8 and criteria 31
and 32
Product owner: Zkalf (chose "+500 bank cap" for Smith and "compare without feat bonuses" on 2026-10-24)
Date: 2026-10-24

## Why
The sim of plan 0021 M2 found three problems.

1. **A free piece of gear slows the sim walker.** Smith's Iron shield came on day 16. The walker then did not craft a
   shield, its crafts and gathering changed, and it reached level 30 on day 93 instead of 84. The Mithril helm of
   Master Smith did the same when it came before level 20. A player is not slower with a free shield. The walker
   follows its rules, so the sim cannot measure the pace with such a reward.
2. **Some milestones did not come on the way.** The walker gathers only about 45 copper ore in the whole game, crafts
   its 20th item after level 10, fishes very little before level 10, and walks about 420,000 steps by level 30.
3. **The meals comparison of spec 0011 §9.3 (target 5) missed by half a day.** Legendary Find is luck. Its bonus
   (+6 Crit) lands on other days in the runs with and without meals.

## Change

### Milestones

| # | Achievement | Before | After |
|---|---|---|---|
| 2 | Prospector | gather 50 copper ore | gather **30** copper ore |
| 3 | Smith | craft 20 items; Iron shield, Uncommon | craft **15** items; **+500 bank cap** |
| 6 | Angler | reach Fishing level 10 | catch **5** fish at **Lake shore** |
| 13 | Master Smith | craft 60 items, mid | craft 60 items, **late** |
| 21 | The Long Road | walk 1,000,000 steps | walk **350,000** steps |

- Angler counts `gathered.lake_scale`. Each catch at Lake shore gives one lake scale, and no other spot gives one.
- Master Smith moves to the late stage, so its Mithril helm comes after level 20 (days 54–63 in the sim). The stages
  then hold 10 early, 8 mid and 12 late achievements.
- The other milestones stay.

### The sim (§8)
1. Criterion 31 uses seed 1 of the sim. Days 16, 50 and 84 are the days of seed 1 before spec 0017.
2. Criterion 32 has two exceptions:
   - Smuggler's Secret: the cove needs the bottle, which is luck.
   - King's Bane: the walker may never fight the Graveyard King. A boss fight is a choice.
3. Criterion 32 runs on the 8 seeds of the pacing test.
4. The meals comparison of spec 0011 §9.3 (target 5) runs with the bonuses of feats set to nothing. The game keeps
   the bonuses. Only the comparison leaves them out.
5. The cost of a feat is its days of grind: from the start of the grind to the feat. The days that a grind adds to
   level 30 are noisy, because the grind changes the gear that the walker makes later.

### Criteria
- Criterion 31 becomes: **Without feats, seed 1 of the sim reaches levels 10, 20 and 30 within 5% of days 16, 50
  and 84.**
- Criterion 32 becomes: **On each of the 8 seeds, the sim walker earns each milestone by the end of its stage,
  except Smuggler's Secret and King's Bane.**
