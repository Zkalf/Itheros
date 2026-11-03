# Draws the wood materials (logs and heartwood) as SVG, in the style of art/README.md (#198).
# Run: python art/materials.py [--preview]. Then .\scripts\export-art.ps1 makes the webp files.
import os
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'items')
REPO = os.path.dirname(HERE)
INK = '#24140A'

# bark: light, mid, dark; cut: centre, middle, edge; ring colour; bark marks
WOODS = {
    'oak':  dict(bark=['#B57A44', '#6F4220', '#2E1808'], cut=['#FBE3B2', '#E2B172', '#A8723A'], ring='#B47C3E', mark='#2A1406'),
    'ash':  dict(bark=['#B8AE9C', '#76695A', '#3A3128'], cut=['#FFF4DC', '#EFD9AE', '#C4A774'], ring='#C9AE7C', mark='#3A3026'),
    'pine': dict(bark=['#C9663A', '#7E3418', '#3A1408'], cut=['#FFE9A6', '#F2C766', '#C48A32'], ring='#D09A3E', mark='#3A1206'),
}
# heartwood: centre, middle, edge of the cut; ring colour; the glint
HEART = {
    'oak':  dict(cut=['#E6A260', '#9A5524', '#4E220A'], ring='#3E1A06', glint='#FFD58A', bark=['#8E5A2E', '#4E2C12', '#22100A']),
    'ash':  dict(cut=['#F6D894', '#C99A4C', '#7A5220'], ring='#6A4416', glint='#FFF1BE', bark=['#9C927F', '#5E5446', '#2C251E']),
    'pine': dict(cut=['#FF9E52', '#C4501E', '#64200A'], ring='#5A1A06', glint='#FFC27A', bark=['#B0552E', '#682A12', '#2E1006']),
}


def common_defs():
    return '''
  <radialGradient id="shadow" cx="0.5" cy="0.5" r="0.5">
    <stop offset="0" stop-color="#000" stop-opacity="0.65"/><stop offset="1" stop-color="#000" stop-opacity="0"/></radialGradient>
  <filter id="grain" x="-10%" y="-10%" width="120%" height="120%">
    <feTurbulence type="fractalNoise" baseFrequency="0.08 1.1" numOctaves="2" seed="7" result="n"/>
    <feColorMatrix in="n" type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  1.1 0 0 0 -0.42" result="d"/>
    <feComposite in="d" in2="SourceAlpha" operator="in" result="d2"/>
    <feMerge><feMergeNode in="SourceGraphic"/><feMergeNode in="d2"/></feMerge></filter>'''


def grads(bark, cut):
    return f'''
  <linearGradient id="bark" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="{bark[0]}"/><stop offset="0.45" stop-color="{bark[1]}"/><stop offset="1" stop-color="{bark[2]}"/></linearGradient>
  <radialGradient id="cut" cx="0.42" cy="0.4" r="0.62">
    <stop offset="0" stop-color="{cut[0]}"/><stop offset="0.6" stop-color="{cut[1]}"/><stop offset="1" stop-color="{cut[2]}"/></radialGradient>'''


def log(w):
    # A short, thick log with its cut end at the origin, the body going back to the left.
    return (f'<path d="M-20 -6 L0 -6 A4.6 6 0 0 1 0 6 L-20 6 A4.6 6 0 0 1 -20 -6 Z" fill="url(#bark)" stroke="{INK}" stroke-width="1.3" filter="url(#grain)"/>'
            f'<path d="M-18 -2.6 L-9 -2.8 M-14 2.4 L-5 2.2 M-19 0 L-15 -0.1" stroke="{w["mark"]}" stroke-width="0.8" stroke-linecap="round" opacity="0.8"/>'
            f'<path d="M-19 -4.4 L-2 -4.4" stroke="{w["bark"][0]}" stroke-width="1.1" stroke-linecap="round" opacity="0.8"/>'
            f'<ellipse cx="0" cy="0" rx="4.6" ry="6" fill="url(#cut)" stroke="{INK}" stroke-width="1.3"/>'
            f'<ellipse cx="0" cy="0" rx="3" ry="3.9" fill="none" stroke="{w["ring"]}" stroke-width="0.7"/>'
            f'<ellipse cx="0" cy="0" rx="1.3" ry="1.7" fill="none" stroke="{w["ring"]}" stroke-width="0.7"/>')


def logs_svg(name):
    w = WOODS[name]
    one = log(w)
    pile = ''.join(f'<g transform="translate({x} {y}) rotate(18)">{one}</g>' for x, y in [(26, 34), (39.5, 36), (34, 23.5)])
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="48" height="48"><defs>{common_defs()}{grads(w["bark"], w["cut"])}</defs>'
            f'<ellipse cx="25" cy="41" rx="20" ry="4.8" fill="url(#shadow)"/>'
            f'<g transform="translate(25.5 25.5) scale(1.0) translate(-26.5 -29)">{pile}</g></svg>')


def heart_svg(name):
    # One big log of its wood, like the log pile, so it reads as a log. The cut end shows what makes it rare: a thin
    # pale band of sapwood around a big, deep, glossy heart, with a soft glow and a small sparkle.
    w = WOODS[name]
    h = HEART[name]
    sap = w['cut']
    rings = ''.join(f'<ellipse cx="{dx}" cy="{dy}" rx="{rx}" ry="{ry}" fill="none" stroke="{h["ring"]}" stroke-width="{sw}" opacity="0.8"/>'
                    for rx, ry, dx, dy, sw in [(3.3, 4.3, 0.15, 0.1, 0.6), (2.1, 2.8, 0.25, 0.2, 0.55), (0.9, 1.2, 0.3, 0.25, 0.6)])
    one = (f'<path d="M-22 -6 L0 -6 A4.6 6 0 0 1 0 6 L-22 6 A4.6 6 0 0 1 -22 -6 Z" fill="url(#bark)" stroke="{INK}" stroke-width="1.1" filter="url(#grain)"/>'
           f'<path d="M-20 -2.6 L-11 -2.8 M-16 2.4 L-6 2.2 M-21 0 L-17 -0.1" stroke="{w["mark"]}" stroke-width="0.7" stroke-linecap="round" opacity="0.8"/>'
           f'<path d="M-21 -4.4 L-2 -4.4" stroke="{w["bark"][0]}" stroke-width="1" stroke-linecap="round" opacity="0.8"/>'
           f'<ellipse cx="0" cy="0" rx="4.6" ry="6" fill="url(#sap)" stroke="{INK}" stroke-width="1.1"/>'
           f'<ellipse cx="0.15" cy="0.1" rx="3.7" ry="4.85" fill="url(#heart)"/>'
           + rings +
           f'<path d="M-2.6 -3.4 C-1.6 -4.6, 0.6 -4.9, 2 -4.2" fill="none" stroke="#FFFFFF" stroke-width="0.6" stroke-linecap="round" opacity="0.8"/>')
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="48" height="48"><defs>{common_defs()}'
            f'{grads(w["bark"], sap)}'
            f'<radialGradient id="sap" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="{sap[0]}"/><stop offset="1" stop-color="{sap[2]}"/></radialGradient>'
            f'<radialGradient id="heart" cx="0.4" cy="0.38" r="0.62"><stop offset="0" stop-color="{h["cut"][0]}"/>'
            f'<stop offset="0.55" stop-color="{h["cut"][1]}"/><stop offset="1" stop-color="{h["cut"][2]}"/></radialGradient>'
            f'<radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="{h["glint"]}" stop-opacity="0.5"/>'
            f'<stop offset="1" stop-color="{h["glint"]}" stop-opacity="0"/></radialGradient></defs>'
            f'<ellipse cx="24" cy="41" rx="19" ry="4.6" fill="url(#shadow)"/>'
            f'<circle cx="36" cy="25" r="13" fill="url(#glow)"/>'
            f'<g transform="translate(37.5 27) rotate(18) scale(1.5)">{one}</g>'
            '<path d="M41.2 11.6 l0.8 -1.8 l0.8 1.8 l1.8 0.8 l-1.8 0.8 l-0.8 1.8 l-0.8 -1.8 l-1.8 -0.8 Z" fill="#FFFFFF" opacity="0.9"/>'
            '</svg>')


os.makedirs(OUT, exist_ok=True)
written = []
for name in WOODS:
    written.append((f'{name}_log', logs_svg(name)))
for name in HEART:
    written.append((f'{name}_heartwood', heart_svg(name)))
for item, text in written:
    with open(os.path.join(OUT, item + '.svg'), 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)
print(f'{len(written)} SVG files in {OUT}')

if '--preview' in sys.argv:
    def url(path):
        return 'file:///' + path.replace(os.sep, '/')
    cell = '<div class="cell"><div class="sock"><img src="{src}"></div><div class="cap">{cap}</div></div>'
    mine = ''.join(cell.format(src=url(os.path.join(OUT, i + '.svg')), cap=i) for i, _ in written)
    nab = ''.join(cell.format(src=url(os.path.join(REPO, 'app', 'assets', 'images', 'items', i + '.webp')), cap=i + ' (nabriis)')
                  for i in ['copper_ore', 'bones', 'wolf_pelt', 'iron_ore', 'feathers', 'goblin_hide'])
    big = ''.join(f'<div class="sock bigs"><img src="{url(os.path.join(OUT, i + ".svg"))}"></div>' for i, _ in written)
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
.bigs {{ width:96px; height:96px; border-radius:20px; }}
.bigs img {{ width:80px; height:80px; }}
</style></head><body>
<div class="plate"><h2>Wood at bag size</h2><div class="grid">{mine}</div>
<h2>nabriis, for comparison</h2><div class="grid">{nab}</div></div>
<div class="plate"><h2>Large</h2><div class="bigrow">{big}</div></div>
</body></html>'''
    preview = os.path.join(tempfile.gettempdir(), 'itheros-materials-preview.html')
    with open(preview, 'w', encoding='utf-8') as f:
        f.write(html)
    print(f'Preview: {preview}')
