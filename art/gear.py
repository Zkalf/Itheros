# Draws gear as SVG (art/items/<id>.svg), in the style of art/README.md (#198). Weapons lie on the diagonal, handle
# bottom left, like the tools and nabriis's copper sword.
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


def svg(body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="48" height="48"><defs>{DEFS}</defs>'
            f'<ellipse cx="24" cy="41.5" rx="19" ry="4.6" fill="url(#shadow)"/>{body}</svg>')


def diag(inner):
    # Upright drawing (point up) turned onto the diagonal.
    return f'<g transform="translate(24 24) rotate(45) scale(1.12) translate(-24 -24.6)">{inner}</g>'


def shaft(y0, y1, w=3.4):
    return (f'<rect x="{24 - w / 2}" y="{y0}" width="{w}" height="{y1 - y0}" rx="{w / 2}" fill="url(#wood)" stroke="{INK}" stroke-width="1.2"/>'
            f'<path d="M{24 - w / 2 + 0.9} {y0 + 3} L{24 - w / 2 + 0.9} {y1 - 2}" stroke="#FFE0B0" stroke-width="0.7" stroke-linecap="round" opacity="0.6"/>')


def bands(ys, fill='url(#wrap)', w=4.6):
    return ''.join(f'<rect x="{24 - w / 2}" y="{y}" width="{w}" height="2.4" rx="0.8" fill="{fill}" stroke="{INK}" stroke-width="0.9"/>' for y in ys)


def copper_spear():
    head = (f'<path d="M24 2 C27.5 7, 28.5 12, 26 17 L22 17 C19.5 12, 20.5 7, 24 2 Z" fill="url(#copper)" stroke="{INK}" stroke-width="1.2" stroke-linejoin="round"/>'
            '<path d="M24 3.5 L24 16" stroke="#7A3010" stroke-width="0.7" opacity="0.8"/>'
            '<path d="M22.8 6 C22 9, 21.8 12, 22.6 15" fill="none" stroke="#FFFFFF" stroke-width="0.8" stroke-linecap="round" opacity="0.8"/>')
    return svg(diag(shaft(16, 46) + bands([16.5, 19.5]) + head))


def copper_mace():
    head = (f'<path d="M24 5 L30 9 L31.5 15 L28 20 L20 20 L16.5 15 L18 9 Z" fill="url(#copper)" stroke="{INK}" stroke-width="1.2" stroke-linejoin="round"/>'
            '<path d="M24 5 L24 20 M18 9 L28 20 M30 9 L20 20" stroke="#7A3010" stroke-width="0.8" opacity="0.7"/>'
            f'<path d="M24 1.5 L26 5.5 L22 5.5 Z" fill="url(#copper)" stroke="{INK}" stroke-width="1"/>'
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


def garnet_ring():
    # A copper ring seen at an angle, a red garnet set on top.
    ring = (f'<ellipse cx="24" cy="29" rx="14" ry="9" fill="none" stroke="{INK}" stroke-width="6.6"/>'
            '<ellipse cx="24" cy="29" rx="14" ry="9" fill="none" stroke="url(#copper)" stroke-width="4.4"/>'
            '<path d="M12 26 C14 22.6, 18 21, 22 20.6" fill="none" stroke="#FFE2C0" stroke-width="1" stroke-linecap="round" opacity="0.85"/>'
            f'<path d="M18 19 L30 19 L28 23 L20 23 Z" fill="url(#copper)" stroke="{INK}" stroke-width="1.1" stroke-linejoin="round"/>'
            f'<path d="M24 6 L31 11 L28.5 19.5 L19.5 19.5 L17 11 Z" fill="url(#gem)" stroke="{INK}" stroke-width="1.2" stroke-linejoin="round"/>'
            '<path d="M17 11 L31 11 M24 6 L21 11 L24 19.5 L27 11 Z" fill="none" stroke="#5A0814" stroke-width="0.7" opacity="0.8"/>'
            '<path d="M20 9.4 L23 7.4" stroke="#FFFFFF" stroke-width="1" stroke-linecap="round" opacity="0.9"/>')
    return svg(ring)


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


def gloves():
    # One deer-hide glove, palm toward us, with stitching and a cuff.
    glove = (f'<path d="M16 42 L16 30 C13 28, 9 25.5, 9 22.5 C9 20.5, 12 20, 14.6 22 L16 23 L16 11 C16 9, 19 9, 19 11 L19.4 20 '
             f'L20 8 C20 6, 23 6, 23 8 L23.4 19.6 L24.2 8.6 C24.2 6.6, 27.2 6.6, 27.2 8.6 L27.4 20.4 L28.4 11 C28.4 9, 31.4 9, 31.4 11 '
             f'L31.6 30 C31.6 35, 30 37.5, 30 42 Z" fill="url(#leather)" stroke="{INK}" stroke-width="1.2" stroke-linejoin="round"/>'
             f'<rect x="15" y="36" width="16" height="6.6" rx="1.6" fill="#8A5428" stroke="{INK}" stroke-width="1.1"/>'
             '<path d="M16.6 39.3 L29.4 39.3" stroke="#E8C898" stroke-width="0.7" stroke-dasharray="1.4 1"/>'
             '<path d="M19 26 C21 28, 26 28, 28.6 26" fill="none" stroke="#E8C898" stroke-width="0.7" stroke-dasharray="1.4 1"/>'
             '<path d="M17.4 12 L17.6 20 M21.4 9 L21.6 18" stroke="#FFFFFF" stroke-width="0.8" stroke-linecap="round" opacity="0.55"/>'
             '<g fill="#F4E2C2" opacity="0.85"><ellipse cx="22" cy="31" rx="1" ry="0.7"/><ellipse cx="26.5" cy="32.6" rx="1" ry="0.7"/></g>')
    return svg(glove)


def bracers():
    # A leather cuff for the forearm, laced on its side.
    cuff = (f'<path d="M13 12 C19 9.6, 29 9.6, 35 12 L33 38 C27 40.4, 21 40.4, 15 38 Z" fill="url(#leather)" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round"/>'
            f'<ellipse cx="24" cy="12" rx="11" ry="2.8" fill="#6A3A16" stroke="{INK}" stroke-width="1.1"/>'
            '<path d="M14.6 16 C20 14, 28 14, 33.4 16 M15.6 34 C20.6 35.8, 27.4 35.8, 32.4 34" fill="none" stroke="#E8C898" stroke-width="0.7" stroke-dasharray="1.4 1"/>'
            + ''.join(f'<path d="M21 {y} L27 {y + 3} M27 {y} L21 {y + 3}" stroke="#3A2010" stroke-width="1" stroke-linecap="round"/>' for y in (19, 24, 29)) +
            '<path d="M16.5 15 C17 22, 17 28, 17.5 34" fill="none" stroke="#FFFFFF" stroke-width="1" stroke-linecap="round" opacity="0.55"/>'
            '<g fill="#F4E2C2" opacity="0.85"><ellipse cx="18.5" cy="22" rx="1" ry="0.7"/><ellipse cx="30" cy="26" rx="1" ry="0.7"/><ellipse cx="19.5" cy="30" rx="1" ry="0.7"/></g>')
    return svg(cuff)


def belt():
    # A coiled leather belt with a copper buckle.
    b = (f'<path d="M9 28 C9 18, 39 18, 39 28 C39 36, 9 36, 9 28 Z" fill="none" stroke="{INK}" stroke-width="7.4"/>'
         '<path d="M9 28 C9 18, 39 18, 39 28 C39 36, 9 36, 9 28 Z" fill="none" stroke="url(#leather)" stroke-width="5.4"/>'
         '<path d="M9 28 C9 18, 39 18, 39 28" fill="none" stroke="#E8C898" stroke-width="0.6" stroke-dasharray="1.4 1" opacity="0.8"/>'
         f'<path d="M16 26 C16 21, 32 21, 32 26" fill="none" stroke="{INK}" stroke-width="6.6"/>'
         '<path d="M16 26 C16 21, 32 21, 32 26" fill="none" stroke="#8A5428" stroke-width="4.6"/>'
         f'<rect x="19" y="29" width="10" height="9" rx="1.6" fill="none" stroke="{INK}" stroke-width="3.6"/>'
         '<rect x="19" y="29" width="10" height="9" rx="1.6" fill="none" stroke="url(#copper)" stroke-width="2"/>'
         f'<path d="M24 30 L24 37" stroke="{INK}" stroke-width="1.6" stroke-linecap="round"/>'
         '<path d="M14 22 C18 19.4, 26 18.6, 32 19.6" fill="none" stroke="#FFFFFF" stroke-width="0.9" stroke-linecap="round" opacity="0.5"/>')
    return svg(b)


def greaves():
    # A pair of greaves standing side by side, like a pair of boots, the front of each leg to the right: the shin
    # curve, the calf at the back, a knee plate on top. Overlapping lake scales cover them (each row lies over the
    # one below); two leather straps go round each calf. The back one stands a little higher and darker.
    shape = ('M17.5 11 C21 8.6, 26 7, 30 8.6 C33.4 16, 33.6 28, 29 37.6 L32.6 41.6 L16.4 41.6 '
             'C15.4 35, 12.4 27, 14.4 18.6 C15 15, 16 12.6, 17.5 11 Z')

    def one(cid):
        rows = ''
        for r, y in reversed(list(enumerate(range(9, 44, 4)))):
            for i in range(6):
                x = 11.6 + i * 4.6 + (2.3 if r % 2 else 0)
                rows += (f'<path d="M{x - 2.5} {y - 1} L{x + 2.5} {y - 1} L{x + 2.5} {y + 0.6} C{x + 2.5} {y + 4}, {x - 2.5} {y + 4}, {x - 2.5} {y + 0.6} Z" '
                         f'fill="url(#scale)" stroke="{INK}" stroke-width="0.7"/>')
        straps = ''.join(
            f'<path d="M14.6 {y} C19 {y + 1.4}, 24 {y + 1.6}, 27.6 {y + 0.6}" fill="none" stroke="{INK}" stroke-width="4"/>'
            f'<path d="M14.6 {y} C19 {y + 1.4}, 24 {y + 1.6}, 27.6 {y + 0.6}" fill="none" stroke="#7A4A26" stroke-width="2.4"/>'
            for y in (19, 31))
        return (f'<path d="{shape}" fill="#5E7E52"/>'
                f'<clipPath id="{cid}"><path d="{shape}"/></clipPath><g clip-path="url(#{cid})">{rows}</g>'
                f'<path d="{shape}" fill="none" stroke="{INK}" stroke-width="1.6" stroke-linejoin="round"/>' + straps +
                f'<path d="M24.6 6.6 C28.6 5, 33.6 7, 33.8 11.6 C34 15.6, 30.6 17.6, 27.6 16.4 C25.6 13.6, 24.4 10, 24.6 6.6 Z" '
                f'fill="url(#scale)" stroke="{INK}" stroke-width="1.4"/>'
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
    return svg(f'<g transform="translate(24 24) rotate(45) scale(1.02) translate(-24 -23)">{inner}</g>')


def antler_mantle():
    # A deer-hide mantle for the shoulders, seen from the front: a neck opening, two rounded flaps, a pale fur edge.
    # A golden antler rises from each shoulder.
    cape = 'M9 22 C9 16, 15 12.6, 19 12.4 C20.4 16.6, 27.6 16.6, 29 12.4 C33 12.6, 39 16, 39 22 L41 33 C36 37, 29 36.6, 24 33.4 C19 36.6, 12 37, 7 33 Z'
    left = f'<g transform="translate(14 17.4)">{antler(True, 0.74)}</g>'
    right = f'<g transform="translate(34 17.4)">{antler(False, 0.74)}</g>'
    m = (left + right +
         f'<path d="{cape}" fill="url(#leather)" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round"/>'
         f'<path d="M19 12.4 C20.4 16.6, 27.6 16.6, 29 12.4 C27 11.4, 21 11.4, 19 12.4 Z" fill="#5E3812" stroke="{INK}" stroke-width="1"/>'
         f'<path d="M7.4 31.6 C12 35.4, 19 35, 24 31.8 C29 35, 36 35.4, 40.6 31.6" fill="none" stroke="{INK}" stroke-width="4.4" stroke-linecap="round"/>'
         '<path d="M7.4 31.6 C12 35.4, 19 35, 24 31.8 C29 35, 36 35.4, 40.6 31.6" fill="none" stroke="#F0DCB8" stroke-width="2.6" stroke-linecap="round"/>'
         '<path d="M24 16.6 L24 31" stroke="#5E3812" stroke-width="0.8" opacity="0.7"/>'
         '<path d="M11 20 C15 17.6, 20 17.6, 23 18.6 M25 18.6 C28 17.6, 33 17.6, 37 20" fill="none" stroke="#E8C898" stroke-width="0.7" stroke-dasharray="1.4 1"/>'
         f'<circle cx="24" cy="18.4" r="1.9" fill="url(#gold)" stroke="{INK}" stroke-width="0.8"/>'
         '<path d="M10.6 21 C11.4 18, 14 15.6, 17.4 14.6" fill="none" stroke="#FFFFFF" stroke-width="1" stroke-linecap="round" opacity="0.55"/>'
         '<g fill="#F4E2C2" opacity="0.85"><ellipse cx="15" cy="25" rx="1.1" ry="0.8"/><ellipse cx="19.5" cy="29" rx="1" ry="0.7"/>'
         '<ellipse cx="31" cy="25.6" rx="1.1" ry="0.8"/><ellipse cx="34" cy="29.4" rx="1" ry="0.7"/><ellipse cx="12" cy="29.6" rx="0.9" ry="0.6"/></g>')
    return svg(m)


ITEMS = dict(copper_spear=copper_spear, copper_mace=copper_mace, bone_spear=bone_spear, bone_club=bone_club,
             garnet_ring=garnet_ring, oak_charm=oak_charm, deer_hide_gloves=gloves, deer_hide_bracers=bracers,
             deer_hide_belt=belt, lake_scale_greaves=greaves,
             bone_greataxe=bone_greataxe, golden_antler_mantle=antler_mantle)

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
                  for i in ['copper_sword', 'bone_sword', 'bone_shield', 'hide_vest', 'iron_helm', 'feather_boots'])
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
<div class="plate"><h2>Early gear at bag size</h2><div class="grid">{mine}</div><h2>nabriis</h2><div class="grid">{nab}</div></div>
<div class="plate big"><div class="grid">{mine}</div></div>
</body></html>'''
    preview = os.path.join(tempfile.gettempdir(), 'itheros-gear-preview.html')
    with open(preview, 'w', encoding='utf-8') as fh:
        fh.write(html)
    print(f'Preview: {preview}')
