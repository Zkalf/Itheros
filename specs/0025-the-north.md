# Spec 0025: Role-play and quests, chapters 2 and 3: the north of the river

Status: accepted
Intent: [intent/0025-the-north.md](../intent/0025-the-north.md) (accepted, 2026-11-18)
Builds on: spec 0023 (people, lines, lore pages, lore achievements), spec 0024 (quests, the quest card), spec 0010 §6
(the teachers), spec 0015 §2.7 (the trainer), spec 0017 (achievements)
Product owner: Zkalf (accepted on 2026-11-18)
Date: 2026-11-18

The north of the river gets its story. Four new people live at Grey Moor, Troll Bridge, Mountain Pass and Dragon's
Peak. Thirty-four quests lead the hero over the moor and the bridge to the Ogre Chieftain, then up the pass to the
Young Dragon. On the way the hero learns that Corvin, the master of the Guild lodge, wants the dragon caught alive.
The dragon falls, and a last page hints that something bigger once lived on the Peak.

## 1. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | The chapters | **Two chapters** (owner, intent 0025). Chapter 2, **"Paid in Old Gold"**, ends at the first Ogre Chieftain kill. Chapter 3, **"The Cage on the Peak"**, ends at the first Young Dragon kill (Claude). |
| 2 | The story | **The cage** (owner): Corvin, the lodge master, wants the dragon alive. His men's hammers woke it (§2.1). |
| 3 | The new people | **Maud, Tobin, Corvin and Nessa** (Claude, §2.2). No name is taken in the data. |
| 4 | Where chapter 2 starts | **After `odda_king`** (Claude, intent open question 1). Data only. An old hero first does the quests of chapter 1, quickly (spec 0024 decision 5). |
| 5 | The twist in time | **Hints first, the truth at the Peak** (Claude, intent open question 2). The bridge and the Chieftain's hoard point up the pass "to the lodge". Corvin stays friendly until Nessa tells the truth (`nessa_wyverns`, `nessa_2`). Then his own lines change. |
| 6 | The old gold | **The King's war chest** (Claude, intent open question 3): lost in the pass a hundred years ago, among the wraiths. Corvin found it and pays with it. |
| 7 | The quests | **34: 17 for each chapter** (owner, intent 0025). Each chapter has a main line of 6 quests to its boss and 11 side quests (§2.8). |
| 8 | Visit quests | **None in the north** (Claude). A visit quest is handed in where it was taken, so it costs a walk back. The quest card names the next giver and their place instead (spec 0024 §3.1). |
| 9 | The quest XP | **36,600 XP for the 34 quests** (Claude, §5): about 8% of the XP from level 11 to 20 and about 6.5% of the XP from level 20 to 30. |
| 10 | Camp after each boss | **A Camp line for each boss** (owner): each teacher and Ysolde get a line after the first Chieftain kill and after the first Young Dragon kill (§2.4). A small rule change. |
| 11 | The end words | **They move into data** (Claude): "The dragon is dead, and the lands are quiet. For now." (§2.9). A small rule change. |
| 12 | Iron Ridge and Mithril Deep | **Lore pages and a lore achievement, no person** (owner, intent 0025 outcome 7). |
| 13 | Lore achievements | **One for each north place** (intent 0025 outcome 19), as in the south: a milestone with +250 bank cap (§2.7). |

## 2. Rules

### 2.1 The story
- **Chapter 2, "Paid in Old Gold":** Grey Moor, Iron Ridge and Troll Bridge.
  - Maud, the warden of the Grey Moor outpost, got Odda's letter with the King's last words.
  - The bandits rob every Guild cart on the ridge road, but they let the sealed crates for "the high road" pass.
  - Tobin, a carter at Troll Bridge, hauled an iron cage over the bridge. The Chieftain took old gold for it.
  - The Chieftain's hoard holds old crowns with the King's face, and a scrap of the toll book: the cage was sealed
    at the lodge.
- **Chapter 3, "The Cage on the Peak":** Mountain Pass, Mithril Deep and Dragon's Peak.
  - Corvin, the lodge master, welcomes the hero. He asks for help with the golems, the harpies and the road. He
    calls his men on the Peak "surveyors".
  - In the pass, the hero finds the King's war chest, broken open and empty. Boot prints lead down to the lodge.
  - On the Peak, Nessa, the dragon-hunter's granddaughter, tells the truth: the lodge men came with hammers, chains
    and a cage. The dragon slept a hundred years, held by the King. The King fell, and the hammers woke it fully.
  - Corvin admits it: a live dragon would make him greater than kings.
  - The hero kills the Young Dragon. Corvin's plan fails. Odda says that the Guild will deal with him.
- **The hook:** behind the dragon's bed lies a shed scale ten times the size of its own (`page_old_scale`).
- **How it ties to chapter 1:**
  - The dragon's first stir woke the King (spec 0023 decision 2). The stir came from the hammers on the Peak.
  - The goblins flee south from the dragon (`pell_2`).
  - Jory's crates for the Peak are Corvin's (`jory_2`, `page_captains_log`). Jory sells that secret in `jory_seal`.
  - The old gold is the King's (`page_jory`: "Ask the King").
  - The hunter's book goes on: the hunter came home with the eleven, went north again alone and never came back
    (`page_hunter_5` to `page_hunter_7`, then the note "The dragon-hunter's last page" of today).

### 2.2 People
- Four new people (spec 0023 §2.1), with lines in `data/story.json`:

| Id | Name and title | Place | Who they are |
|---|---|---|---|
| `maud` | Maud, the warden | Grey Moor | She keeps the Guild outpost on the moor. Hard and tired, and she lights the watch-fires every night. |
| `tobin` | Tobin, the carter | Troll Bridge | He hauls goods over the bridge and pays the Chieftain's toll. Nervous and honest. He hauled the cage. |
| `corvin` | Corvin, the lodge master | Mountain Pass | The master of the Guild lodge. Warm, generous and proud. He is the buyer of the cage. |
| `nessa` | Nessa, the dragon-watcher | Dragon's Peak | The dragon-hunter's granddaughter. She lives on the Peak and watches the dragon, as her mother did. |

- No other character in the data has these names. The data test of spec 0023 criterion 8 covers them.
- Each gets a flat SVG portrait by Claude (`art/people.py`), in the style of the eleven portraits of today.
- A person's row stands first under Here at their place (spec 0023 §3.1). None of the four places is hidden.

### 2.3 Lines
The lines work as in spec 0023 §2.2-§2.3. New lines go at the end of each person's list, so the newest open line
stays on top.

### 2.4 Camp lines (a rule change)
- A **Camp line** is a line of a teacher or the trainer that opens after a deed. The King lines of spec 0023 §2.5
  are the first Camp lines.
- Today each teacher and the trainer hold one Camp line. From this spec, each holds a list, in data order.
- The newest open Camp line takes the place of the greeting at the top of the sheet. For the teacher of the hero's
  origin, it takes the place of the kin line.
- An open Camp line that is not heard puts a dot on the row (spec 0023 §2.5), unless a quest mark wins (spec 0024
  §2.6).
- When the sheet opens, every open Camp line of that teacher or the trainer becomes heard.
- The sheet shows only the newest Camp line. An older Camp line does not show again.
- The learn line, Learn and the tips stay as they are.

### 2.5 Lore pages
The pages work as in spec 0023 §2.4: the same sources, the same `pageChance` of 1% for a find, the same derived
generator.
- The find of Dragon's Peak comes only from fights, because the Peak has no spots.
- The finds of Iron Ridge and Mithril Deep come only from gathering, because these places have no monsters.

### 2.6 The lore of the north
The lore of a place is its pages and the lore notes about its monsters (spec 0023 §2.6). The notes stay as they are.

| Place | Pages | Notes about its monsters |
|---|---|---|
| Grey Moor | 3 | Wolf pelts (Wolf), Mist on the moor (Ghost), Wanted poster (Bandit) |
| Iron Ridge | 2 | none |
| Troll Bridge | 4 | Stolen map (Giant spider), Silk-wrapped letter (Troll), Toll receipt (Ogre Chieftain) |
| Mountain Pass | 3 | Chieftain's boast (Stone golem), Mason's warning (Harpy), Feather quill note (Wraith) |
| Mithril Deep | 2 | none |
| Dragon's Peak | 4 | Cold letter (Wyvern), Scorched page (Fire drake), The dragon-hunter's last page (Young Dragon) |

### 2.7 Lore achievements
Each is a milestone with +250 bank cap and the criterion `{ "lore": "<place>" }` (spec 0023 §2.6).

| Id | Name | Stage | Place | Lore |
|---|---|---|---|---|
| `lore_grey_moor` | Moor Tales | mid | Grey Moor | 3 pages, 3 notes |
| `lore_iron_ridge` | Bandits' Ledger | mid | Iron Ridge | 2 pages |
| `lore_troll_bridge` | Toll Paid | mid | Troll Bridge | 4 pages, 3 notes |
| `lore_mountain_pass` | Lodge Secrets | late | Mountain Pass | 3 pages, 3 notes |
| `lore_mithril_deep` | Silver Dark | late | Mithril Deep | 2 pages |
| `lore_dragons_peak` | Dragon Lore | late | Dragon's Peak | 4 pages, 3 notes |

### 2.8 The quests
The quests work as in spec 0024 §2.1-§2.6. The table order is the order of `data/quests.json`, after the 17 quests
of chapter 1. Each chapter lists its main line first, so the quest card names the next giver of the main line
(spec 0024 §3.1).

**Chapter 2: Paid in Old Gold**

| Id | Giver | Title | After | Task | XP |
|---|---|---|---|---|---|
| `maud_wolves` | Maud | The moor bites | `odda_king` | Kill 40 wolves | 400 |
| `maud_ghosts` | Maud | The pale ones | `maud_wolves` | Kill 40 ghosts | 500 |
| `maud_bandits` | Maud | Robbers on the ridge | `maud_ghosts` | Kill 50 bandits | 600 |
| `tobin_spiders` | Tobin | Webs on the arches | `maud_bandits` | Kill 40 giant spiders | 700 |
| `tobin_trolls` | Tobin | Under the bridge | `tobin_spiders` | Kill 30 trolls | 900 |
| `tobin_chieftain` | Tobin | Paid in Old Gold | `tobin_trolls` | Kill the Ogre Chieftain | 2,000 |
| `maud_vest` | Maud | Wind off the moor | `maud_wolves` | Wear a wolf-pelt vest | 400 |
| `maud_lamps` | Maud | Pale fire | `maud_ghosts` | Bring 10 ectoplasm | 500 |
| `odda_pelts` | Odda | Coats for the Guild | `odda_king` | Bring 15 wolf pelts | 450 |
| `hilde_iron` | Hilde | Dark stone | `odda_king` | Gather 30 iron ore | 350 |
| `bram_ash` | Bram | Ash for the hafts | `odda_king` | Gather 30 ash logs | 350 |
| `sigrun_elk` | Sigrun | Elk on the moor | `odda_king` | Gather 15 elk meat | 350 |
| `wen_trout` | Wen | Trout under the bridge | `maud_bandits` | Gather 20 brown trout | 450 |
| `marta_roast` | Marta | A roast for the road | `sigrun_elk` | Cook 5 elk roasts | 400 |
| `garrow_helm` | Garrow | Iron for your head | `hilde_iron` | Craft 1 iron helm | 450 |
| `tobin_silk` | Tobin | Rope for the cart | `tobin_spiders` | Bring 12 silk | 600 |
| `garrow_troll` | Garrow | A coat that closes | `tobin_trolls` | Wear troll-hide armour | 700 |

**Chapter 3: The Cage on the Peak**

| Id | Giver | Title | After | Task | XP |
|---|---|---|---|---|---|
| `corvin_golems` | Corvin | Stones that walk | `tobin_chieftain` | Kill 15 stone golems | 1,200 |
| `corvin_cores` | Corvin | Walls for the lodge | `corvin_golems` | Bring 8 stone cores | 1,300 |
| `corvin_harpies` | Corvin | Claws from the sun | `corvin_cores` | Kill 30 harpies | 1,500 |
| `nessa_wyverns` | Nessa | The lodge men | `corvin_harpies` | Kill 35 wyverns | 1,800 |
| `nessa_drakes` | Nessa | Fire on the slopes | `nessa_wyverns` | Kill 30 fire drakes | 2,200 |
| `nessa_dragon` | Nessa | The Cage on the Peak | `nessa_drakes` | Kill the Young Dragon | 5,500 |
| `corvin_wraiths` | Corvin | The dead of the pass | `corvin_golems` | Kill 30 wraiths | 1,500 |
| `corvin_feathers` | Corvin | Soft beds | `corvin_harpies` | Bring 12 feathers | 1,300 |
| `nessa_ward` | Nessa | Against the fire | `nessa_wyverns` | Wear a fire-ward amulet | 1,500 |
| `odda_proof` | Odda | Proof for the council | `nessa_wyverns` | Bring 10 wyvern scales | 1,500 |
| `jory_seal` | Jory Tarr | The second secret | `tobin_chieftain` | Bring 6 troll hides | 1,000 |
| `hilde_mithril` | Hilde | Silver in the dark | `tobin_chieftain` | Gather 25 mithril ore | 1,000 |
| `bram_pine` | Bram | Pine from the pass | `tobin_chieftain` | Gather 25 pine logs | 1,000 |
| `wen_char` | Wen | The cold tarn | `tobin_chieftain` | Gather 15 arctic char | 1,000 |
| `sigrun_ibex` | Sigrun | Up on the crags | `tobin_chieftain` | Gather 15 ibex meat | 1,000 |
| `marta_soup` | Marta | Soup for cold days | `wen_char` | Cook 5 char soups | 1,000 |
| `garrow_mithril` | Garrow | A blade of silver | `hilde_mithril` | Craft 1 mithril sword | 1,200 |

- The main line of chapter 2 runs: `maud_wolves`, `maud_ghosts`, `maud_bandits`, `tobin_spiders`, `tobin_trolls`,
  `tobin_chieftain`.
- The main line of chapter 3 runs: `corvin_golems`, `corvin_cores`, `corvin_harpies`, `nessa_wyverns`,
  `nessa_drakes`, `nessa_dragon`.
- The gathering quests need their profession at the spot's level: Mining 10 for iron, Woodcutting 10 for ash,
  Hunting 10 for elk, Fishing 10 for trout, Mining 20, Woodcutting 20, Fishing 20 and Hunting 20 for the spots of
  chapter 3. A hero below that level sees the quest and can take it, as `jory_bass` today.
- The counts follow the rule of spec 0024: a side quest is about a day of walking at the quest's level, and a kill
  quest of the main line about a day too.
- No quest gates a place. The north stays open after the King (`docs/game-direction.md`).

### 2.9 The end words (a rule change)
- With every quest done, the quest card shows the end words from `data/quests.json` (`endWords`), not words in code.
- The end words: "The dragon is dead, and the lands are quiet. For now."
- Before this spec, a hero who finished chapter 1 saw "No more work for now. The north will need you." That hero
  now sees `maud_wolves` offered (decision 4), so the old words have no use.

### 2.10 The words
The words are a design decision (`WRITING.md`). The owner accepts them with this spec. `{name}`,
`{son|daughter|child}` and `{lad|lass|friend}` fill in as today (spec 0012).

**New lines of the people of chapter 1**

| Id | Condition | Gives | Line |
|---|---|---|---|
| `odda_4` | first visit to Grey Moor | | "Maud has my letter, then. Twenty years she's kept that moor for the Guild. If she says the road is bad, it's bad." |
| `odda_5` | first Chieftain kill | | "The bridge is free for the first time in my life. Maud writes that the crates went up the pass, to our own lodge. Corvin will know what's in them. Corvin knows everything." |
| `odda_6` | first Young Dragon kill | | "The dragon. Dead. I've written it three times, and it still looks wrong on the page. The Guild will deal with Corvin. Sit down, {name}. Eat something." |
| `pell_4` | first Young Dragon kill | | "The goblins went home, {name}. North, back where they came from. I never thought I'd miss the noise." |
| `aldous_4` | first Young Dragon kill | | "The graves are quiet. All of them. He held it a hundred years, and you finished it. He can rest now. So can I." |
| `jory_4` | first Chieftain kill | | "The bridge is free, the toll is gone, and my crates? Nobody wants them now. Bad times for an honest smuggler." |
| `jory_5` | first Young Dragon kill | | "A dead dragon. Do you know what a dragon's scale sells for, friend? No? Then you'll sell me yours cheap." |

**Maud, the warden (Grey Moor)**

| Id | Condition | Gives | Line |
|---|---|---|---|
| `maud_1` | none | | "You're Odda's {lad|lass|friend}? Good. The moor eats people who walk it alone. Wolves by day, the pale ones by night, and bandits whenever they like." |
| `maud_kin` | origin: hunter's apprentice | | "A hunter's apprentice. Then read the tracks on the moor: everything runs south. Even the wolves look over their shoulders." |
| `maud_2` | 50 Bandit kills | Maud's story | "Fifty bandits, and not one of them carried a crate for the high road. They rob our carts and wave those through. Someone pays them better than we do." |
| `maud_3` | first Chieftain kill | | "The Chieftain's dead, and the bridge is free. The carts roll again. Only the crates stopped. Funny, that." |
| `maud_4` | first Young Dragon kill | | "I lit every watch-fire on the moor tonight, {name}. Not for a warning. Just because." |

**Tobin, the carter (Troll Bridge)**

| Id | Condition | Gives | Line |
|---|---|---|---|
| `tobin_1` | none | | "Mind the arches, friend. Spiders up top, trolls down below, and the Chieftain in the middle with his hand out. I pay. Everybody pays." |
| `tobin_kin` | origin: miner's child | | "From the Copper Hills? My mother hauled ore out of there. You know a heavy load when you see one. I've hauled some heavy loads." |
| `tobin_2` | 30 Troll kills | Tobin's story | "All right. You've earned it. I hauled a cage over this bridge. Iron, big as a barn. The Chieftain counted the gold twice and waved me through." |
| `tobin_3` | first Chieftain kill | | "No toll! I crossed four times today just to feel it. Where the cage went? Up the pass, friend. To the lodge. I only drive the cart." |

**Corvin, the lodge master (Mountain Pass)**

| Id | Condition | Gives | Line |
|---|---|---|---|
| `corvin_1` | none | | "Welcome to the lodge, {name}! Warm beds, a hot forge and the best stew north of the river. The Guild's heroes never pay here. I insist." |
| `corvin_kin` | origin: tavern cook | | "A tavern cook! Then you'll forgive my stew. Take the kitchen whenever you like. A lodge lives on its cooks." |
| `corvin_2` | 30 Harpy kills | | "The mules move again, thanks to you. My men on the Peak will eat well this month. Surveyors, {name}. Brave men. Cold work." |
| `corvin_3` | 35 Wyvern kills | | "So the old woman on the Peak talks. Yes, a cage. Do you know what a live dragon is worth, {name}? Kings would bow to the man who owns one." |
| `corvin_4` | first Young Dragon kill | | "You killed it. The only one in the world, and you killed it. The Guild will send for me now. I hope it was worth it, {name}." |

**Nessa, the dragon-watcher (Dragon's Peak)**

| Id | Condition | Gives | Line |
|---|---|---|---|
| `nessa_1` | none | | "Another one from the lodge? No. You walk different. Keep your voice down. It sleeps lightly now." |
| `nessa_kin` | origin: smith's apprentice | | "Smith's hands. Good. My grandfather wrote that only crushing blows go through its scales. He didn't bring a hammer. Don't make his mistake." |
| `nessa_2` | 35 Wyvern kills | Nessa's story | "My grandfather went up to kill it and never came down. My mother watched it all her life, and now I do. It slept a hundred years. Then the lodge men came with hammers." |
| `nessa_3` | first Young Dragon kill | | "It's over. A hundred years of watching, and it's over. Come and see what I found behind its bed, {name}. Then tell me it's over." |

**The Camp lines after the Chieftain** (first Ogre Chieftain kill)

| Id | Who | Line |
|---|---|---|
| `chief_hilde` | Hilde | "The Chieftain? The ogres up north fear you now, {name}. Under the hills, we drink to that too." |
| `chief_bram` | Bram | "They say the bridge is free. I'd like to see the pines past it before I'm too old." |
| `chief_wen` | Wen | "Under the bridge the trout bite again. Ogres scare fish, you know. Everyone forgets that." |
| `chief_sigrun` | Sigrun | "An ogre is a big target. Still, you hit it where it hurt. Good." |
| `chief_garrow` | Garrow | "Layered leather and hide, they say, and you found the gaps. I'd have liked to see that." |
| `chief_marta` | Marta | "Ogre-slayer! I'll put something big on the fire, {name}. Something ogre-sized." |
| `chief_ysolde` | Ysolde | "Two bosses down. Feel the talents settle, {name}? That's the road under your feet." |

**The Camp lines after the dragon** (first Young Dragon kill)

| Id | Who | Line |
|---|---|---|
| `dragon_hilde` | Hilde | "A dragon. Under the hills they'll sing of you for a hundred years, {name}. Badly, but loud." |
| `dragon_bram` | Bram | "The woods are full of birds again. They came back first. I noticed." |
| `dragon_wen` | Wen | "The lake is so still this morning, {name}. As if it knows." |
| `dragon_sigrun` | Sigrun | "I taught you to walk soft. You walked soft all the way to a dragon. I'm proud of you." |
| `dragon_garrow` | Garrow | "Heavy as a cathedral door, the hunter wrote. And you broke it. Bring me a scale, {name}. Just one." |
| `dragon_marta` | Marta | "Dragonslayer at my fire! Sit. Eat. Nobody pays tonight, not even Jory." |
| `dragon_ysolde` | Ysolde | "Thirty levels, {name}, and a dragon at the top. Steps did that. Your steps." |

**The lore pages**

| Id | Place | Source | Title | Text |
|---|---|---|---|---|
| `page_odda_letter` | Grey Moor | first visit | Odda's letter | Pinned up in the outpost, in Odda's neat hand: "Maud: the King is down. His last words were 'it wakes'. Watch the high road. I'm sending {name}." |
| `page_hunter_5` | Grey Moor | a find | Hunter's book, page 5 | "Twenty years on, I go north again, alone. The King held it in his way. I mean to end it in mine." |
| `page_maud` | Grey Moor | line `maud_2` | Maud's story | What Maud told you: "The bandits rob every cart on the ridge road. All but the sealed crates for the high road. Those they wave through, hats off." |
| `page_bandit_ledger` | Iron Ridge | first visit | Bandits' ledger | A greasy book in a bandit camp: "Carts robbed: 31. Crates for the high road: let pass, by order. Paid in old crowns, the King's face on them." |
| `page_miners_slate` | Iron Ridge | a find | Miner's slate | Scratched on a slate by the vein: "Iron for chains. Forty fathoms, links thick as a wrist. Ordered from up the pass. No name given." |
| `page_toll_board` | Troll Bridge | first visit | Toll board | Carved over the arch: ONE TOLL. NO RETURNS. Under it, in fresh chalk: "Crates for the high road go free." |
| `page_hunter_6` | Troll Bridge | a find | Hunter's book, page 6 | "The ogres took my coin and laughed. The trolls took my mule. I went on with what I could carry." |
| `page_tobin` | Troll Bridge | line `tobin_2` | Tobin's story | What Tobin told you: "A cage, iron, big as a barn. Chains on a second cart. The Chieftain bit every coin. Old crowns, from before my grandmother was born." |
| `page_chieftains_hoard` | Troll Bridge | the first Chieftain kill | The Chieftain's hoard | Under the Chieftain's seat: a heap of old crowns with the King's face, and a scrap of the toll book: "Cage and chains, for the high road. Paid in full. Sealed at the lodge." |
| `page_lodge_book` | Mountain Pass | first visit | The lodge's guest book | On the first page: "Welcome to the Guild lodge. Warm beds, a hot forge and no questions. Corvin, lodge master." |
| `page_hunter_7` | Mountain Pass | a find | Hunter's book, page 7 | "The pass is full of our dead. They stand where they fell, in their shrouds, and still guard the King's war chest." |
| `page_war_chest` | Mountain Pass | 30 Wraith kills | The King's war chest | Behind the shrouded dead stands an iron chest with the King's seal. Its lock is broken, and it is empty. Fresh boot prints lead down to the lodge. |
| `page_deep_marks` | Mithril Deep | first visit | Chalk at the shaft | Chalked at the shaft head: "Mithril for the lodge. Forty bars, cast thick. What for? Don't ask, says the lodge master." |
| `page_lost_lamp` | Mithril Deep | a find | The lost lamp | A miner's lamp, its glass scratched by an old hand: "It sleeps above us. Dig quiet." |
| `page_cage` | Dragon's Peak | first visit | The empty cage | A cage of iron and mithril, as big as a barn, chained to the rock. Its door is torn off. Claw marks run down the bars. |
| `page_foremans_letter` | Dragon's Peak | a find | The foreman's letter | "To Master Corvin: the beast stirs under the hammers. The men won't go near it. Send more chain, or send us home." |
| `page_nessa` | Dragon's Peak | line `nessa_2` | Nessa's story | What Nessa told you: "The King held it asleep for a hundred years. When he fell, the hammers woke it. Corvin wanted it in a cage. Nothing that size goes in a cage." |
| `page_old_scale` | Dragon's Peak | the first Young Dragon kill | The old scale | Behind the dragon's bed lies a shed scale ten times the size of its own. Something far bigger once slept here. It may yet come home. |

**The quest words, chapter 2**

| Quest | Task words | Ask | Thanks |
|---|---|---|---|
| `maud_wolves` | Kill 40 wolves on Grey Moor | "Odda's letter says you're the one who put the King down. Good. The wolves come closer every night. Forty fewer, and my watch can sleep." | "Forty. The rest will think twice. And they're not hunting, {name}. They're running from something." |
| `maud_ghosts` | Kill 40 ghosts on Grey Moor | "The pale ones walk the moor at night. Old soldiers, some say, who never got home. Your armour won't help. Your blade will." | "Quieter now. Whatever they were waiting for, it isn't here. It's north." |
| `maud_bandits` | Kill 50 bandits on Grey Moor | "Bandits from the ridge rob every Guild cart on this road. Every cart but one kind. Fifty of them, {name}, and the road is ours again." | "Fifty, and their pockets full of old crowns. Odd coin for bandits. Go on to Troll Bridge. Tobin the carter knows the road past it." |
| `tobin_spiders` | Kill 40 giant spiders at Troll Bridge | "Maud sent you? Bless her. The spiders on the arches took my brother's mule last week. Forty of them, and I'll cross without looking up." | "Forty! I looked up anyway. Habit. Now the trolls, if you've the stomach for it." |
| `tobin_trolls` | Kill 30 trolls at Troll Bridge | "The trolls under the bridge mend as fast as you cut them. They take what the Chieftain leaves. Thirty of them, friend. Cut fast." | "Thirty. My knees are still shaking, and I only watched. That leaves the big one." |
| `tobin_chieftain` | Kill the Ogre Chieftain | "The Chieftain owns this bridge. Every cart pays, and some carts pay in old gold to go free. I never ask. Put him down, and nobody pays again." | "He's down! The bridge is free. The cage I hauled went up the pass, friend. Whatever it's for, it's up there now." |
| `maud_vest` | Wear a wolf-pelt vest | "The wind off this moor goes straight through Guild cloth. Six wolf pelts and a bit of grave cloth make a vest. Wear one." | "Better. Now you look like you live here." |
| `maud_lamps` | Bring Maud 10 ectoplasm | "The pale ones leave a glow behind them. It burns in a lamp, cold and blue, and they keep away from it. Ten, for the watch-fires." | "Cold light. Ugly, but it works. The moor will be darker for them tonight." |
| `odda_pelts` | Bring Odda 15 wolf pelts | "Maud writes that the moor is freezing, and my people up there wear Guild cloth. Fifteen wolf pelts, {name}, and I'll have coats made." | "Fifteen. That's coats for the whole outpost. Maud will pretend she's not grateful." |
| `hilde_iron` | Gather 30 iron ore on Iron Ridge | "Copper's for beginners. Past the moor there's a ridge of dark stone, heavy with iron. Thirty ore, {name}. Mind the bandits." | "Iron! Feel the weight of it. Keep it. Garrow will want a word." |
| `bram_ash` | Gather 30 ash logs on Grey Moor | "Ash grows on the moor, straight and tough. Best wood for a haft. Thirty logs, and don't let the wolves sniff your boots." | "Good straight ash. That'll hold a spearhead through anything." |
| `sigrun_elk` | Gather 15 elk meat on the moor tracks | "Elk walk the moor in herds. Fifteen cuts, {name}, and walk soft. An elk hears you before you hear yourself." | "Clean cuts. Take them to Marta. She has plans for them." |
| `wen_trout` | Gather 20 brown trout under the bridge | "Brown trout lie under Troll Bridge, fat as a fist. Twenty of them. The trolls won't mind. Probably." | "Twenty trout, and no troll bites. You're getting good at this." |
| `marta_roast` | Cook 5 elk roasts at the camp fire | "Elk meat? Then we roast. Five elk roasts at my fire, {name}. Slow and hot. The road north is cold." | "Smell that! Eat one before the bridge. You'll thank me." |
| `garrow_helm` | Make an iron helm at the forge | "Five iron ore makes a helm. Make one at any forge. Maud's outpost has one. Your head's worth it." | "Solid. Ugly, but solid. Like all good helms." |
| `tobin_silk` | Bring Tobin 12 silk | "Spider silk makes a rope that never breaks. My cart ropes are rotten. Twelve silk, friend, and I'll haul anything." | "Strong as iron. I'll haul your gear for free next time." |
| `garrow_troll` | Wear troll-hide armour | "Troll hide closes over its own cuts. Six of it and four leather make armour. Make it, wear it, show me." | "Now that's a coat. Cut it and watch it close." |

**The quest words, chapter 3**

| Quest | Task words | Ask | Thanks |
|---|---|---|---|
| `corvin_golems` | Kill 15 stone golems in Mountain Pass | "The hero of the bridge, at my lodge! The golems have blocked the mule road for a month. Fifteen of them, and my supplies move again." | "The road is open! Dinner is on the lodge tonight, {name}. It always is, for you." |
| `corvin_cores` | Bring Corvin 8 stone cores | "A golem's core is the hardest stone there is. Eight of them, and I'll shore up the lodge walls before winter." | "Splendid. Heavy, aren't they? They'll hold anything." |
| `corvin_harpies` | Kill 30 harpies in Mountain Pass | "The harpies dive on my mules from the sun. Thirty of them, {name}. My men on the Peak wait for their supplies. Look in on them, if you go up." | "The mules move again. If you go up to the Peak, tell my men that Corvin sends his best." |
| `nessa_wyverns` | Kill 35 wyverns on Dragon's Peak | "Corvin's men? They're gone. They built a cage for the dragon and woke it with their hammers. It ate the cage. Now the wyverns circle, because it's awake. Thin them, and we'll talk." | "Thirty-five. They'll come back while it's awake. Corvin never wanted it dead, you know. He wanted it for himself." |
| `nessa_drakes` | Kill 30 fire drakes on Dragon's Peak | "The drakes guard the way to its bed. Plated like knights and burning. My grandfather said to bring a hammer. Thirty of them, {name}." | "That's the last of the guard. Only the dragon now. Rest first." |
| `nessa_dragon` | Kill the Young Dragon | "Young for a dragon. Old for everything else. My grandfather came to finish it a hundred years ago. Finish it for him, {name}." | "It's dead. A hundred years of watching, done. Thank you, {name}. Now come and see what lies behind its bed." |
| `corvin_wraiths` | Kill 30 wraiths in Mountain Pass | "The dead of the pass, in their old shrouds. They guard something, the miners say. Thirty of them, and the pass is safe for everyone." | "Thirty! They guard nothing now. Nothing at all." |
| `corvin_feathers` | Bring Corvin 12 feathers | "Harpy feathers make the softest beds in the north. Twelve, {name}, and every guest of the lodge sleeps like a king." | "Wonderful. A king's bed for a king's... well. For a guest." |
| `nessa_ward` | Wear a fire-ward amulet | "Its breath melts iron. Three drake fangs and six feathers make a ward against fire. Wear one, or don't go near its bed." | "Good. Now the fire might not take you at once." |
| `odda_proof` | Bring Odda 10 wyvern scales | "Nessa's letter came. A Guild man, building a cage on the Peak. The council won't take my word against Corvin's. Bring me ten wyvern scales, burned black by the dragon's own fire." | "Proof. The council will read my letter now. Thank you, {name}. I wish it had been anyone but Corvin." |
| `jory_seal` | Bring Jory 6 troll hides | "Back from the north, friend? Still want to know who pays for my crates? Six troll hides. My new boat needs a hull that doesn't tear." | "Here's your secret: the crates are signed for at the Guild lodge on the pass. Old gold, and a Guild seal in the wax. Whose hand? I only sell what I know." |
| `hilde_mithril` | Gather 25 mithril ore in Mithril Deep | "Silver light in the dark, they say, and a long way down. Twenty-five mithril ore, {name}. Under the hills we'd give a beard for that." | "Mithril! Light as a feather, hard as a grudge. Keep it." |
| `bram_pine` | Gather 25 pine logs in Mountain Pass | "Pine from the high pass burns hot and long. Twenty-five logs, {name}. Watch for falling stones." | "Smell that resin. The camp fire will burn all week." |
| `wen_char` | Gather 15 arctic char at the cold tarn | "The cold tarn up the pass is clear as glass, and full of char. Fifteen, {name}. Keep your fingers out of the water." | "Fifteen, and all your fingers. The tarn was kind to you." |
| `sigrun_ibex` | Gather 15 ibex meat on the high crags | "Ibex climb where nothing else climbs. Fifteen cuts from the high crags, {name}. Don't look down." | "You looked down, didn't you? Everyone does. Good meat." |
| `marta_soup` | Cook 5 char soups at the camp fire | "Arctic char makes a soup that keeps you warm through a night on the ice. Five bowls, {name}, at my fire." | "Warm to the toes! Take some up the pass. You'll need it." |
| `garrow_mithril` | Make a mithril sword at the forge | "Eight mithril ore makes a sword that never dulls. Make one, {name}. Corvin's lodge has a good forge, I'm told." | "Look at that edge. I couldn't have made it better. Don't tell anyone I said so." |

## 3. Screens
- No new screen. The rows, sheets, quest marks, the quest card, the Lore tab and the achievements screen work as in
  specs 0023 and 0024.
- A teacher's sheet and Ysolde's sheet show the newest Camp line at the top (§2.4).
- The Lore tab gets a group for each north place, in the order of `world.json`, with "found N of M" (spec 0023
  §3.3).
- The quest card shows the end words of §2.9 when every quest is done.
- Before the PR, these are rendered at 408 dp wide (`CLAUDE.md`):
  - Now at Grey Moor with Maud's row;
  - Nessa's sheet with an offered quest;
  - Corvin's sheet after `corvin_3`;
  - a teacher's sheet with the Chieftain line;
  - the Lore tab with the north groups;
  - the quest card with the end words.
- The four new portraits differ in shape and colours from each other and from the eleven of today, so the player can
  tell all fifteen people apart at a glance.

## 4. Save
- No change. The save version stays 18.
- New quests, lines and pages use the save fields of today: `quests`, `heard` and `lore`.
- When an old save loads, the game gives each page whose source has happened: first visits and deeds (spec 0023 §4).
  A save with a Chieftain kill gets The Chieftain's hoard without a report.
- An old save that finished chapter 1 gets `maud_wolves`, `odda_pelts`, `hilde_iron`, `bram_ash` and `sigrun_elk`
  offered. Its old kills and finds do not count toward them (spec 0024 §2.3).
- Old saves see the dots of the lines that are open for their deeds.
- Each fixture in `app/test/fixtures/saves/` loads.

## 5. Balance
- The 34 quests give 36,600 XP and 34 supply chests in all.

| Chapter | XP of the quests | XP between its levels | Share |
|---|---|---|---|
| 2 (levels 11-20) | 10,100 | 125,230 (28,930 to 154,160) | 8.1% |
| 3 (levels 20-30) | 26,500 | 406,010 (154,160 to 560,170) | 6.5% |
| 1, 2 and 3 | 40,090 | 560,170 | 7.2% |

- The sim walker at 5,000 steps a day (seed 1, today) reaches level 11 on day 17, level 20 on day 53 and level 29 on
  day 99. It earns about 3,500 XP a day over the levels 11-20 and about 7,500 over the levels 20-29.
- So the quests of chapter 2 bring level 20 about 3 days sooner, and those of chapter 3 bring level 30 about 4 more
  days sooner. The owner's targets (mixed level 30 on day 80-100, fighter on day 80-120) do not move.
- 34 more chests come to about a third of the 80-100 daily chests on the way to level 30. The cost: more rolls of
  gear and shards, so a little more loot in the north.
- The sim walker takes no quests (spec 0024 §5). The pacing test in `check.ps1` stays the guard, and it stays green.
- One hand check before the PR: the walker's level on day 53 and day 99, with the XP of chapter 2 added when it
  reaches level 11 and the XP of chapter 3 added when it reaches level 20. Both stay inside the owner's targets.
- The sim walker never opens a sheet, so of the six new lore achievements it can earn only Bandits' Ledger and Silver
  Dark. The pacing test of spec 0017 §8 lets it miss the other four, as it does for the lore milestones of the south.

## 6. Out of scope
- The dragon's mother, as a monster or a place: only the hook (`page_old_scale`).
- New places, monsters, items, recipes or spots.
- Visit quests in the north (decision 8).
- Quests from Ysolde.
- Daily or repeated quests, choices, branches, timed quests and dropping a quest.
- A chapter title on screen: the chapter names live in the quests' titles and in this spec.
- Real art: nabriis can replace the portraits later.

## 7. Acceptance criteria

**People**
1. Maud's row shows first under Here at Grey Moor.
2. Tobin's row shows first under Here at Troll Bridge.
3. Corvin's row shows first under Here at Mountain Pass.
4. Nessa's row shows first under Here at Dragon's Peak.
5. Each of the four rows shows the person's portrait and their name and title.
6. No two characters in the data share a name (data test).
7. The four portraits differ from each other and from the eleven portraits of today.

**Lines**
8. Each new line opens when its condition first holds.
9. Each new origin line is open only for a hero of its origin.
10. A new line of Odda, Pell, Aldous or Jory stands after their lines of today, so it shows on top once open.
11. Corvin's sheet shows `corvin_3` at the top after 35 Wyvern kills.

**Camp lines**
12. Each teacher and Ysolde hold a list of Camp lines (data).
13. After the first Chieftain kill, each teacher's sheet and Ysolde's sheet show the Chieftain line at the top.
14. After the first Young Dragon kill, each sheet shows the dragon line at the top, not the Chieftain line.
15. An open Camp line that is not heard puts a dot on the row.
16. Opening the sheet makes every open Camp line of that teacher or Ysolde heard.
17. Before the first Chieftain kill, a sheet shows the King line or the greeting of today.
18. The learn line, Learn and the tips do not change.

**Lore pages**
19. The first visit to each north place gives its first-visit page.
20. The first Chieftain kill gives The Chieftain's hoard.
21. 30 Wraith kills give The King's war chest.
22. The first Young Dragon kill gives The old scale.
23. Hearing `maud_2`, `tobin_2` or `nessa_2` gives that person's story page.
24. The find of Dragon's Peak rolls after fights there; the finds of Iron Ridge and Mithril Deep roll after gathering
    there (seeded test).
25. The Lore tab shows a group for each north place, in the order of `world.json`, with "found N of M".

**Lore achievements**
26. Finding all the lore of a north place earns its achievement and +250 bank cap.
27. The six new achievements show on the achievements screen with their stage.

**Quests**
28. The data has 51 quests, and each `after` and each giver exists (data test).
29. The 34 new quests stand after the 17 of chapter 1, in the order of §2.8.
30. Handing in `odda_king` offers `maud_wolves`, `odda_pelts`, `hilde_iron`, `bram_ash` and `sigrun_elk`.
31. Handing in `tobin_chieftain` offers `corvin_golems`, `jory_seal`, `hilde_mithril`, `bram_pine`, `wen_char` and
    `sigrun_ibex`.
32. With every quest of chapter 1 done and no quest taken, the quest card says "Maud has work for you in Grey Moor".
33. The 34 new quests give 36,600 XP in all (data test).

**The end words**
34. With every quest done, the quest card shows the end words from `data/quests.json`.
35. The end words are "The dragon is dead, and the lands are quiet. For now."
36. No screen shows "The north will need you." any more.

**Save**
37. The save version stays 18.
38. An old save with a Chieftain kill gets The Chieftain's hoard on load, without a report.
39. An old save with `odda_king` done gets the five quests of criterion 30 offered.
40. Each fixture in `app/test/fixtures/saves/` loads.

**Screens**
41. The six screens of §3 are rendered at 408 dp wide before the PR (`CLAUDE.md`).

**Check and release**
42. Rules, numbers and the save change only as this spec says. The pacing test passes, and the hand check of §5
    stays inside the targets.
43. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

## History
- 2026-11-18: first version (intent 0025). Accepted.
