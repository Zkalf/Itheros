# Draws gear as SVG (art/items/<id>.svg), in the style of art/README.md (#198). Weapons lie on the diagonal, handle
# bottom left, like the tools and nabriis's copper sword. One drawing serves several tiers: the metal or the leather
# only changes its colours (copper, iron, mithril; deer, elk, ibex hide).
# Run: python art/gear.py [--preview]. Then .\scripts\export-art.ps1 makes the webp files.
import os
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'items')
REPO = os.path.dirname(HERE)
INK = '#24140A'

DEFS = '''
<radialGradient id="shadow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#000" stop-opacity="0.65"/><stop offset="1" stop-color="#000" stop-opacity="0"/></radialGradient>
<linearGradient id="copper" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFD8B0"/><stop offset="0.35" stop-color="#DE8650"/><stop offset="0.75" stop-color="#9C4A22"/><stop offset="1" stop-color="#4A1E0A"/></linearGradient>
<linearGradient id="bone" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFF8E8"/><stop offset="0.6" stop-color="#DCCDAA"/><stop offset="1" stop-color="#8E7E5E"/></linearGradient>
<linearGradient id="wood" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#F0B66A"/><stop offset="0.4" stop-color="#B8722F"/><stop offset="1" stop-color="#5A3012"/></linearGradient>
<linearGradient id="leather" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E8B478"/><stop offset="0.5" stop-color="#B07438"/><stop offset="1" stop-color="#5E3812"/></linearGradient>
<linearGradient id="wrap" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C2553A"/><stop offset="1" stop-color="#521810"/></linearGradient>
<linearGradient id="gold" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFE9A8"/><stop offset="0.45" stop-color="#E0A23A"/><stop offset="1" stop-color="#7A4A0A"/></linearGradient>
<linearGradient id="gem" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FF9A8A"/><stop offset="0.5" stop-color="#B3122A"/><stop offset="1" stop-color="#4A0610"/></linearGradient>
<radialGradient id="scale" cx="0.4" cy="0.3" r="0.8"><stop offset="0" stop-color="#F2FAE6"/><stop offset="0.55" stop-color="#A8C894"/><stop offset="1" stop-color="#5E7E52"/></radialGradient>
'''


def lin(i, *stops):
    st = ''.join(f'<stop offset="{k / (len(stops) - 1):.2f}" stop-color="{c}"/>' for k, c in enumerate(stops))
    return f'<linearGradient id="{i}" x1="0" y1="0" x2="1" y2="1">{st}</linearGradient>'


def rad(i, *stops):
    st = ''.join(f'<stop offset="{k / (len(stops) - 1):.2f}" stop-color="{c}"/>' for k, c in enumerate(stops))
    return f'<radialGradient id="{i}" cx="0.4" cy="0.3" r="0.8">{st}</radialGradient>'


# Gradients of the later gear. A picture gets only the ones it uses, so the earlier pictures stay as they were.
EXTRA = {
    'iron': lin('iron', '#D8DEE2', '#8A959C', '#4A545A', '#1E2428'),
    'mithril': lin('mithril', '#F4FCFF', '#A8DCFA', '#4A90C8', '#1C2C44'),
    'fang': lin('fang', '#FFF0C0', '#FFA040', '#D2401A', '#5A1606'),
    'elk': lin('elk', '#C08A58', '#7A4A26', '#3A200C'),
    'ibex': lin('ibex', '#EEE4CE', '#B0A084', '#5A4C38'),
    'lynx': lin('lynx', '#FBF2E0', '#D2BC98', '#8A7454'),
    'sapphire': lin('sapphire', '#A8C8FF', '#1E4FC2', '#0A1A52'),
    'diamond': lin('diamond', '#FFFFFF', '#CFEFFF', '#6EA8C8'),
    'seagem': lin('seagem', '#C8FFF0', '#1E9E86', '#06403A'),
    'rscale': rad('rscale', '#EEF6FF', '#9EB8D6', '#4E6A8E'),
    'tscale': rad('tscale', '#FFFFFF', '#C6ECF6', '#6EA6BE'),
    'ivory': lin('ivory', '#FFFDF4', '#F0E2C2', '#A88A58'),
    'ash': lin('ash', '#F6E6C4', '#C8A272', '#6E4E2C'),
    'pine': lin('pine', '#F6C08A', '#B86A34', '#4E240C'),
    'ecto': ('<radialGradient id="ecto" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#E0FFD0"/>'
             '<stop offset="0.5" stop-color="#7CFF8A" stop-opacity="0.7"/><stop offset="1" stop-color="#2EC060" stop-opacity="0"/></radialGradient>'),
}

# metals: gradient, dark line, light edge
METAL = {'copper': ('copper', '#7A3010', '#FFE2C0'), 'iron': ('iron', '#3A444A', '#FFFFFF'),
         'mithril': ('mithril', '#2E5A82', '#FFFFFF'), 'gold': ('gold', '#7A4A0A', '#FFF6D0')}
# leathers: gradient, cuff, rim, stitches, spots (or None), metal of the buckle and studs
LEATHER = {'deer': ('leather', '#8A5428', '#6A3A16', '#E8C898', '#F4E2C2', 'copper'),
           'elk': ('elk', '#5A3416', '#3A200C', '#D8B080', None, 'iron'),
           'ibex': ('ibex', '#7E6E54', '#5A4C38', '#F6EEDC', None, 'mithril')}


def svg(body):
    extra = ''.join(d for i, d in EXTRA.items() if f'url(#{i})' in body)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="48" height="48"><defs>{DEFS}{extra}</defs>'
            f'<ellipse cx="24" cy="41.5" rx="19" ry="4.6" fill="url(#shadow)"/>{body}</svg>')


def diag(inner):
    # Upright drawing (point up) turned onto the diagonal.
    return f'<g transform="translate(24 24) rotate(45) scale(1.12) translate(-24 -24.6)">{inner}</g>'


def diag_long(inner, s=1.02):
    # The same for the long two-handed weapons, a little smaller so their heads stay on the plate.
    return f'<g transform="translate(24 24) rotate(45) scale({s}) translate(-24 -23)">{inner}</g>'


def shaft(y0, y1, w=3.4):
    return (f'<rect x="{24 - w / 2}" y="{y0}" width="{w}" height="{y1 - y0}" rx="{w / 2}" fill="url(#wood)" stroke="{INK}" stroke-width="1.2"/>'
            f'<path d="M{24 - w / 2 + 0.9} {y0 + 3} L{24 - w / 2 + 0.9} {y1 - 2}" stroke="#FFE0B0" stroke-width="0.7" stroke-linecap="round" opacity="0.6"/>')


def bands(ys, fill='url(#wrap)', w=4.6):
    return ''.join(f'<rect x="{24 - w / 2}" y="{y}" width="{w}" height="2.4" rx="0.8" fill="{fill}" stroke="{INK}" stroke-width="0.9"/>' for y in ys)


def spark(x, y, size=1):
    a, b = 0.8 * size, 1.8 * size
    return (f'<path d="M{x} {y - a - b} l{a} {b} l{b} {a} l-{b} {a} l-{a} {b} l-{a} -{b} l-{b} -{a} l{b} -{a} Z" '
            'fill="#FFFFFF" opacity="0.9"/>')


def studs(points, metal):
    return ''.join(f'<circle cx="{x}" cy="{y}" r="1.1" fill="url(#{METAL[metal][0]})" stroke="{INK}" stroke-width="0.6"/>'
                   for x, y in points)


def spear(metal='copper'):
    g, line, _ = METAL[metal]
    head = (f'<path d="M24 2 C27.5 7, 28.5 12, 26 17 L22 17 C19.5 12, 20.5 7, 24 2 Z" fill="url(#{g})" stroke="{INK}" stroke-width="1.2" stroke-linejoin="round"/>'
            f'<path d="M24 3.5 L24 16" stroke="{line}" stroke-width="0.7" opacity="0.8"/>'
            '<path d="M22.8 6 C22 9, 21.8 12, 22.6 15" fill="none" stroke="#FFFFFF" stroke-width="0.8" stroke-linecap="round" opacity="0.8"/>')
    return svg(diag(shaft(16, 46) + bands([16.5, 19.5]) + head))


def mace(metal='copper'):
    g, line, _ = METAL[metal]
    head = (f'<path d="M24 5 L30 9 L31.5 15 L28 20 L20 20 L16.5 15 L18 9 Z" fill="url(#{g})" stroke="{INK}" stroke-width="1.2" stroke-linejoin="round"/>'
            f'<path d="M24 5 L24 20 M18 9 L28 20 M30 9 L20 20" stroke="{line}" stroke-width="0.8" opacity="0.7"/>'
            f'<path d="M24 1.5 L26 5.5 L22 5.5 Z" fill="url(#{g})" stroke="{INK}" stroke-width="1"/>'
            '<path d="M19 10 C20.5 8, 23 7, 25.5 7.4" fill="none" stroke="#FFFFFF" stroke-width="0.9" stroke-linecap="round" opacity="0.8"/>')
    return svg(diag(shaft(19, 45) + bands([37, 40.5]) + head))


def bone_spear():
    head = (f'<path d="M24 1.5 L27.5 8 L26.2 9.4 L28 13 L26.4 18 L21.6 18 L20 13 L21.8 9.4 L20.5 8 Z" fill="url(#bone)" stroke="{INK}" stroke-width="1.2" stroke-linejoin="round"/>'
            '<path d="M24 3 L24 17" stroke="#A8987A" stroke-width="0.7" opacity="0.8"/>'
            '<path d="M22.6 6 L21.8 12" stroke="#FFFFFF" stroke-width="0.8" stroke-linecap="round" opacity="0.8"/>')
    rope = ''.join(f'<path d="M21.6 {y} L26.4 {y + 1.6}" stroke="#D8BE86" stroke-width="1.6" stroke-linecap="round"/>'
                   f'<path d="M21.6 {y} L26.4 {y + 1.6}" stroke="{INK}" stroke-width="0.4" opacity="0.6"/>' for y in (17.6, 19.6, 21.6))
    return svg(diag(shaft(17, 46) + rope + head))


def bone_club():
    # A big thigh bone as a club, the knobbed end up, a leather grip below.
    club = (f'<path d="M20.5 18 C20 14, 17 12, 17 8 C17 4, 21 3, 23 5.5 C24 4.5, 25 4.5, 26 5.5 C28 3, 32 4, 32 8 C32 12, 29 14, 28.5 18 '
            f'L27.6 40 C27.6 43, 21.4 43, 21.4 40 Z" fill="url(#bone)" stroke="{INK}" stroke-width="1.2" stroke-linejoin="round"/>'
            '<path d="M19.5 8 C19.5 6, 21 5.4, 22 6.4" fill="none" stroke="#FFFFFF" stroke-width="0.9" stroke-linecap="round" opacity="0.85"/>'
            '<path d="M22.6 18 L22.4 30" stroke="#FFFFFF" stroke-width="0.8" stroke-linecap="round" opacity="0.6"/>'
            '<path d="M25 9 L26 12 M27.4 20 L27 23" stroke="#8E7E5E" stroke-width="0.7" stroke-linecap="round"/>')
    return svg(diag(club + bands([32, 35, 38], 'url(#leather)', 7)))


def ring(metal='copper', gem='gem', facet='#5A0814', extra=''):
    # A ring seen at an angle, a gem set on top.
    g, _, edge = METAL[metal]
    r = (f'<ellipse cx="24" cy="29" rx="14" ry="9" fill="none" stroke="{INK}" stroke-width="6.6"/>'
         f'<ellipse cx="24" cy="29" rx="14" ry="9" fill="none" stroke="url(#{g})" stroke-width="4.4"/>'
         f'<path d="M12 26 C14 22.6, 18 21, 22 20.6" fill="none" stroke="{edge}" stroke-width="1" stroke-linecap="round" opacity="0.85"/>'
         f'<path d="M18 19 L30 19 L28 23 L20 23 Z" fill="url(#{g})" stroke="{INK}" stroke-width="1.1" stroke-linejoin="round"/>'
         f'<path d="M24 6 L31 11 L28.5 19.5 L19.5 19.5 L17 11 Z" fill="url(#{gem})" stroke="{INK}" stroke-width="1.2" stroke-linejoin="round"/>'
         f'<path d="M17 11 L31 11 M24 6 L21 11 L24 19.5 L27 11 Z" fill="none" stroke="{facet}" stroke-width="0.7" opacity="0.8"/>'
         '<path d="M20 9.4 L23 7.4" stroke="#FFFFFF" stroke-width="1" stroke-linecap="round" opacity="0.9"/>')
    return svg(r + extra)


def captains_ring():
    # The Drowned Captain's ring: gold, a sea-green stone, barnacles on the band and a strand of sea weed.
    barn = ''.join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="#D8D2C0" stroke="{INK}" stroke-width="0.6"/>'
                   f'<circle cx="{x}" cy="{y}" r="{r * 0.4:.2f}" fill="#6A6458"/>'
                   for x, y, r in ((29.6, 37.4, 1.6), (33.4, 35.8, 1.2), (14, 34, 1.3)))
    weed = ''.join(f'<path d="M36.6 31.6 C40.4 33, 38.6 37.4, 42.6 40" fill="none" stroke="{c}" stroke-width="{w}" stroke-linecap="round"/>'
                   for c, w in ((INK, 2.6), ('#3E8A52', 1.4)))
    return ring('gold', 'seagem', '#06403A', barn + weed)


def oak_charm():
    # A carved oak disc with an acorn and a leaf, on a leather cord.
    charm = ('<path d="M12 6 C14 14, 18 17, 24 17.5 C30 17, 34 14, 36 6" fill="none" stroke="#24140A" stroke-width="2.6" stroke-linecap="round"/>'
             '<path d="M12 6 C14 14, 18 17, 24 17.5 C30 17, 34 14, 36 6" fill="none" stroke="#8A5428" stroke-width="1.4" stroke-linecap="round"/>'
             f'<circle cx="24" cy="28" r="12" fill="url(#wood)" stroke="{INK}" stroke-width="1.3"/>'
             '<circle cx="24" cy="28" r="9.6" fill="none" stroke="#6A3A16" stroke-width="0.8" opacity="0.8"/>'
             '<circle cx="24" cy="17.5" r="2" fill="url(#gold)" stroke="#24140A" stroke-width="0.8"/>'
             '<path d="M20 30 C18 26, 20 22, 24 21 C23 25, 23.5 28, 20 30 Z" fill="#6E9A32" stroke="#24140A" stroke-width="0.7"/>'
             '<path d="M21 28.5 L23.4 22.4" stroke="#3E5A1A" stroke-width="0.5"/>'
             '<ellipse cx="28" cy="31" rx="2.6" ry="3.2" fill="#B07438" stroke="#24140A" stroke-width="0.7"/>'
             '<path d="M25.2 29.4 C25.6 27.2, 30.4 27.2, 30.8 29.4 Z" fill="#6A421E" stroke="#24140A" stroke-width="0.7"/>'
             '<path d="M16 23 C18 19.6, 21 18.6, 24 18.4" fill="none" stroke="#FFFFFF" stroke-width="1" stroke-linecap="round" opacity="0.6"/>')
    return svg(charm)


def gloves(kind='deer'):
    # One hide glove, palm toward us, with stitching and a cuff; the later hides get studs of their metal.
    lea, cuff, _, st, spots, m = LEATHER[kind]
    glove = (f'<path d="M16 42 L16 30 C13 28, 9 25.5, 9 22.5 C9 20.5, 12 20, 14.6 22 L16 23 L16 11 C16 9, 19 9, 19 11 L19.4 20 '
             f'L20 8 C20 6, 23 6, 23 8 L23.4 19.6 L24.2 8.6 C24.2 6.6, 27.2 6.6, 27.2 8.6 L27.4 20.4 L28.4 11 C28.4 9, 31.4 9, 31.4 11 '
             f'L31.6 30 C31.6 35, 30 37.5, 30 42 Z" fill="url(#{lea})" stroke="{INK}" stroke-width="1.2" stroke-linejoin="round"/>'
             f'<rect x="15" y="36" width="16" height="6.6" rx="1.6" fill="{cuff}" stroke="{INK}" stroke-width="1.1"/>'
             f'<path d="M16.6 39.3 L29.4 39.3" stroke="{st}" stroke-width="0.7" stroke-dasharray="1.4 1"/>'
             f'<path d="M19 26 C21 28, 26 28, 28.6 26" fill="none" stroke="{st}" stroke-width="0.7" stroke-dasharray="1.4 1"/>'
             '<path d="M17.4 12 L17.6 20 M21.4 9 L21.6 18" stroke="#FFFFFF" stroke-width="0.8" stroke-linecap="round" opacity="0.55"/>')
    if spots:
        glove += f'<g fill="{spots}" opacity="0.85"><ellipse cx="22" cy="31" rx="1" ry="0.7"/><ellipse cx="26.5" cy="32.6" rx="1" ry="0.7"/></g>'
    else:
        glove += studs(((19.6, 31.4), (23.6, 32.4), (27.6, 31.4)), m)
    return svg(glove)


def bracers(kind='deer'):
    # A leather cuff for the forearm, laced on its side; the later hides get studs of their metal.
    lea, _, rim, st, spots, m = LEATHER[kind]
    cuff = (f'<path d="M13 12 C19 9.6, 29 9.6, 35 12 L33 38 C27 40.4, 21 40.4, 15 38 Z" fill="url(#{lea})" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round"/>'
            f'<ellipse cx="24" cy="12" rx="11" ry="2.8" fill="{rim}" stroke="{INK}" stroke-width="1.1"/>'
            f'<path d="M14.6 16 C20 14, 28 14, 33.4 16 M15.6 34 C20.6 35.8, 27.4 35.8, 32.4 34" fill="none" stroke="{st}" stroke-width="0.7" stroke-dasharray="1.4 1"/>'
            + ''.join(f'<path d="M21 {y} L27 {y + 3} M27 {y} L21 {y + 3}" stroke="#3A2010" stroke-width="1" stroke-linecap="round"/>' for y in (19, 24, 29)) +
            '<path d="M16.5 15 C17 22, 17 28, 17.5 34" fill="none" stroke="#FFFFFF" stroke-width="1" stroke-linecap="round" opacity="0.55"/>')
    if spots:
        cuff += ('<g fill="#F4E2C2" opacity="0.85"><ellipse cx="18.5" cy="22" rx="1" ry="0.7"/><ellipse cx="30" cy="26" rx="1" ry="0.7"/>'
                 '<ellipse cx="19.5" cy="30" rx="1" ry="0.7"/></g>')
    else:
        cuff += studs(((18.4, 20), (18.6, 26), (18.8, 32), (29.6, 20), (29.4, 26), (29.2, 32)), m)
    return svg(cuff)


def belt(kind='deer'):
    # A coiled leather belt with a buckle of its metal.
    lea, inner, _, st, _, m = LEATHER[kind]
    b = (f'<path d="M9 28 C9 18, 39 18, 39 28 C39 36, 9 36, 9 28 Z" fill="none" stroke="{INK}" stroke-width="7.4"/>'
         f'<path d="M9 28 C9 18, 39 18, 39 28 C39 36, 9 36, 9 28 Z" fill="none" stroke="url(#{lea})" stroke-width="5.4"/>'
         f'<path d="M9 28 C9 18, 39 18, 39 28" fill="none" stroke="{st}" stroke-width="0.6" stroke-dasharray="1.4 1" opacity="0.8"/>'
         f'<path d="M16 26 C16 21, 32 21, 32 26" fill="none" stroke="{INK}" stroke-width="6.6"/>'
         f'<path d="M16 26 C16 21, 32 21, 32 26" fill="none" stroke="{inner}" stroke-width="4.6"/>'
         f'<rect x="19" y="29" width="10" height="9" rx="1.6" fill="none" stroke="{INK}" stroke-width="3.6"/>'
         f'<rect x="19" y="29" width="10" height="9" rx="1.6" fill="none" stroke="url(#{METAL[m][0]})" stroke-width="2"/>'
         f'<path d="M24 30 L24 37" stroke="{INK}" stroke-width="1.6" stroke-linecap="round"/>'
         '<path d="M14 22 C18 19.4, 26 18.6, 32 19.6" fill="none" stroke="#FFFFFF" stroke-width="0.9" stroke-linecap="round" opacity="0.5"/>')
    return svg(b)


# scales of the greaves: gradient, base colour
SCALE = {'lake': ('scale', '#5E7E52'), 'river': ('rscale', '#4E6A8E'), 'tarn': ('tscale', '#6EA6BE')}


def greaves(kind='lake'):
    # A pair of greaves standing side by side, like a pair of boots, the front of each leg to the right: the shin
    # curve, the calf at the back, a knee plate on top. Overlapping scales cover them (each row lies over the
    # one below); two leather straps go round each calf. The back one stands a little higher and darker.
    sg, base = SCALE[kind]
    shape = ('M17.5 11 C21 8.6, 26 7, 30 8.6 C33.4 16, 33.6 28, 29 37.6 L32.6 41.6 L16.4 41.6 '
             'C15.4 35, 12.4 27, 14.4 18.6 C15 15, 16 12.6, 17.5 11 Z')

    def one(cid):
        rows = ''
        for r, y in reversed(list(enumerate(range(9, 44, 4)))):
            for i in range(6):
                x = 11.6 + i * 4.6 + (2.3 if r % 2 else 0)
                rows += (f'<path d="M{x - 2.5} {y - 1} L{x + 2.5} {y - 1} L{x + 2.5} {y + 0.6} C{x + 2.5} {y + 4}, {x - 2.5} {y + 4}, {x - 2.5} {y + 0.6} Z" '
                         f'fill="url(#{sg})" stroke="{INK}" stroke-width="0.7"/>')
        straps = ''.join(
            f'<path d="M14.6 {y} C19 {y + 1.4}, 24 {y + 1.6}, 27.6 {y + 0.6}" fill="none" stroke="{INK}" stroke-width="4"/>'
            f'<path d="M14.6 {y} C19 {y + 1.4}, 24 {y + 1.6}, 27.6 {y + 0.6}" fill="none" stroke="#7A4A26" stroke-width="2.4"/>'
            for y in (19, 31))
        return (f'<path d="{shape}" fill="{base}"/>'
                f'<clipPath id="{cid}"><path d="{shape}"/></clipPath><g clip-path="url(#{cid})">{rows}</g>'
                f'<path d="{shape}" fill="none" stroke="{INK}" stroke-width="1.6" stroke-linejoin="round"/>' + straps +
                f'<path d="M24.6 6.6 C28.6 5, 33.6 7, 33.8 11.6 C34 15.6, 30.6 17.6, 27.6 16.4 C25.6 13.6, 24.4 10, 24.6 6.6 Z" '
                f'fill="url(#{sg})" stroke="{INK}" stroke-width="1.4"/>'
                '<path d="M27 8 C29.4 7.2, 31.6 8, 32.4 10" fill="none" stroke="#FFFFFF" stroke-width="1" stroke-linecap="round" opacity="0.85"/>'
                '<path d="M16.4 41.6 L32.6 41.6" stroke="#6A3A16" stroke-width="2.4" stroke-linecap="round"/>')
    back = f'<g transform="translate(3.5 3) scale(0.8)" opacity="1">{one("gb")}<path d="{shape}" fill="#000" opacity="0.28"/></g>'
    front = f'<g transform="translate(14 7.6) scale(0.8)">{one("gf")}</g>'
    return svg(back + front)


def antler(flip=False, s=1.0):
    # A deer antler of gold: the beam curves up from the burr, three tines off its inner side. Thick strokes (ink
    # under gold) keep it readable at bag size. It leans to the right; flip mirrors it.
    beam = 'M0 0 C1 -6, 2 -11, 7 -16 C9 -18, 11 -19.5, 13 -21'
    tines = ['M1.2 -6 C-1 -8, -2.6 -10, -3.4 -13', 'M3.4 -11.6 C2.6 -14, 2.4 -16.6, 3 -19.6', 'M8.2 -16.8 C8.8 -19, 9.8 -21, 11 -23']
    out = ''
    for w, col in ((5.4, INK), (3.4, 'url(#gold)')):
        out += f'<path d="{beam}" fill="none" stroke="{col}" stroke-width="{w}" stroke-linecap="round"/>'
        out += ''.join(f'<path d="{t}" fill="none" stroke="{col}" stroke-width="{w - 0.8}" stroke-linecap="round"/>' for t in tines)
    out += ('<path d="M-0.4 -2 C0.2 -7, 1.6 -11, 5.6 -15" fill="none" stroke="#FFF6D0" stroke-width="0.8" stroke-linecap="round" opacity="0.9"/>'
            f'<ellipse cx="0.2" cy="0.6" rx="3" ry="1.8" fill="url(#gold)" stroke="{INK}" stroke-width="1"/>')
    return f'<g transform="scale({-s if flip else s} {s})">{out}</g>'


def tusk(flip=False, s=1.0):
    # One of Old Tusk's tusks, curving up and out from an iron band. It leans to the right; flip mirrors it.
    out = (f'<path d="M-2.4 0 C-3 -7, 0 -13, 7.6 -17 C4 -12, 2.6 -6.6, 2.4 0 Z" fill="url(#ivory)" stroke="{INK}" stroke-width="1.2" stroke-linejoin="round"/>'
           '<path d="M-1.2 -2 C-1.4 -7, 0.6 -11, 4.4 -14" fill="none" stroke="#FFFFFF" stroke-width="0.8" stroke-linecap="round" opacity="0.9"/>'
           f'<rect x="-3.4" y="-1.6" width="6.8" height="3" rx="1" fill="url(#iron)" stroke="{INK}" stroke-width="0.9"/>')
    return f'<g transform="scale({-s if flip else s} {s})">{out}</g>'


CAPE = ('M9 22 C9 16, 15 12.6, 19 12.4 C20.4 16.6, 27.6 16.6, 29 12.4 C33 12.6, 39 16, 39 22 L41 33 C36 37, 29 36.6, '
        '24 33.4 C19 36.6, 12 37, 7 33 Z')
HEM = 'M7.4 31.6 C12 35.4, 19 35, 24 31.8 C29 35, 36 35.4, 40.6 31.6'
DEER_SPOTS = ('<g fill="#F4E2C2" opacity="0.85"><ellipse cx="15" cy="25" rx="1.1" ry="0.8"/><ellipse cx="19.5" cy="29" rx="1" ry="0.7"/>'
              '<ellipse cx="31" cy="25.6" rx="1.1" ry="0.8"/><ellipse cx="34" cy="29.4" rx="1" ry="0.7"/><ellipse cx="12" cy="29.6" rx="0.9" ry="0.6"/></g>')


def mantle(ornament, fill='url(#leather)', neck='#5E3812', hem='#F0DCB8', stitch='#E8C898', clasp='gold', marks=DEER_SPOTS):
    # A mantle for the shoulders, seen from the front: a neck opening, two rounded flaps, a pale fur edge, a clasp.
    # What it is made of rises from the shoulders (ornament) or covers it (marks).
    return svg(ornament +
               f'<path d="{CAPE}" fill="{fill}" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round"/>'
               f'<path d="M19 12.4 C20.4 16.6, 27.6 16.6, 29 12.4 C27 11.4, 21 11.4, 19 12.4 Z" fill="{neck}" stroke="{INK}" stroke-width="1"/>'
               f'<path d="{HEM}" fill="none" stroke="{INK}" stroke-width="4.4" stroke-linecap="round"/>'
               f'<path d="{HEM}" fill="none" stroke="{hem}" stroke-width="2.6" stroke-linecap="round"/>'
               f'<path d="M24 16.6 L24 31" stroke="{neck}" stroke-width="0.8" opacity="0.7"/>'
               f'<path d="M11 20 C15 17.6, 20 17.6, 23 18.6 M25 18.6 C28 17.6, 33 17.6, 37 20" fill="none" stroke="{stitch}" stroke-width="0.7" stroke-dasharray="1.4 1"/>'
               f'<circle cx="24" cy="18.4" r="1.9" fill="url(#{METAL[clasp][0]})" stroke="{INK}" stroke-width="0.8"/>'
               '<path d="M10.6 21 C11.4 18, 14 15.6, 17.4 14.6" fill="none" stroke="#FFFFFF" stroke-width="1" stroke-linecap="round" opacity="0.55"/>'
               + marks)


def antler_mantle():
    # Deer hide, a golden antler rising from each shoulder.
    return mantle(f'<g transform="translate(14 17.4)">{antler(True, 0.74)}</g>'
                  f'<g transform="translate(34 17.4)">{antler(False, 0.74)}</g>')


def tusk_mantle():
    # Elk hide, a tusk curving up from each shoulder.
    return mantle(f'<g transform="translate(14.4 17)">{tusk(True, 0.92)}</g><g transform="translate(33.6 17)">{tusk(False, 0.92)}</g>',
                  'url(#elk)', '#3A200C', '#E6D2AE', '#D8B080', 'iron', '')


def lynx_mantle():
    # Lynx fur over ibex hide: pale spotted fur, a thick ruff at the neck, a mithril clasp.
    dots = ''.join(f'<ellipse cx="{x}" cy="{y}" rx="{r}" ry="{r * 0.75:.2f}" fill="#4A3828" opacity="0.8"/>'
                   for x, y, r in ((13, 22, 1), (17, 26, 0.9), (12.4, 28.6, 0.9), (20, 30.4, 0.8), (16, 31.6, 0.8), (21, 22.6, 0.8),
                                   (35, 22, 1), (31, 26, 0.9), (35.6, 28.6, 0.9), (28, 30.4, 0.8), (32, 31.6, 0.8), (27, 22.6, 0.8)))
    ruff = ''.join(f'<path d="M11.6 17.6 C16 13.6, 20 16.6, 24 16.6 C28 16.6, 32 13.6, 36.4 17.6" fill="none" stroke="{c}" stroke-width="{w}" stroke-linecap="round"/>'
                   for c, w in ((INK, 5.2), ('#F6ECDA', 3.4)))
    tufts = ''.join(f'<path d="M{x} {y} l{dx} 2.2" stroke="#8A7454" stroke-width="0.7" stroke-linecap="round"/>'
                    for x, y, dx in ((14, 16.6, -0.6), (17, 15.6, 0), (20, 16.4, 0.4), (28, 16.4, -0.4), (31, 15.6, 0), (34, 16.6, 0.6)))
    return mantle('', 'url(#lynx)', '#5A4C38', '#F6ECDA', '#8A7454', 'mithril', dots + ruff + tufts)


def drake_spear():
    # A drake fang as the spearhead, set in a mithril collar.
    head = (f'<path d="M23 1.5 C27.6 5, 28.8 11, 26.6 17.4 L21.6 17.4 C22.8 12, 22.4 7, 23 1.5 Z" fill="url(#fang)" stroke="{INK}" stroke-width="1.2" stroke-linejoin="round"/>'
            '<path d="M23.8 4.4 C25.6 7.6, 26 12, 25.2 15.6" fill="none" stroke="#FFF0C8" stroke-width="0.9" stroke-linecap="round" opacity="0.9"/>'
            f'<path d="M20.6 16.6 L27.4 16.6 L26.4 20.4 L21.6 20.4 Z" fill="url(#mithril)" stroke="{INK}" stroke-width="1" stroke-linejoin="round"/>')
    return svg(diag(shaft(18, 46) + bands([38, 41], 'url(#leather)') + head))


def drake_hammer():
    # A mithril hammer head, a drake fang as the spike at its back and a smaller one on top.
    head = (f'<path d="M17.4 13.4 C13.6 13, 11 11.6, 9.4 9.4 C10.6 14.4, 13.4 18, 17.4 18.6 Z" fill="url(#fang)" stroke="{INK}" stroke-width="1.1" stroke-linejoin="round"/>'
            f'<path d="M22.4 11.6 C22.2 9, 23 7, 24.8 5.4 C24.8 7.6, 25.2 9.6, 26.4 11.6 Z" fill="url(#fang)" stroke="{INK}" stroke-width="1" stroke-linejoin="round"/>'
            f'<rect x="17" y="11" width="15" height="10" rx="1.6" fill="url(#mithril)" stroke="{INK}" stroke-width="1.2"/>'
            f'<rect x="30.4" y="10" width="3.6" height="12" rx="1.2" fill="url(#mithril)" stroke="{INK}" stroke-width="1.1"/>'
            '<path d="M18.6 12.8 L29 12.8" stroke="#FFFFFF" stroke-width="0.9" stroke-linecap="round" opacity="0.85"/>'
            '<path d="M21 16 L28 16" stroke="#2E5A82" stroke-width="0.7" opacity="0.7"/>'
            '<path d="M11.4 11 C12.6 13.6, 14.4 15.4, 16.8 16.2" fill="none" stroke="#FFF0C8" stroke-width="0.7" stroke-linecap="round" opacity="0.85"/>')
    return svg(diag(shaft(14, 46) + bands([38, 41], 'url(#leather)') + head))


def iron_pike():
    # A long ash pike: a narrow iron point with a hook at its side, a leather grip low on the haft.
    head = (f'<path d="M24 1 C26.6 5, 27 9, 25.8 14 L22.2 14 C21 9, 21.4 5, 24 1 Z" fill="url(#iron)" stroke="{INK}" stroke-width="1.2" stroke-linejoin="round"/>'
            '<path d="M24 2.6 L24 13" stroke="#3A444A" stroke-width="0.7" opacity="0.8"/>'
            '<path d="M23 4.6 C22.4 7, 22.4 10, 22.8 12.4" fill="none" stroke="#FFFFFF" stroke-width="0.8" stroke-linecap="round" opacity="0.85"/>'
            f'<path d="M25.6 14 C29 13.6, 31.4 11.6, 32 8.6 C33.2 12.4, 31 16.6, 25.6 17.2 Z" fill="url(#iron)" stroke="{INK}" stroke-width="1.1" stroke-linejoin="round"/>'
            f'<rect x="21.4" y="13.6" width="5.2" height="4.4" rx="1.2" fill="url(#iron)" stroke="{INK}" stroke-width="1"/>')
    return svg(diag_long(shaft(16, 46.4, 3.2) + bands([33, 36, 39], 'url(#leather)', 4.4) + head, 1.0))


def mithril_greatsword():
    # A long mithril blade with a fuller, a broad crossguard with a stone core in its middle, a long grip.
    blade = (f'<path d="M24 1 L27.4 6 L27 31 L21 31 L20.6 6 Z" fill="url(#mithril)" stroke="{INK}" stroke-width="1.2" stroke-linejoin="round"/>'
             '<path d="M24 5 L24 29" stroke="#2E5A82" stroke-width="1.1" stroke-linecap="round" opacity="0.8"/>'
             '<path d="M22.2 7 L22 29" stroke="#FFFFFF" stroke-width="0.9" stroke-linecap="round" opacity="0.9"/>')
    guard = (f'<path d="M14.4 30.6 C17 31.6, 31 31.6, 33.6 30.6 C34.4 32, 34.4 33.6, 33.6 34.8 C31 34, 17 34, 14.4 34.8 C13.6 33.6, 13.6 32, 14.4 30.6 Z" '
             f'fill="url(#mithril)" stroke="{INK}" stroke-width="1.1" stroke-linejoin="round"/>'
             f'<circle cx="24" cy="32.7" r="1.7" fill="#8A7E70" stroke="{INK}" stroke-width="0.7"/>'
             '<circle cx="23.5" cy="32.2" r="0.5" fill="#FFFFFF" opacity="0.8"/>')
    grip = (f'<rect x="22.2" y="34.6" width="3.6" height="8.4" rx="1" fill="#3A2A20" stroke="{INK}" stroke-width="1"/>'
            + ''.join(f'<path d="M22.4 {y} L25.6 {y + 1.2}" stroke="#7A5A40" stroke-width="0.7"/>' for y in (35.6, 37.4, 39.2, 41))
            + f'<circle cx="24" cy="44.6" r="2.4" fill="url(#mithril)" stroke="{INK}" stroke-width="1"/>')
    return svg(diag_long(blade + guard + grip, 1.04))


def drake_halberd():
    # A pine haft, a drake fang as the point, a broad mithril axe blade and a fang hook at the back.
    point = (f'<path d="M23.4 0.6 C27 3.6, 27.6 7.6, 26 11 L22 11 C22.6 7.6, 22.4 4, 23.4 0.6 Z" fill="url(#fang)" stroke="{INK}" stroke-width="1.1" stroke-linejoin="round"/>'
             '<path d="M24 3 C25.4 5.4, 25.6 8, 25 10" fill="none" stroke="#FFF0C8" stroke-width="0.8" stroke-linecap="round" opacity="0.9"/>')
    blade = (f'<path d="M22.4 11 C18 11, 13.6 9.4, 10.4 6.6 C7.4 12.4, 7.4 19.6, 10.4 25.4 C13.6 22.6, 18 21, 22.4 21 Z" '
             f'fill="url(#mithril)" stroke="{INK}" stroke-width="1.2" stroke-linejoin="round"/>'
             '<path d="M10.6 9.4 C9 13.6, 9 18.6, 10.4 22.6" fill="none" stroke="#FFFFFF" stroke-width="0.9" stroke-linecap="round" opacity="0.9"/>'
             '<path d="M16 13 C17 15, 17 17.4, 16 19.4" fill="none" stroke="#2E5A82" stroke-width="0.7" opacity="0.7"/>')
    hook = f'<path d="M25.6 12.6 C28.6 12.6, 30.6 11.4, 32 9.4 C31.8 13, 29.6 16, 25.6 16.6 Z" fill="url(#fang)" stroke="{INK}" stroke-width="1" stroke-linejoin="round"/>'
    collar = f'<rect x="21.2" y="10.4" width="5.6" height="11.2" rx="1.2" fill="url(#mithril)" stroke="{INK}" stroke-width="1"/>'
    return svg(diag_long(shaft(10, 46.4, 3.4) + bands([34, 37, 40], 'url(#leather)', 4.6) + blade + hook + collar + point, 1.0))


def ash_totem():
    # A small totem carved from ash heartwood, two faces one above the other; the eyes glow with ectoplasm. A pair of
    # carved wings at the top, a cord to wear it.
    post = 'M18 12 C18 7, 30 7, 30 12 L30.6 39 C28 40.6, 20 40.6, 17.4 39 Z'
    eyes = ''.join(f'<circle cx="{x}" cy="{y}" r="2.6" fill="url(#ecto)"/>'
                   f'<ellipse cx="{x}" cy="{y}" rx="1.3" ry="1" fill="#C8FFC0" stroke="{INK}" stroke-width="0.7"/>'
                   for x, y in ((21.4, 15), (26.6, 15), (21.4, 28), (26.6, 28)))
    wing = ('M18 14 C14 11.6, 10 12.4, 8 16 C11 15.6, 13 16.6, 14 18.4 C15.4 17.6, 16.6 17.6, 18 18.4 Z')
    t = (f'<path d="M20 9 C18 4, 30 4, 28 9" fill="none" stroke="{INK}" stroke-width="2.4" stroke-linecap="round"/>'
         '<path d="M20 9 C18 4, 30 4, 28 9" fill="none" stroke="#8A5428" stroke-width="1.2" stroke-linecap="round"/>'
         f'<path d="{wing}" fill="url(#ash)" stroke="{INK}" stroke-width="1.1" stroke-linejoin="round"/>'
         f'<path d="{wing}" transform="translate(48 0) scale(-1 1)" fill="url(#ash)" stroke="{INK}" stroke-width="1.1" stroke-linejoin="round"/>'
         f'<path d="{post}" fill="url(#ash)" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round"/>'
         '<path d="M18.4 22 C21 23, 27 23, 29.8 22 M18.8 34.6 C21 35.6, 27 35.6, 30.2 34.6" fill="none" stroke="#6E4E2C" stroke-width="0.9"/>'
         '<path d="M21 19.4 C23 20.6, 25 20.6, 27 19.4 M21 32 L27 32" fill="none" stroke="#4A3018" stroke-width="1" stroke-linecap="round"/>'
         '<path d="M19.6 12.6 L22.8 13.4 M28.4 12.6 L25.2 13.4 M19.6 25.6 L22.8 26.4 M28.4 25.6 L25.2 26.4" stroke="#4A3018" stroke-width="0.9" stroke-linecap="round"/>'
         '<path d="M19.4 11 C19.6 20, 19.4 30, 19 38" fill="none" stroke="#FFFFFF" stroke-width="0.9" stroke-linecap="round" opacity="0.5"/>'
         + eyes)
    return svg(t)


def pine_idol():
    # A small idol carved from pine heartwood: a round head with amber eyes, arms folded, two feathers tied at its
    # side, on a round base.
    f1 = ('<path d="M29.6 14 C32 8, 36 4, 41 2.6 C40.4 7, 37 11.4, 31 15.4 Z" fill="#F2ECE0" stroke="#24140A" stroke-width="0.9" stroke-linejoin="round"/>'
          '<path d="M30.4 14.6 L40 3.6" stroke="#8A7454" stroke-width="0.6"/>'
          '<path d="M36.4 6.4 C38 6, 39.6 4.6, 41 2.6 C40.6 5, 39.6 7, 38.2 8.6 Z" fill="#5A3A20"/>')
    f2 = ('<path d="M30.6 16.4 C35 13.6, 39.4 12.6, 43.6 13.4 C41.4 16.6, 37 18, 31.4 18 Z" fill="#E4DCCC" stroke="#24140A" stroke-width="0.9" stroke-linejoin="round"/>'
          '<path d="M31.4 17.2 L42.6 13.6" stroke="#8A7454" stroke-width="0.6"/>'
          '<path d="M39.6 13 C41 12.8, 42.4 13, 43.6 13.4 C42.8 14.6, 41.6 15.6, 40.2 16.2 Z" fill="#5A3A20"/>')
    body = 'M18.4 20 C16.4 27, 16.6 33, 18 38 L30 38 C31.4 33, 31.6 27, 29.6 20 Z'
    i = (f1 + f2 +
         f'<ellipse cx="24" cy="39" rx="9.6" ry="3" fill="url(#pine)" stroke="{INK}" stroke-width="1.1"/>'
         f'<path d="{body}" fill="url(#pine)" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round"/>'
         f'<circle cx="24" cy="14" r="7" fill="url(#pine)" stroke="{INK}" stroke-width="1.3"/>'
         f'<path d="M28.6 16.6 L31.6 15.6" stroke="#C8B490" stroke-width="1.4" stroke-linecap="round"/>'
         f'<circle cx="21.4" cy="13.6" r="1.4" fill="#FFB820" stroke="{INK}" stroke-width="0.7"/>'
         f'<circle cx="26.6" cy="13.6" r="1.4" fill="#FFB820" stroke="{INK}" stroke-width="0.7"/>'
         '<path d="M21.6 17.4 C23 18.4, 25 18.4, 26.4 17.4" fill="none" stroke="#4E240C" stroke-width="0.9" stroke-linecap="round"/>'
         '<path d="M19 26 C22 28.6, 26 28.6, 29 26 M19.6 30 C22 31.6, 26 31.6, 28.4 30" fill="none" stroke="#4E240C" stroke-width="0.9" stroke-linecap="round"/>'
         '<path d="M19.4 9.6 C20.6 8, 22.4 7.4, 24 7.4" fill="none" stroke="#FFFFFF" stroke-width="0.9" stroke-linecap="round" opacity="0.7"/>'
         '<path d="M19 22 C18.2 27, 18.2 32, 19 36" fill="none" stroke="#FFFFFF" stroke-width="0.8" stroke-linecap="round" opacity="0.5"/>'
         '<ellipse cx="22.4" cy="34.6" rx="0.9" ry="1.3" fill="#FFC040" stroke="#24140A" stroke-width="0.5" opacity="0.9"/>')
    return svg(i)


def bone_greataxe():
    # A long oak haft with a double crescent blade of bone, lashed on with rope, a copper cap and pommel. Bigger than
    # the hatchets and two-bladed, so it reads as two-handed.
    def bit(sign):
        x = lambda v: 24 + sign * v
        return (f'<path d="M{x(2)} 9 C{x(6)} 9, {x(9)} 7, {x(11.6)} 4 C{x(14.6)} 9.6, {x(14.6)} 18.4, {x(11.6)} 24 '
                f'C{x(9)} 21, {x(6)} 19, {x(2)} 19 Z" fill="url(#bone)" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round"/>'
                f'<path d="M{x(11.4)} 6.6 C{x(13)} 10.6, {x(13)} 17, {x(11.4)} 21.4" fill="none" stroke="#FFFFFF" stroke-width="0.9" '
                f'stroke-linecap="round" opacity="{0.9 if sign < 0 else 0.45}"/>'
                f'<path d="M{x(7)} 10.6 C{x(8)} 13, {x(8)} 15, {x(7)} 17.4" fill="none" stroke="#A8987A" stroke-width="0.7" stroke-linecap="round"/>')
    rope = ''.join(f'<path d="M21.6 {y} L26.4 {y + 1.6}" stroke="#D8BE86" stroke-width="1.6" stroke-linecap="round"/>'
                   f'<path d="M21.6 {y} L26.4 {y + 1.6}" stroke="{INK}" stroke-width="0.4" opacity="0.6"/>' for y in (9.4, 11.8, 14.2, 16.6))
    cap = f'<rect x="21.6" y="3.4" width="4.8" height="4" rx="1.4" fill="url(#copper)" stroke="{INK}" stroke-width="1"/>'
    pommel = f'<rect x="21.4" y="43" width="5.2" height="3" rx="1.2" fill="url(#copper)" stroke="{INK}" stroke-width="1"/>'
    inner = shaft(4.6, 45.6, 3.8) + bands([33, 36, 39], 'url(#leather)', 5) + bit(-1) + bit(1) + rope + cap + pommel
    return svg(diag_long(inner))


ITEMS = dict(
    copper_spear=spear, copper_mace=mace, bone_spear=bone_spear, bone_club=bone_club,
    garnet_ring=ring, oak_charm=oak_charm, deer_hide_gloves=gloves, deer_hide_bracers=bracers,
    deer_hide_belt=belt, lake_scale_greaves=greaves,
    bone_greataxe=bone_greataxe, golden_antler_mantle=antler_mantle,
    iron_spear=lambda: spear('iron'), iron_mace=lambda: mace('iron'), iron_pike=iron_pike,
    mithril_spear=lambda: spear('mithril'), mithril_mace=lambda: mace('mithril'), mithril_greatsword=mithril_greatsword,
    drake_fang_spear=drake_spear, drake_fang_hammer=drake_hammer, drake_fang_halberd=drake_halberd,
    sapphire_ring=lambda: ring('iron', 'sapphire', '#0A1A52'),
    star_diamond_ring=lambda: ring('mithril', 'diamond', '#4E88A8', spark(34, 7, 1.1)),
    drowned_captains_ring=captains_ring, ash_totem=ash_totem, pine_idol=pine_idol,
    elk_hide_gloves=lambda: gloves('elk'), elk_hide_bracers=lambda: bracers('elk'), elk_hide_belt=lambda: belt('elk'),
    river_scale_greaves=lambda: greaves('river'), tusk_mantle=tusk_mantle,
    ibex_hide_gloves=lambda: gloves('ibex'), ibex_hide_bracers=lambda: bracers('ibex'), ibex_hide_belt=lambda: belt('ibex'),
    tarn_scale_greaves=lambda: greaves('tarn'), lynx_mantle=lynx_mantle,
)

os.makedirs(OUT, exist_ok=True)
for item, draw in ITEMS.items():
    with open(os.path.join(OUT, item + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
        fh.write(draw())
print(f'{len(ITEMS)} SVG files in {OUT}')

if '--preview' in sys.argv:
    def url(path):
        return 'file:///' + path.replace(os.sep, '/')
    cell = '<div class="cell"><div class="sock"><img src="{src}"></div><div class="cap">{cap}</div></div>'
    mine = ''.join(cell.format(src=url(os.path.join(OUT, i + '.svg')), cap=i) for i in ITEMS)
    nab = ''.join(cell.format(src=url(os.path.join(REPO, 'app', 'assets', 'images', 'items', i + '.webp')), cap=i + ' (nabriis)')
                  for i in ['copper_sword', 'iron_sword', 'mithril_sword', 'drake_fang_blade', 'iron_helm', 'moor_charm'])
    html = f'''<!DOCTYPE html><html><head><meta charset="utf-8"><style>
body {{ margin:0; background:#060708; font-family: Segoe UI, sans-serif; color:#E3EAEC; }}
.plate {{ background:#171C21; border-radius:16px; padding:12px 14px; margin:14px; }}
h2 {{ margin:2px 0 8px; font-size:15px; color:#8AC7BC; }}
.grid {{ display:grid; grid-template-columns: repeat(6, 92px); gap:4px; }}
.cell {{ display:flex; flex-direction:column; align-items:center; margin-bottom:6px; }}
.sock {{ width:48px; height:48px; border-radius:12px; background:#000; border:2px solid #e0e0e0;
         position:relative; overflow:hidden; display:flex; align-items:center; justify-content:center; }}
.sock img {{ position:relative; width:40px; height:40px; }}
.big .sock {{ width:84px; height:84px; border-radius:18px; }}
.big .sock img {{ width:72px; height:72px; }}
.cap {{ font-size:9.5px; color:#7F8A90; margin-top:2px; text-align:center; }}
</style></head><body>
<div class="plate"><h2>Gear at bag size</h2><div class="grid">{mine}</div><h2>nabriis</h2><div class="grid">{nab}</div></div>
<div class="plate big"><div class="grid">{mine}</div></div>
</body></html>'''
    preview = os.path.join(tempfile.gettempdir(), 'itheros-gear-preview.html')
    with open(preview, 'w', encoding='utf-8') as fh:
        fh.write(html)
    print(f'Preview: {preview}')
