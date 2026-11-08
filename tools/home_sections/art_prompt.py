"""Writes a ChatGPT (Codex) image prompt for a list of item pictures.

    python -I tools/home_sections/art_prompt.py <theme|extra> [start end] > prompt.txt

Pictures go to artifacts/illustrations-home/items/<theme>/<slug>.png, the
folder build_themes.py installs from.
"""
import importlib.util
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]

MASTER = """Create an illustration in the "SEG soft clay" style for a calm educational app for young children (2-8) including children with autism and special needs.
Style: soft 2.5D clay / vinyl-toy look, rounded chunky friendly shapes, gentle volume with soft ambient-occlusion shading, one soft light from the top left, no outlines, no black strokes, no texture noise, no glitter, no motion lines.
Palette: warm orange #FF8A32, sky blue #63C6F4, blue #1687D9, turquoise #10B7B0, sunny yellow #FFC546, soft pink #E76F8E, lavender #7C73DF, leaf green #6CC66B, cream #FFF6EA; clear but slightly soft, at most 3-4 main colours.
Calm, low-stimulation composition with lots of empty space, one clear subject, centred, fully inside the frame with ~10% margin, nothing cropped.
No text, no letters, no logos, no watermark. No people, no faces on objects. Transparent background."""

NOTES = {
    'tap': 'a single kitchen-style water tap (faucet) with a small handle',
    'tissue': 'a small box of tissues with one tissue sticking out',
    'dustpan': 'a dustpan with a short handle',
    'drying_rack': 'a folding clothes drying rack with two small clothes on it',
    'bath_sponge': 'a soft round puffy bath sponge',
    'shower': 'a wall shower head with a hose and a few soft water drops',
    'nail_clipper': 'a pair of small nail clippers',
    'rubber_gloves': 'a pair of yellow rubber cleaning gloves',
    'detergent': 'a blue bottle of laundry detergent, with no writing on it',
    'shampoo': 'a bottle of shampoo with no writing on it',
    'toothpaste': 'a tube of toothpaste with no writing on it',
    'cupboard': 'a small wooden kitchen cupboard with two closed doors',
    'cup': 'a small tea cup on a saucer',
    'teapot': 'a Turkish double teapot (caydanlik): a small teapot sitting on top of a larger kettle',
    'glass': 'a plain drinking glass',
    'whisk': 'a balloon whisk',
    'rolling_pin': 'a long thin wooden rolling pin (Turkish oklava)',
    'oven': 'a small kitchen oven with a glass door',
    'fridge': 'a small two-door fridge, closed',
    'dishwasher': 'a small dishwasher, closed',
    'tshirt': 'an orange short-sleeved T-shirt, laid flat',
    'trousers': 'a pair of blue pants, laid flat',
}


def load(path):
    spec = importlib.util.spec_from_file_location(path.stem, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main():
    theme = sys.argv[1]
    rows = []
    for path in sorted(HERE.glob('source_step*.py')):
        src = load(path)
        if theme == 'extra':
            for iid, _, en in src.EXTRA:
                group, slug = iid.split('.', 1)
                rows.append((group, slug, en))
        elif theme == 'clothes' and hasattr(src, 'CLOTHES_OPEN'):
            names = src.CLOTHES_EN
            rows += [('clothes', s, names.get(s, s.replace('_', ' '))) for s in src.CLOTHES_OPEN]
        elif hasattr(src, theme.upper()):
            rows += [(theme, slug, en) for slug, _, _, en in getattr(src, theme.upper())]
    if len(sys.argv) > 3:
        rows = rows[int(sys.argv[2]):int(sys.argv[3])]
    print('Use your image generation tool to make the PNG illustrations below and save each one to the exact path given. '
          'Generate each picture separately (one image call per file). Square 1024x1024, TRUE transparent background (alpha), '
          'nothing cropped. Skip a file that already exists. Do not change any other file. If your image limit is reached, stop and say so plainly. '
          'When done, reply with the list of saved files.\n')
    print('Master style for EVERY picture:\n' + MASTER + '\n')
    for i, (group, slug, en) in enumerate(rows, 1):
        out = ROOT / 'artifacts/illustrations-home/items' / group / f'{slug}.png'
        print(f'{i}. {out}: {NOTES.get(slug, "A single " + en.lower())}.')


if __name__ == '__main__':
    main()
