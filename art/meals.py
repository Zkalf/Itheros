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


# The meals from Cooking 10 up. Each one shows its fish or meat in the colours of art/fish.py and art/hunt.py.

def glow_def(colour):
    return (f'<radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="{colour}" stop-opacity="0.45"/>'
            f'<stop offset="1" stop-color="{colour}" stop-opacity="0"/></radialGradient>')


GLOW = '<ellipse cx="24" cy="26" rx="23" ry="17" fill="url(#glow)"/>'


def lemon(x, y):
    return (f'<circle cx="{x}" cy="{y}" r="2.6" fill="#F2D45A" stroke="{INK}" stroke-width="0.8"/>'
            f'<path d="M{x - 1.8} {y} L{x + 1.8} {y} M{x} {y - 1.8} L{x} {y + 1.8}" stroke="#E0B030" stroke-width="0.5"/>')


def smoke(x, y):
    # Grey smoke for the smoked fish, in place of white steam.
    return ''.join(f'<path d="M{x + dx} {y} C{x + dx - 3} {y - 3}, {x + dx + 3} {y - 5}, {x + dx} {y - 8}" fill="none" stroke="#9AA0A4" '
                   f'stroke-width="1.8" stroke-linecap="round" opacity="0.6"/>' for dx in (0, 6))


def smoked_trout():
    # A whole brown trout, smoked golden brown, on a board, with grey smoke.
    body = (f'<rect x="4" y="26" width="40" height="11" rx="2.4" fill="#5A3416" stroke="{INK}" stroke-width="1.2"/>'
            '<path d="M6 35 L42 35" stroke="#8A5428" stroke-width="0.8" opacity="0.8"/>'
            + fish_on(8, 29.4, 24, '#9A5418', '#F6D088', '#4A2008') +
            ''.join(f'<circle cx="{x}" cy="{y}" r="0.7" fill="#3A2412"/>' for x, y in ((16, 27), (21, 26.4), (26, 27.2), (19, 31))) + smoke(18, 20))
    return svg(fish_defs('#B0601A', '#FFE0A0'), body)


def pie(dish, x0, x1, top):
    # A pie in a dish, a golden crust seen from a little above.
    defs = ('<radialGradient id="crust" cx="0.4" cy="0.35" r="0.75"><stop offset="0" stop-color="#FFE0A0"/>'
            '<stop offset="0.6" stop-color="#E0A04A"/><stop offset="1" stop-color="#9A5A1A"/></radialGradient>')
    w = (x1 - x0) / 2
    cx = (x0 + x1) / 2
    body = (f'<path d="M{x0} 27 L{x0 + 1.4} 33.6 C{x0 + 4} 40.4, {x1 - 4} 40.4, {x1 - 1.4} 33.6 L{x1} 27 Z" fill="{dish}" stroke="{INK}" stroke-width="1.2" stroke-linejoin="round"/>'
            f'<path d="M{x0 + 2.6} 34.6 C{x0 + 6} 38.4, {cx - 4} 39.4, {cx} 39.4" fill="none" stroke="#C8946A" stroke-width="0.9" stroke-linecap="round" opacity="0.7"/>'
            f'<ellipse cx="{cx}" cy="27" rx="{w}" ry="8" fill="url(#crust)" stroke="{INK}" stroke-width="1.3"/>'
            f'<ellipse cx="{cx}" cy="27" rx="{w - 2.4}" ry="5.8" fill="none" stroke="#B87430" stroke-width="0.8" stroke-dasharray="2 1.4"/>'
            + top + steam(cx - 3, 17))
    return defs, body


def eel_pie():
    # An oval pie with the eel's head looking out of the crust at one end and its tail at the other.
    top = (f'<path d="M9 25 C5 22, 3.6 16.6, 6 13 C8.6 11.4, 12 12.6, 13.4 15.6 C14.4 18, 14.4 21, 14 24 Z" fill="#4E5A2C" stroke="{INK}" stroke-width="1.2" stroke-linejoin="round"/>'
           '<path d="M5 14.6 C6.4 13.6, 8 13.4, 9.6 14" fill="none" stroke="#8E9A5A" stroke-width="0.8" stroke-linecap="round"/>'
           f'<circle cx="8.4" cy="16.4" r="1.5" fill="#FFF4C0" stroke="{INK}" stroke-width="0.5"/><circle cx="8.6" cy="16.4" r="0.7" fill="#1A1A0A"/>'
           '<path d="M5.6 19.4 C7 20.4, 8.6 20.6, 10 20" fill="none" stroke="#1A1A0A" stroke-width="0.7" stroke-linecap="round"/>'
           f'<path d="M37 24.6 C39 21.6, 41.4 20.6, 43.4 21.4 C42 23, 41 25, 40.6 27.4 Z" fill="#4E5A2C" stroke="{INK}" stroke-width="1.1" stroke-linejoin="round"/>'
           '<path d="M17 25 L21 29 M22 23.6 L26 27.6 M27 23.6 L31 27.6" stroke="#9A5A1A" stroke-width="1" stroke-linecap="round"/>')
    defs, body = pie('#8A5A3A', 5, 43, top)
    return svg(defs, body)


def grouse_pie():
    # A round pie with a lattice crust, two drumsticks of grouse standing out of it.
    lattice = ''.join(f'<path d="M{x} 21 L{x + 6} 33" stroke="#B87430" stroke-width="1.1" stroke-linecap="round"/>'
                      f'<path d="M{x + 6} 21 L{x} 33" stroke="#B87430" stroke-width="1.1" stroke-linecap="round"/>' for x in (14, 21, 28))
    legs = ''.join(f'<path d="M{x} 25 C{x - 1} 20, {x + dx} 15, {x + dx * 1.6} 11.6" fill="none" stroke="{INK}" stroke-width="4.4" stroke-linecap="round"/>'
                   f'<path d="M{x} 25 C{x - 1} 20, {x + dx} 15, {x + dx * 1.6} 11.6" fill="none" stroke="#D89A5E" stroke-width="2.8" stroke-linecap="round"/>'
                   f'<circle cx="{x + dx * 1.6}" cy="11" r="1.6" fill="#F4ECDA" stroke="{INK}" stroke-width="0.7"/>' for x, dx in ((20, -2.4), (28, 2.4)))
    defs, body = pie('#8A5A3A', 8, 40, lattice + legs)
    return svg(defs, body)


def planked_salmon():
    # A salmon fillet, pink-orange with pale lines, grilled on a cedar plank, a slice of lemon.
    body = (f'<path d="M3 30 L41 18 L45 23 L7 36 Z" fill="url(#wood)" stroke="{INK}" stroke-width="1.2" stroke-linejoin="round"/>'
            '<path d="M5 31.6 L42 20" stroke="#E0A060" stroke-width="0.8" opacity="0.6"/>'
            f'<path d="M9 30 C11 25, 30 19, 37 20 C39.6 21.6, 39 24.6, 36 26 C28 29, 16 33, 11 33 C9 32.6, 8.6 31.4, 9 30 Z" '
            f'fill="url(#salmon)" stroke="{INK}" stroke-width="1.2"/>'
            + ''.join(f'<path d="M{x} {y} c1.4 -1.4, 1.8 -3, 1.4 -4.4" fill="none" stroke="#FFE0CC" stroke-width="0.8" stroke-linecap="round" opacity="0.85"/>'
                      for x, y in ((14, 31), (19, 29.4), (24, 27.6), (29, 25.8), (33, 24.2)))
            + '<path d="M12 28.6 C18 25, 28 21.6, 34 21" fill="none" stroke="#FFFFFF" stroke-width="0.8" stroke-linecap="round" opacity="0.6"/>'
            + lemon(39, 28) + herbs(16, 35) + steam(20, 16))
    defs = ('<linearGradient id="salmon" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFB08A"/>'
            '<stop offset="1" stop-color="#E0603A"/></linearGradient>')
    return svg(defs, body)


def roast(meat, bone=False):
    # A roast on a plate, its cut end showing; tied with twine, or a haunch with the bone out.
    m = meat
    defs = (f'<radialGradient id="roast" cx="0.4" cy="0.3" r="0.75"><stop offset="0" stop-color="{m[0]}"/>'
            f'<stop offset="0.6" stop-color="{m[1]}"/><stop offset="1" stop-color="{m[2]}"/></radialGradient>')
    if bone:
        body = (plate() +
                f'<path d="M30 22 L38 13" stroke="{INK}" stroke-width="5" stroke-linecap="round"/>'
                '<path d="M30 22 L38 13" stroke="#F4ECDA" stroke-width="3" stroke-linecap="round"/>'
                f'<circle cx="38.6" cy="11.4" r="2.1" fill="#F4ECDA" stroke="{INK}" stroke-width="0.9"/>'
                f'<circle cx="40.4" cy="13.6" r="2.1" fill="#F4ECDA" stroke="{INK}" stroke-width="0.9"/>'
                f'<path d="M32 21 C35 25, 33 31, 26 34 C19 36.6, 10 35, 9 30 C8 25, 14 21, 20 19.6 C25 18.4, 29.6 18.6, 32 21 Z" '
                f'fill="url(#roast)" stroke="{INK}" stroke-width="1.3"/>'
                '<path d="M12 25 C15 21.6, 21 20, 27 20" fill="none" stroke="#FFFFFF" stroke-width="0.9" stroke-linecap="round" opacity="0.6"/>'
                + herbs(36, 33) + steam(17, 16))
    else:
        ties = ''.join(f'<path d="M{x} 18.6 C{x + 1.6} 24, {x + 1.6} 30, {x} 34.6" fill="none" stroke="#E8D2A0" stroke-width="1.4"/>' for x in (15, 21.6, 28.2))
        body = (plate() +
                f'<path d="M8 26 C8 20, 16 17.6, 24 17.6 C31 17.6, 36 20, 36 26 C36 32, 30 35.4, 22 35.4 C14 35.4, 8 32, 8 26 Z" fill="url(#roast)" stroke="{INK}" stroke-width="1.3"/>'
                f'<ellipse cx="34.4" cy="26.4" rx="3.2" ry="8.2" fill="{m[3]}" stroke="{INK}" stroke-width="1"/>'
                f'<ellipse cx="34.4" cy="26.4" rx="1.6" ry="4.2" fill="none" stroke="#F4E2CC" stroke-width="0.7" opacity="0.8"/>'
                + ties + '<path d="M11 22 C14 19.4, 20 18.4, 26 18.6" fill="none" stroke="#FFFFFF" stroke-width="0.9" stroke-linecap="round" opacity="0.6"/>'
                + herbs(40, 33) + steam(17, 14))
    return svg(defs, body)


def black_boar_stew():
    defs, body = bowl(['#7A4020', '#2E140A'],
                      '<rect x="14.6" y="21" width="4.4" height="3.6" rx="1" fill="#4A2014" stroke="#24140A" stroke-width="0.6"/>'
                      '<path d="M14.6 21.4 L19 21.4" stroke="#1A1410" stroke-width="1.2"/>'
                      '<rect x="25" y="22.4" width="4.6" height="3.6" rx="1" fill="#4A2014" stroke="#24140A" stroke-width="0.6"/>'
                      '<path d="M25 22.8 L29.6 22.8" stroke="#1A1410" stroke-width="1.2"/>'
                      '<circle cx="21.6" cy="25.6" r="1.3" fill="#D8C068" stroke="#24140A" stroke-width="0.5"/>'
                      '<circle cx="31.8" cy="24.2" r="1.2" fill="#E8862A" stroke="#24140A" stroke-width="0.5"/>'
                      '<circle cx="18.4" cy="25.8" r="0.9" fill="#5A7E2A"/><circle cx="28.4" cy="21.4" r="0.9" fill="#5A7E2A"/>')
    return svg(defs, body)


def char_soup():
    defs, body = bowl(['#F6A86A', '#C0582A'],
                      '<path d="M15 22.6 C17 21, 21 21, 23 22.8 C21 24.6, 17 24.6, 15 22.6 Z" fill="#F8C8A0" stroke="#24140A" stroke-width="0.6"/>'
                      '<path d="M25 24 C27 22.4, 31 22.4, 33 24.2 C31 26, 27 26, 25 24 Z" fill="#F8C8A0" stroke="#24140A" stroke-width="0.6"/>'
                      '<circle cx="21" cy="26" r="0.9" fill="#7FA34A"/><circle cx="30" cy="21.6" r="0.9" fill="#7FA34A"/>'
                      '<circle cx="13.4" cy="24.6" r="0.8" fill="#FFF4D0"/><circle cx="34.6" cy="22.6" r="0.8" fill="#FFF4D0"/>')
    return svg(defs, body)


def moonfish_broth():
    # A pale broth with a moon of fish in it, a soft pale glow and a sparkle.
    defs, body = bowl(['#F4ECF2', '#B8A4C0'],
                      '<circle cx="24" cy="24.2" r="3.4" fill="#FFF8F0" stroke="#24140A" stroke-width="0.7"/>'
                      '<circle cx="25.2" cy="23.4" r="2.8" fill="#D8C4D2"/>'
                      '<circle cx="15" cy="24" r="0.9" fill="#D04A3A"/><circle cx="33" cy="24.4" r="0.9" fill="#D04A3A"/>'
                      '<circle cx="19" cy="26" r="0.7" fill="#FFFFFF"/><circle cx="30" cy="22" r="0.7" fill="#FFFFFF"/>',
                      spark(37, 13, 1))
    return svg(defs + glow_def('#E8D8FF'), GLOW + body)


def baked_fish(back, belly, marks, dish, extra=''):
    # A whole fish baked in an oval dish, with lemon and herbs.
    body = (f'<ellipse cx="24" cy="31" rx="21" ry="8.6" fill="{dish}" stroke="{INK}" stroke-width="1.3"/>'
            f'<ellipse cx="24" cy="30" rx="18" ry="6.4" fill="#5A3A1E" stroke="{INK}" stroke-width="0.8"/>'
            + fish_on(8, 29.6, 24, back, belly, marks) + extra + lemon(37, 34) + herbs(12, 35) + steam(19, 20))
    return svg(fish_defs(back, belly), body)


def baked_sea_bass():
    return baked_fish('#5A6670', '#EEF0EC', '#3A2A1A', '#C8B89A')


def glacier_pike_roast():
    return baked_fish('#4A6A80', '#EEF4F4', '#2A3A44', '#A8C8D8',
                      ''.join(f'<circle cx="{x}" cy="{y}" r="0.6" fill="#F2FAFF"/>' for x, y in ((14, 27), (20, 26.6), (26, 27))))


def salted_mackerel():
    # A mackerel on a plate, its wavy dark stripes on the back, salt crystals around it.
    waves = ''.join(f'<path d="M{x} 25.6 c1 1.4, 2 -1.4, 3 0" fill="none" stroke="#10303A" stroke-width="0.9" stroke-linecap="round"/>'
                    for x in (13, 17, 21, 25))
    salt = ''.join(f'<rect x="{x}" y="{y}" width="1.3" height="1.3" fill="#FFFFFF" stroke="#A8B4BA" stroke-width="0.3" transform="rotate(20 {x} {y})"/>'
                   for x, y in ((8, 34), (11, 36), (34, 35), (38, 33), (30, 37), (16, 37.4), (40, 30), (6, 30)))
    body = plate() + fish_on(9, 29, 22, '#1E5A6A', '#F2F4EE', '#2A1A0A') + waves + salt
    return svg(fish_defs('#2E7080', '#F2F4EE'), body)


def frostfin_fillet():
    # Two fillets with icy blue skin on a plate, a frosty sparkle.
    body = plate()
    for x, y in ((10, 28), (20, 31)):
        body += (f'<path d="M{x} {y} C{x + 4} {y - 5}, {x + 14} {y - 5}, {x + 18} {y - 1} C{x + 14} {y + 3}, {x + 4} {y + 3}, {x} {y} Z" '
                 f'fill="#FBEFE6" stroke="{INK}" stroke-width="1.1"/>'
                 f'<path d="M{x + 1} {y - 0.6} C{x + 5} {y - 4.6}, {x + 13} {y - 4.6}, {x + 17} {y - 1.4}" fill="none" stroke="#7EB0D0" stroke-width="1.8" stroke-linecap="round"/>'
                 + ''.join(f'<path d="M{x + dx} {y + 1.6} l1.2 -3" stroke="#E8C8B4" stroke-width="0.6"/>' for dx in (5, 9, 13)))
    body += herbs(38, 34) + spark(37, 15, 1) + spark(11, 18, 0.7)
    return svg('', body)


def ibex_haunch():
    return roast(['#C86A3E', '#8A3A1C', '#4A1A0A', '#E89A78'], bone=True)


def elk_roast():
    return roast(['#B85A34', '#7A2A16', '#3E1008', '#D8786A'])


def feast(back, belly, glow, fin, extra=''):
    # A feast for a rare catch: its big fish on a platter with roast meat and greens, a glow and a sparkle.
    body = (GLOW + plate() + fish_on(6, 28.5, 26, back, belly, '#2A1A08') +
            f'<path d="M14 23.8 L17 19.6 L20 23.2 L23 19 L26 23" fill="{fin}" stroke="{INK}" stroke-width="0.8" stroke-linejoin="round"/>'
            '<rect x="31" y="32.6" width="5.4" height="4.2" rx="1.2" fill="#8A3A1C" stroke="#24140A" stroke-width="0.7"/>'
            + herbs(9, 34.6) + herbs(40, 35) +
            '<circle cx="14.4" cy="35" r="1.5" fill="#C0392B" stroke="#24140A" stroke-width="0.5"/>' + extra
            + steam(18, 19) + spark(40, 12, 1.1))
    return svg(fish_defs(back, belly) + glow_def(glow), body)


def river_king_feast():
    return feast('#3A4046', '#D8D6C4', '#FFD86A', '#C9A13A')


def one_eye_feast():
    # Old One-Eye: a pale scar across the eye.
    return feast('#33393E', '#C8C4B4', '#E8C080', '#4E5458',
                 '<path d="M7.4 25.6 L11.6 30.6 M11.6 25.6 L7.4 30.6" stroke="#E8DCC8" stroke-width="1.2" stroke-linecap="round"/>')


def pale_one_feast():
    return feast('#B8C4C4', '#FBFDFC', '#A8F0FF', '#C8D8DA')


ITEMS = dict(grilled_perch=grilled_perch, pike_steak=pike_steak, venison_skewer=venison_skewer, boar_stew=boar_stew,
             golden_carp_curry=golden_carp_curry, mossback_feast=mossback_feast,
             smoked_trout=smoked_trout, eel_pie=eel_pie, planked_salmon=planked_salmon, elk_roast=elk_roast,
             black_boar_stew=black_boar_stew, river_king_feast=river_king_feast, baked_sea_bass=baked_sea_bass,
             salted_mackerel=salted_mackerel, moonfish_broth=moonfish_broth, one_eye_feast=one_eye_feast,
             char_soup=char_soup, frostfin_fillet=frostfin_fillet, glacier_pike_roast=glacier_pike_roast,
             ibex_haunch=ibex_haunch, grouse_pie=grouse_pie, pale_one_feast=pale_one_feast)

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
