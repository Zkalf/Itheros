# Spec 0014 amendment 7: a picture for each profession

Status: accepted
Amends: [spec 0014](0014-quiet-teal.md) decision 7 ("Professions keep their icons") and §3.1 (the pictures of
things)
Issue: #198
Product owner: Zkalf (chose on 2026-11-03: Claude draws the pictures, in the style of the #198 comments; a profession
shows its tool)
Date: 2026-11-03

## Why
- The professions show white Material glyphs today: a hammer and pick for Mining, a saw for Woodcutting, a hook for
  Fishing. The glyphs are small, and some do not look like the profession's tool.
- Since #201 each tool item has a picture. The professions can show the same tools.

## Change
1. **The picture of a profession:** each profession has a picture, `professions/<id>.webp`. It shows the profession's
   tool in the iron tier:

   | Profession | Picture |
   |---|---|
   | Mining | pickaxe |
   | Woodcutting | hatchet |
   | Crafting | smith's hammer |
   | Fishing | rod |
   | Hunting | bow |
   | Cooking | cooking pot |

2. **Where it shows:** the picture takes the place of the glyph, at 32 dp, with no socket:
   - on the card of each profession in the Professions tab, before its name,
   - in the header of the profession screen, before its name,
   - in the teacher rows under "Here" on Now.
3. **No picture file:** a profession without a picture file shows its glyph, as today.
4. **The art:** `art/tools.py` draws the six pictures from the same shapes as the tools. `scripts/export-art.ps1`
   exports them.
5. **What stays:**
   - The Professions tab button in the bottom bar keeps its glyph: it is a control (decision 7).
   - The talent icons stay.
   - The tool items keep their own pictures in the bag.
   - The words and the layout of the three places stay.

## Acceptance criteria
**Pictures**
1. Each of the six professions has a file `professions/<id>.webp`.
2. Each profession card in the Professions tab shows the picture of its profession, at 32 dp.
3. The header of each profession screen shows the picture of its profession, at 32 dp.
4. A teacher row under "Here" on Now shows the picture of the teacher's profession, at 32 dp.
5. A profession without a picture file shows its glyph in each of the three places.
6. The Professions tab button in the bottom bar shows its glyph.

**Check and release**
7. Rules, numbers and the save do not change.
8. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.
