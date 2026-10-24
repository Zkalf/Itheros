# Game direction

The owner (Zkalf) sets the direction of Itheros. These rules guide each design choice. Use them when you propose
or review an intent or a spec.

## Balance for the average player
- Tune the pace for about 5,000 steps a day (spec 0001 §5).
- Do not tune for the owner, who walks and runs about 25,000 steps a day.
- Run the sim with `dart run tool/simulate.dart --steps-per-day 5000`.
- Results for heavy walkers are information, not a balance problem.

## Loot: the Diablo 2 grind
- The owner likes low chances and a long grind for loot.
- Prefer the stronger, more random option to the safe one. Examples:
  - strong quality bonuses (+100% legendary)
  - dropped gear that rolls quality too, so bosses are worth farming
- Name the balance cost of the option in one short line.
- The 5,000-step rule covers the pace (levels each day). It does not cover the excitement of loot.

## Explore and fail
- The whole world is open from level 1 (spec 0008). The danger there is a feature.
- Do not propose level gates or other help that protects new players.
- Warnings and cheap losses are enough.

## Influences
| Game | What Itheros takes from it |
|---|---|
| Diablo 2 | The grind for rare loot. |
| World of Warcraft | The feel of the world (NPCs, flavour), the professions, the talents. |
| Heroes of Might and Magic 3 | The owner loves it. No system from it is chosen yet. Lower priority. |

When you propose a design, name the game that it comes from.
