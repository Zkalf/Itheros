# Intent: Levels that matter

Status: accepted
Product owner: Zkalf
Date: 2026-10-19

## Problem
An average walker (about 5,000 steps a day) sees everything the game has on day 1: Goblin Woods, Copper Hills,
the brute, the copper sword and the hide vest. Days 2 to 9 are the same goblins, grinding towards level 10, which
is the hard cap. After that there is nothing to work towards.

Levels don't feel like much either. A level-up adds +5 HP, +1 Attack and +1 Defense, happens while the phone is in
a pocket, and appears as one line in the "while you were away" report. The product owner wants the feeling of
levelling in World of Warcraft: every level is an event, stats grow, and talents open up from level 10.

Grinding one monster also works forever. Nothing pushes the player on to new monsters, and nothing pulls them
there.

## Proposed outcome
Every level-up feels like an event and unlocks something, and the game keeps moving the player on to new monsters.

- **Monsters have levels, shown in WoW-style colours** (grey, green, yellow, orange, red) relative to the player's
  level, so the player can see at a glance what is worth fighting.
- **XP fades as a monster falls below the player's level.** A monster around the player's level gives full XP. A grey
  monster gives almost none. A player farming one monster for too long notices that progress has slowed.
- **Each new monster gives more XP per step than the one before**, so moving up is a reward, not just an escape.
- **Grey monsters still drop their loot.** Going back to farm materials stays useful. It just doesn't level the
  player.
- **No level cap.** Levels continue indefinitely. The practical ceiling comes from content: XP fades out a few levels
  above the strongest monster (for example, top monster level 30 → players stall around level 37). Adding stronger
  monsters later raises the ceiling without changing any rules.
- **A proper level-up moment.** Level-ups that happened while the player was away are celebrated when the app opens,
  before the report: the new level, the stats gained, and what is new.
- **Every level unlocks something the player can name**: a monster, an area, a recipe, a gear slot, or (from
  level 10) a talent point.
- **More monsters in the first areas**, starting with skeletons and zombies. Each one has a twist that changes which
  gear suits it, not just bigger numbers. For example:
  - Skeleton: low HP, tough armour. Rewards a strong weapon. Drops bones for bone gear.
  - Zombie: slow, huge HP, hits hard. Rewards defence. Fights are long and cost many steps.
- **Steps never feel wasted.** Reaching the soft cap slows levelling only. Walking keeps paying out in loot,
  materials and achievements.

### Pace for an average walker (5,000 steps a day)
| Milestone | When |
|---|---|
| Levels 1–5 | Day 1 (unchanged) |
| Level 10, talents open | About 2 weeks (today about 9 days) |
| Level 30, top monster of the first content | About 3 months (about 450,000 steps) |
| Beyond | Slow levelling through fading XP. Loot and crafting take over. |

A heavy walker reaches these milestones several times faster. That is intended.

## Affected users and systems
- **Players:** everyone. Existing saves keep their level and XP.
- **Game rules:** character levels (open-ended XP curve), monster levels, XP fade, unlocks per level, new monsters
  and their drops, new recipes and gear.
- **Content:** new monsters, areas and items for levels 1–30.
- **Screens:** monster colours in the fight list, a level-up screen on app open, and "what's new" in the report.

## Constraints
- Balance for the average walker (about 5,000 steps a day), never for heavy walkers.
- Walking must always pay out in something: no step should feel like it earned nothing.
- Monsters, areas, items, numbers and colour bands live in data, so content can grow later without rule changes.
- Talents are still not built here. This intent only makes sure that levels beyond 10 exist for them.
- **Later, in a separate intent ("Running your day"):** stop conditions ("until grey", "until I have enough"), a
  queue of 3 actions with automatic travel, and a step bank of 10,000 at level 1, +500 per level.
- **Later, tuned separately:** achievement rewards (Marathon's +500 bank cap is too small next to a 10,000 bank),
  the talent tree, and a fourth queue slot as a reward.

## Open questions
1. **Losing fights.** What happens when the player loses, especially once actions can be queued? This has a big
   impact on the game and needs its own discussion before monsters get tougher.
2. **XP fade curve.** How many levels below the player is a monster green, and when is it grey? How little is
   "almost no XP"?
3. **Monster roster for levels 1–30.** Which monsters, in which areas, at which levels, and what twist each one has.
4. **Unlock per level.** The list of what each level from 2 to 30 unlocks, so that no level feels empty.
5. **Stat growth per level.** Does the current +5 HP / +1 Attack / +1 Defense still feel good, or should levels give
   more visible gains?
6. **At the soft cap.** What does a player at the ceiling walk for (rare drops, crafting goals, achievements)?
7. **Talent points without a level cap.** One point per level from 10 gives about 28 points at the first soft cap.
   The tree should be sized for that and grow with each content update.
