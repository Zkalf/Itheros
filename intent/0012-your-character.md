# Intent: Your character

Status: accepted
Product owner: Zkalf
Date: 2026-10-21

## Problem
The player has no name and no story: the game starts straight in camp. With professions and camp NPCs (intents 0010
and 0011), there is room for a WoW-style touch of RP about who you are and where you come from. Owner: a character
creation screen and a name, but no appearance editor ("seems like a lot of work and I've never liked doing it"); a
background should be RP text and also "a clear indication" of what it does in the game.

## Proposed outcome
1. **A creation screen** before the first walk, with three choices:
   - **Name**, typed by the player. It appears on the Character screen, in the journal, and in NPC lines.
   - **Gender:** male, female or neither. RP text follows it where it matters ("Woodcutter's son / daughter / child",
     the fisherman's "lad / lass / friend"); everything else is written neutrally.
   - **Origin:** one of six, one per profession. Each shows a line of RP and, plainly, what it does:

     > **Fisher from the coast**
     > *"You learned to read the water before you could read words."*
     > **Starts with Fishing 3** · the fisherman greets you as one of his own

     The six: Miner's child (Mining), Woodcutter's son/daughter/child (Woodcutting), Smith's apprentice (Crafting),
     Fisher from the coast (Fishing), Hunter's apprentice (Hunting), Tavern cook (Cooking).
2. **The head start is small and visible:** the origin's profession starts a few levels up (about level 3), and that
   profession's teacher greets the player as one of their own. No origin starts ahead in fighting, so the character
   level is the same for everyone.
3. **No appearance editor.** Portraits may come later, when there is art.
4. **Name and gender can be changed later in settings; the origin can't**, since its head start is already used.

## Affected users and systems
All players. A new first screen; game rules for origin head starts; `data/*.json` (origins, their RP lines and
gendered wording, NPC greetings); the save (name, gender, origin); NPC lines, the Character screen and the journal.

## Constraints
- Clean UI (intent 0008): one screen, three choices, done in under a minute. Sensible defaults so the player can
  just tap through.
- **Existing saves keep everything.** Existing players see the creation screen once on the update. Their origin's
  profession is raised to the head-start level only if it is lower; nothing is taken away.
- The head start is small enough that origin is a flavour choice, not a "best pick" (checked in the sim with
  intents 0010 and 0011).
- Gendered wording is limited to the few lines where it reads naturally; the rest of the game stays neutral.
- Out of scope: portraits and appearance, origin-specific quests (quests are a later system), changing origin.

## Open questions
None blocking. Exact head-start level and the RP lines are settled in the spec.
