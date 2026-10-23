# How we write

These rules apply to the project texts that people and AI assistants write for Itheros. One name for each thing and
short, plain sentences make each text easy to read, easy to check and hard to misread.

## Quality comes first
This principle comes before every rule below.
- Never cut a fact, number, condition, qualifier, acceptance criterion or check to make a text shorter or simpler.
- If a rule of this file removes meaning from a text, keep the meaning and break the rule.
- Precision beats brevity.

## What the rules cover
- Intents, specs, amendments and plans.
- Pull request descriptions and reviews.
- Commit messages. The owner squash-merges each pull request, so its title becomes the commit title on `main`.
- Code comments.
- Incident records.
- Release notes. They are for players, so they get the light touch below, like the words in the game. They keep
  their voice.

The rules apply to new texts. Accepted intents, specs and plans are never edited (see `CLAUDE.md`). A clearer
version of one comes as a new clean edition that the owner accepts. The clean edition keeps every fact and every
section and criterion number.

**Words that players see in the game are out of scope.** Screen text and the lines in `data/*.json` are design
decisions. The spec of each feature owns them. The owner accepts them with that spec. This file does not override
them. A light touch is fine:
- Labels, hints and messages that a spec leaves open use plain words and one name for each thing.
- Lines that characters say and lore texts keep their own voice. Contractions are fine there.

## The rules

### Words
1. Give each word one meaning and each thing one name. Use the same name every time: "placeholder", not also
   "fallback" or "stand-in".
2. Keep the articles ("the", "a", "an"). Write "The tab shows six buttons", not "Tab shows six buttons".
3. Do not use -ing forms of verbs, phrasal verbs or contractions where a plain form exists. For example, write:
   - "when the player taps", not "when tapping"
   - "remove", not "take out"
   - "does not", not "doesn't"
4. Keep quotes, names, ids, code, file paths and numbers exactly as they are. This includes names that end in -ing,
   such as Mining.

### Sentences
5. Use the active voice. Write "The game saves the queue", not "The queue is saved".
6. Use simple tenses, such as "opens", "opened" and "will open". Do not use "is opening" or "has opened".
7. Write one idea in each sentence.
8. Use at most 20 words in an instruction and at most 25 words in a description. An instruction tells the reader to
   do something. A description tells what something is or does.

### Layout
9. Put items, steps and conditions in a vertical list. Do not chain them as fragments in a paragraph.
10. Use a table for things that you compare.
11. Use headings to group the parts of a text.
12. Readability comes before length, and [quality](#quality-comes-first) comes before both. A longer text with clear
    lists is better than a short, dense one.

### Specs and amendments
13. Each acceptance criterion checks one thing. If a criterion checks two things, make two criteria. Keep both checks
    (see [Quality comes first](#quality-comes-first)).
14. Group the criteria under short headings, such as "Screens", "Save" and "Balance". Number the criteria in one
    series across the headings, so each number names one criterion.

## Example
This example shows one criterion from a spec, before and after the rules.

**Before:** one sentence of 31 words, with four checks and two names for one thing.

> 5. When tapping a locked recipe, a hint pops up telling the player what's missing, and its icon is swapped for a
>    fallback image; the stand-in shouldn't be shown for unlocked ones.

**After:** four criteria under one heading, with one name and plain verbs.

> **Locked recipes**
>
> 5. A tap on a locked recipe opens a hint.
> 6. The hint tells the player what they do not have.
> 7. A locked recipe shows the placeholder image instead of its icon.
> 8. An unlocked recipe never shows the placeholder image.

What changed:
- Four checks became four criteria, with one heading for the group.
- "fallback image" and "stand-in" became one name: "placeholder image".
- "tapping", "telling", "pops up", "what's missing" and "shouldn't" became plain forms.
- The passives "is swapped" and "be shown" became active verbs.
- In criterion 7, "its" can only mean the recipe.
- Each fact stays: the tap, the hint, the image, and the locked and unlocked cases.

## Where the rules come from
The rules are a short set from ASD-STE100 Simplified Technical English, not the full standard. Give an AI assistant
the rules in this file, not the name of the standard.

## Text that breaks the rules
- Check your own text against the rules before you ask for a review.
- A review (see [REVIEW.md](REVIEW.md)) names the rule by its number and gives a better version.
- Most findings under these rules are **Nits**. `REVIEW.md` allows at most 3 Nits in each review.
- A finding is **Important** when a reader can read the text in two ways, or when the text loses or changes a fact.
