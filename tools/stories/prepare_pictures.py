"""Prepares freshly generated story pictures for the app.

    python -I tools/stories/prepare_pictures.py <story_id> [...]

Keeps the originals under artifacts/illustrations-stories/originals/<id>/,
turns scenes (page*, result*) into 1200x800 JPEGs and crops the transparent
cards (cover, choice_*) to their subject, square, 640 px.
Only PNG scenes are converted, so running it twice is harmless.
"""
import shutil
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]


def main():
    for sid in sys.argv[1:]:
        folder = ROOT / 'assets/stories' / sid
        keep = ROOT / 'artifacts/illustrations-stories/originals' / sid
        keep.mkdir(parents=True, exist_ok=True)
        for f in sorted(folder.glob('*.png')):
            if not (keep / f.name).exists():
                shutil.copy2(f, keep / f.name)
            im = Image.open(f)
            if f.name.startswith(('page', 'result')):
                im.convert('RGB').resize((1200, 800), Image.LANCZOS).save(
                    f.with_suffix('.jpg'), quality=86, optimize=True, progressive=True)
                f.unlink()
                continue
            im = im.convert('RGBA')
            box = im.getchannel('A').point(lambda v: 255 if v > 24 else 0).getbbox()
            sub = im.crop(box)
            side = int(max(sub.size) * 1.08)
            out = Image.new('RGBA', (side, side), (0, 0, 0, 0))
            out.paste(sub, ((side - sub.width) // 2, (side - sub.height) // 2))
            out.resize((640, 640), Image.LANCZOS).save(f, optimize=True)
        print(sid, 'ready')


if __name__ == '__main__':
    main()
