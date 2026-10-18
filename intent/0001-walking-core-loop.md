# Intent: Walking-powered combat RPG — core loop

Status: accepted
Product owner: Zkalf
Date: 2026-10-18

## Problem
Most mobile games reward time spent looking at the screen. Players who want a reason to walk more have few
games where real-world walking *is* the game rather than a side bonus. Location-based games tie play to
GPS and specific places, which excludes walking indoors, on a treadmill, or in areas with few points of interest.

## Proposed outcome
A mobile combat RPG where nearly all progress comes from steps the player takes in real life, counted by the
phone's pedometer. The player fights enemies, gains levels, and improves gear through gathering and crafting.

Observable outcomes:

- Steps walked since the player's last session turn into in-game progress when they next open the app.
- A player who never walks makes little or no progress. A player who walks more progresses faster.
- The game works with no GPS, at any location, and while the app is closed.
- Opening the app for a minute each day feels rewarding, not like a chore.

### RPG systems in scope
- **Combat:** the theme of the game. Fights are auto-resolved from the character's stats and gear, with no
  player input during the fight, so combat runs the same whether the app is open or closed. The first enemy
  the player meets is a **goblin**.
- **Levels:** the player gains experience and levels up.
- **Gear:** equipment that makes the character stronger.
- **Gathering and crafting:** activities besides combat that produce materials, which are crafted into better gear.
- **Talents:** unlock later, around level 10, so the early game stays simple.
- **Achievements:** milestones for players to chase.

### Step economy
- **Every activity costs steps:** travelling the world, combat, gathering, crafting, and any future activity.
  Steps are the single resource that drives all play.
- **Step bank:** steps walked while the character isn't doing an activity are stored in a bank instead of being
  lost. The bank is capped, and the cap grows with character level. Talents and achievement rewards can raise
  it further. Steps walked while the bank is full are lost.
- **Banked steps boost walking, they don't replace it:** banked steps can only be used while actually walking.
  Each real step during an activity counts double (1 walked + 1 from the bank) until the bank runs out. Banked
  steps cannot be spent without walking.
- **Activities continue offline:** while the app is closed, the character keeps doing its current activity, paid
  for by the steps walked.
- **Activity ends → bank:** when an activity finishes or can't continue (e.g. crafting runs out of materials),
  the remaining steps go to the bank.
- **Later additions, not in this intent:** limited direct spending of banked steps, given as a reward through
  daily features, talents, or achievements. A way for the player to stop an activity.

### Difficulty curve and onboarding
- The first levels are easy and get harder over time. The early game is a natural tutorial: each system is
  introduced as it is reached, without a separate tutorial mode.
- Starting to play must be quick and simple. New systems (crafting, talents) appear only once the basics
  are familiar.

## Affected users and systems
- **Players:** casual mobile players who want motivation to walk and enjoy RPG progression. Not fitness
  enthusiasts specifically.
- **Platforms:** iOS and/or Android phones (to be decided).
- **Step data:** OS step-counting APIs (iOS Core Motion / HealthKit; Android step counter sensor / Health Connect).
  These require health/motion permission prompts and app-store privacy disclosures.
- **Game systems:** step ingestion → combat, gathering, crafting → XP, levels, gear, talents, achievements.

## Constraints
- Step counting must come from the OS, not the app tracking motion itself. This keeps battery use low and
  works when the app is closed.
- Health data stays on the device unless a later intent justifies sending it anywhere.
- The game must not punish missed days harshly (no streak loss that makes a sick day feel bad).
- No talents before roughly level 10.
- **Non-goals for now:** GPS/map gameplay, real-money competitive play, wearable-only features.

## Open questions
Carried into `spec.md`, where Claude proposes answers for the product owner to approve:

1. **Stopping an activity:** how does the player stop or change an activity? (Deferred by the product owner.)
2. **Bank cap values:** starting cap, growth per level, and how talents and achievements raise it.
3. **What "almost all" excludes:** which progress, if any, comes from something other than steps?
4. **Platforms:** iOS, Android, or both at launch?
5. **Engine/tech:** Unity, Godot, Flutter, React Native, native?
6. **History:** do steps from before install, or older than the last session, count? There are OS limits on
   how far back each API reports.
7. **Cheating:** how much do we care about phone-shaking or step-faking devices? Single-player tolerance vs. leaderboards.
8. **Daily caps:** is there a daily step cap or diminishing returns, so heavy walkers don't outpace content?
9. **Social:** solo only, or friends / shared goals?
10. **Monetisation:** free, paid, ads, IAP? This must not let money replace walking.
11. **Scope:** prototype first (steps → fight a goblin → gain XP/loot), or a fuller first release?
