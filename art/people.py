# Draws the portraits of the people of the story (spec 0023 §3.5) to art/portraits/<id>.svg, and the picture of a
# found lore page to art/pictures/lore_page.svg. Claude draws them until nabriis draws the real art (art/README.md).
# The style of art/README.md: rich, warm colour, light from the top left, a thin dark-brown outline. Each portrait is a
# bust on a round backdrop of its own colour, so the four people differ at a glance by colour and by silhouette:
#   Odda:   auburn hair in a bun, a quill, the teal coat of the Guild, a warm amber backdrop;
#   Pell:   bald, a big white beard, soot on the cheeks, a leather apron, an ember-orange backdrop;
#   Aldous: a dark hood, a pale long face, a lantern glow, a cold blue-grey backdrop;
#   Jory:   a wide black hat, a red scarf, a gold earring, a sly look, a deep sea-green backdrop.
# The six teachers and Ysolde at Camp (spec 0023 §3.6):
#   Hilde:  a brass helmet with a lamp, short braids, dust, slate and copper, a dark stone backdrop;
#   Bram:   a green wool cap, a broad red beard, an axe on the shoulder, a leaf-green backdrop;
#   Wen:    a knitted blue cap, grey stubble, a pipe, a yellow oilskin, a sky-blue backdrop;
#   Sigrun: a fur hood, a long fair braid, a green cloak and a bow, a pale snow backdrop;
#   Garrow: bald, a short black beard, bare arms, a leather apron, a hammer, a forge-red backdrop;
#   Marta:  a white headscarf, red cheeks, a wide smile, a wooden spoon, a rose backdrop;
#   Ysolde: long silver hair, a gold circlet, a violet cloak with the Guild's clasp, a violet backdrop.
# Run: python art/people.py. Then .\scripts\export-art.ps1 -Only <the ids that changed>.
import os

HERE = os.path.dirname(os.path.abspath(__file__))
INK = '#24140A'
SKIN = ('#F2C9A0', '#C98B5E')
PALE = ('#E8DCCB', '#A99886')


def grad(id_, a, b, x2=1, y2=1):
    return (f'<linearGradient id="{id_}" x1="0" y1="0" x2="{x2}" y2="{y2}"><stop offset="0" stop-color="{a}"/>'
            f'<stop offset="1" stop-color="{b}"/></linearGradient>')


def backdrop(inner, outer):
    """A round backdrop with a soft light from the top left and a dark rim."""
    return (f'<radialGradient id="bg" cx="0.36" cy="0.32" r="0.75"><stop offset="0" stop-color="{inner}"/>'
            f'<stop offset="1" stop-color="{outer}"/></radialGradient>'
            '<clipPath id="disc"><circle cx="50" cy="50" r="46"/></clipPath>')


def frame(body):
    return (f'<circle cx="50" cy="50" r="48" fill="#2A1A0C"/>'
            f'<circle cx="50" cy="50" r="46" fill="url(#bg)"/>'
            f'<g clip-path="url(#disc)">{body}</g>'
            f'<circle cx="50" cy="50" r="46" fill="none" stroke="{INK}" stroke-width="2"/>')


def face(cx=50, cy=46, rx=15, ry=18, skin='skin'):
    """An oval face, lit from the top left, with a cheek glow."""
    return (f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="url(#{skin})" stroke="{INK}" stroke-width="1.4"/>'
            f'<ellipse cx="{cx - rx * 0.35}" cy="{cy - ry * 0.35}" rx="{rx * 0.35}" ry="{ry * 0.22}" fill="#FFFFFF" '
            'opacity="0.18"/>')


def eyes(cx=50, y=44, gap=6, look=0, squint=False):
    """Two eyes [gap] from the middle; [look] moves the pupils sideways; [squint] draws two kind arcs instead."""
    out = ''
    for side in (-1, 1):
        x = cx + side * gap
        if squint:
            out += (f'<path d="M{x - 2.6} {y} Q{x} {y - 1.6} {x + 2.6} {y}" fill="none" stroke="{INK}" '
                    'stroke-width="1.4" stroke-linecap="round"/>')
        else:
            out += (f'<ellipse cx="{x}" cy="{y}" rx="2.2" ry="1.6" fill="#FFFFFF" stroke="{INK}" stroke-width="0.8"/>'
                    f'<circle cx="{x + look}" cy="{y}" r="1.1" fill="{INK}"/>')
    return out


def nose(cx=50, y=50):
    return f'<path d="M{cx} {y - 4} Q{cx - 2.4} {y + 1} {cx + 1} {y + 1.6}" fill="none" stroke="{INK}" stroke-width="1.1" ' \
           'stroke-linecap="round" opacity="0.8"/>'


def odda():
    defs = (backdrop('#F2B65C', '#7A4310') + grad('skin', *SKIN) + grad('hair', '#C2602C', '#5E2410')
            + grad('coat', '#3FB3A8', '#14514C'))
    body = (
        # The coat of the Guild, with a cream collar.
        f'<path d="M14 100 Q16 72 36 66 L50 72 L64 66 Q84 72 86 100 Z" fill="url(#coat)" stroke="{INK}" '
        'stroke-width="1.6"/>'
        f'<path d="M38 66 L50 80 L62 66 L56 64 L50 72 L44 64 Z" fill="#EFE3C4" stroke="{INK}" stroke-width="1.2"/>'
        # A ledger under her arm.
        f'<rect x="64" y="78" width="18" height="22" rx="2" transform="rotate(-12 73 89)" fill="#7A3E1C" '
        f'stroke="{INK}" stroke-width="1.2"/>'
        f'<path d="M44 60 Q50 66 56 60 V66 H44 Z" fill="url(#skin)" stroke="{INK}" stroke-width="1.2"/>'
        # The hair behind, the face, then the bun and the fringe.
        f'<path d="M33 46 Q32 24 50 23 Q68 24 67 46 Q66 56 62 58 Q66 40 50 36 Q34 40 38 58 Q34 56 33 46 Z" '
        f'fill="url(#hair)" stroke="{INK}" stroke-width="1.4"/>'
        + face(50, 46, 14, 17)
        + f'<circle cx="50" cy="20" r="8" fill="url(#hair)" stroke="{INK}" stroke-width="1.4"/>'
        f'<path d="M36 40 Q42 28 52 30 Q60 30 64 40 Q56 33 50 34 Q42 34 36 40 Z" fill="url(#hair)" stroke="{INK}" '
        'stroke-width="1.2"/>'
        '<path d="M44 18 Q48 14 54 16" fill="none" stroke="#F0A070" stroke-width="1.2" opacity="0.8"/>'
        # A grey streak, then the quill behind her ear.
        '<path d="M58 30 Q63 34 64 42" fill="none" stroke="#D8D0C4" stroke-width="1.6" opacity="0.9"/>'
        f'<path d="M66 44 L82 18 Q84 22 80 28 Q78 34 70 42 Z" fill="#F4F0E6" stroke="{INK}" stroke-width="1.1"/>'
        + eyes(50, 45, 5.5, look=0.4)
        + nose(50, 51)
        + f'<path d="M45 56 Q50 59 55 56" fill="none" stroke="{INK}" stroke-width="1.3" stroke-linecap="round"/>'
    )
    return defs, body


def pell():
    defs = (backdrop('#FF9A3C', '#5A1A04') + grad('skin', '#E8B488', '#A86A40') + grad('beard', '#FFFFFF', '#B8B4AC')
            + grad('apron', '#8E5A2E', '#3E220C'))
    soot = ''.join(f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="#2A2420" opacity="0.45"/>'
                   for x, y, rx, ry in ((40, 50, 3.5, 2), (61, 47, 2.6, 1.6), (54, 36, 2, 1.2)))
    embers = ''.join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="#FFD27A" opacity="0.9"/>'
                     for x, y, r in ((18, 30, 1.4), (82, 24, 1.1), (76, 40, 0.9), (22, 52, 1)))
    body = (
        embers
        # A broad, stooped body in a leather apron over a rough shirt.
        + f'<path d="M10 100 Q12 70 34 64 L66 64 Q88 70 90 100 Z" fill="#6E6A5A" stroke="{INK}" stroke-width="1.6"/>'
        f'<path d="M30 100 L34 68 L66 68 L70 100 Z" fill="url(#apron)" stroke="{INK}" stroke-width="1.4"/>'
        # A bald, broad head with a wide face.
        + face(50, 44, 17, 18)
        + '<path d="M38 30 Q46 25 56 27" fill="none" stroke="#FFFFFF" stroke-width="2" opacity="0.35"/>'
        # Ears, then white tufts above them.
        + ''.join(f'<ellipse cx="{x}" cy="46" rx="3" ry="4.5" fill="url(#skin)" stroke="{INK}" stroke-width="1.1"/>'
                  for x in (33, 67))
        + ''.join(f'<path d="M{x} 40 q{d * 4} -4 {d * 6} 2 q-{d * 2} 2 -{d * 6} 2 Z" fill="url(#beard)" '
                  f'stroke="{INK}" stroke-width="0.9"/>' for x, d in ((34, -1), (66, 1)))
        + soot
        # Bushy brows, small kind eyes, a big nose.
        + f'<path d="M39 39 Q44 36 48 39" fill="none" stroke="#F4F4F4" stroke-width="2.6" stroke-linecap="round"/>'
        f'<path d="M52 39 Q56 36 61 39" fill="none" stroke="#F4F4F4" stroke-width="2.6" stroke-linecap="round"/>'
        + eyes(50, 43, 6, squint=True)
        + f'<ellipse cx="50" cy="50" rx="4" ry="3.4" fill="#D98E6A" stroke="{INK}" stroke-width="1.1"/>'
        # A big white beard to the chest.
        f'<path d="M34 50 Q36 58 42 56 Q46 60 50 58 Q54 60 58 56 Q64 58 66 50 Q70 66 60 76 Q54 82 50 80 '
        f'Q46 82 40 76 Q30 66 34 50 Z" fill="url(#beard)" stroke="{INK}" stroke-width="1.4"/>'
        '<path d="M44 62 Q46 70 44 76 M50 62 V78 M56 62 Q54 70 56 76" fill="none" stroke="#B8B4AC" '
        'stroke-width="0.9"/>'
        f'<path d="M45 56 Q50 54 55 56" fill="none" stroke="{INK}" stroke-width="1.1"/>'
    )
    return defs, body


def aldous():
    defs = (backdrop('#8EA4B6', '#1C2632') + grad('skin', *PALE) + grad('hood', '#4A3A56', '#140E1C')
            + '<radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFE7A0" '
            'stop-opacity="0.9"/><stop offset="1" stop-color="#FFE7A0" stop-opacity="0"/></radialGradient>')
    body = (
        # The lantern's glow at the lower right, then the lantern.
        '<circle cx="76" cy="78" r="20" fill="url(#glow)"/>'
        # A tall, narrow robe and hood.
        f'<path d="M18 100 Q22 70 40 64 L60 64 Q78 70 82 100 Z" fill="url(#hood)" stroke="{INK}" stroke-width="1.6"/>'
        f'<path d="M30 60 Q26 30 36 18 Q50 8 64 18 Q74 30 70 60 Q64 68 50 68 Q36 68 30 60 Z" fill="url(#hood)" '
        f'stroke="{INK}" stroke-width="1.6"/>'
        # The hood's shadow round a long, pale face.
        '<ellipse cx="50" cy="46" rx="15" ry="20" fill="#0C0812" opacity="0.6"/>'
        + face(50, 47, 11.5, 17)
        + '<path d="M44 30 Q50 26 56 30" fill="none" stroke="#4A3A56" stroke-width="3"/>'
        # Tired eyes with dark rings, a long nose, grey stubble, a thin mouth.
        + ''.join(f'<path d="M{x - 3} 46 Q{x} 48 {x + 3} 46" fill="none" stroke="#7A6A72" stroke-width="1.2"/>'
                  for x in (45, 55))
        + eyes(50, 43, 5, look=-0.4)
        + f'<path d="M50 44 L48 54 Q50 55 52 54" fill="none" stroke="{INK}" stroke-width="1.1" stroke-linecap="round"/>'
        '<path d="M40 54 Q50 66 60 54 Q58 62 50 63 Q42 62 40 54 Z" fill="#9C948C" opacity="0.55"/>'
        f'<path d="M46 59 H54" stroke="{INK}" stroke-width="1.2" stroke-linecap="round"/>'
        # A lantern on its ring.
        f'<path d="M72 66 Q76 60 80 66" fill="none" stroke="{INK}" stroke-width="1.4"/>'
        f'<rect x="70" y="66" width="12" height="16" rx="2" fill="#FFD772" stroke="{INK}" stroke-width="1.4"/>'
        f'<path d="M70 70 H82 M70 78 H82 M76 66 V82" stroke="{INK}" stroke-width="1"/>'
        f'<path d="M69 82 H83 L81 86 H71 Z" fill="#3A3028" stroke="{INK}" stroke-width="1.2"/>'
    )
    return defs, body


def jory():
    defs = (backdrop('#3E8C80', '#0C2624') + grad('skin', '#E2AE80', '#9A6038') + grad('hat', '#3A3430', '#0E0C0A')
            + grad('scarf', '#E0503A', '#7A1A10') + grad('coat', '#5A4A36', '#20180E'))
    body = (
        # A dark coat with its collar up.
        f'<path d="M12 100 Q14 72 34 64 L66 64 Q86 72 88 100 Z" fill="url(#coat)" stroke="{INK}" stroke-width="1.6"/>'
        + face(50, 48, 14, 17)
        # Stubble, a sly half smile, a scar on the cheek.
        + '<path d="M37 52 Q40 64 50 66 Q60 64 63 52 Q62 60 50 62 Q38 60 37 52 Z" fill="#5A3C28" opacity="0.4"/>'
        f'<path d="M44 57 Q50 60 57 55" fill="none" stroke="{INK}" stroke-width="1.3" stroke-linecap="round"/>'
        '<path d="M58 44 L62 52" stroke="#B0603E" stroke-width="1.2" stroke-linecap="round"/>'
        # Narrow, sideways eyes under a low brow.
        + eyes(50, 46, 5.5, look=1)
        + f'<path d="M41 41 L48 43 M52 43 L59 40" stroke="{INK}" stroke-width="1.6" stroke-linecap="round"/>'
        + nose(50, 52)
        # A gold earring.
        + f'<circle cx="36" cy="54" r="2.6" fill="none" stroke="#F2C24A" stroke-width="1.4"/>'
        # A red scarf at the throat, its knot to one side.
        f'<path d="M34 64 Q50 74 66 64 L66 70 Q50 80 34 70 Z" fill="url(#scarf)" stroke="{INK}" stroke-width="1.4"/>'
        f'<path d="M58 70 L64 86 L56 82 Z" fill="url(#scarf)" stroke="{INK}" stroke-width="1.2"/>'
        # A wide-brimmed hat, pulled low.
        f'<path d="M14 36 Q50 28 86 36 Q80 42 50 40 Q20 42 14 36 Z" fill="url(#hat)" stroke="{INK}" '
        'stroke-width="1.6"/>'
        f'<path d="M30 36 Q30 14 50 14 Q70 14 70 36 Q50 32 30 36 Z" fill="url(#hat)" stroke="{INK}" '
        'stroke-width="1.6"/>'
        '<path d="M30 33 Q50 29 70 33" fill="none" stroke="#7A1A10" stroke-width="2.4"/>'
        '<path d="M36 20 Q42 16 50 16" fill="none" stroke="#FFFFFF" stroke-width="1.2" opacity="0.3"/>'
    )
    return defs, body


def hilde():
    defs = (backdrop('#9A8670', '#1E1610') + grad('skin', '#EDBE94', '#A8724A') + grad('helm', '#F2CC5A', '#8A5A12')
            + grad('shirt', '#6A7480', '#262C34') + grad('hair', '#A0522D', '#4A200C')
            + '<radialGradient id="beam" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFF6C8" '
            'stop-opacity="0.9"/><stop offset="1" stop-color="#FFF6C8" stop-opacity="0"/></radialGradient>')
    body = (
        # A slate shirt with copper braces.
        f'<path d="M12 100 Q14 72 34 65 L66 65 Q86 72 88 100 Z" fill="url(#shirt)" stroke="{INK}" stroke-width="1.6"/>'
        f'<path d="M36 66 L40 100 M64 66 L60 100" stroke="#C8743A" stroke-width="4"/>'
        f'<path d="M44 60 Q50 66 56 60 V67 H44 Z" fill="url(#skin)" stroke="{INK}" stroke-width="1.2"/>'
        # Two short braids under the helmet.
        + ''.join(f'<path d="M{x} 44 Q{x + d * 3} 56 {x} 66" fill="none" stroke="url(#hair)" stroke-width="5" '
                  'stroke-linecap="round"/>' for x, d in ((34, -1), (66, 1)))
        + face(50, 47, 15, 17)
        # Dust on the cheek and the brow.
        + ''.join(f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="#5A4A3A" opacity="0.4"/>'
                  for x, y, rx, ry in ((40, 53, 3, 1.8), (60, 41, 2.4, 1.2)))
        + eyes(50, 46, 6, look=0.3)
        + f'<path d="M41 41 Q45 39 48 41 M52 41 Q55 39 59 41" fill="none" stroke="#6A3418" stroke-width="1.6" '
        'stroke-linecap="round"/>'
        + nose(50, 52)
        + f'<path d="M44 57 Q50 60 56 57" fill="none" stroke="{INK}" stroke-width="1.3" stroke-linecap="round"/>'
        # A brass helmet with a brim and a lamp in front, its light above.
        + '<circle cx="50" cy="12" r="12" fill="url(#beam)"/>'
        f'<path d="M32 38 Q32 18 50 18 Q68 18 68 38 Z" fill="url(#helm)" stroke="{INK}" stroke-width="1.6"/>'
        f'<path d="M28 38 Q50 32 72 38 Q50 42 28 38 Z" fill="url(#helm)" stroke="{INK}" stroke-width="1.4"/>'
        '<path d="M38 26 Q44 21 52 21" fill="none" stroke="#FFFFFF" stroke-width="1.4" opacity="0.5"/>'
        f'<circle cx="50" cy="26" r="5" fill="#FFF6C8" stroke="{INK}" stroke-width="1.4"/>'
    )
    return defs, body


def bram():
    defs = (backdrop('#9CCB5A', '#1E3A0C') + grad('skin', '#EBB890', '#A66C44') + grad('beard', '#E07A3A', '#7A2E0C')
            + grad('cap', '#4E8A3A', '#1A3A10') + grad('vest', '#8A6038', '#3A2410') + grad('steel', '#E8ECF0', '#7A848E'))
    body = (
        # An axe over the right shoulder, its haft behind him.
        f'<path d="M58 100 L84 30" stroke="#7A4A22" stroke-width="5" stroke-linecap="round"/>'
        f'<path d="M58 100 L84 30" stroke="{INK}" stroke-width="0.8" fill="none"/>'
        f'<path d="M78 28 Q92 20 94 36 Q88 34 84 40 Z" fill="url(#steel)" stroke="{INK}" stroke-width="1.3"/>'
        # A cream shirt under a leather vest, broad shoulders.
        f'<path d="M8 100 Q10 70 34 63 L66 63 Q90 70 92 100 Z" fill="#E8DCC0" stroke="{INK}" stroke-width="1.6"/>'
        f'<path d="M8 100 Q10 70 34 63 L42 100 Z M92 100 Q90 70 66 63 L58 100 Z" fill="url(#vest)" stroke="{INK}" '
        'stroke-width="1.4"/>'
        + face(50, 44, 15, 17)
        + eyes(50, 42, 6, look=-0.3)
        + f'<path d="M40 37 L48 38 M52 38 L60 37" stroke="#7A2E0C" stroke-width="2.2" stroke-linecap="round"/>'
        + nose(50, 48)
        # A broad red beard, square at the bottom.
        + f'<path d="M35 46 Q36 54 42 54 Q50 58 58 54 Q64 54 65 46 Q68 62 64 72 Q50 78 36 72 Q32 62 35 46 Z" '
        f'fill="url(#beard)" stroke="{INK}" stroke-width="1.4"/>'
        f'<path d="M44 54 Q50 52 56 54" fill="none" stroke="{INK}" stroke-width="1.2"/>'
        '<path d="M42 60 V70 M50 59 V73 M58 60 V70" stroke="#A04818" stroke-width="0.9"/>'
        # A green wool cap with a turned-up brim.
        f'<path d="M34 34 Q32 14 50 14 Q68 14 66 34 Z" fill="url(#cap)" stroke="{INK}" stroke-width="1.6"/>'
        f'<rect x="32" y="29" width="36" height="8" rx="3" fill="#3A6E2A" stroke="{INK}" stroke-width="1.4"/>'
        '<path d="M40 22 V29 M46 18 V29 M52 17 V29 M58 19 V29" stroke="#2A5A1C" stroke-width="1"/>'
    )
    return defs, body


def wen():
    defs = (backdrop('#6CB8F0', '#0C2A4E') + grad('skin', '#E6B28C', '#9E6A48') + grad('cap', '#3A6ABE', '#14306A')
            + grad('oil', '#FFD84A', '#B08A10'))
    smoke = ('<path d="M78 46 Q74 40 79 35 Q84 30 80 24" fill="none" stroke="#FFFFFF" stroke-width="1.8" '
             'opacity="0.55" stroke-linecap="round"/>')
    body = (
        # A yellow oilskin coat with its collar up.
        f'<path d="M12 100 Q14 72 34 64 L66 64 Q86 72 88 100 Z" fill="url(#oil)" stroke="{INK}" stroke-width="1.6"/>'
        f'<path d="M34 64 L42 78 L50 68 L58 78 L66 64" fill="none" stroke="{INK}" stroke-width="1.3"/>'
        f'<path d="M50 68 V100" stroke="{INK}" stroke-width="1.2"/>'
        + face(50, 47, 14, 17)
        # Grey stubble on a weathered face.
        + '<path d="M37 50 Q38 64 50 66 Q62 64 63 50 Q62 60 50 62 Q38 60 37 50 Z" fill="#8A8A88" opacity="0.5"/>'
        + eyes(50, 45, 5.5, squint=True)
        + ''.join(f'<path d="M{x} 47 l{d * 3} 1.5" stroke="#8A5A3A" stroke-width="0.8"/>' for x, d in ((42, -1), (58, 1)))
        + nose(50, 52)
        + f'<path d="M45 57 Q49 59 54 57" fill="none" stroke="{INK}" stroke-width="1.2" stroke-linecap="round"/>'
        # A pipe from the corner of the mouth, and its smoke.
        f'<path d="M54 57 L70 54" stroke="#4A2A14" stroke-width="2.2" stroke-linecap="round"/>'
        f'<path d="M68 48 H76 L75 56 Q72 58 69 56 Z" fill="#6A3A1A" stroke="{INK}" stroke-width="1.2"/>'
        + smoke
        # A knitted blue cap, rolled at the brim.
        + f'<path d="M35 36 Q34 18 50 18 Q66 18 65 36 Z" fill="url(#cap)" stroke="{INK}" stroke-width="1.6"/>'
        f'<rect x="33" y="31" width="34" height="8" rx="3.5" fill="#2A54A0" stroke="{INK}" stroke-width="1.4"/>'
        '<path d="M37 34 H63" stroke="#6A94DE" stroke-width="1" stroke-dasharray="2 2"/>'
        '<path d="M40 24 Q46 20 52 20" fill="none" stroke="#FFFFFF" stroke-width="1.2" opacity="0.35"/>'
    )
    return defs, body


def sigrun():
    defs = (backdrop('#EEEAE0', '#5A5A50') + grad('skin', '#F4D2B4', '#B88A68') + grad('fur', '#8A6440', '#3A2614')
            + grad('cloak', '#4E7A3E', '#1A3410') + grad('braid', '#F6DC8A', '#B08A2A'))
    body = (
        # A green cloak, a bow string across the chest.
        f'<path d="M12 100 Q14 72 34 64 L66 64 Q86 72 88 100 Z" fill="url(#cloak)" stroke="{INK}" stroke-width="1.6"/>'
        f'<path d="M22 70 L78 100" stroke="#E8E0C8" stroke-width="1.4"/>'
        f'<path d="M14 62 Q8 84 22 100" fill="none" stroke="#6A3E1A" stroke-width="3.4" stroke-linecap="round"/>'
        # A fur hood round the face, with a pale trim.
        f'<path d="M28 64 Q22 34 34 20 Q50 8 66 20 Q78 34 72 64 Q60 70 50 70 Q40 70 28 64 Z" fill="url(#fur)" '
        f'stroke="{INK}" stroke-width="1.6"/>'
        '<path d="M34 62 Q30 36 40 26 Q50 20 60 26 Q70 36 66 62" fill="none" stroke="#F4EEDC" stroke-width="4" '
        'stroke-linecap="round"/>'
        + face(50, 46, 13, 17)
        + eyes(50, 44, 5.5, look=-0.6)
        + f'<path d="M42 39 L48 40 M52 40 L58 39" stroke="#9A7A2A" stroke-width="1.5" stroke-linecap="round"/>'
        + nose(50, 50)
        + f'<path d="M46 56 H54" stroke="{INK}" stroke-width="1.3" stroke-linecap="round"/>'
        # Fair hair at the brow, and a long braid over the shoulder.
        + f'<path d="M38 36 Q44 30 50 32 Q56 30 62 36 Q56 33 50 34 Q44 33 38 36 Z" fill="url(#braid)" '
        f'stroke="{INK}" stroke-width="1"/>'
        + ''.join(f'<ellipse cx="{x}" cy="{y}" rx="4.4" ry="3.6" fill="url(#braid)" stroke="{INK}" stroke-width="1"/>'
                  for x, y in ((62, 66), (64, 72), (65, 78), (66, 84), (66, 90)))
        + f'<rect x="63" y="93" width="6" height="3" rx="1" fill="#C0402A" stroke="{INK}" stroke-width="0.8"/>'
    )
    return defs, body


def garrow():
    defs = (backdrop('#F05A3A', '#3A0804') + grad('skin', '#D8A07A', '#8A5634') + grad('beard', '#3A3030', '#0E0A0A')
            + grad('apron', '#9A4E28', '#40180A') + grad('iron', '#B8C0C8', '#4A525A'))
    body = (
        # A hammer over the left shoulder.
        f'<path d="M40 100 L18 40" stroke="#7A4A22" stroke-width="5" stroke-linecap="round"/>'
        f'<rect x="8" y="28" width="20" height="12" rx="2" transform="rotate(-20 18 34)" fill="url(#iron)" '
        f'stroke="{INK}" stroke-width="1.3"/>'
        # Very broad shoulders, bare arms, a heavy leather apron.
        f'<path d="M4 100 Q6 66 32 60 L68 60 Q94 66 96 100 Z" fill="url(#skin)" stroke="{INK}" stroke-width="1.6"/>'
        f'<path d="M28 100 L32 64 L68 64 L72 100 Z" fill="url(#apron)" stroke="{INK}" stroke-width="1.4"/>'
        f'<path d="M32 64 L40 56 M68 64 L60 56" stroke="#40180A" stroke-width="2.4"/>'
        # A bald, broad head with a shine.
        + face(50, 42, 16, 17)
        + '<path d="M38 30 Q46 25 56 27" fill="none" stroke="#FFFFFF" stroke-width="2" opacity="0.35"/>'
        + ''.join(f'<ellipse cx="{x}" cy="44" rx="3" ry="4.2" fill="url(#skin)" stroke="{INK}" stroke-width="1.1"/>'
                  for x in (34, 66))
        # Heavy black brows, steady eyes, a short black beard.
        + f'<path d="M39 36 L48 38 M52 38 L61 36" stroke="{INK}" stroke-width="3" stroke-linecap="round"/>'
        + eyes(50, 41, 6)
        + nose(50, 47)
        + f'<path d="M35 44 Q36 52 42 52 Q50 50 58 52 Q64 52 65 44 Q66 60 50 66 Q34 60 35 44 Z" fill="url(#beard)" '
        f'stroke="{INK}" stroke-width="1.4"/>'
        f'<path d="M44 55 Q50 53 56 55" fill="none" stroke="#D88A6A" stroke-width="1.3"/>'
    )
    return defs, body


def marta():
    defs = (backdrop('#F4A0B4', '#6A1A30') + grad('skin', '#F4CCA8', '#C08A62') + grad('scarf', '#FFFFFF', '#C8C0B4')
            + grad('dress', '#D8443A', '#701810') + grad('spoon', '#D8A060', '#7A4A1C'))
    body = (
        # A red dress, a white apron bib.
        f'<path d="M12 100 Q14 72 34 64 L66 64 Q86 72 88 100 Z" fill="url(#dress)" stroke="{INK}" stroke-width="1.6"/>'
        f'<path d="M38 100 L40 70 Q50 74 60 70 L62 100 Z" fill="#F6F0E4" stroke="{INK}" stroke-width="1.3"/>'
        # A wooden spoon held up.
        f'<path d="M80 100 L76 52" stroke="url(#spoon)" stroke-width="3.6" stroke-linecap="round"/>'
        f'<ellipse cx="75.5" cy="46" rx="5" ry="7" fill="url(#spoon)" stroke="{INK}" stroke-width="1.2"/>'
        # A round face with red cheeks and a wide smile.
        + face(50, 47, 16, 17)
        + ''.join(f'<circle cx="{x}" cy="52" r="3.8" fill="#E8605A" opacity="0.55"/>' for x in (40, 60))
        + eyes(50, 45, 6, squint=True)
        + nose(50, 51)
        + f'<path d="M43 56 Q50 63 57 56 Q50 59 43 56 Z" fill="#8A2A20" stroke="{INK}" stroke-width="1.2"/>'
        # Dark hair at the brow, and a white headscarf knotted on top.
        + '<path d="M36 40 Q42 34 50 35 Q58 34 64 40 Q58 37 50 38 Q42 37 36 40 Z" fill="#4A2A18"/>'
        f'<path d="M32 44 Q30 20 50 19 Q70 20 68 44 Q64 34 50 33 Q36 34 32 44 Z" fill="url(#scarf)" stroke="{INK}" '
        'stroke-width="1.6"/>'
        f'<path d="M44 20 Q40 10 46 10 Q50 14 50 19 Q50 14 54 10 Q60 10 56 20 Z" fill="url(#scarf)" stroke="{INK}" '
        'stroke-width="1.3"/>'
        '<path d="M36 30 Q44 23 54 23" fill="none" stroke="#D8443A" stroke-width="1.4" stroke-dasharray="2 3"/>'
    )
    return defs, body


def ysolde():
    defs = (backdrop('#B08AF0', '#1E0C44') + grad('skin', '#F2D4C0', '#B8907A') + grad('hair', '#F4F4FA', '#A8A8BC')
            + grad('cloak', '#7A4AC0', '#2A1250') + grad('gold', '#FFE07A', '#B0801A'))
    body = (
        # Silver hair falling behind the shoulders.
        f'<path d="M30 44 Q28 22 50 20 Q72 22 70 44 Q74 64 68 78 L32 78 Q26 64 30 44 Z" fill="url(#hair)" '
        f'stroke="{INK}" stroke-width="1.4"/>'
        # A violet cloak with a high collar and the Guild's gold clasp.
        f'<path d="M12 100 Q14 72 34 64 L66 64 Q86 72 88 100 Z" fill="url(#cloak)" stroke="{INK}" stroke-width="1.6"/>'
        f'<path d="M30 70 Q34 60 40 58 L50 70 L60 58 Q66 60 70 70 L60 76 L50 72 L40 76 Z" fill="#5A2E96" '
        f'stroke="{INK}" stroke-width="1.3"/>'
        f'<circle cx="50" cy="74" r="5" fill="url(#gold)" stroke="{INK}" stroke-width="1.3"/>'
        f'<path d="M50 70.5 L52 74 L50 77.5 L48 74 Z" fill="#7A4AC0"/>'
        + face(50, 45, 13, 17)
        + eyes(50, 44, 5.5)
        + f'<path d="M42 39 Q45 37 48 39 M52 39 Q55 37 58 39" fill="none" stroke="#9A9AB0" stroke-width="1.4" '
        'stroke-linecap="round"/>'
        + nose(50, 50)
        + f'<path d="M46 56 Q50 58 54 56" fill="none" stroke="{INK}" stroke-width="1.2" stroke-linecap="round"/>'
        # The hair parted at the brow, and a thin gold circlet.
        + f'<path d="M37 42 Q38 28 50 27 Q62 28 63 42 Q58 32 50 32 Q42 32 37 42 Z" fill="url(#hair)" stroke="{INK}" '
        'stroke-width="1.1"/>'
        f'<path d="M36 34 Q50 27 64 34" fill="none" stroke="url(#gold)" stroke-width="2"/>'
        f'<circle cx="50" cy="30" r="1.8" fill="#9AE0FF" stroke="{INK}" stroke-width="0.6"/>'
    )
    return defs, body


def lore_page():
    """A torn page of parchment with lines of ink and a red wax seal: the picture of a found lore page."""
    defs = grad('parchment', '#F8EBC8', '#C9A86A') + grad('wax', '#E04A3A', '#7A1210')
    lines = ''.join(f'<path d="M{30 + (i % 2) * 2} {30 + i * 8} H{68 - (i % 3) * 4}" stroke="#5A3A1C" '
                    'stroke-width="1.6" stroke-linecap="round" opacity="0.75"/>' for i in range(6))
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100">'
            f'<defs>{defs}</defs>'
            '<ellipse cx="52" cy="92" rx="30" ry="4.5" fill="#000000" opacity="0.28"/>'
            f'<path d="M22 14 L76 10 L80 30 L76 50 L82 70 L74 88 L26 90 L20 72 L24 52 L18 32 Z" '
            f'fill="url(#parchment)" stroke="{INK}" stroke-width="2" stroke-linejoin="round" '
            'transform="rotate(-4 50 50)"/>'
            '<path d="M26 18 L72 14" stroke="#FFFFFF" stroke-width="1.6" opacity="0.6" stroke-linecap="round"/>'
            f'<g transform="rotate(-4 50 50)">{lines}</g>'
            f'<circle cx="66" cy="76" r="9" fill="url(#wax)" stroke="{INK}" stroke-width="1.6"/>'
            '<path d="M62 72 Q66 68 70 72" fill="none" stroke="#FFB0A0" stroke-width="1.2" opacity="0.8"/>'
            f'<path d="M63 78 L66 73 L69 78 Z" fill="none" stroke="{INK}" stroke-width="1"/>'
            '</svg>')


def portrait(draw):
    defs, body = draw()
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100">'
            f'<defs>{defs}</defs>{frame(body)}</svg>')


def write(folder, name, svg):
    out = os.path.join(HERE, folder)
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, f'{name}.svg'), 'w', encoding='utf-8', newline='\n') as f:
        f.write(svg)


def main():
    for name, draw in (('odda', odda), ('pell', pell), ('aldous', aldous), ('jory', jory), ('hilde', hilde),
                       ('bram', bram), ('wen', wen), ('sigrun', sigrun), ('garrow', garrow), ('marta', marta),
                       ('ysolde', ysolde)):
        write('portraits', name, portrait(draw))
    write('pictures', 'lore_page', lore_page())
    print('portraits and the lore page written to art/portraits and art/pictures')


if __name__ == '__main__':
    main()
