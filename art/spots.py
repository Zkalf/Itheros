# Draws the gathering spots as SVG (art/spots/<id>.svg), in the style of art/README.md (#198). Each spot is a small
# scene that the player can tell apart from the other spots of its profession: an ore vein in its rock, a tree, a
# water, a trail with its tracks. The rare find of the spot shows as a small glint where it fits.
# Run: python art/spots.py. Then .\scripts\export-art.ps1 makes the webp files (app/assets/images/spots/).
import os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'spots')
INK = '#24140A'

SHADOW = ('<radialGradient id="shadow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#000" stop-opacity="0.65"/>'
          '<stop offset="1" stop-color="#000" stop-opacity="0"/></radialGradient>')


def lin(i, *stops, x2=1, y2=1):
    st = ''.join(f'<stop offset="{k / (len(stops) - 1):.2f}" stop-color="{c}"/>' for k, c in enumerate(stops))
    return f'<linearGradient id="{i}" x1="0" y1="0" x2="{x2}" y2="{y2}">{st}</linearGradient>'


def rad(i, *stops):
    st = ''.join(f'<stop offset="{k / (len(stops) - 1):.2f}" stop-color="{c}"/>' for k, c in enumerate(stops))
    return f'<radialGradient id="{i}" cx="0.4" cy="0.3" r="0.8">{st}</radialGradient>'


def svg(defs, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="48" height="48"><defs>{SHADOW}{defs}</defs>'
            f'<ellipse cx="24" cy="41.5" rx="20" ry="4.6" fill="url(#shadow)"/>{body}</svg>')


def spark(x, y, size=1):
    a, b = 0.8 * size, 1.8 * size
    return (f'<path d="M{x} {y - a - b} l{a} {b} l{b} {a} l-{b} {a} l-{a} {b} l-{a} -{b} l-{b} -{a} l{b} -{a} Z" '
            'fill="#FFFFFF" opacity="0.9"/>')


def grass(points, colour='#6E9A32'):
    return ''.join(f'<path d="M{x} {y} l-1.2 -3 M{x} {y} l0.2 -3.6 M{x} {y} l1.4 -2.8" stroke="{colour}" stroke-width="0.9" '
                   'stroke-linecap="round"/>' for x, y in points)


# --- Mining: an outcrop of angular rock, lit from the top left; nuggets of ore break out of its cracks, loose
# chunks lie at its foot, and the rare gem of the spot sticks out as a small crystal.
# rock: light face, mid, shadow face; ore: light, mid, dark; gem: light, dark; patina (copper) or glow (mithril)
VEINS = {
    'copper_vein':  dict(rock=['#CDB89A', '#97805F', '#5A4732'], ore=['#FFD9A8', '#E07A3A', '#8A3A14'],
                         gem=['#FF8A9A', '#B3122A'], patina='#3EAA82'),
    'iron_vein':    dict(rock=['#A8ACAE', '#6E7376', '#3A3E42'], ore=['#C8A090', '#7A3A2A', '#2E1812'],
                         gem=['#9AC0FF', '#1E4FC2'], rust='#B8582A'),
    'mithril_vein': dict(rock=['#8A90A0', '#555B6A', '#2A2E3A'], ore=['#FFFFFF', '#9AD8FF', '#3A80C0'],
                         gem=['#FFFFFF', '#9ACCE8'], glow='#9AD8FF'),
}
ROCK = 'M4 40 L6 29 L11 21 L19 13 L29 11 L37 16 L42 24 L45 40 Z'
LIT = 'M6 29 L11 21 L19 13 L29 11 L25 19 L17 24 L12 31 Z'
DARK = 'M37 16 L42 24 L45 40 L33 40 L34 28 L31 21 Z'
CRACKS = 'M25 19 L27 26 L22 32 M17 24 L19 31 M31 21 L33 28 M27 26 L33 28'
# nugget clusters: (x, y, size)
NUGGETS = ((21, 28, 1.7), (30, 23.6, 1.35), (14.6, 33.4, 1.25), (34, 32.4, 1.5))


def nugget(x, y, s):
    # A faceted lump of ore: a light top face and a dark side.
    pts = [(-2.6, 0.4), (-1.4, -2.2), (1.4, -2.6), (2.8, -0.4), (1.8, 2), (-1.4, 2.2)]
    d = 'M' + ' L'.join(f'{x + px * s:.2f} {y + py * s:.2f}' for px, py in pts) + ' Z'
    top = (f'M{x - 1.4 * s:.2f} {y - 2.2 * s:.2f} L{x + 1.4 * s:.2f} {y - 2.6 * s:.2f} L{x + 2.8 * s:.2f} {y - 0.4 * s:.2f} '
           f'L{x + 0.2 * s:.2f} {y + 0.2 * s:.2f} L{x - 2.6 * s:.2f} {y + 0.4 * s:.2f} Z')
    return (f'<path d="{d}" fill="url(#ored)" stroke="{INK}" stroke-width="0.9" stroke-linejoin="round"/>'
            f'<path d="{top}" fill="url(#ore)"/>'
            f'<path d="{d}" fill="none" stroke="{INK}" stroke-width="0.9" stroke-linejoin="round"/>'
            f'<path d="M{x - 1.2 * s:.2f} {y - 1.4 * s:.2f} L{x + 0.8 * s:.2f} {y - 1.8 * s:.2f}" stroke="#FFFFFF" stroke-width="0.7" stroke-linecap="round" opacity="0.85"/>')


def vein(spot):
    v = VEINS[spot]
    r, o, g = v['rock'], v['ore'], v['gem']
    defs = (lin('rock', r[0], r[1], r[2]) + lin('ore', o[0], o[1]) + lin('ored', o[1], o[2])
            + lin('gem', g[0], g[1]))
    body = ''
    if 'glow' in v:
        defs += (f'<radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="{v["glow"]}" stop-opacity="0.5"/>'
                 f'<stop offset="1" stop-color="{v["glow"]}" stop-opacity="0"/></radialGradient>')
        body += '<ellipse cx="25" cy="28" rx="20" ry="14" fill="url(#glow)"/>'
    body += (f'<path d="{ROCK}" fill="url(#rock)" stroke="{INK}" stroke-width="1.4" stroke-linejoin="round"/>'
             f'<path d="{LIT}" fill="{r[0]}" opacity="0.55"/>'
             f'<path d="{DARK}" fill="{r[2]}" opacity="0.55"/>'
             f'<path d="{CRACKS}" fill="none" stroke="{r[2]}" stroke-width="1" stroke-linecap="round" stroke-linejoin="round"/>'
             f'<path d="M11 21 L19 13 L29 11" fill="none" stroke="#FFFFFF" stroke-width="1" stroke-linecap="round" stroke-linejoin="round" opacity="0.5"/>')
    if 'rust' in v:
        body += ''.join(f'<path d="M{x} {y} l0.6 3" stroke="{v["rust"]}" stroke-width="1.2" stroke-linecap="round" opacity="0.7"/>'
                        for x, y, _ in NUGGETS)
    body += ''.join(nugget(x, y, s) for x, y, s in NUGGETS)
    if 'patina' in v:
        body += ''.join(f'<circle cx="{x}" cy="{y}" r="0.8" fill="{v["patina"]}" stroke="{INK}" stroke-width="0.4"/>'
                        for x, y in ((18.6, 29.6), (31, 25.4), (36, 33.4)))
    # the rare gem: a small crystal out of the top of the rock
    body += (f'<path d="M23.6 15.6 L25.4 10.4 L27.6 10.8 L28.4 16 Z" fill="url(#gem)" stroke="{INK}" stroke-width="0.9" stroke-linejoin="round"/>'
             f'<path d="M25.4 10.4 L26.2 15.8" stroke="{g[1]}" stroke-width="0.6" opacity="0.8"/>'
             + spark(31, 9, 0.8))
    # loose chunks at the foot of the rock
    body += nugget(8, 39.4, 0.95) + nugget(40.6, 39.8, 1.0)
    if 'glow' in v:
        body += spark(13, 19, 0.6) + spark(39, 21, 0.6)
    return svg(defs, body)


# --- Woodcutting: one tree of its kind on a patch of grass.
def tree(spot):
    if spot == 'oak_tree':
        defs = rad('leaf', '#B8D86A', '#5E8E2A', '#2A4A12') + lin('bark', '#A87A4A', '#6A4422', '#3A2210', y2=0)
        trunk = 'M21 40 C22 34, 22 30, 20.6 26 L27.4 26 C26 30, 26 34, 27 40 Z'
        crown = ''.join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="url(#leaf)" stroke="{INK}" stroke-width="1.2"/>'
                        for x, y, r in ((15, 20, 8), (33, 20, 8), (24, 14, 10), (24, 23, 8)))
        extra = ''.join(f'<ellipse cx="{x}" cy="{y}" rx="1" ry="1.3" fill="#B87A3A" stroke="{INK}" stroke-width="0.5"/>' for x, y in ((14, 24), (31, 25), (22, 18)))
        lit = '<path d="M14 10 C17 7, 22 5.6, 26 5.6" fill="none" stroke="#FFFFFF" stroke-width="1" stroke-linecap="round" opacity="0.5"/>'
    elif spot == 'ash_tree':
        defs = rad('leaf', '#D8EC9A', '#8AB84A', '#3E6A1E') + lin('bark', '#D8D2C2', '#9A9484', '#5A5446', y2=0)
        trunk = 'M22 40 C22.6 32, 22.6 24, 22 14 L26 14 C25.4 24, 25.4 32, 26 40 Z'
        crown = ''.join(f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="url(#leaf)" stroke="{INK}" stroke-width="1.1"/>'
                        for x, y, rx, ry in ((16, 22, 6, 4.4), (32, 21, 6, 4.4), (18, 13, 6, 4.6), (30, 12.6, 6, 4.6), (24, 7.6, 6, 4.4), (24, 17, 5, 4)))
        extra = ('<path d="M22.6 30 L17 25 M25.4 27 L31 22" stroke="#7A7464" stroke-width="1.4" stroke-linecap="round"/>'
                 + ''.join(f'<path d="M{x} {y} l1.6 2.6" stroke="#C8A848" stroke-width="1" stroke-linecap="round"/>' for x, y in ((14, 25), (33, 24))))
        lit = '<path d="M19 5.6 C21 4.2, 24 3.8, 26.6 4.2" fill="none" stroke="#FFFFFF" stroke-width="1" stroke-linecap="round" opacity="0.5"/>'
    else:
        defs = lin('leaf', '#6A9A5A', '#2E5A34', '#14301C', x2=0.6) + lin('bark', '#B86A3A', '#7A3E1E', '#3E1E0C', y2=0)
        trunk = 'M22.4 40 L22.6 30 L25.4 30 L25.6 40 Z'
        crown = ''.join(f'<path d="M24 {y} L{24 + w} {y + h} C{24 + w * 0.4} {y + h - 1.6}, {24 - w * 0.4} {y + h - 1.6}, {24 - w} {y + h} Z" '
                        f'fill="url(#leaf)" stroke="{INK}" stroke-width="1.2" stroke-linejoin="round"/>'
                        for y, w, h in ((14, 13, 18), (8, 10, 14), (3, 7, 10)))
        extra = (''.join(f'<path d="M{x} {y} l1.4 2.4" stroke="#C8E8A8" stroke-width="0.8" stroke-linecap="round" opacity="0.5"/>' for x, y in ((18, 22), (27, 18), (21, 13)))
                 + '<ellipse cx="29.6" cy="27.6" rx="1.2" ry="1.8" fill="#8A5A2A" stroke="#24140A" stroke-width="0.5"/>')
        lit = ''
    ground = (f'<ellipse cx="24" cy="40" rx="15" ry="3.4" fill="#4E7A2A" stroke="{INK}" stroke-width="1"/>'
              + grass(((12, 40.4), (35, 40.6), (17, 41.4), (30, 41.2))))
    body = (ground + f'<path d="{trunk}" fill="url(#bark)" stroke="{INK}" stroke-width="1.2" stroke-linejoin="round"/>'
            + crown + extra + lit)
    return svg(defs, body)


# --- Fishing: the water of the spot.
def water_defs(top, bottom):
    return lin('water', top, bottom, x2=0)


def ripples(points, colour='#E8F6FF'):
    return ''.join(f'<path d="M{x} {y} c2 -1.2, 4 -1.2, 6 0" fill="none" stroke="{colour}" stroke-width="0.9" stroke-linecap="round" opacity="0.8"/>'
                   for x, y in points)


def lake_shore():
    defs = lin('water', '#8ACCE0', '#2E6A8A')
    body = (f'<ellipse cx="24" cy="32" rx="20" ry="8.4" fill="url(#water)" stroke="{INK}" stroke-width="1.3"/>'
            f'<path d="M4.6 30 C8 36, 16 40, 24 40.4 C14 39, 8 35, 6 30 Z" fill="#B8A06A" stroke="{INK}" stroke-width="0.9"/>'
            + ripples(((18, 30), (27, 33), (20, 36)))
            + f'<ellipse cx="32" cy="29.6" rx="3.6" ry="1.6" fill="#5E9A3A" stroke="{INK}" stroke-width="0.8"/>'
            '<path d="M32 29.6 L35.4 29" stroke="#2E5A1E" stroke-width="0.6"/>'
            '<circle cx="31" cy="29" r="0.9" fill="#F6E0EC"/>'
            + ''.join(f'<path d="M{x} 36 C{x - 0.6} 28, {x + dx} 20, {x + dx * 1.4} {top}" fill="none" stroke="{INK}" stroke-width="2.4" stroke-linecap="round"/>'
                      f'<path d="M{x} 36 C{x - 0.6} 28, {x + dx} 20, {x + dx * 1.4} {top}" fill="none" stroke="#7EA83E" stroke-width="1.2" stroke-linecap="round"/>'
                      for x, dx, top in ((9, -1, 17), (12, 0.6, 15), (14.6, 1.6, 19)))
            + ''.join(f'<rect x="{x - 1}" y="{y}" width="2" height="5" rx="1" fill="#7A4A22" stroke="{INK}" stroke-width="0.6"/>' for x, y in ((11.4, 15), (8.2, 17.4)))
            + '<path d="M38 22 C34 21, 30 25, 27 31" fill="none" stroke="#3A2A1A" stroke-width="0.7"/>')
    return svg(defs, body)


def under_the_bridge():
    defs = lin('water', '#6AA8C8', '#1E4A6A') + lin('stone', '#D8D0C0', '#9A9080', '#5A5246')
    arch = 'M3 26 L45 26 L45 34 L38 34 C38 26, 10 26, 10 34 L3 34 Z'
    blocks = ''.join(f'<path d="M{x} 26 L{x} 30" stroke="#7A7060" stroke-width="0.8"/>' for x in (9, 16, 23, 30, 37))
    body = (f'<path d="M2 34 C10 30, 38 30, 46 34 L44 40 C34 42.6, 14 42.6, 4 40 Z" fill="url(#water)" stroke="{INK}" stroke-width="1.2"/>'
            + ripples(((16, 37), (25, 38.6), (30, 36)))
            + f'<path d="{arch}" fill="url(#stone)" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round"/>'
            + blocks + f'<path d="M3 30 L10 30 M38 30 L45 30" stroke="#7A7060" stroke-width="0.8"/>'
            f'<path d="M2 22 L46 22 L46 26 L2 26 Z" fill="#B8AE9C" stroke="{INK}" stroke-width="1.2"/>'
            + ''.join(f'<rect x="{x}" y="17.6" width="2.4" height="4.4" fill="#A89E8C" stroke="{INK}" stroke-width="0.8"/>' for x in (5, 13, 21, 29, 37))
            + '<path d="M3 23.4 L45 23.4" stroke="#FFFFFF" stroke-width="0.8" opacity="0.5"/>'
            '<path d="M20 34 C22 32.6, 26 32.6, 28 34" fill="none" stroke="#C9A13A" stroke-width="1.2" stroke-linecap="round"/>')
    return svg(defs, body)


def cove_rocks():
    defs = lin('water', '#4AA0B0', '#14485A') + rad('rock', '#8A8478', '#55504A', '#262420')
    body = (f'<path d="M2 30 C12 27, 36 27, 46 30 L45 40 C34 43, 14 43, 3 40 Z" fill="url(#water)" stroke="{INK}" stroke-width="1.2"/>'
            f'<path d="M8 36 C6 28, 10 18, 17 16 C23 15, 26 22, 25 30 C25 33, 23 36, 20 37 Z" fill="url(#rock)" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round"/>'
            f'<path d="M26 37 C25 31, 28 25, 33 24 C38 24, 41 29, 40 36 Z" fill="url(#rock)" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round"/>'
            '<path d="M11 24 C12 20, 15 17.6, 18 17.4 M29 28 C30 26, 32 25.2, 34 25.2" fill="none" stroke="#FFFFFF" stroke-width="0.9" stroke-linecap="round" opacity="0.5"/>'
            + ''.join(f'<path d="M{x} {y} c1.4 -1.6, 3 -1.6, 4.4 0 c1.4 -1.6, 3 -1.6, 4.4 0" fill="none" stroke="#FFFFFF" stroke-width="1.3" stroke-linecap="round" opacity="0.9"/>'
                      for x, y in ((4, 36.6), (21, 37.6), (36, 36.4)))
            + ''.join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="#D8D2C0" stroke="{INK}" stroke-width="0.5"/>' for x, y, r in ((14, 30, 1.1), (16.4, 31.6, 0.8), (33, 31, 0.9)))
            + '<path d="M36 18 l2.6 -1.6 l2.6 1.6 M40 13 l2 -1.2 l2 1.2" fill="none" stroke="#F2F2F2" stroke-width="0.9" stroke-linecap="round"/>')
    return svg(defs, body)


def cold_tarn():
    defs = lin('water', '#5A7E9A', '#14243A') + lin('snow', '#FFFFFF', '#C8DCEA', '#7E9AB0')
    body = (f'<path d="M6 21 L14 10 L20 16 L26 6 L35 17 L42 21 Z" fill="url(#snow)" stroke="{INK}" stroke-width="1.2" stroke-linejoin="round"/>'
            '<path d="M14 10 L16 15 L20 16 M26 6 L27 12 L31 13" fill="none" stroke="#8AA4BA" stroke-width="0.8"/>'
            f'<ellipse cx="24" cy="31" rx="20" ry="9" fill="url(#water)" stroke="{INK}" stroke-width="1.3"/>'
            f'<path d="M14 27.6 L21 26.4 L22.4 29 L16 30.2 Z" fill="#E8F4FC" stroke="{INK}" stroke-width="0.8" stroke-linejoin="round"/>'
            f'<path d="M28 33 L35 32 L36 34.6 L29.6 35.4 Z" fill="#E8F4FC" stroke="{INK}" stroke-width="0.8" stroke-linejoin="round"/>'
            + ripples(((10, 33), (24, 37)), '#A8C8E0')
            + '<path d="M6 26 C10 22.6, 20 21.4, 30 22" fill="none" stroke="#C8E0F0" stroke-width="0.8" opacity="0.5"/>'
            + spark(38, 27, 0.8) + spark(9, 14, 0.6))
    return svg(defs, body)


# --- Hunting: the trail and the tracks of the animal that lives there.
def hoof(x, y, s=1.0, colour='#3A2414'):
    return (f'<g transform="translate({x} {y}) scale({s})">'
            f'<path d="M-1.6 -2.6 C-2.8 -1, -2.6 1.6, -0.6 2.2 L-0.4 -2.4 Z M1.6 -2.6 C2.8 -1, 2.6 1.6, 0.6 2.2 L0.4 -2.4 Z" fill="{colour}"/></g>')


def deer_trail():
    defs = lin('path', '#C8A070', '#8A643A', x2=0) + rad('fern', '#A8D86A', '#4E8A2A', '#22401A')
    body = (f'<path d="M3 30 C8 20, 20 15, 30 14 C40 14, 46 22, 45 32 C44 39, 36 42.4, 24 42.4 C12 42.4, 3 39, 3 30 Z" fill="#5E8A34" stroke="{INK}" stroke-width="1.2"/>'
            '<path d="M7 26 C11 19.6, 19 16.4, 27 16" fill="none" stroke="#A8D06A" stroke-width="0.9" stroke-linecap="round" opacity="0.6"/>'
            f'<path d="M6 40 C14 34, 16 28, 22 22 C26 18, 29 16, 32 15 L37 15.6 C34 19, 30 23, 28 28 C25 34, 26 38, 30 41 Z" fill="url(#path)" stroke="{INK}" stroke-width="1.2" stroke-linejoin="round"/>'
            + ''.join(hoof(x, y, s) for x, y, s in ((16, 35, 1.1), (20.6, 31, 1), (23, 26.6, 0.9), (26.6, 22, 0.85), (30, 18.6, 0.75), (33.6, 16.4, 0.65)))
            + ''.join(f'<path d="M{x} {y} C{x - 6} {y - 4}, {x - 8} {y - 10}, {x - 6} {y - 14} C{x - 3} {y - 10}, {x - 1} {y - 5}, {x} {y} Z" fill="url(#fern)" stroke="{INK}" stroke-width="0.9"/>'
                      for x, y in ((11, 32), (42, 34)))
            + grass(((6, 30), (36, 24), (40, 40), (14, 22), (44, 22)))
            + f'<path d="M37 31 C38 28, 40 27, 42 27.4" fill="none" stroke="#C9A13A" stroke-width="1.2" stroke-linecap="round"/>'
            + spark(41, 25, 0.6))
    return svg(defs, body)


def moor_tracks():
    defs = lin('mud', '#8A6A4A', '#4A3220', x2=0) + lin('moor', '#8A7A4A', '#4E4428', x2=0)
    heather = ''.join(f'<circle cx="{x}" cy="{y}" r="2.2" fill="#9A4A9A" stroke="{INK}" stroke-width="0.7"/>'
                      f'<circle cx="{x - 0.6}" cy="{y - 0.7}" r="0.8" fill="#D8A0D8"/>'
                      for x, y in ((8, 24), (12, 21), (38, 22), (42, 25), (35, 19), (6, 30), (43, 31)))
    body = (f'<path d="M3 26 C12 20, 36 18, 45 24 L44 39 C34 43, 14 43, 4 39 Z" fill="url(#moor)" stroke="{INK}" stroke-width="1.2" stroke-linejoin="round"/>'
            f'<path d="M12 40 C14 33, 20 28, 26 25 C30 23, 34 22, 37 22 C34 26, 31 30, 30 34 C29 37, 30 39, 32 41 Z" fill="url(#mud)" stroke="{INK}" stroke-width="1" stroke-linejoin="round"/>'
            '<ellipse cx="20" cy="38" rx="3" ry="1.2" fill="#6A8AA0" opacity="0.8"/>'
            + ''.join(hoof(x, y, s, '#24160C') for x, y, s in ((19, 34.4, 1.5), (24, 29.6, 1.35), (29.4, 26, 1.2), (33.4, 23.4, 1.05)))
            + heather + grass(((15, 23), (31, 19), (40, 36)), '#8A9A4A'))
    return svg(defs, body)


def high_crags():
    defs = rad('crag', '#B8B4AC', '#7A766E', '#3A3832') + lin('snow', '#FFFFFF', '#D8E6F0', x2=0)
    body = (f'<path d="M3 40 L10 22 L16 26 L24 6 L31 18 L36 14 L45 40 Z" fill="url(#crag)" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round"/>'
            f'<path d="M20 15.6 L24 6 L28.6 14.4 L26 13 L24.6 16 L22.4 13.6 Z" fill="url(#snow)" stroke="{INK}" stroke-width="0.9" stroke-linejoin="round"/>'
            f'<path d="M33.4 16.4 L36 14 L38.6 19 L36.6 18 L35 19.6 Z" fill="url(#snow)" stroke="{INK}" stroke-width="0.8" stroke-linejoin="round"/>'
            '<path d="M24 6 L22 20 L17 30 M31 18 L30 28 M10 22 L13 32" fill="none" stroke="#4A4840" stroke-width="0.9" opacity="0.8"/>'
            '<path d="M8 28 C10 24, 14 22, 16 22" fill="none" stroke="#FFFFFF" stroke-width="0.9" stroke-linecap="round" opacity="0.5"/>'
            f'<path d="M4 40 C14 36, 34 36, 44 40 C34 42, 14 42, 4 40 Z" fill="url(#snow)" stroke="{INK}" stroke-width="1"/>'
            + ''.join(hoof(x, y, s, '#5A6878') for x, y, s in ((14, 39.4, 0.7), (19, 38.6, 0.7), (25, 38.8, 0.7), (31, 38.6, 0.7)))
            + f'<path d="M38 30 C38 26, 40 24, 42.6 24.4 M40 30 C40.4 27, 42 26, 44 26.4" fill="none" stroke="{INK}" stroke-width="2" stroke-linecap="round"/>'
            '<path d="M38 30 C38 26, 40 24, 42.6 24.4 M40 30 C40.4 27, 42 26, 44 26.4" fill="none" stroke="#C8B48A" stroke-width="1" stroke-linecap="round"/>')
    return svg(defs, body)


ITEMS = {**{k: (lambda k=k: vein(k)) for k in VEINS},
         **{k: (lambda k=k: tree(k)) for k in ('oak_tree', 'ash_tree', 'pine_tree')},
         'lake_shore': lake_shore, 'under_the_bridge': under_the_bridge, 'cove_rocks': cove_rocks, 'cold_tarn': cold_tarn,
         'deer_trail': deer_trail, 'moor_tracks': moor_tracks, 'high_crags': high_crags}

os.makedirs(OUT, exist_ok=True)
for spot, draw in ITEMS.items():
    with open(os.path.join(OUT, spot + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
        fh.write(draw())
print(f'{len(ITEMS)} SVG files in {OUT}')
