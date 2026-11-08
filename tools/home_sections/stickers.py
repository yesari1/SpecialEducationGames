"""Stickers: ~10 per theme, drawn with ChatGPT in the app's clay style.

    python -I tools/home_sections/stickers.py prompt <start> <end> > prompt.txt
    python -I tools/home_sections/stickers.py install

A sticker shows one item of its theme and uses that item's name and voice.
Originals: artifacts/illustrations-home/stickers/<theme>/<slug>.png. install
writes assets/stickers/<theme>/<slug>.webp and assets/content/stickers.json
(only stickers that have a picture).
"""
import json
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / 'artifacts/illustrations-home/stickers'
ITEMS = ROOT / 'assets/content/items'
PER_THEME = 10
ORDER = ['animals', 'produce', 'food', 'cleaning', 'clothes', 'kitchen', 'home', 'vehicles', 'jobs', 'nature',
         'colors', 'shapes', 'numbers', 'body', 'emotions', 'music']


def catalog():
    rows = []
    themes = {t['id']: t for t in json.loads((ROOT / 'assets/content/themes.json').read_text(encoding='utf-8-sig'))}
    for theme in ORDER:
        if theme not in themes:
            continue
        items = json.loads((ITEMS / f'{theme}.json').read_text(encoding='utf-8-sig'))
        usable = [i for i in items if i.get('audio')]
        usable.sort(key=lambda i: ['easy', 'medium', 'hard'].index(i['tier']))
        for item in usable[:PER_THEME]:
            rows.append((theme, item['id'].split('.', 1)[1], item['id'], item['name']['en']))
    return rows


def prompt(start, end):
    print('Use your image generation tool to make the stickers below, one image call per file, and save each as a PNG at the exact path. '
          'Skip a file that already exists. Do not change any other file. If your image limit is reached, stop and say so plainly. '
          'When done, reply with the saved files.\n')
    print('Style for EVERY sticker: a die-cut children\'s sticker, one friendly subject in the "SEG soft clay" style (soft 2.5D clay look, rounded chunky shapes, '
          'gentle soft shading, light from the top left, no black outlines, no noise, no glitter), surrounded by one even thick white border that follows its shape. '
          'Colours clear but soft: warm orange #FF8A32, sky blue #63C6F4, blue #1687D9, turquoise #10B7B0, sunny yellow #FFC546, soft pink #E76F8E, lavender #7C73DF, leaf green #6CC66B. '
          'Square 1024x1024, TRUE transparent background outside the white border, subject centred, nothing cropped. No text, no letters unless the subject is a numeral, no logos.\n')
    for i, (theme, slug, _, en) in enumerate(catalog()[start:end], 1):
        print(f'{i}. {ART / theme / (slug + ".png")}: {en} ({theme}).')


def install():
    out = []
    for theme, slug, item, _ in catalog():
        src = ART / theme / f'{slug}.png'
        target = ROOT / f'assets/stickers/{theme}/{slug}.webp'
        if not src.exists():
            continue
        if not target.exists() or src.stat().st_mtime > target.stat().st_mtime:
            target.parent.mkdir(parents=True, exist_ok=True)
            im = Image.open(src).convert('RGBA')
            im = im.crop(im.getchannel('A').point(lambda v: 255 if v > 24 else 0).getbbox())
            im.thumbnail((384, 384), Image.LANCZOS)
            im.save(target, 'WEBP', quality=88, alpha_quality=100, method=6)
        out.append({'id': f'{theme}.{slug}', 'theme': theme, 'item': item, 'image': f'assets/stickers/{theme}/{slug}.webp'})
    (ROOT / 'assets/content/stickers.json').write_text(json.dumps(out, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    print(len(out), 'stickers')


if __name__ == '__main__':
    if sys.argv[1] == 'prompt':
        prompt(int(sys.argv[2]), int(sys.argv[3]))
    else:
        install()
