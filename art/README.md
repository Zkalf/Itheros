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
  (like the wolf pelt), and one big fish scale for each water.
- `python art/tools.py --preview` (or `art/materials.py`, `art/fish.py` or `art/hunt.py --preview`) also writes a sheet with the tools at bag size next to nabriis's pictures.
- Python is needed only to change the art. The game, its tests and the release do not use it.
