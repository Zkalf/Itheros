# Draws the meat, the hides and the scales as SVG (art/items/<id>.svg), in the style of art/README.md (#198).
# Each item has its own shape: a haunch, a chop, a tied roast, a rack of ribs, a plucked bird; a rolled hide with a
# strap (like the wolf pelt); one big fish scale with a pearly sheen.
# Run: python art/hunt.py [--preview]. Then .\scripts\export-art.ps1 makes the webp files.
import os
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'items')
REPO = os.path.dirname(HERE)
INK = '#24140A'

# meat: light, mid, dark of the cut; the fat; a rind (or None)
MEAT = {
    'venison':         dict(m=['#D8605A', '#9E2A26', '#5A1210'], fat='#F4E2CC', rind=None),
    'boar_meat':       dict(m=['#F08A80', '#C24A44', '#7A2420'], fat='#FFF0DE', rind=None),
    'elk_meat':        dict(m=['#C64A40', '#86201C', '#4A0E0C'], fat='#EEDCC2', rind=None),
    'black_boar_meat': dict(m=['#E07870', '#A8343A', '#621418'], fat='#FBEBD8', rind='#2A2420'),
    'ibex_meat':       dict(m=['#CC5C4C', '#8E2E22', '#4E140C'], fat='#F0E0C6', rind=None),
}
# hides: light, mid, dark of the fur; the spots (or None)
HIDES = {
    'deer_hide': dict(f=['#D9A266', '#A8682E', '#5E3410'], spots='#F4E2C2'),
    'elk_hide':  dict(f=['#9E6E40', '#6A421E', '#36200C'], spots=None),
    'ibex_hide': dict(f=['#CDBFA6', '#8E7E66', '#4E4232'], spots=None),
    # a rare find: pale winter fur with dark spots, a glow and a sparkle
    'snow_lynx_pelt': dict(f=['#F4E8D2', '#BFA888', '#6E5A42'], spots='#3A2C20', glow='#CFEFFF'),
}
# scales: centre, middle, edge; the sheen
SCALES = {
    'lake_scale':  dict(s=['#F2FAE6', '#A8C894', '#5E7E52'], sheen='#E6FFD8'),
    'river_scale': dict(s=['#EEF6FF', '#9EB8D6', '#4E6A8E'], sheen='#D8ECFF'),
    'tarn_scale':  dict(s=['#FFFFFF', '#C6ECF6', '#6EA6BE'], sheen='#E8FCFF'),
}

SHADOW = ('<radialGradient id="shadow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#000" stop-opacity="0.65"/>'
          '<stop offset="1" stop-color="#000" stop-opacity="0"/></radialGradient>')
FUR = ('<filter id="fur" x="-10%" y="-10%" width="120%" height="120%">'
       '<feTurbulence type="fractalNoise" baseFrequency="0.9 0.25" numOctaves="2" seed="3" result="n"/>'
       '<feColorMatrix in="n" type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  1.2 0 0 0 -0.45" result="d"/>'
       '<feComposite in="d" in2="SourceAlpha" operator="in" result="d2"/>'
       '<feMerge><feMergeNode in="SourceGraphic"/><feMergeNode in="d2"/></feMerge></filter>')
BONE = ('<linearGradient id="bone" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFF8E8"/>'
        '<stop offset="1" stop-color="#C9B896"/></linearGradient>')


def svg(defs, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="48" height="48"><defs>{SHADOW}{FUR}{BONE}{defs}</defs>'
            f'<ellipse cx="24" cy="41" rx="19" ry="4.6" fill="url(#shadow)"/>{body}</svg>')


def lit(d):
    return f'<path d="{d}" fill="none" stroke="#FFFFFF" stroke-width="1" stroke-linecap="round" opacity="0.65"/>'


def marble(d, fat):
    return f'<path d="{d}" fill="none" stroke="{fat}" stroke-width="0.8" stroke-linecap="round" opacity="0.7"/>'


def bone(x0, y0, x1, y1, w=3.2):
    return (f'<path d="M{x0} {y0} L{x1} {y1}" stroke="{INK}" stroke-width="{w + 2}" stroke-linecap="round"/>'
            f'<path d="M{x0} {y0} L{x1} {y1}" stroke="url(#bone)" stroke-width="{w}" stroke-linecap="round"/>')


def meat(item):
    p = MEAT[item]
    m, fat = p['m'], p['fat']
    defs = (f'<radialGradient id="meat" cx="0.38" cy="0.32" r="0.75"><stop offset="0" stop-color="{m[0]}"/>'
            f'<stop offset="0.55" stop-color="{m[1]}"/><stop offset="1" stop-color="{m[2]}"/></radialGradient>')
    if item == 'venison':
        # A haunch: a big leg, the bone knuckle out of the narrow end.
        body = (bone(30, 14, 37, 7.5) +
                f'<circle cx="38.6" cy="5.6" r="2.3" fill="url(#bone)" stroke="{INK}" stroke-width="1"/>'
                f'<circle cx="39.8" cy="8.4" r="2.3" fill="url(#bone)" stroke="{INK}" stroke-width="1"/>'
                f'<path d="M31.5 13 C35 18, 34 27, 28 33.5 C22 39.5, 11 40, 7.5 34 C4.5 28.5, 9 21, 16 17 C21 14, 27 11, 31.5 13 Z" '
                f'fill="url(#meat)" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round"/>'
                + marble('M12 30 C16 27, 20 29, 24 25 M15 35 C20 33, 24 34, 28 29', fat)
                + lit('M14 20 C19 16.5, 25 14.2, 29.5 14.5'))
    elif item in ('boar_meat', 'black_boar_meat'):
        # A thick chop: the eye of the meat, a rim of fat, a bone along one side.
        body = (f'<path d="M8 22 C8 12, 24 7.5, 35 11 C43 13.5, 44 23, 39 30 C34 37, 20 40, 12 35.5 C9 33.5, 8 28, 8 22 Z" '
                f'fill="{fat}" stroke="{INK}" stroke-width="1.3"/>'
                f'<path d="M12 22 C12 15, 24 11.5, 33 14 C39.5 16, 40 23.5, 36 29 C32 34.5, 21 36.5, 15 33 C12.5 31.5, 12 27, 12 22 Z" '
                f'fill="url(#meat)" stroke="{INK}" stroke-width="0.9"/>'
                f'<path d="M9.5 28 C12 36, 22 39.5, 31 36" fill="none" stroke="{INK}" stroke-width="5.4" stroke-linecap="round"/>'
                f'<path d="M9.5 28 C12 36, 22 39.5, 31 36" fill="none" stroke="url(#bone)" stroke-width="3.4" stroke-linecap="round"/>'
                + marble('M17 20 C21 18, 25 21, 30 19 M16 26 C21 24.5, 26 27, 32 25', fat)
                + lit('M12 16 C18 10.5, 28 9.4, 35 11.6'))
        if p['rind']:
            # The black boar keeps its bristly rind.
            body += (f'<path d="M8.6 20 C9.5 11, 24 6.6, 35.5 10.2 C42 12.4, 44.2 19, 42.6 25" fill="none" '
                     f'stroke="{p["rind"]}" stroke-width="2.8" stroke-linecap="round"/>')
            body += ''.join(f'<path d="M{x} {y} l{dx} {dy}" stroke="{p["rind"]}" stroke-width="0.9" stroke-linecap="round"/>'
                            for x, y, dx, dy in [(12, 13.5, -1.2, -2), (17, 10, -0.6, -2.2), (23, 8.4, 0, -2.3), (29, 8.6, 0.6, -2.2),
                                                 (35, 10, 1.2, -2), (40, 13.2, 1.8, -1.6), (43, 19, 2.2, -0.8)])
    elif item == 'elk_meat':
        # A big roast, tied with twine, its cut end to the right.
        ties = ''.join(f'<path d="M{x} {y0} C{x + 2} {y0 + 9}, {x + 2} {y1 - 9}, {x} {y1}" fill="none" stroke="#E8D2A0" stroke-width="1.5"/>'
                       for x, y0, y1 in [(15, 11.5, 34.5), (23, 9.6, 36.4), (31, 9.8, 35.8)])
        body = (f'<path d="M7 21 C7 13, 18 9, 28 9.5 C38 10, 43 15, 43 22 C43 30, 36 36, 25 36.5 C14 37, 7 30, 7 21 Z" '
                f'fill="url(#meat)" stroke="{INK}" stroke-width="1.3"/>'
                f'<ellipse cx="39.6" cy="22.6" rx="3.2" ry="10" fill="{m[0]}" stroke="{INK}" stroke-width="1"/>'
                f'<ellipse cx="39.6" cy="22.6" rx="1.7" ry="5.2" fill="none" stroke="{fat}" stroke-width="0.8" opacity="0.8"/>'
                + ties + lit('M10 17 C14 12, 22 10.4, 30 10.6'))
    else:
        # ibex_meat: a rack of ribs, a lean slab with four bones out of the top.
        bones = ''.join(bone(x, 21, x + 3, 8, 2.2) for x in (12, 19, 26, 33))
        body = (bones +
                f'<path d="M7 22 C14 18, 30 17, 41 20 C43.5 26, 41 33, 36 36 C27 39, 15 38.5, 9 35 C6 31, 5.5 26, 7 22 Z" '
                f'fill="url(#meat)" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round"/>'
                f'<path d="M8 22.4 C15 19, 30 18.2, 40.4 20.8" fill="none" stroke="{fat}" stroke-width="2" stroke-linecap="round"/>'
                + marble('M12 29 C17 27, 22 30, 27 28 M24 33 C28 31.5, 32 33, 36 31', fat)
                + lit('M10 24.5 C16 22, 26 21.4, 36 22.6'))
    return svg(defs, body)


def grouse():
    # A plucked bird, legs up, ready for the pot.
    defs = ('<radialGradient id="skin" cx="0.38" cy="0.32" r="0.75"><stop offset="0" stop-color="#FFE8C8"/>'
            '<stop offset="0.6" stop-color="#E4A472"/><stop offset="1" stop-color="#985A30"/></radialGradient>')

    def leg(x0, y0, cx, cy, x1, y1, x2, y2, x3, y3):
        d = f'M{x0} {y0} C{cx} {cy}, {x1} {y1}, {x2} {y2}'
        return (f'<path d="{d}" fill="none" stroke="{INK}" stroke-width="7.4" stroke-linecap="round"/>'
                f'<path d="{d}" fill="none" stroke="url(#skin)" stroke-width="5.4" stroke-linecap="round"/>'
                + bone(x2, y2, x3, y3, 1.8))
    body = (f'<path d="M6 28 C6 18, 17 12.5, 27 13 C37 13.5, 43 20, 42 28 C41 35, 33 38.5, 24 38.5 C14 38.5, 6 35, 6 28 Z" '
            f'fill="url(#skin)" stroke="{INK}" stroke-width="1.3"/>'
            + leg(22, 19, 22, 13, 26, 9, 29, 7.5, 33, 5.5)
            + leg(30, 20, 32, 14, 36, 11.5, 39, 10.5, 42.6, 9.4) +
            f'<path d="M10 28 C13 24, 20 23.5, 24 27 C20 31, 13 31.5, 10 28 Z" fill="#D2905E" stroke="{INK}" stroke-width="0.9" opacity="0.9"/>'
            f'<path d="M6.5 26 C4 25, 2.6 27, 3.6 29 C4.6 30.6, 6.4 30.4, 7 29.4" fill="url(#skin)" stroke="{INK}" stroke-width="1"/>'
            + lit('M9 22 C13 17, 20 15, 26 15.4') +
            '<g fill="#A86A40" opacity="0.55"><circle cx="16" cy="33" r="0.5"/><circle cx="20" cy="35" r="0.5"/>'
            '<circle cx="27" cy="34" r="0.5"/><circle cx="33" cy="31" r="0.5"/><circle cx="36" cy="26" r="0.5"/>'
            '<circle cx="14" cy="20" r="0.5"/></g>')
    return svg(defs, f'<g transform="translate(0 1)">{body}</g>')


def hide(item):
    p = HIDES[item]
    f = p['f']
    defs = (f'<linearGradient id="furc" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{f[0]}"/>'
            f'<stop offset="0.5" stop-color="{f[1]}"/><stop offset="1" stop-color="{f[2]}"/></linearGradient>')
    # A rolled hide, fur outside, lying on its side; the rolled end shows a spiral of pale skin; a strap.
    roll = (f'<path d="M7 20 C9 15.5, 13 14.6, 16 15 L35 14.5 C40 14.4, 43 19, 43 25 C43 31, 40 35.6, 35 35.5 L16 36 '
            f'C12 36.2, 8 33.5, 7 30 Z" fill="url(#furc)" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round" filter="url(#fur)"/>')
    tufts = ''.join(f'<path d="M{x} {y} l{dx} {dy}" stroke="{f[2]}" stroke-width="0.9" stroke-linecap="round" opacity="0.7"/>'
                    for x, y, dx, dy in [(12, 18, 1.4, -2.2), (17, 17, 1.2, -2.4), (22, 16.6, 1, -2.4), (27, 16.4, 1, -2.4),
                                         (14, 26, 1.6, -2), (20, 25, 1.6, -2), (26, 25, 1.6, -2),
                                         (13, 32, 1.6, -1.8), (19, 32.6, 1.6, -1.8), (25, 32.6, 1.6, -1.8)])
    spots = ''
    if p['spots']:
        spots = ''.join(f'<ellipse cx="{x}" cy="{y}" rx="1.3" ry="0.9" fill="{p["spots"]}" opacity="0.9"/>'
                        for x, y in ((14, 21), (26, 21), (17, 28), (27.5, 28.4), (12.5, 33)))
    spiral = 'M36 25 m-0.5 0 a1.6 2.2 0 1 1 1.6 2 a3.4 4.6 0 1 1 -3.6 -4.8 a5.2 7.4 0 1 1 5.6 7.8'
    end = (f'<ellipse cx="36" cy="25" rx="7" ry="10.6" fill="{f[1]}" stroke="{INK}" stroke-width="1.3"/>'
           f'<path d="{spiral}" fill="none" stroke="#F0D8B4" stroke-width="1.6" stroke-linecap="round"/>')
    strap = (f'<path d="M22 14.8 C20 20, 20 30, 22 35.8" fill="none" stroke="{INK}" stroke-width="4.2"/>'
             '<path d="M22 14.8 C20 20, 20 30, 22 35.8" fill="none" stroke="#7A4A26" stroke-width="2.6"/>'
             '<path d="M21.2 17 C20.4 21, 20.4 26, 20.8 30" fill="none" stroke="#C08A5A" stroke-width="0.7" opacity="0.8"/>')
    shine = lit('M11 17.4 C18 15.8, 28 15.6, 34 15.8')
    if 'glow' not in p:
        return svg(defs, f'<g transform="translate(-1 0)">{roll}{tufts}{spots}{strap}{end}{shine}</g>')
    # The lynx: many small dark spots on its pale winter fur.
    spots = ''.join(f'<ellipse cx="{x}" cy="{y}" rx="{r}" ry="{r * 0.75}" fill="{p["spots"]}" opacity="0.8"/>'
                    for x, y, r in ((11, 21, 0.9), (15.5, 18.6, 0.8), (14, 24, 1), (18.6, 22.4, 0.9), (25, 19, 0.8), (27.6, 23.4, 1),
                                    (11.4, 28, 0.9), (16, 29, 1), (25.4, 28.6, 0.9), (29.6, 31.4, 0.8), (13, 33.4, 0.8), (18.4, 33.6, 0.9),
                                    (25.6, 33.2, 0.8), (30, 18.6, 0.7)))
    return svg(defs + glow_def(p['glow']), glow(24, 25) + f'<g transform="translate(-1 0)">{roll}{tufts}{spots}{strap}{end}{shine}</g>'
               + sparkle(41, 10))


def scales(item):
    p = SCALES[item]
    s = p['s']
    # One big fish scale, a little cupped: growth lines, grooves at the root, a pearly sheen.
    defs = (f'<radialGradient id="sc" cx="0.42" cy="0.3" r="0.8"><stop offset="0" stop-color="{s[0]}"/>'
            f'<stop offset="0.5" stop-color="{s[1]}"/><stop offset="1" stop-color="{s[2]}"/></radialGradient>'
            '<linearGradient id="pearl" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFD6F0" stop-opacity="0.45"/>'
            '<stop offset="0.5" stop-color="#D6FFF4" stop-opacity="0.25"/><stop offset="1" stop-color="#C8D8FF" stop-opacity="0.45"/></linearGradient>')
    outline = 'M24 6 C34 6, 41 13, 41 22.5 C41 31, 35 37.5, 27 39.5 L24 41 L21 39.5 C13 37.5, 7 31, 7 22.5 C7 13, 14 6, 24 6 Z'
    rings = ''.join(f'<path d="M{24 - r} {22.5 + r * 0.15} C{24 - r} {22.5 - r * 1.2}, {24 + r} {22.5 - r * 1.2}, {24 + r} {22.5 + r * 0.15}" '
                    f'fill="none" stroke="{s[2]}" stroke-width="0.7" opacity="0.7"/>' for r in (5, 9, 13))
    grooves = ''.join(f'<path d="M24 39 L{x} 29" stroke="{s[2]}" stroke-width="0.8" stroke-linecap="round" opacity="0.6"/>'
                      for x in (18, 21.5, 24, 26.5, 30))
    body = (f'<path d="{outline}" fill="url(#sc)" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round"/>'
            f'<path d="{outline}" fill="url(#pearl)"/>' + rings + grooves +
            f'<path d="M12 15 C15 10, 21 8, 27 8.4" fill="none" stroke="{p["sheen"]}" stroke-width="1.6" stroke-linecap="round" opacity="0.95"/>'
            '<path d="M33.6 10.6 l0.7 -1.6 l0.7 1.6 l1.6 0.7 l-1.6 0.7 l-0.7 1.6 l-0.7 -1.6 l-1.6 -0.7 Z" fill="#FFFFFF" opacity="0.9"/>')
    return svg(defs, f'<g transform="translate(24 24) rotate(-14) scale(0.98) translate(-24 -24)">{body}</g>')


def glow_def(colour):
    return (f'<radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="{colour}" stop-opacity="0.4"/>'
            f'<stop offset="1" stop-color="{colour}" stop-opacity="0"/></radialGradient>')


def glow(x, y, r=19):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="url(#glow)"/>'


def sparkle(x, y):
    return (f'<path d="M{x} {y - 2.6} l0.8 1.8 l1.8 0.8 l-1.8 0.8 l-0.8 1.8 l-0.8 -1.8 l-1.8 -0.8 l1.8 -0.8 Z" '
            'fill="#FFFFFF" opacity="0.9"/>')


def golden_antler():
    # A rare find: a whole deer antler of gold, the burr at the bottom left, four tines, a glow and a sparkle.
    defs = ('<linearGradient id="gold" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFF0B8"/>'
            '<stop offset="0.45" stop-color="#E8A83A"/><stop offset="1" stop-color="#7A4A0A"/></linearGradient>' + glow_def('#FFE08A'))
    beam = 'M10 38 C12 30, 15 23, 22 17 C27 13, 33 10.5, 39 7'
    tines = ['M12.6 31 C9 29, 6.6 26.4, 5.6 22.4', 'M15.6 24.4 C13.6 20.4, 13.2 16.4, 14.2 12',
             'M22 17 C21.6 13, 22.4 9.4, 24.6 6', 'M30 12 C30.4 9.4, 31.6 7, 33.6 4.8']
    out = ''
    for w, col in ((7, INK), (5, 'url(#gold)')):
        out += f'<path d="{beam}" fill="none" stroke="{col}" stroke-width="{w}" stroke-linecap="round"/>'
        out += ''.join(f'<path d="{t}" fill="none" stroke="{col}" stroke-width="{w - 1}" stroke-linecap="round"/>' for t in tines)
    out += (f'<ellipse cx="10.4" cy="38.6" rx="4.4" ry="2.6" transform="rotate(-20 10.4 38.6)" fill="url(#gold)" stroke="{INK}" stroke-width="1.1"/>'
            '<path d="M9.4 34 C11.4 27, 15 21.6, 21 16.6 C25 13.4, 30 11, 34 9.4" fill="none" stroke="#FFF8DC" stroke-width="1" stroke-linecap="round" opacity="0.9"/>'
            '<path d="M14 21 L13.8 17 M21.4 13 L22.2 10" stroke="#FFF8DC" stroke-width="0.7" stroke-linecap="round" opacity="0.8"/>'
            '<path d="M14.4 30 C16 27, 18 24, 20 22" fill="none" stroke="#8A5410" stroke-width="0.7" opacity="0.6" stroke-linecap="round"/>')
    return svg(defs, glow(24, 23) + out + sparkle(41, 15) + sparkle(8, 12))


def old_tusk():
    # A rare find: the great tusk of Old Tusk, the old boar. A long ivory crescent, yellowed at the root, with
    # growth rings, cracks and a chipped tip; a glow and a sparkle.
    defs = ('<linearGradient id="ivory" x1="0" y1="1" x2="1" y2="0"><stop offset="0" stop-color="#8E6A3A"/>'
            '<stop offset="0.25" stop-color="#D8BE88"/><stop offset="0.6" stop-color="#F6EAD0"/><stop offset="1" stop-color="#FFFDF4"/></linearGradient>'
            + glow_def('#FFE8B0'))
    tusk = 'M6 33 C8 20, 20 9, 41 6 C38.6 7.6, 39.4 8.4, 37.6 9.6 C27 14, 19 23, 16.4 37.6 C13 39.6, 7.6 38.4, 6 33 Z'
    rings = ''.join(f'<path d="{d}" fill="none" stroke="#6A4A22" stroke-width="0.8" opacity="0.7" stroke-linecap="round"/>'
                    for d in ('M7.2 29.6 C10 31, 14 31.6, 17.2 31.4', 'M8.4 25.6 C11 27.2, 15 28, 18.4 27.8'))
    body = (f'<path d="{tusk}" fill="url(#ivory)" stroke="{INK}" stroke-width="1.4" stroke-linejoin="round"/>' + rings +
            '<path d="M9 22 C13 14.6, 21 9.6, 33 7.6" fill="none" stroke="#FFFFFF" stroke-width="1.2" stroke-linecap="round" opacity="0.9"/>'
            '<path d="M22 19 L25.4 17.6 L26.6 19.4 M14.6 26 L17 23.6" fill="none" stroke="#7A5A30" stroke-width="0.7" stroke-linecap="round" opacity="0.8"/>'
            f'<path d="M6.2 33.4 C8.4 37.6, 13 38.8, 16.4 37.6" fill="none" stroke="{INK}" stroke-width="0.9" opacity="0.6"/>')
    return svg(defs, glow(24, 23) + f'<g transform="translate(0.5 1)">{body}</g>' + sparkle(40, 15) + sparkle(9, 13))


ITEMS = {**{k: (lambda k=k: meat(k)) for k in MEAT}, 'grouse': grouse,
         **{k: (lambda k=k: hide(k)) for k in HIDES}, **{k: (lambda k=k: scales(k)) for k in SCALES},
         'golden_antler': golden_antler, 'old_tusks_tusk': old_tusk}

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
    nab = ''.join(cell.format(src=url(os.path.join(REPO, 'app', 'assets', 'images', 'items', i + '.webp')), cap=i)
                  for i in ['wolf_pelt', 'goblin_hide', 'troll_hide', 'dragon_scale', 'wyvern_scale', 'perch'])
    big = ''.join(f'<div class="sock bigs"><img src="{url(os.path.join(OUT, i + ".svg"))}"></div>' for i in ITEMS)
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
.bigrow {{ display:grid; grid-template-columns: repeat(6, 92px); gap:6px; }}
.bigs {{ width:84px; height:84px; border-radius:18px; }}
.bigs img {{ width:72px; height:72px; }}
</style></head><body>
<div class="plate"><h2>Meat, hides and scales at bag size</h2><div class="grid">{mine}</div>
<h2>Already in the game</h2><div class="grid">{nab}</div></div>
<div class="plate"><h2>Larger</h2><div class="bigrow">{big}</div></div>
</body></html>'''
    preview = os.path.join(tempfile.gettempdir(), 'itheros-hunt-preview.html')
    with open(preview, 'w', encoding='utf-8') as fh:
        fh.write(html)
    print(f'Preview: {preview}')
