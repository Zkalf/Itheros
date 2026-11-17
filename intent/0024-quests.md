# Intent: Quests: the people of the south ask the hero for help

Status: accepted
Product owner: Zkalf (chose on 2026-11-17: quests replace "Next goal"; story quests teach what Next goal taught, with
no gear advice after them; the reward is XP and a supply chest; a quest counts deeds from the moment the player
takes it; the first build is the south of the river, chapter 1; accepted on 2026-11-17)
Date: 2026-11-17
Issue: #274

## Problem
Since spec 0023, people live in the world. Odda, Pell, Aldous and Jory Tarr talk to the hero, and the six teachers
and Ysolde react to the King's fall. But nobody asks the hero for anything:
- The player picks spots and grinds. No one in the world gives a reason to go to a place or to fight a monster.
- The only guide is "Next goal" on Now (spec 0002 §9.3). It is one dry line that the rules work out from the save:
  equip a better item, craft an upgrade, get the missing materials, or fight the monster with the most XP.
- "Next goal" has no voice. It does not belong to the story or to any person.

`docs/game-direction.md` takes the feel of the world from World of Warcraft: NPCs, flavour and quests. The owner
wants quests to replace "Next goal" (2026-11-17).

## Proposed outcome

### Quests from people
1. A **quest** is a request from a person: who asks, why, what to do and what the hero gets.
2. The people of the south give quests: Odda, the six teachers, Pell, Aldous and Jory Tarr.
3. A quest asks for something that the game counts today:
   - kill a number of one monster, or a boss;
   - bring a number of an item, from fights or from gathering;
   - gather at a spot;
   - craft or cook an item;
   - wear an item;
   - visit a place.
4. The player takes a quest on the person's sheet.
5. A quest counts only what the hero does after taking it (owner). The fights and the gathering of the queue count
   as they run.
6. The player hands the quest in to the person who gave it. A quest that asks the hero to bring items takes them
   from the bag at hand-in.
7. A person's row shows a mark when they have a quest to give or a quest to hand in, as in World of Warcraft.

### The reward
8. A finished quest gives **XP and a supply chest** (owner). The chest rolls its contents as a supply chest does
   (spec 0013): materials or meals, sometimes gear with a strong quality roll, rarely a boss shard.
9. Rewards stay small next to the grind. Quests add to the pace; they do not replace walking and fighting.

### Quest lines
10. Quests come in lines. Each one leads to the next, and the lines lead the hero from Camp to Goblin Woods, Old
    Graveyard and Smugglers' Cove.
11. The lines follow chapter 1 of the story (spec 0023) and end at the first kill of the Graveyard King.
12. The first quests teach the basics that "Next goal" taught: wear a better item, learn a profession, gather, craft,
    cook and fight a monster of the hero's level (owner). After those, the quests give no more gear advice. The bag
    already lists the best gear first.

### In place of "Next goal"
13. The "Next goal" card on Now becomes the **quest card**. It shows the open quest, its task and its count, for
    example "Goblins killed: 4 of 10".
14. When no quest is open, the card says who has a quest for the hero and where, for example "Pell has work for you
    in Goblin Woods".
15. A new player gets the first quest from Odda when the camp tour ends (spec 0022), or at once if they skip it.
16. The switch that hides "Next goal" (Settings) hides the quest card instead. A save keeps its choice.
17. The rules of "Next goal" go away: no equip, craft, collect, profession or fight line any more.

### The quest log
18. The player can read their quests: the open ones with their count, and the finished ones with their words.

## Affected users and systems
- **Players:** every player, new saves and old saves.
- **Data:** a new `data/quests.json` with each quest: the giver, the words, the task, the count, the reward and the
  quest before it. The words stay in data, not in code.
- **game_core:** taking a quest, its count from the moment it is taken, hand-in, the reward and the next quest in
  the line. The save keeps the open and the finished quests (a new save version). "Next goal" and its rules go away.
  The sim walker has its own goals (`simulation.dart`), not "Next goal", so removing it does not change the walker.
- **App:**
  - the quest card on Now, in place of "Next goal";
  - the marks on a person's row;
  - a quest part on the person's sheet: take, the count, hand in;
  - the quest log;
  - the Settings switch, renamed.
- **Specs:** the specs that name "Next goal" change with it: spec 0002 §9.3, spec 0008 decision 9, spec 0010 §8.4,
  spec 0005, spec 0009 §5.3 and spec 0020.
- **Old saves:** they start the quest lines at the first quest. The spec says how an old hero of a high level meets
  the first quests.

## Constraints
- **The pace moves a little.** The reward adds XP and supply chests. The spec sets how much and checks it with the
  sim. The levels stay on the targets that the owner accepted (mixed level 30 on day 80-100).
- **Read and listen.** Taking a quest is not a choice in the story. Quests do not branch, and no answer changes the
  story.
- **The queue stays as it is.** A quest adds no new kind of action. The fights, gathering and crafts of the queue
  count for it.
- **The words are a design decision.** The spec writes each quest's words. The owner accepts them with the spec.
- **Art:** the quest marks are flat icons that Claude draws, so no art comes in under a new licence.
- **Influences:**
  - World of Warcraft: quest givers, the marks over their heads, quest lines and the quest log.
  - Diablo 2: the reward chest rolls its loot.
- **Out of scope:**
  - north of the river: its people and quests come later, mostly as data;
  - daily or repeated quests;
  - work orders built from the old "Next goal" rules (the owner chose story quests only);
  - choices, branches and timed quests.

## Open questions
1. **The quests in words.** The spec writes each quest line: the givers, the tasks, the counts and the words.
2. **The size of the reward.** How much XP a quest gives, and the sim check that keeps the levels on target.
3. **Old saves.** How a hero who is already strong meets the first quests: as quick quests with their small reward,
   or with the teaching quests marked done.
4. **The marks and the log.** How the marks look, and where the quest log lives (the Journal, or a screen of its own).
5. **No quest left.** What the quest card shows when the hero has finished every quest of the first build.
6. **The queue.** Whether a stop condition "until the quest is done" helps, or whether the stop conditions of today
   are enough.
7. **Dropping a quest.** Whether the player can drop a quest they took.

## History
- 2026-11-17, #274: first version, with the owner's answers to the first questions. Accepted.
