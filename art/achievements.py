# Draws the achievements that have no picture from nabriis as SVG (art/achievements/<id>.svg), in the style of his
# patches (#198): a sewn shield patch with a dark rim and cream stitches, a sky of sun rays, layered mountains and
# dark pines, and one flat emblem in front. The four finds show a gem in the colour of their quality.
# Run: python art/achievements.py [--preview <file.html>]. Then .\scripts\export-art.ps1 makes the webp files
# (app/assets/images/achievements/).
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'achievements')

RIM = '#2A2925'
STITCH = '#EFE3BF'
INK = '#1E2A28'       # the flat dark of the emblems
CREAM = '#F3E9CC'
PINE = '#24483C'
PINE2 = '#2F5E4C'

# The shield: the patch, the field inside the rim, and the line of the stitches.
SHIELD = 'M8 12 Q8 5 15 5 H85 Q92 5 92 12 V54 Q92 81 50 96 Q8 81 8 54 Z'
FIELD = 'M13.5 15 Q13.5 10.5 18 10.5 H82 Q86.5 10.5 86.5 15 V54 Q86.5 77.5 50 90.5 Q13.5 77.5 13.5 54 Z'
SEAM = 'M11 13.5 Q11 7.8 16.5 7.8 H83.5 Q89 7.8 89 13.5 V54 Q89 79.5 50 93.4 Q11 79.5 11 54 Z'

SKIES = {
    'warm': ('#F1CF78', '#F6E8C3'),
    'teal': ('#9DCDC6', '#F1E7CB'),
    'dusk': ('#D9C9A3', '#EEE4CA'),
    'night': ('#2B3A55', '#3B4D70'),
    'deep': ('#3E7684', '#5C93A0'),
}


def rays(sky, cx=50, cy=50, n=20):
    a, b = SKIES[sky]
    out = f'<rect x="0" y="0" width="100" height="100" fill="{b}"/>'
    for i in range(0, n, 2):
        t0 = 2 * math.pi * i / n
        t1 = 2 * math.pi * (i + 1) / n
        out += (f'<path d="M{cx} {cy} L{cx + 90 * math.cos(t0):.1f} {cy + 90 * math.sin(t0):.1f} '
                f'L{cx + 90 * math.cos(t1):.1f} {cy + 90 * math.sin(t1):.1f} Z" fill="{a}"/>')
    return out


def poly(points, fill, extra=''):
    return f'<path d="M{" L".join(f"{x} {y}" for x, y in points)} Z" fill="{fill}"{extra}/>'


def ridge(points, fill):
    # A mountain line closed at the bottom of the patch.
    return poly(points + [(100, 100), (0, 100)], fill)


def pine(x, base, h, fill=PINE):
    w = h * 0.3
    return (f'<path d="M{x} {base - h} L{x + w * 0.7:.1f} {base - h * 0.45:.1f} L{x + w * 0.35:.1f} {base - h * 0.45:.1f} '
            f'L{x + w:.1f} {base} L{x - w:.1f} {base} L{x - w * 0.35:.1f} {base - h * 0.45:.1f} '
            f'L{x - w * 0.7:.1f} {base - h * 0.45:.1f} Z" fill="{fill}"/>')


def forest(trees, fill=PINE):
    return ''.join(pine(x, b, h, fill) for x, b, h in trees)


EDGE_TREES = [(17, 80, 18), (22, 84, 22), (27, 88, 16), (78, 84, 22), (83, 80, 18), (73, 88, 16)]


def spark(x, y, s=1.0, fill=CREAM):
    a, b = 1.2 * s, 3.2 * s
    return (f'<path d="M{x} {y - b} L{x + a} {y - a} L{x + b} {y} L{x + a} {y + a} L{x} {y + b} L{x - a} {y + a} '
            f'L{x - b} {y} L{x - a} {y - a} Z" fill="{fill}"/>')


def patch(body):
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100">'
            f'<defs><clipPath id="field"><path d="{FIELD}"/></clipPath></defs>'
            f'<path d="{SHIELD}" fill="{RIM}"/>'
            f'<g clip-path="url(#field)">{body}</g>'
            f'<path d="{SEAM}" fill="none" stroke="{STITCH}" stroke-width="1.1" stroke-dasharray="2.6 1.8"/>'
            '</svg>')


# --- the emblems -------------------------------------------------------------------------------------------------

def adventurer():
    # A flag on the peak, and the path up to it.
    return (rays('teal', cy=40)
            + ridge([(0, 58), (16, 46), (28, 54), (40, 44), (60, 56), (74, 42), (100, 56)], '#6E9C8E')
            + ridge([(0, 92), (24, 64), (50, 28), (76, 64), (100, 92)], '#8A5A3C')
            + poly([(50, 28), (57.5, 39), (53, 37), (49, 41), (45, 36.5), (42.5, 39)], CREAM)
            + '<path d="M50 90 C40 84 58 76 48 70 C40 65 56 58 50 50 C47 46 52 42 50 39" fill="none" '
              f'stroke="{CREAM}" stroke-width="3.2" stroke-linecap="round"/>'
            + f'<path d="M50 28 V12" stroke="{INK}" stroke-width="1.6" stroke-linecap="round"/>'
            + poly([(50.5, 12), (63, 15.5), (50.5, 19.5)], '#B5452E')
            + forest(EDGE_TREES))


def seasoned():
    # A tent and a camp fire under the evening sun.
    return (rays('warm', cy=46)
            + ridge([(0, 60), (20, 48), (36, 56), (54, 44), (72, 54), (100, 46)], '#6E9C8E')
            + ridge([(0, 72), (30, 66), (60, 70), (100, 64)], PINE2)
            + poly([(22, 80), (40, 48), (58, 80)], '#C9874A')
            + poly([(40, 48), (58, 80), (48, 80)], '#9C6334')
            + poly([(34, 80), (40, 64), (46, 80)], INK)
            + f'<path d="M40 48 L37 42 M40 48 L43 42" stroke="{INK}" stroke-width="1.4" stroke-linecap="round"/>'
            + f'<path d="M62 82 L78 76 M62 76 L78 82" stroke="{INK}" stroke-width="2.6" stroke-linecap="round"/>'
            + '<path d="M70 78 C62 70 68 64 70 56 C72 62 80 66 74 74 C73 70 71 70 70 78 Z" fill="#E8742A"/>'
            + '<path d="M70.5 78 C67 72 70 69 71 64 C72 68 75 71 72.5 76 Z" fill="#F7C64A"/>'
            + forest([(14, 88, 16), (86, 88, 16)]))


def champion():
    # A sword in a laurel wreath.
    # Two branches of the wreath: a stem on an arc from the bottom up each side, a leaf on each side of it.
    leaves = ''
    for side in (-1, 1):
        leaves += (f'<path d="M50 80 A26 26 0 0 {1 if side > 0 else 0} {50 + side * 22} 34" fill="none" '
                   'stroke="#2F5A3C" stroke-width="1.6"/>')
        for i in range(8):
            t = math.radians(100 - i * 17)  # from the bottom (100°) up to the top (-19°)
            x, y = 50 + side * 25 * math.cos(t - math.pi / 2), 56 - 25 * math.sin(t - math.pi / 2)
            ang = (math.degrees(t) - 90) * side
            for lean, fill in ((-35, '#3E6B4A'), (35, '#5E8F5E')):
                leaves += (f'<ellipse cx="{x:.1f}" cy="{y:.1f}" rx="2.4" ry="5.6" fill="{fill}" '
                           f'transform="rotate({ang + lean * side:.0f} {x:.1f} {y:.1f}) translate(0 -3)"/>')
    return (rays('warm', cy=50)
            + ridge([(0, 78), (24, 72), (50, 76), (76, 70), (100, 76)], PINE2)
            + leaves
            + poly([(46.5, 24), (50, 15), (53.5, 24), (53.5, 64), (46.5, 64)], '#E8E2D0', f' stroke="{INK}" stroke-width="1"')
            + '<path d="M50 22 V62" stroke="#B9B2A0" stroke-width="1.2"/>'
            + f'<rect x="38" y="63" width="24" height="4.4" rx="1.6" fill="#D9A441" stroke="{INK}" stroke-width="1"/>'
            + f'<rect x="47.6" y="67" width="4.8" height="11" fill="{INK}"/>'
            + f'<circle cx="50" cy="80" r="3.4" fill="#D9A441" stroke="{INK}" stroke-width="1"/>'
            + '<path d="M38 82 Q50 88 62 82" fill="none" stroke="#B5452E" stroke-width="3" stroke-linecap="round"/>')


GEMS = {
    'lucky_find': ('#A5D6A7', '#4CAF50', '#2E7D32'),
    'rare_find': ('#BBDEFB', '#42A5F5', '#1565C0'),
    'epic_find': ('#E1BEE7', '#AB47BC', '#6A1B9A'),
    'legendary_find': ('#FFE0B2', '#FF9800', '#E65100'),
}


def find(kind):
    light, mid, dark = GEMS[kind]
    glow = ''
    if kind == 'legendary_find':
        glow = (f'<radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="{light}" stop-opacity="0.95"/>'
                f'<stop offset="1" stop-color="{light}" stop-opacity="0"/></radialGradient>'
                '<circle cx="50" cy="52" r="30" fill="url(#glow)"/>')
    sky = f'<rect x="0" y="0" width="100" height="100" fill="{CREAM}"/>'
    for i in range(0, 20, 2):
        t0, t1 = 2 * math.pi * i / 20, 2 * math.pi * (i + 1) / 20
        sky += (f'<path d="M50 52 L{50 + 90 * math.cos(t0):.1f} {52 + 90 * math.sin(t0):.1f} '
                f'L{50 + 90 * math.cos(t1):.1f} {52 + 90 * math.sin(t1):.1f} Z" fill="{light}"/>')
    rocks = (poly([(14, 92), (22, 74), (34, 70), (42, 78), (36, 92)], '#7C6A58')
             + poly([(58, 92), (64, 76), (76, 72), (86, 80), (88, 92)], '#7C6A58')
             + poly([(30, 92), (40, 76), (60, 76), (70, 92)], '#5E4F42')
             + poly([(22, 74), (34, 70), (30, 78)], '#9C8A76') + poly([(64, 76), (76, 72), (72, 78)], '#9C8A76'))
    # A cut gem: crown facets on top, the pavilion to a point below.
    gem = (poly([(34, 46), (40, 36), (60, 36), (66, 46), (50, 74)], mid, f' stroke="{INK}" stroke-width="1.6" stroke-linejoin="round"')
           + poly([(40, 36), (60, 36), (55, 46), (45, 46)], light)
           + poly([(34, 46), (40, 36), (45, 46)], mid)
           + poly([(66, 46), (60, 36), (55, 46)], dark)
           + poly([(34, 46), (45, 46), (50, 74)], light, ' opacity="0.55"')
           + poly([(55, 46), (66, 46), (50, 74)], dark)
           + f'<path d="M34 46 H66 M45 46 L50 74 L55 46" fill="none" stroke="{INK}" stroke-width="1" stroke-linejoin="round"/>'
           + poly([(34, 46), (40, 36), (60, 36), (66, 46), (50, 74)], 'none', f' stroke="{INK}" stroke-width="1.6" stroke-linejoin="round"'))
    sparks = spark(30, 30, 1.0) + spark(70, 26, 0.8)
    if kind in ('epic_find', 'legendary_find'):
        sparks += spark(74, 52, 0.7) + spark(26, 56, 0.6)
    if kind == 'legendary_find':
        sparks += spark(50, 22, 1.1)
    if kind == 'lucky_find':
        # A four-leaf clover beside the gem.
        sparks += ''.join(f'<circle cx="{74 + dx}" cy="{60 + dy}" r="3.2" fill="#3E8E4A"/>'
                          for dx, dy in ((-2.6, 0), (2.6, 0), (0, -2.6), (0, 2.6)))
        sparks += f'<path d="M74 63 Q75 68 72 70" stroke="#3E8E4A" stroke-width="1.2" fill="none"/>'
    return sky + glow + rocks + gem + sparks


def angler():
    # A rod over the lake, a fish leaping on the line.
    return (rays('teal', cy=36)
            + ridge([(0, 54), (18, 40), (32, 50), (50, 36), (70, 50), (86, 40), (100, 50)], '#6E9C8E')
            + '<rect x="0" y="56" width="100" height="44" fill="#4F8FA6"/>'
            + ''.join(f'<path d="M{x} {y} h{w}" stroke="#A9D3DF" stroke-width="1.4" stroke-linecap="round"/>'
                      for x, y, w in ((22, 64, 14), (60, 66, 18), (34, 74, 20), (66, 80, 12)))
            + f'<path d="M14 92 Q40 40 76 20" fill="none" stroke="#7A4B2A" stroke-width="2.6" stroke-linecap="round"/>'
            + f'<path d="M76 20 Q74 34 62 46" fill="none" stroke="{INK}" stroke-width="0.7"/>'
            + f'<path d="M48 56 Q56 40 70 50 Q62 52 56 60 Q52 60 48 56 Z" fill="{INK}"/>'
            + poly([(68, 49), (75, 45), (73, 54)], INK)
            + '<circle cx="52.5" cy="53" r="1.1" fill="#F3E9CC"/>'
            + '<path d="M44 60 q4 -4 8 0 M60 62 q3 -3 6 0" fill="none" stroke="#DDEFF3" stroke-width="1.2"/>'
            + f'<circle cx="22" cy="80" r="3.4" fill="#7A4B2A" stroke="{INK}" stroke-width="0.8"/>')


def deep_waters():
    # A great fish down in the dark tarn, under snowy peaks.
    return (rays('deep', cy=30)
            + ridge([(0, 46), (20, 26), (34, 40), (50, 22), (68, 40), (82, 28), (100, 44)], '#7FA3AE')
            + poly([(20, 26), (26, 32), (22, 31), (17, 30)], CREAM) + poly([(50, 22), (56, 30), (50, 28), (45, 29)], CREAM)
            + poly([(82, 28), (87, 33), (82, 32), (78, 32)], CREAM)
            + '<rect x="0" y="48" width="100" height="52" fill="#2A6476"/>'
            + '<rect x="0" y="48" width="100" height="5" fill="#3B7C8E"/>'
            # The great fish, darker than the water, with a pale belly line and a glinting eye.
            + '<path d="M16 72 Q36 52 62 64 Q70 67 74 65 L88 54 L85 72 L88 90 L74 79 Q70 77 62 80 Q36 92 16 72 Z" fill="#0E2630"/>'
            + '<path d="M36 61 L44 50 L52 61 Z M42 82 L48 89 L52 81 Z" fill="#0E2630"/>'
            + '<path d="M22 76 Q40 86 62 78" fill="none" stroke="#3E7F92" stroke-width="1.4" stroke-linecap="round"/>'
            + '<circle cx="26" cy="69" r="2" fill="#BFE6EE"/>'
            + ''.join(f'<path d="M{x} {y} h{w}" stroke="#7FB8C6" stroke-width="1.2" stroke-linecap="round" opacity="0.8"/>'
                      for x, y, w in ((14, 52, 16), (46, 51, 20), (74, 53, 12)))
            + ''.join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="none" stroke="#7FB8C6" stroke-width="0.8"/>'
                      for x, y, r in ((26, 60, 1.6), (28, 55, 1.1), (24, 50.5, 0.8))))


def stones(where, fill=INK):
    return ''.join(f'<path d="M{x - w} {b} V{b - h + w} Q{x - w} {b - h} {x} {b - h} Q{x + w} {b - h} {x + w} {b - h + w} V{b} Z" fill="{fill}"/>'
                   for x, b, w, h in where)


def bone_collector():
    # A skull and crossed bones over the graves.
    bone = lambda x1, y1, x2, y2: (
        f'<path d="M{x1} {y1} L{x2} {y2}" stroke="{CREAM}" stroke-width="4.4" stroke-linecap="round"/>'
        + ''.join(f'<circle cx="{x + dx}" cy="{y + dy}" r="2.6" fill="{CREAM}"/>'
                  for x, y, (dx, dy) in ((x1, y1, (-1.8, 1.2)), (x1, y1, (1.2, -1.8)), (x2, y2, (1.8, 1.2)), (x2, y2, (-1.2, -1.8)))))
    return (rays('dusk', cy=44)
            + ridge([(0, 62), (22, 52), (44, 60), (70, 50), (100, 60)], '#8E9A8C')
            + ridge([(0, 80), (100, 78)], '#4B5A4E')
            + stones([(20, 84, 5, 16), (80, 84, 5, 16), (30, 88, 4, 11), (70, 88, 4, 11)], '#3A4540')
            + bone(30, 72, 70, 40) + bone(30, 40, 70, 72)
            + f'<path d="M36 46 Q36 28 50 28 Q64 28 64 46 Q64 52 58 54 V60 H42 V54 Q36 52 36 46 Z" fill="{CREAM}" stroke="{INK}" stroke-width="1.2"/>'
            + f'<ellipse cx="44" cy="44" rx="4" ry="4.6" fill="{INK}"/><ellipse cx="56" cy="44" rx="4" ry="4.6" fill="{INK}"/>'
            + poly([(50, 48), (52.4, 53), (47.6, 53)], INK)
            + f'<path d="M45 57 V60 M50 57 V60 M55 57 V60" stroke="{INK}" stroke-width="1"/>')


def moon(x, y, r):
    return (f'<circle cx="{x}" cy="{y}" r="{r + 4}" fill="{CREAM}" opacity="0.18"/>'
            f'<circle cx="{x}" cy="{y}" r="{r}" fill="{CREAM}"/>'
            f'<circle cx="{x - r * 0.35:.1f}" cy="{y - r * 0.2:.1f}" r="{r * 0.18:.1f}" fill="#E0D3AD"/>'
            f'<circle cx="{x + r * 0.3:.1f}" cy="{y + r * 0.35:.1f}" r="{r * 0.12:.1f}" fill="#E0D3AD"/>')


def ghost_hunter():
    # A ghost rising over the graves at night.
    return (rays('night', cy=40)
            + moon(70, 28, 9)
            + ridge([(0, 64), (24, 54), (48, 62), (76, 52), (100, 62)], '#24324A')
            + stones([(22, 86, 6, 18), (78, 86, 6, 18), (34, 90, 4.5, 12), (66, 90, 4.5, 12)], '#3E4E66')
            + '<path d="M36 74 V46 Q36 28 50 28 Q64 28 64 46 V74 L59 69 L54.5 74 L50 69 L45.5 74 L41 69 Z" fill="#DDE8EC"/>'
            + '<path d="M36 46 Q36 30 48 28.5 Q40 34 40 48 V71 L36 74 Z" fill="#B8CCD3"/>'
            + f'<ellipse cx="45" cy="44" rx="2.8" ry="4" fill="{INK}"/><ellipse cx="55" cy="44" rx="2.8" ry="4" fill="{INK}"/>'
            + f'<ellipse cx="50" cy="54" rx="3" ry="3.6" fill="{INK}"/>'
            + '<path d="M36 52 Q28 50 26 44 M64 52 Q72 50 74 44" fill="none" stroke="#DDE8EC" stroke-width="4" stroke-linecap="round"/>')


def wolf_pack():
    # A wolf howling at the moon from a rock.
    return (rays('night', cy=34)
            + moon(36, 26, 11)
            + ridge([(0, 64), (20, 56), (40, 62), (64, 52), (100, 60)], '#24324A')
            + poly([(26, 92), (36, 80), (74, 78), (88, 92)], '#3E4E66')
            # A wolf sitting on the rock, its head thrown back to howl at the moon.
            + f'<path d="M40 82 L42 66 Q42 58 46 52 L40 46 L28 36 L31 34 L38 38 L33 31 L36 30 L44 36 '
              f'L46 26 L51 34 Q58 38 60 46 Q70 54 72 68 L76 82 Z" fill="{INK}"/>'
            + f'<path d="M72 80 Q84 78 86 68 Q86 82 74 86 Z" fill="{INK}"/>'
            + '<circle cx="45.5" cy="39" r="1" fill="#9DD3DD"/>'
            + ''.join(pine(x, b, h, '#1A2638') for x, b, h in ((14, 84, 22), (22, 90, 18), (88, 86, 20))))


def the_long_road():
    # A worn boot before a road that runs to the horizon.
    return (rays('warm', cy=40)
            + ridge([(0, 50), (20, 42), (40, 48), (60, 40), (80, 46), (100, 42)], '#6E9C8E')
            + ridge([(0, 60), (30, 52), (60, 58), (100, 50)], PINE2)
            + poly([(46, 52), (54, 52), (82, 96), (18, 96)], '#E3CB8E')
            + '<path d="M50 56 V60 M50 66 V72 M50 78 V86" stroke="#F7EBC8" stroke-width="1.6" stroke-linecap="round"/>'
            + forest([(14, 72, 18), (86, 72, 18), (10, 84, 20), (90, 84, 20)])
            # A worn walking boot, toe to the right: a cuff, laces, the toe cap and a thick sole with a heel.
            + f'<path d="M24 56 Q31 53 39 56 L40 70 Q42 74 48 75 L56 77 Q63 79 63 85 V87 H24 Z" fill="#7A4B2A" '
              f'stroke="{INK}" stroke-width="1.2" stroke-linejoin="round"/>'
            + '<path d="M24 56 Q31 53 39 56 L39 60 Q31 57 24 60 Z" fill="#A86E40"/>'
            + f'<path d="M40 64 L45 62 M40 68 L46 66 M42 72 L48 70" stroke="{CREAM}" stroke-width="1.1" stroke-linecap="round"/>'
            + '<path d="M50 76 Q60 77 62 84" fill="none" stroke="#5C3519" stroke-width="1.4"/>'
            + f'<path d="M22 87 H64 Q65 91 61 91 H34 V93 H24 V91 Q22 91 22 87 Z" fill="{INK}"/>')


def golem_breaker():
    # The head of a stone golem, cracked, and the hammer that broke it.
    return (rays('teal', cy=44)
            + ridge([(0, 64), (24, 50), (46, 60), (70, 48), (100, 60)], '#8A5A3C')
            + forest(EDGE_TREES)
            + poly([(30, 30), (70, 30), (74, 60), (64, 72), (36, 72), (26, 60)], '#8A8F8C', f' stroke="{INK}" stroke-width="1.4" stroke-linejoin="round"')
            + poly([(30, 30), (70, 30), (66, 38), (34, 38)], '#A9AEAA')
            + poly([(26, 60), (36, 72), (40, 60)], '#6D7270')
            + f'<rect x="36" y="44" width="10" height="6" fill="{INK}"/><rect x="54" y="44" width="10" height="6" fill="{INK}"/>'
            + '<rect x="38" y="45.5" width="6" height="3" fill="#7FD3E0"/><rect x="56" y="45.5" width="6" height="3" fill="#7FD3E0"/>'
            + f'<path d="M42 60 H58 V64 H42 Z" fill="{INK}"/>'
            + f'<path d="M50 30 L47 38 L52 44 M66 38 L60 52 L64 58" fill="none" stroke="{INK}" stroke-width="1.2"/>'
            # The war hammer leans at the golem's side, not across its face.
            + f'<path d="M62 92 L84 60" stroke="#7A4B2A" stroke-width="3" stroke-linecap="round"/>'
            + f'<path d="M76 52 L92 62 L88 68 L72 58 Z" fill="#5E6468" stroke="{INK}" stroke-width="1.2" stroke-linejoin="round"/>')


def troll_slayer():
    # A troll's head over crossed axes.
    axe = lambda x1, y1, x2, y2, s: (
        f'<path d="M{x1} {y1} L{x2} {y2}" stroke="#7A4B2A" stroke-width="2.6" stroke-linecap="round"/>'
        + f'<path d="M{x2} {y2} q{8 * s} -2 {10 * s} 8 q-6 {0} -{8 * s} 4 Z" fill="{CREAM}" stroke="{INK}" stroke-width="1"/>')
    return (rays('warm', cy=40)
            + ridge([(0, 60), (22, 48), (44, 56), (70, 44), (100, 56)], '#6E9C8E')
            + forest(EDGE_TREES)
            + axe(70, 86, 34, 58, -1) + axe(30, 86, 66, 58, 1)
            + poly([(28, 38), (20, 30), (32, 32)], '#6A7C58') + poly([(72, 38), (80, 30), (68, 32)], '#6A7C58')
            + '<path d="M28 42 Q28 22 50 22 Q72 22 72 42 Q72 60 50 64 Q28 60 28 42 Z" fill="#7C8F6A" stroke="#1E2A28" stroke-width="1.2"/>'
            + f'<path d="M34 36 L44 39 M66 36 L56 39" stroke="{INK}" stroke-width="2" stroke-linecap="round"/>'
            + f'<circle cx="41" cy="42" r="2" fill="{INK}"/><circle cx="59" cy="42" r="2" fill="{INK}"/>'
            + '<path d="M46 40 Q50 38 54 40 L56 50 Q50 54 44 50 Z" fill="#6A7C58"/>'
            + f'<path d="M40 56 Q50 60 60 56" fill="none" stroke="{INK}" stroke-width="1.6"/>'
            + poly([(42, 56.5), (44, 50), (45.5, 57.5)], CREAM) + poly([(58, 56.5), (56, 50), (54.5, 57.5)], CREAM))


def wyvern_hunter():
    # A wyvern in flight, and the bow drawn at it.
    return (rays('teal', cy=36)
            + ridge([(0, 66), (20, 52), (40, 62), (62, 48), (100, 62)], '#6E9C8E')
            + forest(EDGE_TREES)
            + '<g transform="translate(52 36) scale(1.45) translate(-50 -38)">'
            + f'<path d="M30 36 Q42 30 50 34 Q58 30 70 36 L62 38 L68 44 L58 42 L54 48 L50 44 L46 48 L42 42 L32 44 L38 38 Z" fill="{INK}"/>'
            + f'<path d="M50 34 L48 28 L52 26 L56 30 Z" fill="{INK}"/>'
            + f'<path d="M50 44 Q48 54 54 58" fill="none" stroke="{INK}" stroke-width="2" stroke-linecap="round"/>'
            + '</g>'
            + '<path d="M30 88 Q24 66 44 56" fill="none" stroke="#7A4B2A" stroke-width="2.8" stroke-linecap="round"/>'
            + f'<path d="M30 88 L44 56" stroke="{CREAM}" stroke-width="0.9"/>'
            + f'<path d="M34 78 L58 52" stroke="{INK}" stroke-width="1.4" stroke-linecap="round"/>'
            + poly([(58, 52), (55, 53), (57, 50)], INK)
            + poly([(34, 78), (31, 79), (33, 75)], '#B5452E'))


def master_smith():
    # An anvil, the hammer on it, and the sparks.
    return (rays('warm', cy=44)
            + ridge([(0, 62), (26, 52), (50, 60), (74, 50), (100, 60)], '#8A5A3C')
            + ridge([(0, 82), (100, 80)], '#5E4F42')
            + f'<path d="M24 52 H70 Q74 52 76 56 H62 V60 Q62 64 58 66 H54 V74 H64 V80 H32 V74 H42 V66 H38 Q34 64 34 60 V58 Q26 58 24 52 Z" fill="{INK}"/>'
            + '<path d="M28 53 H68" stroke="#4E5A58" stroke-width="1.6"/>'
            + f'<path d="M48 48 L66 26" stroke="#7A4B2A" stroke-width="3" stroke-linecap="round"/>'
            + f'<path d="M40 40 L50 32 L58 40 L48 48 Z" fill="#5E6468" stroke="{INK}" stroke-width="1"/>'
            + ''.join(f'<path d="M{x} {y} l{dx} {dy}" stroke="#F2A03C" stroke-width="1.6" stroke-linecap="round"/>'
                      for x, y, dx, dy in ((40, 50, -8, -6), (38, 52, -10, 0), (42, 48, -3, -10), (36, 46, -6, -8)))
            + spark(26, 40, 0.7, '#F7C64A') + spark(30, 30, 0.6, '#F7C64A'))


def smugglers_secret():
    # A chest of gold in a hidden cove, a boat at anchor.
    return (rays('teal', cy=40)
            + '<rect x="0" y="52" width="100" height="48" fill="#4F8FA6"/>'
            + poly([(0, 30), (16, 36), (24, 52), (30, 70), (0, 76)], '#8A5A3C')
            + poly([(100, 34), (84, 40), (76, 54), (70, 70), (100, 76)], '#8A5A3C')
            + poly([(0, 30), (16, 36), (10, 44), (0, 42)], '#A87650') + poly([(100, 34), (84, 40), (90, 46), (100, 46)], '#A87650')
            # The boat at anchor, out on the water to the right of the chest.
            + '<g transform="translate(66 52) scale(0.8) translate(-52 -56)">'
            + f'<path d="M42 58 H62 L58 63 H46 Z" fill="{INK}"/><path d="M52 58 V44" stroke="{INK}" stroke-width="1.2"/>'
            + poly([(52.5, 44), (60, 55), (52.5, 55)], CREAM)
            + '</g>'
            + '<path d="M0 82 Q50 70 100 82 V100 H0 Z" fill="#E3CB8E"/>'
            # A treasure chest: the lid stands open behind, gold heaps inside, the front is a box with two
            # bands and a lock, and coins lie spilled on the sand.
            + f'<path d="M35 74 L37 60 H63 L65 74 Z" fill="#5C3519" stroke="{INK}" stroke-width="1.2" stroke-linejoin="round"/>'
            + f'<path d="M37 60 H63" stroke="#9C6334" stroke-width="2.4"/>'
            + f'<path d="M42 61 V73 M58 61 V73" stroke="#D9A441" stroke-width="1.6"/>'
            + f'<path d="M34 75 Q38 66 44 68 Q50 63 56 68 Q62 66 66 75 Z" fill="#F7C64A" stroke="{INK}" stroke-width="1"/>'
            + ''.join(f'<circle cx="{x}" cy="{y}" r="1.6" fill="#FFE08A" stroke="#B5822A" stroke-width="0.5"/>'
                      for x, y in ((42, 69), (50, 66), (57, 69), (46, 72), (54, 72)))
            + f'<rect x="33" y="74" width="34" height="15" fill="#7A4B2A" stroke="{INK}" stroke-width="1.2"/>'
            + f'<path d="M33 74 H67" stroke="#9C6334" stroke-width="2"/>'
            + f'<path d="M40 74 V89 M60 74 V89" stroke="#D9A441" stroke-width="2"/>'
            + f'<rect x="46.5" y="76" width="7" height="7" rx="1" fill="#D9A441" stroke="{INK}" stroke-width="0.8"/>'
            + f'<circle cx="50" cy="79" r="1" fill="{INK}"/><path d="M50 79 V81.4" stroke="{INK}" stroke-width="0.8"/>'
            + ''.join(f'<ellipse cx="{x}" cy="{y}" rx="2.2" ry="1.2" fill="#F7C64A" stroke="#B5822A" stroke-width="0.5"/>'
                      for x, y in ((28, 90), (72, 89), (75, 92), (24, 93)))
            + spark(62, 62, 0.7, '#FFF3C4') + spark(38, 64, 0.5, '#FFF3C4'))


def master_of_a_trade():
    # The four gathering tools: pickaxe and hatchet crossed before the rod and the bow.
    return (rays('warm', cy=48)
            + ridge([(0, 70), (24, 62), (50, 68), (76, 60), (100, 68)], PINE2)
            + forest([(16, 88, 16), (84, 88, 16)])
            # rod and bow, upright behind
            + '<path d="M30 86 Q34 50 40 22" fill="none" stroke="#7A4B2A" stroke-width="2" stroke-linecap="round"/>'
            + f'<path d="M40 22 Q46 40 44 52" fill="none" stroke="{INK}" stroke-width="0.6"/>'
            + '<path d="M66 20 Q80 50 66 84" fill="none" stroke="#7A4B2A" stroke-width="2.6" stroke-linecap="round"/>'
            + f'<path d="M66 20 L66 84" stroke="{CREAM}" stroke-width="0.8"/>'
            # pickaxe and hatchet, crossed in front
            + f'<path d="M30 80 L70 36" stroke="#9C6334" stroke-width="3.4" stroke-linecap="round"/>'
            + f'<path d="M56 26 Q72 26 80 42 Q70 34 58 32 Z" fill="#5E6468" stroke="{INK}" stroke-width="1"/>'
            + f'<path d="M70 80 L30 36" stroke="#9C6334" stroke-width="3.4" stroke-linecap="round"/>'
            + f'<path d="M30 36 L24 28 Q30 24 38 30 L36 40 Z" fill="#8A8F8C" stroke="{INK}" stroke-width="1"/>'
            + spark(50, 18, 0.9))


DRAW = {
    'adventurer': adventurer,
    'seasoned': seasoned,
    'champion': champion,
    'lucky_find': lambda: find('lucky_find'),
    'rare_find': lambda: find('rare_find'),
    'epic_find': lambda: find('epic_find'),
    'legendary_find': lambda: find('legendary_find'),
    'angler': angler,
    'deep_waters': deep_waters,
    'bone_collector': bone_collector,
    'ghost_hunter': ghost_hunter,
    'wolf_pack': wolf_pack,
    'the_long_road': the_long_road,
    'golem_breaker': golem_breaker,
    'troll_slayer': troll_slayer,
    'wyvern_hunter': wyvern_hunter,
    'master_smith': master_smith,
    'smugglers_secret': smugglers_secret,
    'master_of_a_trade': master_of_a_trade,
}


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, draw in DRAW.items():
        with open(os.path.join(OUT, f'{name}.svg'), 'w', encoding='utf-8', newline='\n') as f:
            f.write(patch(draw()))
    print(f'{len(DRAW)} achievements written to {OUT}')
    if '--preview' in sys.argv:
        path = sys.argv[sys.argv.index('--preview') + 1]
        app = os.path.join(HERE, '..', 'app', 'assets', 'images', 'achievements')
        cells = ''
        for name in DRAW:
            src = 'file:///' + os.path.join(OUT, f'{name}.svg').replace('\\', '/')
            cells += (f'<figure><img src="{src}" width="128"><img src="{src}" width="72">'
                      f'<figcaption>{name}</figcaption></figure>')
        for name in ('bear_hunter', 'prospector', 'goblin_slayer_1', 'marathon'):
            src = 'file:///' + os.path.abspath(os.path.join(app, f'{name}.webp')).replace('\\', '/')
            cells += (f'<figure><img src="{src}" width="128"><img src="{src}" width="72">'
                      f'<figcaption>nabriis: {name}</figcaption></figure>')
        with open(path, 'w', encoding='utf-8') as f:
            f.write('<!DOCTYPE html><html><body style="background:#1B1F22;color:#ccc;font:12px sans-serif;margin:8px">'
                    '<style>figure{display:inline-block;margin:6px;text-align:center;width:210px}'
                    'img{vertical-align:middle;margin:2px}</style>' + cells + '</body></html>')
        print(f'preview: {path}')


if __name__ == '__main__':
    main()
