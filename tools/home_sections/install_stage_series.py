"""Installs a series of cut-out stage pictures that must stay aligned.

    python -I tools/home_sections/install_stage_series.py grow tree

Every picture artifacts/fix-nov12/cut/<series>_*.png is cropped with the SAME
box (the union of what is drawn in all of them, plus room above for things
that grow or fall), so one picture can replace another in a game without
anything jumping. Writes assets/images/play/<name>.webp and prints the
width / height to put in the game's "aspect".
"""
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
CUT = ROOT / 'artifacts/fix-nov12/cut'
PLAY = ROOT / 'assets/images/play'


def main():
    for series in sys.argv[1:]:
        files = sorted(CUT.glob(f'{series}_*.png'))
        boxes = [Image.open(f).getchannel('A').point(lambda v: 255 if v > 24 else 0).getbbox() for f in files]
        left, top = min(b[0] for b in boxes), min(b[1] for b in boxes)
        right, bottom = max(b[2] for b in boxes), max(b[3] for b in boxes)
        w, h = Image.open(files[0]).size
        pad = 40
        box = (max(0, left - pad), max(0, top - pad * 3), min(w, right + pad), min(h, bottom + pad))
        for f in files:
            im = Image.open(f).convert('RGBA').crop(box)
            if im.height > 1000:
                im = im.resize((round(im.width * 1000 / im.height), 1000), Image.LANCZOS)
            im.save(PLAY / f'{f.stem}.webp', 'WEBP', quality=90, alpha_quality=100, method=4)
        print(series, len(files), 'pictures, aspect', round((box[2] - box[0]) / (box[3] - box[1]), 4))


if __name__ == '__main__':
    main()
