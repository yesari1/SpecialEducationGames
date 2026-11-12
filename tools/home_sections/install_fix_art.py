"""Installs the pictures of the 12 November 2026 fix round.

    python -I tools/home_sections/install_fix_art.py

From artifacts/fix-nov12/ (drawn with ChatGPT image generation through Codex,
see wear_runner.py and make_prompts.py there):
- jobs/*.png and out/*.png: the job scenes and the girl's weather scenes,
  transparent, cropped to the figures -> assets/images/play/<name>.webp
- wear/<who>_base.png and <who>_<outfit>_<n>.png: the child before and after
  each garment -> assets/images/wear/, plus <who>_face.webp and the picture
  of the game's card (artifacts/illustrations-home/items/wear/<who>.png)
- wear/item_<who>_<outfit>_<slug>.png: each garment alone ->
  artifacts/illustrations-home/items/outfit/, which build_themes.py installs
- assets/images/play/bowl_front.webp: the near wall of bowl_empty.webp, drawn
  over the fruit so it sits inside the bowl.
Run build_themes.py and build_photo_bounds.py afterwards.
"""
import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / 'artifacts/fix-nov12'
PLAY = ROOT / 'assets/images/play'
WEAR = ROOT / 'assets/images/wear'
ITEMS = ROOT / 'artifacts/illustrations-home/items'


def clean(im):
    """Clears the faint halo image generation leaves around a cutout."""
    im = im.convert('RGBA')
    alpha = im.getchannel('A').point(lambda v: 0 if v < 20 else v)
    im.putalpha(alpha)
    return im


def save(im, out, quality=90):
    out.parent.mkdir(parents=True, exist_ok=True)
    im.save(out, 'WEBP', quality=quality, alpha_quality=100, method=4)


def fresh(src, out):
    """True when [out] was already made from this [src]."""
    return out.exists() and out.stat().st_mtime >= src.stat().st_mtime


def scenes(folder):
    done = 0
    for src in sorted((SRC / folder).glob('*.png')):
        if src.name.startswith('_') or fresh(src, PLAY / f'{src.stem}.webp'):
            continue
        im = clean(Image.open(src))
        box = im.getchannel('A').point(lambda v: 255 if v > 24 else 0).getbbox()
        pad = 24
        box = (max(0, box[0] - pad), max(0, box[1] - pad), min(im.width, box[2] + pad), min(im.height, box[3] + pad))
        im = im.crop(box)
        if im.width > 1200:
            im = im.resize((1200, round(im.height * 1200 / im.width)), Image.LANCZOS)
        save(im, PLAY / f'{src.stem}.webp')
        done += 1
    print(f'{folder} scenes:', done)


def wear():
    done = 0
    for src in sorted((SRC / 'wear').glob('*.png')):
        name = src.stem
        if name.startswith('_'):
            continue
        if name.startswith('item_'):
            out = ITEMS / 'outfit' / f'{name[5:]}.png'
            out.parent.mkdir(parents=True, exist_ok=True)
            if not fresh(src, out):
                clean(Image.open(src)).save(out)
            continue
        if fresh(src, WEAR / f'{name}.webp'):
            continue
        im = clean(Image.open(src))
        if im.size != (1024, 1536):
            print('SKIPPED (size)', src.name, im.size)
            continue
        save(im.resize((800, 1200), Image.LANCZOS), WEAR / f'{name}.webp')
        done += 1
    for who in ('boy', 'girl'):
        base = SRC / 'wear' / f'{who}_base.png'
        if not base.exists():
            continue
        im = clean(Image.open(base))
        # The head: from the top of the hair to the chin.
        box = im.getchannel('A').point(lambda v: 255 if v > 24 else 0).getbbox()
        head = im.crop((0, box[1], 1024, box[1] + round((box[3] - box[1]) * .40)))
        hb = head.getchannel('A').point(lambda v: 255 if v > 24 else 0).getbbox()
        head = head.crop(hb)
        head.thumbnail((256, 256), Image.LANCZOS)
        save(head, WEAR / f'{who}_face.webp')
        # The game's card shows the child dressed for the park.
        last = sorted((SRC / 'wear').glob(f'{who}_park_*.png'))
        if last:
            card = ITEMS / 'wear' / f'{who}.png'
            card.parent.mkdir(parents=True, exist_ok=True)
            clean(Image.open(last[-1])).save(card)
    print('wear pictures:', done)


def bowl_front():
    """Everything of bowl_empty.webp that is nearer than the bowl's opening."""
    im = Image.open(PLAY / 'bowl_empty.webp').convert('RGBA')
    w, h = im.size
    # The inside of the bowl as seen in the picture (an ellipse), measured
    # on the 1200x800 picture.
    cx, cy, rx, ry = .489 * w, .345 * h, .355 * w, .245 * h
    mask = Image.new('L', (w * 2, h * 2), 255)
    draw = ImageDraw.Draw(mask)
    draw.ellipse([(cx - rx) * 2, (cy - ry) * 2, (cx + rx) * 2, (cy + ry) * 2], fill=0)
    # Nothing above the middle of the opening is "in front".
    draw.rectangle([0, 0, w * 2, cy * 2], fill=0)
    mask = mask.resize((w, h), Image.LANCZOS).filter(ImageFilter.GaussianBlur(1.2))
    im.putalpha(mask)
    save(im, PLAY / 'bowl_front.webp', quality=92)
    print('bowl front written')


def main():
    scenes('jobs')
    scenes('out')
    wear()
    if not (PLAY / 'bowl_front.webp').exists():
        bowl_front()


if __name__ == '__main__':
    main()
