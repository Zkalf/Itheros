# Glossary

This file lists the words that the project texts of Itheros use: intents, specs, plans, designs, reviews and the
docs. Each word has one meaning (`WRITING.md` rule 1). The code name is given where it is different.

- A new spec, amendment, plan or design that brings a new word adds it here, in the same pull request.
- A word that players see in the game belongs to its spec (see `WRITING.md`). This file only explains it.
- [Words with more than one meaning](#words-with-more-than-one-meaning) lists the old words that new texts replace.

## Steps and days

| Word | Meaning |
|---|---|
| **step** | One step that the player walks, read from Health Connect. Steps pay for every action. |
| **step bank** | The store of steps walked while the character has no action. It has a cap. Steps over the cap are lost. Code name: `stepBank`. |
| **sync** | The read of new steps from Health Connect into the game. Steps count per local day. |
| **test walk** | Pretend steps that a button adds, as if walked (spec 0004). A hidden switch turns the button on. |
| **supply chest** | The reward for a day with at least 5,000 steps spent on actions (spec 0013). |

## The queue and walks

The owner and Claude chose these words on 2026-10-24, after the playtest of the queue rework (spec 0016). On
2026-11-11 the owner chose **queue slot** in place of "slot".

| Word | Meaning |
|---|---|
| **current action** | The action that the character does now. It is number 1 on the queue card. Not "running action": in a walking game, a reader takes "running" literally. |
| **waiting action** | An action in the queue after the current action. Waiting actions start one by one. |
| **queue slot** | A place in the queue. The queue has 5 queue slots (`queueSlots` in `economy.json`). Each action takes one queue slot, a walk too. |
| **walk** | A travel action: the character moves to another place. Players see "Walk to", "Walking to" and "Walked to". The code name stays `Activity.travel`. Not also "trip" or "travel". |
| **needed walk** | A walk that the action after it needs. The player cannot remove it or stop it. |
| **stage** | One part of a walk: one route, walked once. The walk from Camp to Grey Moor has two stages. Not "leg" (the code name is `leg`). |
| **route** | The fixed connection between two neighbouring places, with its steps (`routes` in `world.json`). |
| **place** | An area on the World map, such as Camp or Grey Moor. Not "node": in the data, a node is a gathering spot. |
| **end place** | The place at the end of the queue (spec 0016). |
| **unit** | One finished part of an action: one fight, one gathered item or one craft. Stop conditions are checked after each unit. |
| **stop condition** | The rule that ends an action, such as "Until I have N" or "Until N crafted". |
| **change sheet** | The sheet that opens on a tap on the current action (spec 0016). |

## The world

| Word | Meaning |
|---|---|
| **Camp** | The place where the game starts. It has the forge, the camp fire, the item bank, the teachers and the trainer. |
| **explored** | A place where the player has stood. |
| **fog** | The cover over a place that is not explored and not next to an explored place. |
| **closed road** | A route that stays shut until a boss falls. The Graveyard King closes the road across the river (intent 0022). |
| **gathering spot** | A place to gather one kind of material, such as a vein or a fishing spot. Code name: node. Short form: spot. |
| **spot tip** | A line that tells what lives at a spot, in the game's voice (spec 0010 amendment 8). |
| **story** | A short text that a place tells on the first visit. It shows on the story card. |

## The character and the professions

| Word | Meaning |
|---|---|
| **character level** | The level of the character, from fight XP. |
| **origin** | The start story that the player picks on a new game, one for each profession (spec 0012). |
| **head start** | Level 5 in the profession of the origin, learned from the start (`headStartLevel`). |
| **profession** | A skill with its own level. Gathering professions: Mining, Woodcutting, Fishing, Hunting. Crafting professions: Crafting, Cooking. |
| **profession level** | The level of one profession, from the XP of its actions. |
| **unlock level** | The profession level that a gathering spot or a recipe needs. |
| **profession tier** | A band of profession levels. New tiers open at profession level 10 and 20. |
| **teacher** | The person at Camp who teaches one profession. There are six. |
| **recipe** | A rule that turns materials into an item, with its steps and its unlock level. |
| **forge** | The place for salvage and reroll, at Camp, Grey Moor and Mountain Pass. |
| **camp fire** | The only place where the character cooks. |
| **rare find** | A rare extra item from a gathering action, such as the golden antler (`rareFind` in `economy.json`). |
| **message in a bottle** | A rare find of each cast at any water (spec 0011). |
| **perfect dish** | A meal that rolls stronger or longer lasting when the character cooks it (spec 0011). |
| **talent** | A rank that the player buys with talent points in a talent tree (spec 0015). |
| **talent tree** | One of the two sets of talents: Combat and Utility. |
| **trainer** | Ysolde, at Camp. She resets the talents. The first reset is free; later resets cost steps. |
| **path** | One talent in a talent tree, drawn as a plate with an image, a name and one line. |
| **pip** | One rank of a talent, drawn as a small dot. A taken rank is filled. |

## Items, the bag and the bank

| Word | Meaning |
|---|---|
| **gear** | An item that the character wears in a gear slot. |
| **gear slot** | A place on the Gear page for one worn item, such as Head or Ring 1. The Gear page has 16. |
| **one-hander** | A weapon for the main hand. The off hand stays free for a shield. |
| **two-hander** | A weapon that takes both hands. It hits harder than the one-hander of its gear tier. |
| **tool** | An item that a profession uses, such as a hatchet. |
| **material** | An item that recipes use, such as oak logs or copper ore. |
| **meal** | A cooked item that the character eats for a buff. |
| **buff** | A bonus for a number of steps, such as the bonus of a meal. |
| **auto-eat** | The meal that the character eats by itself when the last meal runs out. |
| **item level** | The level of an item. It sets the stat tier of the item. |
| **quality** | The grade of a piece of gear or a tool: Common, Uncommon, Rare, Epic or Legendary. Each quality has its own colour. Materials and meals have no quality. |
| **quality step** | The number of qualities above Common: 0 for Common, 4 for Legendary. Spec 0005 says "tier" for it. |
| **bonus stat** | An extra stat on an item, rolled at random. An item can have the same bonus stat more than once. |
| **gear tier** | The material band of gear, such as copper, bone or iron. Each gear tier has its own set of weapons. |
| **stat tier** | The band of item levels that sets which bonus stats an item can roll: tier 1 up to level 9, tier 2 for 10–19, tier 3 from 20 (spec 0009). |
| **unique item** | The one item of a boss, made from 10 boss shards of that boss. |
| **bag** | The items that the character carries. |
| **space** | A place in the bag for one stack. The bag has 40 spaces (`bag.spaces` in `economy.json`). |
| **stack** | Items of one kind in one space. |
| **stack size** | The most items of one kind that one space holds (`bag.stacks` in `economy.json`). |
| **overloaded** | The state of a bag that uses more spaces than it has. Actions out in the world then cost more steps. |
| **item bank** | The store of items at Camp. Code name: `itemBank`. Not the step bank. |
| **selection** | The items that the player picked in the bag or the bank for one action. A hold on an item starts it (spec 0020 amendment 8). |
| **selection bar** | The bar at the bottom of the screen while a selection runs: ×, the number of selected items and the actions. |
| **salvage** | To break spare gear into dust at a forge. |
| **dust** | The result of a salvage, in the quality of the item: Uncommon dust, for example. |
| **reroll** | To spend 3 dust at a forge for a new quality roll on an item. |
| **boss shard** | A rare result of a salvage. 10 shards of one boss make the unique item of that boss. |
| **destroy** | To remove an item from the game for good (spec 0021 amendment 2). |

## Fights and monsters

| Word | Meaning |
|---|---|
| **monster level** | The level of a monster. Its colour comes from the monster level minus the character level. |
| **colour** | The band of a monster by its level: skull, red, orange, yellow, green or grey (spec 0002 §3). |
| **XP fade** | Less XP from a monster, spot or recipe below the character level: green fades, grey gives 5% (spec 0002). |
| **Low XP** | The label on a grey monster row (spec 0002 amendment 2). |
| **boss** | A strong monster with its own unique item. The Graveyard King, for example. |
| **lurker** | A monster far above the level of its place, such as the Old Bear in Goblin Woods (spec 0002 §5.4). |
| **trait** | A rule of a monster: quick, slow, ghostly or regenerates. |
| **damage type** | The way that a weapon hits: slash, pierce or crush (`damageType` in `items.json`). |
| **monster armour** | How light or heavy a monster's armour is. It makes one damage type strong or weak against the monster. Not an armour item. |
| **stats** | HP, Attack, Defense, Hit, Crit, Dodge and Block. |
| **round** | One exchange of hits in a fight. |
| **round log** | The rounds of the latest fight of the current fight action (spec 0019). |
| **fight summary** | The short record of one finished fight (spec 0019). |
| **loss** | A lost fight. It gives part of the XP. Three losses in a row end the action. |
| **achievement** | A goal with a reward, in two kinds: milestone and feat. Players see "Trophies". |
| **milestone** | An achievement on the way through the game. Its reward is a bigger step bank or an item. Not a plan milestone. |
| **feat** | An achievement that costs a long grind or a long chase for luck. |
| **trophy piece** | Gear made from the drops of a monster, such as a pelt or a tusk. Not the trophy button. |

## Screens and looks

Most of these words come from the Quiet Teal look (spec 0014).

| Word | Meaning |
|---|---|
| **tab** | One of the four pages of the bottom bar, such as Now or World. |
| **top bar** | The bar at the top with the trophy button, the Journal button, the Bank button and Settings. |
| **trophy button** | The button in the top bar that opens the achievements. Not a trophy piece. |
| **away report** | The page that tells what happened while the app was closed (spec 0004). |
| **Journal** | The list of past reports and events (spec 0004). |
| **level-up card** | The card that tells of a new level, at app open. |
| **story card** | The card on Now with the story of the place (spec 0008 amendment 6). |
| **"New in Itheros" card** | The card with the release notes after an update (spec 0018). |
| **Camp tour** | The cards that show a new player around Camp, with the guide Odda (spec 0022). |
| **case** | The black background of the app. |
| **plate** | A dark panel with round corners and a thin teal line. Cards, sheets, dialogs and the bars stand on plates. |
| **sheet** | A panel that slides up from the bottom of the screen, such as the monster sheet. |
| **card** | A panel with the details of one thing, such as the item card. |
| **socket** | The dark square that holds the image of a thing. |
| **quality ring** | The 2 dp line in the quality colour around the socket of gear or a tool. Materials and meals have none. |
| **map ring** | The teal circle that marks the current place on the World map and on the route map. Nothing else marks it. |
| **wash** | A light fill in the quality colour inside the socket. Uncommon and higher have one. |
| **flush** | With no gap. The map ring sits flush around the marker of the place. |
| **badge** | A small mark on the corner of a socket, such as the count "×14" or a level. |
| **chip** | A small button that filters a list or picks an option. A selected chip is lit. |
| **lit** | The lighter slate of a selected tab or chip. |
| **placeholder** | The image that shows when a thing has no picture yet. Not "fallback" or "stand-in". |

## The pace and the sims

| Word | Meaning |
|---|---|
| **pace** | How fast a player at 5,000 steps a day moves through the levels (`docs/game-direction.md`). |
| **sim** | A run of the game on made-up days of steps, with a walker as the player. |
| **walker** | The simulated player in the sims (`packages/game_core/lib/simulation.dart`). |
| **reference player** | A simple player that the sims use as a yardstick (spec 0002). |
| **seed** | The start number of the random generator. A sim runs on many seeds and reports the median. |
| **pacing test** | The test (tag `pacing`) that runs the sims and checks the targets of the specs. |
| **profession stream** | The second random generator in the save. Profession results use it (spec 0010). |

## The way we work

| Word | Meaning |
|---|---|
| **owner** | Zkalf, the product owner. Only the owner accepts texts, merges and releases. |
| **intent** | A text that tells what the player misses and why it matters (`intent/`). |
| **spec** | A text with the decisions and the acceptance criteria of a change (`specs/`). |
| **acceptance criterion** | One numbered check in a spec that the change must pass. |
| **amendment** | A new file that changes an accepted intent, spec or plan. |
| **erratum** | A new file that fixes a mistake in an accepted file. |
| **clean edition** | A clearer copy of an accepted text, with every fact and number kept (`WRITING.md`). |
| **plan** | A text with the milestones of a change and their proof (`plans/`). |
| **plan milestone** | One step of a plan. It ends with its proof and a commit. Not an achievement milestone. |
| **proof** | What shows that a plan milestone works: a test, a check or a screenshot. |
| **draft** / **accepted** | The two values of the `Status:` line. An accepted file never changes. |
| **fast lane** | The path for a change of only config, docs or wording: a commit, no pull request (`CLAUDE.md`). |
| **check** | `scripts\check.ps1`: format, analyze and tests. "Green" means that it passes. CI runs the same check. |
| **production gate** | The hook that blocks Claude from a release, a merge and a push to `main` (plan 0009). |
| **verifier** | The subagent that checks a change against the acceptance criteria of its spec. |
| **eval** | A real task that headless Claude does, graded by a script (`evals/README.md`). |
| **incident record** | The record of a problem from real use (`incidents/`). |
| **fixture save** | A save from a release in `app/test/fixtures/saves/`. The tests load each one. |
| **owner's build** | The APK for the owner's phone, with the test walk (`check.ps1 -Release`). |
| **friend APK** | The APK of a release, without the test walk (`release.ps1`). |
| **notes file** | The file of one change in `releases/next/`, with lines for players. |
| **final notes** | The pull request that joins the notes files into `releases/next.md` before a release. |
| **x.y.z** | The parts of a version: x for 1.0, y for something new to play, z for fixes only (`RELEASING.md`). |
| **worktree** | A second folder of the repo for a change in a parallel session (`scripts\new-worktree.ps1`). |
| **idea**, **parked**, **nit**, **bug** | The labels of the GitHub issues. Each idea also has **soon** or **later** (`CONTRIBUTING.md`). |

## Words with more than one meaning

Accepted texts keep their words. New texts use the names in the right-hand column, so each name has one meaning.

| Old word | Meaning | New name |
|---|---|---|
| **slot** | a place in the queue | **queue slot** |
| | a place on the Gear page | **gear slot** |
| **ring** | the line in the quality colour around a socket | **quality ring** |
| | the teal circle on the current place | **map ring** |
| **tier** | a material band of gear (copper, bone, iron) | **gear tier** |
| | a band of item levels for bonus stats (spec 0009) | **stat tier** |
| | the number of qualities above Common (spec 0005) | **quality step** |
| | a band of profession levels (spec 0012) | **profession tier** |
| **milestone** | a kind of achievement | **milestone** |
| | one step of a plan | **plan milestone** |
| **armour** | how light or heavy a monster's armour is | **monster armour** |
| | a body item, such as Troll-hide armour | the name of the item |
| **trophy** | the button for the achievements | **trophy button** |
| | gear from the drops of a monster | **trophy piece** |
| **level** | of the character, a profession, an item, a monster, a spot or a recipe | **character level**, **profession level**, **item level**, **monster level**, **unlock level** |
| **area** | a place on the map | **place** |
| **bank** | the store of steps, or the store of items | **step bank** or **item bank** |

## Words that we do not use

- **edge**: graph theory names a route an edge. This word brings "node" with it, and "node" already means a
  gathering spot.
- **step**, as a part of a walk: steps are what the player walks and pays with. Use **stage**.
- **running action**: use **current action**.
- **trip** or **travel**, for a walk: use **walk**.
