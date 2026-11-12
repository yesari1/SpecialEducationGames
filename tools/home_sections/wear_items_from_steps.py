"""Cuts each garment out of the dress-up pictures themselves.

    python -I tools/home_sections/wear_items_from_steps.py [--all]

For every outfit step the garment is what changed between the picture before
and the picture after it (artifacts/fix-nov12/wear/<who>_<outfit>_<n>.png).
The cut-out is written to artifacts/illustrations-home/items/outfit/
<who>_<outfit>_<slug>.png, where build_themes.py installs it from. It is the
stand-in for a garment whose own drawing (item_*.png) does not exist yet;
--all writes it for every garment.
"""
import importlib.util
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
WEAR = ROOT / 'artifacts/fix-nov12/wear'
OUT = ROOT / 'artifacts/illustrations-home/items/outfit'

spec = importlib.util.spec_from_file_location('source_step2', Path(__file__).with_name('source_step2.py'))
source = importlib.util.module_from_spec(spec)
spec.loader.exec_module(source)


def garment(before, after):
    a, b = before.convert('RGBA'), after.convert('RGBA')
    diff = ImageChops.difference(a, b)
    r, g, bl, al = diff.split()
    change = ImageChops.lighter(ImageChops.lighter(r, g), ImageChops.lighter(bl, al))
    mask = change.point(lambda v: 255 if v > 26 else 0)
    # Close small gaps; then keep only what belongs to a solid area, so the
    # hair-thin differences along the child's outline are dropped.
    mask = mask.filter(ImageFilter.MaxFilter(7)).filter(ImageFilter.MinFilter(7))
    solid = mask.filter(ImageFilter.MinFilter(15)).filter(ImageFilter.MaxFilter(29))
    mask = ImageChops.multiply(mask, solid)
    mask = ImageChops.multiply(mask, b.getchannel('A').point(lambda v: 255 if v > 40 else 0))
    mask = mask.filter(ImageFilter.GaussianBlur(1))
    out = b.copy()
    out.putalpha(mask)
    box = mask.point(lambda v: 255 if v > 40 else 0).getbbox()
    return out.crop(box) if box else None


def main():
    every = '--all' in sys.argv
    OUT.mkdir(parents=True, exist_ok=True)
    made = 0
    for who, outfits in source.OUTFITS.items():
        for outfit, slugs in outfits.items():
            for n, slug in enumerate(slugs, 1):
                name = f'{who}_{outfit}_{slug}'
                drawn = WEAR / f'item_{name}.png'
                after = WEAR / f'{who}_{outfit}_{n}.png'
                before = WEAR / (f'{who}_{outfit}_{n - 1}.png' if n > 1 else f'{who}_base.png')
                if (drawn.exists() and not every) or not after.exists() or not before.exists():
                    continue
                cut = garment(Image.open(before), Image.open(after))
                if cut is None:
                    print('nothing changed?', name)
                    continue
                cut.save(OUT / f'{name}.png')
                made += 1
    print('cut out:', made)


if __name__ == '__main__':
    main()
