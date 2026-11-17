# Draws the portraits of the people of the story (spec 0023 §3.5) to art/portraits/<id>.svg, and the picture of a
# found lore page to art/pictures/lore_page.svg. Claude draws them until nabriis draws the real art (art/README.md).
# The style of art/README.md: rich, warm colour, light from the top left, a thin dark-brown outline. Each portrait is a
# bust on a round backdrop of its own colour, so the four people differ at a glance by colour and by silhouette:
#   Odda:   auburn hair in a bun, a quill, the teal coat of the Guild, a warm amber backdrop;
#   Pell:   bald, a big white beard, soot on the cheeks, a leather apron, an ember-orange backdrop;
#   Aldous: a dark hood, a pale long face, a lantern glow, a cold blue-grey backdrop;
#   Jory:   a wide black hat, a red scarf, a gold earring, a sly look, a deep sea-green backdrop.
# Run: python art/people.py. Then .\scripts\export-art.ps1 -Only odda,pell,aldous,jory,lore_page.
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
    for name, draw in (('odda', odda), ('pell', pell), ('aldous', aldous), ('jory', jory)):
        write('portraits', name, portrait(draw))
    write('pictures', 'lore_page', lore_page())
    print('portraits and the lore page written to art/portraits and art/pictures')


if __name__ == '__main__':
    main()
