# Draws the 16 fish as SVG (art/items/<id>.svg), in the style of art/README.md (#198).
# One fish shape with parts; each species sets its colours, pattern, fins and its special mark.
# Run: python art/fish.py [--preview]. Then .\scripts\export-art.ps1 makes the webp files.
import os
import random
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'items')
REPO = os.path.dirname(HERE)
INK = '#24140A'

# back, side, belly; fin colour; pattern; tail; dorsal; depth of the body; rare; special marks
FISH = {
    'perch':         dict(c=['#4E6A2A', '#9AA845', '#F2E3A8'], fin='#E0602E', pat=('bars', '#2E3A14'), tail='fork', dorsal='spiny', d=8.6),
    'pike':          dict(c=['#3E5A2A', '#7C9A4A', '#EDE6BE'], fin='#B8873A', pat=('dots', '#E9E2A0'), tail='fork', dorsal='back', d=5.8, snout=True),
    'golden_carp':   dict(c=['#B8741E', '#F2B53A', '#FFE9A0'], fin='#E08A2A', pat=('scales', '#C9862A'), tail='fork', dorsal='soft', d=8.2, barbels=True, glint=True),
    'old_mossback':  dict(c=['#2E3E1E', '#5E7034', '#C9C08A'], fin='#4E5A2A', pat=('scales', '#2A3614'), tail='round', dorsal='soft', d=9.4, barbels=True, moss=True, rare='#B8E07A'),
    'brown_trout':   dict(c=['#5E4A26', '#B08E50', '#F3E3B8'], fin='#9A7A40', pat=('spots', '#3A2412', '#C0392B'), tail='square', dorsal='soft', d=7.0),
    'eel':           dict(c=['#2E3A1E', '#6E7A3A', '#E2D69A'], fin='#5A522C', pat=None, tail='eel', dorsal='eel', d=3.6, eel=True),
    'silver_salmon': dict(c=['#3E5E6E', '#B9C8CE', '#F4F6F2'], fin='#7E8E94', pat=('spots', '#2A3640'), tail='fork', dorsal='soft', d=7.2, hook=True, glint=True),
    'river_king':    dict(c=['#3A4046', '#7E8A8E', '#D8D6C4'], fin='#C9A13A', pat=('scutes', '#E8D9A0'), tail='fork', dorsal='crown', d=7.4, snout=True, barbels=True, rare='#FFD86A'),
    'sea_bass':      dict(c=['#4A5660', '#A9B4BA', '#EEF0EC'], fin='#7A868C', pat=('lines', '#5E6A72'), tail='square', dorsal='spiny', d=8.0),
    'mackerel':      dict(c=['#1E5A6A', '#5EA8A8', '#F2F4EE'], fin='#5E7E84', pat=('waves', '#10303A'), tail='fork', dorsal='small', d=6.4),
    'moonfish':      dict(c=['#5E6E8E', '#C9B4C4', '#F4E8E8'], fin='#D04A3A', pat=('dots', '#FFFFFF'), tail='fork', dorsal='tall', d=12.5, short=True, glint=True),
    'old_one_eye':   dict(c=['#33393E', '#6E767A', '#C8C4B4'], fin='#4E5458', pat=('scars', '#D9CFC0'), tail='torn', dorsal='spiny', d=9.6, scar=True, rare='#E8C080'),
    'arctic_char':   dict(c=['#2E4250', '#6E8696', '#F08A4A'], fin='#E06A3A', pat=('dots', '#F6E0C0'), tail='square', dorsal='soft', d=7.0, fin_edge=True),
    'frostfin':      dict(c=['#4E7EA0', '#A8D4EA', '#F2FAFF'], fin='#DFF4FF', pat=('dots', '#FFFFFF'), tail='fork', dorsal='soft', d=7.0, frost=True, glint=True),
    'glacier_pike':  dict(c=['#3E5A6E', '#8AA6B6', '#EEF4F4'], fin='#9AB6C4', pat=('dots', '#F2FAFF'), tail='fork', dorsal='back', d=5.8, snout=True),
    'the_pale_one':  dict(c=['#B8C4C4', '#E6ECEA', '#FBFDFC'], fin='#C8D8DA', pat=('scales', '#C0CCCC'), tail='round', dorsal='soft', d=10.0, ghost=True, rare='#A8F0FF'),
}


def body_path(d, short=False):
    # The side of the fish, nose at the left. Depth d is half the height at the thickest point.
    n = 8 if short else 4      # nose x
    t = 37 if short else 38.5  # tail base x
    return (f'M{n} 25 C{n + 3} {25 - d * 0.95}, {n + 14} {25 - d * 1.05}, {t - 8} {25 - d * 0.62} '
            f'C{t - 3.5} {25 - d * 0.4}, {t - 1} {25 - d * 0.18}, {t} 25 '
            f'C{t - 1} {25 + d * 0.18}, {t - 3.5} {25 + d * 0.4}, {t - 8} {25 + d * 0.66} '
            f'C{n + 14} {25 + d * 1.08}, {n + 3} {25 + d * 0.9}, {n} 25 Z')


def tail(kind, t):
    return {
        'fork': f'M{t - 1} 25 L{t + 8} 16.5 L{t + 5.5} 25 L{t + 8} 33.5 Z',
        'square': f'M{t - 1} 25 L{t + 7.5} 18.5 L{t + 7} 25 L{t + 7.5} 31.5 Z',
        'round': f'M{t - 1} 25 C{t + 3} 17, {t + 9} 18, {t + 8.5} 25 C{t + 9} 32, {t + 3} 33, {t - 1} 25 Z',
        'torn': f'M{t - 1} 25 L{t + 8} 17 L{t + 6} 21 L{t + 7.5} 23 L{t + 5} 25 L{t + 8} 33 Z',
    }[kind]


def dorsal(kind, d, short=False):
    top = 25 - d * 0.98
    x0 = 15 if short else 14
    return {
        'spiny': f'M{x0} {top + 1.2} L{x0 + 1.5} {top - 5} L{x0 + 3.5} {top - 1} L{x0 + 5} {top - 5.6} L{x0 + 7} {top - 1} '
                 f'L{x0 + 8.5} {top - 5} L{x0 + 10.5} {top - 0.6} L{x0 + 12} {top - 3.6} L{x0 + 14} {top + 0.6} Z',
        'soft': f'M{x0 + 2} {top + 0.8} C{x0 + 4} {top - 5}, {x0 + 10} {top - 5.6}, {x0 + 13} {top + 0.8} Z',
        'back': f'M28 {25 - d * 0.7} C29 {25 - d * 0.7 - 5}, 33 {25 - d * 0.7 - 4.5}, 34 {25 - d * 0.45} Z',
        'small': f'M{x0 + 3} {top + 0.8} C{x0 + 5} {top - 3.6}, {x0 + 8} {top - 3.6}, {x0 + 10} {top + 0.8} Z',
        'tall': f'M{x0 + 1} {top + 1.6} C{x0 + 4} {top - 4.6}, {x0 + 10} {top - 4.6}, {x0 + 15} {top + 2.2} Z',
        'crown': f'M{x0} {top + 1} L{x0 + 1.5} {top - 6} L{x0 + 3.2} {top - 1.4} L{x0 + 5} {top - 7} L{x0 + 6.8} {top - 1.4} '
                 f'L{x0 + 8.6} {top - 6} L{x0 + 10.4} {top - 1} L{x0 + 12} {top - 4.4} L{x0 + 13.6} {top + 0.8} Z',
    }[kind]


def pattern(spec, d, rnd, short=False):
    if not spec:
        return ''
    kind, col = spec[0], spec[1]
    n0 = 10 if short else 8
    out = []
    if kind == 'bars':
        for x in (13, 18.5, 24, 29.5):
            out.append(f'<path d="M{x} {25 - d} C{x + 1} 22, {x + 1.4} 27, {x + 0.6} {25 + d * 0.5}" stroke="{col}" stroke-width="2.4" stroke-linecap="round" fill="none" opacity="0.75"/>')
    elif kind in ('dots', 'spots'):
        count = 16 if kind == 'dots' else 14
        for _ in range(count):
            x = rnd.uniform(n0 + 3, 34)
            y = rnd.uniform(25 - d * 0.75, 25 + d * 0.25)
            r = rnd.uniform(0.45, 0.8)
            out.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r:.2f}" fill="{col}" opacity="0.85"/>')
        if kind == 'spots' and len(spec) > 2:
            for _ in range(5):
                x = rnd.uniform(n0 + 6, 32)
                y = rnd.uniform(24.5, 25 + d * 0.3)
                out.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="0.65" fill="{spec[2]}"/>')
    elif kind == 'scales':
        for row, y in enumerate((25 - d * 0.55, 25 - d * 0.15, 25 + d * 0.25)):
            for i in range(7):
                x = n0 + 7 + i * 3.6 + (1.8 if row % 2 else 0)
                if x > 35:
                    continue
                out.append(f'<path d="M{x - 1.6:.1f} {y:.1f} A1.8 1.8 0 0 0 {x + 1.6:.1f} {y:.1f}" stroke="{col}" stroke-width="0.7" fill="none" opacity="0.8"/>')
    elif kind == 'scutes':
        for i in range(7):
            x = 12 + i * 3.4
            y = 23.6 - (0.4 if i % 2 else 0)
            out.append(f'<path d="M{x} {y - 1.2} L{x + 1.2} {y} L{x} {y + 1.2} L{x - 1.2} {y} Z" fill="{col}" stroke="{INK}" stroke-width="0.5"/>')
    elif kind == 'lines':
        for y in (22.2, 24.4, 26.6):
            out.append(f'<path d="M12 {y} C20 {y - 0.6}, 28 {y - 0.4}, 35 {y + 0.2}" stroke="{col}" stroke-width="0.7" fill="none" opacity="0.8"/>')
    elif kind == 'waves':
        for i in range(6):
            x = 12 + i * 3.8
            out.append(f'<path d="M{x} {25 - d * 0.85} C{x + 2} {25 - d * 0.55}, {x - 1} {25 - d * 0.3}, {x + 1.2} {24.6}" stroke="{col}" stroke-width="1.1" fill="none" opacity="0.85"/>')
    elif kind == 'scars':
        for x, y in ((16, 21), (24, 27), (29, 22.5)):
            out.append(f'<path d="M{x} {y} l3.4 -1.6 M{x + 0.6} {y + 1.2} l3.2 -1.4" stroke="{col}" stroke-width="0.7" stroke-linecap="round" opacity="0.85"/>')
    return ''.join(out)


def fish_svg(item):
    f = FISH[item]
    rnd = random.Random(item)
    c = f['c']
    d = f['d']
    short = f.get('short', False)
    n = 8 if short else 4
    t = 37 if short else 38.5
    defs = (f'<linearGradient id="body" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{c[0]}"/>'
            f'<stop offset="0.45" stop-color="{c[1]}"/><stop offset="1" stop-color="{c[2]}"/></linearGradient>'
            f'<linearGradient id="fin" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{f["fin"]}"/>'
            f'<stop offset="1" stop-color="{c[0]}"/></linearGradient>'
            '<radialGradient id="shadow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#000" stop-opacity="0.65"/>'
            '<stop offset="1" stop-color="#000" stop-opacity="0"/></radialGradient>'
            f'<clipPath id="side"><path d="{body_path(d, short)}"/></clipPath>')
    glow = ''
    if f.get('rare'):
        defs += (f'<radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="{f["rare"]}" stop-opacity="0.45"/>'
                 f'<stop offset="1" stop-color="{f["rare"]}" stop-opacity="0"/></radialGradient>')
        glow = '<ellipse cx="24" cy="24" rx="23" ry="17" fill="url(#glow)"/>'
    fin_opacity = '0.75' if f.get('frost') or f.get('ghost') else '1'

    if f.get('eel'):
        # A long body in an S, a fin along the back, a small head at the left.
        path = 'M3.5 23.5 C8.5 13, 17 14, 21.5 20.5 C25.5 26.5, 30.5 29, 36.5 24.5 C40 22, 42.5 20.5, 45.5 21.5 C43.5 25, 41 28.5, 37.5 31.5 C30.5 37.5, 22 34, 18 28 C14.8 23.2, 11 23, 8.5 28.2 C6.6 31, 3 29, 3.5 23.5 Z'
        fins = f'<path d="M12 18.2 C16 15.6, 20 17.4, 22.4 20.6 M24 24 C27 28.6, 32 30, 36.4 26.6" stroke="{f["fin"]}" stroke-width="2.2" stroke-linecap="round" fill="none"/>'
        body = (fins + f'<path d="{path}" fill="url(#body)" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round"/>'
                f'<path d="M7 22 C11 17, 16 17.2, 19.5 21.6" stroke="#FFFFFF" stroke-width="0.9" fill="none" stroke-linecap="round" opacity="0.6"/>'
                f'<circle cx="8.6" cy="22.4" r="1.2" fill="#1A1006"/><circle cx="8.2" cy="22" r="0.4" fill="#FFFFFF"/>')
        return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="48" height="48"><defs>{defs}</defs>'
                f'<ellipse cx="24" cy="41" rx="19" ry="4.4" fill="url(#shadow)"/><g transform="translate(0 2)">{body}</g></svg>')

    parts = []
    # fins behind the body
    parts.append(f'<path d="{tail(f["tail"], t)}" fill="url(#fin)" stroke="{INK}" stroke-width="1.2" stroke-linejoin="round" opacity="{fin_opacity}"/>')
    parts.append(f'<path d="{dorsal(f["dorsal"], d, short)}" fill="{f["fin"]}" stroke="{INK}" stroke-width="1.1" stroke-linejoin="round" opacity="{fin_opacity}"/>')
    belly = 25 + d * 0.9
    parts.append(f'<path d="M{n + 15} {belly - 0.6} L{n + 12.5} {belly + 4.2} L{n + 19.5} {belly - 0.2} Z" fill="{f["fin"]}" stroke="{INK}" stroke-width="1" stroke-linejoin="round" opacity="{fin_opacity}"/>')
    parts.append(f'<path d="M{t - 9} {25 + d * 0.62} L{t - 10} {25 + d * 0.62 + 3.4} L{t - 5} {25 + d * 0.5} Z" fill="{f["fin"]}" stroke="{INK}" stroke-width="0.9" stroke-linejoin="round" opacity="{fin_opacity}"/>')
    if f.get('fin_edge'):
        parts.append(f'<path d="M{n + 12.8} {belly + 3.6} L{n + 19.2} {belly}" stroke="#FFFFFF" stroke-width="0.8" opacity="0.9"/>')
    # the body, its pattern clipped to it
    body_op = '0.92' if f.get('ghost') else '1'
    parts.append(f'<path d="{body_path(d, short)}" fill="url(#body)" opacity="{body_op}"/>')
    parts.append(f'<g clip-path="url(#side)">{pattern(f.get("pat"), d, rnd, short)}'
                 f'<path d="M{n + 2} {25 + d * 0.15} C{n + 12} {25 + d * 0.05}, {t - 12} {25 + d * 0.05}, {t} 25" stroke="#FFFFFF" stroke-width="0.6" fill="none" opacity="0.35"/></g>')
    if f.get('moss'):
        for x, y, r in ((14, 25 - d * 0.92, 1.9), (18.5, 25 - d * 1.0, 2.3), (23.5, 25 - d * 0.95, 2.0), (28, 25 - d * 0.78, 1.6), (20, 25 - d * 0.55, 1.3)):
            parts.append(f'<circle cx="{x}" cy="{y:.1f}" r="{r}" fill="#6E9A32" stroke="{INK}" stroke-width="0.6"/>')
            parts.append(f'<circle cx="{x - 0.5}" cy="{y - 0.5:.1f}" r="{r * 0.45:.2f}" fill="#A8D05A"/>')
    parts.append(f'<path d="{body_path(d, short)}" fill="none" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round"/>')
    # gill, lit back, mouth, eye
    gx = n + 7
    parts.append(f'<path d="M{gx} {25 - d * 0.65} C{gx - 1.6} {25 - d * 0.2}, {gx - 1.6} {25 + d * 0.3}, {gx + 0.2} {25 + d * 0.65}" fill="none" stroke="{INK}" stroke-width="0.9" stroke-linecap="round" opacity="0.7"/>')
    parts.append(f'<path d="M{n + 5} {25 - d * 0.72} C{n + 12} {25 - d * 1.0}, {t - 14} {25 - d * 0.98}, {t - 8} {25 - d * 0.58}" fill="none" stroke="#FFFFFF" stroke-width="0.9" stroke-linecap="round" opacity="0.7"/>')
    if f.get('snout'):
        parts.append(f'<path d="M{n - 0.5} 25.2 L{n + 4.5} 25.6" stroke="{INK}" stroke-width="0.8" stroke-linecap="round"/>')
    else:
        parts.append(f'<path d="M{n + 0.3} 25.6 C{n + 1.5} 26.2, {n + 2.5} 26, {n + 3} 25.4" stroke="{INK}" stroke-width="0.8" fill="none" stroke-linecap="round"/>')
    if f.get('hook'):
        parts.append(f'<path d="M{n - 0.2} 24.6 C{n - 1.2} 25.6, {n - 0.6} 26.8, {n + 0.8} 26.6" stroke="{INK}" stroke-width="1" fill="none" stroke-linecap="round"/>')
    if f.get('barbels'):
        parts.append(f'<path d="M{n + 1} 26 C{n - 0.5} 28.5, {n - 2} 29, {n - 2.5} 30.5 M{n + 2} 26.2 C{n + 1.5} 29, {n + 0.5} 30, {n + 0.5} 31.5" stroke="{INK}" stroke-width="0.7" fill="none" stroke-linecap="round"/>')
    ex, ey = n + 3.4, 25 - d * 0.32
    if f.get('scar'):
        parts.append(f'<path d="M{ex - 1.8} {ey - 1.8} L{ex + 1.8} {ey + 1.8} M{ex + 1.8} {ey - 1.8} L{ex - 1.8} {ey + 1.8}" stroke="#E8DCCB" stroke-width="1" stroke-linecap="round"/>')
        parts.append(f'<path d="M{ex - 3} {ey - 3.2} L{ex + 3.4} {ey + 3.4}" stroke="{INK}" stroke-width="0.6" stroke-linecap="round" opacity="0.8"/>')
    elif f.get('ghost'):
        parts.append(f'<circle cx="{ex}" cy="{ey}" r="1.6" fill="#7FE6FF" stroke="{INK}" stroke-width="0.6"/><circle cx="{ex}" cy="{ey}" r="0.7" fill="#E8FCFF"/>')
    else:
        parts.append(f'<circle cx="{ex}" cy="{ey}" r="1.5" fill="#1A1006"/><circle cx="{ex - 0.5}" cy="{ey - 0.5}" r="0.5" fill="#FFFFFF"/>')
    if f.get('glint'):
        parts.append(f'<path d="M{t - 13} {25 - d * 0.6} l0.6 -1.3 l0.6 1.3 l1.3 0.6 l-1.3 0.6 l-0.6 1.3 l-0.6 -1.3 l-1.3 -0.6 Z" fill="#FFFFFF" opacity="0.9"/>')
    sparkle = ''
    if f.get('rare'):
        sparkle = '<path d="M41.2 9.6 l0.8 -1.8 l0.8 1.8 l1.8 0.8 l-1.8 0.8 l-0.8 1.8 l-0.8 -1.8 l-1.8 -0.8 Z" fill="#FFFFFF" opacity="0.9"/>'
    fishy = ''.join(parts)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="48" height="48"><defs>{defs}</defs>'
            f'<ellipse cx="24" cy="41" rx="19" ry="4.4" fill="url(#shadow)"/>{glow}'
            f'<g transform="translate(24 24) rotate(-12) scale(1.12) translate(-24 -24) translate(-1.6 0.6)">{fishy}</g>{sparkle}</svg>')


os.makedirs(OUT, exist_ok=True)
for item in FISH:
    with open(os.path.join(OUT, item + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
        fh.write(fish_svg(item))
print(f'{len(FISH)} SVG files in {OUT}')

if '--preview' in sys.argv:
    def url(path):
        return 'file:///' + path.replace(os.sep, '/')
    cell = '<div class="cell"><div class="sock"><img src="{src}"></div><div class="cap">{cap}</div></div>'
    mine = ''.join(cell.format(src=url(os.path.join(OUT, i + '.svg')), cap=i) for i in FISH)
    nab = ''.join(cell.format(src=url(os.path.join(REPO, 'app', 'assets', 'images', 'items', i + '.webp')), cap=i)
                  for i in ['copper_ore', 'bones', 'wolf_pelt', 'oak_log', 'pine_heartwood', 'iron_rod'])
    big = ''.join(f'<div class="sock bigs"><img src="{url(os.path.join(OUT, i + ".svg"))}"></div>' for i in FISH)
    html = f'''<!DOCTYPE html><html><head><meta charset="utf-8"><style>
body {{ margin:0; background:#060708; font-family: Segoe UI, sans-serif; color:#E3EAEC; }}
.plate {{ background:#171C21; border-radius:16px; padding:12px 14px; margin:14px; }}
h2 {{ margin:2px 0 8px; font-size:15px; color:#8AC7BC; }}
.grid {{ display:grid; grid-template-columns: repeat(8, 76px); gap:4px; margin-bottom:4px; }}
.cell {{ display:flex; flex-direction:column; align-items:center; }}
.sock {{ width:48px; height:48px; border-radius:12px; background:#000; border:1px solid rgba(185,194,201,.18);
         position:relative; overflow:hidden; display:flex; align-items:center; justify-content:center; }}
.sock::before {{ content:""; position:absolute; inset:0; background: radial-gradient(circle at 50% 42%, rgba(43,51,59,.5), rgba(43,51,59,.19) 60%, transparent 61%); }}
.sock img {{ position:relative; width:39px; height:39px; }}
.cap {{ font-size:9px; color:#7F8A90; margin-top:2px; text-align:center; }}
.bigrow {{ display:grid; grid-template-columns: repeat(8, 76px); gap:6px; }}
.bigs {{ width:72px; height:72px; border-radius:16px; }}
.bigs img {{ width:62px; height:62px; }}
</style></head><body>
<div class="plate"><h2>Fish at bag size</h2><div class="grid">{mine}</div>
<h2>Already in the game</h2><div class="grid">{nab}</div></div>
<div class="plate"><h2>Larger</h2><div class="bigrow">{big}</div></div>
</body></html>'''
    preview = os.path.join(tempfile.gettempdir(), 'itheros-fish-preview.html')
    with open(preview, 'w', encoding='utf-8') as fh:
        fh.write(html)
    print(f'Preview: {preview}')
