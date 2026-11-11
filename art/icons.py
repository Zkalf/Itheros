# Draws the small icons of Camp and of the level-up card as flat silhouettes (art/icons/<name>.svg), #198: the Bank,
# the Forge, the Camp fire and the trainer on Now; the level, a new gathering spot and a talent point on a level-up.
# White on clear, like the empty gear slots (art/slots.py); the game tints them like the stock icons they replace.
# Run: python art/icons.py [--preview <file.html>]. Then .\scripts\export-art.ps1 makes the webp files
# (app/assets/images/icons/).
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'icons')


def svg(body):
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="48" height="48">'
            f'<g fill="#FFF" fill-rule="evenodd" stroke="none">{body}</g></svg>')


def circle(cx, cy, r):
    return f'M{cx} {cy - r} A{r} {r} 0 1 1 {cx - 0.01} {cy - r} Z '


def spark(cx, cy, r):
    k = r * 0.3
    return (f'M{cx} {cy - r} L{cx + k} {cy - k} L{cx + r} {cy} L{cx + k} {cy + k} L{cx} {cy + r} '
            f'L{cx - k} {cy + k} L{cx - r} {cy} L{cx - k} {cy - k} Z ')


ICONS = {
    # The Bank: a strongbox with iron bands and a lock.
    'bank': '<path d="M7 18 C7 12 11 9 17 9 L31 9 C37 9 41 12 41 18 L41 20 L7 20 Z"/>'
            '<path d="M7 22 L41 22 L41 39 L7 39 Z '
            'M20 25 L28 25 L28 32 L20 32 Z"/>'
            f'<path d="{circle(24, 27.5, 1.6)}M23.2 28 L24.8 28 L25.2 30.5 L22.8 30.5 Z"/>',
    # The Forge: an anvil with a hammer over it.
    'forge': '<path d="M7 24 L35 24 C35 28 32.5 30.5 28 31 L27 34 L31 34 L33 38 L11 38 L13 34 L17 34 L16 31 '
             'C11 30.5 7 28 7 24 Z M35 24 L41 25.5 L35 27 Z"/>'
             '<path d="M10 40 L34 40 L34 43 L10 43 Z"/>'
             '<path d="M27 4 L36 9 L33.5 13.5 L24.5 8.5 Z M28.5 11 L31 12.5 L22 21 L19.5 19.5 Z"/>',
    # The Camp fire: a flame over two crossed logs.
    'fire': '<path d="M24 4 C26 10 33 14 33 23 C33 29 29 33 24 33 C19 33 15 29 15 23 C15 18 18 15 19 11 '
            'C21 14 21 17 23 18 C24 13 23 8 24 4 Z M24 22 C22 25 20 26.5 20 29 C20 30.5 22 31.5 24 31.5 '
            'C26 31.5 28 30.5 28 29 C28 26.5 26 25 24 22 Z"/>'
            '<path d="M8 33 L11 31 L40 41 L37 43.5 Z M40 33 L37 31 L8 41 L11 43.5 Z"/>',
    # The trainer: an open book of talents with a star over it.
    'trainer': '<path d="M5 16 C11 14 18 15 23 18 L23 41 C18 38 11 37 5 39 Z '
               'M43 16 C37 14 30 15 25 18 L25 41 C30 38 37 37 43 39 Z"/>'
               f'<path d="{spark(24, 8, 6.5)}"/>',
    # A new level: a double arrow up in a ring.
    'level': f'<path d="{circle(24, 24, 19)}{circle(24, 24, 15.5)}"/>'
             '<path d="M24 11 L35 22 L31 22 L24 15 L17 22 L13 22 Z M24 21 L35 32 L31 32 L24 25 L17 32 L13 32 Z"/>'
             '<path d="M22 31 L26 31 L26 37 L22 37 Z"/>',
    # A new gathering spot: a rock with a vein and a pickaxe stuck in it.
    'spot': '<path d="M4 40 L13 24 L19 28 L27 16 L36 26 L44 40 Z M18 33 L22 30 L25 33 L22 36 Z"/>'
            '<path d="M30 3 C36 4 41 8 43 13 L41 14 C38 10 34 8 30 7.5 Z M36 9 L38.5 10.5 L31 23 L28.5 21.5 Z"/>',
    # A talent point: a big spark with two small ones.
    'talent': f'<path d="{spark(22, 26, 16)}{spark(38, 10, 6)}{spark(39, 37, 4.5)}"/>',
}


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, body in ICONS.items():
        with open(os.path.join(OUT, f'{name}.svg'), 'w', encoding='utf-8', newline='\n') as f:
            f.write(svg(body))
    if '--preview' in sys.argv:
        path = sys.argv[sys.argv.index('--preview') + 1]
        cells = ''.join(
            f'<div class="c"><div class="s"><div class="m" style="-webkit-mask-image:url(\'{os.path.join(OUT, n + ".svg").replace(os.sep, "/")}\')"></div></div>'
            f'<span>{n}</span></div>'
            for n in ICONS)
        html = ('<!DOCTYPE html><html><body style="background:#161D21;color:#9AA;font:13px sans-serif;margin:16px">'
                '<style>.c{display:inline-flex;flex-direction:column;align-items:center;gap:6px;margin:8px;width:80px}'
                '.s{width:56px;height:56px;display:flex;align-items:center;justify-content:center}'
                '.m{width:32px;height:32px;background:#D8DEDF;-webkit-mask-size:contain;-webkit-mask-repeat:no-repeat;'
                '-webkit-mask-position:center}</style>' + cells + '</body></html>')
        with open(path, 'w', encoding='utf-8') as f:
            f.write(html)
    print(f'{len(ICONS)} icons written to {OUT}')


if __name__ == '__main__':
    main()
