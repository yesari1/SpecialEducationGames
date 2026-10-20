"""Adapt an already-transparent real photo cutout for the catalog.

Same treatment as the earlier verified photos (REAL_PHOTOS.md): keep the
photographed pixels and alpha, crop to the alpha bounds, aspect-preserving
Lanczos resize so the subject spans at most 912 px, center on a 1024x1024
RGBA canvas and add a 4 px white outline outside the subject. No new mask,
no generative edits.

    python -I tools/adapt_cutout_photo.py <original.png> <out.png>
Prints the input and output SHA-256 for the credit record.
"""
import hashlib
import sys

from PIL import Image, ImageFilter

MAX_EXTENT = 912
CANVAS = 1024
OUTLINE = 4


def sha(path):
    return hashlib.sha256(open(path, 'rb').read()).hexdigest()


def adapt(src, dst):
    image = Image.open(src).convert('RGBA')
    alpha = image.getchannel('A')
    box = alpha.point(lambda a: 255 if a > 24 else 0).getbbox()
    if box is None:
        raise SystemExit('no opaque pixels')
    image = image.crop(box)
    scale = MAX_EXTENT / max(image.size)
    size = (max(1, round(image.width * scale)), max(1, round(image.height * scale)))
    image = image.resize(size, Image.LANCZOS)
    canvas = Image.new('RGBA', (CANVAS, CANVAS), (0, 0, 0, 0))
    offset = ((CANVAS - size[0]) // 2, (CANVAS - size[1]) // 2)
    canvas.paste(image, offset, image)
    # White outline: dilate the subject's alpha by OUTLINE px and put white under it.
    mask = canvas.getchannel('A').point(lambda a: 255 if a > 24 else 0)
    grown = mask.filter(ImageFilter.MaxFilter(OUTLINE * 2 + 1))
    outline = Image.new('RGBA', canvas.size, (255, 255, 255, 0))
    outline.putalpha(grown)
    result = Image.alpha_composite(outline, canvas)
    result.save(dst)
    return box, size


if __name__ == '__main__':
    src, dst = sys.argv[1], sys.argv[2]
    box, size = adapt(src, dst)
    print(f'input {sha(src)} crop {box} subject {size} output {sha(dst)}')
