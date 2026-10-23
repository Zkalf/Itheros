# Spec 0014: Quiet Teal

Status: draft
Intent: [intent/0014-ui-style.md](../intent/0014-ui-style.md) (merged in #32 as 94bcdec, which accepts it; renumbered in 23b96db)
Builds on: spec 0008 + amendments 1–3 (bars, doll, bag, cards, fog), spec 0009 + amendment 1 (one monster sheet),
spec 0010 + amendments 1–3 (Professions, teachers, profession buttons and filters), spec 0011 (meals, hidden
areas), spec 0012 (Who are you?), spec 0004 amendments 2–3 and spec 0005 amendment 3 (the report), spec 0006
amendment 2 (trophy), spec 0002 §9.2 (Risky)
Overrides: intent 0008's "no art budget" and spec 0008 §3.5's icons and corner count (§2.3, §3, §4.2), with
criterion 8's icons (§3); spec 0004 amendment 3's banner icons (§4.2); spec 0002 §3's 💀 (§2.3); spec 0006
criterion 11's river from `world.json` (§4.2); spec 0007 decision 5, the launcher icon (§3.3); the art and portrait
lines out of scope in spec 0002 §10 and spec 0012 §7 (§3.1, §4.2)
Product owner: Zkalf
Date: 2026-10-22

One look for the whole app: slate plates on a black case, one soft teal for the main action and for what is current
or earned, a black border on every button. Monsters, items, achievements, places and the World map get images; what
has none yet shows a marked placeholder, so the style ships first. The report gains a map of the walk, the one data
change. No change to steps, XP, chances, drops or monsters. Sizes are in dp.

## 1. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | The style or today's screens? | **The style sets the look; today's accepted structure stays** (the list under this table). |
| 2 | Light and dark | **Dark only** (intent). The app no longer follows the phone's setting, and neither do the Android windows. |
| 3 | Ship before the images exist? | **Yes** (intent). The build brings images for 48 of the 178 items; the other 130 show their placeholder until made. New content can ship without an image: a check reports placeholders and never fails on them. |
| 4 | Placeholders | **One per kind or slot, plus one generic**, each with a visible "PH" (§3.2). Real images never carry it. |
| 5 | Colour of the PH mark | **Light steel `#B9C2C9`**, because teal already marks actions and earned things. |
| 6 | Images | **AI-made; the image files are their source** (intent). Keyed by the game's ids and bundled: no network code, no new packages, no INTERNET permission. |
| 7 | Fonts | Cormorant Garamond, Alegreya Sans, Alegreya Sans SC and Spectral, bundled, under the **SIL Open Font License 1.1** (intent). Settings shows the licence texts (§4.2). |
| 8 | Which icons become images | An icon that stands for a monster, item, achievement, rank or place becomes its image. Icons in controls, and icons that aren't things, stay (§3.1). Professions keep their six icons: they already differ, and they sit in buttons. |
| 9 | Boss screen | **The monster's own sheet.** Every sheet carries the monster's image on top; a boss (a monster with first-kill drops) gets it across the full width. The intent's boss screen is this sheet: spec 0009 decision 11 keeps one sheet per monster, and stats stay hidden until 10 kills. |
| 10 | Portraits | **Monsters:** their images on rows, sheets, the Bestiary and banners. **The player:** a portrait by origin and gender (both already saved), on the "Who are you?" cards and the Character header; a placeholder until made. No save change. |
| 11 | Route map | **In the away report and its journal entry:** a crop of the World map with the roads walked, the places passed and the ring on the end place (§4.2). It needs the one data change: the report remembers the places walked through (§5). |
| 12 | Talents | **The look only** (§4.3). The intent puts a talents screen in scope, but without talent rules there is nothing to spend; the talent spec builds it. The Character header keeps today's talent line. |
| 13 | When counts show | **From 2 up, for every kind, as today**, now on a badge hanging outside the square. |
| 14 | Each fact once | Seven repeats go (§4.1). A fact shown once today stays; a picture beside the name it shows is not a repeat. |

Kept as accepted: the bottom and top bars (spec 0008 §3.1, spec 0004 decision 3, spec 0006 amendment 2); button
words; squares with image and count only (spec 0008 §3.5, decision 10); the 16-slot doll and 5-column bag (spec 0008
amendment 3); the Character header (spec 0012 §4.4); fog by exploring (spec 0008 decision 5); one sheet per monster,
stats unknown until 10 kills (spec 0009 decision 11, §7.1); a report like a journal entry (spec 0004 amendment 2).

## 2. Look

### 2.1 Colours

| Role | Hex | Used for |
|---|---|---|
| Case | `#060708` | the screen background and the 6 dp gutters between plates |
| Plate | `#171C21` (top `#1C2227` to bottom `#14181D`) | cards, panels, sheets, dialogs, snack bars, the mount and tray |
| Shades | raised `#2B333B` to `#1E242A`; lit `#2E3740` to `#20262D`; sunk `#101418` | slate buttons and chips; the lit tab and selected chips; text fields |
| Teal | `#8AC7BC`, on it `#0D1416`; deep teal `#17292C` to `#112023`, on it `#D3ECE7` | the main button, focus, the current place, "You are here", earned achievements, "New", the rank name, the unseen dot, the loading bar, plate hairlines (at 16%); deep teal: report banners |
| Steel, mist | `#B9C2C9`; `#8FA2AE` | steel: bars (but the step bank), the Active chip, the PH mark; mist: the step bank |
| Text | `#E3EAEC`, muted `#A8B3B8`, faint `#7F8A90` | body, secondary lines, small labels |
| Border | `#000000` | every button, tab, chip and switch, the count badge and the loading bar: 2 dp |
| Short, Risky | `#E08A7C`; `#FBB15A` | inputs the player is short of; the word "Risky" (the orange band, lightened to read on a plate) |

Quality and band colours stay; no other warm colour but Short and Risky. Text reads at 14 : 1 on a plate. Status
bar icons are light.

### 2.2 Fonts, plates and buttons
- **Fonts:** Cormorant Garamond 600 for the wordmark (50, caps, letter-spacing 0.3 em), headlines (33), titles (26)
  and names in rows (20). Alegreya Sans for body (16, 14, 13) and tab labels (700, 12). Alegreya Sans SC, its small
  caps, for button labels (700, 13) and list headings such as "Here" (700, 11), from today's words. Spectral 600,
  lining figures of equal width, for stats (15, 34 large), level badges (14) and the count badge (12.5).
- **Plates:** radius 16, 16 dp padding, a 1 dp teal hairline, 6 dp apart; nothing interactive but the World map
  stands on the case. Sheets: radius 22 at the top. Text fields are sunk, teal ring when focused. Image frames keep
  a neutral rim.
- **Buttons:** every button, in every state, has a **2 dp black border**, a light top line, a dark lip and a 2 dp
  black drop; heights 52 (full width), 44, 38 (top bar), 36; radius 12 (10 at 36). **Teal** (`#A4D7CD` to `#7BB6AB`,
  label `#0D1416`) for today's filled buttons (Allow step access, Try again, Set out, Next, Continue, Start now and
  Add to queue, Learn <profession>, Save); **ghost** (border only) for Cancel, Not now, Keep it, Skip all; **slate**
  for the rest. Pressed sinks (no drop); focused adds a 2 dp gap and teal ring; disabled is `#14181C`, label `#5E676C`.
- **Chips and segments** (Gear | Bag, Log · Bestiary · Lore and the like) are slate, radius 8, with the border; a
  selected one is lit, teal label. Status chips are outlines: Active steel, "New" and "You are here" teal.
- **The mount:** top-bar buttons are 38 dp slate icon buttons on a plate (radius 15, 4 dp padding, 5 dp apart); the
  trophy's dot is teal. Pushed pages show Back alone, as today, on a mount, with its "Back" tooltip, the title
  beside it.
- **The tray:** the bottom bar is a plate (radius 16, 5 dp padding, 6 dp from the edges) with four tabs 5 dp apart:
  50 dp, radius 11, the border, icon over label; idle `#191E23` to `#121519`, label `#98A3A9`; lit with teal.
- The profession buttons and filter chips (spec 0010 amendment 3) are a sideways row of slate buttons and chips.
  Parts still to come follow these rules: the daily chest's card (intent 0013) is a plate on Now and in the report.

### 2.3 Sockets, the count, bars, badges and the ring
- **Sockets:** a dark recess with the neutral rim, radius 12 (10 below 40 dp); 72 dp for heads of cards and sheets
  and portraits, 48 rows and the bag, 40 small rows, 32 banners; doll squares keep today's size (48–72).
- **Quality:** every gear and tool socket has a 2 dp ring in its quality colour, 3 dp inside the rim, Common's
  `#E0E0E0` included; Uncommon to Legendary also add a wash of that colour from the bottom (14, 18, 22, 26%).
  Materials and meals keep the plain rim with no ring, so gear never looks like a material.
- **An empty doll slot:** a dashed ring and its slot's icon, faint, as today; never marked PH.
- **The count badge,** from 2 up for every kind, hangs off the socket's lower right corner (8 dp right, 7 dp below):
  21 dp tall, at least 30 wide, radius 8, the border, fill `#222A31` to `#12171B`, "×14". Grids leave room for it.
- **Bars:** 8 dp, black track; mist for the step bank, teal for unearned achievements and the loading bar (12 dp,
  with the border), steel for every other bar; a bar keeps its number. **Banners:** deep teal, radius 12, teal edge.
  **Level badges:** 32 × 24, radius 7, band colour, the level in `#0E1114` (white on red); the skull band shows a
  skull image at 22 dp, drawn bone-white, in place of 💀; screen readers still say "Level: far too strong".
- **The ring:** one ring marks where the player is, on the World map and the route map: a circle 20 dp wider than
  the marker (64 round 44 dp markers, 58 round 38 dp ones), a 4 dp teal stroke between 2 dp black edges, a dark wash
  inside, a soft teal glow, under the marker and above the roads. Nothing else marks the place.
- **Names:** each goes below its marker (or ring), else above, right or left: the first side inside the map that
  touches no marker, ring, plate or other name. Step plates sit mid-road, or slide beside it away from what they
  would touch. Step plates go first, then the current place's name, then the others in data order. Code places it
  all from the data; a place's marker and name stay one tappable unit.

## 3. Images

### 3.1 What shows an image

| Thing | Keyed by | Shown on | Placeholder |
|---|---|---|---|
| Monster | its id | monster rows, its sheet, Bestiary rows, banners, level-up rows | one |
| Gear | item id | the doll, the bag, the item card, slot sheet rows, banners | one per slot kind (14; rings and trinkets one each) |
| Tool | item id | the bag, the item card | one per profession's tool (6) |
| Material, meal | item id | the bag, the item card, banners, meal lines on Now and Professions | one each |
| Achievement | its id | Achievements (when earned), banners | one; an unearned one shows the locked patch |
| Rank | `rank_<name>` in lower case | the level-up card of a new rank | the generic one |
| Place | fogged: the fog marker; else its own id; else its kind, the first that fits: forge, water only, no monsters, a boss, monsters | the World map, the route map, Now's status card | the place placeholder; water places show today's water icon in a plain 44 dp slate marker, without the mark, until their marker image exists |
| Player | origin and gender, e.g. `coast_fisher_female` | "Who are you?" cards and the Character header (72 dp) | one |

Images are bundled files named by their key. The style's own pictures: the splash, the World map, the skull, the
locked patch, the emblem. Icons in controls, and icons that aren't things, stay: tabs; Trophies, Journal, Settings,
Back; Stop, remove, −/+; Gear | Bag; rows that open something (Open the World map, Travel here, Forge, Camp fire,
teachers); the sync warning, the Next goal flag, the link on a blocked Off hand, the Slayer chip's icon.

### 3.2 Placeholders and the PH mark
- A thing without its own image shows its kind's placeholder, else the generic one; gear never the material one.
- Every placeholder shows "PH", drawn by the app on the object in small letterspaced caps, light steel at 85%,
  weight 700, with a 0.75 dp stroke of `#050708` at 60%, at the file's one label spot (position and angle, kept
  beside it), such as a boot's shaft. Its font size is 22% of the socket's width, clamped to 9–16 dp, at every
  socket size; never on the ring or under the count badge. Real images, the style's pictures,
  the water icon and empty doll slots never carry it. Screen readers say "placeholder picture"; the item card adds
  "Picture coming later" under its image.
- A check in `check.ps1` lists by kind every id in data that shows a placeholder (water places included), and every
  image whose key is not in data. It never fails on them, only when the generic placeholder is missing or an image
  can't be read.

### 3.3 Splash, welcome and launcher
- **Splash** (while the game loads; today a spinner): the splash picture fills the screen; ITHEROS near the top in
  the wordmark style, dark ink `#0B1012` on the sky (no shade), under a small rule and diamond, status bar icons dark;
  at the bottom a plate with the loading bar, "Reading your steps" and "Version <version>".
- **Welcome** ("Your steps are your power") and "Health Connect is needed": the same picture on top in place of
  today's 64 dp icon, cropped to show the walker; then a plate with today's words and the teal button. Status bar
  icons are dark over the picture.
- **Launcher:** the emblem on `#060708`, with a one-colour version for themed icons; the name stays Itheros. Both
  Android window themes (launch and normal) use `#060708` whatever the phone's setting.

## 4. Screens

### 4.1 Each fact once

| Screen | Twice today | Kept |
|---|---|---|
| The four tab screens | the screen's name as the title and on the lit tab | the lit tab; tab screens have no title |
| Now | the place in the status card and in "Here: Camp" | the status card; the list's heading reads "Here" (spec 0008 §3.2) |
| Now's Here list, the area sheet | "10 steps per round" (`combatRoundSteps`) on every monster row | once, in a "Monsters · 10 steps per round" head above the monster rows; spots, teachers, Forge and Camp fire follow as today |
| Item card, bag gear with no bonus stats, for an empty slot | the stats, then the same numbers as the change | the stats, then "Chest is empty" alone (spec 0008 §3.5's "or Slot is empty"); gear with bonus stats keeps its change line, their sum |
| Achievements, earned | "Walk 100 steps" with a full bar and "100 / 100" | the goal and a teal rim; unearned ones keep the bar and its number |
| World | the current place in the theme colour and a pin icon | the ring (§2.3) |
| Journal, Bestiary rows | "Slayer" and a target icon | the word |

### 4.2 Screen by screen
- **Now:** the status card shows the current place's marker (32 dp) in place of the pin; the meal line leads with
  the meal's image; monster rows lead with the monster's (48 dp); the fight log's "── New fight ──" is faint.
- **World:** the World map image fills the width edge to edge at the data's aspect (1.5); its river was drawn along
  today's `mapRiver`, and the code no longer draws one. Markers (44 dp) stand at their data positions with names
  (§2.3); roads carry step counts, roads into fog are dashed without; fog shows "???" (spec 0008 §3.3); hidden areas
  aren't drawn. The area sheet: "You are here" in teal, the Monsters head, rows as on Now.
- **Monster sheet:** one sheet, bestiary card on top, fight choices below. The card leads with the monster's image
  (72 dp); a **boss** (today the Graveyard King, the Ogre Chieftain, the Young Dragon) shows it across the full
  width, at most 200 dp tall. Stats stay "???" until 10 kills (spec 0009 §7.1). Bestiary rows lead with it (40 dp).
- **Character:** the header adds the portrait (72 dp) beside the name; the rank is teal. The doll keeps its layout,
  the figure outline in faint text colour and a blocked Off hand greyed with a link icon. The item card leads with
  the item's image (72 dp); slot sheet rows lead with theirs (40 dp).
- **While you were away and the Journal:** as today; on the away screen, the footnote and **Continue** share one
  plate at the bottom.
  Banners for levels, lore notes, profession levels and the sea chart are text only; the others lead with the image
  of what they name: the achievement, the monster or the item (finds, trophy fish, rerolls, bottles, the chest).
- **Route map:** with two or more places in the route (§5), a band of the World map image sits between banners and
  lines, at the World tab's scale and as wide as the plate, from 24 dp above the route's highest place to 24 dp below
  its lowest (where the map allows), at least 120 dp tall. It shows the roads walked with their step counts, the
  places passed (38 dp markers, names by §2.3) and the ring on the end place, nothing else.
- **Level-up:** a new rank's card shows the rank's image (72 dp) in place of the icon; other cards show none. "What's
  new" rows lead with the monster's image, or that of the item a recipe makes; spots and talent points have none.
- **"Who are you?":** each origin card leads with the portrait (72 dp) for that origin and the gender picked, changing
  as the gender does; the selected card has the teal ring (the theme colour, spec 0012 §4.1).
- **Achievements:** a list as today. Earned: the image (48 dp, teal rim), name, goal, reward, "New" when not seen
  before. Unearned: the locked patch, name, goal, reward, a teal bar and "x / y".
- **Professions:** as today, in the style. **Settings:** a new row **Licences**, above the version, opens a page with
  each of the four fonts' names, copyright lines and the SIL Open Font License 1.1 text.

### 4.3 Talents (the look only)
Not built now; the talent spec builds the screen and may change this. Its look: a page head with the points left;
per path a plate with its image (72 dp), name and one line; progress as teal pips, one per step, a taken step filled;
the spend button slate; no count beside the pips.

## 5. Save: the one data change
- A report keeps a **route**: the place the player stood in before the steps, then every place arrived at, in
  order, including places passed on a walk of several roads. With no arrival, the route is empty.
- Reports merged across syncs and days join their routes; the place where one ends and the next begins shows once.
- It is saved with the journal entry, like the news lists of specs 0009–0011: an entry saved before this spec loads
  with an empty route and shows no map. Every fixture in `app/test/fixtures/saves/` loads. No save version changes:
  the game state stays at version 10 and the save file at 3. Portraits read the saved origin and gender.

## 6. Out of scope
A fight scene and animation; the talent rules and building the talents screen; a boss screen apart from the sheet;
a light theme; an appearance editor; images for professions, teachers, spots, lore notes and areas; zooming the map;
sound; any change to rules or numbers. Missing images come later as content, with no spec.

## 7. Concerns
1. **Placeholders at first (medium, intended).** Three items in four and every tool, meal and portrait start
   without images (about 28 placeholders, most still to make); "Who are you?", the first game screen, opens on six
   identical placeholder portraits. The PH mark says so plainly; each image is a file.
2. **Tests that pin today's look (medium).** About six widget tests change by design (the skull, a banner icon,
   "Here: …", the bag's count and borders, the card's repeated stats), up to ten more if widget types or names move;
   widget types may stay, themed. The plan rewrites each with its replacement, as plan 0010 did.
3. **Size (low).** With all images in, the app grows by about 10 MB (intent). The plan measures the APK.
4. **The image and the data (low).** The World map image holds its own river and ground: a later change to
   `mapRiver`, or a place added in data, doesn't change them until the image is redone. Nothing breaks.

## 8. Acceptance criteria
1. The app and both Android window themes are dark (`#060708`) whatever the phone's setting (today all follow it).
   The theme uses the §2.1 colours, no warm one but the quality and band colours, Short and Risky; the four fonts
   are bundled and used as §2.2, and Settings has a Licences row with their texts.
2. Every button, tab, chip, segment and switch has a 2 dp black border when enabled, pressed, focused and disabled;
   teal, ghost and slate buttons are as §2.2 lists them, with today's words; Back keeps its tooltip; top-bar buttons
   stand on a mount, the tabs on a tray, and no button stands on the case.
3. The bottom bar has exactly Now, World, Professions and Character; the top bar has Trophies (with its dot),
   Journal and Settings on every tab screen; tab screens have no title (today they repeat the tab's name).
4. Each §4.1 repeat shows once, as its last column says: Now's list is headed "Here" (today "Here: <place>"), and an
   empty slot's card drops the change line only when it repeats the stats exactly.
5. Each monster, item, earned achievement, rank and portrait shows its image by its key, else its kind's placeholder,
   else the generic one; gear never shows the material placeholder. A fogged place shows the fog marker; any other
   place shows its own image, else its kind's marker (water: today's water icon). An unearned achievement shows the
   locked patch.
6. Every placeholder shown for a thing without an image carries the §3.2 mark as §3.2 says, and its item card says
   "Picture coming later"; real images, the style's pictures, the water icon and empty doll slots never do. The §3.2
   check lists placeholders by kind and passes; a data-only item, monster, achievement or gear slot without an image
   passes.
7. Bag and doll squares show only the image and, from 2 up, the count on a badge off the lower right ("×3"; today
   inside the corner). Every gear and tool square has a ring in its quality colour (Common included), Uncommon and
   up also a wash; no material or meal square has a ring. The doll keeps 16 slots, the bag 5 columns, gear first.
8. The World map is the World map image with its own river and each marker at its data position; one teal ring
   marks the current place, nothing else (today a coloured marker and a pin); at 360 dp wide and wider, wherever the
   player stands, no plate or name overlaps the ring, a marker or another plate or name, and every name stays inside
   the map.
9. Monster rows, the monster sheet, Bestiary rows and banners show the monster's image; a boss's sheet shows it
   across the full width; tapping a monster opens one sheet; stats stay unknown until 10 kills. The skull band
   shows the skull image, never 💀; screen readers still say "Level: far too strong".
10. Banners for levels, lore notes, profession levels and the sea chart are text only; the others lead with the
    image of what they name (today icons); banners stay above the lines, on the away screen and in the Journal.
11. A report keeps its route across syncs and days, the joining place once; with two or more places it shows the
    §4.2 route map on the away screen and in its journal entry. An entry saved without a route loads with none and
    shows no map; every fixture loads; the save versions (10 and 3) and the report lines are unchanged.
12. The splash shows the picture, ITHEROS and the loading bar (today a spinner); welcome and "Health Connect is
    needed" show the same picture; status bar icons are light, dark over the picture; the launcher is the emblem on
    `#060708` (today a boot and a sword on green).
13. A new rank's level-up card shows the rank's image, other cards no picture; "What's new" rows lead with the
    monster's image or the image of the item a recipe makes; spots and talent points have none.
14. "Who are you?" cards and the Character header show the portrait for the origin and gender, changing with the
    gender picked; the header keeps the name, rank · origin with its seven taps, the eight stats and the talent line.
15. Game rules and data numbers are unchanged, and the existing pacing test stays green.
16. `.\scripts\check.ps1 -Release` is green, with no INTERNET permission and no new package.
