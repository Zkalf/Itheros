# Draws the map marker of the water places (art/places/water.svg), in the style of nabriis's markers (#198): a round
# medallion with a gold ring and a dark slate face, and one painted object on it. Mirror Lake and Smugglers' Cove use
# it: they have only fishing spots and no marker of their own.
# Run: python art/places.py. Then .\scripts\export-art.ps1 makes the webp file (app/assets/images/places/water.webp).
import os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'places')
INK = '#24140A'


def water():
    defs = (
        '<linearGradient id="gold" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F6D77A"/>'
        '<stop offset="0.45" stop-color="#D9A33A"/><stop offset="1" stop-color="#8E5E14"/></linearGradient>'
        '<radialGradient id="slate" cx="0.42" cy="0.38" r="0.7"><stop offset="0" stop-color="#3C444D"/>'
        '<stop offset="1" stop-color="#1C2026"/></radialGradient>'
        '<linearGradient id="sea" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5FB4D6"/>'
        '<stop offset="1" stop-color="#1F5C86"/></linearGradient>'
        '<linearGradient id="fish" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E4F1F4"/>'
        '<stop offset="0.5" stop-color="#8FB8C6"/><stop offset="1" stop-color="#3E6E82"/></linearGradient>'
        '<clipPath id="face"><circle cx="50" cy="50" r="40.5"/></clipPath>'
    )
    # Two rows of waves across the lower half of the face, each with a pale crest.
    waves = ''
    for y, light in ((62, '#9ED8EC'), (72, '#6FB7D6')):
        d = f'M4 {y} ' + ' '.join(f'q6 -6 12 0 q6 6 12 0' for _ in range(4)) + ' V100 H4 Z'
        waves += f'<path d="{d}" fill="url(#sea)" stroke="{INK}" stroke-width="1" stroke-linejoin="round"/>'
        waves += (f'<path d="M4 {y} ' + ' '.join('q6 -6 12 0 q6 6 12 0' for _ in range(4)) + '" fill="none" '
                  f'stroke="{light}" stroke-width="1.6" stroke-linecap="round"/>')
    # A fish leaping in an arc over the waves, lit from the top left.
    fish = (
        f'<path d="M30 58 Q36 34 58 32 Q66 32 70 36 L80 28 L78 40 L84 48 L72 44 Q66 50 58 50 Q42 52 30 58 Z" '
        f'fill="url(#fish)" stroke="{INK}" stroke-width="1.4" stroke-linejoin="round"/>'
        f'<path d="M46 36 L50 26 L56 33 Z" fill="#6E98A8" stroke="{INK}" stroke-width="1" stroke-linejoin="round"/>'
        '<path d="M36 50 Q46 38 62 36" fill="none" stroke="#FFFFFF" stroke-width="1.4" stroke-linecap="round" opacity="0.8"/>'
        f'<circle cx="62" cy="39" r="2" fill="{INK}"/><circle cx="62.6" cy="38.4" r="0.6" fill="#FFFFFF"/>'
    )
    drops = ''.join(f'<path d="M{x} {y} q1.6 2.6 0 3.6 q-1.6 -1 0 -3.6 Z" fill="#BFE6F2" stroke="{INK}" stroke-width="0.5"/>'
                    for x, y in ((26, 50), (22, 56), (34, 44), (82, 54)))
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100">'
            f'<defs>{defs}</defs>'
            '<circle cx="50" cy="50" r="47" fill="#3A2A10"/>'
            '<circle cx="50" cy="50" r="44.5" fill="url(#gold)"/>'
            '<circle cx="50" cy="50" r="44.5" fill="none" stroke="#FFF1B8" stroke-width="0.8" opacity="0.7"/>'
            f'<circle cx="50" cy="50" r="40.5" fill="url(#slate)" stroke="{INK}" stroke-width="1.2"/>'
            f'<g clip-path="url(#face)">{waves}</g>'
            f'{drops}{fish}'
            '</svg>')


def main():
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, 'water.svg'), 'w', encoding='utf-8', newline='\n') as f:
        f.write(water())
    print(f'water marker written to {OUT}')


if __name__ == '__main__':
    main()
