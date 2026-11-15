"""Clears the faint haze some generated cut-outs carry around their subject.

    python -I tools/home_sections/clean_haze.py [--write]

A picture whose alpha channel has a wide area of very low values (a soft
glow left by image generation: the sun, the clean glass, the cloud) shows a
whitish cloud around it on a coloured background. Lists every WebP under
assets/images and assets/stickers with such a haze;
with --write sets alpha below 80 to zero in them (edges stay smooth: only
the lowest values go). Run build_photo_bounds.py afterwards.
"""
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]


def main():
    write = '--write' in sys.argv
    found = 0
    for folder in ('assets/images', 'assets/stickers'):
        for f in sorted((ROOT / folder).rglob('*')):
            if f.suffix.lower() not in ('.webp', '.png'):
                continue
            im = Image.open(f)
            if im.mode != 'RGBA':
                continue
            alpha = im.getchannel('A')
            hist = alpha.histogram()
            low = sum(hist[1:60])
            total = im.width * im.height
            if low / total < .03:
                continue
            found += 1
            print(f'{f.relative_to(ROOT).as_posix()}: {low * 100 // total}% haze')
            if write:
                im.putalpha(alpha.point(lambda v: 0 if v < 80 else v))
                if f.suffix.lower() == '.webp':
                    im.save(f, 'WEBP', quality=92, alpha_quality=100, method=4)
                else:
                    im.save(f)
    print(found, 'pictures with haze', '(cleaned)' if write else '')


if __name__ == '__main__':
    main()
