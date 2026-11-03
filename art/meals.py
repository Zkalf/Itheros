# Draws the meals as SVG (art/items/<id>.svg), in the style of art/README.md (#198).
# A meal is served: on a plate, in a bowl or on a skewer; warm food has steam.
# Run: python art/meals.py [--preview <ids>]. Then .\scripts\export-art.ps1 makes the webp files.
import os
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'items')
REPO = os.path.dirname(HERE)
INK = '#24140A'

SHADOW = ('<radialGradient id="shadow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#000" stop-opacity="0.65"/>'
          '<stop offset="1" stop-color="#000" stop-opacity="0"/></radialGradient>'
          '<radialGradient id="plate" cx="0.45" cy="0.35" r="0.7"><stop offset="0" stop-color="#F4EEE0"/>'
          '<stop offset="0.7" stop-color="#CFC4AE"/><stop offset="1" stop-color="#8E8270"/></radialGradient>'
          '<linearGradient id="wood" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C8874A"/>'
          '<stop offset="1" stop-color="#6A3A16"/></linearGradient>')
STEAM = ('<path d="M{x} {y} C{a} {b}, {c} {d}, {x} {e}" fill="none" stroke="#F2F6F8" stroke-width="1.4" '
         'stroke-linecap="round" opacity="0.5"/>')


def steam(x, y):
    return (STEAM.format(x=x, y=y, a=x - 2.5, b=y - 2.5, c=x + 2.5, d=y - 4.5, e=y - 7) +
            STEAM.format(x=x + 6, y=y + 1, a=x + 3.5, b=y - 1.5, c=x + 8.5, d=y - 3.5, e=y - 6))


def spark(x, y, size=1):
    s, t = 0.8 * size, 1.8 * size
    return f'<path d="M{x - s} {y} l{s} -{t} l{s} {t} l{t} {s} l-{t} {s} l-{s} {t} l-{s} -{t} l-{t} -{s} Z" fill="#FFFFFF" opacity="0.9"/>'


def svg(defs, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="48" height="48"><defs>{SHADOW}{defs}</defs>'
            f'<ellipse cx="24" cy="41" rx="19" ry="4.6" fill="url(#shadow)"/>{body}</svg>')


def plate():
    return (f'<ellipse cx="24" cy="31" rx="20" ry="8.5" fill="url(#plate)" stroke="{INK}" stroke-width="1.3"/>'
            f'<ellipse cx="24" cy="30" rx="14.5" ry="5.6" fill="none" stroke="#B0A48C" stroke-width="0.8"/>')


def bowl(food, top, extra=''):
    # A wooden bowl, its stew seen from a little above.
    defs = (f'<radialGradient id="food" cx="0.45" cy="0.4" r="0.7"><stop offset="0" stop-color="{food[0]}"/>'
            f'<stop offset="1" stop-color="{food[1]}"/></radialGradient>')
    body = (f'<path d="M5 24 C5 35, 13 40.5, 24 40.5 C35 40.5, 43 35, 43 24 Z" fill="url(#wood)" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round"/>'
            '<path d="M9 28 C10.5 33.5, 15 37, 21 38" fill="none" stroke="#E0A060" stroke-width="1" stroke-linecap="round" opacity="0.6"/>'
            f'<ellipse cx="24" cy="24" rx="19" ry="6.4" fill="#8A5428" stroke="{INK}" stroke-width="1.3"/>'
            f'<ellipse cx="24" cy="24.4" rx="16.4" ry="4.8" fill="url(#food)" stroke="{INK}" stroke-width="0.8"/>'
            + top + steam(19, 17) + extra)
    return defs, body


def fish_on(x, y, length, back, belly, marks):
    # A cooked fish, lying flat: a body, a tail, an eye, grill marks.
    l = length
    return (f'<path d="M{x + l} {y} L{x + l + 6} {y - 4.5} L{x + l + 5} {y} L{x + l + 6} {y + 4.5} Z" fill="{back}" stroke="{INK}" stroke-width="1.1" stroke-linejoin="round"/>'
            f'<path d="M{x} {y} C{x + 4} {y - 7}, {x + l - 6} {y - 7}, {x + l + 1} {y} C{x + l - 6} {y + 6.5}, {x + 4} {y + 6.5}, {x} {y} Z" '
            f'fill="url(#fishg)" stroke="{INK}" stroke-width="1.2"/>'
            + ''.join(f'<path d="M{x + 7 + i * 5.5} {y - 4.6} L{x + 4.5 + i * 5.5} {y + 4.6}" stroke="{marks}" stroke-width="1.3" stroke-linecap="round" opacity="0.8"/>' for i in range(3)) +
            f'<circle cx="{x + 3.2}" cy="{y - 1}" r="1" fill="#2A1A0A"/>'
            f'<path d="M{x + 5} {y - 3.8} C{x + 10} {y - 5.6}, {x + l - 8} {y - 5.6}, {x + l - 3} {y - 3.6}" fill="none" stroke="#FFFFFF" stroke-width="0.8" stroke-linecap="round" opacity="0.6"/>')


def fish_defs(back, belly):
    return (f'<linearGradient id="fishg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{back}"/>'
            f'<stop offset="1" stop-color="{belly}"/></linearGradient>')


def herbs(x, y):
    return (f'<path d="M{x} {y} c-2 -1.5, -3.5 -0.5, -4 1.5 c2 0.6, 3.4 0, 4 -1.5 Z" fill="#6E9A32" stroke="{INK}" stroke-width="0.6"/>'
            f'<path d="M{x} {y} c1.2 -2.2, 3.2 -2.4, 4.6 -1.2 c-1.2 1.6, -3 2, -4.6 1.2 Z" fill="#8AB83E" stroke="{INK}" stroke-width="0.6"/>')


def grilled_perch():
    return svg(fish_defs('#B0702A', '#F0C878'), plate() + fish_on(9, 29, 22, '#9A5E22', '#F0C878', '#4A2408') + herbs(38, 33) + steam(19, 21))


def pike_steak():
    # A round steak of pike: pale flesh in rings, the backbone in the middle, a browned skin edge.
    body = (plate() +
            f'<ellipse cx="22" cy="28.5" rx="11" ry="6.6" fill="#C08A50" stroke="{INK}" stroke-width="1.2"/>'
            f'<ellipse cx="22" cy="27.6" rx="9.6" ry="5.4" fill="#F6E6CC" stroke="#D8B88C" stroke-width="0.8"/>'
            '<path d="M14 27.6 C17 25, 27 25, 30 27.6 M15.5 29.4 C18 27.8, 26 27.8, 28.5 29.4" fill="none" stroke="#E2C9A0" stroke-width="0.7"/>'
            f'<circle cx="22" cy="27.6" r="1.4" fill="#FFFFFF" stroke="{INK}" stroke-width="0.6"/>'
            '<path d="M14 25.6 C17 23.6, 22 23, 26 23.4" fill="none" stroke="#FFFFFF" stroke-width="0.8" stroke-linecap="round" opacity="0.7"/>'
            + herbs(36, 31) + '<circle cx="35" cy="27" r="2.6" fill="#F2D45A" stroke="#24140A" stroke-width="0.8"/>'
            '<path d="M33.2 27 L36.8 27 M35 25.2 L35 28.8" stroke="#E0B030" stroke-width="0.5"/>' + steam(17, 21))
    return svg('', body)


def venison_skewer():
    # A wooden skewer with chunks of venison and onion, lying across.
    chunks = ''
    for i, (x, y) in enumerate(((14, 30), (21, 25.5), (28, 21), (35, 16.5))):
        if i % 2 == 0:
            chunks += (f'<rect x="{x - 4}" y="{y - 4}" width="8" height="8" rx="2" transform="rotate(-33 {x} {y})" fill="url(#meatg)" stroke="{INK}" stroke-width="1.1"/>'
                       f'<path d="M{x - 2.5} {y - 2.6} L{x + 0.5} {y - 3.4}" stroke="#2A1006" stroke-width="1.1" stroke-linecap="round" opacity="0.7"/>')
        else:
            chunks += (f'<ellipse cx="{x}" cy="{y}" rx="3.2" ry="4" transform="rotate(-33 {x} {y})" fill="#F2E2C2" stroke="{INK}" stroke-width="1"/>'
                       f'<ellipse cx="{x}" cy="{y}" rx="1.6" ry="2.2" transform="rotate(-33 {x} {y})" fill="none" stroke="#C9A878" stroke-width="0.6"/>')
    defs = ('<radialGradient id="meatg" cx="0.4" cy="0.35" r="0.7"><stop offset="0" stop-color="#B8582C"/>'
            '<stop offset="1" stop-color="#5A1E0A"/></radialGradient>')
    body = (f'<path d="M6 36 L42 12" stroke="{INK}" stroke-width="2.8" stroke-linecap="round"/>'
            '<path d="M6 36 L42 12" stroke="#D8A868" stroke-width="1.4" stroke-linecap="round"/>' + chunks + steam(22, 15))
    return svg(defs, body)


def boar_stew():
    defs, body = bowl(['#B06A30', '#5E2E10'],
                      '<rect x="15" y="21" width="4" height="3.4" rx="1" fill="#7A3A1C" stroke="#24140A" stroke-width="0.6"/>'
                      '<rect x="25" y="22.4" width="4.4" height="3.4" rx="1" fill="#7A3A1C" stroke="#24140A" stroke-width="0.6"/>'
                      '<circle cx="21.5" cy="25.6" r="1.4" fill="#E8862A" stroke="#24140A" stroke-width="0.5"/>'
                      '<circle cx="31.5" cy="24.2" r="1.3" fill="#E8862A" stroke="#24140A" stroke-width="0.5"/>'
                      '<circle cx="18.5" cy="25.8" r="0.9" fill="#7FA34A"/><circle cx="28.4" cy="21.6" r="0.9" fill="#7FA34A"/>')
    return svg(defs, body)


def golden_carp_curry():
    defs, body = bowl(['#FFD24A', '#C8841A'],
                      '<path d="M17 23.5 C19 21.4, 25 21.2, 27.5 23.6 C25 25.8, 19 25.8, 17 23.5 Z" fill="#F6C064" stroke="#24140A" stroke-width="0.7"/>'
                      '<path d="M27.5 23.6 L30.4 21.8 L30 25.4 Z" fill="#E0962A" stroke="#24140A" stroke-width="0.6"/>'
                      '<circle cx="13.5" cy="24.4" r="0.9" fill="#FFF4D0"/><circle cx="33.5" cy="23.2" r="0.9" fill="#FFF4D0"/>'
                      '<circle cx="31" cy="25.4" r="0.7" fill="#C0392B"/><circle cx="15.5" cy="22.6" r="0.7" fill="#7FA34A"/>',
                      spark(36, 13, 1))
    return svg(defs, body)


def mossback_feast():
    # A feast for the rare catch: a big green-tinged fish roast on a platter with greens, and a glow.
    defs = (fish_defs('#4E6A2A', '#D8C88A') +
            '<radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#B8E07A" stop-opacity="0.45"/>'
            '<stop offset="1" stop-color="#B8E07A" stop-opacity="0"/></radialGradient>')
    body = ('<ellipse cx="24" cy="26" rx="23" ry="17" fill="url(#glow)"/>' + plate() +
            fish_on(6, 28.5, 26, '#3E5420', '#D8C88A', '#2A1A08') +
            herbs(9, 34) + herbs(37, 35) +
            '<circle cx="14" cy="34.5" r="1.6" fill="#C0392B" stroke="#24140A" stroke-width="0.5"/>'
            '<circle cx="33" cy="35.2" r="1.6" fill="#E8862A" stroke="#24140A" stroke-width="0.5"/>'
            + steam(18, 20) + spark(40, 12, 1.1))
    return svg(defs, body)


ITEMS = dict(grilled_perch=grilled_perch, pike_steak=pike_steak, venison_skewer=venison_skewer, boar_stew=boar_stew,
             golden_carp_curry=golden_carp_curry, mossback_feast=mossback_feast)

os.makedirs(OUT, exist_ok=True)
for item, draw in ITEMS.items():
    with open(os.path.join(OUT, item + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
        fh.write(draw())
print(f'{len(ITEMS)} SVG files in {OUT}')

if '--preview' in sys.argv:
    ids = sys.argv[sys.argv.index('--preview') + 1:] or list(ITEMS)

    def url(path):
        return 'file:///' + path.replace(os.sep, '/')
    cell = '<div class="cell"><div class="sock"><img src="{src}"></div><div class="cap">{cap}</div></div>'
    mine = ''.join(cell.format(src=url(os.path.join(OUT, i + '.svg')), cap=i) for i in ids)
    html = f'''<!DOCTYPE html><html><head><meta charset="utf-8"><style>
body {{ margin:0; background:#060708; font-family: Segoe UI, sans-serif; color:#E3EAEC; }}
.plate {{ background:#171C21; border-radius:16px; padding:12px 14px; margin:14px; }}
.grid {{ display:grid; grid-template-columns: repeat(6, 92px); gap:4px; }}
.cell {{ display:flex; flex-direction:column; align-items:center; margin-bottom:6px; }}
.sock {{ width:48px; height:48px; border-radius:12px; background:#000; border:1px solid rgba(185,194,201,.18);
         position:relative; overflow:hidden; display:flex; align-items:center; justify-content:center; }}
.sock::before {{ content:""; position:absolute; inset:0; background: radial-gradient(circle at 50% 42%, rgba(43,51,59,.5), rgba(43,51,59,.19) 60%, transparent 61%); }}
.sock img {{ position:relative; width:39px; height:39px; }}
.big .sock {{ width:84px; height:84px; border-radius:18px; }}
.big .sock img {{ width:72px; height:72px; }}
.cap {{ font-size:9.5px; color:#7F8A90; margin-top:2px; text-align:center; }}
</style></head><body>
<div class="plate"><div class="grid">{mine}</div></div>
<div class="plate big"><div class="grid">{mine}</div></div>
</body></html>'''
    preview = os.path.join(tempfile.gettempdir(), 'itheros-meals-preview.html')
    with open(preview, 'w', encoding='utf-8') as fh:
        fh.write(html)
    print(f'Preview: {preview}')
