# Draws the dust, the gems and the boss shards as SVG (art/items/<id>.svg), in the style of art/README.md (#198).
# Run: python art/finds.py. Then .\scripts\export-art.ps1 makes the webp files.
import os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'items')
INK = '#24140A'

# The dust takes the colour of its quality (economy.json): light, base, dark.
DUST = {
    'common_dust':    ['#FFFFFF', '#D6D6D6', '#8A8A8A'],
    'uncommon_dust':  ['#C8F5CA', '#4CAF50', '#1E6A22'],
    'rare_dust':      ['#CDE6FD', '#42A5F5', '#145A9A'],
    'epic_dust':      ['#EBC8F2', '#AB47BC', '#5E1A6E'],
    'legendary_dust': ['#FFE2B8', '#FF9800', '#9A4E00'],
}
# gems: light, base, dark
GEMS = {
    'garnet':       ['#FF9A8A', '#B3122A', '#4A0610'],
    'sapphire':     ['#A8C8FF', '#1E4FC2', '#0A1A52'],
    'star_diamond': ['#FFFFFF', '#CFEFFF', '#6EA8C8'],
}
# boss shards: light, base, dark, glow
SHARDS = {
    'kings_shard':      ['#E6F2D8', '#8EA67A', '#2E3A26', '#B8F08A'],  # the Graveyard King: bone and grave-green
    'chieftains_shard': ['#F2C89A', '#A8642E', '#4A240A', '#FFB060'],  # the Ogre Chieftain: tusk-brown
    'dragons_shard':    ['#FFB09A', '#C83A1E', '#4E0E06', '#FF7A3A'],  # the Young Dragon: ember-red
}

SHADOW = ('<radialGradient id="shadow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#000" stop-opacity="0.65"/>'
          '<stop offset="1" stop-color="#000" stop-opacity="0"/></radialGradient>')
SPARK = 'M{x} {y} l{s} -{t} l{s} {t} l{t} {s} l-{t} {s} l-{s} {t} l-{s} -{t} l-{t} -{s} Z'


def spark(x, y, size=1):
    return f'<path d="{SPARK.format(x=x - 0.8 * size, y=y, s=0.8 * size, t=1.8 * size)}" fill="#FFFFFF" opacity="0.9"/>'


def svg(defs, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="48" height="48"><defs>{SHADOW}{defs}</defs>'
            f'<ellipse cx="24" cy="41" rx="19" ry="4.6" fill="url(#shadow)"/>{body}</svg>')


def dust(item):
    c = DUST[item]
    # A heap of glittering dust, grains around its foot, sparkles on top.
    defs = (f'<radialGradient id="d" cx="0.4" cy="0.3" r="0.75"><stop offset="0" stop-color="{c[0]}"/>'
            f'<stop offset="0.55" stop-color="{c[1]}"/><stop offset="1" stop-color="{c[2]}"/></radialGradient>')
    heap = 'M6 37 C9 30, 14 18, 24 15 C34 18, 39 30, 42 37 C35 40, 13 40, 6 37 Z'
    grains = ''.join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{c[1]}" stroke="{INK}" stroke-width="0.4"/>'
                     for x, y, r in ((5, 39.5, 0.8), (9, 40.8, 0.6), (40, 40.2, 0.8), (44, 38.6, 0.6), (36, 41.4, 0.5)))
    flecks = ''.join(f'<circle cx="{x}" cy="{y}" r="0.55" fill="#FFFFFF" opacity="0.85"/>'
                     for x, y in ((18, 26), (27, 22), (31, 30), (14, 33), (23, 33), (35, 35), (21, 20)))
    body = (f'<path d="{heap}" fill="url(#d)" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round"/>'
            f'<path d="M13 28 C16 22, 20 18, 24 17" fill="none" stroke="#FFFFFF" stroke-width="1.1" stroke-linecap="round" opacity="0.7"/>'
            + grains + flecks + spark(24, 11, 1.2) + spark(35, 18, 0.8) + spark(12, 21, 0.7))
    return svg(defs, body)


def gem(item):
    c = GEMS[item]
    # A cut gem seen from a little above: the table on top, the facets of the crown, the point below.
    defs = (f'<linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{c[0]}"/>'
            f'<stop offset="0.5" stop-color="{c[1]}"/><stop offset="1" stop-color="{c[2]}"/></linearGradient>')
    glow = ''
    if item == 'star_diamond':
        defs += ('<radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#E8FBFF" stop-opacity="0.55"/>'
                 '<stop offset="1" stop-color="#E8FBFF" stop-opacity="0"/></radialGradient>')
        glow = '<circle cx="24" cy="23" r="21" fill="url(#glow)"/>'
    outline = 'M14 10 L34 10 L42 19 L24 40 L6 19 Z'
    facets = (f'<path d="M6 19 L42 19 M14 10 L18 19 L24 10 L30 19 L34 10 M18 19 L24 40 L30 19" fill="none" stroke="{c[2]}" stroke-width="0.9" opacity="0.8"/>'
              f'<path d="M14 10 L34 10 L30 19 L18 19 Z" fill="{c[0]}" opacity="0.55"/>'
              f'<path d="M6 19 L18 19 L24 40 Z" fill="{c[2]}" opacity="0.35"/>'
              f'<path d="M30 19 L42 19 L24 40 Z" fill="{c[2]}" opacity="0.55"/>')
    body = (glow + f'<path d="{outline}" fill="url(#g)" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round"/>' + facets +
            f'<path d="{outline}" fill="none" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round"/>'
            '<path d="M16 12 L22 12" stroke="#FFFFFF" stroke-width="1.2" stroke-linecap="round" opacity="0.9"/>'
            + spark(33, 8, 1.1) + (spark(10, 30, 0.8) if item == 'star_diamond' else ''))
    return svg(defs, body)


def shard(item):
    c = SHARDS[item]
    # A jagged shard of the boss, standing up, with a soft glow of its power and cracks of light.
    defs = (f'<linearGradient id="s" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{c[0]}"/>'
            f'<stop offset="0.5" stop-color="{c[1]}"/><stop offset="1" stop-color="{c[2]}"/></linearGradient>'
            f'<radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="{c[3]}" stop-opacity="0.5"/>'
            f'<stop offset="1" stop-color="{c[3]}" stop-opacity="0"/></radialGradient>')
    outline = 'M22 4 L30 13 L28 18 L35 26 L31 40 L17 40 L13 30 L18 22 L15 15 Z'
    body = ('<ellipse cx="24" cy="23" rx="18" ry="20" fill="url(#glow)"/>'
            f'<path d="{outline}" fill="url(#s)" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round"/>'
            f'<path d="M22 4 L24 19 L31 40 M24 19 L18 22 M24 19 L28 18" fill="none" stroke="{c[2]}" stroke-width="0.9" opacity="0.8"/>'
            f'<path d="M21 26 L24 31 L22 35" fill="none" stroke="{c[3]}" stroke-width="1.2" stroke-linecap="round" opacity="0.95"/>'
            '<path d="M18 15 L21 7" stroke="#FFFFFF" stroke-width="1.1" stroke-linecap="round" opacity="0.8"/>'
            + spark(35, 10, 1))
    return svg(defs, body)


ITEMS = {**{k: (lambda k=k: dust(k)) for k in DUST}, **{k: (lambda k=k: gem(k)) for k in GEMS},
         **{k: (lambda k=k: shard(k)) for k in SHARDS}}

os.makedirs(OUT, exist_ok=True)
for item, draw in ITEMS.items():
    with open(os.path.join(OUT, item + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
        fh.write(draw())
print(f'{len(ITEMS)} SVG files in {OUT}')
