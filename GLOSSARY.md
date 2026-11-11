# Glossary

This file lists the words that the specs, plans and designs of Itheros use. Each word has one meaning
(`WRITING.md` rule 1). The code name is given where it is different.

- A new spec, amendment, plan or design that brings a new word adds it here, in the same pull request.
- A word that players see in the game belongs to its spec (see `WRITING.md`). This file only explains it.

## Steps and days

| Word | Meaning |
|---|---|
| **step** | One step that the player walks, read from Health Connect. Steps pay for every action. |
| **step bank** | The store of steps walked while the character has no action. It has a cap. Steps over the cap are lost. Code name: `stepBank`. |
| **sync** | The read of new steps from Health Connect into the game. Steps count per local day. |
| **test walk** | Pretend steps that a button adds, as if walked (spec 0004). A hidden switch turns the button on. |
| **supply chest** | The reward for a day with at least 5,000 steps spent on actions (spec 0013). |

## The queue and walks

The owner and Claude chose these words on 2026-10-24, after the playtest of the queue rework (spec 0016).

| Word | Meaning |
|---|---|
| **current action** | The action that the character does now. It is number 1 on the queue card. Not "running action": in a walking game, a reader takes "running" literally. |
| **waiting action** | An action in the queue after the current action. Waiting actions start one by one. |
| **slot** | A place in the queue. The queue has 5 slots (`queueSlots` in `economy.json`). Each action takes one slot, a walk too. For the places of worn gear, see **gear slot**. |
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
| **explored** | A place where the player has stood. |
| **fog** | The cover over a place that is not explored and not next to an explored place. |
| **gathering spot** | A place to gather one kind of material, such as a vein or a fishing spot. Code name: node. Short form: spot. |
| **spot tip** | A line that tells what lives at a spot, in the game's voice (spec 0010 amendment 8). |

## Items, the bag and the bank

| Word | Meaning |
|---|---|
| **gear** | An item that the character wears in a gear slot. |
| **gear slot** | A place on the Gear page for one worn item, such as Head or Ring 1. The Gear page has 16. |
| **tool** | An item that a profession uses, such as a hatchet. |
| **material** | An item that recipes use, such as oak logs or copper ore. |
| **meal** | A cooked item that the character eats for a buff. |
| **quality** | The grade of a piece of gear or a tool, from Common up. Each quality has its own colour. Materials and meals have no quality. |
| **bonus stat** | An extra stat on an item, rolled at random. An item can have the same bonus stat more than once. |
| **tier** | The material band of gear, such as copper, bone or iron. Each tier has its own set of weapons. The tier sets which bonus stats an item can roll. |
| **bag** | The items that the character carries. |
| **space** | A place in the bag for one stack. The bag has 40 spaces (`bag.spaces` in `economy.json`). |
| **stack** | Items of one kind in one space. |
| **stack size** | The most items of one kind that one space holds (`bag.stacks` in `economy.json`). |
| **overloaded** | The state of a bag that uses more spaces than it has. Actions out in the world then cost more steps. |
| **item bank** | The store of items at Camp. Code name: `itemBank`. Not the step bank. |
| **salvage** | To break spare gear into dust at a forge. |
| **dust** | The result of a salvage, in the quality of the item: Uncommon dust, for example. |
| **reroll** | To spend 3 dust at a forge for a new quality roll on an item. |
| **boss shard** | A rare result of a salvage. 10 shards of one boss make the unique item of that boss. |

## Fights and levels

| Word | Meaning |
|---|---|
| **round** | One exchange of hits in a fight. |
| **round log** | The rounds of the latest fight of the current fight action (spec 0019). |
| **fight summary** | The short record of one finished fight (spec 0019). |
| **XP fade** | Less XP from a monster, spot or recipe far below the player's level (spec 0002). |
| **milestone** | An achievement on the way through the game. Its reward is a bigger step bank or an item. |
| **feat** | An achievement that costs a long grind or a long chase for luck. |
| **talent** | A rank that the player buys with talent points in a talent tree (spec 0015). |
| **path** | One talent in a talent tree, drawn as a plate with an image, a name and one line. |
| **pip** | One rank of a talent, drawn as a small dot. A taken rank is filled. |

## Screens and looks

These words come from the Quiet Teal look (spec 0014).

| Word | Meaning |
|---|---|
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

## Words for the specs

| Word | Meaning |
|---|---|
| **reference player** | A simple player that the pacing sims use as a yardstick (spec 0002). |
| **walker** | The simulated player in the pacing sims (`packages/game_core/lib/simulation.dart`). |
| **profession stream** | The second random generator in the save. Profession results use it (spec 0010). |

## Words with two meanings in older texts

Accepted texts keep their words. New texts use the longer names below, so each name has one meaning.

| Word | Meaning 1 | Meaning 2 |
|---|---|---|
| **slot** | **queue slot**: a place in the queue | **gear slot**: a place on the Gear page |
| **ring** | **quality ring**: the line in the quality colour around a socket | **map ring**: the teal circle on the current place |

## Words that we do not use

- **edge**: graph theory names a route an edge. This word brings "node" with it, and "node" already means a
  gathering spot.
- **step**, as a part of a walk: steps are what the player walks and pays with. Use **stage**.
- **running action**: use **current action**.
- **trip** or **travel**, for a walk: use **walk**.
- **area**, for a place: older specs use it. New texts use **place**.
- **bank**, alone: say **step bank** or **item bank**.
