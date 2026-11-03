# Draws the six tool shapes in four tiers as SVG (art/items/<id>.svg), the style of art/README.md (#198).
# Run: python art/tools.py [--preview]. Then .\scripts\export-art.ps1 makes the webp files.
# --preview also writes a sheet with the tools at bag size next to nabriis's pictures, in the temp folder.
import os
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'items')
REPO = os.path.dirname(HERE)
INK = '#24140A'  # the outline: dark brown, not black

TIERS = {
    'old':     dict(metal=['#CDBDA6', '#8F7C66', '#5B4736', '#2C2017'], wood=['#B9A07E', '#7F6549', '#3D2C1C'],
                    bind=['#D8BE86', '#8A6A36'], rust=True),
    'copper':  dict(metal=['#FFD8B0', '#DE8650', '#9C4A22', '#4A1E0A'], wood=['#F0B66A', '#B8722F', '#5A3012'],
                    bind=['#D0603E', '#5E1C10'], rust=False),
    'iron':    dict(metal=['#F6F9FA', '#AAB5BC', '#5F6B73', '#262D32'], wood=['#E9AC62', '#A8632A', '#4E290E'],
                    bind=['#C2553A', '#521810'], rust=False),
    'mithril': dict(metal=['#F4FCFF', '#B3DCF2', '#5C8CB2', '#1C2C44'], wood=['#D9A272', '#8E5634', '#3E2112'],
                    bind=['#3D6E9E', '#152A44'], rust=False),
}
IDS = {
    'old': dict(pick='old_pick', hatchet='old_hatchet', hammer='old_hammer', rod='old_rod', bow='old_bow', pot='old_pot'),
}
for t in ('copper', 'iron', 'mithril'):
    IDS[t] = dict(pick=f'{t}_pickaxe', hatchet=f'{t}_hatchet', hammer=f'{t}_hammer', rod=f'{t}_rod',
                  bow=f'{t}_bow', pot=f'{t}_pot')


def defs(p):
    m, w, b = p['metal'], p['wood'], p['bind']
    return f'''<defs>
  <linearGradient id="metal" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="{m[0]}"/><stop offset="0.3" stop-color="{m[1]}"/>
    <stop offset="0.7" stop-color="{m[2]}"/><stop offset="1" stop-color="{m[3]}"/></linearGradient>
  <linearGradient id="metalSide" x1="0" y1="0" x2="1" y2="0">
    <stop offset="0" stop-color="{m[0]}"/><stop offset="0.35" stop-color="{m[1]}"/>
    <stop offset="0.75" stop-color="{m[2]}"/><stop offset="1" stop-color="{m[3]}"/></linearGradient>
  <radialGradient id="metalBall" cx="0.35" cy="0.3" r="0.8">
    <stop offset="0" stop-color="{m[0]}"/><stop offset="0.3" stop-color="{m[1]}"/>
    <stop offset="0.7" stop-color="{m[2]}"/><stop offset="1" stop-color="{m[3]}"/></radialGradient>
  <linearGradient id="wood" x1="0" y1="0" x2="1" y2="0">
    <stop offset="0" stop-color="{w[0]}"/><stop offset="0.4" stop-color="{w[1]}"/><stop offset="1" stop-color="{w[2]}"/></linearGradient>
  <linearGradient id="bind" x1="0" y1="0" x2="1" y2="0">
    <stop offset="0" stop-color="{b[0]}"/><stop offset="1" stop-color="{b[1]}"/></linearGradient>
  <radialGradient id="shadow" cx="0.5" cy="0.5" r="0.5">
    <stop offset="0" stop-color="#000" stop-opacity="0.65"/><stop offset="1" stop-color="#000" stop-opacity="0"/></radialGradient>
  <filter id="grain" x="-10%" y="-10%" width="120%" height="120%">
    <feTurbulence type="fractalNoise" baseFrequency="0.08 1.1" numOctaves="2" seed="7" result="n"/>
    <feColorMatrix in="n" type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  1.1 0 0 0 -0.42" result="d"/>
    <feComposite in="d" in2="SourceAlpha" operator="in" result="d2"/>
    <feMerge><feMergeNode in="SourceGraphic"/><feMergeNode in="d2"/></feMerge></filter>
  <filter id="grit" x="-10%" y="-10%" width="120%" height="120%">
    <feTurbulence type="fractalNoise" baseFrequency="1.4" numOctaves="2" seed="4" result="n"/>
    <feColorMatrix in="n" type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0.9 0 0 0 -0.3" result="d"/>
    <feComposite in="d" in2="SourceAlpha" operator="in" result="d2"/>
    <feMerge><feMergeNode in="SourceGraphic"/><feMergeNode in="d2"/></feMerge></filter>
</defs>'''


def rust(p, spots):
    if not p['rust']:
        return ''
    return ''.join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="#8A4A22" opacity="0.75"/>' for x, y, r in spots)


def haft(x=21.2, y=12, h=31, wdt=5.6):
    return (f'<rect x="{x}" y="{y}" width="{wdt}" height="{h}" rx="{wdt/2}" fill="url(#wood)" filter="url(#grain)" '
            f'stroke="{INK}" stroke-width="1.3"/>'
            f'<path d="M{x+1.6} {y+14} L{x+1.6} {y+h-2}" stroke="#FFE0B0" stroke-width="0.9" stroke-linecap="round" opacity="0.6"/>')


def wraps(p, ys, x=20.6, w=6.8):
    return ''.join(f'<rect x="{x}" y="{y}" width="{w}" height="3.2" rx="1" fill="url(#bind)" stroke="{INK}" stroke-width="1.1"/>'
                   for y in ys)


def pick(p):
    body = (haft() +
            f'<path d="M4 22 C11 7.5, 37 7.5, 44 22 C36 13.8, 12 13.8, 4 22 Z" fill="url(#metal)" filter="url(#grit)" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round"/>'
            + rust(p, [(12, 13.5, 1.1), (33, 12.6, 0.9), (38, 16.5, 0.8)]) +
            f'<rect x="19.6" y="9.6" width="8.8" height="7.6" rx="1.4" fill="url(#metalSide)" stroke="{INK}" stroke-width="1.3"/>'
            + wraps(p, [17, 21.4]) +
            '<path d="M8.5 17.6 C15 10.6, 33 10.6, 39.5 17.6" fill="none" stroke="#FFFFFF" stroke-width="1.1" stroke-linecap="round" opacity="0.85"/>'
            '<circle cx="5.2" cy="21" r="0.9" fill="#FFFFFF"/>')
    return f'<g transform="translate(24 23.5) scale(1.04) rotate(40) translate(-24 -26)">{body}</g>'


def hatchet(p):
    body = (haft(y=10, h=33) +
            f'<path d="M20.5 10 L10 6.6 C5.6 9.2, 3.6 13.4, 4.2 17.2 C4.8 21, 6.8 24.2, 10 26.4 C13 23, 16.5 20, 20.5 18.4 Z" fill="url(#metal)" filter="url(#grit)" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round"/>'
            + rust(p, [(10, 13, 1.1), (14, 21, 0.9)]) +
            f'<path d="M27.5 11 L30.5 11.5 L30.5 16.5 L27.5 17 Z" fill="url(#metalSide)" stroke="{INK}" stroke-width="1.2" stroke-linejoin="round"/>'
            f'<rect x="19.6" y="8.4" width="8.8" height="11" rx="1.4" fill="url(#metalSide)" stroke="{INK}" stroke-width="1.3"/>'
            + wraps(p, [20.6, 25]) +
            '<path d="M9.4 8.2 C6.4 10.4, 5.2 14, 5.6 17.6" fill="none" stroke="#FFFFFF" stroke-width="1.1" stroke-linecap="round" opacity="0.9"/>'
            '<circle cx="9.8" cy="7.6" r="0.8" fill="#FFFFFF"/>')
    return f'<g transform="translate(24 24) scale(1.06) rotate(38) translate(-24 -26)">{body}</g>'


def hammer(p):
    body = (haft(y=14, h=29) +
            f'<path d="M11 7.5 L17 7.5 L17 18.5 L11 18.5 Z" fill="url(#metal)" filter="url(#grit)" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round"/>'
            f'<path d="M17 8.8 L30.5 8.8 L36.5 11.6 L36.5 14.6 L30.5 17.2 L17 17.2 Z" fill="url(#metal)" filter="url(#grit)" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round"/>'
            + rust(p, [(14, 11, 1.1), (29, 13.5, 0.9), (34, 13, 0.7)]) +
            f'<rect x="19.6" y="7.6" width="8.8" height="11" rx="1.4" fill="url(#metalSide)" stroke="{INK}" stroke-width="1.3"/>'
            + wraps(p, [19.6]) +
            '<path d="M12 9.3 L16 9.3 M18 10.3 L30 10.3" stroke="#FFFFFF" stroke-width="1.1" stroke-linecap="round" opacity="0.85"/>')
    return f'<g transform="translate(24 24) scale(1.06) rotate(38) translate(-24 -26)">{body}</g>'


def rod(p):
    # A long pole from the cork grip (bottom left) to the tip (top right), the line hangs to a float.
    m = p['metal']
    return (f'<path d="M41.5 6 C40 14, 39 20, 38.6 27" fill="none" stroke="#E8E2D2" stroke-width="0.7" opacity="0.9"/>'
            f'<path d="M7.5 41.5 L41.5 6" stroke="{INK}" stroke-width="5.2" stroke-linecap="round"/>'
            f'<path d="M7.5 41.5 L41.5 6" stroke="url(#wood)" stroke-width="3.2" stroke-linecap="round"/>'
            f'<path d="M8.3 40.2 L40.8 6.4" stroke="#FFE0B0" stroke-width="0.6" stroke-linecap="round" opacity="0.7"/>'
            f'<path d="M5.5 43.5 L13 35.5" stroke="{INK}" stroke-width="6.4" stroke-linecap="round"/>'
            f'<path d="M5.5 43.5 L13 35.5" stroke="#C8A274" stroke-width="4.4" stroke-linecap="round"/>'
            f'<path d="M6 42.2 L12 35.9" stroke="#E9CDA2" stroke-width="1.2" stroke-linecap="round" opacity="0.8"/>'
            f'<circle cx="16.5" cy="34.5" r="4.4" fill="url(#metalBall)" stroke="{INK}" stroke-width="1.3"/>'
            f'<circle cx="16.5" cy="34.5" r="1.4" fill="{m[3]}"/>'
            f'<path d="M14.2 32.4 A3 3 0 0 1 17.8 31.6" fill="none" stroke="#FFFFFF" stroke-width="0.9" opacity="0.9"/>'
            + ''.join(f'<circle cx="{x}" cy="{y}" r="1.2" fill="url(#metalBall)" stroke="{INK}" stroke-width="0.8"/>'
                      for x, y in [(24, 24.4), (31, 16.9), (37.5, 9.9)]) +
            f'<path d="M38.6 27 L38.6 29" stroke="#E8E2D2" stroke-width="0.7"/>'
            f'<ellipse cx="38.6" cy="31.5" rx="2.6" ry="3.2" fill="#F2EEE4" stroke="{INK}" stroke-width="1.1"/>'
            f'<path d="M36 31.5 A2.6 3.2 0 0 0 41.2 31.5 Z" fill="#C8382A"/>'
            f'<ellipse cx="38.6" cy="31.5" rx="2.6" ry="3.2" fill="none" stroke="{INK}" stroke-width="1.1"/>')


def bow(p):
    # A recurve bow: the limb as a thick stroke with an outline, the string, a grip wrap, tier caps at the tips.
    limb = 'M15 4.5 C11 8, 13.5 12, 19 15 C29 21, 29 28, 19 34 C13.5 37, 11 41, 15 44.5'
    return (f'<path d="M15 4.5 L15 44.5" stroke="#E8E2D2" stroke-width="0.8"/>'
            f'<path d="{limb}" fill="none" stroke="{INK}" stroke-width="5.6" stroke-linecap="round"/>'
            f'<path d="{limb}" fill="none" stroke="url(#wood)" stroke-width="3.6" stroke-linecap="round" filter="url(#grain)"/>'
            f'<path d="M19.5 15.6 C27 20.5, 27.5 25, 25.6 28" fill="none" stroke="#FFE0B0" stroke-width="0.9" stroke-linecap="round" opacity="0.75"/>'
            f'<path d="M24 20.5 C26.6 23, 26.6 26, 24 28.5" fill="none" stroke="{INK}" stroke-width="6.6" stroke-linecap="round"/>'
            f'<path d="M24 20.5 C26.6 23, 26.6 26, 24 28.5" fill="none" stroke="url(#bind)" stroke-width="4.6" stroke-linecap="round"/>'
            + ''.join(f'<circle cx="{x}" cy="{y}" r="1.9" fill="url(#metalBall)" stroke="{INK}" stroke-width="1"/>'
                      for x, y in [(15, 4.8), (15, 44.2)]) +
            # an arrow across the bow
            f'<path d="M6 30 L40 18" stroke="{INK}" stroke-width="2.6" stroke-linecap="round"/>'
            f'<path d="M6 30 L40 18" stroke="#D8B985" stroke-width="1.2" stroke-linecap="round"/>'
            f'<path d="M40.5 17.8 L36 16.2 L37.6 20.6 Z" fill="url(#metal)" stroke="{INK}" stroke-width="1" stroke-linejoin="round"/>'
            f'<path d="M6 30 L3.5 27.4 M8 29.3 L5.5 26.7 M6 30 L4.4 33 M8 29.3 L6.4 32.3" stroke="#B8382A" stroke-width="1.4" stroke-linecap="round"/>')


def pot(p):
    m = p['metal']
    return ('<path d="M18.5 14 C16.5 11.5, 20.5 9.5, 18.5 6.5 C17 4.5, 19 3, 19 3" fill="none" stroke="#E8EEF0" stroke-width="1.4" stroke-linecap="round" opacity="0.55"/>'
            '<path d="M29.5 13 C27.5 10.5, 31.5 8.5, 29.5 5.5 C28 3.5, 30 2, 30 2" fill="none" stroke="#E8EEF0" stroke-width="1.4" stroke-linecap="round" opacity="0.45"/>'
            f'<path d="M8 19 C8 9, 40 9, 40 19" fill="none" stroke="{INK}" stroke-width="3" />'
            f'<path d="M8 19 C8 9, 40 9, 40 19" fill="none" stroke="url(#metalSide)" stroke-width="1.4"/>'
            f'<path d="M14.5 39 L12.5 44 M33.5 39 L35.5 44 M24 40.5 L24 45" stroke="{INK}" stroke-width="3.6" stroke-linecap="round"/>'
            f'<path d="M14.5 39 L12.5 44 M33.5 39 L35.5 44 M24 40.5 L24 45" stroke="{m[2]}" stroke-width="1.8" stroke-linecap="round"/>'
            f'<path d="M7 20 C6.5 33, 13 41.5, 24 41.5 C35 41.5, 41.5 33, 41 20 Z" fill="url(#metalBall)" filter="url(#grit)" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round"/>'
            + rust(p, [(14, 30, 1.3), (31, 35, 1), (35, 26, 0.9)]) +
            f'<ellipse cx="24" cy="20" rx="18" ry="5" fill="url(#metalSide)" stroke="{INK}" stroke-width="1.3"/>'
            f'<ellipse cx="24" cy="20.4" rx="15" ry="3.5" fill="#7A3A16" stroke="{INK}" stroke-width="0.9"/>'
            '<ellipse cx="21" cy="19.6" rx="7" ry="1.4" fill="#C2662A" opacity="0.85"/>'
            '<circle cx="28" cy="20.6" r="1.1" fill="#E7C46A"/><circle cx="18" cy="21" r="0.9" fill="#7FA34A"/>'
            '<path d="M10.5 25 C11 31, 14 35.5, 18 37.6" fill="none" stroke="#FFFFFF" stroke-width="1.2" stroke-linecap="round" opacity="0.6"/>')


FIT = dict(pick=(1.06, 0.5), hatchet=(1.0, 1.6), hammer=(1.02, 0.8), rod=(0.96, 0), bow=(1.0, 0), pot=(0.98, 0.6))
SHAPES = dict(pick=pick, hatchet=hatchet, hammer=hammer, rod=rod, bow=bow, pot=pot)


def svg(tier, shape):
    p = TIERS[tier]
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="48" height="48">{defs(p)}'
            f'<ellipse cx="24" cy="42" rx="19" ry="4.6" fill="url(#shadow)"/><g transform="translate(24 {24+FIT[shape][1]}) scale({FIT[shape][0]}) translate(-24 -24)">{SHAPES[shape](p)}</g></svg>')


os.makedirs(OUT, exist_ok=True)
for tier in TIERS:
    for shape in SHAPES:
        with open(os.path.join(OUT, IDS[tier][shape] + '.svg'), 'w', encoding='utf-8', newline='\n') as f:
            f.write(svg(tier, shape))

if '--preview' not in sys.argv:
    print(f'{len(TIERS) * len(SHAPES)} SVG files in {OUT}')
    sys.exit(0)

# Preview: rows by tier at bag size, nabriis's pictures for comparison, and one row large.
cell = '<div class="cell"><div class="sock"><img src="{src}"></div><div class="cap">{cap}</div></div>'
rows = []
for tier in TIERS:
    cells = ''.join(cell.format(src='file:///' + os.path.join(OUT, IDS[tier][s] + '.svg').replace(os.sep, '/'), cap=IDS[tier][s]) for s in SHAPES)
    rows.append(f'<div class="grid">{cells}</div>')
nab = ''.join(cell.format(src='file:///' + os.path.join(REPO, 'app', 'assets', 'images', 'items', i + '.webp').replace(os.sep, '/'), cap=i + ' (nabriis)')
              for i in ['copper_ore', 'iron_sword', 'bones', 'iron_helm', 'wolf_pelt', 'copper_sword'])
big = ''.join('<div class="sock bigs"><img src="file:///' + os.path.join(OUT, IDS['iron'][s] + '.svg').replace(os.sep, '/') + '"></div>' for s in SHAPES)
html = f'''<!DOCTYPE html><html><head><meta charset="utf-8"><style>
body {{ margin:0; background:#060708; font-family: Segoe UI, sans-serif; color:#E3EAEC; }}
.plate {{ background:#171C21; border-radius:16px; padding:12px 14px; margin:14px; }}
h2 {{ margin:2px 0 8px; font-size:15px; color:#8AC7BC; }}
.grid {{ display:grid; grid-template-columns: repeat(6, 92px); gap:4px; margin-bottom:4px; }}
.cell {{ display:flex; flex-direction:column; align-items:center; }}
.sock {{ width:48px; height:48px; border-radius:12px; background:#000; border:1px solid rgba(185,194,201,.18);
         position:relative; overflow:hidden; display:flex; align-items:center; justify-content:center; }}
.sock::before {{ content:""; position:absolute; inset:0; background: radial-gradient(circle at 50% 42%, rgba(43,51,59,.5), rgba(43,51,59,.19) 60%, transparent 61%); }}
.sock img {{ position:relative; width:39px; height:39px; }}
.cap {{ font-size:9.5px; color:#7F8A90; margin-top:2px; text-align:center; }}
.bigrow {{ display:flex; gap:10px; }}
.bigs {{ width:120px; height:120px; border-radius:22px; }}
.bigs img {{ width:100px; height:100px; }}
</style></head><body>
<div class="plate"><h2>Tools at bag size: old · copper · iron · mithril</h2>{''.join(rows)}
<h2>nabriis, for comparison</h2><div class="grid">{nab}</div></div>
<div class="plate"><h2>Iron, large</h2><div class="bigrow">{big}</div></div>
</body></html>'''
preview = os.path.join(tempfile.gettempdir(), 'itheros-tools-preview.html')
with open(preview, 'w', encoding='utf-8') as f:
    f.write(html)
print(f'Preview: {preview}')
