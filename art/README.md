# Art drawn by Claude

Claude draws pictures as SVG in this folder when nabriis has none yet (#198). nabriis can replace any of them: a
webp from nabriis in `app/assets/images/` wins, and its SVG here goes.

## The style
The resources and map objects of Heroes of Might and Magic 3 inspire it (the feel only, no copied art):
- rich, warm, painted colour, light from the top left, a bright edge and a glint,
- a thin dark-brown outline (`#24140A`), not black,
- no frame: the object lies on the plate, with a soft shadow under it,
- tools in four tiers: old (worn, rust, rope), copper, iron, mithril (blue-silver),
- materials show the thing itself; a rare find gets a soft glow and a small sparkle.

## Make the webp files
`.\scripts\export-art.ps1` turns `art/items/<id>.svg` into `app/assets/images/items/<id>.webp` (256 x 256), with
Microsoft Edge. The file name is the item id, so the game finds the picture by itself. `-Only <id>` exports one.

## Change a drawing
- The tools come from `art/tools.py` (Python 3): one function draws each shape, and the tiers only change its
  colours. Change the script, run `python art/tools.py`, then `.\scripts\export-art.ps1`. Never edit the tool SVGs
  by hand: the next run of the script writes them again.
- The wood materials (logs and heartwood) come from `art/materials.py` in the same way: a log pile for each
  log, and one big log with a dark, glossy heart for each heartwood (a rare find).
- The 16 fish come from `art/fish.py`: one fish shape, and each species sets its colours, pattern, fins and its
  mark. The rare fish carry the marks of Wen's tips (moss, a crown fin, a scar, a pale glow).
- The meat, hides and scales come from `art/hunt.py`: a cut of its own for each meat, a rolled hide with a strap
  (like the wolf pelt), and one big fish scale for each water. The rare finds (golden antler, Old Tusk's tusk, snow
  lynx pelt) glow and sparkle like the heartwoods.
- The dust, gems and boss shards come from `art/finds.py` (dust in its quality colour, each shard in the colour
  of its boss). The meals come from `art/meals.py`: served on a plate, in a bowl, in a pie or on a skewer, with steam; each fish or meat keeps
  its colours from `art/fish.py` and `art/hunt.py`, and a feast of a rare catch glows.
- Gear comes from `art/gear.py`: weapons lie on the diagonal like the tools; rings, charms and armour stand up. One
  drawing serves several tiers: the metal (copper, iron, mithril) or the hide (deer, elk, ibex) only changes its colours.
- `python art/tools.py --preview` (or `art/materials.py`, `art/fish.py` or `art/hunt.py --preview`) also writes a sheet with the tools at bag size next to nabriis's pictures.
- The gathering spots come from `art/spots.py` and go to `app/assets/images/spots/`: an ore vein in its rock, a tree, a
  water, a trail with its tracks; the rare find of the spot glints where it fits.
- The achievements without a picture from nabriis come from `art/achievements.py` and go to
  `app/assets/images/achievements/`. They follow nabriis's patches, not the HoMM3 style above: a sewn shield with a
  dark rim and cream stitches, a sky of sun rays, mountains and pines, one flat emblem. The four finds show a gem in
  the colour of their quality. `--preview <file.html>` shows them next to four of nabriis's patches.
- The marker of the water places (Mirror Lake, Smugglers' Cove) comes from `art/places.py` and goes to
  `app/assets/images/places/water.webp`: a gold-ringed medallion like nabriis's markers, with a fish over the waves.
- Python is needed only to change the art. The game, its tests and the release do not use it.
- The empty gear slots come from `art/slots.py` and go to `app/assets/images/slots/`: a flat white silhouette of what
  the slot holds (a helm, a boot, a ring), not the painted style above. The game tints it faint on the dark socket, so
  an empty slot reads as empty and still tells its slot. Ring 1 and Ring 2 share `ring`, the trinkets `trinket`.
  `--preview <file.html>` shows them at 72 and 48 dp.
- The talent icons come from `art/talents.py` (one for each `image` of `talents.json`, to
  `app/assets/images/talents/`), and the small icons of Camp and of the level-up card from `art/icons.py` (to
  `app/assets/images/icons/`): flat white silhouettes like the slots. The game tints them like the stock icons they
  replace (teal for talents). Without its file, a thing keeps its stock icon.
