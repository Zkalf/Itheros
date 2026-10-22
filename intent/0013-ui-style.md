# Intent: Quiet Teal UI style

Status: draft
Product owner: Zkalf
Date: 2026-10-22

## Problem
The app uses the Material icons of Flutter. Monsters have no picture, and many items share one icon. So players
tell loot and monsters apart only by name. Zkalf and nabriis chose one style for the app: Quiet Teal.

## Proposed outcome
1. **One style on all screens:** slate panels on black, one soft teal accent and no brown. The quality and level
   colours stay.
2. **Black borders** on all buttons.
3. **Images** for all monsters, items, achievements and the World map. The item count is outside the frame. Gear
   never looks like a material.
4. **A splash:** the name Itheros on a full-screen image, with a loading bar at the bottom. The launcher icon is an
   emblem in the same style.
5. **One teal ring** shows where you are on the map.
6. **Each fact shows only once** on a screen. A fact that the app shows once today stays.
7. **Placeholders** for new content without its own image: one for each kind of thing (for example boots, a sword
   or a monster), and one generic placeholder for the rest. New boots then show the boots placeholder.

## Affected users and systems
All players and all screens. The theme, images, fonts and launcher icon. No change to the game rules. The new spec
replaces the icon rules in intent 0008 and spec 0008 §3.5, the 💀 in spec 0002 §3 (the level rules stay), the banner
icons in spec 0004 amendment 3 and the launcher icon in spec 0007 decision 5.

## Constraints
- **Dark only.** The app no longer follows the light or dark setting of the phone.
- No network code and no new packages.
- New content can ship without its own image.
- The fonts keep their own licence (SIL Open Font License 1.1). The app includes the licence texts.
- The images are AI-made. The image files are their source.
- The images make the app about 10 MB bigger: about 60 MB instead of 50 MB.
- The style goes on the current screens. The design shows some older screens.
- In scope: a talents screen, a boss screen, portraits and a route map in the away report. The talent rules (how
  players spend points) come in their own intent.
- Out of scope: a fight scene and animation.

## Open questions
None.
