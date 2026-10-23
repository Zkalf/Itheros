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
- Release notes. They are for players, but they are outside the game.

Accepted intents, specs and plans stay as they are. The rules apply to new text.

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

## Why this style
Most of these rules come from ASD-STE100 Simplified Technical English, a standard for maintenance manuals. Its makers
say that it is not for all kinds of text. They also say that many of its principles can apply to other texts. Examples
are short sentences, one topic in each sentence and the active voice. We use a short set of rules from it, not the
full standard.

### What a small test found
An AI assistant built the same small game six times, from the same intent and spec.
- For three builds, the AI assistant had a version of the spec in this style and an instruction to write in it.
  For the other three, it had the plain spec.
- The spec in this style had shorter sentences: a mean of 8.6 words against 10.4.
- In the spec in this style, 2% of the sentences had more than 20 words, against 8% in the plain spec.
- The spec in this style had 2 passives against 19, and 0 semicolons against 16.
- For the player and for the structure of the code, the two groups did not differ.
- The builds from the spec in this style finished about 27% faster.
- They had about two more low-severity defects each.
- Their code needed about 20% more changed lines for the same extension.
- Each group had three builds, so each of these three differences can be chance.
- The plain spec was already short. So the test compares this style with good plain English, not with typical text.
  The test also had only one task.

### Human readers
Studies with human readers are mixed. One found that readers understood more, mostly with hard texts and for readers
whose first language is not English. Others found no clear gain, or a gain from only some of the rules.

### AI assistants
Give an AI assistant the rules in this file, not the name of the standard.
- One informal public test, by one author with a small sample, asked an AI assistant to explain code. With the name
  of the standard in the prompt, the explanations lost 46.8% of the key facts. With the looser phrase "Simple
  Technical English", they lost 8.5%.
- A public audit compared a prompt of 8 short lines with a skill of 50 rules, on 8 sample replies. The short prompt
  did better on everything that a reader sees. The skill did better only on its own automatic checks.
- In a small blind test, one reader ranked text from short plain rules first. The two prompts that named the standard
  came last. The AI assistants had fixed lists of facts. All versions kept every fact. Four rankings by one reader
  are weak evidence.

## Text that breaks the rules
- Check your own text against the rules before you ask for a review.
- A review (see [REVIEW.md](REVIEW.md)) names the rule by its number and gives a better version.
- Most findings under these rules are **Nits**. `REVIEW.md` allows at most 3 Nits in each review.
- A finding is **Important** when a reader can read the text in two ways, or when the text loses or changes a fact.
- Accepted intents, specs and plans stay as they are. If their words can mean two things, an amendment fixes them.
