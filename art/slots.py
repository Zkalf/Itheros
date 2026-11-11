# Draws the empty gear slots as flat silhouettes (art/slots/<slot>.svg), #198. Each one is the plain shape of what
# the slot holds (a helm, a boot, a ring), in white on clear. The game tints it faint on the dark socket, so an empty
# slot reads as empty and still tells its slot (spec 0014 §2.3: "the faint slot icon").
# Run: python art/slots.py [--preview <file.html>]. Then .\scripts\export-art.ps1 makes the webp files
# (app/assets/images/slots/).
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'slots')


def svg(body):
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="48" height="48">'
            f'<g fill="#FFF" fill-rule="evenodd" stroke="none">{body}</g></svg>')


# Each shape fills about 30 x 30 of the 48 x 48 box, centred, so all slots look the same size.
SLOTS = {
    # A nasal helm: a dome, cheek guards and the nose bar.
    'head': '<path d="M11 27 C11 15 17 9 24 9 C31 9 37 15 37 27 L37 36 L31 36 L31 29 L27 27 L27 37 L21 37 L21 27 '
            'L17 29 L17 36 L11 36 Z"/>',
    # An amulet: a chain in a V and a round pendant with a gem hole.
    'neck': '<path d="M12 9 L24 28 L36 9 L33.5 9 L24 24 L14.5 9 Z"/>'
            '<path d="M24 25 A7.5 7.5 0 1 1 23.99 25 Z M24 29.5 A3 3 0 1 0 24.01 29.5 Z"/>',
    # A pauldron: three curved plates, one over the other.
    'shoulder': '<path d="M9 30 C9 18 16 11 26 11 C34 11 39 16 39 22 C33 19 24 20 18 25 C14 28 12 31 12 34 Z"/>'
                '<path d="M14 36 C15 29 21 24 30 23 C34 23 37 24 39 26 C33 26 26 28 21 32 C18 34 17 36 17 38 Z"/>'
                '<path d="M19 40 C21 34 26 30 33 29 C35 29 37 29.5 38 30.5 C33 31 28 33 25 36 C23 38 22 39 22 41 Z"/>',
    # A cloak: a hood on top, falling wide to a ragged hem.
    'cloak': '<path d="M24 7 C19 7 16 11 16 15 C16 17 16.5 18 17 19 C13 24 10 31 9 40 L15 38 L19 41 L24 38 L29 41 '
             'L33 38 L39 40 C38 31 35 24 31 19 C31.5 18 32 17 32 15 C32 11 29 7 24 7 Z '
             'M24 11 C21.5 11 20 13 20 15.5 C20 17 21 18.5 24 19 C27 18.5 28 17 28 15.5 C28 13 26.5 11 24 11 Z"/>',
    # A tunic: shoulders, short sleeves and a V neck.
    'chest': '<path d="M18 8 L24 14 L30 8 L36 10 L42 18 L37 22 L34 19 L34 40 L14 40 L14 19 L11 22 L6 18 L12 10 Z"/>',
    # A bracer: a curved cuff with crossed laces.
    'bracer': '<path d="M14 12 C14 9 34 9 34 12 L32 37 C32 40 16 40 16 37 Z '
              'M20.5 16 L27.5 23 L26 24.5 L19 17.5 Z M27.5 16 L29 17.5 L22 24.5 L20.5 23 Z '
              'M20.5 25 L27.5 32 L26 33.5 L19 26.5 Z M27.5 25 L29 26.5 L22 33.5 L20.5 32 Z"/>',
    # A glove: four fingers, the thumb and a flared cuff.
    'gloves': '<path d="M17 24 L17 11 C17 9.5 20 9.5 20 11 L20 21 L21 21 L21 8.5 C21 7 24 7 24 8.5 L24 21 L25 21 '
              'L25 9.5 C25 8 28 8 28 9.5 L28 22 L29 22 L29 13 C29 11.5 32 11.5 32 13 L32 28 C32 31 31 33 29 34 '
              'L29 37 L16 37 L16 33 L11 25 C10 23.5 12 22 13.5 23.5 L17 27 Z M14 37 L31 37 L32 42 L13 42 Z"/>',
    # A belt: a strap with a square buckle and its pin.
    'belt': '<path d="M6 20 L42 20 L42 28 L6 28 Z M18 17 L30 17 L30 31 L18 31 Z M21 20 L27 20 L27 28 L21 28 Z"/>'
            '<path d="M23.2 23 L36 23 L36 25 L23.2 25 Z"/>',
    # Greaves: a pair of leg guards with knee plates.
    'legs': '<path d="M13 8 L22 8 L22.5 22 L21 38 L14 38 L12.5 22 Z M26 8 L35 8 L35.5 22 L34 38 L27 38 L25.5 22 Z"/>'
            '<path d="M11.5 20 L23.5 20 L23 25 L12 25 Z M24.5 20 L36.5 20 L36 25 L25 25 Z"/>',
    # A boot: the shaft, the heel and a pointed toe.
    'boots': '<path d="M15 8 L27 8 L27 28 C27 30 29 31 32 31.5 C37 32.3 40 34 40 37 L40 40 L12 40 L12 36 L15 34 Z"/>'
             '<path d="M13 8 L29 8 L29 12 L13 12 Z"/>',
    # A ring: a band with a gem on top.
    'ring': '<path d="M24 15 A12 12 0 1 1 23.99 15 Z M24 19.5 A7.5 7.5 0 1 0 24.01 19.5 Z"/>'
            '<path d="M18.5 12 L21 8 L27 8 L29.5 12 L24 18 Z"/>',
    # A charm: a ring at the top and a hanging talisman with a star.
    'trinket': '<path d="M24 5 A3 3 0 1 1 23.99 5 Z M24 7 A1.2 1.2 0 1 0 24.01 7 Z"/>'
               '<path d="M22.8 10.5 L25.2 10.5 L25.2 14 L22.8 14 Z"/>'
               '<path d="M24 13 L35 20 L32 37 L24 43 L16 37 L13 20 Z M24 19 L25.9 24.7 L31.8 24.7 L27 28.2 L28.9 33.8 '
               'L24 30.3 L19.1 33.8 L21 28.2 L16.2 24.7 L22.1 24.7 Z"/>',
    # A sword, upright: the blade, the guard and the grip.
    'mainHand': '<path d="M24 4 L27 9 L27 30 L21 30 L21 9 Z"/>'
                '<path d="M14 30 L34 30 L34 33.5 L14 33.5 Z"/>'
                '<path d="M22.3 33.5 L25.7 33.5 L25.7 41 L22.3 41 Z"/>'
                '<path d="M24 40 A3.2 3.2 0 1 1 23.99 40 Z"/>',
    # A heater shield with a boss.
    'offHand': '<path d="M10 9 C17 10 20 8 24 6 C28 8 31 10 38 9 L38 22 C38 31 32 38 24 42 C16 38 10 31 10 22 Z '
               'M24 18.5 A4.5 4.5 0 1 0 24.01 18.5 Z"/>',
}


def main():
    os.makedirs(OUT, exist_ok=True)
    for slot, body in SLOTS.items():
        with open(os.path.join(OUT, f'{slot}.svg'), 'w', encoding='utf-8', newline='\n') as f:
            f.write(svg(body))
    if '--preview' in sys.argv:
        path = sys.argv[sys.argv.index('--preview') + 1]
        cells = ''.join(
            f'<div class="c"><div class="s s72"><div class="m" style="-webkit-mask-image:url(\'{os.path.join(OUT, s + ".svg").replace(os.sep, "/")}\')"></div></div>'
            f'<div class="s s48"><div class="m" style="-webkit-mask-image:url(\'{os.path.join(OUT, s + ".svg").replace(os.sep, "/")}\')"></div></div>'
            f'<span>{s}</span></div>'
            for s in SLOTS)
        html = ('<!DOCTYPE html><html><body style="background:#161D21;color:#9AA;font:13px sans-serif;margin:16px">'
                '<style>.c{display:inline-flex;flex-direction:column;align-items:center;gap:6px;margin:8px;width:90px}'
                '.s{background:#050708;border-radius:12px;display:flex;align-items:center;justify-content:center}'
                '.s72{width:72px;height:72px}.s48{width:48px;height:48px}'
                '.m{width:70%;height:70%;background:#5F7A80;-webkit-mask-size:contain;-webkit-mask-repeat:no-repeat;'
                '-webkit-mask-position:center}</style>' + cells + '</body></html>')
        with open(path, 'w', encoding='utf-8') as f:
            f.write(html)
    print(f'{len(SLOTS)} slots written to {OUT}')


if __name__ == '__main__':
    main()
