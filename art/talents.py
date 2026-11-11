# Draws the talent icons as flat silhouettes (art/talents/<image>.svg), #198. One shape for each `image` of
# talents.json, in white on clear, like the empty gear slots (art/slots.py). The game tints it teal, as the stock
# icons were (spec 0015 §6: "from the app's icon set until art comes").
# Run: python art/talents.py [--preview <file.html>]. Then .\scripts\export-art.ps1 makes the webp files
# (app/assets/images/talents/).
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'talents')


def svg(body):
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="48" height="48">'
            f'<g fill="#FFF" fill-rule="evenodd" stroke="none">{body}</g></svg>')


def circle(cx, cy, r):
    return f'M{cx} {cy - r} A{r} {r} 0 1 1 {cx - 0.01} {cy - r} Z '


TALENTS = {
    # Might: a sword held high, on the diagonal.
    'attack': '<path d="M38 5 L43 5 L43 10 L19 34 L14 29 Z"/>'
              '<path d="M8 25 L23 40 L20 43 L5 28 Z"/>'
              '<path d="M10.5 34.5 L13.5 37.5 L7 44 L4 41 Z"/>',
    # Toughness: a heart.
    'hp': '<path d="M24 41 C14 33 7 27 7 18.5 C7 12.5 11.5 8.5 16.5 8.5 C20 8.5 22.5 10.5 24 13 '
          'C25.5 10.5 28 8.5 31.5 8.5 C36.5 8.5 41 12.5 41 18.5 C41 27 34 33 24 41 Z"/>',
    # Guard: a heater shield with a cross.
    'defense': '<path d="M9 8 C17 9 20 7 24 5 C28 7 31 9 39 8 L39 22 C39 32 32 39 24 43 C16 39 9 32 9 22 Z '
               'M22 12 L26 12 L26 21 L33 21 L33 25 L26 25 L26 36 L22 36 L22 25 L15 25 L15 21 L22 21 Z"/>',
    # Keen eye and Impale: a blade point that bursts.
    'crit': '<path d="M24 4 L27.5 17 L40 12 L31 22 L44 26 L31 29 L37 41 L26 32 L24 44 L22 32 L11 41 L17 29 '
            'L4 26 L17 22 L8 12 L20.5 17 Z M24 19 L21 24 L24 29 L27 24 Z"/>',
    # Swift strikes: a boot with lines of speed behind it.
    'steps': '<path d="M22 10 L32 10 L32 27 C32 29 34 30 37 30.5 C41 31.2 43 33 43 36 L43 38 L20 38 L20 35 L22 33 Z"/>'
             '<path d="M5 17 L17 17 L17 20 L5 20 Z M8 24 L18 24 L18 27 L8 27 Z M4 31 L17 31 L17 34 L4 34 Z"/>',
    # Precision: a target with an arrow in the middle.
    'hit': f'<path d="{circle(22, 26, 16)}{circle(22, 26, 12)}"/>'
           f'<path d="{circle(22, 26, 8.5)}{circle(22, 26, 4.5)}"/>'
           '<path d="M21 25 L37 9 L39 11 L23 27 Z M35 6 L42 6 L42 13 L38.5 13 L38.5 9.5 L35 9.5 Z"/>',
    # Evasion: a figure leaning away from a passing gust.
    'dodge': f'<path d="{circle(30, 10, 4.5)}"/>'
             '<path d="M27 16 L33 17 L34 28 L38 39 L34 40.5 L29.5 30 L26 33 L22 41 L18 39.5 L22 30 L23 22 L17 26 '
             'L14.5 23.5 Z"/>'
             '<path d="M4 20 L16 20 L16 22.5 L4 22.5 Z M6 27 L14 27 L14 29.5 L6 29.5 Z M3 34 L13 34 L13 36.5 L3 36.5 Z"/>',
    # Treasure hunter: a cut gem.
    'quality': '<path d="M14 9 L34 9 L42 19 L24 41 L6 19 Z M17 12 L13.5 18 L20 18 Z M24 12 L21 18 L27 18 Z '
               'M31 12 L28 18 L34.5 18 Z M10.5 21 L21.5 34 L19 21 Z M37.5 21 L26.5 34 L29 21 Z"/>',
    # Deep pockets: a coin purse tied at the top, with a coin.
    'bank': '<path d="M18 8 L30 8 L27 14 C35 17 40 24 40 31 C40 38 33 42 24 42 C15 42 8 38 8 31 C8 24 13 17 21 14 Z '
            f'M20 16.5 L28 16.5 L28 18.5 L20 18.5 Z {circle(24, 30, 6)}"/>'
            f'<path d="{circle(24, 30, 3.6)}"/>',
    # Nimble and Practised hands: an open hand with a spark of skill.
    'profession': '<path d="M14 27 L14 15 C14 13.5 17 13.5 17 15 L17 24 L18 24 L18 12.5 C18 11 21 11 21 12.5 L21 24 '
                  'L22 24 L22 13.5 C22 12 25 12 25 13.5 L25 25 L26 25 L26 17 C26 15.5 29 15.5 29 17 L29 31 '
                  'C29 37 25 41 20 41 C16 41 13 39 11 35 L7 28 C6 26.5 8 25 9.5 26.5 L14 30 Z"/>'
                  '<path d="M36 6 L37.6 11.4 L43 13 L37.6 14.6 L36 20 L34.4 14.6 L29 13 L34.4 11.4 Z"/>',
    # Bountiful: a full sack, tied, with something spilling out.
    'material': '<path d="M19 6 L29 6 L27 12 C34 15 39 22 39 29 C39 37 32 41 24 41 C16 41 9 37 9 29 C9 22 14 15 21 12 Z '
                'M20.5 14 L27.5 14 L27.5 16 L20.5 16 Z"/>'
                f'<path d="{circle(40.5, 38, 3)}{circle(35, 41, 2.5)}"/>',
    # Wary: an open eye.
    'warning': '<path d="M3 24 C9 14 16 10 24 10 C32 10 39 14 45 24 C39 34 32 38 24 38 C16 38 9 34 3 24 Z '
               'M24 15 A9 9 0 1 0 24.01 15 Z"/>'
               f'<path d="{circle(24, 24, 5)}"/>',
    # Master crafter: an anvil.
    'anvil': '<path d="M6 13 L38 13 C38 18 35 21 30 22 L29 27 L34 27 L36 33 L12 33 L14 27 L19 27 L18 22 C12 21 6 18 6 13 Z"/>'
             '<path d="M38 13 L44 15 L38 17 Z"/>'
             '<path d="M10 35 L38 35 L38 40 L10 40 Z"/>',
    # Quartermaster: a list with ticks and a plus.
    'queue': '<path d="M6 9 L12 9 L12 15 L6 15 Z M16 10.5 L34 10.5 L34 13.5 L16 13.5 Z '
             'M6 20 L12 20 L12 26 L6 26 Z M16 21.5 L34 21.5 L34 24.5 L16 24.5 Z '
             'M6 31 L12 31 L12 37 L6 37 Z M16 32.5 L28 32.5 L28 35.5 L16 35.5 Z"/>'
             '<path d="M35.5 28 L38.5 28 L38.5 33 L43.5 33 L43.5 36 L38.5 36 L38.5 41 L35.5 41 L35.5 36 L30.5 36 '
             'L30.5 33 L35.5 33 Z"/>',
    # Wayfarer and Light pack: a signpost on a path.
    'travel': '<path d="M22 6 L26 6 L26 42 L22 42 Z"/>'
              '<path d="M12 10 L34 10 L39 14.5 L34 19 L12 19 Z M36 22 L14 22 L9 26.5 L14 31 L36 31 Z"/>'
              '<path d="M10 41 C16 39 32 39 38 41 L38 43 L10 43 Z"/>',
    # Lucky hammer: two dice.
    'reroll': '<path d="M6 16 L22 12 L26 28 L10 32 Z '
              f'{circle(11.8, 19.5, 2)}{circle(19.6, 25, 2)}'
              f'"/><path d="M27 18 L42 22 L38 38 L23 34 Z {circle(30, 24, 1.8)}{circle(36.5, 26, 1.8)}'
              f'{circle(33.2, 29.8, 1.8)}{circle(29.5, 32, 1.8)}{circle(36, 33.8, 1.8)}"/>',
    # Bigger bag: a backpack with a flap and a pocket.
    'bag': '<path d="M19 6 C19 3.5 29 3.5 29 6 L29 9 L26.5 9 L26.5 7 C26.5 6 21.5 6 21.5 7 L21.5 9 L19 9 Z"/>'
           '<path d="M13 17 C13 11.5 17 9 24 9 C31 9 35 11.5 35 17 L36 39 C36 41 34 42 32 42 L16 42 C14 42 12 41 12 39 Z '
           'M17 29 L31 29 L31 37 L17 37 Z M13.3 20 L34.7 20 L34.8 22 L13.2 22 Z"/>',
}


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, body in TALENTS.items():
        with open(os.path.join(OUT, f'{name}.svg'), 'w', encoding='utf-8', newline='\n') as f:
            f.write(svg(body))
    if '--preview' in sys.argv:
        path = sys.argv[sys.argv.index('--preview') + 1]
        cells = ''.join(
            f'<div class="c"><div class="s"><div class="m" style="-webkit-mask-image:url(\'{os.path.join(OUT, n + ".svg").replace(os.sep, "/")}\')"></div></div>'
            f'<span>{n}</span></div>'
            for n in TALENTS)
        html = ('<!DOCTYPE html><html><body style="background:#161D21;color:#9AA;font:13px sans-serif;margin:16px">'
                '<style>.c{display:inline-flex;flex-direction:column;align-items:center;gap:6px;margin:8px;width:80px}'
                '.s{width:56px;height:56px;display:flex;align-items:center;justify-content:center}'
                '.m{width:40px;height:40px;background:#4FB3A6;-webkit-mask-size:contain;-webkit-mask-repeat:no-repeat;'
                '-webkit-mask-position:center}</style>' + cells + '</body></html>')
        with open(path, 'w', encoding='utf-8') as f:
            f.write(html)
    print(f'{len(TALENTS)} talents written to {OUT}')


if __name__ == '__main__':
    main()
