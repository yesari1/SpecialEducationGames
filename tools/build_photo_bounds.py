"""Precompute opaque bounds of the item cutout PNGs.

PhotoVisual frames a photo by its non-transparent pixels instead of the
square file. Measuring that at runtime costs a full pixel scan per image on
the UI isolate, so the bounds are stored here as fractions (left, top, right,
bottom in 0..1) and the app only scans images missing from the file.

Run from the project root after adding or changing photos:
    python -I tools/build_photo_bounds.py
"""
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ALPHA_THRESHOLD = 24
PADDING_PX = 4


def bounds(path: Path):
    with Image.open(path) as image:
        rgba = image.convert('RGBA')
        width, height = rgba.size
        alpha = rgba.getchannel('A').point(lambda a: 255 if a > ALPHA_THRESHOLD else 0)
        box = alpha.getbbox()
    if box is None:
        return None
    left, top, right, bottom = box
    left = max(0, left - PADDING_PX)
    top = max(0, top - PADDING_PX)
    right = min(width, right + PADDING_PX)
    bottom = min(height, bottom + PADDING_PX)
    return [round(left / width, 5), round(top / height, 5),
            round(right / width, 5), round(bottom / height, 5)]


def main():
    result = {}
    for path in sorted((ROOT / 'assets' / 'images').rglob('*.png')):
        key = path.relative_to(ROOT).as_posix()
        measured = bounds(path)
        if measured is not None:
            result[key] = measured
    out = ROOT / 'assets' / 'content' / 'photo_bounds.json'
    out.write_text(json.dumps(result, separators=(',', ':'), sort_keys=True), encoding='utf-8')
    print(f'{len(result)} photo bounds -> {out.relative_to(ROOT).as_posix()}')


if __name__ == '__main__':
    main()
