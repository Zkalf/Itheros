# Spec 0014: Quiet Teal

Status: accepted
Intent: [intent/0014-ui-style.md](../intent/0014-ui-style.md) (merged in #32 as 94bcdec, which accepts it;
renumbered in 23b96db)
Builds on:
- spec 0008 and its amendments 1-3;
- spec 0009 and its amendment 1;
- spec 0010 and its amendments 1-4 (and erratum 1);
- spec 0011 and spec 0012;
- spec 0004 amendments 2-3, spec 0005 amendment 3, spec 0006 amendment 2 and spec 0002 §9.2.
Overrides:
- intent 0008's "no art budget";
- spec 0008 §3.5's icons and corner count, and criterion 8's icons;
- spec 0004 amendment 3's banner icons;
- spec 0002 §3's 💀;
- spec 0006 criterion 11's drawn river;
- spec 0007 decision 5 (the launcher);
- the art and portrait lines that spec 0002 §10 and spec 0012 §7 put out of scope.
Product owner: Zkalf
Date: 2026-10-22

## Summary
- The app gets one look: slate plates on a black case, one soft teal, and a black border on each button.
- Monsters, items, achievements, places, gathering spots, professions and the map get images.
- A thing without an image shows a placeholder with the mark "PH". So the style can ship before all images exist.
- The screens, rules and numbers do not change.
- The away report gets a route map. This is the one data change.
- All sizes are in dp. The kit below gives the exact sizes and gradients.

![The Quiet Teal board from intent 0014: the idea, the colours and four screens](../docs/design/0014-quiet-teal-board.webp)

![The Quiet Teal kit: colours, buttons, sockets, the PH mark, the bars and the map ring](../docs/design/0014-quiet-teal-kit.webp)

![Five screens in Quiet Teal: splash, Now, the bag, a boss sheet and the away report](../docs/design/0014-quiet-teal-screens.webp)

The images show the look of 2026-10-22. If an image and this spec are different, the spec is correct.

## 1. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | Style or structure? | **The style sets the look. The accepted structure stays:** the top and bottom bars, the doll, the bag, the Character header, fog by exploration, one sheet for each monster, and a report that looks like a journal entry. |
| 2 | Light or dark? | **Dark only.** This includes the Android windows. |
| 3 | Ship before all images exist? | **Yes.** The first build had images for 48 of the 178 items. The other items show a placeholder until their image exists. |
| 4 | Placeholders | **One for each kind or slot, and one generic.** Each placeholder has the PH mark in light steel. A real image never has the mark. |
| 5 | Images | **AI-made. The image files are their source.** The app keys the images by the game's ids and bundles them. No network code. No new packages. |
| 6 | Fonts | Cormorant Garamond, Alegreya Sans, Alegreya Sans SC and Spectral, under the **SIL OFL 1.1**. Settings shows the licences. |
| 7 | Icons | An icon for a thing (a monster, item, achievement, rank or place) becomes its image. Icons in controls stay. **Each profession shows a picture of its tool**. The Professions button in the bottom bar is a control, so it keeps its glyph. |
| 8 | Boss screen | **The monster's own sheet.** A boss shows its image across the full width. Each monster has one sheet. Stats stay hidden until 10 kills. |
| 9 | Portraits | Monsters use their images. The player's portrait follows origin and gender. The save has both. |
| 10 | Route map | The away report and its journal entry show the route (§5). |
| 11 | Talents | **The look only** (§4.3). The talent spec builds the screen. |
| 12 | Each fact once | Seven repeats go (§4.1). |

## 2. Look

### 2.1 Colours

| Role | Hex | Use |
|---|---|---|
| Case | `#060708` | the background |
| Plate | `#171C21` | cards, sheets, dialogs, snack bars, the top bar and the bottom bar |
| Slate | `#2B333B` to `#1E242A` | buttons and chips that are not selected |
| Selected | `#4C6768` (teal `#8AC7BC` at 35% over slate `#2B333B`) | a selected chip, segment, Journal tab or bottom bar tab |
| Lit | `#2E3740` | only the thumb of a switch that is off |
| Teal | `#8AC7BC`, text on it `#0D1416`; deep teal `#17292C` | main buttons, focus, the current place, earned things, "New", the rank, the loading bar; deep teal for banners |
| Steel, mist | `#B9C2C9`; `#8FA2AE` | steel for bars and the PH mark; mist for the step bank |
| Text | `#E3EAEC`, muted `#A8B3B8`, faint `#7F8A90` | body text, secondary text, small labels |
| Short, Risky | `#E08A7C`; `#FBB15A` | inputs that the player does not have; the word "Risky" |

- The game's quality and band colours stay.
- The interface uses no other warm colour.
- Status bar icons are light. They are dark on the splash picture.

### 2.2 Type, plates and buttons
**Type**
- Cormorant Garamond for the wordmark, titles and names.
- Alegreya Sans for body text and tab labels.
- Alegreya Sans SC (small caps) for button labels and list headings. The words do not change.
- Spectral for numbers.

**Plates**
- Radius 16, a 1 dp teal hairline, 6 dp apart.
- Only the map stands on the case. All other controls stand on a plate.

**Buttons**
- Each button has a **2 dp black border** in each state.
- The filled buttons of 2026-10-22 are teal.
- Cancel, Not now, Keep it and Skip all are ghost buttons (the border only).
- All other buttons are slate.
- A pressed button sinks. A focused button gets a teal ring.

**Chips, segments and tabs**
- Chips and segments are slate, with the border.
- A selected chip, segment, Journal tab or bottom bar tab has the selected fill `#4C6768`, a white `#FFFFFF` label,
  and a white icon where it has an icon.
- These controls have the selected look:
  - the segments, such as Gear and Bag on the Character tab and the gender on "Who are you?";
  - the choice chips and the filter chips, such as the stop choices, Auto-eat, Have mats, Have level and Up to 5
    levels ahead;
  - the tabs of the Journal: Log, Bestiary and Lore;
  - the open tab of the bottom bar: Now, World, Professions or Character.
- A chip, segment or Journal tab that is not selected stays slate with a light text label `#E3EAEC`.
- Status chips are outlines.
- The kind chips of the bag and the bank (spec 0020 amendment 2) and the tabs of the bank screen (spec 0020
  amendment 3) use the same selected look.

**The outline on button labels**
- A thin black outline surrounds the letters of each button label: four black shadows of 0.8 dp, one on each side,
  with no blur.
- These labels have the outline:
  - slate buttons, such as Go there, Equip, Swap, Unequip, Change and Reroll;
  - ghost buttons: Cancel, Not now, Keep it and Skip all;
  - segments, choice chips and filter chips, selected or not;
  - the tabs of the Journal;
  - the labels of the bottom bar.
- These labels do not have the outline:
  - teal buttons. Their label is dark `#0D1416` on teal, and an outline makes it heavier, not clearer;
  - status chips, such as "Active". They are not buttons.
- Icons have no outline.
- The 2 dp black border, the shapes, the sizes, the fonts and the words of each control stay as they are.
- Text that is not on a button keeps its look: body text, titles, names, list headings and numbers.

**Top bar and bottom bar**
- Top bar: Trophies, Journal and Settings are slate icon buttons on a plate. A pushed page shows Back only.
- Bottom bar: a plate with the four tabs. Each tab shows its icon above its label.
- The open tab has the selected look.
- A tab that is not open has no fill, and a muted icon and label.

**New parts** follow the same rules. Examples:
- the profession buttons and filters;
- the card of the daily chest.

### 2.3 Sockets, counts, bars and the ring
**Sockets**
- Each image sits in a dark socket.

| Where | Size |
|---|---|
| Heads and portraits | 72 dp |
| The portrait in the Character header | 48 dp (spec 0008 §3.5) |
| Rows of the Achievements screen | 72 dp |
| The action sheet of a gather or a craft | 72 dp |
| Rows and the bag (monster rows, spot rows, recipe rows, the queue card) | 48 dp |
| Banners, and the lines of the materials table | 32 dp |

- On the Achievements screen, the socket stands at the start of the row, centred on the height of the row. The rows
  are a little taller, so fewer rows fit on one screen. The owner accepts this.
- Each other row of the game keeps its 48 dp socket.

**Quality**
- Gear and tools have a 2 dp ring in their quality colour. Common has `#E0E0E0`.
- Uncommon and higher also have a wash of that colour.
- Materials and meals have no ring. So gear never looks like a material.

**Count**
- A small badge with a border shows counts of 2 and more. It hangs off the lower right corner ("×14").

**Empty doll slot**
- The faint slot icon. It never has the PH mark.

**Bars**
- Bars are steel. The step bank is mist.
- The loading bar and unearned achievements are teal.
- Each bar keeps its number.

**Level badges**
- Level badges keep their look.
- The skull band shows a skull image in place of 💀. Screen readers still say "Level: far too strong".

**The ring**
- One teal ring marks the current place on the World map and on the route map. No other mark shows the current
  place.
- The code places the names and the step plates. These rules hold:
  - Nothing on the map overlaps: no two names, step plates or markers.
  - Each name lies inside the map, at most 8 dp from its marker.
  - Each step plate lies on its road.
  - **Own marker:** the marker nearest to the middle of a name is the marker of its own place.
  - **Roads:** a road can cross the edge of a name. The distance from the middle of a name to each road with a step
    plate is at least half the height of the name.
- **Name size:** the names on the map are 13 dp. They keep their font (Cormorant Garamond 600) and their colours.
- **Room for each place:** the World map keeps room for each place and each road, also when the
  place is hidden or in the fog.
  - The placement uses the real name of each place and the step count of each road.
  - The map draws only what it drew before amendment 2: no hidden place, no hidden road, and no step count on a road
    into the fog.
  - A name in the fog ("???") stands inside the room of the real name, as near to its marker as it can.
  - So no name moves when the bottle reveals Smugglers' Cove or when a place leaves the fog.
- The rules of the own marker, the roads and the name size also apply to the strip of the route map. The strip
  shows only the places of its route, so the room for each place does not apply to it.
- **Places on the map** (`map` in `packages/game_core/data/world.json`, parts of the width and the
  height of the map):

  | Place | Before amendment 2 | Since amendment 2 |
  |---|---|---|
  | Camp | x 0.5, y 0.92 | x 0.36, y 0.92 |
  | Mirror Lake | x 0.72, y 0.94 | x 0.72, y 0.89 |
  | Copper Hills | x 0.8, y 0.8 | x 0.84, y 0.76 |

  - Camp moves left, so the camp of the map picture shows to the right of its marker.
  - The roads keep their step counts.

## 3. Images

### 3.1 What shows an image

| Thing | Key | Placeholder |
|---|---|---|
| Monster | its id | one |
| Gear | its item id | one for each slot kind |
| Tool | its item id | one for each profession |
| Material, meal | its item id | one for materials, one for meals |
| Achievement | its id | a locked achievement shows the locked patch |
| Rank | `rank_<name>` | the generic placeholder |
| Place | the fog marker if the place has fog; else its id; else its kind | a water place keeps its water icon until it has a marker |
| Player | origin and gender, for example `coast_fisher_female` | one |
| Gathering spot | `spots/<spot id>` | the tool placeholder of its profession |
| Profession | `professions/<id>` | the profession's glyph |
| Action in the queue | the picture of its thing (below) | the placeholder of that thing |

The style also has these pictures: the splash, the World map, the skull, the locked patch and the launcher emblem.

**Gathering spots**

| Profession | Spots | Placeholder |
|---|---|---|
| Mining | Copper vein, Iron vein, Mithril vein | `tool_mining` |
| Woodcutting | Oak tree, Ash tree, Pine tree | `tool_woodcutting` |
| Fishing | Lake shore, Under the bridge, Cove rocks, Cold tarn | `tool_fishing` |
| Hunting | Deer trail, Moor tracks, High crags | `tool_hunting` |

- A real image of a spot comes as content: the file `app/assets/images/spots/<spot id>.webp`.

**Professions**
- Each profession has a picture, `professions/<id>.webp`. It shows the profession's tool in the iron tier:

  | Profession | Picture |
  |---|---|
  | Mining | pickaxe |
  | Woodcutting | hatchet |
  | Crafting | smith's hammer |
  | Fishing | rod |
  | Hunting | bow |
  | Cooking | cooking pot |

- A profession without a picture file shows its glyph.
- `art/tools.py` draws the six pictures from the same shapes as the tools. `scripts/export-art.ps1` exports them.
- The talent icons stay. The tool items keep their own pictures in the bag.

**Actions**

| Action | Picture |
|---|---|
| Fight | the monster |
| Gather | the spot |
| Craft | the item that the recipe makes |
| Reroll | the item that the player rerolls |
| Walk | the marker of the place |

- A thing without a picture file shows its placeholder, as everywhere (§3.2). No new picture is needed.
- The item of a craft or a reroll shows the ring of its quality when it is gear or a tool, as in the bag.

### 3.2 Placeholders and the PH mark
- A thing without an image shows the placeholder of its kind. If its kind has no placeholder, it shows the generic
  placeholder.
- Gear never shows the material placeholder.
- The app draws "PH" on the object, at a spot that each placeholder keeps (for example, the shaft of a boot).
- The mark is small caps in light steel at 85%, with a thin dark stroke.
- Its font size is 22% of the socket width, from 9 dp to 16 dp.
- It is never on the ring or below the count badge.
- Screen readers say "placeholder picture". The item card adds the line "Picture coming later".
- A check in `check.ps1` lists each id that shows a placeholder, spots included. The check
  never fails because of a placeholder. So new content does not need an image.

### 3.3 Splash, welcome and launcher
- **Splash:** the splash picture fills the screen. ITHEROS is near the top. A plate at the bottom holds the loading
  bar, "Reading your steps" and the version.
- **Welcome** and "Health Connect is needed": the same picture is at the top. Below it are the words and the teal
  button.
- **Launcher:** the emblem on `#060708`, and a one-colour version of it. Both Android window themes use `#060708`.
- **The emblem fills the icon:**
  - The emblem and the one-colour emblem are about 74 dp across in the icon's 108 dp: a little more than the 72 dp
    that a round launcher shows. On a round icon no background shows.
  - The picture of the emblem does not change, only its size in the icon files. The launcher crops its outer edge a
    little.
  - The background layer stays `#060708`. A launcher with square or rounded-square icons still shows it in the
    corners.
  - The splash screen uses the same file, so its emblem grows by the same share.

## 4. Screens

### 4.1 Each fact once

| Where | Shown twice before spec 0014 | Kept |
|---|---|---|
| Tab screens | the name of the screen as the title and on the tab | the tab |
| Now | the place in the status card and in "Here: Camp" | the status card; the list heading is "Here" |
| Monster rows | "10 steps per round" on each row | one "Monsters · 10 steps per round" heading |
| Item card for an empty slot | the stats, and the same numbers as the change | the stats; the change line stays if it is different |
| Earned achievements | the goal, a full bar and "100 / 100" | the goal and a teal rim |
| World | the place in colour and a pin | the ring |
| Bestiary rows | "Slayer" and an icon | the word |

### 4.2 Screen by screen
**Now**
- The status card shows the marker of the place.
- Meal lines and monster rows start with their images.
- **Spot rows** have the layout of a monster row, on Now "Here" and on the area sheet of the
  World map:
  - the row starts with the picture of the spot in a 48 dp socket;
  - the level badge is on the name line, before the name;
  - the badge keeps its colour and its number.
- The teacher rows under "Here" show the picture of the teacher's profession at 32 dp, with no socket.
- These rows keep their icons: the Forge row, the Camp fire row and the "Walk here" row.
- **The step bank**: a tap on the step bank row (its label and its bar) opens a sheet:
  - the title "Step bank";
  - "Steps walked while resting are saved here. During an activity, each step you walk uses one banked step and
    counts double.";
  - "Steps arrive from Health Connect about once a minute. Pull down to check now."
- Now shows neither of those two lines under the step bank or at the bottom of the screen.
- The step bank bar and its label, "Walked today" and pull to refresh stay.

**The queue card**
- The row of the current action starts with its picture in a 48 dp socket, before the action's name.
- Each row of a waiting action starts with its picture in a 48 dp socket, in place of the number circle.
- The number of each row (1 for the current action, then 2, 3, …) is a small round badge on the top-left corner of
  its picture.
- When the queue has only one slot, the current action shows no number.
- A reroll shows no stop line, as a walk shows none. This holds for the current action and for a waiting one.
- The words, the stop lines, the bars, the tally, Stop, Remove and the tap that changes a stop condition stay.

**The action sheet**
- The sheet of a gather or a craft starts with the picture in a 72 dp socket, beside the title.
- The sheet of a fight keeps the monster's card, with its picture (spec 0009 decision 11).

**World**
- The map image fills the width. The image has its own river.
- Markers, roads, step counts and fog keep their look.
- The line "Tap a place to see what lives there." does not show under the map.

**Monster sheet**
- Each monster has one sheet. The card starts with the image of the monster.
- A boss is a monster with first-kill drops. Its image fills the width and is at most 200 dp tall.

**Character**
- The portrait is next to the name, at 48 dp (spec 0008 §3.5).
- The rank is teal.
- The Gear page and the bag show images. The Gear page is a grid of four columns with no figure (spec 0008
  amendment 8).

**Away report and Journal**
- Banners for levels, lore, professions and the sea chart are text only.
- The other banners start with the image of the thing that they name.
- The route map is between the banners and the lines.

**Professions**
- The card of each profession in the Professions tab shows the picture of its profession at 32 dp, with no socket,
  before its name.
- The header of each profession screen shows the picture of its profession at 32 dp, before its name.
- The Professions button in the bottom bar keeps its glyph (decision 7).
- **Recipe rows:**
  - Each recipe row starts with the picture of the item that it makes, in a 48 dp socket.
  - Gear and tools show the ring of their quality, as in the bag. Meals and materials have no ring.
  - The level badge is on the title line, before the recipe's name, as in a monster row or a spot row. It keeps its
    colour.
  - The words of the row stay: the kind, the stats, the materials, "Enough for N", the steps and the XP, or why it is
    locked.
  - A tap on the row opens the action sheet. The row does not open the item card: its subtitle already shows the
    item's stats, and the sheet shows the picture large.
- **The materials table:**
  - Each line starts with the material's picture in a 32 dp socket, before its name.
  - A tap on a line opens the material's card: where it comes from and what uses it. The card has no buttons.
  - The columns Have, Uses and Left stay.

**Achievements**
- Each row starts with its picture in a 72 dp socket.
- The row keeps the name, the "Feat" chip, the goal, the "Reward:" line and the bar with its numbers, the "New" chip
  at the end, the teal rim of an earned achievement, and the locked patch for a locked achievement.

**Level-up, "Who are you?"**
- They show the images and portraits of §3.1.

**Settings**
- A **Licences** row shows the licences of the four fonts.

**Going back**
- **Swipe right anywhere:** on a screen that slid in, a swipe to the right that starts anywhere on the screen goes
  back. The screen follows the finger, as the edge swipe does.
- **Let go halfway:** a swipe that ends before the middle of the screen, and slowly, slides the screen back in. A
  quick swipe goes back from any distance. These are the rules of the edge swipe.
- **Taps stay taps:** a tap, or a touch that moves less than the touch slop of the phone (about 18 dp), never starts
  a swipe. A tap on a recipe, a button or a row works as before.
- **Scrolls stay scrolls:** a touch that moves more up or down than to the side scrolls the screen.
- **A swipe to the left** does nothing.
- **Where it does not apply:**
  - the tabs of the bottom bar (they did not slide in);
  - sheets and dialogs;
  - a screen with a part that scrolls or drags to the side. It keeps only the edge swipe.
- The slide-in of #141, the Back button, the phone's back button and the edge swipe stay.

### 4.3 Talents (the look only)
- Spec 0014's look for the talent spec:
  - A heading shows the points that are left.
  - Each path has a plate with an image, a name and one line.
  - Teal pips show the steps. A taken step is filled.
  - The spend button is slate.
- Spec 0015 amendment 3 replaced it with a tree: icons on a grid, with lines between them. Spec 0015 amendment 6 put
  each tree on a plate of its own. Spec 0015 owns the look of the talents now.

## 5. The one data change: the route
- A report keeps a route.
  - The route starts at the place where the player was.
  - Then it lists each place where the player arrived.
  - Two merged reports join their routes.
- If the route has two or more places, the report and its journal entry show a strip of the map. The strip shows
  the roads walked, the places passed and the ring on the last place.
- The game saves the route with the journal entry.
- An older entry loads with no route and shows no map.
- The save versions stay at 10 and 3. Each fixture loads.

## 6. Out of scope
- A fight scene and animation.
- The talent rules.
- A separate boss screen.
- A light theme.
- An appearance editor.
- Images for teachers and areas. A gathering spot is not an area. Professions have pictures (§3.1).
- Changes to rules or numbers.

The missing images come later as content.

## 7. Concerns
1. **Many placeholders at first** (intended): three items in four, and all tools, meals and portraits.
2. **Tests for the old look:** about six tests change by design. The plan names each test.
3. **Size:** with all images, the app is about 10 MB larger.

## 8. Acceptance criteria
A criterion that checks several things has a letter for each check (rule 13 of `WRITING.md`).

### 8.1 Look
1. Dark:
   - 1a. The app is dark for each phone setting.
   - 1b. The Android launch window and normal window are dark (`#060708`).
2. Colours:
   - 2a. The app uses the colours of §2.1.
   - 2b. It uses no other warm colour.
   - 2c. Each colour literal in `app/lib/` is a colour of §2.1, a quality or band colour, black, white or transparent.
3. Fonts:
   - 3a. The app bundles the four fonts and uses them as §2.2 says.
   - 3b. Settings has a Licences row with their licence texts.
4. Each button, tab, chip, segment and switch has the 2 dp black border in each state.
5. Buttons:
   - 5a. Teal, ghost and slate buttons are as §2.2 says.
   - 5b. Each button keeps its words.
6. Back keeps its "Back" tooltip.

### 8.2 Structure that stays
7. Bars:
   - 7a. The bottom bar has Now, World, Professions and Character.
   - 7b. The top bar has Trophies with its dot, Journal and Settings on each tab screen.
   - 7c. Tab screens have no title.
8. The Character header:
   - 8a. It keeps the name, the rank and the origin, and the talent line.
   - 8b. The level stands beside the name, and the seven stats stand in their row (spec 0008 §3.5).
   - 8c. Seven taps on the rank still turn on the test walk.
   - The test of an origin that does not fit uses a phone 320 dp wide.
9. The Gear page and the bag:
   - 9a. The Gear page keeps 16 slots, in a grid of four columns with no figure (spec 0008 §3.5).
   - 9b. The bag keeps 5 columns, with gear first.
10. Each fact once:
    - 10a. Each repeat of §4.1 shows once.
    - 10b. The item card for an empty slot drops the change line only if the line repeats the stats.

### 8.3 Images and placeholders
11. Images:
    - 11a. Each thing in §3.1 shows its image by its key.
    - 11b. A thing without an image shows its placeholder.
    - 11c. Gear never shows the material placeholder.
12. Places and achievements:
    - 12a. A fogged place shows the fog marker.
    - 12b. A water place without a marker shows the water icon.
    - 12c. A locked achievement shows the locked patch.
13. The PH mark:
    - 13a. Only placeholders have the PH mark.
    - 13b. The mark is as §3.2 says.
    - 13c. The water icon and empty doll slots have no mark.
14. Screen readers and the item card:
    - 14a. Screen readers say "placeholder picture" for a placeholder.
    - 14b. The item card of a placeholder says "Picture coming later".
15. The check of §3.2 lists the placeholders and passes. Content without an image also passes.
16. A socket shows the image. For 2 or more, it also shows the count badge outside the lower right corner.
17. Rings:
    - 17a. Gear and tools have a ring in their quality colour, Common included.
    - 17b. Materials and meals have no ring.

### 8.4 Screens
18. The map:
    - 18a. One teal ring marks the current place.
    - 18b. At a width of 360 dp, nothing on the map overlaps.
    - 18c. Each name stays inside the map.
19. Monster sheets:
    - 19a. A tap on a monster opens one sheet with its image.
    - 19b. A boss shows its image across the full width.
    - 19c. Stats stay unknown until 10 kills.
20. The skull band shows the skull image. Screen readers still say "Level: far too strong".
21. Each banner shows text or an image, as §4.2 says.
22. Level-up and "What's new":
    - 22a. The level-up card of a new rank shows the rank image.
    - 22b. "What's new" rows start with the image of the monster, or of the item that a recipe makes.
23. Portraits:
    - 23a. "Who are you?" cards and the Character header show the portrait for the origin and gender.
    - 23b. The portrait changes when the player picks another gender.
24. Splash, welcome and launcher:
    - 24a. The splash shows the picture, ITHEROS and the loading bar.
    - 24b. Welcome and "Health Connect is needed" show the same picture.
    - 24c. The launcher shows the emblem on `#060708`. Criteria 110-112 say how large.

### 8.5 Route and save
25. The route:
    - 25a. A report keeps its route across syncs and days.
    - 25b. With two or more places, it shows the route map on the away screen and in its journal entry.
26. The save:
    - 26a. An entry from before spec 0014 loads and shows no map.
    - 26b. The save versions stay at 10 and 3.
    - 26c. Each fixture in `app/test/fixtures/saves/` loads.

### 8.6 Rules and build
27. Rules and numbers do not change. The pacing test passes.
28. `.\scripts\check.ps1 -Release` passes. The app has no INTERNET permission and no new package.

### 8.7 After the first build
**Swipe back**
29. A swipe to the right from the middle of a profession's screen goes back to Professions.
30. A tap on a recipe row of a profession's screen opens the recipe, and does not go back.
31. A short slow swipe to the right, less than a third of the screen, leaves the profession's screen open.
32. A vertical scroll on a profession's screen scrolls it, and does not go back.
33. A swipe to the left on a profession's screen does not go back.
34. A swipe to the right on the Now tab changes nothing.
35. Rules, numbers and the save do not change. The pacing test passes.
36. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

**Fewer words on Now and World**
37. Now does not show "Steps walked while resting are saved here."
38. Now does not show "Steps arrive from Health Connect about once a minute."
39. A tap on the step bank opens a sheet with the title "Step bank" and both lines.
40. The World tab does not show "Tap a place to see what lives there."
41. Rules, numbers and the save do not change. The pacing test passes.
42. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

**Spot rows**
43. On Now "Here", each spot row starts with a 48 dp socket.
44. On the area sheet of the World map, each spot row starts with a 48 dp socket.
45. A spot without an image shows the tool placeholder of its profession, as the table of §3.1 says.
46. A spot with an image file `spots/<spot id>` shows that image, without the PH mark.
47. The level badge of a spot is on the name line, before the name.
48. The level badge of a spot keeps its colour and its number.
49. The Forge, Camp fire and "Walk here" rows keep their icons.
50. The placeholder check lists each spot that shows a placeholder and passes.

**Names on the map**
51. At 360 dp, for each of the 12 places as the current place, the marker nearest to the middle of each name is the
    marker of its own place.
52. At 360 dp, for each current place, the distance from the middle of each name to each road with a step plate is
    at least half the height of the name.
53. At 360 dp, for each current place, criterion 18 still holds: nothing overlaps, and each name stays inside the
    map.
54. The names on the map are 13 dp.
55. At 360 dp, with Camp as the current place, each name has the same rect before and after the bottle reveals
    Smugglers' Cove.
56. At 360 dp, with Camp as the current place, the "???" name of a place in the fog lies inside the rect that its
    real name has when the place leaves the fog.
57. At 360 dp, the World map draws no hidden place, no road to a hidden place, and no step count on a road into the
    fog.
58. Camp, Mirror Lake and Copper Hills have the map points of the table in §2.3.
59. Each other place keeps its map point.

**Achievement rows**
60. Each row of the Achievements screen starts with a 72 × 72 dp socket.
61. A locked achievement shows the locked patch in the socket. An earned achievement shows its image.
62. The socket is centred on the height of its row.
63. The name, the goal, the "Reward:" line, the bar and the "New" chip still show in the row.
64. The monster rows and the spot rows on Now "Here" keep their 48 dp sockets.

**The selected look and the label outline**
65. A selected segment has the fill `#4C6768`, a white label and a white icon.
66. A selected choice chip and a selected filter chip have the fill `#4C6768` and a white label.
67. The open tab of the Journal has the fill `#4C6768` and a white label.
68. A segment, chip or Journal tab that is not selected has the fill slate `#2B333B` and the label `#E3EAEC`.
69. The open tab of the bottom bar has the fill `#4C6768`, a white icon and a white label. The other tabs have no
    fill and a muted icon and label.
70. The label of a slate button has the four black shadows of 0.8 dp with no blur.
71. The label of a ghost button has the outline.
72. The label of each segment, choice chip, filter chip and Journal tab has the outline, selected or not.
73. Each label of the bottom bar has the outline.
74. The label of a teal button has no shadow.
75. A status chip has no shadow.

**Profession pictures**
76. Each of the six professions has a file `professions/<id>.webp`.
77. Each profession card in the Professions tab shows the picture of its profession, at 32 dp.
78. The header of each profession screen shows the picture of its profession, at 32 dp.
79. A teacher row under "Here" on Now shows the picture of the teacher's profession, at 32 dp.
80. A profession without a picture file shows its glyph in each of the three places.
81. The Professions tab button in the bottom bar shows its glyph.

**Pictures in the queue**
82. The current action's row starts with the picture of its thing in a 48 dp socket, for a fight, a gather, a craft
    and a walk.
83. Each waiting action's row starts with the picture of its thing in a 48 dp socket, for a fight, a gather, a craft,
    a reroll and a walk.
84. A craft of gear shows the ring of the quality of its item.
85. A reroll shows the ring of the quality of the item that the player rerolls.
86. Each waiting row shows its number as a badge on its picture: 2, 3, ….
87. With two or more slots, the current action shows the badge 1 on its picture.
88. With one slot, the current action shows no number.
89. No waiting row shows the old number circle beside its picture.
90. A tap on a waiting row still opens its change sheet, and Remove still removes it.
91. The sheet of a gather starts with the spot's picture in a 72 dp socket, beside the title.
92. The sheet of a craft starts with the picture of the item that it makes, in a 72 dp socket, beside the title.
93. The sheet of a fight still starts with the monster's card.
94. The queue card and the action sheet are rendered at 408 dp wide before the PR (`CLAUDE.md`).
95. `releases/next/` has a line for players.

**Recipe rows and the materials table**
96. Each recipe row on the Crafting screen starts with the picture of the item that it makes, in a 48 dp socket.
97. Each recipe row on the Cooking screen starts with the picture of the meal that it makes, in a 48 dp socket.
98. A gear or tool recipe shows the ring of its item's quality.
99. A meal recipe shows no ring.
100. The level badge stands on the title line, before the recipe's name.
101. A locked recipe also shows its picture, and its badge keeps the colour of a locked recipe.
102. A tap on a recipe row still opens its action sheet.
103. Each line of the materials table starts with the material's picture in a 32 dp socket, before its name.
104. A tap on a line opens the card of that material.
105. The card of a material from the table shows no buttons.
106. A waiting reroll on the queue card shows no stop line.
107. A current reroll on the queue card shows no stop line.
108. A waiting fight still shows its stop line.
109. The Crafting screen, the Cooking screen and the sheet of a craft are rendered at 408 dp wide before the PR
     (`CLAUDE.md`).

**The launcher icon**
110. In each density, the emblem covers the whole circle of 72 dp in the centre of the 108 dp icon: no pixel inside
     it is transparent.
111. The one-colour emblem has the same size as the emblem, and still one colour.
112. The adaptive icon keeps its three layers: the background `#060708`, the emblem and the one-colour emblem.

## History
- 2026-10-22: first version (intent 0014, plan 0017). Criteria 1-28.
- 2026-10-24, amendment 1 (plan 0020): pictures for gathering spots. §3.1; §3.2; §4.2 "Now"; §6; criteria 27, 28 and
  43-50.
- 2026-10-25, amendment 2 (#68): names on the map stay next to their place; three map points move. §2.3 "The ring";
  criteria 27, 28 and 51-59.
- 2026-10-25, amendment 3 (#88, plan 0023): 72 dp pictures on the Achievements screen. §2.3 "Sockets"; §4.2
  "Achievements"; criteria 27, 28 and 60-64.
- 2026-10-26, amendment 4 (#101, plan 0027): a clear selected look, and an outline on button labels. §2.1; §2.2;
  criteria 2c, 27, 28 and 65-75.
- 2026-10-31, spec 0015 amendments 3 and 6: the talents look like a tree, each tree a plate. §4.3.
- 2026-11-01, amendment 5: swipe right to go back. §4.2 "Going back"; criteria 29-36.
- 2026-11-01, amendment 6 (#122, plan 0035): fewer words on Now and World; the step bank sheet. §4.2 "Now", "World";
  criteria 37-42.
- 2026-11-03, amendment 7 (#198, plan 0045): a picture for each profession. Decision 7; §3.1; §4.2 "Now",
  "Professions"; §6; criteria 27, 28 and 76-81.
- 2026-11-06, amendment 8 (#86, plan 0047): pictures for the actions in the queue. §2.3; §3.1; §4.2 "The queue card",
  "The action sheet"; criteria 27, 28 and 82-95.
- 2026-11-06, amendment 9 (PR #216, plan 0048): pictures on recipe rows and in the materials table; no stop line for
  a reroll. §2.3; §4.2 "Professions", "The queue card"; criteria 27, 28, 95 and 96-109.
- 2026-11-06, amendment 10 (#222): the emblem fills the launcher icon. §3.3; criteria 24c and 110-112.
- 2026-11-06, spec 0020 amendment 2 (#197): the kind chips of the bag and the bank use the selected look. §2.2.
- 2026-11-06, spec 0020 amendment 3 (#220): the tabs of the bank screen use the selected look. §2.2.
- 2026-11-10, spec 0008 amendment 7 and its erratum 1 (#254): the portrait in the Character header is 48 dp; the level
  beside the name and seven stats. §2.3; §4.2 "Character"; criterion 8.
- 2026-11-11, spec 0008 amendment 8: the Gear page is a grid of four columns with no figure. §4.2 "Character";
  criterion 9a.
- 2026-11-15 (plan 0068): the amendments and clean edition 1 folded into this file. No rule, number, colour, size or
  criterion changed. (draft)
